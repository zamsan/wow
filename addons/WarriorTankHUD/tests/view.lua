WarriorTankHUD = {}
dofile("addons/WarriorTankHUD/State.lua")
dofile("addons/WarriorTankHUD/View.lua")
dofile("addons/WarriorTankHUD/Core.lua")

local frames = {}

-- Make a minimal frame that records visible effects of the real view code.
local function makeFrame(kind, parent)
	local frame = { kind = kind, parent = parent, scripts = {}, children = {} }
	function frame:SetSize(width, height) self.width, self.height = width, height end
	function frame:SetPoint(_, _, _, x, y) self.x, self.y = x, y end
	function frame:ClearAllPoints() self.x, self.y = nil, nil end
	function frame:SetMinMaxValues(minimum, maximum) self.minimum, self.maximum = minimum, maximum end
	function frame:SetValue(value) self.value = value end
	function frame:SetText(value) self.text = value end
	function frame:SetTexture(value) self.texture = value end
	function frame:SetAlpha(value) self.alpha = value end
	function frame:SetScript(event, callback) self.scripts[event] = callback end
	function frame:GetCenter() return self.centerX or (500 + (self.x or 0)), self.centerY or (500 + (self.y or 0)) end
	function frame:CreateFontString() return makeFrame("FontString", self) end
	function frame:CreateTexture() return makeFrame("Texture", self) end
	function frame:Show() self.shown = true end
	function frame:Hide() self.shown = false end
	function frame:SetMovable() end
	function frame:EnableMouse() end
	function frame:RegisterForDrag() end
	function frame:StartMoving() end
	function frame:StopMovingOrSizing() end
	function frame:SetStatusBarTexture() end
	function frame:SetStatusBarColor() end
	function frame:SetFont() end
	function frame:SetJustifyH() end
	function frame:SetAllPoints() end
	function frame:SetTexCoord() end
	function frame:SetBackdrop() end
	table.insert(frames, frame)
	return frame
end

local parent = { GetCenter = function() return 500, 500 end }
local saved = {}
local now = 100
local spellIds = { shieldBlock = 1, revenge = 2, taunt = 3, thunderClap = 4 }
local callbacks = {}
local api = {
	UIParent = parent,
	CreateFrame = function(kind, _, owner) return makeFrame(kind, owner) end,
	screenWidth = function() return 1000 end,
	screenHeight = function() return 1000 end,
	playerClass = function() return "WARRIOR" end,
	health = function() return 720 end,
	healthMax = function() return 1000 end,
	rage = function() return 35 end,
	rageMax = function() return 100 end,
	time = function() return now end,
	spell = function(id)
		return { known = true, icon = "icon" .. id, start = id == 3 and 90 or 0, duration = id == 3 and 20 or 0, usable = true }
	end,
	onEvent = function(callback) callbacks.event = callback end,
	onTick = function(callback) callbacks.tick = callback end,
	onReset = function(callback) callbacks.reset = callback end,
}

local view = WarriorTankHUD.Core.Start(api, saved, spellIds)
assert(view and view.frame.shown, "warrior HUD always visible")
assert(view.healthBar.value == 720 and view.healthText.text == "720 / 1000", "health bar")
assert(view.rageBar.value == 35 and view.rageText.text == "35 / 100", "rage bar")
assert(view.icons.shieldBlock.texture.texture == "icon1", "shield icon")
assert(view.icons.revenge.texture.texture == "icon2", "revenge icon")
assert(view.icons.taunt.cooldown.text == "10", "taunt countdown")
assert(view.icons.thunderClap.texture.texture == "icon4", "thunder icon")

now = 111
callbacks.tick(0.2)
assert(view.icons.taunt.cooldown.text == "", "idle countdown reaches ready")
assert(view.icons.taunt.frame.alpha == 1, "ready icon brightens")

view.frame.centerX, view.frame.centerY = 620, 420
view.frame.scripts.OnDragStop(view.frame)
assert(saved.x == 120 and saved.y == -80, "drag position saved")
local restored = WarriorTankHUD.View.Create(api, saved)
assert(restored.frame.x == 120 and restored.frame.y == -80, "relog restores position")
callbacks.reset()
assert(saved.x == 0 and saved.y == -115, "reset saves default")

local corrupt = WarriorTankHUD.View.Create(api, { x = 9000, y = "bad" })
assert(corrupt.frame.x == 0 and corrupt.frame.y == -115, "bad position resets")
api.playerClass = function() return "MAGE" end
assert(WarriorTankHUD.Core.Start(api, {}, spellIds) == nil, "other class has no HUD")

print("view assertions passed")
