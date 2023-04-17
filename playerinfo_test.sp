#include <sourcemod>
#include "playerinfo.inc"

public void OnPluginStart() {
    RegConsoleCmd("sm_hours", CMD_Hours);
}

public Action CMD_Hours(int client, int args) {
	PI_GetGameHours(client, 440, OnHoursReceived);
}

public void OnHoursReceived(GameHoursResponse response, int hours) {
	PrintToServer("adsfkljsdfklsdjf");
	PrintToChatAll("hours of whoever asked are %i", hours / 60);
}