# _VirtualPlates-WotLK
_VirtualPlates is a legacy addon created by [Saiket](https://www.wowinterface.com/downloads/info14964-_VirtualPlates.html) during WotLK.  
This is a modified version with a custom design and extended functionality.  
It may not be compatible with other nameplate addons.

## Basic Features
- Scales and sorts nameplates based on their distance to the camera.
- Modified nameplate appearance (configurable via Lua only).
- Added health percentage, cast spell name and cast timer text.
- Custom glow for the target and mouseover nameplates.
- Prioritized sorting for the target nameplate.
- TotemPlates-style functionality for totems and specific NPCs (editable list in the Totems folder).
- Minimun level nameplate filter (set via Lua file)

## Extended Features
- Support for modern nameplate APIs and Events.
- Improved nameplate scanning and handling.
- Nameplate scaling is now based on distance to the player (instead of the camera).
- Distance-based fading for some visual regions.
- Custom glow for the focus nameplate.
- Focus nameplate is now also prioritized in sorting, second to the target.
- Optional distance text displayed on nameplates (`/vpdist`).
- Optional class icons on friendly players in PvP instances (`/vpicons`).
- Optional player-only nameplate filter (`/vpfilter`).
   
A `/reload` is recommended after changing the `nameplateDistance` CVar (`/console nameplateDistance #`).

<p align="center">
  <img src="https://raw.githubusercontent.com/KhalGH/_VirtualPlates-WotLK/refs/heads/assets/assets/VirtualPlates_img1.jpg" 
       alt="_VirtualPlates_Img1" width="95%">
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/KhalGH/_VirtualPlates-WotLK/refs/heads/assets/assets/VirtualPlates_img2.jpg" 
       alt="_VirtualPlates_Img2" width="95%">
</p>

## Optional Dependency
Extended features require the **C_NamePlate** `API` and **NAME_PLATE_UNIT** `Events` from Retail, which are not available in WoW 3.3.5a by default.  
Support for these APIs and Events is provided through the custom library **AwesomeWotlk**, created by [FrostAtom](https://github.com/FrostAtom).  
Some of these extended features use [this fork](https://github.com/KhalGH/awesome_wotlk) of **AwesomeWotlk**.

## Installation
1. Download the [addon](https://github.com/KhalGH/_VirtualPlates-WotLK/releases/download/v1.2/_VirtualPlates_mod-v1.2.zip) and optionally the [AwesomeWotlk](https://github.com/KhalGH/_VirtualPlates-WotLK/releases/download/v1.2/AwesomeWotlk.7z) library.  
2. Extract the `!!!_VirtualPlates` folder into `World of Warcraft/Interface/AddOns/`.  
3. Extract `AwesomeWotlk.7z` and follow the `Instructions.txt` file to implement it.  
4. Restart the game and enable the addon.

## Disclaimer
Private servers may have specific rules regarding the use of custom libraries like **AwesomeWotlk**.  
Please verify your server’s policy to ensure the library is allowed before using it.  
The addon still works without the library, but is limited to its basic features.

## Information  
- **Addon Version:** 1.2  
- **Game Version:** 3.3.5a (WotLK)  
- **Original Author:** Saiket
- **Modified by:** Khal
