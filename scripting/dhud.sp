#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <geoip>
#include "kento_rankme/rankme.inc"
#include <stamm>
#include <ttt>

#define TTT_TEAM_UNASSIGNED (1 << 0)
#define TTT_TEAM_INNOCENT (1 << 1)
#define TTT_TEAM_TRAITOR (1 << 2)
#define TTT_TEAM_DETECTIVE (1 << 3)

#pragma newdecls required

/* Global vars*/
bool isTTT;
bool isRank;
bool isStamm;
bool hudEnabled[MAXPLAYERS + 1];
char names[MAXPLAYERS + 1][MAX_MESSAGE_LENGTH];
char countries[MAXPLAYERS + 1][3];
int rankPoints[MAXPLAYERS + 1];
int stammPoints[MAXPLAYERS + 1];
int roles[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Dream HUD",
	author = "Luckiris",
	description = "Print HUD to players",
	version = "1.0",
	url = "https://dream-community.de"
};

public void OnPluginStart()
{
	/* Commands */
	RegConsoleCmd("sm_dhud", CommandHud, "Toggle the hud for the client");
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "ttt"))
	{
		isTTT = true;
	}
	if (StrEqual(name, "kento_rankme"))
	{
		isRank = true;
	}
	if (StrEqual(name, "stamm"))
	{
		isStamm = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "ttt"))
	{
		isTTT = false;
	}
	else if (StrEqual(name, "kento_rankme"))
	{
		isRank = false;
	}
	else if (StrEqual(name, "stamm"))
	{
		isStamm = false;
	}
}

public void OnClientPostAdminCheck(int client)
{
	hudEnabled[client] = true;
	names[client] = UpdateName(client);
	countries[client] = UpdateCountry(client);
	CreateTimer(5.0, TimerUpdateInformation, GetClientUserId(client), TIMER_REPEAT);
	CreateTimer(1.0, TimerShowHud, GetClientUserId(client), TIMER_REPEAT);
}

/* 
	Commands
*/
public Action CommandHud(int client, int args)
{
	/*	Enable or not the HUD for the client 
	
	*/
	if (hudEnabled[client])
	{
		hudEnabled[client] = false;
		PrintCenterText(client, "Dream HUD is off !");
	}
	else
	{
		hudEnabled[client] = true;
		PrintCenterText(client, "Dream HUD is on !");
	}
	return Plugin_Handled;
}

/*
	Timers
*/
public Action TimerUpdateInformation(Handle timer, any data)
{
	/* Vars */
	int client = GetClientOfUserId(data);
	Action result = Plugin_Stop; // <- By default the timer killed itself
	
	if (IsValidClient(client))
	{
		rankPoints[client] = RankMe_GetPoints(client);
		stammPoints[client] = STAMM_GetClientPoints(client);
		result = Plugin_Continue;
	}
	return result;
}

public Action TimerShowHud(Handle timer, any data)
{
	/* Vars */
	int client = GetClientOfUserId(data);
	Action result = Plugin_Stop; // <- By default the timer killed itself
	
	if (IsValidClient(client))
	{
		/* Check if player is alive or not and show the good HUD */
		if (IsPlayerAlive(client))
		{
			ShowAliveHud(client);
		}
		else
		{
			ShowDeadHud(client);
		}
		result = Plugin_Continue;
	}
	return result;
}

/*
	Functions update
*/
char[] UpdateName(int client)
{
	/*	Update name of client 
	
	*/
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	return name;
}

char[] UpdateCountry(int client)
{
	/* Update country of Client
	
	*/
	char country[3], ip[20];
	GetClientIP(client, ip, sizeof(ip));
	GeoipCode2(ip, country);
	return country;
}

/*
	Function EVENT
*/
void TTT_OnClientGetRole(int client, int role)
{
	roles[client] = role;
}

/*
	Functions HUD
*/
void ShowAliveHud(int client)
{
	char message[MAX_MESSAGE_LENGTH];
	
	/* Final format */
	Format(message, sizeof(message), "%s (%s)", names[client], countries[client]);
	
	/* Sending HUD to alive client ... */
	PrintCenterText(client, "%s", message);
}

void ShowDeadHud(int client)
{
	char message[MAX_MESSAGE_LENGTH];
	
	/* Final format */
	Format(message, sizeof(message), "%s (%s) [%s]\n%s %s", names[client], countries[client], GetHudRole(client), GetHudStamm(client), GetHudRank(client));
	
	/* Sending HUD to dead client ... */
	PrintCenterText(client, "%s", message);
}

char[] GetHudRole(int client)
{
	/*	Formatting roles of clients
	
	*/
	char role[20] = "";
	
	if (IsAdmin(client, ADMFLAG_BAN) && isTTT)
	{
		switch(roles[client])
		{
			case TTT_TEAM_INNOCENT:
			{
				Format(role, sizeof(role), "\x01\x04INNOCENT\x01");
			}	
			case TTT_TEAM_UNASSIGNED:
   			{
      			Format(role, sizeof(role), "UNASSIGNED");
   			}
			case TTT_TEAM_TRAITOR: 
			{
				Format(role, sizeof(role), "\x01\x02TRAITOR\x01");			
			}	
			case TTT_TEAM_DETECTIVE: 
			{
				Format(role, sizeof(role), "\x01\x0DETECTIVE\x01");			
			}		
		}
	}
	return role;
}

char[] GetHudStamm(int client)
{
	/*	Formatting stamm of client
	
	*/
	char stamm[20] = "";
	
	if (isStamm)
	{
		IntToString(stammPoints[client], stamm, sizeof(stamm));
	}
	return stamm;
}

char[] GetHudRank(int client)
{
	/*	Formatting stamm of client
	
	*/
	char rank[20] = "";
	
	if (isRank)
	{
		IntToString(rankPoints[client], rank, sizeof(rank));
	}
	return rank;
}

/*
	Functions utils
*/
bool IsValidClient(int client)
{
	/*	Check if the client is in game, connected and not a bot
	
	*/
	bool result = false;
	if (client > 0 && client < MAXPLAYERS && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		result = true;
	}
	return result;
}

bool IsAdmin(int client, int flag)
{
	/*	Check if the clients has the flags
	
	*/
	return CheckCommandAccess(client, "sm_admin", flag, true);
}