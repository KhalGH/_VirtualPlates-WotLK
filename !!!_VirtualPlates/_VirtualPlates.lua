--[[
	*************************************************************************************
	*  _VirtualPlates by Saiket:                                                        *
	*     - Adds depth to the default nameplate frames.                                 *
	*  Additional features by Khal:                                                     *
	*     - Modified nameplate appearance.                                              *
	*     - Support for nameplates custom API, with fallbacks when unavailable.         *
	*     - Improved nameplate scanning and handling.                                   *
	*     - Nameplate scaling is now based on distance to the player.                   *
	*     - Option to disable dynamic scaling if desired.                               *
	*     - Optional distance text displayed on nameplates.                             *
	*     - Custom glow for the target, focus and mouseover nameplates.                 *
	*     - Distance-based fading for some visual regions.                              *
	*     - Prioritized sorting for target and focus nameplates.                        *
	*     - TotemPlates-style functionality for totems and specific NPCs.               *
	*     - Optional class icons on friendly players in PvP instances.                  *
	*     - Optional player-only nameplate filter.                                      *
	*************************************************************************************
]]

local AddOnName, me = ...;
_VirtualPlates = me;
me.Frame = CreateFrame( "Frame", nil, WorldFrame );
me.Version = GetAddOnMetadata( AddOnName, "Version" ):match( "^([%d.]+)" );

-- Lua API
local math_min, math_max, tonumber, select, sort, wipe, pairs, ipairs, unpack, tremove, tinsert =
      math.min, math.max, tonumber, select, sort, wipe, pairs, ipairs, unpack, tremove, tinsert
-- WoW API
local GetCVar, CreateFrame, UnitReaction, UnitIsPlayer, UnitIsUnit, UnitName, UnitClass =
      GetCVar, CreateFrame, UnitReaction, UnitIsPlayer, UnitIsUnit, UnitName, UnitClass
-- Nameplates API
local C_NamePlate = C_NamePlate
local C_NamePlate_GetNamePlateForUnit = C_NamePlate and C_NamePlate.GetNamePlateForUnit
local C_NamePlate_GetNamePlatesDistance = C_NamePlate and C_NamePlate.GetNamePlatesDistance

me.OptionsCharacter = {}
me.OptionsCharacterDefault = {
	ScaleNormDist = 33;		-- Distance (or camera depth pivot) at which nameplates are forced to default scaling
	MinScale = 0.2;			-- Minimum scale factor for nameplates at long distances
	MaxScaleEnabled = true;	-- Enables/disables changing the default scale factor
	MaxScale = 1;			-- Default scale factor for nameplates at close range (defined by ScaleNormDist)
	DynamicScaling = true;	-- Enables/disables dynamic scaling of nameplates (/vpscale)
	ShowClassIcons = true;	-- Enables/disables class icons on allies in PvP instances (/vpicons)
}

-- Sensitive Settings (can be changed, but handle with care)
local distanceLimit = math_min(tonumber(GetCVar("nameplateDistance")) or 41, 100) -- Distance at which nameplates reach minimum scale
local fadeStart = 60 	-- Distance at which nameplate regions start to fade (some regions for players, all regions for NPCs)
local fadeEnd = 80 		-- Distance at which nameplate regions are fully faded out (some regions for players, all regions for NPCs)
local CameraClip = 4 	-- Yards from camera when nameplates begin fading out
local PlateLevels = 3 	-- Frame level difference between plates so one plate's children don't overlap the next closest plate
local UpdateRate = 0.05	-- Minimum time between plates are updated.

-- Defined in _VirtualPlates_Customize.lua or Totems.xml
local VirtualPlates = me.VirtualPlates
local RealPlates = me.RealPlates
local TotemPlates = me.TotemPlates
local NP_WIDTH = me.NP_WIDTH
local NP_HEIGHT = me.NP_HEIGHT
local globalYoffset = me.globalYoffset
local nameplateMinLevel = me.nameplateMinLevel
local texturePath = me.texturePath
local nameText_colorR, nameText_colorG, nameText_colorB = unpack(me.nameText_color)
local CustomizePlate = me.CustomizePlate
local SetupTotemPlate = me.SetupTotemPlate

