--[[****************************************************************************
  * _VirtualPlates by Saiket                                                   *
  * Locales/Locale-frFR.lua - Localized string constants (fr-FR).              *
  ****************************************************************************]]

if ( GetLocale() ~= "frFR" ) then
	return;
end

if C_NamePlate and C_NamePlate.GetNamePlatesDistance then
	local _VirtualPlates = select( 2, ... );
	_VirtualPlates.L = setmetatable( {
		CONFIG_DESC = 	"Configurez la façon dont _VirtualPlates met à l'échelle les barres de nom.\n" ..
						"Augmentez la variable CVar 'nameplateDistance' pour étendre la portée de visibilité (valeur actuelle : " .. GetCVar("nameplateDistance") .. ").\n\n" ..
						"Auteur : Saiket\nVersion améliorée par |cffc41f3bKhal|r",
		CONFIG_LIMITS = "Limites d'échelle des barres de nom",
		CONFIG_MAXSCALE = "Échelle par défaut",
		CONFIG_MAXSCALEENABLED = "Modifier la taille par défaut",
		CONFIG_MAXSCALEENABLED_DESC = "Ajuste la taille par défaut des barres de nom selon ce facteur.",
		CONFIG_MINSCALE = "Échelle minimale",
		CONFIG_MINSCALE_DESC = "Définit la taille minimale des barres de nom à longue distance. La distance utilisée pour l’échelle minimale est basée sur la CVar 'nameplateDistance', plafonnée à 100 yards.",
		CONFIG_SCALEFACTOR = "Seuil de distance pour la mise à l'échelle",
		CONFIG_SCALEFACTOR_DESC = "Les barres de nom plus proches que cette distance s'affichent à taille normale. Au-delà, elles rétrécissent progressivement.",
		CONFIG_SLIDER_FORMAT = "%.2f",
		CONFIG_SLIDERYARD_FORMAT = "%dm",
		CONFIG_TITLE = "_|cffCCCC88VirtualPlates|r",
	}, { __index = _VirtualPlates.L; } );
else
	local _VirtualPlates = select( 2, ... );
	_VirtualPlates.L = setmetatable( {
		CONFIG_DESC = "Configurez la façon dont _VirtualPlates met à l'échelle les barres de nom.",
		CONFIG_LIMITS = "Limites d'échelle des barres de nom",
		CONFIG_MAXSCALE = "Maximum",
		CONFIG_MAXSCALEENABLED = "Limiter l’échelle maximale",
		CONFIG_MAXSCALEENABLED_DESC = "Empêche les barres de nom de devenir trop grandes lorsqu'elles sont proches de l'écran.",
		CONFIG_MINSCALE = "Minimum",
		CONFIG_MINSCALE_DESC = "Limite la réduction minimale des barres de nom, de 0 signifiant pas de limite, à 1 signifiant qu'elles ne rétrécissent pas plus que leur taille par défaut.",
		CONFIG_SCALEFACTOR = "Distance de normalisation de l’échelle",
		CONFIG_SCALEFACTOR_DESC = "Les barres de nom à cette distance de la caméra auront une taille normale.",
		CONFIG_SLIDER_FORMAT = "%.2f",
		CONFIG_SLIDERYARD_FORMAT = "%dm",
		CONFIG_TITLE = "_|cffCCCC88VirtualPlates|r",
	}, { __index = _VirtualPlates.L; } );
end

