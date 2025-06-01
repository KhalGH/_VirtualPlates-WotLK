--[[****************************************************************************
  * _VirtualPlates by Saiket                                                   *
  * Locales/Locale-zhTW.lua - Localized string constants (zh-TW).              *
  ****************************************************************************]]


if ( GetLocale() ~= "zhTW" ) then
	return;
end

if C_NamePlate and C_NamePlate.GetNamePlatesDistance then
	local _VirtualPlates = select( 2, ... );
	_VirtualPlates.L = setmetatable( {
		CONFIG_DESC = 	"設定 _VirtualPlates 如何縮放名條。\n" ..
						"增加 'nameplateDistance' CVar 以延長可視距離（目前值：" .. GetCVar("nameplateDistance") .. "）。\n\n" ..
						"作者：Saiket\n增強版本由 |cffc41f3bKhal|r 製作",
		CONFIG_LIMITS = "名條縮放限制",
		CONFIG_MAXSCALE = "預設縮放",
		CONFIG_MAXSCALEENABLED = "更改預設大小",
		CONFIG_MAXSCALEENABLED_DESC = "依此比例調整名條的預設大小。",
		CONFIG_MINSCALE = "最小縮放",
		CONFIG_MINSCALE_DESC = "定義名條在遠距離時可縮小的最小比例。最小縮放所依據的距離基於 'nameplateDistance' CVar，限制上限為100米。",
		CONFIG_SCALEFACTOR = "縮放距離門檻",
		CONFIG_SCALEFACTOR_DESC = "比此距離更近的名條會以預設大小顯示，超過則逐漸縮小。",
		CONFIG_SLIDER_FORMAT = "%.2f",
		CONFIG_SLIDERYARD_FORMAT = "%d米",
		CONFIG_TITLE = "_|cffCCCC88VirtualPlates|r",
	}, { __index = _VirtualPlates.L; } );	
else
	local _VirtualPlates = select( 2, ... );
	_VirtualPlates.L = setmetatable( {
		CONFIG_DESC = "設定 _VirtualPlates 如何縮放名條。",
		CONFIG_LIMITS = "名條縮放限制",
		CONFIG_MAXSCALE = "最大縮放",
		CONFIG_MAXSCALEENABLED = "限制最大縮放",
		CONFIG_MAXSCALEENABLED_DESC = "防止名條靠近畫面時變得過大。",
		CONFIG_MINSCALE = "最小值",
		CONFIG_MINSCALE_DESC = "限制名條最小縮放比例，0 表示無限制，1 表示不會縮小到小於預設大小。",
		CONFIG_SCALEFACTOR = "縮放歸一距離",
		CONFIG_SCALEFACTOR_DESC = "距離鏡頭此距離的名條會以正常大小顯示。",
		CONFIG_SLIDER_FORMAT = "%.2f",
		CONFIG_SLIDERYARD_FORMAT = "%d米",
		CONFIG_TITLE = "_|cffCCCC88VirtualPlates|r",
	}, { __index = _VirtualPlates.L; } );
end