-- Internal State and Constants
local PlatesVisible = {};
local PlateOverrides = {}; -- [ MethodName ] = Function overrides for Virtuals
local NextUpdate = 0
local totemsTexPath = texturePath .. "Totems\\"
local classesTexPath = texturePath .. "Classes\\"
local InCombat = false
local inPvPinstance = false
local showDistanceText = false -- Toggles the visibility of distance text (/vpdist)
local filterPlayers = false -- Toggles the visibility of non-player nameplates (/vpfilter)
me.PlatesVisible = PlatesVisible -- reference for _VirtualPlates_Config.lua

-- Backup of original methods
local WorldFrame_GetChildren = WorldFrame.GetChildren
local SetAlpha = me.Frame.SetAlpha
local SetFrameLevel = me.Frame.SetFrameLevel
local SetScale = me.Frame.SetScale

-- Individual plate methods
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
	------------------------ TotemPlates Handling (by Khal) ------------------------
	local nameText = Virtual.nameText:GetText()
	local totemTex = TotemPlates[nameText]
	if totemTex then
		if not self.totemPlate then
			SetupTotemPlate(self) -- Setup TotemPlate on the fly
		end
		Virtual:Hide()
		if C_NamePlate then
			-- Delay frame to ensure namePlateUnitToken is available and UnitReaction returns valid data
			self.delayFrame:SetScript("OnUpdate", function(delayFrame)
				delayFrame:SetScript("OnUpdate", nil)
				local unitToken = self.namePlateUnitToken
				if unitToken then
					local reaction = UnitReaction(unitToken, "player")
					local isHostile = reaction and reaction <= 4
					if totemTex ~= "" and isHostile then
						self.totemPlate:Show()
						self.totemPlate.icon:SetTexture(totemsTexPath .. totemTex)
					end	
				end
			end)
		elseif totemTex ~= "" then
			self.totemPlate:Show()
			self.totemPlate.icon:SetTexture(totemsTexPath .. totemTex)
		end
	else
		if self.totemPlate then self.totemPlate:Hide() end
		-------------- Nameplate Visibility Filter (by Khal) --------------
		local levelText = Virtual.levelText:GetText()
		local levelNumber = tonumber(levelText)
		if levelNumber and levelNumber < nameplateMinLevel then
			Virtual:Hide() -- Hide low level nameplates
		elseif C_NamePlate then
			-- Delay frame to ensure namePlateUnitToken is available and UnitIsPlayer returns valid data
			self.delayFrame:SetScript("OnUpdate", function(delayFrame)
				delayFrame:SetScript("OnUpdate", nil)
				local unitToken = self.namePlateUnitToken
				if unitToken then
					local isPlayer = UnitIsPlayer(unitToken) == 1
					if filterPlayers and not isPlayer then
						Virtual:Hide() -- Hide non-players nameplates
					else
						------------------- Show class icons on allies during PvP -------------------
						if Virtual.classIcon then
							local reaction = UnitReaction(unitToken, "player")
							local isFriendly = reaction and reaction >= 5
							local ShowClassIcons = me.OptionsCharacter.ShowClassIcons
							if isPlayer and isFriendly and inPvPinstance and ShowClassIcons then
								local class = select(2, UnitClass(unitToken))
								Virtual.classIcon:SetTexture(classesTexPath .. class)
								Virtual.classIcon:Show()
							else
								Virtual.classIcon:Hide()
							end
						end
					end
				end
			end)
		end	
	end
	if not me.OptionsCharacter.DynamicScaling then
		if totemTex then
			SetScale(Virtual, 0.001)
		else
			SetScale(Virtual, me.OptionsCharacter.MaxScaleEnabled and me.OptionsCharacter.MaxScale or 1)
		end
		if self.totemPlate then
			SetScale(self.totemPlate, me.OptionsCharacter.MaxScaleEnabled and me.OptionsCharacter.MaxScale or 1)
		end 
	end	
