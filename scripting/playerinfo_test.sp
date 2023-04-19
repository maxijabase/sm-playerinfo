#include <sourcemod>
#include "include/playerinfo.inc"

public void OnPluginStart() {
	RegConsoleCmd("sm_hours", CMD_Hours);
	RegConsoleCmd("sm_time", CMD_Time);
	RegConsoleCmd("sm_bans", CMD_Bans);
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
}

public void OnHoursReceived(GameHoursResponse response, const char[] error, int hours) {
	PrintToChatAll("response is %i", response);
	PrintToChatAll("error is %s", error);
	PrintToChatAll("hours of whoever asked are %i", hours / 60);
}

public void OnAccountCreationDateReceived(AccountCreationDateResponse response, const char[] error, int timestamp) {
	PrintToChatAll("response is %i", response);
	PrintToChatAll("timestamp is %i", timestamp);
	char time[64];
	FormatTime(time, sizeof(time), "%b %d, %Y (%R)", timestamp);
	PrintToChatAll(time);
}

public void OnBansReceived(PlayerBansResponse response, const char[] error, PlayerBans bans) {
	PrintToChatAll("commbanned: %d", bans.CommunityBanned);
	PrintToChatAll("vac: %d", bans.VACBanned);
	PrintToChatAll("vacs: %i", bans.NumberOfVACBans);
	PrintToChatAll("days since last vac: %i", bans.DaysSinceLastBan);
	PrintToChatAll("Game bans: %i", bans.NumberOfGameBans);
	PrintToChatAll("Economyban: %i", bans.EconomyBan);
} 