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
- Support for modern nameplate APIs and Events.
- Improved nameplate scanning and handling.
- Nameplate scaling is now based on distance to the player (instead of the camera).
- Optional distance text displayed on nameplates (`/vpdist`).
- Distance-based fading for some visual regions.
- Custom glow for the focus nameplate.
- The focus nameplate is now also prioritized, in addition to the target.

<p align="center">
  <img src="https://private-user-images.githubusercontent.com/111320187/449669200-ca5ca766-7805-48a4-ba39-11b8f7dabcd9.jpg?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3NDg3NDA5MzgsIm5iZiI6MTc0ODc0MDYzOCwicGF0aCI6Ii8xMTEzMjAxODcvNDQ5NjY5MjAwLWNhNWNhNzY2LTc4MDUtNDhhNC1iYTM5LTExYjhmN2RhYmNkOS5qcGc_WC1BbXotQWxnb3JpdGhtPUFXUzQtSE1BQy1TSEEyNTYmWC1BbXotQ3JlZGVudGlhbD1BS0lBVkNPRFlMU0E1M1BRSzRaQSUyRjIwMjUwNjAxJTJGdXMtZWFzdC0xJTJGczMlMkZhd3M0X3JlcXVlc3QmWC1BbXotRGF0ZT0yMDI1MDYwMVQwMTE3MThaJlgtQW16LUV4cGlyZXM9MzAwJlgtQW16LVNpZ25hdHVyZT0yYjQ1ZmFmN2VmZTdkYmZiNDVjOWEyODE1YzgxOWJjYWUxMTVhMTdhYzlkMWJjZmQ3NzQzMGU3NjljZDAxNTkwJlgtQW16LVNpZ25lZEhlYWRlcnM9aG9zdCJ9.2DbQkbEwMqDS4EcOfhNZOYhKiZeh6qZPWKppTZJuyR8" 
       alt="_VirtualPlates_Img1" width="95%">
</p>

<p align="center">
  <img src="https://private-user-images.githubusercontent.com/111320187/449669203-386dab87-c148-469e-a78d-de4390dd51fb.jpg?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3NDg3NDA5MzgsIm5iZiI6MTc0ODc0MDYzOCwicGF0aCI6Ii8xMTEzMjAxODcvNDQ5NjY5MjAzLTM4NmRhYjg3LWMxNDgtNDY5ZS1hNzhkLWRlNDM5MGRkNTFmYi5qcGc_WC1BbXotQWxnb3JpdGhtPUFXUzQtSE1BQy1TSEEyNTYmWC1BbXotQ3JlZGVudGlhbD1BS0lBVkNPRFlMU0E1M1BRSzRaQSUyRjIwMjUwNjAxJTJGdXMtZWFzdC0xJTJGczMlMkZhd3M0X3JlcXVlc3QmWC1BbXotRGF0ZT0yMDI1MDYwMVQwMTE3MThaJlgtQW16LUV4cGlyZXM9MzAwJlgtQW16LVNpZ25hdHVyZT1jYjkzMmQ0NThlNzk2YWVlZjgyOWFhOTg1ZDg0OTY5NTBjMmFhZmEzMjdmMGE2NDFiNzNiNzBmMjE0MDU4YzY0JlgtQW16LVNpZ25lZEhlYWRlcnM9aG9zdCJ9.HbLYz37ksQ8-JUq8kjrZPHp6vtES9wpORTDFud4VcZA" 
       alt="_VirtualPlates_Img2" width="95%">
</p>

## Optional Dependency
Extended features require the **C_NamePlate** APIs and **NAME_PLATE_UNIT** Events from Retail, which are not available in WoW 3.3.5a by default.  
Support for these APIs and Events is provided through the custom library **AwesomeWotlk**, created by [FrostAtom](https://github.com/FrostAtom).  
Some of these extended features use [this fork](https://github.com/KhalGH/awesome_wotlk) of **AwesomeWotlk**.

## Installation
1. Download the [addon](https://github.com/KhalGH/_VirtualPlates-WotLK/releases/download/v1.0/_VirtualPlates_mod-v1.0.zip) and optionally the [AwesomeWotlk](https://github.com/KhalGH/_VirtualPlates-WotLK/releases/download/v1.0/AwesomeWotlk.7z) library.  
2. Extract the `!!!_VirtualPlates` folder into `World of Warcraft/Interface/AddOns/`.  
3. Extract `AwesomeWotlk.7z` and follow the `Instructions.txt` file to implement it.  
4. Restart the game and enable the addon.

## Disclaimer
Private servers may have specific rules regarding the use of custom libraries like **AwesomeWotlk**.  
Please verify your server’s policy to ensure the library is allowed before using it.  
The addon still works without the library, but is limited to its basic features.
