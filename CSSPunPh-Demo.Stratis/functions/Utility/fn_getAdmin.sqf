/*
Function:
    CSSPunPh_fnc_getAdmin

Description:
    Returns unit object of online admin or objNull.
    Does not work in SP. Must be on Local Host / Dedicated Multiplayer.

Scope:
    <SERVER>

Environment:
    <ANY>

Returns:
    <OBJECT> Admin unit if online/Local Host or objNull if no admin.

Examples:
    [] call CSSPunPh_fnc_getAdmin;

Author: Caleb Serafin
License: MIT License, Copyright (c) 2019 Barbolani & The Official AntiStasi Community
*/

if (isServer && hasInterface) then { CSSPunPh_admin = player; };
if (isNil "CSSPunPh_admin") then {CSSPunPh_admin = objNull};
if (admin owner CSSPunPh_admin isEqualTo 0 && !hasInterface) then {
    private _allPlayers = (allUnits + allDeadMen);
    private _adminIndex = _allPlayers findIf {!(admin owner _x isEqualTo 0)};
    CSSPunPh_admin = if (_adminIndex isEqualTo -1) then { objNull } else { _allPlayers # _adminIndex };
};
CSSPunPh_admin;
