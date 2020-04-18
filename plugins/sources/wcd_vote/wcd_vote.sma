/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <sockets>

#define PLUGIN "WCD Vote"
#define VERSION "1.0"
#define AUTHOR "WarGods Team"

#define CMDTARGET_NO_BOTS 8
#define MINIMUM_NUMBER_OF_VOTES_DENOMINATOR 2.0
#define ALLOWED_TIME_TO_SCAN 300
#define REMOTE_HOST "wargods.ro"
#define SCRIPT_PATH "/wcd/checkResult.php"

#define BAN_REASON_DISCONNECT 1
#define BAN_REASON_CHEAN_ON 2
#define BAN_REASON_NO_SCAN 3

new votesToRequestTheScan[33];
new votesMap[33][33]; //[whoVoted][forWhoVoted]
new scanInProgress[33];
new pluginActive;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd ("say", "checkForVoteCommand" );
	register_clcmd("amx_votewcd", "voteForWcd");
	
	pluginActive = 1;
	//@ToDo: For the users that were in scanning before map changed, resume the scannings.
}


public client_connect(userIndex) {
	votesToRequestTheScan[userIndex] = 0;
	scanInProgress[[userIndex] = 0;
	for(new i = 1; i < 33; i++) {
		votesMap[userIndex][i] = 0;
	}
}

public client_disconnected(userIndex, dropByServer) {
	removeActiveScanRequest(userIndex);
	
	if(pluginActive && !dropByServer && scanInProgress(userIndex)) {
		banUser(userIndex, BAN_REASON_DISCONNECT);
	}
}

public server_changelevel() {
	pluginActive = false; //Don't ban the users if the server disconnected them for changemap.
	//@ToDo: Save active scannings in file
}

removeActiveScanRequest(userIndex) {
		scanInProgress[[userIndex] = 0;
		remove_task(userIndex + 12340); //Remove the leftover scanning task.	
}

banUser(userIndex, banReason) {
	
}

public checkForVoteCommand(id) {
	
	static s_Args[32]
	
	read_args(s_Args, sizeof(s_Args) - 1);
	remove_quotes(s_Args);
	
	if(equal(s_Args, "/votewcd", 8)) {
		replace(s_Args, sizeof(s_Args) - 1, "/", "");
		client_cmd(id, "amx_%s", s_Args);
	}
	
	return PLUGIN_CONTINUE;
}

public voteForWcd(id) {
	new targetUserName[64];
	read_argv(1, s_Arg1, sizeof(targetUserName) - 1);
	
	new targetUserIndex = cmd_target(id, targetUserName, CMDTARGET_NO_BOTS);
	
	if(!targetUserIndex) {
		print(id, "^x03[Wargods] Could not find the user");
		return PLUGIN_HANDLED;
	}
	
	if(!scanInProgress(targetUserIndex) && !alreadyVotedForThePlayer(id, targetUserIndex)) {
		votesToRequestTheScan[targetUserIndex] = votesToRequestTheScan[targetUserIndex] + 1;
		votesMap[id, targetUserIndex] = 1;
		
		if(votesToRequestTheScan[targetUserIndex] >= get_playersnum() / MINIMUM_NUMBER_OF_VOTES_DENOMINATOR) {
			requestScan(targetUserIndex);
		}
		
	}
	
}

alreadyVotedForThePlayer(whoVotedIndex, forWhoVotedIndex) {
	return votesMap[whoVotedIndex][forWhoVotedIndex] == 1;
}

scanInProgress(userIndex) {
	return scanInProgress[userIndex] == 1;
}

requestScan(targetUserIndex) {
	new playerDetails[4][40];
	format(playerDetails[0],"%d", targetUserIndex);
	get_user_ip(targetUserIndex, playerDetails[1], sizeof(playerDetails[1]) - 1);
	get_user_name(targetUserIndex, playerDetails[2], sizeof(playerDetails[2]) - 1);
	format(playerDetails[4],"%d", get_user_userid(targetUserIndex));
	
	scanInProgress[targetUserIndex] = 1;
	new uniqueTaskId = targetUserIndex + 12340;
	set_task(ALLOWED_TIME_TO_SCAN, "checkWCDResult", uniqueTaskId ,playerDetails, 4, "a", 1)
}


checkWcdResult() {
	new error = 0;
	new constring[512]
	
	removeActiveScanRequest(userIndex);
	
	new g_sckweb = socket_open(REMOTE_HOST, 80, SOCKET_TCP, error);
	if (g_sckweb > 0)
	{
		format(constring,511,"GET %s?ip=%s HTTP/1.1^nHost: %s^n^n",SCRIPT_NAME, userIp,REMOTE_HOST)
		socket_send(g_sckweb, constring, 511)
		read_web(g_sckweb, userIndex);
	}
	else
	{
		switch (error)
		{
			case 1: { server_print("Error creating socket"); }
			case 2: { server_print("Error resolving remote hostname"); }
			case 3: { server_print("Error connecting socket"); }
		}
		
		return PLUGIN_CONTINUE
	}
}

public read_web(g_sckweb, userIndex) {
	const SIZE = 63
	new line_variable[SIZE + 1], line_value[SIZE + 1]
	
	if (socket_is_readable(g_sckweb, 60))
	{
		new buf[512], lines[30][100], count = 0
		socket_recv(g_sckweb, buf, 511);
		socket_close(g_sckweb);
		
		if(equali("CheatOn", buf)) {
			banUser(userIndex, BAN_REASON_CHEAN_ON);	
		}
		
		if(equali("NoScan", buf)) {
			banUser(userIndex, BAN_REASON_NO_SCAN);	
		}
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg1250\\ deff0\\ deflang1048{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ f0\\ fs16 \n\\ par }
*/
