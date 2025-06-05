-------------------------------------------------------------------------------------------------
----------------------- VirtualPlates Appeareance Customization (by Khal) -----------------------
-------------------------------------------------------------------------------------------------

local me = select( 2, ... );

me.VirtualPlates = {}
local VirtualPlates = me.VirtualPlates
me.RealPlates = {}
local RealPlates = me.RealPlates

local C_NamePlate = C_NamePlate
local C_NamePlate_GetNamePlateForUnit = C_NamePlate and C_NamePlate.GetNamePlateForUnit
local C_NamePlate_GetNamePlatesDistance = C_NamePlate and C_NamePlate.GetNamePlatesDistance
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local texturePath = "Interface\\AddOns\\!!!_VirtualPlates\\Textures\\"
local fontPath = "Fonts\\ARIALN.TTF"
local fontSize = 9

me.globalYoffset = 25
local globalYoffset = me.globalYoffset

function me.IsNamePlate(frame)
    if frame:GetName() then return false end
    local region = select(2, frame:GetRegions())
    return region and region:GetTexture() == "Interface\\Tooltips\\Nameplate-Border"
end
local IsNamePlate = me.IsNamePlate

local function CreateHealthBorder(healthBar)
	if not healthBar.healthBarBorder then
		healthBar.healthBarBorder = healthBar:CreateTexture(nil, "ARTWORK")
		healthBar.healthBarBorder:SetTexture(texturePath .. "HealthBar-Border")
		healthBar.healthBarBorder:SetSize(156.65, 39.16)
		healthBar.healthBarBorder:SetPoint("CENTER", 10.5, 9)
	end
end

local function CreateNameText(healthBar)
	if not healthBar.nameText then
		healthBar.nameText = healthBar:CreateFontString(nil, "OVERLAY")
		healthBar.nameText:SetFont(fontPath, fontSize)
		healthBar.nameText:SetPoint("CENTER", 0.2, 0.7)
		healthBar.nameText:SetWidth(85)
		healthBar.nameText:SetTextColor(1, 1, 1)
		healthBar.nameText:SetShadowOffset(0.5, -0.5)
		healthBar.nameText:SetNonSpaceWrap(false)
		healthBar.nameText:SetWordWrap(false)
	end
end

local function CreateTargetGlow(healthBar)
	if not healthBar.targetGlow then
		healthBar.targetGlow = healthBar:CreateTexture(nil, "OVERLAY")	
		healthBar.targetGlow:SetTexture(texturePath .. "HealthBar-TargetGlow")
		healthBar.targetGlow:SetSize(156.65, 39.16)
		healthBar.targetGlow:SetPoint("CENTER", 0.7, 0.5)
		healthBar.targetGlow:Hide()
	end
end

local function CreateFocusGlow(healthBar)
	if not healthBar.focusGlow then
		healthBar.focusGlow = healthBar:CreateTexture(nil, "OVERLAY")	
		healthBar.focusGlow:SetTexture(texturePath .. "HealthBar-FocusGlow")
		healthBar.focusGlow:SetVertexColor(0.6, 0.2, 1)
		healthBar.focusGlow:SetSize(156.65, 39.16)
		healthBar.focusGlow:SetPoint("CENTER", 0.7, 0.5)
		healthBar.focusGlow:Hide()
	end
end

local function UpdateHealthText(healthBar)
	local min, max = healthBar:GetMinMaxValues()
	local value = healthBar:GetValue()
	if max > 0 then
		local percent = math.floor((value / max) * 100)
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
		healthBar.healthText:SetFont(fontPath, fontSize-0.2)
		healthBar.healthText:SetPoint("RIGHT", 0, 0.3)
		healthBar.healthText:SetTextColor(1, 1, 1)
		healthBar.healthText:SetShadowOffset(0.5, -0.5)
		UpdateHealthText(healthBar)
		healthBar:HookScript("OnValueChanged", UpdateHealthText)
		healthBar:HookScript("OnShow", UpdateHealthText)
	end
end

local function CreateBarBackground(Bar)
	if not Bar.BackgroundTex then
		Bar.BackgroundTex = Bar:CreateTexture(nil, "BACKGROUND")
		Bar.BackgroundTex:SetTexture(texturePath .. "NamePlate-Background")
		Bar.BackgroundTex:SetSize(156.65, 39.16)
		Bar.BackgroundTex:SetPoint("CENTER", 10.5, 9)
	end
end

local function CreateCastText(castBar)
	if not castBar.castText then
		castBar.castText = castBar:CreateFontString(nil, "OVERLAY")
		castBar.castText:SetFont(fontPath, fontSize)
		castBar.castText:SetPoint("CENTER", castBar, "CENTER", -3.8, 1.6)
		castBar.castText:SetWidth(90)
		castBar.castText:SetNonSpaceWrap(false)
		castBar.castText:SetWordWrap(false)
		castBar.castText:SetTextColor(1, 1, 1)
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
		castBar.castTimerText:SetFont(fontPath, fontSize-0.2)
		castBar.castTimerText:SetPoint("RIGHT", castBar, "RIGHT", -2, 1)
		castBar.castTimerText:SetTextColor(1, 1, 1)
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
		virtual.castGlow:SetVertexColor(1, 0, 0)
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
						virtual.castGlow:SetVertexColor(0.25, 0.75, 0.25)
					else
						virtual.castGlow:SetVertexColor(1, 0, 0)
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

local function CreateDistanceText(virtual)
	if not virtual.distanceText then
		virtual.distanceText = virtual:CreateFontString(nil, "OVERLAY")
		virtual.distanceText:SetFont(fontPath, fontSize + 2, "OUTLINE")
		virtual.distanceText:SetPoint("CENTER", virtual:GetChildren(), 0, 16)
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

local function CreateClassIcon(virtual)
	if not virtual.classIcon then
		virtual.classIcon = virtual:CreateTexture(nil, "ARTWORK")	
		virtual.classIcon:SetSize(26, 26)
		virtual.classIcon:SetPoint("LEFT", -9.6, -9 + globalYoffset)
		virtual.classIcon:Hide()
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

function me.CustomizePlate(virtual)
	local threatGlow, healthBarBorder, castBarBorder, shieldCastBarBorder, spellIcon, healthBarHighlight, nameText, levelText, bossIcon, raidTargetIcon, eliteIcon = virtual:GetRegions()
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
	healthBarHighlight:SetSize(156.65, 39.16)
	bossIcon:SetSize(18, 18)
	bossIcon:SetPoint("CENTER", 73.3, -9.2 + globalYoffset)
	raidTargetIcon:SetPoint("RIGHT", raidTargetIcon:GetParent(), "LEFT", 176, -9 + globalYoffset)
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
	virtual:SetScript("OnShow", virtualPlate_OnShow)
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