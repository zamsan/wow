WarriorTankHUD = {}
dofile("addons/WarriorTankHUD/State.lua")

local spellIds = { shieldBlock = 1, revenge = 2, taunt = 3, thunderClap = 4 }
local api = {
	health = function() return 720 end,
	healthMax = function() return 1000 end,
	rage = function() return 35 end,
	rageMax = function() return 100 end,
	time = function() return 100 end,
	spell = function(id)
		if id == 1 then return { known = true, icon = "shield", start = 90, duration = 20, usable = true } end
		if id == 2 then return { known = true, icon = "revenge", start = 0, duration = 0, usable = true } end
		if id == 3 then return { known = true, icon = "taunt", start = 0, duration = 0, usable = false } end
		if id == 4 then return { known = true, icon = "thunder", start = 70, duration = 20, usable = true } end
	end,
}

local snapshot = WarriorTankHUD.State.Read(api, spellIds)
assert(snapshot.health == 720 and snapshot.healthMax == 1000, "health values")
assert(snapshot.rage == 35 and snapshot.rageMax == 100, "rage values")
assert(snapshot.spells.shieldBlock.remaining == 10 and not snapshot.spells.shieldBlock.usable, "shield cooldown")
assert(snapshot.spells.revenge.usable and snapshot.spells.revenge.icon == "revenge", "revenge proc")
assert(not snapshot.spells.taunt.usable, "API unusable state")
assert(snapshot.spells.thunderClap.remaining == 0 and snapshot.spells.thunderClap.usable, "expired cooldown")

api.rage = function() return 0 end
api.spell = function(id)
	if id == 4 then return nil end
	return { known = false }
end
snapshot = WarriorTankHUD.State.Read(api, { shieldBlock = 1, revenge = 2, taunt = 3 })
assert(snapshot.rage == 0, "zero rage")
assert(not snapshot.spells.shieldBlock.usable and not snapshot.spells.shieldBlock.known, "unlearned spell")
assert(not snapshot.spells.thunderClap.usable and snapshot.spells.thunderClap.remaining == 0, "missing spell ID")

api.spell = function() error("restricted beta API") end
snapshot = WarriorTankHUD.State.Read(api, spellIds)
assert(not snapshot.spells.taunt.usable and not snapshot.spells.taunt.known, "restricted API stays inactive")

api.spell = function() return { known = true, start = "secret", duration = 10, usable = true } end
snapshot = WarriorTankHUD.State.Read(api, spellIds)
assert(not snapshot.spells.taunt.usable and snapshot.spells.taunt.remaining == 0, "unreadable cooldown stays inactive")

api.spell = function() return { known = true, icon = "icon", usable = true } end
snapshot = WarriorTankHUD.State.Read(api, spellIds)
assert(not snapshot.spells.taunt.usable, "missing cooldown stays inactive")

api.spell = function() return { known = true, start = 0, usable = true } end
snapshot = WarriorTankHUD.State.Read(api, spellIds)
assert(not snapshot.spells.taunt.usable, "partial cooldown stays inactive")

api.spell = function() return { known = true, start = 0, duration = 0, usable = true } end
api.time = function() return nil end
snapshot = WarriorTankHUD.State.Read(api, spellIds)
assert(not snapshot.spells.taunt.usable, "missing clock stays inactive")

print("state assertions passed")
