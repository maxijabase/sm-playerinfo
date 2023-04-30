#pragma semicolon 1
#pragma newdecls required

#if defined _playerinfo_included
#endinput
#endif
#define _playerinfo_included

enum GameHoursResponse
{
  GameHours_Success, /* Request was successful */
  GameHours_AppIdNotFound, /* App ID was not found within the account */
  GameHours_InvisibleHours, /* Data requested is invisible relative to the API Key owner */
  GameHours_UnknownError, /* Unknown error */
}

enum AccountCreationDateResponse
{
  AccountCreationDate_Success, /* Request was successful */
  AccountCreationDate_InvisibleDate, /* Data requested is invisible relative to the API Key owner */
  AccountCreationDate_UnknownError, /* Unknown error */
}

enum PlayerBansResponse
{
  PlayerBans_Success, /* Request was successful */
  PlayerBans_UnknownError, /* Unknown error */
}

enum EconomyBanStatus
{
  EconomyBan_None, 
  EconomyBan_Probation, 
  EconomyBan_Banned
}

enum struct PlayerBans
{
  bool CommunityBanned;
  bool VACBanned;
  int NumberOfVACBans;
  int DaysSinceLastBan;
  int NumberOfGameBans;
  EconomyBanStatus EconomyBan;
}

typeset GameHoursResponseCallback
{
  function void(GameHoursResponse response, const char[] error, int hours);
  function void(GameHoursResponse response, const char[] error, int hours, any data);
}

typeset AccountCreationDateCallback
{
  function void(AccountCreationDateResponse response, const char[] error, int timestamp);
  function void(AccountCreationDateResponse response, const char[] error, int timestamp, any data);
}

typeset PlayerBansResponseCallback
{
  function void(PlayerBansResponse response, const char[] error, PlayerBans bans);
  function void(PlayerBansResponse response, const char[] error, PlayerBans bans, any data);
}

native int PI_GetGameHours(int client, int appid, GameHoursResponseCallback callback, any data = 0);
native int PI_GetAccountCreationDate(int client, AccountCreationDateCallback callback, any data = 0);
native int PI_GetPlayerBans(int client, PlayerBansResponseCallback callback, any data = 0);

public SharedPlugin __pl_playerinfo = 
{
  name = "playerinfo", 
  file = "playerinfo.smx", 
  #if defined REQUIRE_PLUGIN
  required = 1, 
  #else
  required = 0, 
  #endif
};
