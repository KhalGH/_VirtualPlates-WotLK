--[[****************************************************************************
  * _VirtualPlates by Saiket                                                   *
  * Locales/Locale-koKR.lua - Localized string constants (ko-KR).              *
  ****************************************************************************]]


if ( GetLocale() ~= "koKR" ) then
	return;
end

if C_NamePlate and C_NamePlate.GetNamePlatesDistance then
	local _VirtualPlates = select( 2, ... );
	_VirtualPlates.L = setmetatable( {
		CONFIG_DESC = 	"_VirtualPlates가 이름표의 크기를 조절하는 방식을 설정합니다.\n" ..
					  	"'nameplateDistance' CVar 값을 증가시키면 이름표의 가시 거리 범위가 확장됩니다 (현재 값: " .. GetCVar("nameplateDistance") .. ").\n\n" ..
					  	"제작자: Saiket\n개선 버전: |cffc41f3bKhal|r",
		CONFIG_LIMITS = "이름표 크기 한계",
		CONFIG_MAXSCALE = "기본 크기",
		CONFIG_MAXSCALEENABLED = "기본 크기 변경",
		CONFIG_MAXSCALEENABLED_DESC = "이 값으로 기본 이름표 크기를 조정합니다.",
		CONFIG_MINSCALE = "최소 크기",
		CONFIG_MINSCALE_DESC = "멀리 있는 이름표가 얼마나 작아질 수 있는지를 정의합니다. 최소 크기에 사용되는 거리는 'nameplateDistance' CVar 값이며 최대 100야드까지 적용됩니다.",
		CONFIG_SCALEFACTOR = "스케일 적용 거리 임계값",
		CONFIG_SCALEFACTOR_DESC = "이 거리보다 가까운 이름표는 기본 크기로 표시되며, 그보다 멀면 점차 작아집니다.",
		CONFIG_SLIDER_FORMAT = "%.2f",
		CONFIG_SLIDERYARD_FORMAT = "%d미터",
		CONFIG_TITLE = "_|cffCCCC88VirtualPlates|r",
	}, { __index = _VirtualPlates.L; } );	
else
	local _VirtualPlates = select( 2, ... );
	_VirtualPlates.L = setmetatable( {
		CONFIG_DESC = "_VirtualPlates의 크기 변경이 가능한 이름표를 설정합니다.",
		CONFIG_LIMITS = "이름표 크기 제한",
		CONFIG_MAXSCALE = "이름표의 최대 크기 설정",
		CONFIG_MAXSCALEENABLED = "이름표의 최대 크기 설정",
		CONFIG_MAXSCALEENABLED_DESC = "대상이 매우 가까이 있을 때, 이름표가 너무 커지지 않도록 한계치를 설정합니다.",
		CONFIG_MINSCALE = "이름표의 최소 크기 설정",
		CONFIG_MINSCALE_DESC = "대상이 먼거리에 있을수록 이름표는 작게 표시되는데, 가장 작을때의 한계치를 설정합니다. 0 으로 갈수록 작아지며, 1 은 게임 기본 크기와 동일한 크기입니다.",
		CONFIG_SCALEFACTOR = "스케일 정규화 거리",
		CONFIG_SCALEFACTOR_DESC = "시점이 축소되었을 때, 이름표는 이 곳에 설정된 값으로 이름표 크기를 설정합니다.",
		CONFIG_SLIDER_FORMAT = "%.2f",
		CONFIG_SLIDERYARD_FORMAT = "%d미터",
		CONFIG_TITLE = "_|cffCCCC88VirtualPlates|r",
	}, { __index = _VirtualPlates.L; } );
end

