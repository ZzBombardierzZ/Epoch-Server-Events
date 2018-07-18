/*
	Original Treasure Event by Aidem
	Original "crate visited" marker concept and code by Payden
	Rewritten and updated for DayZ Epoch 1.0.6+ by JasonTM
	Last update: 7-3-2018
*/

_spawnChance =  1; // Percentage chance of event happening.The number must be between 0 and 1. 1 = 100% chance.
_gemChance = .25; // Chance that a gem will be added to the crate. The number must be between 0 and 1. 1 = 100% chance.
_markerRadius = 350; // Radius the loot can spawn and used for the marker
_timeout = 20; // Time it takes for the event to time out (in minutes). To disable timeout set to -1.
_debug = false; // Puts a marker exactly were the loot spawns
_nameMarker = false; // Center marker with the name of the mission.
_markPosition = false; // Puts a marker exactly were the loot spawns.
_lootAmount = 5; // This is the number of times a random loot selection is made.
_messageType = "TitleText"; // Type of announcement message. Options "Hint","TitleText". ***Warning: Hint appears in the same screen space as common debug monitors
_visitMark = true; // Places a "visited" check mark on the mission if a player gets within range of the crate.
_visitDistance = 20; // Distance from crate before crate is considered "visited"
_crate = "GuerillaCacheBox";

_weapons = [["revolver_gold_EP1","6Rnd_45ACP"],["AKS_GOLD","30Rnd_762x39_AK47"]];
_lootList = [[5,"ItemGoldBar"],[3,"ItemGoldBar10oz"],"ItemBriefcase100oz",[20,"ItemSilverBar"],[10,"ItemSilverBar10oz"]];
_gemList = ["ItemTopaz","ItemObsidian","ItemSapphire","ItemAmethyst","ItemEmerald","ItemCitrine","ItemRuby"];

// Random chance of event happening
_spawnRoll = random 1;
if (_spawnRoll > _spawnChance and !_debug) exitWith {};

// Random location
_position = [getMarkerPos "center",0,(((getMarkerSize "center") select 1)*0.75),10,0,2000,0] call BIS_fnc_findSafePos;

diag_log format["Pirate Treasure Event Spawning At %1", _position];

_lootPos = [_position,0,(_markerRadius - 100),10,0,2000,0] call BIS_fnc_findSafePos;

if (_debug) then {diag_log format["Pirate Treasure Event: creating ammo box at %1", _lootPos];};

// Create ammo box
_lootBox = createVehicle [_crate,_lootPos,[], 0, "NONE"];
clearMagazineCargoGlobal _lootBox;
clearWeaponCargoGlobal _lootBox;

// Cut the grass around the loot position
_clutter = createVehicle ["ClutterCutter_EP1", _lootPos, [], 0, "CAN_COLLIDE"];
_clutter setPos _lootPos;

// Chance for a gem
if (_spawnRoll < _gemChance) then {
	_gem = _gemList call dz_fn_array_selectRandom;
	_lootBox addMagazineCargoGlobal [_gem,1];
};

// Add loot
for "_i" from 1 to _lootAmount do {
	_loot = _lootList call dz_fn_array_selectRandom;
	
	if ((typeName _loot) == "ARRAY") then {
		_lootBox addMagazineCargoGlobal [_loot select 1,_loot select 0];
	} else {
		_lootBox addMagazineCargoGlobal [_loot,1];
	};
};

// Add weapon
_weapon = _weapons call dz_fn_array_selectRandom;
_lootBox addWeaponCargoGlobal [_weapon select 0,1];
_lootBox addMagazineCargoGlobal [_weapon select 1,3];

// Add backpack
_backpack = DayZ_Backpacks call dz_fn_array_selectRandom;
_lootBox addBackpackCargoGlobal [_backpack,1];

if (_messageType == "Hint") then {
	_image = (getText (configFile >> "CfgMagazines" >> "ItemRuby" >> "picture"));
	_hint = "STR_CL_ESE_TREASURE_HINT";
	RemoteMessage = ["hint", _hint, [_image]];
} else {
	_message = "STR_CL_ESE_TREASURE";
	RemoteMessage = ["titleText",_message];
};
publicVariable "RemoteMessage";

if (_debug) then {diag_log format["Pirate Treasure event setup, waiting for %1 minutes", _timeout];};

_startTime = diag_tickTime;
_eventMarker = "";
_crateMarker = "";
_visitMarker = "";
_textMarker = "";
_finished = false;
_visitedCrate = false;
_playerNear = true;

while {!_finished} do {
	
	_eventMarker = createMarker [ format ["loot_eventMarker_%1", _startTime], _position];
	_eventMarker setMarkerShape "ELLIPSE";
	_eventMarker setMarkerColor "ColorYellow";
	_eventMarker setMarkerAlpha 0.5;
	_eventMarker setMarkerSize [(_markerRadius + 50), (_markerRadius + 50)];
	
	if (_nameMarker) then {
		_textMarker = createMarker [format["loot_text_marker_%1",_startTime],_position];
		_textMarker setMarkerShape "ICON";
		_textMarker setMarkerType "mil_dot";
		_textMarker setMarkerColor "ColorBlack";
		_textMarker setMarkerText "Pirate Treasure";
	};
	
	if (_markPosition) then {
		_crateMarker = createMarker [ format ["loot_event_crateMarker_%1", _startTime], _lootPos];
		_crateMarker setMarkerShape "ICON";
		_crateMarker setMarkerType "mil_dot";
		_crateMarker setMarkerColor "ColorYellow";
	};
	
	if (_visitMark) then {
		{if (isPlayer _x && _x distance _lootBox <= _visitDistance && !_visitedCrate) then {_visitedCrate = true};} count playableUnits;
	
		// Add the visit marker to the center of the mission
		if (_visitedCrate) then {
			_visitMarker = createMarker [ format ["loot_event_visitMarker_%1", _startTime], [(_position select 0), (_position select 1) + 25]];
			_visitMarker setMarkerShape "ICON";
			_visitMarker setMarkerType "hd_pickup";
			_visitMarker setMarkerColor "ColorBlack";
		}; 
	};
	
	uiSleep 1;
	
	deleteMarker _eventMarker;
	if !(isNil "_textMarker") then {deleteMarker _textMarker;};
	if !(isNil "_crateMarker") then {deleteMarker _crateMarker;};
	if !(isNil "_visitMarker") then {deleteMarker _visitMarker;}; 
	
	if (_timeout != -1) then {
		if (diag_tickTime - _startTime >= _timeout*60) then {
			_finished = true;
		};
	};
};

// Prevent the crate from being deleted if a player is still visiting because that's just rude.
while {_playerNear} do {
	{if (isPlayer _x && _x distance _lootBox >= _visitDistance) then {_playerNear = false};} count playableUnits;
};

// Clean up
deleteVehicle _lootBox;
deleteVehicle _clutter;

if (_debug) then {diag_log "Pirate Treasure Event Ended";};
