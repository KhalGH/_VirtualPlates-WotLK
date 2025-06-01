# _VirtualPlates-WotLK
_VirtualPlates is a legacy WotLK addon created by [Saiket](https://www.wowinterface.com/downloads/info14964-_VirtualPlates.html).  
This is a modified version with a custom design and extended functionality. It may not be compatible with other nameplate addons.

## Basic Features
- Scales and sorts nameplates based on their distance to the camera.
- Modified nameplate appearance (configurable via Lua only).
- Added health percentage, cast spell name and cast timer text.
- Custom glow for the target and mouseover nameplates.
- Prioritized sorting for the target nameplate.

## Extended Features
- Support for modern nameplate APIs and Events, with fallbacks when unavailable.
- Improved nameplate scanning and handling.
- Nameplate scaling is now based on distance to the player (instead of the camera).
- Optional distance text displayed on nameplates (`/vpdist`).
- Distance-based fading for some visual regions.
- Custom glow for the focus nameplate.
- The focus nameplate is now also prioritized, in addition to the target.

## Optional Dependency
Extended features require the **C_NamePlate** APIs and **NAME_PLATE_UNIT** Events from Retail, which are not available in WoW 3.3.5a by default.  
Support for these APIs and Events is provided through the custom library **AwesomeWotlk**, created by [FrostAtom](https://github.com/FrostAtom).  
Some of these extended features use this [fork](https://github.com/KhalGH/awesome_wotlk) of **AwesomeWotlk**.

## Installation
1. Download the addon and optionally the [AwesomeWotlk](https://github.com/KhalGH/awesome_wotlk/releases/download/0.1.4-f1/AwesomeWotlk.7z) library.  
2. Extract the `!!!_VirtualPlates` folder into `World of Warcraft/Interface/AddOns/`.  
3. Extract `AwesomeWotlk.7z` and follow the `Instructions.txt` file to implement it.  
4. Restart the game and enable the addon.

## Disclaimer
Private servers may have specific rules regarding the use of custom libraries like **AwesomeWotlk**.  
Please verify your server’s policy to ensure the library is allowed before using it.  
The addon still works without the library, but is limited to its basic features.
