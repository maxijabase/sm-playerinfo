#include <sourcemod>
#include <sdktools>
#include <ripext>
#include <autoexecconfig>
#include "include/playerinfo.inc"

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

#define PLAYER_LEVEL_URL "http://api.steampowered.com/IPlayerService/GetSteamLevel/v1"
#define PLAYER_SUMMARIES_URL "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2"
#define PLAYER_OWNED_GAMES_URL "https://api.steampowered.com/IPlayerService/GetOwnedGames/v1"

char apiKey[64];
ConVar cvApiKey;

public Plugin myinfo = 
{
	name = "[API] Player Info", 
	author = "ampere", 
	description = "Exposes natives to query the Steam API for player information.", 
	version = PLUGIN_VERSION, 
	url = "github.com/maxijabase"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("PI_GetGameHours", Native_GetGameHours);
	CreateNative("PI_GetVACBans", Native_GetVACBans);
	CreateNative("PI_GetGameBans", Native_GetGameBans);
	CreateNative("PI_GetSteamLevel", Native_GetSteamLevel);
	CreateNative("PI_GetProfilePrivacy", Native_GetProfilePrivacy);
	CreateNative("PI_GetAccountCreationDate", Native_GetAccountCreationDate);
	
	RegPluginLibrary("playerinfo");
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	AutoExecConfig_SetCreateFile(true);
	AutoExecConfig_SetFile("playerinfo");
	
	AutoExecConfig_CreateConVar("sm_playerinfo_version", PLUGIN_VERSION, "Standard plugin version ConVar", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	
	cvApiKey = AutoExecConfig_CreateConVar("sm_playerinfo_apikey", "", "Your Steam API Key");
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}

public void OnConfigsExecuted()
{
	cvApiKey.GetString(apiKey, sizeof(apiKey));
	if (apiKey[0] == '\0') {
		SetFailState("API Key not set in config file!");
	}
}

public int Native_GetGameHours(Handle plugin, int numParams)
{
	if (numParams != 3)
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid number of parameters supplied.");
	}
	
	int client = GetNativeCell(1);
	int appid = GetNativeCell(2);
	
	DataPack pack = new DataPack();
	pack.WriteFunction(GetNativeFunction(3));
	pack.WriteCell(plugin);
	
	char steamid[32];
	GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
	
	HTTPRequest request = CreateRequest(PLAYER_OWNED_GAMES_URL);
	
	request.AppendQueryParam("appids_filter[0]", "%i", appid);
	request.AppendQueryParam("include_played_free_games", "1");
	request.AppendQueryParam("steamid", steamid);
	request.Get(OnHoursReceived, pack);
}

public void OnHoursReceived(HTTPResponse response, DataPack pack, const char[] error)
{
	pack.Reset();
	Function callback = pack.ReadFunction();
	Handle plugin = pack.ReadCell();
	delete pack;
	
	GameHoursResponse gameHoursResponse;
	int hoursResponse = -1;
	
	if (response.Status != HTTPStatus_OK) {
		gameHoursResponse = GameHours_UnknownError;
	}
	else {
		JSONObject root = view_as<JSONObject>(response.Data);
		JSONObject response = root.Get("response");
		
		// Response object is empty
		if (!response.HasKey("game_count")) {
			gameHoursResponse = GameHours_InvisibleHours;
		}
		
		// Game count is 0, account does not own the game
		else if (response.GetInt("game_count") == 0) {
			gameHoursResponse = GameHours_AppIdNotFound;
		}
		
		// We found a game to retrieve hours from
		else {
			JSONArray games = response.Get("games");
			JSONObject info = games.Get(0);
			hoursResponse = info.GetInt("playtime_forever");
			gameHoursResponse = GameHours_Success;
		}
	}
	
	// Fire callback
	Call_StartFunction(plugin, callback);
	Call_PushCell(gameHoursResponse);
	Call_PushString(error);
	Call_PushCell(hoursResponse);
	Call_Finish();
}

public int Native_GetVACBans(Handle plugin, int numParams)
{
}

public int Native_GetGameBans(Handle plugin, int numParams)
{
}

public int Native_GetSteamLevel(Handle plugin, int numParams)
{
}

public int Native_GetProfilePrivacy(Handle plugin, int numParams)
{
}

public int Native_GetAccountCreationDate(Handle plugin, int numParams)
{
	if (numParams != 2)
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid number of parameters supplied.");
	}
	
	int client = GetNativeCell(1);
	Function callback = GetNativeFunction(2);
	
	DataPack pack = new DataPack();
	pack.WriteFunction(callback);
	pack.WriteCell(plugin);
	
	char steamid[32];
	GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
	
	HTTPRequest request = CreateRequest(PLAYER_SUMMARIES_URL);
	request.AppendQueryParam("steamids", steamid);
	request.Get(OnAccountCreationDateReceived, pack);
}

public void OnAccountCreationDateReceived(HTTPResponse response, DataPack pack, const char[] error) {
	pack.Reset();
	Function callback = pack.ReadFunction();
	Handle plugin = pack.ReadCell();
	delete pack;
	
	AccountCreationDateResponse accountCreationDateResponse;
	int timestamp;
	
	if (response.Status != HTTPStatus_OK) {
		accountCreationDateResponse = AccountCreationDate_UnknownError;
	}
	else {
		JSONObject root = view_as<JSONObject>(response.Data);
		JSONObject response = view_as<JSONObject>(root.Get("response"));
		JSONArray players = view_as<JSONArray>(response.Get("players"));
		JSONObject data = view_as<JSONObject>(players.Get(0));
		if (!data.HasKey("timecreated")) {
			accountCreationDateResponse = AccountCreationDate_InvisibleDate;
		}
		else {
			timestamp = data.GetInt("timecreated");
		}
	}
	
	Call_StartFunction(plugin, callback);
	Call_PushCell(accountCreationDateResponse);
	Call_PushString(error);
	Call_PushCell(timestamp);
	Call_Finish();
}

HTTPRequest CreateRequest(const char[] url) {
	HTTPRequest req = new HTTPRequest(url);
	req.AppendQueryParam("format", "json");
	req.AppendQueryParam("key", apiKey);
	return req;
} 