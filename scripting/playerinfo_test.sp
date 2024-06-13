#include <sourcemod>
#include "include/playerinfo.inc"

public void OnPluginStart() {
  RegConsoleCmd("sm_hours", CMD_Hours);
  RegConsoleCmd("sm_time", CMD_Time);
  RegConsoleCmd("sm_bans", CMD_Bans);
  RegConsoleCmd("sm_level", CMD_Level);
}

public Action CMD_Hours(int client, int args) {
  PI_GetGameHours(client, 440, OnHoursReceived);
  return Plugin_Handled;
}

public Action CMD_Time(int client, int args) {
  PI_GetAccountCreationDate(client, OnAccountCreationDateReceived)
  return Plugin_Handled;
}

public Action CMD_Bans(int client, int args) {
  PI_GetPlayerBans(client, OnBansReceived);
  return Plugin_Handled;
}

public Action CMD_Level(int client, int args) {
  char arg1[32];
  GetCmdArg(1, arg1, sizeof(arg1));
  
  PI_GetSteamLevel(client, OnLevelReceived, StringToInt(arg1));
  return Plugin_Handled;
}

public void OnHoursReceived(GameHoursResponse response, const char[] error, int hours) {
  if (response == GameHours_SteamIdFail) {
    PrintToChatAll("OnHoursReceived: Failed to retrieve Steam ID!")
    return;
  }
  PrintToChatAll("response is %i", response);
  PrintToChatAll("error is %s", error);
  PrintToChatAll("hours of whoever asked are %i", hours / 60);
}

public void OnAccountCreationDateReceived(AccountCreationDateResponse response, const char[] error, int timestamp) {
  if (response == AccountCreationDate_SteamIdFail) {
    PrintToChatAll("OnAccountCreationDateReceived: Failed to retrieve Steam ID!")
    return;
  }
  PrintToChatAll("response is %i", response);
  PrintToChatAll("timestamp is %i", timestamp);
  char time[64];
  FormatTime(time, sizeof(time), "%b %d, %Y (%R)", timestamp);
  PrintToChatAll(time);
}

public void OnBansReceived(PlayerBansResponse response, const char[] error, PlayerBans bans) {
  if (response == PlayerBans_SteamIdFail) {
    PrintToChatAll("OnBansReceived: Failed to retrieve Steam ID!")
    return;
  }
  PrintToChatAll("commbanned: %d", bans.CommunityBanned);
  PrintToChatAll("vac: %d", bans.VACBanned);
  PrintToChatAll("vacs: %i", bans.NumberOfVACBans);
  PrintToChatAll("days since last vac: %i", bans.DaysSinceLastBan);
  PrintToChatAll("Game bans: %i", bans.NumberOfGameBans);
  PrintToChatAll("Economyban: %i", bans.EconomyBan);
} 

public void OnLevelReceived(SteamLevelResponse response, const char[] error, int level, int number) {
  if (response == SteamLevel_SteamIdFail) {
    PrintToChatAll("OnLevelReceived: Failed to retrieve Steam ID!")
    return;
  }
  PrintToChatAll("response is %d", response);
  PrintToChatAll("Steam level is %d", level);
  PrintToChatAll("Input was %d", number);
}