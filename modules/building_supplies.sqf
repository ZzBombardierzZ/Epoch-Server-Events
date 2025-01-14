/*
	Original Construction "IKEA" Event by Aidem
	Original "crate visited" marker concept and code by Payden
	Rewritten and updated for DayZ Epoch 1.0.6+ by JasonTM
	Updated for DayZ Epoch 1.0.7+ by JasonTM
	Last update: 06-01-2021
*/

local _spawnChance =  1; // Percentage chance of event happening.The number must be between 0 and 1. 1 = 100% chance.
local _chainsawChance = .25; // Chance that a chainsaw with mixed gas will be added to the crate. The number must be between 0 and 1. 1 = 100% chance.
local _vaultChance = .25; // Chance that a safe or lockbox will be added to the crate. The number must be between 0 and 1. 1 = 100% chance.
local _radius = 350; // Radius the loot can spawn and used for the marker.
local _timeout = 20; // Time it takes for the event to time out (in minutes). To disable timeout set to -1.
local _debug = false; // Diagnostic logs used for troubleshooting.
local _nameMarker = true; // Center marker with the name of the mission.
local _markPos = false; // Puts a marker exactly were the loot spawns.
local _lootAmount = 15; // This is the number of times a random loot selection is made.
local _type = "TitleText"; // Type of announcement message. Options "Hint","TitleText". ***Warning: Hint appears in the same screen space as common debug monitors
local _visitMark = true; // Places a "visited" check mark on the mission if a player gets within range of the crate.
local _distance = 20; // Distance in meters from crate before crate is considered "visited"
local _crate = "DZ_AmmoBoxBigUS"; // Class name of loot crate.
#define TITLE_COLOR "#00FF11" // Hint Option: Color of Top Line
#define TITLE_SIZE "1.75" // Hint Option: Size of top line
#define IMAGE_SIZE "4" // Hint Option: Size of the image

local _lootList = [ // If the item has a number in front of it, then that many will be added to the crate if it is selected one time. Each item can be selected multiple times. Adjust the array configuration to your preferences.
	[3,"MortarBucket"],"ItemWoodStairs",[12,"CinderBlocks"],"plot_pole_kit",[12,"PartPlankPack"],[12,"PartPlywoodPack"],"m240_nest_kit","light_pole_kit","ItemWoodCrateKit","ItemFuelBarrel",
	[4,"metal_floor_kit"],[4,"ItemWoodFloor"],[4,"half_cinder_wall_kit"],[4,"metal_panel_kit"],"fuel_pump_kit",[4,"full_cinder_wall_kit"],"ItemWoodWallWithDoorLgLocked","storage_shed_kit","sun_shade_kit","wooden_shed_kit",
	[2,"ItemComboLock"],[4,"ItemWoodWallLg"],"ItemWoodWallGarageDoorLocked",[4,"ItemWoodWallWindowLg"],"wood_ramp_kit",[8,"ItemWoodFloorQuarter"],"bulk_ItemSandbag","bulk_ItemTankTrap","bulk_ItemWire","bulk_PartGeneric",
	"workbench_kit","cinder_garage_kit","cinder_door_kit","wood_shack_kit","deer_stand_kit",[3,"ItemWoodWallThird"],"ItemWoodLadder",[3,"desert_net_kit"],[3,"forest_net_kit"],[2,"ItemSandbagLarge"]
];

if (random 1 > _spawnChance and !_debug) exitWith {};

local _pos = [getMarkerPos "center",0,(((getMarkerSize "center") select 1)*0.75),10,0,.3,0] call BIS_fnc_findSafePos;

diag_log format["IKEA Event spawning at %1", _pos];
 
local _lootPos = [_pos,0,(_radius - 100),10,0,2000,0] call BIS_fnc_findSafePos;
 
if (_debug) then {diag_log format["IKEA Event: creating ammo box at %1", _lootPos];};

local _box = _crate createVehicle [0,0,0];
_box setPos _lootPos;

clearMagazineCargoGlobal _box;
clearWeaponCargoGlobal _box;

if (random 1 < _vaultChance) then {
	local _vault = ["ItemVault","ItemLockbox"] call BIS_fnc_selectRandom;
	_box addMagazineCargoGlobal [_vault,1];
};

