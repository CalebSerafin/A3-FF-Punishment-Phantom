/*
Function:
    CSSPunPh_fnc_punishment_FF

Description:
    Checks if incident reported is indeed a rebel Friendly Fire event.
    Refer to CSSPunPh_fnc_punishment.sqf for actual punishment logic.
    NOTE: When called from an Hit type of EH, use Example 2 in order to detect collisions.

Scope:
    <SERVER> Execute on server only.

Environment:
    <UNSCHEDULED> This function is thread safe. However, quick execution is optimal.

Parameters:
    <OBJECT> Player that is being verified for FF. | <ARRAY<OBJECT,OBJECT>> Suspected instigator and source/killer returned from EH. The unit that caused the damage is collisions is the source/killer.
    <NUMBER> The amount of time to add to the players total sentence time.
    <NUMBER> Raise the player's total offence level by this percentage. (100% total = Ocean Gulag).
    <OBJECT> The victim of the player's FF. [DEFAULT=objNull]
    <STRING> Custom message to be displayed to FFer [DEFAULT=""]

Returns:
    <STRING> Either a exemption type or "PROSECUTED".

Examples <OBJECT>:
    [_instigator, _unit] remoteExec ["CSSPunPh_fnc_punishment_FF",2,false];   // How it should be called from another object.
    // Unit Tests:
    [player, objNull] remoteExec ["CSSPunPh_fnc_punishment_release",2];          // Test self with no victim
    [player, cursorObject] remoteExec ["CSSPunPh_fnc_punishment_release",2];     // Test self with victim

Examples <ARRAY<OBJECT,OBJECT>>:
    [[_instigator,_source], _unit] remoteExec ["CSSPunPh_fnc_punishment_FF",2,false]; // How it should be called from an EH.

Author: Caleb Serafin
License: MIT License, Copyright (c) 2019 Barbolani & The Official AntiStasi Community
*/
params [
    ["_instigator",objNull, [objNull,[]], [] ],
    ["_victim",objNull, [objNull]],
    ["_customMessage","", [""], [] ]
];
private _filename = "fn_punishment_FF.sqf";

//////////////Enable Switches///////////////
if (isNil "CSSPunPh_FFPunEnabled") then { CSSPunPh_FFPunEnabled = true; };
if (isNil "CSSPunPh_FFPunTellInstigator") then { CSSPunPh_FFPunTellInstigator = false; };
if (isNil "CSSPunPh_FFPunTellVictim") then { CSSPunPh_FFPunTellVictim = false; };
if (isNil "CSSPunPh_FFPunTellAdmin") then { CSSPunPh_FFPunTellAdmin = true; };

