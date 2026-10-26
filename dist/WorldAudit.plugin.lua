--!strict
-- World Audit: a read-only workspace inspection tool for Roblox Studio.
-- Source modules are bundled into a single local plugin by scripts/build.py.

assert(plugin, "World Audit runs only as a Studio plugin")

local Rules = (function()
--!strict
-- Individual checks are intentionally conservative. Every finding is advisory.

local Rules = {}

export type Finding = {
	code: string,
	severity: string,
	title: string,
	message: string,
	instance: Instance,
}

local function add(emit: (string, string, string, string) -> (), code: string, severity: string, title: string, message: string)
	emit(code, severity, title, message)
end

function Rules.inspect(instance: Instance, emit: (string, string, string, string) -> ())
	if instance:IsA("MeshPart") and instance.CollisionFidelity == Enum.CollisionFidelity.PreciseConvexDecomposition then
		add(emit, "PRECISE_COLLISION", "Warning", "Precise mesh collision", "A simpler collision mode might be sufficient for this mesh.")
	end

	if instance:IsA("BasePart") then
		if instance.Transparency >= 1 and instance.CanCollide then
			add(emit, "INVISIBLE_COLLIDER", "Info", "Invisible collider", "Check that this is an intentional invisible wall or collision volume.")
		end
		if not instance.Anchored and instance.Parent == workspace then
			add(emit, "LOOSE_ROOT_PART", "Info", "Unanchored root part", "A loose part directly under Workspace may fall or move at runtime.")
		end
	end

	if instance:IsA("ParticleEmitter") and instance.Enabled and instance.Rate > 250 then
		add(emit, "HIGH_PARTICLE_RATE", "Warning", "High particle rate", "More than 250 particles/second. Profile on a lower-end device.")
	end

	if (instance:IsA("PointLight") or instance:IsA("SpotLight") or instance:IsA("SurfaceLight")) and instance.Enabled and instance.Shadows and instance.Range > 40 then
		add(emit, "WIDE_SHADOW_LIGHT", "Info", "Large shadow-casting light", "Wide shadow lights may be expensive in busy scenes.")
	end

	if instance:IsA("Sound") and instance.SoundId == "" then
		add(emit, "MISSING_SOUND_ID", "Info", "Missing sound asset", "This Sound does not reference an audio asset.")
	end

	if (instance:IsA("Decal") or instance:IsA("Texture")) and instance.Texture == "" then
		add(emit, "MISSING_TEXTURE", "Info", "Missing texture asset", "This object does not reference a texture.")
	end
end

return Rules

end)()
local Scanner = (function()
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

end)()
local Selection = game:GetService("Selection")
local Workspace = game:GetService("Workspace")

local C = {
	background = Color3.fromRGB(19, 24, 31),
	panel = Color3.fromRGB(27, 34, 44),
	card = Color3.fromRGB(37, 46, 58),
	border = Color3.fromRGB(58, 70, 86),
	primary = Color3.fromRGB(89, 149, 246),
	text = Color3.fromRGB(238, 242, 247),
	muted = Color3.fromRGB(167, 181, 198),
	warning = Color3.fromRGB(248, 185, 96),
	info = Color3.fromRGB(128, 183, 231),
	success = Color3.fromRGB(142, 215, 171),
}

local function ui(className: string, properties: {[string]: any}, parent: Instance): any
	local element = Instance.new(className)
	for key, value in pairs(properties) do
		(element :: any)[key] = value
	end
	element.Parent = parent
	return element
end

