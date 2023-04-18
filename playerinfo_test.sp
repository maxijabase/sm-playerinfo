#include <sourcemod>
#include "include/playerinfo.inc"

public void OnPluginStart() {
    RegConsoleCmd("sm_hours", CMD_Hours);
}

public Action CMD_Hours(int client, int args) {
	PI_GetGameHours(client, 440, OnHoursReceived);
}

public void OnHoursReceived(GameHoursResponse response, const char[] error, int hours) {
	PrintToChatAll("response is %i", response);
	PrintToChatAll("error is %s", error);
	PrintToChatAll("hours of whoever asked are %i", hours / 60);
}