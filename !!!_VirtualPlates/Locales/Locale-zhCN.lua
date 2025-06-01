--[[****************************************************************************
  * _VirtualPlates by Saiket                                                   *
  * Locales/Locale-zhCN.lua - Localized string constants (zh-CN).              *
  ****************************************************************************]]


if ( GetLocale() ~= "zhCN" ) then
	return;
end

if C_NamePlate and C_NamePlate.GetNamePlatesDistance then
	local _VirtualPlates = select( 2, ... );
	_VirtualPlates.L = setmetatable( {
		CONFIG_DESC = 	"配置 _VirtualPlates 如何缩放姓名板。\n" ..
						"增加 'nameplateDistance' CVar 来扩展可见距离（当前值：" .. GetCVar("nameplateDistance") .. "）。\n\n" ..
						"作者: Saiket\n增强版本由 |cffc41f3bKhal|r 提供",
		CONFIG_LIMITS = "姓名板缩放限制",
		CONFIG_MAXSCALE = "默认缩放",
		CONFIG_MAXSCALEENABLED = "更改默认大小",
		CONFIG_MAXSCALEENABLED_DESC = "按此比例调整姓名板的默认大小。",
		CONFIG_MINSCALE = "最小缩放",
		CONFIG_MINSCALE_DESC = "定义远距离时姓名板最小的显示比例。最小缩放对应的距离基于 'nameplateDistance' CVar，最大限制为100米。",
		CONFIG_SCALEFACTOR = "缩放距离阈值",
		CONFIG_SCALEFACTOR_DESC = "比此距离更近的姓名板显示默认大小，超过则逐渐缩小。",
		CONFIG_SLIDER_FORMAT = "%.2f",
		CONFIG_SLIDERYARD_FORMAT = "%d米",
		CONFIG_TITLE = "_|cffCCCC88VirtualPlates|r",
	}, { __index = _VirtualPlates.L; } );	
else
	local _VirtualPlates = select( 2, ... );
	_VirtualPlates.L = setmetatable( {
		CONFIG_DESC = "配置 _VirtualPlates 如何缩放姓名板。",
		CONFIG_LIMITS = "姓名板缩放限制",
		CONFIG_MAXSCALE = "最大缩放",
		CONFIG_MAXSCALEENABLED = "限制最大缩放",
		CONFIG_MAXSCALEENABLED_DESC = "防止姓名板靠近屏幕时变得过大。",
		CONFIG_MINSCALE = "最小值",
		CONFIG_MINSCALE_DESC = "限制姓名板最小缩放比例，0 表示无限制，1 表示不小于默认大小。",
		CONFIG_SCALEFACTOR = "缩放归一距离",
		CONFIG_SCALEFACTOR_DESC = "距离摄像机该距离的姓名板显示正常大小。",
		CONFIG_SLIDER_FORMAT = "%.2f",
		CONFIG_SLIDERYARD_FORMAT = "%d米",
		CONFIG_TITLE = "_|cffCCCC88VirtualPlates|r",
	}, { __index = _VirtualPlates.L; } );
end