local function corner(parent: Instance, radius: number)
	ui("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function label(parent: Instance, text: string, size: UDim2, position: UDim2, font: Enum.Font, fontSize: number, color: Color3): TextLabel
	return ui("TextLabel", {
		BackgroundTransparency = 1, Size = size, Position = position,
		Font = font, TextSize = fontSize, TextColor3 = color,
		Text = text, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, parent) :: TextLabel
end

local toolbar = plugin:CreateToolbar("World Audit")
local toolbarButton = toolbar:CreateButton("World Audit", "Check Workspace for common scene issues", "")
toolbarButton.ClickableWhenViewportHidden = true

local widgetInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right, false, false, 440, 580, 350, 360)
local widget = plugin:CreateDockWidgetPluginGuiAsync("WorldAudit_Panel_1", widgetInfo)
widget.Title = "World Audit"

local root = ui("Frame", {
	Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.background, BorderSizePixel = 0,
}, widget)

label(root, "WORLD AUDIT", UDim2.new(1, -24, 0, 28), UDim2.fromOffset(14, 12), Enum.Font.GothamBold, 18, C.text)
label(root, "Inspect your scene without changing it", UDim2.new(1, -24, 0, 22), UDim2.fromOffset(14, 41), Enum.Font.Gotham, 12, C.muted)

local scanButton = ui("TextButton", {
	Position = UDim2.fromOffset(14, 76), Size = UDim2.new(1, -28, 0, 38),
	BackgroundColor3 = C.primary, BorderSizePixel = 0,
	Text = "Scan Workspace", Font = Enum.Font.GothamBold,
	TextSize = 14, TextColor3 = Color3.new(1, 1, 1),
}, root) :: TextButton
corner(scanButton, 8)

local summary = label(root, "No scan yet", UDim2.new(1, -28, 0, 24), UDim2.fromOffset(14, 124), Enum.Font.GothamMedium, 12, C.text)

local search = ui("TextBox", {
	Position = UDim2.fromOffset(14, 155), Size = UDim2.new(1, -28, 0, 33),
	BackgroundColor3 = C.panel, BorderSizePixel = 0,
	Text = "", PlaceholderText = "Find an object or rule...", ClearTextOnFocus = false,
	Font = Enum.Font.Gotham, TextSize = 12,
	TextColor3 = C.text, PlaceholderColor3 = C.muted,
	TextXAlignment = Enum.TextXAlignment.Left,
}, root) :: TextBox
corner(search, 6)
ui("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, search)

local filters: {[string]: TextButton} = {}
local activeFilter = "All"
local filterNames = {"All", "Warning", "Info"}
for index, name in ipairs(filterNames) do
	local button = ui("TextButton", {
		Position = UDim2.new((index - 1) / 3, if index == 1 then 14 else 5, 0, 198),
		Size = UDim2.new(1 / 3, -18, 0, 30),
		BackgroundColor3 = if index == 1 then C.primary else C.panel,
		BorderSizePixel = 0, Text = name, TextColor3 = C.text,
		Font = Enum.Font.GothamMedium, TextSize = 12,
	}, root) :: TextButton
	corner(button, 6)
	filters[name] = button
end

local scroll = ui("ScrollingFrame", {
	Position = UDim2.fromOffset(14, 238), Size = UDim2.new(1, -28, 1, -294),
	BackgroundColor3 = C.panel, BorderSizePixel = 0,
	ScrollBarThickness = 5, ScrollBarImageColor3 = C.border,
	AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
}, root) :: ScrollingFrame
corner(scroll, 8)
ui("UIPadding", {
	PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
	PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
}, scroll)
ui("UIListLayout", {Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder}, scroll)

local exportButton = ui("TextButton", {
	Position = UDim2.new(0, 14, 1, -47), Size = UDim2.new(1, -28, 0, 34),
	BackgroundColor3 = C.card, BorderSizePixel = 0,
	Text = "View / copy text report", TextColor3 = C.text,
	TextSize = 12, Font = Enum.Font.GothamMedium,
}, root) :: TextButton
corner(exportButton, 7)

local exportFrame = ui("Frame", {
	Visible = false, Position = UDim2.fromOffset(14, 238),
	Size = UDim2.new(1, -28, 1, -294),
	BackgroundColor3 = C.panel, BorderSizePixel = 0, ZIndex = 5,
}, root) :: Frame
corner(exportFrame, 8)
local exportText = ui("TextBox", {
	Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -20, 1, -20),
	BackgroundColor3 = C.panel, BorderSizePixel = 0,
	Font = Enum.Font.Code, TextSize = 12, TextColor3 = C.text,
	Text = "", TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = false, MultiLine = true, ClearTextOnFocus = false,
	ZIndex = 6,
}, exportFrame) :: TextBox

local report = nil
local filteredLimit = 80
local isScanning = false

local function clearRows()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function hint(text: string)
	local item = label(scroll, text, UDim2.new(1, -10, 0, 58), UDim2.new(), Enum.Font.Gotham, 12, C.muted)
	item.TextWrapped = true
	item.TextTruncate = Enum.TextTruncate.None
	return item
end

local function filteredFindings()
	local items = {}
	if not report then
		return items
	end
	local query = string.lower(search.Text)
	for _, entry in ipairs(report.findings) do
		local matchesFilter = activeFilter == "All" or entry.severity == activeFilter
		local matchesSearch = query == "" or string.find(string.lower(entry.code .. " " .. entry.title .. " " .. entry.instance:GetFullName()), query, 1, true) ~= nil
		if matchesFilter and matchesSearch then
			table.insert(items, entry)
		end
	end
	return items
end

local function render()
	clearRows()
	if not report then
		hint("Run a scan to review warnings and informational findings.")
		return
	end
	local entries = filteredFindings()
	if #entries == 0 then
		hint("Nothing matched. Try another filter or search term.")
		return
	end
	for index = 1, math.min(#entries, filteredLimit) do
		local entry = entries[index]
		local card = ui("TextButton", {
			LayoutOrder = index, Size = UDim2.new(1, -2, 0, 94),
			BackgroundColor3 = C.card, BorderSizePixel = 0,
			Text = "", AutoButtonColor = true,
		}, scroll) :: TextButton
		corner(card, 6)
		local accent = ui("Frame", {
			Size = UDim2.new(0, 3, 1, 0), BorderSizePixel = 0,
			BackgroundColor3 = if entry.severity == "Warning" then C.warning else C.info,
		}, card)
		corner(accent, 2)
		label(card, entry.title, UDim2.new(1, -22, 0, 19), UDim2.fromOffset(12, 8), Enum.Font.GothamBold, 12, C.text)
		label(card, entry.instance:GetFullName(), UDim2.new(1, -22, 0, 17), UDim2.fromOffset(12, 29), Enum.Font.Code, 11, C.muted)
		local description = label(card, entry.message, UDim2.new(1, -22, 0, 41), UDim2.fromOffset(12, 50), Enum.Font.Gotham, 11, C.muted)
		description.TextWrapped = true
		description.TextYAlignment = Enum.TextYAlignment.Top
		description.TextTruncate = Enum.TextTruncate.None
		card.MouseButton1Click:Connect(function()
			if entry.instance:IsDescendantOf(game) then
				Selection:Set({entry.instance})
			end
		end)
	end
	if #entries > filteredLimit then
		local more = ui("TextButton", {
			LayoutOrder = filteredLimit + 1,
			Size = UDim2.new(1, -2, 0, 38), BackgroundColor3 = C.border,
			BorderSizePixel = 0, Text = string.format("Show more (%d remaining)", #entries - filteredLimit),
			Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.text,
		}, scroll) :: TextButton
		corner(more, 6)
		more.MouseButton1Click:Connect(function()
			filteredLimit += 80
			render()
		end)
	end
end

local function makeTextReport(): string
	if not report then
		return "Run a scan first."
	end
	local lines = {
		"WORLD AUDIT", "Read-only Roblox Studio scene report",
		string.format("Inspected: %d | Ignored subtrees: %d | Findings: %d", report.inspected, report.ignoredSubtrees, report.totalFindings),
		"",
	}
	for _, entry in ipairs(report.findings) do
		table.insert(lines, string.format("[%s] %s | %s\n  %s", entry.severity, entry.code, entry.instance:GetFullName(), entry.message))
	end
	if report.truncated then
		table.insert(lines, "Report truncated after 5,000 stored findings.")
	end
	return table.concat(lines, "\n")
end

search:GetPropertyChangedSignal("Text"):Connect(function()
	filteredLimit = 80
	render()
end)

for name, button in pairs(filters) do
	button.MouseButton1Click:Connect(function()
		activeFilter = name
		filteredLimit = 80
		for otherName, other in pairs(filters) do
			other.BackgroundColor3 = if otherName == activeFilter then C.primary else C.panel
		end
		render()
	end)
end

exportButton.MouseButton1Click:Connect(function()
	exportFrame.Visible = not exportFrame.Visible
	if exportFrame.Visible then
		exportText.Text = makeTextReport()
		exportButton.Text = "Close report (Ctrl+A, Ctrl+C to copy)"
	else
		exportButton.Text = "View / copy text report"
	end
end)

scanButton.MouseButton1Click:Connect(function()
	if isScanning then
		return
	end
	isScanning = true
	scanButton.Text = "Scanning..."
	scanButton.Active = false
	local ok, result = pcall(function()
		return Scanner.scan(Workspace, Rules.inspect, function(inspected: number)
			summary.Text = string.format("Scanning... %d objects", inspected)
		end)
	end)
	if ok then
		report = result
		filteredLimit = 80
		local warnings = 0
		for _, finding in ipairs(report.findings) do
			if finding.severity == "Warning" then
				warnings += 1
			end
		end
		summary.Text = string.format("%d objects | %d findings | %d warnings", report.inspected, report.totalFindings, warnings)
		if report.truncated then
			summary.Text = summary.Text .. " (partial list)"
		end
		render()
		if exportFrame.Visible then
			exportText.Text = makeTextReport()
		end
	else
		warn("World Audit scan failed:", result)
		summary.Text = "Scan failed; check Studio Output."
	end
	scanButton.Text = "Scan Workspace"
	scanButton.Active = true
	isScanning = false
end)

toolbarButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

render()
