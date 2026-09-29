WarriorTankHUD = WarriorTankHUD or {}
WarriorTankHUD.Core = {}

-- Start the warrior HUD and wire state refreshes to client notifications.
function WarriorTankHUD.Core.Start(api, saved, spellIds)
	if api.playerClass() ~= "WARRIOR" then return nil end
	local view = WarriorTankHUD.View.Create(api, saved)
	local hasCooldown = false
	local elapsed = 0
	-- Refresh resource bars and spell icons using the normalized adapter.
	local function refresh()
		hasCooldown = view:Render(WarriorTankHUD.State.Read(api, spellIds))
	end
	api.onEvent(refresh)
	api.onTick(function(delta)
		if not hasCooldown then return end
		elapsed = elapsed + delta
		if elapsed >= 0.1 then
			elapsed = 0
			refresh()
		end
	end)
	api.onReset(function() view:ResetPosition() end)
	refresh()
	return view
end

-- Read one spell through the APIs exposed by the current game client.
local function readNativeSpell(id)
	local modern = C_Spell
	local info = modern and modern.GetSpellInfo and modern.GetSpellInfo(id)
	local icon = info and info.iconID
	if not icon and GetSpellTexture then icon = GetSpellTexture(id) end
	local known = (IsSpellKnown and IsSpellKnown(id)) or false
	if modern and modern.IsSpellKnown then known = modern.IsSpellKnown(id) end
	local start, duration
	if modern and modern.GetSpellCooldown then
		local cooldown = modern.GetSpellCooldown(id)
		if cooldown then start, duration = cooldown.startTime, cooldown.duration end
	elseif GetSpellCooldown then
		start, duration = GetSpellCooldown(id)
	end
	local usable = false
	if modern and modern.IsSpellUsable then
		usable = modern.IsSpellUsable(id)
	elseif IsUsableSpell then
		usable = IsUsableSpell(id)
	end
	return { known = known == true, icon = icon, start = start, duration = duration, usable = usable == true }
end

-- Adapt game globals to the small interface used by State and View.
local function nativeApi()
	local eventFrame = CreateFrame("Frame")
	return {
		UIParent = UIParent,
		CreateFrame = CreateFrame,
		screenWidth = GetScreenWidth,
		screenHeight = GetScreenHeight,
		playerClass = function() local _, class = UnitClass("player"); return class end,
		health = function() return UnitHealth("player") end,
		healthMax = function() return UnitHealthMax("player") end,
		rage = function() return UnitPower("player", 1) end,
		rageMax = function() return UnitPowerMax("player", 1) end,
		time = GetTime,
		spell = readNativeSpell,
		onEvent = function(callback)
			for _, event in ipairs({ "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "SPELL_UPDATE_COOLDOWN", "SPELL_UPDATE_USABLE", "SPELLS_CHANGED", "PLAYER_ENTERING_WORLD" }) do
				eventFrame:RegisterEvent(event)
			end
			eventFrame:SetScript("OnEvent", function(_, event, unit)
				if unit == nil or unit == "player" then callback() end
			end)
		end,
		onTick = function(callback)
			eventFrame:SetScript("OnUpdate", function(_, delta) callback(delta) end)
		end,
		onReset = function(callback)
			SLASH_WARRIORTANKHUD1 = "/wthud"
			SlashCmdList.WARRIORTANKHUD = function(message)
				if message == "reset" then callback() end
			end
		end,
	}
end

-- Create the game adapter after saved variables and the player are ready.
local function bootstrap()
	WarriorTankHUDDB = type(WarriorTankHUDDB) == "table" and WarriorTankHUDDB or {}
	local spellIds = {
		shieldBlock = nil,
		revenge = nil,
		taunt = nil,
		thunderClap = nil,
	}
	WarriorTankHUD.Core.Start(nativeApi(), WarriorTankHUDDB, spellIds)
end

if type(CreateFrame) == "function" and type(UnitClass) == "function" then
	local loader = CreateFrame("Frame")
	loader:RegisterEvent("PLAYER_LOGIN")
	loader:SetScript("OnEvent", bootstrap)
end