///////////Checks if is Collision///////////
private _isCollision = false;
if (_instigator isEqualType []) then {
    _isCollision = !(((_instigator#0) isEqualType objNull) && {isPlayer (_instigator#0)});
    _instigator = _instigator select _isCollision;  // First one in EH will be unit by default, if its a collision the eh returns the instigator in "source" or "killer"
};
if (!(_instigator isEqualType objNull)) exitWith {"NOT OBJECT"};
private _vehicle = vehicle _instigator;
private _vehicleType = typeOf _vehicle;

//////////////////Cool-down/////////////////
if (_instigator getVariable ["CSSPunPh_FFPunish_CD ", 0] > servertime) exitWith {"PUNISHMENT COOL-DOWN ACTIVE"};
_instigator setVariable ["CSSPunPh_FFPunish_CD ", servertime + 1, false];  // Will only ever be evaluated from one machine.

/////////////////Definitions////////////////
private _victimStats = ["damaged systemPunished ",format ["damaged %1 ", name _victim]] select (_victim isKindOf "Man");
_victimStats = [_victimStats,"[",["AI",getPlayerUID _victim] select (isPlayer _victim),"]"] joinString "";
private _notifyVictim = {
    if (!CSSPunPh_FFPunTellVictim) exitWith {};
    if (isPlayer _victim) then {["FF Notification", format["%1 hurt you!",name _instigator]] remoteExec ["CSSPunPh_fnc_customHint", _victim, false];};
};
private _notifyInstigator = {
    params ["_exempMessage"];
    if (!CSSPunPh_FFPunTellInstigator) exitWith {};
    private _comradeStats = ["",["Injured comrade: ",name _victim,""] joinString ""] select (_victim isKindOf "Man");
    ["FF Warning", [_exempMessage,_comradeStats,_customMessage] joinString "<br/>"] remoteExec ["CSSPunPh_fnc_customHint", _instigator, false];
};
private _notifyAdmin = {
    params ["_exemption","_offenceTotal"];
    if (!CSSPunPh_FFPunTellAdmin) exitWith {};
    private _admin = [] call CSSPunPh_fnc_getAdmin;
    if (!isNull _admin) then {
        ["FF Notification", [name _instigator," has FFed by ",_exemption,".<br/>Total Offences: ",str _offenceTotal, "<br/>Victim: ",name _victim] joinString ""] remoteExec ["CSSPunPh_fnc_customHint",_admin,false];
    };
};
private _logPvP = {
    if (!(_victim isKindOf "Man")) exitWith {};
    private _killStats = format ["PVP | %1 [%2]%3", name _instigator, getPlayerUID _instigator, _victimStats];
    [2,_killStats,_filename,true] call CSSPunPh_fnc_log;
};

///////////////Checks if is FF//////////////
private _exemption = switch (true) do {  // ~0.012 ms for all false cases
    case (!CSSPunPh_FFPunEnabled):                                          {"FF PUNISH IS DISABLED"};
    case (!isMultiplayer):                                                  {"IS NOT MULTIPLAYER"};
    case ("HC" in (getPlayerUID _instigator)):                              {"FF BY HC"};  // Quick & reliable check
    case (!(isPlayer _instigator)):                                         {"FF BY AI"};
    case (_vehicle isEqualTo (vehicle _victim)):                            {"IN SAME VEHICLE"};  // Also fulfils role of checking whether the instigator and victim is same person.
    case (!((side group _victim) isEqualTo (side group _instigator))):      {call _logPvP; "DIFFERENT GROUP SIDES"};
    case (!((side _victim) isEqualTo (side _instigator))):                  {call _logPvP; "DIFFERENT UNIT SIDES"};
    default                                                                 {""};
};
if (!(_exemption isEqualTo "")) exitWith {
    format["NOT FF, %1", _exemption];
};

/////////////Acts on Collision//////////////
if (_isCollision) then {
    _customMessage = [_customMessage,"You damaged a friendly as a driver."] joinString "<br/>";
    _timeAdded = 27;
    _offenceAdded = 0.15;
    [2, format ["COLLISION | %1 [%2]'s %3 %4", name _instigator, getPlayerUID _instigator, _vehicleType, _victimStats], _filename] call CSSPunPh_fnc_log;
};

/////////Checks for important roles/////////
_exemption = switch (true) do {
    case (!(admin owner _instigator isEqualTo 0) || player isEqualTo _instigator): {  // Local host included.
        ["You damaged a friendly as admin."] call _notifyInstigator; // Admin not reported to victim in case of Zeus remote control.
        format ["ADMIN, %1", ["Server","Voted","Logged"] select (admin owner _instigator)];
    };
    case (_vehicle isKindOf "Air"): {
        call _notifyVictim;
        ["You damaged a friendly as CAS support."] call _notifyInstigator;
        format["AIRCRAFT, %1", _vehicleType];
    };
    case (
        isNumber (configFile >> "CfgVehicles" >> _vehicleType >> "artilleryScanner") &&
        {!(getNumber (configFile >> "CfgVehicles" >> _vehicleType >> "artilleryScanner") isEqualTo 0)}
    ): {
        call _notifyVictim;
        ["You damaged a friendly as arty support."] call _notifyInstigator;
        format ["ARTY, %1", _vehicleType];
    };
    // TODO: if( remoteControlling(_instigator) ) exitWith
        // For the meantime do either one of the following: login as admin for Zeus, or "player setVariable ["PvP",true,true];
        // Without above: Your AI will be prosecuted for FF. Upon leaving UAV you will be punished. If you have debug console you can self forgive.
    default {""};
};
if (!(_exemption isEqualTo "")) exitWith {
    private _UID = getPlayerUID _instigator;
    ([_UID,[["offenceTotal",0]]] call CSSPunPh_fnc_punishment_dataGet) params ["_offenceTotal"];
    _offenceTotal = _offenceTotal + 1;
    [_UID,[["offenceTotal",_offenceTotal],["lastOffenceTime",floor serverTime]]] call CSSPunPh_fnc_punishment_dataSet;

    private _playerStats = format["%1 [%2] %3", name _instigator, getPlayerUID _instigator, _victimStats];
    [2, format ["%1 | %2", _exemption, _playerStats], _filename,true] call CSSPunPh_fnc_log;
    [_exemption,_offenceTotal] call _notifyAdmin;

    _exemption;
};

///////////////Drop The Hammer//////////////
[_instigator,_victim,_customMessage] call CSSPunPh_fnc_punishment;
