#pragma semicolon 1
#pragma newdecls required

#if defined _playerinfo_included
#endinput
#endif
#define _playerinfo_included

enum GameHoursResponse
{
  GameHours_Success, // Request was successful
  GameHours_AppIdNotFound, // App ID was not found within the account
  GameHours_InvisibleHours, // Data requested is invisible relative to the API Key owner
  GameHours_UnknownError, // Unknown error
  GameHours_SteamIdFail // Could not retrieve Steam ID
}

enum AccountCreationDateResponse
{
  AccountCreationDate_Success, // Request was successful
  AccountCreationDate_InvisibleDate, // Data requested is invisible relative to the API Key owner
  AccountCreationDate_UnknownError, // Unknown error
  AccountCreationDate_SteamIdFail // Could not retrieve Steam ID
}

enum PlayerBansResponse
{
  PlayerBans_Success, // Request was successful
  PlayerBans_UnknownError, // Unknown error
  PlayerBans_SteamIdFail // Could not retrieve Steam ID
}

enum SteamLevelResponse
{
  SteamLevel_Success, // Request was successful
  SteamLevel_InvisibleLevel, // Data requested is invisible relative to the API Key owner
  SteamLevel_UnknownError, // Unknown error
  SteamLevel_SteamIdFail // Could not retrieve Steam ID
}

enum ProfilePrivacyResponse
{
  ProfilePrivacy_Public, // Profile is public
  ProfilePrivacy_FriendsOnly, // Profile is friends-only
  ProfilePrivacy_Private, // Profile is private
  ProfilePrivacy_UnknownError, // Unknown error
  ProfilePrivacy_SteamIdFail // Could not retrieve Steam ID
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

typeset SteamLevelResponseCallback
{
  function void(SteamLevelResponse response, const char[] error, int level);
  function void(SteamLevelResponse response, const char[] error, int level, any data);
}

typeset ProfilePrivacyResponseCallback
{
  function void(ProfilePrivacyResponse response, const char[] error);
  function void(ProfilePrivacyResponse response, const char[] error, any data);
}

native void PI_GetGameHours(int client, int appid, GameHoursResponseCallback callback, any data = 0);
native void PI_GetAccountCreationDate(int client, AccountCreationDateCallback callback, any data = 0);
native void PI_GetPlayerBans(int client, PlayerBansResponseCallback callback, any data = 0);
native void PI_GetSteamLevel(int client, SteamLevelResponseCallback callback, any data = 0);
native void PI_GetProfilePrivacy(int client, ProfilePrivacyResponseCallback callback, any data = 0);

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
