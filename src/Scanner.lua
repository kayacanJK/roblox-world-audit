--!strict
-- Iterative walk avoids recursion and skips ignored subtrees without examining them.

local Scanner = {}

export type Report = {
	findings: {any},
	inspected: number,
	ignoredSubtrees: number,
	totalFindings: number,
	truncated: boolean,
}

local MAX_STORED_FINDINGS = 5000
local YIELD_EVERY = 400

function Scanner.scan(root: Instance, inspect: (Instance, (string, string, string, string) -> ()) -> (), onProgress: ((number) -> ())?): Report
	local report: Report = {
		findings = {},
		inspected = 0,
		ignoredSubtrees = 0,
		totalFindings = 0,
		truncated = false,
	}
	local pending: {Instance} = {root}
	local visited = 0

	while #pending > 0 do
		local item = pending[#pending]
		pending[#pending] = nil
		visited += 1

		if item ~= root and item:GetAttribute("WorldAuditIgnore") == true then
			report.ignoredSubtrees += 1
		else
			if item ~= root then
				report.inspected += 1
				inspect(item, function(code: string, severity: string, title: string, message: string)
					report.totalFindings += 1
					if #report.findings < MAX_STORED_FINDINGS then
						table.insert(report.findings, {
							code = code,
							severity = severity,
							title = title,
							message = message,
							instance = item,
						})
					else
						report.truncated = true
					end
				end)
			end
			for _, child in ipairs(item:GetChildren()) do
				table.insert(pending, child)
			end
		end

		if visited % YIELD_EVERY == 0 then
			if onProgress then
				onProgress(report.inspected)
			end
			task.wait()
		end
	end

	table.sort(report.findings, function(a, b)
		if a.severity ~= b.severity then
			return a.severity == "Warning"
		end
		if a.code ~= b.code then
			return a.code < b.code
		end
		return a.instance:GetFullName() < b.instance:GetFullName()
	end)

	return report
end

return Scanner
