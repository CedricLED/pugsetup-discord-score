#include <cstrike>
#include <sourcemod>
#include <SteamWorks>
#include <smjansson>
#include <sdktools>

#include "include/logdebug.inc"
#include "include/pugsetup.inc"

#include "pugsetup/generic.sp"

#pragma semicolon 1

public Plugin myinfo = {
    name = "CSGO Pugsetup: Discord Score",
    author = "Cedric Le Denmat",
    description = "Posts game score to discord on match end",
    version = "1.0.0"
};

#define STEAM_IDS_LENGTH 18

ConVar g_discordBotUrl;
ConVar g_discordBotPass;

public void OnPluginStart()
{
  InitDebugLog("sm_discordbot_debug", "discordbot");
  g_discordBotUrl = CreateConVar("sm_discordbot_url", "http://example.com", "The URL for the API.", FCVAR_PROTECTED);
  g_discordBotPass = CreateConVar("sm_discordbot_pass", "password", "Pass for the API.", FCVAR_PROTECTED);
  AutoExecConfig(true, "pugsetup/pugsetup_discordbot");
  RegConsoleCmd("getpugscore", team_scores);
}

public void PugSetup_OnMatchOver(bool hasDemo, const char[] demoFileName)
{
  char tscore[255];
  int inttscore = CS_GetTeamScore(CS_TEAM_T);
  IntToString(inttscore, tscore, sizeof(tscore));

  char ctscore[255];
  int intctscore = CS_GetTeamScore(CS_TEAM_T);
  IntToString(intctscore, ctscore, sizeof(tscore));

  char tname[255];
  GetTeamName(CS_TEAM_T, tname, sizeof(tname));

  char ctname[255];
  GetTeamName(CS_TEAM_CT, ctname, sizeof(ctname));

  char url[255];
  GetConVarString(g_discordBotUrl, url, sizeof(url));
  char pass[63];
  GetConVarString(g_discordBotPass, pass, sizeof(pass));

  bool responseResult;

  Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, url);
  if (hRequest == INVALID_HANDLE)
  {
    return;
  }
  SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, "state", "result");
  SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, "pass", pass);
  SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, "tscore", tscore);
  SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, "ctscore", ctscore);
  SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, "tname", tname);
  SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, "ctname", ctname);
  SteamWorks_SetHTTPCallbacks(hRequest, OnTransferComplete);
  responseResult = SteamWorks_SendHTTPRequest(hRequest);
  if (!responseResult)
  {
    CloseHandle(hRequest);
  }
}

public OnTransferComplete(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode)
{
  CloseHandle(hRequest);
}

public Action:team_scores(client, argc) {
	new tscore = CS_GetTeamScore(CS_TEAM_T);
	new ctscore = CS_GetTeamScore(CS_TEAM_CT);

	ReplyToCommand(client, "T's = %d, CT's = %d", tscore, ctscore);

	return Plugin_Handled;
}