end
--- Removes the plate from the visible list when hidden.
function me:PlateOnHide ()
	PlatesVisible[ self ] = nil;
	local Virtual = VirtualPlates[ self ];
	if self.totemPlate then self.totemPlate:Hide() end
	if Virtual.classIcon then Virtual.classIcon:Hide() end
	Virtual:Hide(); -- Explicitly hide so IsShown returns false.
end

-- Main plate handling and updating	
do
	do
		local PlatesUpdate
		do
			local SortOrder, Depths = {}, {}
			local Virtual, Depth, Scale
			--- Subroutine for table.sort to depth-sort plate virtuals.
			local function SortFunc (PlateA, PlateB)
				return Depths[PlateA] > Depths[PlateB]
			end
			--- Sorts, scales, and fades all nameplates based on distance or depth.
			function PlatesUpdate()
				for Plate, Virtual in pairs(PlatesVisible) do
					Depth = Virtual:GetEffectiveDepth() -- Note: Depth of the actual plate is blacklisted, so use child Virtual instead
					if Depth <= 0 then -- Too close to camera; Completely hidden
						SetAlpha(Virtual, 0)
					else
						SortOrder[#SortOrder + 1] = Plate
						Depths[Plate] = Depth
					end
				end
				if #SortOrder > 0 then
					sort(SortOrder, SortFunc)
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
								local region = Plate[9] -- nameText reference on RealPlate
								if region and region:IsObjectType("FontString") and region:GetText() == TargetName then
									tremove(SortOrder, i)
									tinsert(SortOrder, Plate)
									break
								end
							end
						end
					end
					-------------- Scales and fades VirtualPlates based on real distance (by Khal) --------------
					if me.OptionsCharacter.DynamicScaling then
						local MinScale = me.OptionsCharacter.MinScale or 0.2
						local MaxScale = me.OptionsCharacter.MaxScaleEnabled and me.OptionsCharacter.MaxScale
						local ScaleNormDist = me.OptionsCharacter.ScaleNormDist
						local Distances = C_NamePlate_GetNamePlatesDistance and C_NamePlate_GetNamePlatesDistance()
						for Index, Plate in ipairs(SortOrder) do
							Virtual, Depth = VirtualPlates[Plate], Depths[Plate]
							local Distance = Distances and Distances[Plate]
							local healthBar = Virtual.healthBar
							local castBar = Virtual.castBar
							local castBarBorder = Virtual.castBarBorder
							local healthBarHighlight = Virtual.healthBarHighlight
							local classIcon = Virtual.classIcon
							local nameText_alpha = 1
							local totemPlate_alpha
							if Distance then
								if showDistanceText then 
									Virtual.distanceText:SetText(string.format("%.0f yd", Distance)) 
								end
								local function SetRegionsAlpha(alpha)
									if healthBar.healthBarBorder then healthBar.healthBarBorder:SetAlpha(alpha) end
									if healthBar.nameText then healthBar.nameText:SetAlpha(alpha) end
									if healthBar.healthText then healthBar.healthText:SetAlpha(alpha) end
									if castBarBorder then castBarBorder:SetAlpha(alpha) end
									if castBar.castTimerText then castBar.castTimerText:SetAlpha(alpha) end
									if castBar.castText then castBar.castText:SetAlpha(alpha) end
									if classIcon then classIcon:SetAlpha(alpha) end
								end
								if Depth > CameraClip then
									if Distance <= fadeEnd or UnitIsPlayer(Plate.namePlateUnitToken) == 1 then
										local alpha = math_max(0, math_min(1, 1 - ((Distance - fadeStart) / (fadeEnd - fadeStart))))
										SetRegionsAlpha(alpha)
										SetAlpha(Virtual, 1)
										nameText_alpha = alpha
										totemPlate_alpha = alpha
									else
										local alpha = math_max(0, math_min(1, 1 - ((Distance - fadeEnd) / 30)))
										SetRegionsAlpha(0)
										SetAlpha(Virtual, alpha)
										nameText_alpha = 0
									end
								else -- Begin fading as nameplate passes behind screen
									SetRegionsAlpha(1)
									SetAlpha(Virtual, Depth/CameraClip)
								end
								MaxScale = MaxScale or 1
								if ScaleNormDist < distanceLimit then
									if Distance <= ScaleNormDist then
										Scale = MaxScale
									elseif Distance >= distanceLimit then
										Scale = MinScale
									else
										Scale = MaxScale - (MaxScale - MinScale) * (Distance - ScaleNormDist) / (distanceLimit - ScaleNormDist)
									end
								else
									Scale = MaxScale
								end
							else -- Fallback: original scaling based on camera depth
								Scale = ScaleNormDist / Depth
								if Scale < MinScale then
									Scale = MinScale
								elseif MaxScale and Scale > MaxScale then
									Scale = MaxScale
								end
							end
							------------------ TotemPlates Visual Update (by Khal) ------------------
							local totemTex = TotemPlates[healthBar.nameText:GetText()]
							if Plate.totemPlate and totemTex then
								if totemTex ~= "" then
									SetScale(Plate.totemPlate, Scale)
									SetFrameLevel(Plate.totemPlate, Index * PlateLevels)
									if Distance then
										local alpha = totemPlate_alpha or math_max(0, math_min(1, 1 - ((Distance - fadeStart) / (fadeEnd - fadeStart))))
										SetAlpha(Plate.totemPlate, alpha)
									end
								end
								Scale = 0.001 -- Shrinks the nameplate hitbox to effectively disable interaction
							end
							----------------------- Improved mouseover highlight handling (by Khal) -----------------------
							if C_NamePlate then
								if Plate == C_NamePlate_GetNamePlateForUnit("mouseover") and not UnitIsUnit("target","mouseover") then
									healthBarHighlight:Show()
									healthBar.nameText:SetTextColor(1, 1, 0, nameText_alpha) -- yellow
									if Plate.totemPlate then Plate.totemPlate.mouseoverGlow:Show() end
								else
									healthBarHighlight:Hide()
									healthBar.nameText:SetTextColor(nameText_colorR, nameText_colorG, nameText_colorB, nameText_alpha)
									if Plate.totemPlate then Plate.totemPlate.mouseoverGlow:Hide() end
								end
							else
								if healthBarHighlight:IsShown() then
									local name = select(1, UnitName("mouseover"))
									healthBar.nameText:SetTextColor(1, 1, 0, nameText_alpha) -- yellow
									if healthBar.nameText:GetText() ~= name then
										healthBarHighlight:Hide()
									end
								else
									healthBar.nameText:SetTextColor(nameText_colorR, nameText_colorG, nameText_colorB, nameText_alpha)
								end
							end
							if not Virtual:IsShown() then 
								Scale = 0.001
							end
							SetScale(Virtual, Scale)
							SetFrameLevel(Virtual, Index * PlateLevels)
							if not InCombat then
								local Width, Height = Virtual:GetSize()
								Plate:SetSize(0.88 * Width * Scale, 0.8 * Height * Scale)
							end
						end
					else
						local Distances = showDistanceText and C_NamePlate_GetNamePlatesDistance and C_NamePlate_GetNamePlatesDistance()		
						for Index, Plate in ipairs( SortOrder ) do
							Depth, Virtual = Depths[ Plate ], VirtualPlates[ Plate ];
							if ( Depth < CameraClip ) then -- Begin fading as nameplate passes behind screen
								SetAlpha( Virtual, Depth / CameraClip );
							else
								SetAlpha( Virtual, 1 );
							end
							SetFrameLevel( Virtual, Index * PlateLevels );
							--------------------- Distance Text Update (by Khal) ---------------------
							if Distances then
								Virtual.distanceText:SetText(string.format("%.0f yd", Distances[Plate])) 
							end
							------------------ TotemPlates Visual Update (by Khal) ------------------
							local healthBar = Virtual.healthBar
							local totemTex = TotemPlates[healthBar.nameText:GetText()]
							if Plate.totemPlate and totemTex and totemTex ~= "" then
								SetFrameLevel(Plate.totemPlate, Index * PlateLevels)
							end
							----------------------- Improved mouseover highlight handling (by Khal) -----------------------
							local healthBarHighlight = Virtual.healthBarHighlight
							if C_NamePlate then
								if Plate == C_NamePlate_GetNamePlateForUnit("mouseover") and not UnitIsUnit("target","mouseover") then
									healthBarHighlight:Show()
									healthBar.nameText:SetTextColor(1, 1, 0, 1) -- yellow
									if Plate.totemPlate then Plate.totemPlate.mouseoverGlow:Show() end
								else
									healthBarHighlight:Hide()
									healthBar.nameText:SetTextColor(nameText_colorR, nameText_colorG, nameText_colorB, 1)
									if Plate.totemPlate then Plate.totemPlate.mouseoverGlow:Hide() end
								end
							else
								if healthBarHighlight:IsShown() then
									local name = select(1, UnitName("mouseover"))
									healthBar.nameText:SetTextColor(1, 1, 0, 1) -- yellow
									if healthBar.nameText:GetText() ~= name then
										healthBarHighlight:Hide()
									end
								else
									healthBar.nameText:SetTextColor(nameText_colorR, nameText_colorG, nameText_colorB, 1)
								end
							end
						end
					end
					wipe(SortOrder)
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

		-- Creates a semi-transparent hitbox texture for debugging
		local function SetupHitboxTexture(Plate)
			Plate.hitBox = Plate:CreateTexture(nil, "BACKGROUND")
			Plate.hitBox:SetTexture(0,0,0,0.5)
			Plate.hitBox:SetAllPoints(Plate)
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

			-- Hook methods
			for Key, Value in pairs( PlateOverrides ) do
				Virtual[ Key ] = Value;
			end

			CustomizePlate(Virtual)
			Plate.delayFrame = CreateFrame("Frame")
			--SetupHitboxTexture(Plate)

			if not C_NamePlate then
				if Plate:IsVisible() then
					me.PlateOnShow(Plate);
				end
			end

			-- Force recalculation of effective depth for all child frames
			local Depth = WorldFrame:GetDepth();
			WorldFrame:SetDepth( Depth + 1 );
			WorldFrame:SetDepth( Depth );
		end

		------------------ Improved NamePlates Scan (by Khal) ------------------
		local function IsNamePlate(frame)
			if frame:GetName() then return false end
			local region = select(2, frame:GetRegions())
			return region and region:GetTexture() == "Interface\\Tooltips\\Nameplate-Border"
		end
		if C_NamePlate then
			local C_NamePlate_Events = CreateFrame("Frame")
			C_NamePlate_Events:RegisterEvent("NAME_PLATE_CREATED")
			C_NamePlate_Events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
			C_NamePlate_Events:SetScript("OnEvent", function(_, event, arg)
				if event == "NAME_PLATE_CREATED" then	
					local Plate = arg
					if not VirtualPlates[Plate] then
						PlateAdd(Plate)
					end
				elseif event == "NAME_PLATE_UNIT_ADDED" then
					local token = arg
					local Plate = C_NamePlate_GetNamePlateForUnit(token)
					if Plate and not Plate.namePlateUnitToken then
						Plate.namePlateUnitToken = token
						if Plate:IsVisible() then
							me.PlateOnShow(Plate);
						end
					end
				end
			end)
		end
		local ChildCount, NewChildCount = 0;
		WorldFrame:HookScript("OnUpdate", function()
			NewChildCount = WorldFrame:GetNumChildren();
			if ChildCount ~= NewChildCount then
				local WFchildren = { WorldFrame_GetChildren(WorldFrame) }
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
				NextUpdate = UpdateRate;
				return PlatesUpdate();
			end
		end
	end

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
		return ReplaceChildren( WorldFrame_GetChildren( self, ... ) );
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

		print("_|cffCCCC88VirtualPlates|r modified v" .. me.Version .. " by |cffc41f3bKhal|r")
	end
end
--- Caches in-combat status when leaving combat.
function me.Frame:PLAYER_REGEN_ENABLED ()
	InCombat = false;
end
--- Restores plates to their real size before entering combat.
function me.Frame:PLAYER_REGEN_DISABLED ()
	InCombat = true;
end
--- Tracks PvP instance
function me.Frame:PLAYER_ENTERING_WORLD ()
	local instanceType = select(2, IsInInstance())
	inPvPinstance = (instanceType == "pvp")
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
function me.SetScaleNormDist ( Value )
	if ( Value ~= me.OptionsCharacter.ScaleNormDist ) then
		me.OptionsCharacter.ScaleNormDist = Value;

		me.Config.ScaleNormDist:SetValue( Value );
		return true;
	end
end

function me.SetShowClassIcons ( Enable )
	if ( Enable ~= me.OptionsCharacter.ShowClassIcons ) then
		me.OptionsCharacter.ShowClassIcons = Enable;
		return true;
	end
end

function me.SetDynamicScaling ( Enable )
	if ( Enable ~= me.OptionsCharacter.DynamicScaling ) then
		me.OptionsCharacter.DynamicScaling = Enable;
		return true;
	end
end

--- Synchronizes addon settings with an options table.
-- @ param OptionsCharacter  An options table to synchronize with, or nil to use defaults.
function me.Synchronize ( OptionsCharacter )
	-- Load defaults if settings omitted
	if not OptionsCharacter then
		OptionsCharacter = me.OptionsCharacterDefault;
	end

	for key, defaultValue in pairs(me.OptionsCharacterDefault) do
		if OptionsCharacter[key] == nil then
			OptionsCharacter[key] = defaultValue
		end
	end

	me.SetMinScale( OptionsCharacter.MinScale );
	me.SetMaxScale( OptionsCharacter.MaxScale );
	me.SetMaxScaleEnabled( OptionsCharacter.MaxScaleEnabled );
	me.SetScaleNormDist( OptionsCharacter.ScaleNormDist );
	me.SetShowClassIcons( OptionsCharacter.ShowClassIcons );
	me.SetDynamicScaling( OptionsCharacter.DynamicScaling );
end

WorldFrame:HookScript( "OnUpdate", me.WorldFrameOnUpdate ); -- First OnUpdate handler to run
me.Frame:SetScript( "OnEvent", me.Frame.OnEvent );
me.Frame:RegisterEvent( "ADDON_LOADED" );
me.Frame:RegisterEvent( "PLAYER_REGEN_DISABLED" );
me.Frame:RegisterEvent( "PLAYER_REGEN_ENABLED" );
me.Frame:RegisterEvent( "PLAYER_ENTERING_WORLD" );

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

SLASH_VP1 = "/vp"
SlashCmdList["VP"] = function()
	print("  |cffCCCC88============= _VirtualPlates Slash Commands =============|r")
	print("  |cff00FF98  /vpscale:|r Toggles on/off VirtualPlates dynamic scaling.")
	if C_NamePlate then
		print("  |cff00FF98  /vpicons:|r Toggles the visibility of class icons in PvP instances.")
		print("  |cff00FF98  /vpfilter:|r Toggles the visibility of non-player nameplates.")
		if C_NamePlate_GetNamePlatesDistance then 
			print("  |cff00FF98  /vpdist:|r Toggles the visibility of distance text.") 
		end
	end
	print("  |cffCCCC88=====================================================|r")
end
SLASH_VPSCALE1 = "/vpscale"
SlashCmdList["VPSCALE"] = function()
	me.OptionsCharacter.DynamicScaling = not me.OptionsCharacter.DynamicScaling
	if me.OptionsCharacter.DynamicScaling then
		print("_|cffCCCC88VirtualPlates|r: Dynamic scaling |cff88FF88enabled|r")
	else
		for Plate, Virtual in pairs(VirtualPlates) do
			local castBarBorder = Virtual.castBarBorder
			local classIcon = Virtual.classIcon
			local healthBar = Virtual.healthBar
			local castBar = Virtual.castBar
			if healthBar.healthBarBorder then healthBar.healthBarBorder:SetAlpha(1) end
			if healthBar.nameText then healthBar.nameText:SetAlpha(1) end
			if healthBar.healthText then healthBar.healthText:SetAlpha(1) end
			if castBarBorder then castBarBorder:SetAlpha(1) end
			if castBar.castTimerText then castBar.castTimerText:SetAlpha(1) end
			if castBar.castText then castBar.castText:SetAlpha(1) end
			if classIcon then classIcon:SetAlpha(1) end
			SetAlpha(Virtual, 1)
			if TotemPlates[healthBar.nameText:GetText()] then
				SetScale(Virtual, 0.001)
			else
				SetScale(Virtual, me.OptionsCharacter.MaxScaleEnabled and me.OptionsCharacter.MaxScale or 1)
			end
			if Plate.totemPlate then
				SetAlpha(Plate.totemPlate, 1)
				SetScale(Plate.totemPlate, me.OptionsCharacter.MaxScaleEnabled and me.OptionsCharacter.MaxScale or 1)
			end
			if not InCombat then
				Plate:SetSize(NP_WIDTH, NP_HEIGHT)
			end
		end
		print("_|cffCCCC88VirtualPlates|r: Dynamic scaling |cffff4444disabled|r")
	end
end
SLASH_VPICONS1 = "/vpicons"
SlashCmdList["VPICONS"] = function()
	if C_NamePlate then
		me.OptionsCharacter.ShowClassIcons = not me.OptionsCharacter.ShowClassIcons
		for Plate, _ in pairs(PlatesVisible) do
            me.PlateOnShow(Plate)
        end	
		if me.OptionsCharacter.ShowClassIcons then
			print("_|cffCCCC88VirtualPlates|r: Class icons in PvP instance |cff88FF88enabled|r")
		else
			print("_|cffCCCC88VirtualPlates|r: Class icons in PvP instance |cffff4444disabled|r")
		end
	end
end
SLASH_VPFILTER1 = "/vpfilter"
SlashCmdList["VPFILTER"] = function()
	if C_NamePlate then
		filterPlayers = not filterPlayers
		for Plate, _ in pairs(PlatesVisible) do
            me.PlateOnShow(Plate)
        end
		if filterPlayers then
			print("_|cffCCCC88VirtualPlates|r: Player filter |cff88FF88enabled|r")
		else
			print("_|cffCCCC88VirtualPlates|r: Player filter |cffff4444disabled|r")
		end
	end
end
SLASH_VPDIST1 = "/vpdist"
SlashCmdList["VPDIST"] = function()
	if C_NamePlate_GetNamePlatesDistance then
		showDistanceText = not showDistanceText
		if not showDistanceText then
			for _, Virtual in pairs(VirtualPlates) do
				if Virtual.distanceText then
					Virtual.distanceText:SetText("")
				end
			end
		end
	end
end