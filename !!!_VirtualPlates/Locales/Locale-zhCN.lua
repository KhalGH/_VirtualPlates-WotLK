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
		CONFIG_DESC = 	"配置 _VirtualPlates 缩放姓名板的方式。\n" ..
					  	"提高 CVar 'nameplateDistance' 的值可扩展可见范围（当前值：" .. GetCVar("nameplateDistance") .. "）。\n\n" ..
					  	"作者：Saiket\n修改版本：|cffc41f3bKhal|r",
		CONFIG_LIMITS = "姓名板缩放限制",
		CONFIG_MAXSCALE = "默认缩放",
		CONFIG_MAXSCALEENABLED = "更改默认大小",
		CONFIG_MAXSCALEENABLED_DESC = "通过该因子调整姓名板的默认大小。",
		CONFIG_MINSCALE = "最小缩放",
		CONFIG_MINSCALE_DESC = "定义在较远距离时姓名板的最小显示大小。此距离基于 'nameplateDistance' CVar，最大为100码。",
		CONFIG_SCALEFACTOR = "缩放距离阈值",
		CONFIG_SCALEFACTOR_DESC = "距离小于该值的姓名板将显示为默认大小，超过该距离则逐渐缩小。",
		CONFIG_SLIDER_FORMAT = "%.2f",
		CONFIG_SLIDERYARD_FORMAT = "%d码",
		CONFIG_TITLE = "_|cffCCCC88VirtualPlates|r",
	}, { __index = _VirtualPlates.L; } );
else
	local _VirtualPlates = select( 2, ... );
	_VirtualPlates.L = setmetatable( {
		CONFIG_DESC = "配置 _VirtualPlates 缩放姓名板的方式。",
		CONFIG_LIMITS = "姓名板缩放限制",
		CONFIG_MAXSCALE = "最大值",
		CONFIG_MAXSCALEENABLED = "限制最大缩放",
		CONFIG_MAXSCALEENABLED_DESC = "防止姓名板在靠近屏幕时变得过大。",
		CONFIG_MINSCALE = "最小值",
		CONFIG_MINSCALE_DESC = "限制姓名板缩小的程度，从0（无限制）到1（不会小于默认大小）。",
		CONFIG_SCALEFACTOR = "缩放标准距离",
		CONFIG_SCALEFACTOR_DESC = "距离相机该距离的姓名板将显示为标准大小。",
		CONFIG_SLIDER_FORMAT = "%.2f",
		CONFIG_SLIDERYARD_FORMAT = "%d码",
		CONFIG_TITLE = "_|cffCCCC88VirtualPlates|r",
	}, { __index = _VirtualPlates.L; } );
end

