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
