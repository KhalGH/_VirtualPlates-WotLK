--[[****************************************************************************
  * _VirtualPlates by Saiket                                                   *
  * Locales/Locale-ruRU.lua - Localized string constants (ru-RU).              *
  ****************************************************************************]]

if ( GetLocale() ~= "ruRU" ) then
	return;
end

if C_NamePlate and C_NamePlate.GetNamePlatesDistance then
	local _VirtualPlates = select( 2, ... );
	_VirtualPlates.L = setmetatable( {
		CONFIG_DESC = 	"Настройка масштабирования индикаторов здоровья через _VirtualPlates.\n" ..
					  	"Увеличьте 'nameplateDistance' для расширения дальности видимости (текущее: " .. GetCVar("nameplateDistance") .. ").\n\n" ..
					  	"Автор: Saiket\nУлучшенная версия от |cffc41f3bKhal|r",
		CONFIG_LIMITS = "Пределы масштабирования индикаторов",
		CONFIG_MAXSCALE = "Масштаб по умолчанию",
		CONFIG_MAXSCALEENABLED = "Изменить размер по умолчанию",
		CONFIG_MAXSCALEENABLED_DESC = "Настраивает масштаб индикаторов по умолчанию на указанный множитель.",
		CONFIG_MINSCALE = "Минимальный масштаб",
		CONFIG_MINSCALE_DESC = "Определяет, насколько маленькими могут быть индикаторы на большом расстоянии. Максимальная дистанция — 100 ярдов, определяется переменной 'nameplateDistance'.",
		CONFIG_SCALEFACTOR = "Порог дистанции масштабирования",
		CONFIG_SCALEFACTOR_DESC = "Индикаторы, находящиеся ближе этой дистанции, отображаются в обычном размере. Дальше — постепенно уменьшаются.",
		CONFIG_SLIDER_FORMAT = "%.2f",
		CONFIG_SLIDERYARD_FORMAT = "%dм",
		CONFIG_TITLE = "_|cffCCCC88VirtualPlates|r",
	}, { __index = _VirtualPlates.L; } );
else
	local _VirtualPlates = select( 2, ... );
	_VirtualPlates.L = setmetatable( {
		CONFIG_DESC = "Настройка масштабирования индикаторов здоровья через _VirtualPlates.",
		CONFIG_LIMITS = "Пределы масштабирования индикаторов",
		CONFIG_MAXSCALE = "Максимум",
		CONFIG_MAXSCALEENABLED = "Ограничить максимальный масштаб",
		CONFIG_MAXSCALEENABLED_DESC = "Предотвращает чрезмерное увеличение индикаторов при приближении к экрану.",
		CONFIG_MINSCALE = "Минимум",
		CONFIG_MINSCALE_DESC = "Ограничивает, насколько маленькими могут быть индикаторы: 0 — без ограничения, 1 — не меньше стандартного размера.",
		CONFIG_SCALEFACTOR = "Дистанция нормализации масштаба",
		CONFIG_SCALEFACTOR_DESC = "Индикаторы на таком расстоянии от камеры будут отображаться в обычном размере.",
		CONFIG_SLIDER_FORMAT = "%.2f",
		CONFIG_SLIDERYARD_FORMAT = "%dм",
		CONFIG_TITLE = "_|cffCCCC88VirtualPlates|r",
	}, { __index = _VirtualPlates.L; } );
end
