--[[
	*************************************************************************************
	*  _VirtualPlates by Saiket:                                                        *
	*     - Adds depth to the default nameplate frames.                                 *
	*  Additional features by Khal:                                                     *
	*     - Modified nameplate appearance.		                                        *
	*     - Support for nameplates API and events, with fallbacks when unavailable.     *
	*     - Improved nameplate scanning and handling.                                   *
	*     - Nameplate scaling is now based on distance to the player.                   *
	*	  - Optional distance text displayed on nameplates (/vpdist).					*
	*	  - Distance-based fading for some visual regions.								*
	*     - Custom glow for the target, focus and mouseover nameplates.                 *
	*     - Prioritized sorting for target and focus nameplates.                        *
	*************************************************************************************
]]

local AddOnName, me = ...;
_VirtualPlates = me;
me.Frame = CreateFrame( "Frame", nil, WorldFrame );

me.Version = GetAddOnMetadata( AddOnName, "Version" ):match( "^([%d.]+)" );

local VirtualPlates = {};
local RealPlates = {} 
me.Plates = VirtualPlates;
local PlatesVisible = {};
me.PlatesVisible = PlatesVisible;

me.OptionsCharacter = { };
me.OptionsCharacterDefault = {
	MinScale = 0.2;
	MaxScale = 1;
	MaxScaleEnabled = true;
	ScaleFactor = 41;
};

me.CameraClip = 4; -- Yards from camera when nameplates begin fading out
me.PlateLevels = 3; -- Frame level difference between plates so one plate's children don't overlap the next closest plate
me.UpdateRate = 0.05; -- Minimum time between plates are updated.

local InCombat = false;
local NextUpdate = 0;
local PlateOverrides = {}; -- [ MethodName ] = Function overrides for Virtuals

-------------------------------------------------------------------------------------------------
----------------------- VirtualPlates Appeareance Customization (by Khal) -----------------------
-------------------------------------------------------------------------------------------------

local C_NamePlate = C_NamePlate
local C_NamePlate_GetNamePlateForUnit = C_NamePlate and C_NamePlate.GetNamePlateForUnit
local C_NamePlate_GetNamePlatesDistance = C_NamePlate and C_NamePlate.GetNamePlatesDistance
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local fadeDistance = 80
local fadeRange = 20
local globalYoffset = 25
local texturePath = "Interface\\AddOns\\!!!_VirtualPlates\\Textures\\"
local fontPath = "Fonts\\ARIALN.TTF"
local fontSize = 9
local showDistanceText = false

local function IsNamePlate(frame)
    if frame:GetName() then return false end
    local region = select(2, frame:GetRegions())
    return region and region:GetTexture() == "Interface\\Tooltips\\Nameplate-Border"
end

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

local function CreateCastGlow(frame)
	if not frame.castGlow then
		frame.castGlow = frame:CreateTexture(nil, "OVERLAY")	
		frame.castGlow:SetTexture(texturePath .. "CastBar-Glow")
		frame.castGlow:SetTexCoord(0, 0.55, 0, 1)
		frame.castGlow:SetSize(159.5, 40)
		frame.castGlow:SetPoint("CENTER", 2.75, -27.5 + globalYoffset)
		frame.castGlow:SetVertexColor(1, 0, 0)
		frame.castGlow:Hide()
		local castBar = select(2, frame:GetChildren())
		local castBarBorder = select(3, frame:GetRegions())
		castBar:HookScript("OnShow", function()
			local namePlateUnit = RealPlates[frame].namePlateUnitToken
			if namePlateUnit then
				local namePlateTarget = UnitName(namePlateUnit.."target")
				if namePlateTarget == UnitName("player") and castBarBorder:IsShown() and not UnitIsUnit("target", namePlateUnit) then
					local reaction = UnitReaction("player", namePlateUnit)
					if reaction and reaction >= 5 then
						frame.castGlow:SetVertexColor(0.25, 0.75, 0.25)
					else
						frame.castGlow:SetVertexColor(1, 0, 0)
					end
					frame.castGlow:Show()
				end
			end
		end)
		castBar:HookScript("OnValueChanged", function()
			local namePlateUnit = RealPlates[frame].namePlateUnitToken
			if namePlateUnit then
				if UnitIsUnit("target", namePlateUnit) == 1 then
					frame.castGlow:Hide()
				end
			end
		end)
		castBar:HookScript("OnHide", function()
			frame.castGlow:Hide()
		end)
	end
