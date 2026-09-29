WarriorTankHUD = WarriorTankHUD or {}
WarriorTankHUD.View = {}

local DEFAULT_X, DEFAULT_Y = 0, -115
local WIDTH, HEIGHT = 244, 86
local order = { "shieldBlock", "revenge", "taunt", "thunderClap" }
local labels = { shieldBlock = "막기", revenge = "복수", taunt = "도발", thunderClap = "천둥" }

-- Reject broken or off-screen saved coordinates before placing the HUD.
local function validPosition(api, x, y)
	return type(x) == "number" and type(y) == "number"
		and x == x and y == y
		and math.abs(x) <= (api.screenWidth() - WIDTH) / 2
		and math.abs(y) <= (api.screenHeight() - HEIGHT) / 2
end

-- Create one resource bar and its numeric label.
local function createBar(api, parent, y, red, green, blue)
	local bar = api.CreateFrame("StatusBar", nil, parent)
	bar:SetSize(WIDTH, 16)
	bar:SetPoint("TOP", parent, "TOP", 0, y)
	bar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
	bar:SetStatusBarColor(red, green, blue)
	local label = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("CENTER", bar, "CENTER", 0, 0)
	return bar, label
end

-- Create a spell icon with a short label and countdown text.
local function createIcon(api, parent, key, index)
	local frame = api.CreateFrame("Frame", nil, parent)
	frame:SetSize(36, 36)
	frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 24 + (index - 1) * 57, -43)
	local texture = frame:CreateTexture(nil, "ARTWORK")
	texture:SetAllPoints(frame)
	local cooldown = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	cooldown:SetPoint("CENTER", frame, "CENTER", 0, 0)
	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("TOP", frame, "BOTTOM", 0, -2)
	label:SetText(labels[key])
	return { frame = frame, texture = texture, cooldown = cooldown }
end

-- Build a fixed screen-space HUD and retain its per-character position.
function WarriorTankHUD.View.Create(api, savedPosition)
	local saved = type(savedPosition) == "table" and savedPosition or {}
	local frame = api.CreateFrame("Frame", nil, api.UIParent)
	frame:SetSize(WIDTH, HEIGHT)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	local x, y = saved.x, saved.y
	if not validPosition(api, x, y) then
		x, y = DEFAULT_X, DEFAULT_Y
	end
	frame:SetPoint("CENTER", api.UIParent, "CENTER", x, y)
	local view = { frame = frame, saved = saved, icons = {} }
	view.healthBar, view.healthText = createBar(api, frame, -2, 0.2, 0.8, 0.25)
	view.rageBar, view.rageText = createBar(api, frame, -22, 0.85, 0.2, 0.2)
	for index, key in ipairs(order) do
		view.icons[key] = createIcon(api, frame, key, index)
	end
	frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local centerX, centerY = self:GetCenter()
		local parentX, parentY = api.UIParent:GetCenter()
		local newX, newY = centerX - parentX, centerY - parentY
		if validPosition(api, newX, newY) then
			saved.x, saved.y = newX, newY
		else
			view:ResetPosition()
		end
	end)
	frame:Show()
	return setmetatable(view, { __index = WarriorTankHUD.View })
end

-- Render player resources and spell states, returning whether a timer remains.
function WarriorTankHUD.View:Render(snapshot)
	self.healthBar:SetMinMaxValues(0, math.max(1, snapshot.healthMax))
	self.healthBar:SetValue(snapshot.health)
	self.healthText:SetText(snapshot.health .. " / " .. snapshot.healthMax)
	self.rageBar:SetMinMaxValues(0, math.max(1, snapshot.rageMax))
	self.rageBar:SetValue(snapshot.rage)
	self.rageText:SetText(snapshot.rage .. " / " .. snapshot.rageMax)
	local hasCooldown = false
	for _, key in ipairs(order) do
		local state = snapshot.spells[key]
		local icon = self.icons[key]
		icon.texture:SetTexture(state.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
		icon.frame:SetAlpha(state.usable and 1 or (state.known and 0.45 or 0.25))
		icon.cooldown:SetText(state.remaining > 0 and tostring(math.ceil(state.remaining)) or "")
		hasCooldown = hasCooldown or state.remaining > 0
	end
	return hasCooldown
end

-- Restore the original fixed position and persist it for this character.
function WarriorTankHUD.View:ResetPosition()
	self.saved.x, self.saved.y = DEFAULT_X, DEFAULT_Y
	self.frame:ClearAllPoints()
	self.frame:SetPoint("CENTER", self.frame.parent or UIParent, "CENTER", DEFAULT_X, DEFAULT_Y)
end
