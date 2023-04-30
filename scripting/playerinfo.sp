#include <sourcemod>
#include <sdktools>
#include <ripext>
#include <autoexecconfig>
#include "include/playerinfo.inc"

#undef REQUIRE_PLUGIN
#include <updater>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.1"

#define UPDATE_URL "https://raw.githubusercontent.com/maxijabase/sm-playerinfo/master/updatefile.txt"

#define PLAYER_LEVEL_URL "http://api.steampowered.com/IPlayerService/GetSteamLevel/v1"
#define PLAYER_SUMMARIES_URL "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2"
#define PLAYER_OWNED_GAMES_URL "http://api.steampowered.com/IPlayerService/GetOwnedGames/v1"
#define PLAYER_BANS_URL "http://api.steampowered.com/ISteamUser/GetPlayerBans/v1"

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
  CreateNative("PI_GetPlayerBans", Native_GetPlayerBans);
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
  
  if (LibraryExists("updater"))
  {
    Updater_AddPlugin(UPDATE_URL);
  }
}

public void OnLibraryAdded(const char[] name)
{
  if (StrEqual(name, "updater"))
  {
    Updater_AddPlugin(UPDATE_URL);
  }
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
    JSONObject responseObj = view_as<JSONObject>(root.Get("response"));
    
    // Response object is empty
    if (!responseObj.HasKey("game_count")) {
      gameHoursResponse = GameHours_InvisibleHours;
    }
    
    // Game count is 0, account does not own the game
    else if (responseObj.GetInt("game_count") == 0) {
      gameHoursResponse = GameHours_AppIdNotFound;
    }
    
    // We found a game to retrieve hours from
    else {
      JSONArray games = view_as<JSONArray>(responseObj.Get("games"));
      JSONObject info = view_as<JSONObject>(games.Get(0));
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

public int Native_GetPlayerBans(Handle plugin, int numParams)
{
  int client = GetNativeCell(1);
  Function callback = GetNativeFunction(2);
  
  DataPack pack = new DataPack();
  pack.WriteFunction(callback);
  pack.WriteCell(plugin);
  
  char steamid[32];
  GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
  
  HTTPRequest request = CreateRequest(PLAYER_BANS_URL);
  request.AppendQueryParam("steamids", steamid);
  request.Get(OnPlayerBansReceived, pack);
}

public void OnPlayerBansReceived(HTTPResponse response, DataPack pack, const char[] error) {
  pack.Reset();
  Function callback = pack.ReadFunction();
  Handle plugin = pack.ReadCell();
  delete pack;
  
  PlayerBans bans;
  PlayerBansResponse playerBansResponse;
  
  if (response.Status != HTTPStatus_OK) {
    playerBansResponse = PlayerBans_UnknownError;
  }
  else {
    JSONObject root = view_as<JSONObject>(response.Data);
    JSONArray players = view_as<JSONArray>(root.Get("players"));
    JSONObject data = view_as<JSONObject>(players.Get(0));
    
    char datas[2048];
    data.ToString(datas, sizeof datas);
    PrintToServer(datas);
    
    bans.CommunityBanned = data.GetBool("CommunityBanned");
    bans.VACBanned = data.GetBool("VACBanned");
    bans.NumberOfVACBans = data.GetInt("NumberOfVACBans");
    bans.DaysSinceLastBan = data.GetInt("DaysSinceLastBan");
    bans.NumberOfGameBans = data.GetInt("NumberOfGameBans");
    
    char economyBan[2];
    data.GetString("EconomyBan", economyBan, sizeof(economyBan));
    
    switch (economyBan[0]) {
      case 'n':bans.EconomyBan = EconomyBan_None;
      case 'p':bans.EconomyBan = EconomyBan_Probation;
      case 'b':bans.EconomyBan = EconomyBan_Banned;
    }
    
    playerBansResponse = PlayerBans_Success;
  }
  
  Call_StartFunction(plugin, callback);
  Call_PushCell(playerBansResponse);
  Call_PushString(error);
  Call_PushArray(bans, sizeof(bans));
  Call_Finish();
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
  int client = GetNativeCell(1);
  Function callback = GetNativeFunction(2);
  any data = GetNativeCell(3);
  
  DataPack pack = new DataPack();
  pack.WriteFunction(callback);
  pack.WriteCell(plugin);
  pack.WriteCell(data);
  
  char steamid[32];
  GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
  
  HTTPRequest request = CreateRequest(PLAYER_SUMMARIES_URL);
  request.AppendQueryParam("steamids", steamid);
  request.Get(OnAccountCreationDateReceived, pack);
}

public void OnAccountCreationDateReceived(HTTPResponse response, DataPack pack, const char[] error)
{
  pack.Reset();
  Function callback = pack.ReadFunction();
  Handle plugin = pack.ReadCell();
  any data = pack.ReadCell();
  delete pack;
  
  AccountCreationDateResponse accountCreationDateResponse;
  int timestamp;
  
  if (response.Status != HTTPStatus_OK) {
    accountCreationDateResponse = AccountCreationDate_UnknownError;
  }
  else {
    JSONObject root = view_as<JSONObject>(response.Data);
    JSONObject responseObj = view_as<JSONObject>(root.Get("response"));
    JSONArray players = view_as<JSONArray>(responseObj.Get("players"));
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
  Call_PushCell(data);
  Call_Finish();
}

HTTPRequest CreateRequest(const char[] url)
{
  HTTPRequest req = new HTTPRequest(url);
  req.AppendQueryParam("format", "json");
  req.AppendQueryParam("key", apiKey);
  return req;
} 