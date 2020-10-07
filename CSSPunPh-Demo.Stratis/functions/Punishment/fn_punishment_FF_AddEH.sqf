/*
Function:
    CSSPunPh_fnc_punishment_FF_addEH

Description:
    Adds EHs for Punishment FF check.
    This is the default entry point for the Punishment Module.
    Nothing else should be called from Antistasi.

Scope:
    <LOCAL> Execute on object you wish to assign the EH to.

Environment:
    <ANY>

Parameters:
    <OBJECT> The Object that the Event Handlers are being added to.
    <BOOLEAN> Whether it is intended to be added to AI.

Returns:
    <BOOLEAN> true if it hasn't crashed; false if CSSPunPh_FFPunEnabled is false or invalid params; nil if it has crashed.

Examples:
    if (hasInterface) then {
        [player] call CSSPunPh_fnc_punishment_FF_addEH; // Recommended to add to "onPlayerRespawn.sqf"
    };
    // Add to cursorObject
    [cursorObject,true] remoteExec ["CSSPunPh_fnc_punishment_FF_addEH",cursorObject,false];
    // Add to AI/player from init field
    [this,true] call CSSPunPh_fnc_punishment_FF_addEH;

Author: Caleb Serafin
License: MIT License, Copyright (c) 2019 Barbolani & The Official AntiStasi Community
*/
params [ ["_unit",objNull,[objNull]], ["_addToAI",false,[false]] ];
private _fileName = "fn_punishment_FF_addEH.sqf";

if (!(_unit isKindOf "Man")) exitWith {
    [1,"No unit given",_fileName] remoteExecCall ["CSSPunPh_fnc_log",2,false];
    false;
};

private _isAI = !isPlayer _unit || !hasInterface || {!(_unit isEqualTo player)}; // Avoiding adding fired handlers for Ai. Needs to be local for ace, self punishment, and checkStatus.

if (_isAI && !_addToAI) exitWith {true};

_unit addEventHandler ["Killed", {
    params ["_unit", "_killer", "_instigator", "_useEffects"];
    [[_instigator,_killer], _unit] remoteExecCall ["CSSPunPh_fnc_punishment_FF",2,false];
}];
_unit addEventHandler ["Hit", {
    params ["_unit", "_source", "_damage", "_instigator"];
    [[_instigator,_source], _unit] remoteExecCall ["CSSPunPh_fnc_punishment_FF",2,false];
}];

[3,format["Punishment Event Handlers Added to: %1",name _unit],_fileName] remoteExecCall ["CSSPunPh_fnc_log",2,false];
true;
