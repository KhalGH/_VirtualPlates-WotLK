-------------------------------------------------------------------------------------------------
----------------------- VirtualPlates Appeareance Customization (by Khal) -----------------------
-------------------------------------------------------------------------------------------------

local me = select( 2, ... ); -- namespace

----------------------------- API -----------------------------
local C_NamePlate = C_NamePlate
local C_NamePlate_GetNamePlateForUnit = C_NamePlate and C_NamePlate.GetNamePlateForUnit
local C_NamePlate_GetNamePlatesDistance = C_NamePlate and C_NamePlate.GetNamePlatesDistance
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local UnitName = UnitName
local UnitIsUnit = UnitIsUnit
local UnitReaction = UnitReaction
local CreateFrame = CreateFrame
local math_floor = math.floor
local unpack = unpack

------------------------- Core Variables -------------------------
local VirtualPlates = {} -- storage table for virtual nameplate frames
local RealPlates = {} -- storage table for real nameplate frames
local texturePath = "Interface\\AddOns\\!!!_VirtualPlates\\Textures\\"
local NP_WIDTH = 156.65118520899 -- nameplate original width (don't modify)
local NP_HEIGHT = 39.162796302247 -- nameplate original height (don't modify)
me.VirtualPlates = VirtualPlates -- reference for _VirtualPlates.lua
me.RealPlates = RealPlates -- reference for _VirtualPlates.lua
me.texturePath = texturePath -- reference for _VirtualPlates.lua

-------------------- Customization Parameters --------------------
local fontPath = "Fonts\\ARIALN.TTF"
local globalYoffset = 22
me.globalYoffset = globalYoffset -- reference for _VirtualPlates.lua
-- Name Text
local nameText_fontSize = 9
local nameText_fontFlags = nil
local nameText_anchor = "CENTER"
local nameText_Xoffset = 0.2
local nameText_Yoffset = 0.7
local nameText_width = 85 -- max text width before truncation (...)
local nameText_color = {1, 1, 1} -- white
me.nameText_color = nameText_color -- reference for _VirtualPlates.lua
-- Health Text
local healthText_fontSize = 8.8
local healthText_fontFlags = nil
local healthText_anchor = "RIGHT"
local healthText_Xoffset = 0
local healthText_Yoffset = 0.3
local healthText_color = {1, 1, 1} -- white
-- Cast Text
local castText_fontSize = 9
local castText_fontFlags = nil
local castText_anchor = "CENTER"
local castText_Xoffset = -3.8
local castText_Yoffset = 1.6
local castText_width = 90 -- max text width before truncation (...)
local castText_color = {1, 1, 1} -- white
-- Cast Timer Text
local castTimerText_fontSize = 8.8
local castTimerText_fontFlags = nil
local castTimerText_anchor = "RIGHT"
local castTimerText_Xoffset = -2
local castTimerText_Yoffset = 1
local castTimerText_color = {1, 1, 1} -- white
-- Distance Text
local distanceText_fontSize = 11
local distanceText_fontFlags = "OUTLINE"
local distanceText_anchor = "CENTER"
local distanceText_Xoffset = 0
local distanceText_Yoffset = 16
local distanceText_color = {1, 1, 1} -- white
-- Target Glow
local targetGlow_alpha = 1 -- opacity
me.targetGlow_alpha = targetGlow_alpha -- reference for _VirtualPlates.lua
-- Mouseover Glow
local mouseoverGlow_alpha = 1 -- opacity
me.mouseoverGlow_alpha = mouseoverGlow_alpha -- reference for _VirtualPlates.lua
-- Focus Glow
local focusGlow_color = {0.6, 0.2, 1} -- purple (add 4th value for opacity)
-- Cast Glow (Shows when unit is targetting you)
local castGlow_friendlyColor = {0.25, 0.75, 0.25} -- friendly: green (add 4th value for opacity)
local castGlow_enemyColor = {1, 0, 0} -- enemy: red (add 4th value for opacity)
-- Boss Icon
local bossIcon_size = 18
local bossIcon_anchor = "RIGHT"
local bossIcon_Xoffset = 4.5
local bossIcon_Yoffset = -9
-- Raid Target Icon
local raidTargetIcon_size = 27
local raidTargetIcon_anchor = "RIGHT"
local raidTargetIcon_Xoffset = 16
local raidTargetIcon_Yoffset = -9
-- Class Icon
local classIcon_size = 26
local classIcon_anchor = "LEFT"
local classIcon_Xoffset = -9.6
local classIcon_Yoffset = -9
-- Totem Plates
local totemSize = 23 -- size of the totem (or NPC) icon replacing the nameplate
local totemOffSet = -14 -- vertical offset for totem icon
local totemGlowSize = 128 * totemSize / 88 -- ratio 128:88 comes from texture pixels

---------------------------- Customization Functions ----------------------------
local function CreateHealthBorder(healthBar)
	if not healthBar.healthBarBorder then
		healthBar.healthBarBorder = healthBar:CreateTexture(nil, "ARTWORK")
		healthBar.healthBarBorder:SetTexture(texturePath .. "HealthBar-Border")
		healthBar.healthBarBorder:SetSize(NP_WIDTH, NP_HEIGHT)
		healthBar.healthBarBorder:SetPoint("CENTER", 10.5, 9)
	end
end

local function CreateBarBackground(Bar)
	if not Bar.BackgroundTex then
		Bar.BackgroundTex = Bar:CreateTexture(nil, "BACKGROUND")
		Bar.BackgroundTex:SetTexture(texturePath .. "NamePlate-Background")
		Bar.BackgroundTex:SetSize(NP_WIDTH, NP_HEIGHT)
		Bar.BackgroundTex:SetPoint("CENTER", 10.5, 9)
	end
end

local function CreateNameText(healthBar)
	if not healthBar.nameText then
		healthBar.nameText = healthBar:CreateFontString(nil, "OVERLAY")
		healthBar.nameText:SetFont(fontPath, nameText_fontSize, nameText_fontFlags)
		healthBar.nameText:SetPoint(nameText_anchor, nameText_Xoffset, nameText_Yoffset)
		healthBar.nameText:SetWidth(nameText_width)
		healthBar.nameText:SetTextColor(unpack(nameText_color))
		healthBar.nameText:SetShadowOffset(0.5, -0.5)
		healthBar.nameText:SetNonSpaceWrap(false)
		healthBar.nameText:SetWordWrap(false)
	end
end

local function UpdateHealthText(healthBar)
	local min, max = healthBar:GetMinMaxValues()
	local value = healthBar:GetValue()
	if max > 0 then
		local percent = math_floor((value / max) * 100)
		if percent < 100 and percent > 0 then
			healthBar.healthText:SetText(percent .. "%")
		else
			healthBar.healthText:SetText("")
		end
	else
		healthBar.healthText:SetText("")
	end
end

local function CreateHealthText(healthBar)
	if not healthBar.healthText then
		healthBar.healthText = healthBar:CreateFontString(nil, "OVERLAY")
		healthBar.healthText:SetFont(fontPath, healthText_fontSize, healthText_fontFlags)
		healthBar.healthText:SetPoint(healthText_anchor, healthText_Xoffset, healthText_Yoffset)
		healthBar.healthText:SetTextColor(unpack(healthText_color))
		healthBar.healthText:SetShadowOffset(0.5, -0.5)
		UpdateHealthText(healthBar)
		healthBar:HookScript("OnValueChanged", UpdateHealthText)
		healthBar:HookScript("OnShow", UpdateHealthText)
	end
end

local function CreateTargetGlow(healthBar)
	if not healthBar.targetGlow then
		healthBar.targetGlow = healthBar:CreateTexture(nil, "OVERLAY")	
		healthBar.targetGlow:SetTexture(texturePath .. "HealthBar-TargetGlow")
		healthBar.targetGlow:SetSize(NP_WIDTH, NP_HEIGHT)
		healthBar.targetGlow:SetAlpha(targetGlow_alpha)
		healthBar.targetGlow:SetPoint("CENTER", 0.7, 0.5)
		healthBar.targetGlow:Hide()
	end
end

local function UpdateTargetGlow(healthBar)
	local virtual = healthBar:GetParent()
	local realPlate = RealPlates[virtual]
	healthBar.targetBorderDelay = healthBar.targetBorderDelay or CreateFrame("Frame")
	healthBar.targetBorderDelay:SetScript("OnUpdate", function(self, elapsed)
		self:SetScript("OnUpdate", nil)
		if C_NamePlate then
			local targetPlate = C_NamePlate_GetNamePlateForUnit("target")
			if virtual == VirtualPlates[targetPlate] then
				healthBar.targetGlow:Show()
				if realPlate.totemPlate then realPlate.totemPlate.targetGlow:Show() end
			else
				healthBar.targetGlow:Hide()
				if realPlate.totemPlate then realPlate.totemPlate.targetGlow:Hide() end
			end			
		else
			if healthBar.nameText:GetText() == UnitName("target") and virtual:GetAlpha() == 1 then
				healthBar.targetGlow:Show()
				if realPlate.totemPlate then realPlate.totemPlate.targetGlow:Show() end
			else
				healthBar.targetGlow:Hide()
				if realPlate.totemPlate then realPlate.totemPlate.targetGlow:Hide() end
			end
		end
	end)
end

local function CreateFocusGlow(healthBar)
	if not healthBar.focusGlow then
		healthBar.focusGlow = healthBar:CreateTexture(nil, "OVERLAY")	
		healthBar.focusGlow:SetTexture(texturePath .. "HealthBar-FocusGlow")
		healthBar.focusGlow:SetVertexColor(unpack(focusGlow_color))
		healthBar.focusGlow:SetSize(NP_WIDTH, NP_HEIGHT)
		healthBar.focusGlow:SetPoint("CENTER", 0.7, 0.5)
		healthBar.focusGlow:Hide()
	end
end

local function UpdateFocusGlow(healthBar)
	if C_NamePlate then
		healthBar.focusBorderDelay = healthBar.focusBorderDelay or CreateFrame("Frame")
		healthBar.focusBorderDelay:SetScript("OnUpdate", function(self, elapsed)
			self:SetScript("OnUpdate", nil)
			if healthBar:GetParent() == VirtualPlates[C_NamePlate_GetNamePlateForUnit("focus")] and not UnitIsUnit("target","focus") then		
				healthBar.focusGlow:Show()
			else
				healthBar.focusGlow:Hide()
			end
		end)
	end
end

local function CreateCastText(castBar)
	if not castBar.castText then
		castBar.castText = castBar:CreateFontString(nil, "OVERLAY")
		castBar.castText:SetFont(fontPath, castText_fontSize, castText_fontFlags)
		castBar.castText:SetPoint(castText_anchor, castText_Xoffset, castText_Yoffset)
		castBar.castText:SetWidth(castText_width)
		castBar.castText:SetTextColor(unpack(castText_color))
		castBar.castText:SetNonSpaceWrap(false)
		castBar.castText:SetWordWrap(false)
		castBar.castText:SetShadowOffset(0.5, -0.5)
		castBar.castTextDelay = castBar.castTextDelay or CreateFrame("Frame")
		local function UpdateCastText()
			castBar.castTextDelay:SetScript("OnUpdate", function(self, elapsed)
				self:SetScript("OnUpdate", nil)
				local unit = "target"
				if C_NamePlate then
					local plate = RealPlates[castBar:GetParent()]
					if plate and plate.namePlateUnitToken then
						unit = plate.namePlateUnitToken
					end
				end
				local spellName = UnitCastingInfo(unit) or UnitChannelInfo(unit)
				castBar.castText:SetText(spellName)				
			end)
		end
		UpdateCastText()
		castBar:HookScript("OnShow", UpdateCastText)
	end 
end

local function CreateCastTimer(castBar)
	if not castBar.castTimerText then
		castBar.castTimerText = castBar:CreateFontString(nil, "OVERLAY")
		castBar.castTimerText:SetFont(fontPath, castTimerText_fontSize, castTimerText_fontFlags)
		castBar.castTimerText:SetPoint(castTimerText_anchor, castTimerText_Xoffset, castTimerText_Yoffset)
		castBar.castTimerText:SetTextColor(unpack(castTimerText_color))
		castBar.castTimerText:SetShadowOffset(0.5, -0.5)
		castBar:HookScript("OnValueChanged", function(self, value)
			local min, max = self:GetMinMaxValues()
			if max and value then
				local remaining = max - value
				if C_NamePlate then
					if self.channeling then
						self.castTimerText:SetFormattedText("%.1f", value)
					else
						self.castTimerText:SetFormattedText("%.1f", remaining)						
					end
				else
					if UnitChannelInfo("target") then
						self.castTimerText:SetFormattedText("%.1f", value)
					else
						self.castTimerText:SetFormattedText("%.1f", remaining)
					end
				end
			end
		end)
	end
end

local function CreateCastGlow(virtual)
	if not virtual.castGlow then
		virtual.castGlow = virtual:CreateTexture(nil, "OVERLAY")	
		virtual.castGlow:SetTexture(texturePath .. "CastBar-Glow")
		virtual.castGlow:SetTexCoord(0, 0.55, 0, 1)
		virtual.castGlow:SetSize(159.5, 40)
		virtual.castGlow:SetPoint("CENTER", 2.75, -27.5 + globalYoffset)
		virtual.castGlow:SetVertexColor(unpack(castGlow_enemyColor))
		virtual.castGlow:Hide()
		local castBar = select(2, virtual:GetChildren())
		local castBarBorder = select(3, virtual:GetRegions())
		castBar:HookScript("OnShow", function()
			local namePlateUnit = RealPlates[virtual].namePlateUnitToken
			if namePlateUnit then
				local namePlateTarget = UnitName(namePlateUnit.."target")
				if namePlateTarget == UnitName("player") and castBarBorder:IsShown() and not UnitIsUnit("target", namePlateUnit) then
					local reaction = UnitReaction("player", namePlateUnit)
					if reaction and reaction >= 5 then
						virtual.castGlow:SetVertexColor(unpack(castGlow_friendlyColor))
					else
						virtual.castGlow:SetVertexColor(unpack(castGlow_enemyColor))
					end
					virtual.castGlow:Show()
				end
			end
		end)
		castBar:HookScript("OnValueChanged", function()
			local namePlateUnit = RealPlates[virtual].namePlateUnitToken
			if namePlateUnit then
				if UnitIsUnit("target", namePlateUnit) == 1 then
					virtual.castGlow:Hide()
				end
			end
		end)
		castBar:HookScript("OnHide", function()
			virtual.castGlow:Hide()
		end)
	end
end

local function CreateClassIcon(virtual)
	if not virtual.classIcon then
		virtual.classIcon = virtual:CreateTexture(nil, "ARTWORK")	
		virtual.classIcon:SetSize(classIcon_size, classIcon_size)
		virtual.classIcon:SetPoint(classIcon_anchor, classIcon_Xoffset, classIcon_Yoffset + globalYoffset)
		virtual.classIcon:Hide()
	end
end

local function CreateDistanceText(virtual)
	if not virtual.distanceText then
		virtual.distanceText = virtual:CreateFontString(nil, "OVERLAY")
		virtual.distanceText:SetFont(fontPath, distanceText_fontSize, distanceText_fontFlags)
		virtual.distanceText:SetPoint(distanceText_anchor, virtual:GetChildren(), distanceText_Xoffset, distanceText_Yoffset)
		virtual.distanceText:SetTextColor(unpack(distanceText_color))
	end
end

function me.CustomizePlate(virtual)
	local threatGlow, healthBarBorder, castBarBorder, shieldCastBarBorder, spellIcon, healthBarHighlight, nameText, levelText, bossIcon, raidTargetIcon, eliteIcon = virtual:GetRegions()
	virtual.nameText = nameText
	virtual.levelText = levelText
	virtual.healthBar, virtual.castBar = virtual:GetChildren()
	virtual.healthBar.barTex = virtual.healthBar:GetRegions()
	virtual.castBar.barTex = virtual.castBar:GetRegions()
	virtual.castBarBorder = castBarBorder
	virtual.healthBarHighlight = healthBarHighlight
	CreateHealthBorder(virtual.healthBar)
	CreateNameText(virtual.healthBar)
	CreateTargetGlow(virtual.healthBar)
	CreateFocusGlow(virtual.healthBar)
	CreateHealthText(virtual.healthBar)
	CreateBarBackground(virtual.healthBar)
	CreateBarBackground(virtual.castBar)
	CreateCastText(virtual.castBar)
	CreateCastTimer(virtual.castBar)
	CreateCastGlow(virtual)
	CreateDistanceText(virtual)
	CreateClassIcon(virtual)
	healthBarBorder:Hide()
	nameText:Hide()
	threatGlow:SetTexture(nil)
	castBarBorder:SetTexture(texturePath .. "CastBar-Border")
	healthBarHighlight:SetTexture(texturePath .. "HealthBar-MouseoverGlow")
	healthBarHighlight:SetSize(NP_WIDTH, NP_HEIGHT)
	healthBarHighlight:SetAlpha(mouseoverGlow_alpha)
	bossIcon:ClearAllPoints()
	bossIcon:SetSize(bossIcon_size, bossIcon_size)
	bossIcon:SetPoint(bossIcon_anchor, bossIcon_Xoffset, bossIcon_Yoffset + globalYoffset)
	raidTargetIcon:ClearAllPoints()
	raidTargetIcon:SetSize(raidTargetIcon_size, raidTargetIcon_size)
	raidTargetIcon:SetPoint(raidTargetIcon_anchor, raidTargetIcon_Xoffset, raidTargetIcon_Yoffset + globalYoffset)
	eliteIcon:SetTexCoord(0.578125, 0, 0.578125, 0.84375, 0, 0, 0, 0.84375)
	eliteIcon:SetPoint("LEFT", 0, -11.5 + globalYoffset)
	virtual.healthBar.barTex:SetTexture(texturePath .. "NamePlate-BarFill")
	virtual.healthBar.barTex:SetDrawLayer("BORDER")
	virtual.castBar.barTex:SetTexture(texturePath .. "NamePlate-BarFill")
	local function virtualPlate_OnShow()
		castBarBorder:SetPoint("CENTER", 0, -19 + globalYoffset)
		castBarBorder:SetWidth(145)
		shieldCastBarBorder:SetWidth(145)
		healthBarHighlight:ClearAllPoints()
		healthBarHighlight:SetPoint("CENTER", 1.2, -8.7 + globalYoffset)
		levelText:Hide()
		virtual.healthBar.nameText:SetText(nameText:GetText())
		UpdateTargetGlow(virtual.healthBar)
		UpdateFocusGlow(virtual.healthBar)
	end
	virtualPlate_OnShow()
	virtual:HookScript("OnShow", virtualPlate_OnShow)
end

function me.SetupTotemPlate(Plate)
	if not Plate.totemPlate then
		local Virtual = VirtualPlates[Plate];
		Plate.totemPlate = CreateFrame("Frame", nil, Plate)
		Plate.totemPlate:SetPoint("CENTER", Virtual, 0, totemOffSet)
		Plate.totemPlate:SetSize(totemSize, totemSize)
		Plate.totemPlate:Hide()
		Plate.totemPlate.icon = Plate.totemPlate:CreateTexture(nil, "ARTWORK")
		Plate.totemPlate.icon:SetAllPoints(Plate.totemPlate)
		Plate.totemPlate.targetGlow = Plate.totemPlate:CreateTexture(nil, "OVERLAY")
		Plate.totemPlate.targetGlow:SetTexture(texturePath .. "TotemPlate-TargetGlow.blp")
		Plate.totemPlate.targetGlow:SetPoint("CENTER")
		Plate.totemPlate.targetGlow:SetSize(totemGlowSize, totemGlowSize)
		Plate.totemPlate.targetGlow:SetAlpha(targetGlow_alpha)
		Plate.totemPlate.targetGlow:Hide()
		Plate.totemPlate.mouseoverGlow = Plate.totemPlate:CreateTexture(nil, "OVERLAY")
		Plate.totemPlate.mouseoverGlow:SetTexture(texturePath .. "TotemPlate-MouseoverGlow.blp")
		Plate.totemPlate.mouseoverGlow:SetPoint("CENTER")
		Plate.totemPlate.mouseoverGlow:SetSize(totemGlowSize, totemGlowSize)
		Plate.totemPlate.mouseoverGlow:SetAlpha(mouseoverGlow_alpha)
		Plate.totemPlate.mouseoverGlow:Hide()
	end
end

local function IsNamePlate(frame)
    if frame:GetName() then return false end
    local region = select(2, frame:GetRegions())
    return region and region:GetTexture() == "Interface\\Tooltips\\Nameplate-Border"
end

local NamePlateUpdater = CreateFrame("Frame")
NamePlateUpdater:RegisterEvent("PLAYER_TARGET_CHANGED")
NamePlateUpdater:RegisterEvent("PLAYER_FOCUS_CHANGED")
if C_NamePlate then
	NamePlateUpdater:RegisterEvent("UNIT_SPELLCAST_START")
	NamePlateUpdater:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
end
NamePlateUpdater:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" then
		for _, frame in ipairs({ WorldFrame:GetChildren() }) do
			if IsNamePlate(frame) then
				local healthBar = select(1, frame:GetChildren())
				if event == "PLAYER_TARGET_CHANGED" then
					UpdateTargetGlow(healthBar)
				end
				UpdateFocusGlow(healthBar)
			end
		end
    elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
        local unitID, spellName = ...
		if unitID:match("^nameplate%d+$") then
			local virtual = VirtualPlates[C_NamePlate_GetNamePlateForUnit(unitID)]
			local castBar = virtual and select(2, virtual:GetChildren())
			if castBar then
				castBar.channeling = (event == "UNIT_SPELLCAST_CHANNEL_START")
			end
		end
	end
end)