if (random 1 < _chainsawChance) then {
	local _saw = ["Chainsaw","ChainSawB","ChainsawG","ChainsawP"] call BIS_fnc_selectRandom;
	_box addMagazineCargoGlobal ["ItemJerryMixed",2];
	_box addWeaponCargoGlobal [_saw,1];
};

for "_i" from 1 to _lootAmount do {
	local _loot = _lootList call BIS_fnc_selectRandom;
	
	if ((typeName _loot) == "ARRAY") then {
		_box addMagazineCargoGlobal [_loot select 1,_loot select 0];
	} else {
		_box addMagazineCargoGlobal [_loot,1];
	};
};

local _pack = ["Patrol_Pack_DZE1","Assault_Pack_DZE1","Czech_Vest_Pouch_DZE1","TerminalPack_DZE1","TinyPack_DZE1","ALICE_Pack_DZE1","TK_Assault_Pack_DZE1","CompactPack_DZE1","British_ACU_DZE1","GunBag_DZE1","NightPack_DZE1","SurvivorPack_DZE1","AirwavesPack_DZE1","CzechBackpack_DZE1","WandererBackpack_DZE1","LegendBackpack_DZE1","CoyoteBackpack_DZE1","LargeGunBag_DZE1"] call BIS_fnc_selectRandom;
_box addBackpackCargoGlobal [_pack,1];

if (_type == "Hint") then {
	local _img = (getText (configFile >> "CfgVehicles" >> "UralCivil_DZE" >> "picture"));
	RemoteMessage = ["hintWithImage",["STR_CL_ESE_IKEA_TITLE","STR_CL_ESE_IKEA"],[_img,TITLE_COLOR,TITLE_SIZE,IMAGE_SIZE]];
} else {
	RemoteMessage = ["titleText","STR_CL_ESE_IKEA"];
};
publicVariable "RemoteMessage";

if (_debug) then {diag_log format["IKEA Event setup, event will end in %1 minutes", _timeout];};

local _time = diag_tickTime;
local _done = false;
local _visited = false;
local _isNear = true;
local _markers = [1,1,1,1];

//[position,createMarker,setMarkerColor,setMarkerType,setMarkerShape,setMarkerBrush,setMarkerSize,setMarkerText,setMarkerAlpha]
_markers set [0, [_pos, format ["eventMark%1", _time], "ColorGreen", "","ELLIPSE", "", [_radius, _radius], [], 0.5]];
if (_nameMarker) then {_markers set [1, [_pos, format ["eventDot%1",_time], "ColorBlack", "mil_dot","ICON", "", [], ["STR_CL_ESE_IKEA_TITLE"], 0]];};
if (_markPos) then {_markers set [2, [_lootPos, format ["eventDebug%1",_time], "ColorGreen", "mil_dot","ICON", "", [], [], 0]];};
DZE_ServerMarkerArray set [count DZE_ServerMarkerArray, _markers]; // Markers added to global array for JIP player requests.
local _markerIndex = count DZE_ServerMarkerArray - 1;
PVDZ_ServerMarkerSend = ["start",_markers];
publicVariable "PVDZ_ServerMarkerSend";

while {!_done} do {
	uiSleep 3;
	if (_visitMark && !_visited) then {
		{
			if (isPlayer _x && {_x distance _box <= _distance}) exitWith {
				_visited = true;
				_markers set [3, [[(_pos select 0), (_pos select 1) + 25], format ["EventVisit%1", _time], "ColorBlack", "hd_pickup","ICON", "", [], [], 0]];
				DZE_ServerMarkerArray set [_markerIndex, _markers];
				PVDZ_ServerMarkerSend = ["createSingle",(_markers select 3)];
				publicVariable "PVDZ_ServerMarkerSend";
			};
		} count playableUnits;
	};
	
	if (_timeout != -1) then {
		if (diag_tickTime - _time >= _timeout*60) then {
			_done = true;
		};
	};
};

while {_isNear} do {
	uiSleep 3;
	{if (isPlayer _x && _x distance _box >= _distance) exitWith {_isNear = false};} count playableUnits;
};

// Clean up
deleteVehicle _box;
// Tell all clients to remove the markers from the map
local _remove = [];
{
	if (typeName _x == "ARRAY") then {
		_remove set [count _remove, (_x select 1)];
	};
} count _markers;
PVDZ_ServerMarkerSend = ["end",_remove];
publicVariable "PVDZ_ServerMarkerSend";
DZE_ServerMarkerArray set [_markerIndex, -1];
diag_log "IKEA Event Ended";
