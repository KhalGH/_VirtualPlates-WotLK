--[[****************************************************************************
  * _VirtualPlates by Saiket                                                   *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]

if C_NamePlate and C_NamePlate.GetNamePlatesDistance then
	select( 2, ... ).L = setmetatable( {
		CONFIG_DESC = 	"Configure the way _VirtualPlates scales nameplates.\n" ..
					  	"Increase 'nameplateDistance' CVar to extend visibility range (current value: " .. GetCVar("nameplateDistance") .. ").\n\n" ..
					  	"Author: Saiket\nEnhanced version by |cffc41f3bKhal|r",
		CONFIG_LIMITS = "Nameplate Scale Limits",
		CONFIG_MAXSCALE = "Default Scale",
		CONFIG_MAXSCALEENABLED = "Change default size",
		CONFIG_MAXSCALEENABLED_DESC = "Adjusts the default nameplate size by this factor.",
		CONFIG_MINSCALE = "Minimum Scale",
		CONFIG_MINSCALE_DESC = "Defines how small nameplates can appear at long distances. The distance used for the minimum scale is based on the 'nameplateDistance' CVar, capped at 100 yds.",
		CONFIG_SCALEFACTOR = "Scaling Distance Threshold",
		CONFIG_SCALEFACTOR_DESC = "Nameplates closer than this distance show at default size. Beyond it, they gradually shrink.",
		CONFIG_SLIDER_FORMAT = "%.2f",
		CONFIG_SLIDERYARD_FORMAT = "%dyd",
		CONFIG_TITLE = "_|cffCCCC88VirtualPlates|r",
	}, {
		__index = function ( self, Key )
			if ( Key ~= nil ) then
				rawset( self, Key, Key );
				return Key;
			end
		end;
	} );
else
	select( 2, ... ).L = setmetatable( {
		CONFIG_DESC = "Configure the way _VirtualPlates scales nameplates.",
		CONFIG_LIMITS = "Nameplate Scale Limits",
		CONFIG_MAXSCALE = "Maximum",
		CONFIG_MAXSCALEENABLED = "Limit maximum scale",
		CONFIG_MAXSCALEENABLED_DESC = "Prevents nameplates from growing too large when they're near the screen.",
		CONFIG_MINSCALE = "Minimum",
		CONFIG_MINSCALE_DESC = "Limits how small nameplates can shrink, from 0 meaning no limit, to 1 meaning they won't shrink smaller than their default size.",
		CONFIG_SCALEFACTOR = "Scale Normalization Distance",
		CONFIG_SCALEFACTOR_DESC = "Nameplates this far from the camera will be normal sized.",
		CONFIG_SLIDER_FORMAT = "%.2f",
		CONFIG_SLIDERYARD_FORMAT = "%dyd",
		CONFIG_TITLE = "_|cffCCCC88VirtualPlates|r",
	}, {
		__index = function ( self, Key )
			if ( Key ~= nil ) then
				rawset( self, Key, Key );
				return Key;
			end
		end;
	} );
end
