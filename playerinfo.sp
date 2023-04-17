#include <sourcemod>
#include <sdktools>
#include <ripext>
#include <autoexecconfig>
#include "playerinfo.inc"

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

#define PLAYER_LEVEL_URL "http://api.steampowered.com/IPlayerService/GetSteamLevel/v1"
#define PLAYER_SUMMARIES_URL "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2"
#define PLAYER_OWNED_GAMES_URL "https://api.steampowered.com/IPlayerService/GetOwnedGames/v1"

char apiKey[64];

public Plugin myinfo = 
{
	name = "Player Info", 
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
	
	RegPluginLibrary("playerinfo");
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	AutoExecConfig_SetCreateFile(true);
	AutoExecConfig_SetFile("playerinfo");
	
	AutoExecConfig_CreateConVar("sm_playerinfo_version", PLUGIN_VERSION, "Standard plugin version ConVar", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	ConVar cv_apiKey = AutoExecConfig_CreateConVar("sm_playerinfo_apikey", "", "Your Steam API Key");
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	cv_apiKey.GetString(apiKey, sizeof(apiKey));
	if (apiKey[0] == '\0') {
		SetFailState("API Key is not set! Check cfg/sourcemod/playerinfo.cfg");
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
	pack.WriteCell(GetClientUserId(client));
	pack.WriteFunction(GetNativeFunction(3));
	pack.WriteCell(plugin);
	
	char steamid[32];
	GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
	
	HTTPRequest request = CreateRequest(PLAYER_OWNED_GAMES_URL);
	
	PrintToServer("appid %i", appid);
	PrintToServer("steamid %s", steamid);
	PrintToServer("apikey %s", apiKey);
	
	request.AppendQueryParam("appids_filter[0]", "%i", appid);
	request.AppendQueryParam("include_played_free_games", "1");
	request.AppendQueryParam("steamid", steamid);
	request.Get(OnHoursReceived, pack);
}

public void OnHoursReceived(HTTPResponse response, DataPack pack, const char[] error) {
	pack.Reset();
	int userid = pack.ReadCell();
	Function cb = pack.ReadFunction();
	Handle plugin = pack.ReadCell();
	delete pack;
	
	if (response.Status != HTTPStatus_OK) {
		ThrowError("Error! %s", error);
	}
	
	JSONObject root = view_as<JSONObject>(response.Data);
	JSONObject response = root.Get("response");
	JSONArray games = response.Get("games");
	JSONObject info = games.Get(0);
	int hours = info.GetInt("playtime_forever");
	
	PrintToServer("hours are %i, userid is %i, client is %N", hours / 60, userid, GetClientOfUserId(userid));	
	
	Call_StartFunction(plugin, cb);
	Call_PushCell(GameHours_Success);
	Call_PushCell(hours);
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
}

HTTPRequest CreateRequest(const char[] url) {
	HTTPRequest req = new HTTPRequest(url);
	req.AppendQueryParam("format", "json");
	req.AppendQueryParam("key", apiKey);
	return req;
}