end

local function CreateDistanceText(frame)
	if not frame.distanceText then
		frame.distanceText = frame:CreateFontString(nil, "OVERLAY")
		frame.distanceText:SetFont(fontPath, fontSize+2, "OUTLINE")
		frame.distanceText:SetPoint("RIGHT", frame:GetChildren(), "LEFT", -3, 1)
	end
end

local function UpdateTargetGlow(healthBar)
	healthBar.targetBorderDelay = healthBar.targetBorderDelay or CreateFrame("Frame")
	healthBar.targetBorderDelay:SetScript("OnUpdate", function(self, elapsed)
		self:SetScript("OnUpdate", nil)
		if C_NamePlate then
			if healthBar:GetParent() == VirtualPlates[C_NamePlate_GetNamePlateForUnit("target")] then		
				healthBar.targetGlow:Show()
			else
				healthBar.targetGlow:Hide()
			end			
		else
			if healthBar.nameText:GetText() == UnitName("target") and healthBar:GetParent():GetAlpha() == 1 then
				healthBar.targetGlow:Show()
			else
				healthBar.targetGlow:Hide()
			end
		end
	end)
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

local function CustomizePlate(frame)
	local threatGlow, healthBarBorder, castBarBorder, shieldCastBarBorder, spellIcon, healthBarHighlight, nameText, levelText, bossIcon, raidTargetIcon, eliteIcon = frame:GetRegions()
	local healthBar, castBar = frame:GetChildren()
	local healthBarTexture = healthBar:GetRegions()		
	local castBarTexture = castBar:GetRegions()	
	CreateHealthBorder(healthBar)
	CreateNameText(healthBar)
	CreateTargetGlow(healthBar)
	CreateFocusGlow(healthBar)
	CreateHealthText(healthBar)
	CreateBarBackground(healthBar)
	CreateBarBackground(castBar)
	CreateCastText(castBar)
	CreateCastTimer(castBar)
	CreateCastGlow(frame)
	CreateDistanceText(frame)
	healthBarBorder:Hide()
	nameText:Hide()
	castBarBorder:SetTexture(texturePath .. "CastBar-Border")
	healthBarHighlight:SetTexture(texturePath .. "HealthBar-MouseoverGlow")
	healthBarHighlight:SetSize(156.65, 39.16)
	bossIcon:SetSize(18, 18)
	bossIcon:SetPoint("CENTER", 73.3, -9.2 + globalYoffset)
	raidTargetIcon:SetPoint("RIGHT", raidTargetIcon:GetParent(), "LEFT", 13, -9 + globalYoffset)
	eliteIcon:SetTexCoord(0.578125, 0, 0.578125, 0.84375, 0, 0, 0, 0.84375)
	eliteIcon:SetPoint("LEFT", 0, -11.5 + globalYoffset)
	healthBarTexture:SetTexture(texturePath .. "NamePlate-BarFill")
	healthBarTexture:SetDrawLayer("BORDER")
	castBarTexture:SetTexture(texturePath .. "NamePlate-BarFill")
	local function virtualPlate_OnShow()
		castBarBorder:SetPoint("CENTER", 0, -19 + globalYoffset)
		castBarBorder:SetWidth(145)
		shieldCastBarBorder:SetWidth(145)
		healthBarHighlight:ClearAllPoints()
		healthBarHighlight:SetPoint("CENTER", 1.2, -8.7 + globalYoffset)
		levelText:Hide()
		healthBar.nameText:SetText(nameText:GetText())
		UpdateTargetGlow(healthBar)
		UpdateFocusGlow(healthBar)
	end
	virtualPlate_OnShow()
	frame:SetScript("OnShow", virtualPlate_OnShow)
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
			local virtualPlate = VirtualPlates[C_NamePlate_GetNamePlateForUnit(unitID)]
			local castBar = virtualPlate and select(2, virtualPlate:GetChildren())
			if castBar then
				castBar.channeling = (event == "UNIT_SPELLCAST_CHANNEL_START")
			end
		end
	end
