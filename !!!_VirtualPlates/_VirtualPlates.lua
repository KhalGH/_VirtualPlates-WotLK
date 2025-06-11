--[[
	*************************************************************************************
	*  _VirtualPlates by Saiket:                                                        *
	*     - Adds depth to the default nameplate frames.                                 *
	*  Additional features by Khal:                                                     *
	*     - Modified nameplate appearance.                                              *
	*     - Support for nameplates API and events, with fallbacks when unavailable.     *
	*     - Improved nameplate scanning and handling.                                   *
	*     - Nameplate scaling is now based on distance to the player.                   *
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

me.OptionsCharacter = { };
me.OptionsCharacterDefault = {
	MinScale = 0.2;
	MaxScale = 1;
	MaxScaleEnabled = true;
	ScaleFactor = 33;
	ShowClassIcons = true; -- (/vpicons)
};

-- Lua API
local math_min, math_max, tonumber, select, sort, wipe, pairs, ipairs, unpack, tremove, tinsert =
      math.min, math.max, tonumber, select, sort, wipe, pairs, ipairs, unpack, tremove, tinsert
-- WoW API
local UnitReaction, UnitIsPlayer, UnitIsUnit, UnitName, UnitClass, CreateFrame =
      UnitReaction, UnitIsPlayer, UnitIsUnit, UnitName, UnitClass, CreateFrame
-- Custom WoW API
local C_NamePlate = C_NamePlate
local C_NamePlate_GetNamePlateForUnit = C_NamePlate and C_NamePlate.GetNamePlateForUnit
local C_NamePlate_GetNamePlatesDistance = C_NamePlate and C_NamePlate.GetNamePlatesDistance

-- Defined in _VirtualPlates_Customize.lua or Totems.xml
local VirtualPlates = me.VirtualPlates
local RealPlates = me.RealPlates
local TotemPlates = me.TotemPlates
local globalYoffset = me.globalYoffset
local texturePath = me.texturePath
local nameText_colorR, nameText_colorG, nameText_colorB = unpack(me.nameText_color)
local CustomizePlate = me.CustomizePlate
local SetupTotemPlate = me.SetupTotemPlate

-- Internal State and Constants
local PlatesVisible = {}
local PlateOverrides = {}; -- [ MethodName ] = Function overrides for Virtuals
local NextUpdate = 0
local totemsTexPath = texturePath .. "Totems\\"
local classesTexPath = texturePath .. "Classes\\"
local InCombat = false
local inPvPinstance = false
local showDistanceText = false -- Toggles the visibility of distance text (/vpdist)
local filterPlayers = false -- Toggles the visibility of non-player nameplates (/vpfilter)
local CameraClip = 4 -- Yards from camera when nameplates begin fading out
local PlateLevels = 3 -- Frame level difference between plates so one plate's children don't overlap the next closest plate

-- Configurable Settings
local distanceLimit = math_min(tonumber(GetCVar("nameplateDistance")) or 41, 100) -- Distance at which nameplates reach minimum scale
local fadeStart = 60 -- Distance at which nameplate regions start to fade (some regions for players, all regions for NPCs)
local fadeEnd = 80 -- Distance at which nameplate regions are fully faded out (some regions for players, all regions for NPCs)
local nameplateMinLevel = 10 -- Minimum level to show nameplate
local UpdateRate = 0.05 -- Minimum time between plates are updated.

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
	local WorldFrame_GetChildren = WorldFrame.GetChildren;
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
			local GetFrameLevel = me.Frame.GetFrameLevel;
			local SetScale = me.Frame.SetScale;

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
								local region = Plate[9] -- nameText reference on RealPlate
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

						local castBarBorder = Virtual.castBarBorder
						local classIcon = Virtual.classIcon
						local healthBarHighlight = Virtual.healthBarHighlight
						local healthBar = Virtual.healthBar
						local castBar = Virtual.castBar

						if ( Depth < CameraClip ) then -- Begin fading as nameplate passes behind screen
							SetAlpha( Virtual, Depth / CameraClip );
						else
							SetAlpha( Virtual, 1 );
						end

						SetFrameLevel( Virtual, Index * PlateLevels );

						-------------- Scales VirtualPlates and fades regions based on real distance (by Khal) --------------
						if C_NamePlate_GetNamePlatesDistance then 
							local Distance = Distances[ Plate ]
							local unitToken = Plate.namePlateUnitToken
							if showDistanceText then 
								Virtual.distanceText:SetText(string.format("%.0f yd", Distance)) 
							else
								Virtual.distanceText:SetText("") 
							end
							local minDistanceLimit = ScaleFactor -- Addon setting: originally a "camera depth" (distance)
							local maxDistanceLimit = distanceLimit
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
								local function SetRegionsAlpha(alpha)
									if healthBar.healthBarBorder then healthBar.healthBarBorder:SetAlpha(alpha) end
									if healthBar.nameText then healthBar.nameText:SetAlpha(alpha) end
									if healthBar.healthText then healthBar.healthText:SetAlpha(alpha) end
									if castBarBorder then castBarBorder:SetAlpha(alpha) end
									if castBar.castTimerText then castBar.castTimerText:SetAlpha(alpha) end
									if castBar.castText then castBar.castText:SetAlpha(alpha) end
									if classIcon then classIcon:SetAlpha(alpha) end
								end
								if Distance <= fadeEnd or UnitIsPlayer(unitToken) == 1 then
									local alpha = math_max(0, math_min(1, 1 - ((Distance - fadeStart) / (fadeEnd - fadeStart))))
									SetRegionsAlpha(alpha)
									SetAlpha(Virtual, 1)
								else
									local alpha = math_max(0, math_min(1, 1 - ((Distance - fadeEnd) / 30)))
									SetRegionsAlpha(0)
									SetAlpha(Virtual, alpha)
								end
							end
						else -- Fallback: original scaling based on camera depth
							Scale = ScaleFactor / Depth;
							if ( Scale < MinScale ) then
								Scale = MinScale;
							elseif ( MaxScale and Scale > MaxScale ) then
								Scale = MaxScale;
							end
						end
						------------------ TotemPlates Visual Update (by Khal) ------------------
						local totemTex = TotemPlates[healthBar.nameText:GetText()]
						if totemTex then
							if totemTex ~= "" then
								SetScale(Plate.totemPlate, Scale)
								SetFrameLevel(Plate.totemPlate, GetFrameLevel(Virtual))
								if C_NamePlate_GetNamePlatesDistance then
									local Distance = Distances[Plate]	
									if Distance and Plate.totemPlate then
										local alpha = math_max(0, math_min(1, 1 - ((Distance - fadeStart) / (fadeEnd - fadeStart))))
										SetAlpha(Plate.totemPlate, alpha)
									end
								end
							end
							Scale = 0.001 -- Shrinks the nameplate hitbox to effectively disable interaction
						end
						----------------------- Improved mouseover highlight handling (by Khal) -----------------------
						local nameText_alpha = healthBar.nameText:GetAlpha()
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
						----------------------------------------------------------------------------

						if not Virtual:IsShown() then 
							Scale = 0.001 -- Shrinks the nameplate hitbox to effectively disable interaction, by Khal
						end

						SetScale( Virtual, Scale );

						if ( not InCombat ) then
							local Width, Height = Virtual:GetSize();
							Plate:SetSize( 0.88 * Width * Scale, 0.8 * Height * Scale );
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
function me.SetScaleFactor ( Value )
	if ( Value ~= me.OptionsCharacter.ScaleFactor ) then
		me.OptionsCharacter.ScaleFactor = Value;

		me.Config.ScaleFactor:SetValue( Value );
		return true;
	end
end

--- by Khal
function me.SetShowClassIcons ( Enable )
	if ( Enable ~= me.OptionsCharacter.ShowClassIcons ) then
		me.OptionsCharacter.ShowClassIcons = Enable;
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
	me.SetShowClassIcons( OptionsCharacter.ShowClassIcons );
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
	if C_NamePlate then
		print("  |cffCCCC88============= _VirtualPlates Slash Commands =============|r")
		print("  |cff00FF98  /vpicons:|r Toggles the visibility of class icons in PvP instances.")
		print("  |cff00FF98  /vpfilter:|r Toggles the visibility of non-player nameplates.")
		if C_NamePlate_GetNamePlatesDistance then 
			print("  |cff00FF98  /vpdist:|r Toggles the visibility of distance text.") 
		end
		print("  |cffCCCC88=====================================================|r")
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
	end
end
