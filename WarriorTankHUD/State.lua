WarriorTankHUD = WarriorTankHUD or {}
WarriorTankHUD.State = {}

local spellKeys = { "shieldBlock", "revenge", "taunt", "thunderClap" }

-- Return nil when a beta client rejects a state API call.
local function safelyRead(callback, argument)
	if type(callback) ~= "function" then return nil end
	local ok, value = pcall(callback, argument)
	if ok then return value end
	return nil
end

-- Read player resources and each configured spell without guessing unavailable states.
function WarriorTankHUD.State.Read(api, spellIds)
	local now = safelyRead(api.time)
	local snapshot = {
		health = safelyRead(api.health) or 0,
		healthMax = safelyRead(api.healthMax) or 0,
		rage = safelyRead(api.rage) or 0,
		rageMax = safelyRead(api.rageMax) or 0,
		spells = {},
	}
	for _, key in ipairs(spellKeys) do
		local id = spellIds and spellIds[key]
		local value = id and safelyRead(api.spell, id) or nil
		local known = value ~= nil and value.known == true
		local start = value and value.start
		local duration = value and value.duration
		local valid, remaining = pcall(function()
			return math.max(0, start + duration - now)
		end)
		if not valid then known, remaining = false, 0 end
		snapshot.spells[key] = {
			icon = value and value.icon or nil,
			remaining = known and remaining or 0,
			usable = known and remaining == 0 and value.usable == true or false,
			known = known,
		}
	end
	return snapshot
end