end)

--------------------------------------------------------------------------------------------------------
----------------------------------------- _VirtualPlates Logic -----------------------------------------
--------------------------------------------------------------------------------------------------------

-- Individual plate methods
do
	--- If an anchor ataches to the original plate (by WoW), re-anchor to the Virtual.
	local function ResetPoint ( Plate, Region, Point, RelFrame, ... )
		if ( RelFrame == Plate ) then
			local point, xOfs, yOfs = ...
			Region:SetPoint( Point, VirtualPlates[ Plate ], point, xOfs + 11, yOfs + globalYoffset);
		end
	end

	--- Re-anchors regions when a plate is shown.
	-- WoW re-anchors most regions when it shows a nameplate, so restore those anchors to the Virtual frame.
	function me:PlateOnShow ()
		NextUpdate = 0; -- Resize instantly
		local Virtual = VirtualPlates[ self ];
		PlatesVisible[ self ] = Virtual;
		Virtual:Show();
		-- Reposition all regions
		for Index, Region in ipairs( self ) do
			for Point = 1, Region:GetNumPoints() do
				ResetPoint( self, Region, Region:GetPoint( Point ) );
			end
		end
	end
end
--- Removes the plate from the visible list when hidden.
function me:PlateOnHide ()
	PlatesVisible[ self ] = nil;
	VirtualPlates[ self ]:Hide(); -- Explicitly hide so IsShown returns false.
end

