--[[****************************************************************************
  * _VirtualPlates by Saiket                                                   *
  * Locales/Locale-deDE.lua - Localized string constants (de-DE).              *
  ****************************************************************************]]

if ( GetLocale() ~= "deDE" ) then
	return;
end

if C_NamePlate and C_NamePlate.GetNamePlatesDistance then
	local _VirtualPlates = select( 2, ... );
	_VirtualPlates.L = setmetatable( {
		CONFIG_DESC = 	"Konfiguriere, wie _VirtualPlates Nameplates skaliert.\n" ..
					  	"Erhöhe den 'nameplateDistance'-CVar, um die Sichtweite zu erweitern (aktueller Wert: " .. GetCVar("nameplateDistance") .. ").\n\n" ..
					  	"Autor: Saiket\nErweiterte Version von |cffc41f3bKhal|r",
		CONFIG_LIMITS = "Grenzen der Nameplate-Skalierung",
		CONFIG_MAXSCALE = "Standardgröße",
		CONFIG_MAXSCALEENABLED = "Standardgröße ändern",
		CONFIG_MAXSCALEENABLED_DESC = "Passt die Standardgröße der Nameplates um diesen Faktor an.",
		CONFIG_MINSCALE = "Minimale Skalierung",
		CONFIG_MINSCALE_DESC = "Legt fest, wie klein Nameplates auf große Entfernungen werden können. Die maximale Entfernung beträgt 100 Meter und wird durch den CVar 'nameplateDistance' bestimmt.",
		CONFIG_SCALENORMDIST = "Abstand für Skalierungsschwelle",
		CONFIG_SCALENORMDIST_DESC = "Nameplates, die näher als dieser Abstand sind, werden in Standardgröße angezeigt. Darüber hinaus schrumpfen sie allmählich.",
		CONFIG_SLIDER_FORMAT = "%.2f",
		CONFIG_SLIDERYARD_FORMAT = "%dm",
		CONFIG_TITLE = "_|cffCCCC88VirtualPlates|r",
	}, { __index = _VirtualPlates.L; } );
else
	local _VirtualPlates = select( 2, ... );
	_VirtualPlates.L = setmetatable( {
		CONFIG_DESC = "Einstellungen der Nameplate-Skalierung durch _VirtualPlates.",
		CONFIG_LIMITS = "Nameplate Skalierungs-Limit",
		CONFIG_MAXSCALE = "Maximum",
		CONFIG_MAXSCALEENABLED = "Limitiert maximale Skalierung",
		CONFIG_MAXSCALEENABLED_DESC = "Verhindert das die Nameplates zu groß werden wenn die nah am Bildschirm sind.",
		CONFIG_MINSCALE = "Minimum",
		CONFIG_MINSCALE_DESC = "Limitiert wie klein Nameplates werden dürfen, von 0 also ohne Limit bis 1 also nicht kleiner als ihre Standard Größe.",
		CONFIG_SCALENORMDIST = "Distanz zur Skalierungsnormalisierung",
		CONFIG_SCALENORMDIST_DESC = "Nameplates in dieser Entfernung zur Kamera werden in normaler Größe dargestellt.",
		CONFIG_SLIDER_FORMAT = "%.2f",
		CONFIG_SLIDERYARD_FORMAT = "%dym",
		CONFIG_TITLE = "_|cffCCCC88VirtualPlates|r",
	}, { __index = _VirtualPlates.L; } );
end
