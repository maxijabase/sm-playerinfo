#if defined _playerinfo_included
#endinput
#endif
#define _playerinfo_included

enum GameHoursResponse {
	GameHours_Success,
	GameHours_InvalidAppId,
	GameHours_Invisible
}

typedef GameHoursCallback = function void (GameHoursResponse response, int hours);

native int PI_GetGameHours(int client, int appid, GameHoursCallback callback);

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
