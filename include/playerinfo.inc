#if defined _playerinfo_included
#endinput
#endif
#define _playerinfo_included

enum GameHoursResponse {
	GameHours_Success, /* Request was successful */
	GameHours_AppIdNotFound, /* App ID was not found within the account */
	GameHours_InvisibleHours, /* Data requested is invisible relative to the API Key owner */
	GameHours_UnknownError, /* Unknown error */
}

enum AccountCreationDateResponse {
	AccountCreationDate_Success, /* Request was successful */
	AccountCreationDate_InvisibleDate, /* Data requested is invisible relative to the API Key owner */
	AccountCreationDate_UnknownError, /* Unknown error */
}

typedef GameHoursResponseCallback = function void(GameHoursResponse response, const char[] error, int hours);

typedef AccountCreationDateCallback = function void(AccountCreationDateResponse response, const char[] error, int timestamp);

native int PI_GetGameHours(int client, int appid, GameHoursResponseCallback callback);

native int PI_GetAccountCreationDate(int client, AccountCreationDateCallback callback)

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