-- Main plate handling and updating	
do
	local WorldFrameGetChildren = WorldFrame.GetChildren;
	local select = select;
	do
		local PlatesUpdate;
		do
			local SortOrder, Depths, Distances = {}, {}, {};
			--- Subroutine for table.sort to depth-sort plate virtuals.
			local function SortFunc ( PlateA, PlateB )
				return Depths[ PlateA ] > Depths[ PlateB ];
			end

			local SetAlpha = me.Frame.SetAlpha; -- Must backup since plate SetAlpha methods are overridden
			local SetFrameLevel = me.Frame.SetFrameLevel;
			local SetScale = me.Frame.SetScale;
			local sort, wipe = sort, wipe;
			local ipairs = ipairs;

			local Depth, Virtual, Scale;
			local MinScale, MaxScale, ScaleFactor;
			--- Sorts, scales, and fades all nameplates based on depth.
			function PlatesUpdate ()
				for Plate, Virtual in pairs( PlatesVisible ) do
					Depth = Virtual:GetEffectiveDepth(); -- Note: Depth of the actual plate is blacklisted, so use child Virtual instead
					if ( Depth <= 0 ) then -- Too close to camera; Completely hidden
						SetAlpha( Virtual, 0 );
					else
						SortOrder[ #SortOrder + 1 ] = Plate;
						Depths[ Plate ] = Depth;
					end
				end

				Distances = C_NamePlate_GetNamePlatesDistance and C_NamePlate_GetNamePlatesDistance() -- by Khal

				if ( #SortOrder > 0 ) then
					MinScale, MaxScale = me.OptionsCharacter.MinScale or 0.2, me.OptionsCharacter.MaxScaleEnabled and me.OptionsCharacter.MaxScale;
					ScaleFactor = me.OptionsCharacter.ScaleFactor; -- This is actually a "camera depth" (distance) pivot at which nameplates are forced to normal scaling

					sort( SortOrder, SortFunc );

					------------ Move the target and focus nameplate to the top of the sort order (by Khal) ------------
					if C_NamePlate then
						local targetPlate = C_NamePlate_GetNamePlateForUnit("target")
						local focusPlate = C_NamePlate_GetNamePlateForUnit("focus")
						if targetPlate or focusPlate then
							local targetIndex, focusIndex
							for i, Plate in ipairs(SortOrder) do
								if targetPlate and Plate == targetPlate then
									targetIndex = i
									if not focusPlate then break end
								elseif focusPlate and Plate == focusPlate then
									focusIndex = i
									if not targetPlate then break end
								end
								if targetIndex and focusIndex then
									break
								end
							end
							if focusIndex and focusPlate ~= targetPlate then
								tremove(SortOrder, focusIndex)
								tinsert(SortOrder, focusPlate)
								if targetIndex and targetIndex > focusIndex then
									targetIndex = targetIndex - 1
								end
							end
							if targetIndex then
								tremove(SortOrder, targetIndex)
								tinsert(SortOrder, targetPlate)
							end							
						end
					else -- Fallback: match by name (less reliable)
						local TargetName = UnitName("target")
						if TargetName then
							local foundTarget = false
							for i, Plate in ipairs(SortOrder) do
								local region = Plate[9] -- nameText reference on RealPlate (index depends on the current customization)
								if region and region:IsObjectType("FontString") and region:GetText() == TargetName then
									tremove(SortOrder, i)
									tinsert(SortOrder, Plate)
									break
								end
							end
						end
					end
					---------------------------------------------------------------------------------------------------

					for Index, Plate in ipairs( SortOrder ) do
						Depth, Virtual = Depths[ Plate ], VirtualPlates[ Plate ];
						local _, _, castBarBorder, _, _, healthBarHighlight = Virtual:GetRegions()
						local healthBar, castBar = Virtual:GetChildren() -- by Khal


						if ( Depth < me.CameraClip ) then -- Begin fading as nameplate passes behind screen
							SetAlpha( Virtual, Depth / me.CameraClip );
						else
							SetAlpha( Virtual, 1 );
						end

						SetFrameLevel( Virtual, Index * me.PlateLevels );

						--------- Scales VirtualPlates and fades text/border based on real distance (by Khal) ---------
						if C_NamePlate_GetNamePlatesDistance then 
							local Distance = Distances[ Plate ]
							if showDistanceText then 
								Virtual.distanceText:SetText(string.format("%.0f", Distance)) 
							else
								Virtual.distanceText:SetText("") 
							end
							local minDistanceLimit = ScaleFactor -- Addon setting: originally a "camera depth" (distance)
							local maxDistanceLimit = math.min(tonumber(GetCVar("nameplateDistance")) or 41, 100)
							MaxScale = MaxScale or 1
							if minDistanceLimit < maxDistanceLimit then
								if Distance <= minDistanceLimit then
									Scale = MaxScale
								elseif Distance >= maxDistanceLimit then
									Scale = MinScale
								else
									local t = (Distance - minDistanceLimit) / (maxDistanceLimit - minDistanceLimit)
									Scale = MaxScale - t * (MaxScale - MinScale)
								end
							else
								Scale = MaxScale
							end
							if Distance then
								local alpha = math.max(0, math.min(1, 1 - ((Distance - (fadeDistance - fadeRange)) / fadeRange)))
								if healthBar.healthBarBorder then healthBar.healthBarBorder:SetAlpha(alpha) end	
								if healthBar.nameText then healthBar.nameText:SetAlpha(alpha) end	
								if healthBar.healthText then healthBar.healthText:SetAlpha(alpha) end	
								if castBar.castTimerText then castBar.castTimerText:SetAlpha(alpha) end	
								if castBar.castText then castBar.castText:SetAlpha(alpha) end	
								if castBarBorder then castBarBorder:SetAlpha(alpha) end
							end
						else -- Fallback: original scaling based on camera depth
							Scale = ScaleFactor / Depth;
							if ( Scale < MinScale ) then
								Scale = MinScale;
							elseif ( MaxScale and Scale > MaxScale ) then
								Scale = MaxScale;
							end
						end
						------------------------------------------------------------------------------------------------

						SetScale( Virtual, Scale );

						------------- Improved mouseover highlight handling (by Khal) -------------
						local nameTextAlpha = healthBar.nameText:GetAlpha()
						if C_NamePlate then
							if Plate == C_NamePlate_GetNamePlateForUnit("mouseover") and not UnitIsUnit("target","mouseover") then
								healthBarHighlight:Show()
								healthBar.nameText:SetTextColor(1, 1, 0, nameTextAlpha)
							else
								healthBarHighlight:Hide()
								healthBar.nameText:SetTextColor(1, 1, 1, nameTextAlpha)
							end
						else
							if healthBarHighlight:IsShown() then
								local name = select(1, UnitName("mouseover"))
								healthBar.nameText:SetTextColor(1, 1, 0, nameTextAlpha)
								if healthBar.nameText:GetText() ~= name then
									healthBarHighlight:Hide()
								end
							else
								healthBar.nameText:SetTextColor(1, 1, 1, nameTextAlpha)
							end
						end
						----------------------------------------------------------------------------

						if ( not InCombat ) then
							local Width, Height = Virtual:GetSize();
							Plate:SetSize( Width * Scale, Height * Scale );
						end
					end
					wipe( SortOrder );
				end
			end
		end

		--- Parents all plate children to the Virtual, and saves references to them in the plate.
		-- @ param Plate  Original nameplate children are being removed from.
		-- @ param ...  Children of Plate to be reparented.
		local function ReparentChildren ( Plate, ... )
			local Virtual = VirtualPlates[ Plate ];
			for Index = 1, select( "#", ... ) do
				local Child = select( Index, ... );
				if ( Child ~= Virtual ) then
					local LevelOffset = Child:GetFrameLevel() - Plate:GetFrameLevel();
					Child:SetParent( Virtual );
					Child:SetFrameLevel( Virtual:GetFrameLevel() + LevelOffset ); -- Maintain relative frame levels
					Plate[ #Plate + 1 ] = Child;
				end
			end
		end
		--- Parents all plate regions to the Virtual, similar to ReparentChildren.
		-- @ see ReparentChildren
		local function ReparentRegions ( Plate, ... )
			local Virtual = VirtualPlates[ Plate ];
			for Index = 1, select( "#", ... ) do
				local Region = select( Index, ... );
				Region:SetParent( Virtual );
				Plate[ #Plate + 1 ] = Region;
			end
		end

		--- Adds and skins a new nameplate.
		-- @ param Plate  Newly found default nameplate to be hooked.
		local function PlateAdd ( Plate )
			local Virtual = CreateFrame( "Frame", nil, Plate );

			VirtualPlates[ Plate ] = Virtual;
			RealPlates[ Virtual ] = Plate; -- by Khal
			Plate.VirtualPlate = Plate.VirtualPlate or Virtual -- by Khal
			Virtual.RealPlate = Virtual.RealPlate or Plate -- by Khal
			
			Virtual:Hide(); -- Gets explicitly shown on plate show
			Virtual:SetPoint( "TOP" );
			Virtual:SetSize( Plate:GetSize() );

			ReparentChildren( Plate, Plate:GetChildren() );
			ReparentRegions( Plate, Plate:GetRegions() );
			Virtual:EnableDrawLayer( "HIGHLIGHT" ); -- Allows the highlight to show without enabling mouse events

			Plate:SetScript( "OnShow", me.PlateOnShow );
			Plate:SetScript( "OnHide", me.PlateOnHide );

			if ( Plate:IsVisible() ) then
				me.PlateOnShow( Plate );
			end

			-- Hook methods
			for Key, Value in pairs( PlateOverrides ) do
				Virtual[ Key ] = Value;
			end

			CustomizePlate(Virtual) -- by Khal

			-- Force recalculation of effective depth for all child frames
			local Depth = WorldFrame:GetDepth();
			WorldFrame:SetDepth( Depth + 1 );
			WorldFrame:SetDepth( Depth );
		end

		------------------ Improved NamePlates Scan (by Khal) ------------------
		if C_NamePlate then
			local C_NamePlate_Events = CreateFrame("Frame")
			C_NamePlate_Events:RegisterEvent("NAME_PLATE_CREATED")
			C_NamePlate_Events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
			C_NamePlate_Events:SetScript("OnEvent", function(_, event, arg)
				if event == "NAME_PLATE_CREATED" then	
					local plateFrame = arg
					if not VirtualPlates[plateFrame] then
						PlateAdd(plateFrame)
					end
				elseif event == "NAME_PLATE_UNIT_ADDED" then
					local token = arg
					local frame = C_NamePlate.GetNamePlateForUnit(token)
					if frame and not frame.namePlateUnitToken then
						frame.namePlateUnitToken = token
					end
				end
			end)
		end
		local ChildCount, NewChildCount = 0;
		WorldFrame:HookScript("OnUpdate", function()
			NewChildCount = WorldFrame:GetNumChildren();
			if ChildCount ~= NewChildCount then
				local WFchildren = { WorldFrameGetChildren(WorldFrame) }
				for i = ChildCount + 1, NewChildCount do
					local child = WFchildren[i]
					if not VirtualPlates[child] and IsNamePlate(child) then
						PlateAdd(child)
					end
				end
				ChildCount = NewChildCount
			end
		end)
		----------------------------------------------------------------------

		function me:WorldFrameOnUpdate ( Elapsed )
			-- Apply depth to found plates
			NextUpdate = NextUpdate - Elapsed;
			if ( NextUpdate <= 0 ) then
				NextUpdate = me.UpdateRate;
				return PlatesUpdate();
			end
		end
	end

	local unpack = unpack;
	local Children = {};
	--- Filters the results of WorldFrame:GetChildren to replace plates with their virtuals.
	local function ReplaceChildren ( ... )
		local Count = select( "#", ... );
		for Index = 1, Count do
			local Frame = select( Index, ... );
			Children[ Index ] = VirtualPlates[ Frame ] or Frame;
		end
		for Index = Count + 1, #Children do -- Remove any extras from the last call
			Children[ Index ] = nil;
		end
		return unpack( Children );
	end
	--- Returns Virtual frames in place of real nameplates.
	-- @ return The results of WorldFrame:GetChildren with any reference to a plate replaced with its virtuals.
	function WorldFrame:GetChildren ( ... )
		return ReplaceChildren( WorldFrameGetChildren( self, ... ) );
	end
end

--- Initializes settings once loaded.
function me.Frame:ADDON_LOADED ( Event, AddOn )
	if ( AddOn == AddOnName ) then
		self:UnregisterEvent( Event );
		self[ Event ] = nil;

		local OptionsCharacter = _VirtualPlatesOptionsCharacter;
		_VirtualPlatesOptionsCharacter = me.OptionsCharacter;

		me.Synchronize( OptionsCharacter ); -- Loads defaults if either are nil

		print("_|cffCCCC88VirtualPlates|r modified version by |cffc41f3bKhal|r")
	end
end
--- Caches in-combat status when leaving combat.
function me.Frame:PLAYER_REGEN_ENABLED ()
	InCombat = false;
end
--- Restores plates to their real size before entering combat.
function me.Frame:PLAYER_REGEN_DISABLED ()
	InCombat = true;

	for Plate, Virtual in pairs( VirtualPlates ) do
		Plate:SetSize( Virtual:GetSize() );
	end
end
--- Global event handler.
function me.Frame:OnEvent ( Event, ... )
	if ( self[ Event ] ) then
		return self[ Event ]( self, Event, ... );
	end
end

--- Sets the minimum scale plates will be shrunk to.
-- @ param Value  New mimimum scale to use.
-- @ return True if setting changed.
function me.SetMinScale ( Value )
	if ( Value ~= me.OptionsCharacter.MinScale ) then
		me.OptionsCharacter.MinScale = Value;

		me.Config.MinScale:SetValue( Value );
		return true;
	end
end
--- Sets the maximum scale plates will grow to.
-- @ param Value  New maximum scale to use.
-- @ return True if setting changed.
function me.SetMaxScale ( Value )
	if ( Value ~= me.OptionsCharacter.MaxScale ) then
		me.OptionsCharacter.MaxScale = Value;

		me.Config.MaxScale:SetValue( Value );
		return true;
	end
end
--- Enables clamping nameplates to a maximum scale.
-- @ param Enable  Boolean to allow using the MaxScale setting.
-- @ return True if setting changed.
function me.SetMaxScaleEnabled ( Enable )
	if ( Enable ~= me.OptionsCharacter.MaxScaleEnabled ) then
		me.OptionsCharacter.MaxScaleEnabled = Enable;

		me.Config.MaxScaleEnabled:SetChecked( Enable );
		me.Config.MaxScaleEnabled.setFunc( Enable and "1" or "0" );
		return true;
	end
end
--- Sets the scale factor apply to plates.
-- @ param Value  When nameplates are this many yards from the screen, they'll be normal sized.
-- @ return True if setting changed.
function me.SetScaleFactor ( Value )
	if ( Value ~= me.OptionsCharacter.ScaleFactor ) then
		me.OptionsCharacter.ScaleFactor = Value;

		me.Config.ScaleFactor:SetValue( Value );
		return true;
	end
end

--- Synchronizes addon settings with an options table.
-- @ param OptionsCharacter  An options table to synchronize with, or nil to use defaults.
function me.Synchronize ( OptionsCharacter )
	-- Load defaults if settings omitted
	if ( not OptionsCharacter ) then
		OptionsCharacter = me.OptionsCharacterDefault;
	end

	me.SetMinScale( OptionsCharacter.MinScale );
	me.SetMaxScale( OptionsCharacter.MaxScale );
	me.SetMaxScaleEnabled( OptionsCharacter.MaxScaleEnabled );
	me.SetScaleFactor( OptionsCharacter.ScaleFactor );
end

WorldFrame:HookScript( "OnUpdate", me.WorldFrameOnUpdate ); -- First OnUpdate handler to run
me.Frame:SetScript( "OnEvent", me.Frame.OnEvent );
me.Frame:RegisterEvent( "ADDON_LOADED" );
me.Frame:RegisterEvent( "PLAYER_REGEN_DISABLED" );
me.Frame:RegisterEvent( "PLAYER_REGEN_ENABLED" );

local GetParent = me.Frame.GetParent;
do
	--- Add method overrides to be applied to plates' Virtuals.
	local function AddPlateOverride ( MethodName )
		PlateOverrides[ MethodName ] = function ( self, ... )
			local Plate = GetParent( self );
			return Plate[ MethodName ]( Plate, ... );
		end
	end
	AddPlateOverride( "GetParent" );
	AddPlateOverride( "SetAlpha" );
	AddPlateOverride( "GetAlpha" );
	AddPlateOverride( "GetEffectiveAlpha" );
end
-- Method overrides to use plates' OnUpdate script handlers instead of their Virtuals' to preserve handler execution order
do
	--- Wrapper for plate OnUpdate scripts to replace their self parameter with the plate's Virtual.
	local function OnUpdateOverride ( self, ... )
		self.OnUpdate( VirtualPlates[ self ], ... );
	end
	local type = type;

	local SetScript = me.Frame.SetScript;
	--- Redirects all SetScript calls for the OnUpdate handler to the original plate.
	function PlateOverrides:SetScript ( Script, Handler, ... )
		if ( type( Script ) == "string" and Script:lower() == "onupdate" ) then
			local Plate = GetParent( self );
			Plate.OnUpdate = Handler;
			return Plate:SetScript( Script, Handler and OnUpdateOverride or nil, ... );
		else
			return SetScript( self, Script, Handler, ... );
		end
	end

	local GetScript = me.Frame.GetScript;
	--- Redirects calls to GetScript for the OnUpdate handler to the original plate's script.
	function PlateOverrides:GetScript ( Script, ... )
		if ( type( Script ) == "string" and Script:lower() == "onupdate" ) then
			return GetParent( self ).OnUpdate;
		else
			return GetScript( self, Script, ... );
		end
	end

	local HookScript = me.Frame.HookScript;
	--- Redirects all HookScript calls for the OnUpdate handler to the original plate.
	-- Also passes the virtual to the hook script instead of the plate.
	function PlateOverrides:HookScript ( Script, Handler, ... )
		if ( type( Script ) == "string" and Script:lower() == "onupdate" ) then
			local Plate = GetParent( self );
			if ( Plate.OnUpdate ) then
				-- Hook old OnUpdate handler
				local Backup = Plate.OnUpdate;
				function Plate:OnUpdate ( ... )
					Backup( self, ... ); -- Technically we should return Backup's results to match HookScript's hook behavior,
					return Handler( self, ... ); -- but the overhead isn't worth it when these results get discarded.
				end
			else
				Plate.OnUpdate = Handler;
			end
			return Plate:SetScript( Script, OnUpdateOverride, ... );
		else
			return HookScript( self, Script, Handler, ... );
		end
	end
end

SLASH_VPDIST1 = "/vpdist"
SlashCmdList["VPDIST"] = function()
    showDistanceText = not showDistanceText
end