--[[****************************************************************************
  * _VirtualPlates by Saiket                                                   *
  * Locales/Locale-esES.lua - Localized string constants (es-ES).              *
  ****************************************************************************]]

if ( GetLocale() ~= "esES" ) then
	return;
end

if C_NamePlate and C_NamePlate.GetNamePlatesDistance then
	local _VirtualPlates = select( 2, ... );
	_VirtualPlates.L = setmetatable( {
		CONFIG_DESC = 	"Configura la forma en que _VirtualPlates escala los nameplates.\n" ..
					  	"Aumenta el CVar 'nameplateDistance' para extender el rango de visibilidad (valor actual: " .. GetCVar("nameplateDistance") .. ").\n\n" ..
					  	"Autor: Saiket\nVersión modificada por |cffc41f3bKhal|r",
		CONFIG_LIMITS = "Límites de Escalado de Nameplates",
		CONFIG_MAXSCALE = "Escala por defecto",
		CONFIG_MAXSCALEENABLED = "Cambiar el tamaño por defecto",
		CONFIG_MAXSCALEENABLED_DESC = "Ajusta el tamaño por defecto de los nameplates usando este factor",
		CONFIG_MINSCALE = "Escala Mínima",
		CONFIG_MINSCALE_DESC = "Define la escala mínima para nameplates a grandes distancias. La distancia asociada a la escala mínima es el CVar 'nameplateDistance' con un cap de 100 m.",
		CONFIG_SCALENORMDIST = "Distancia Umbral de Escalado",
		CONFIG_SCALENORMDIST_DESC = "Los nameplates más cercanos que esta distancia se mostrarán con su tamaño por defecto, y se reducirán gradualmente a medida que aumente la distancia por encima del umbral.",
		CONFIG_SLIDER_FORMAT = "%.2f",
		CONFIG_SLIDERYARD_FORMAT = "%dm",
		CONFIG_TITLE = "_|cffCCCC88VirtualPlates|r",
	}, { __index = _VirtualPlates.L; } );
else
	local _VirtualPlates = select( 2, ... );
	_VirtualPlates.L = setmetatable( {
		CONFIG_DESC = "Configura la forma en que _VirtualPlates escala los nameplates.",
		CONFIG_LIMITS = "Límites de Escalado de Nameplates",
		CONFIG_MAXSCALE = "Máximo",
		CONFIG_MAXSCALEENABLED = "Límite de escala máxima",
		CONFIG_MAXSCALEENABLED_DESC = "Previene que los nameplates se vuelvan muy grandes al estar cerca de la cámara.",
		CONFIG_MINSCALE = "Mínimo",
		CONFIG_MINSCALE_DESC = "Limita qué tanto pueden encogerse los nameplates, desde 0 (sin límite) hasta 1 (no podrán ser más pequeños que el tamaño por defecto).",
		CONFIG_SCALENORMDIST = "Distancia de Normalización de Escala",
		CONFIG_SCALENORMDIST_DESC = "Los nameplates a esta distancia de la cámara tendrán escala normal",
		CONFIG_SLIDER_FORMAT = "%.2f",
		CONFIG_SLIDERYARD_FORMAT = "%dm",
		CONFIG_TITLE = "_|cffCCCC88VirtualPlates|r",
	}, { __index = _VirtualPlates.L; } );
end
