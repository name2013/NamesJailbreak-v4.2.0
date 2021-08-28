#pragma semicolon 1
#define PLUGIN_AUTHOR "Name"
#define PLUGIN_VERSION "4.2.0 (beta version)"
#include <sourcemod>
#include <sourcemod>
#include <sdktools>

#include <cstrike>
#include <sdkhooks>
#include <sdkhooks>
 //#include <smlib>
#pragma newdecls required
////////////////////////////////////////////////////
//ConVars
ConVar c_iResetStat = null;
//Handles
//Handle i_mTimer = null;
//Handle i_mStart = null;
//Booleans
bool IsUserABadGuy[MAXPLAYERS + 1] = false;
bool HasUserShot[MAXPLAYERS + 1] = false;
bool IsClientCut[MAXPLAYERS + 1] = false;
bool IsUserUsed[MAXPLAYERS + 1] = false;
bool IsUserCaptain[MAXPLAYERS + 1] = false;
bool IsUserGuardian[MAXPLAYERS + 1] = false;
bool HasGuardianPicked = false;
bool IsUserUseLess[MAXPLAYERS + 1] = false;
//bool IsGuardCreated = false;
//bool IsNewRound = true;
//Strings
//Ints
//int g_MaxBeam[MAXPLAYERS+1] = 0;
////////////////////////////////////////////////////
EngineVersion g_Game;

public Plugin myinfo = {
  name = "Spartacus Network JailBreak",
  author = PLUGIN_AUTHOR,
  description = "Adds JailBreak Support",
  version = PLUGIN_VERSION,
};
public void OnPluginStart() {
  g_Game = GetEngineVersion();
  if (g_Game != Engine_CSGO && g_Game != Engine_CSS) {
    SetFailState("This plugin is for CSGO/CSS only.");
  }
  //Hooks
  HookEvent("round_start", RoundStart, EventHookMode_PostNoCopy);
  HookEvent("player_spawn", PlayerSpawn, EventHookMode_PostNoCopy);
  HookEvent("player_hurt", PlayerHurt, EventHookMode_PostNoCopy);
  HookEvent("player_death", PlayerDeath);
  HookEvent("player_team", PlayerTeamChange);
  HookEvent("round_end", PreRestart, EventHookMode_Post);
  //AdminCmds
  RegAdminCmd("sm_ul", Command_UseLess, ADMFLAG_BAN, "Make a ct player useless");
  RegAdminCmd("sm_uf", Command_UseFull, ADMFLAG_BAN, "Make a ct player useless");
  //ConVars
  c_iResetStat = CreateConVar("jba_data_reload", "1", "If this is enabled, then player stat of being useless will reset on map change.");
  //ClientCmds
  //ServerCmds
}
public void OnMapStart() {
  if (GetConVarBool(c_iResetStat)) {
    for (int i = 1; i <= MaxClients; i++) {
      if (IsClientConnected(i)) {
        IsUserUseLess[i] = false;
      }
    }
  }
}
public Action Command_UseLess(int client, int args) {
  char m_iTraget[32];
  GetCmdArg(1, m_iTraget, sizeof(m_iTraget));
  int i_mTarget = FindTarget(client, m_iTraget);
  if (GetClientTeam(i_mTarget) == CS_TEAM_CT && IsPlayerAlive(i_mTarget) && !IsUserUseLess[i_mTarget]) {
    IsUserUseLess[i_mTarget] = true;
    PrintToChatAll(" \x04[Name JB] \x09Player \x2%N \x09Is Now Useless!", i_mTarget);
  }
  return Plugin_Handled;
}
public Action Command_UseFull(int client, int args) {
  char m_iTraget[32];
  GetCmdArg(1, m_iTraget, sizeof(m_iTraget));
  int i_mTarget = FindTarget(client, m_iTraget);

  if (GetClientTeam(i_mTarget) == CS_TEAM_CT && IsPlayerAlive(i_mTarget) && IsUserUseLess[i_mTarget]) {
    IsUserUseLess[i_mTarget] = false;
    PrintToChatAll(" \x04[Name JB] \x09Player \x2%N \x09Is Now UseFull!", i_mTarget);
  }
  return Plugin_Handled;
}
public Action OnPlayerRunCmd(int client, int &buttons) {
  int button = GetClientButtons(client);
  if (buttons & IN_ALT1) {
    if (IsUserUsed[client]) {
      return Plugin_Continue;
    }
    int target = GetClientAimTarget(client, true);
	if(target == -1)
	  return Plugin_Handled;
    if (IsUserABadGuy[target] && GetClientTeam(client) == CS_TEAM_CT && !IsClientCut[target]) {
      float Distance = GetEntitiesDistance(client, target);
      if (Distance > 150.0) {
        PrintToChat(client, " \x04[Name JB] \x09Can't Cut ! Player Is Too Far!");
        IsUserUsed[client] = true;
        CreateTimer(0.5, OnTeamTimer, client);
        return Plugin_Handled;
      } else {
        StripAllWeapons(target);
        PrintToChatAll(" \x04[Name JB] \x09Player \x2%N \x09Has Been Cut!", target);
        //IsUserABadGuy[target] = false;
        IsClientCut[target] = true;
        SetEntityRenderMode(target, RENDER_NORMAL);
        SetEntityRenderColor(target, 0, 0, 255, 225);
        //CS_RespawnPlayer(target);
        PrintHintText(target, "You have been cut! You have to call a friend to rescue you before they kill you!");
        SetEntPropFloat(target, Prop_Data, "m_flLaggedMovementValue", 0.0);
        //GivePlayerItem(target, "weapon_knife");
        IsUserUsed[client] = true;
        CreateTimer(0.5, OnTeamTimer, client);
        return Plugin_Handled;
      }
    } else if (IsClientCut[target] && GetClientTeam(client) == CS_TEAM_T && !IsClientCut[client]) {
      float Distance = GetEntitiesDistance(client, target);
      if (Distance > 100.0) {
        PrintToChat(client, " \x04[Name JB] \x09Too far to rescue!");
        IsUserUsed[client] = true;
        CreateTimer(0.5, OnTeamTimer, client);
        return Plugin_Handled;
      } else {
        PrintToChatAll(" \x04[Name JB] \x09Player \x2%N \x09Has Been Rescued!", target);
        PrintToChatAll(" \x04[Name JB] \x09Player \x2%N \x09Is Now A Bad Guy!", client);
        IsUserABadGuy[client] = true;
        IsClientCut[target] = false;
        SetEntityRenderMode(target, RENDER_NORMAL);
        SetEntityRenderColor(target, 225, 0, 0, 225);
        SetEntityRenderColor(client, 225, 0, 0, 225);
        //CS_RespawnPlayer(target);
        GivePlayerItem(target, "weapon_knife");
        SetEntPropFloat(target, Prop_Data, "m_flLaggedMovementValue", 1.0);
        IsUserUsed[client] = true;
        CreateTimer(0.5, OnTeamTimer, client);
        return Plugin_Handled;
      }
    } else if (IsClientCut[target] && GetClientTeam(client) == CS_TEAM_CT && IsUserABadGuy[target]) {
      if (!IsUserCaptain[client] && !IsUserGuardian[client]) {
        PrintToChat(client, " \x04[Name JB] \x09Only captain or guardian can forgive cut users!");
        IsUserUsed[client] = true;
        CreateTimer(0.5, OnTeamTimer, client);
        return Plugin_Handled;
      }
      float Distance = GetEntitiesDistance(client, target);
      if (Distance > 200.0) {
        PrintToChat(client, " \x04[Name JB] \x09Too far to forgive!");
        IsUserUsed[client] = true;
        CreateTimer(0.5, OnTeamTimer, client);
        return Plugin_Handled;
      } else {
        PrintToChatAll(" \x04[Name JB] \x09Player \x2%N \x09Has Been Forgiven!", target);
        //PrintToChatAll(" \x04[Name JB] \x09Player \x2%N \x09Is Now A Bad Guy!", client);
        IsUserABadGuy[target] = false;
        IsClientCut[target] = false;
        SetEntityRenderMode(target, RENDER_NORMAL);
        SetEntityRenderColor(target, 0, 255, 0, 225);
        //SetEntityRenderColor(client, 225, 0, 0, 225);
        //CS_RespawnPlayer(target);
        GivePlayerItem(target, "weapon_knife");
        SetEntPropFloat(target, Prop_Data, "m_flLaggedMovementValue", 1.0);
        IsUserUsed[client] = true;
        CreateTimer(0.5, OnTeamTimer, client);
        return Plugin_Handled;
      }
    } else if (IsUserCaptain[client] && HasGuardianPicked == false && GetClientTeam(target) == CS_TEAM_CT) {
      if (GetTeamPlayers(2, false) <= 9) {
        PrintToChat(client, " \x04[Name JB] \x09Cannot Hire Any Guardians at this moment!");
        IsUserUsed[client] = true;
        CreateTimer(0.5, OnTeamTimer, client);
        return Plugin_Handled;
      }
      float Distance = GetEntitiesDistance(client, target);
      if (Distance > 200.0) {
        PrintToChat(client, " \x04[Name JB] \x09Too far to hire!");
        IsUserUsed[client] = true;
        CreateTimer(0.5, OnTeamTimer, client);
        return Plugin_Handled;
      } else {
        PrintToChatAll(" \x04[Name JB] \x09Player \x2%N \x09Has Been Hired for being a Guardian!", target);
        IsUserGuardian[target] = true;
        HasGuardianPicked = true;
        SetEntityRenderMode(target, RENDER_NORMAL);
        SetEntityRenderColor(target, 255, 0, 255, 225);
        GivePlayerItem(target, "weapon_tagrenade");
      }
    }
  }

  if (buttons & IN_ATTACK2) {
    if (IsUserCaptain[client]) {
      SparkIt(client);
    }
  }

  return Plugin_Continue;
}
public Action OnTeamTimer(Handle timer, any client) {
  IsUserUsed[client] = false;
}
//3 = CT , 2 = T.

public Action PlayerTeamChange(Handle event,
  const char[] name, bool dontBroadcast) {
  int client = GetClientOfUserId(GetEventInt(event, "userid"));
  int team = GetEventInt(event, "team");
  if (team == 2) {
    IsUserCaptain[client] = false;
    IsUserGuardian[client] = false;
    HasGuardianPicked = false;
    IsUserABadGuy[client] = false;
    HasUserShot[client] = false;
    PrintToChatAll(" \x04[Name JB] \x09Player \x02%N \x09 Has Changed His Team To \x02Terrorists!", client);
  } else if (team == 3) {
    IsUserCaptain[client] = false;
    IsUserGuardian[client] = false;
    HasGuardianPicked = false;
    IsUserABadGuy[client] = false;
    HasUserShot[client] = false;
    IsClientCut[client] = false;
    //BaseComm_SetClientMute(client, false);
    PrintToChatAll(" \x04[Name JB] \x09Player \x02%N \x09 Has Changed His Team To \x02Counter-Terrorists!", client);
  }
}
public Action PreRestart(Handle event,
  const char[] name, bool dontBroadcast) {
  /*
  int CTCount = GetTeamPlayers(3, false);
  CTCount = CTCount + 3;
  int TCount = GetTeamPlayers(2, false);
  do
  {
  	int User = GetRandomAllPlayer(3);
  	//SetEntPropEnt(User, Prop_Send, "m_iTeamNum", 2);
  	ChangeClientTeam(User, 2);
  }
  while(CTCount >= TCount && CTCount >= 1);
  */
  //IsNewRound = true;
  //ServerCommand("bot_kick");
  for (int x = 1; x <= MaxClients; x++) {
    if (IsClientInGame(x) && IsPlayerAlive(x)) {
      SetEntityRenderMode(x, RENDER_NORMAL);
      SetEntityRenderColor(x, 225, 225, 225, 225);
    }
  }
  //KillTimer(i_mTimer);
  //KillTimer(i_mStart);
}
public Action PlayerDeath(Handle event,
  const char[] name, bool dontBroadcast) {
  int client = GetClientOfUserId(GetEventInt(event, "userid"));
  if (IsUserCaptain[client]) {
    int g_iCaptain;
    int w_FailAttempts = 0;
    int w_MaxFailAttempts = GetTeamPlayers(3, true);
    do {
      if (w_FailAttempts == w_MaxFailAttempts) {
        PrintToChatAll(" \x04[Name JB] \x09Setting Captain has failed! All CT Members are useless or no-one is alive!");
        break;
      }
      w_FailAttempts++;
      g_iCaptain = GetRandomPlayer(3);
      if (!IsUserUseLess[g_iCaptain] && IsPlayerAlive(g_iCaptain)) {
        SetEntityRenderMode(g_iCaptain, RENDER_NORMAL);
        SetEntityRenderColor(g_iCaptain, 225, 225, 0, 225);
        IsUserCaptain[g_iCaptain] = true;
        PrintToChatAll(" \x04[Name JB] \x09Player \x2%N \x09Is Now Captain!", g_iCaptain);
        GivePlayerItem(g_iCaptain, "weapon_tagrenade");
      }
    }
    while (IsUserUseLess[g_iCaptain] && !IsPlayerAlive(g_iCaptain));
  }

}
public Action RoundStart(Handle event,
  const char[] name, bool dontBroadcast) {
  //int client = GetClientOfUserId(GetEventInt(event, "userid"));
  //IsGuardCreated = false;
  for (int i = 1; i <= MaxClients; i++) {
    //g_MaxBeam[i] = 0;
    if (IsClientConnected(i)) {
      IsUserCaptain[i] = false;
      IsUserGuardian[i] = false;
      HasGuardianPicked = false;
      IsUserABadGuy[i] = false;
      HasUserShot[i] = false;
      IsClientCut[i] = false;
    }
    if (IsClientConnected(i) && IsFakeClient(i)) {
      KickClient(i);
    }
  }
  //PrintToChatAll(" \x04[Name JB] \x09All Terrists Have Muted For 30 Seconds!");
  int g_iCaptain;
  int w_FailAttempts = 0;
  int w_MaxFailAttempts = GetTeamPlayers(3, true);
  do {
    if (w_MaxFailAttempts == 0) {
      PrintToChatAll(" \x04[Name JB] \x09Setting Captain has failed! There is no-one on CT Side!");
      break;
    }
    if (w_FailAttempts == w_MaxFailAttempts) {
      PrintToChatAll(" \x04[Name JB] \x09Setting Captain has failed! All CT Members are useless or no-one is alive!");
      break;
    }
    w_FailAttempts++;
    g_iCaptain = GetRandomPlayer(3);
    if (!IsUserUseLess[g_iCaptain]) {
      SetEntityRenderMode(g_iCaptain, RENDER_NORMAL);
      SetEntityRenderColor(g_iCaptain, 225, 225, 0, 225);
      IsUserCaptain[g_iCaptain] = true;
      PrintToChatAll(" \x04[Name JB] \x09Player \x2%N \x09Is Now Captain!", g_iCaptain);
      GivePlayerItem(g_iCaptain, "weapon_tagrenade");
    }
  }
  while (IsUserUseLess[g_iCaptain]);
  PrintToChatAll(" \x04[Name JB] \x09Terrorist's state has been changed to Inconnect!");
  /*
  if(IsNewRound)
  {
  	i_mTimer = CreateTimer(150.0, Timer_SetState);
  	i_mStart = CreateTimer(30.0, Timer_SetUnMute);
  	IsNewRound = false;
  }
  */
}
public Action PlayerSpawn(Handle event,
  const char[] name, bool dontBroadcast) {
  int client = GetClientOfUserId(GetEventInt(event, "userid"));
  if (!client)
    return Plugin_Continue;
  SetEntityRenderMode(client, RENDER_NORMAL);
  SetEntityRenderColor(client, 225, 225, 225, 225);
  if (GetClientTeam(client) == CS_TEAM_T) {
    //Client_RemoveAllWeapons(client, "weapon_knife", true);
    StripAllWeapons(client);
    GivePlayerItem(client, "weapon_knife");
  }
  return Plugin_Continue;
}

public Action PlayerHurt(Handle event,
  const char[] name, bool dontBroadcast) {
  int victim = GetClientOfUserId(GetEventInt(event, "userid"));
  int n_iattacker = GetClientOfUserId(GetEventInt(event, "attacker"));
  //char WeaponName[32];
  //GetClientWeapon(client, WeaponName, sizeof(WeaponName);
  if (IsUserABadGuy[n_iattacker] == false && GetClientTeam(victim) == CS_TEAM_CT && GetClientTeam(n_iattacker) != CS_TEAM_CT) {
    IsUserABadGuy[n_iattacker] = true;
    HasUserShot[n_iattacker] = true;
    char PlayerName[MAX_NAME_LENGTH];
    GetClientName(n_iattacker, PlayerName, sizeof(PlayerName));
    PrintToChatAll(" \x04[Name JB] \x09Player \x2%s \x09Has Shot And Is Now a Bad Guy!", PlayerName);
    SetEntityRenderMode(n_iattacker, RENDER_NORMAL);
    SetEntityRenderColor(n_iattacker, 225, 0, 0, 225);
  }
  return Plugin_Continue;
}

public void OnClientPutInServer(int client) {
  SDKHook(client, SDKHook_OnTakeDamage, OnDamage);
  SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
  SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
}
public Action OnWeaponDrop(int client, int weapon) {
  if (GetClientTeam(client) != CS_TEAM_CT) {
    return Plugin_Continue;
  } else {
    if (weapon == -1) {
      return Plugin_Continue;
    }
    char g_iClassName[32];
    GetEdictClassname(weapon, g_iClassName, sizeof(g_iClassName));
    if (StrEqual(g_iClassName, "weapon_tagrenade", false)) {
      if (IsUserCaptain[client]) {
        GivePlayerItem(client, "weapon_tagrenade");
        return Plugin_Handled;
      }
    } else if (!StrEqual(g_iClassName, "weapon_knife") && !StrEqual(g_iClassName, "weapon_decoy") && !StrEqual(g_iClassName, "weapon_flashbang") && !StrEqual(g_iClassName, "weapon_smokegrenade") &&
      !StrEqual(g_iClassName, "weapon_healthshot") && !StrEqual(g_iClassName, "weapon_taser")) {
      PrintToChat(client, " \x04[Name JB] \x09You Cannot Drop Your Gun!");
      return Plugin_Handled;
    } else
      return Plugin_Continue;
  }
}
public Action OnWeaponSwitch(int client, int weapon) {
  if (IsUserABadGuy[client] == false && GetClientTeam(client) == CS_TEAM_T) {
    char WeaponName[32], PlayerName[MAX_NAME_LENGTH];
    GetEdictClassname(weapon, WeaponName, sizeof(WeaponName));
    if (!IsItemSafe(WeaponName)) {
      IsUserABadGuy[client] = true;
      GetClientName(client, PlayerName, sizeof(PlayerName));
      PrintToChatAll(" \x04[Name JB] \x09Player \x2%s \x09Is Now a Bad Guy!", PlayerName);
      SetEntityRenderMode(client, RENDER_NORMAL);
      SetEntityRenderColor(client, 225, 0, 0, 225);
    }
  }
}
public Action OnDamage(int victim, int & attacker, int & inflictor, float & damage, int & damagetype) {
  if (IsUserCaptain[attacker]) {
    return Plugin_Continue;
  }
  if (IsUserGuardian[attacker]) {
    return Plugin_Continue;
  }
  if (IsClientCut[attacker]) {
    return Plugin_Handled;
  }
  if (GetClientTeam(victim) == CS_TEAM_T && IsUserABadGuy[victim] == false) {
    if (GetClientTeam(attacker) == CS_TEAM_T) {
      return Plugin_Continue;
    } else {
      ForcePlayerSuicide(attacker);
      char PlayerName[MAX_NAME_LENGTH];
      GetClientName(attacker, PlayerName, sizeof(PlayerName));
      PrintToChatAll(" \x04[Name JB] \x09Player \x2%s \x09Has Slayed for hurting an inoccent!", PlayerName);
      return Plugin_Handled;
    }
  } else if (GetClientTeam(victim) == CS_TEAM_CT && IsUserABadGuy[attacker] == false) {
    if (GetClientTeam(attacker) == CS_TEAM_CT) {
      return Plugin_Handled;
    }
    char WeaponName[32];
    GetClientWeapon(attacker, WeaponName, sizeof(WeaponName));
    if (StrEqual(WeaponName, "weapon_knife")) {
      //ForcePlayerSuicide(attacker);
      char PlayerName[MAX_NAME_LENGTH];
      GetClientName(attacker, PlayerName, sizeof(PlayerName));
      IsUserABadGuy[attacker] = true;
      PrintToChatAll(" \x04[Name JB] \x09Player \x2%s \x09Is Now a Bad Guy!", PlayerName);
      SetEntityRenderMode(attacker, RENDER_NORMAL);
      SetEntityRenderColor(attacker, 225, 0, 0, 225);
      return Plugin_Handled;
    }
  }
  if (GetClientTeam(attacker) == CS_TEAM_T) {
    HasUserShot[attacker] = true;
  }
  return Plugin_Continue;
}

stock int GetPlayerCount() {
  int PlayerNumb = 0;
  for (int x = 1; x <= MaxClients; x++) {
    if (IsClientInGame(x) && !IsFakeClient(x)) {
      PlayerNumb++;
    }
  }
  return PlayerNumb;
}
stock int GetTeamPlayers(int team, bool Alive) {
  int TSide = 0;
  int CtSide = 0;
  if (Alive) {
    for (int x = 1; x <= MaxClients; x++) {
      if (IsClientInGame(x) && !IsFakeClient(x) && GetClientTeam(x) == 2 && IsPlayerAlive(x)) {
        TSide++;
      }
      if (IsClientInGame(x) && !IsFakeClient(x) && GetClientTeam(x) == 3 && IsPlayerAlive(x)) {
        CtSide++;
      }
    }
  }
  if (!Alive) {
    for (int x = 1; x <= MaxClients; x++) {
      if (IsClientInGame(x) && !IsFakeClient(x) && GetClientTeam(x) == 2) {
        TSide++;
      }
      if (IsClientInGame(x) && !IsFakeClient(x) && GetClientTeam(x) == 3) {
        CtSide++;
      }
    }
  }
  if (team == 2) {
    return TSide;
  } else if (team == 3) {
    return CtSide;
  } else
    return 0;
}
stock float GetEntitiesDistance(int ent1, int ent2) {
  float orig1[3];
  GetEntPropVector(ent1, Prop_Send, "m_vecOrigin", orig1);

  float orig2[3];
  GetEntPropVector(ent2, Prop_Send, "m_vecOrigin", orig2);

  return GetVectorDistance(orig1, orig2);
}
public int GetRandomPlayer(int team) {
  int RandomClient;

  ArrayList ValidClients = new ArrayList();

  for (int i = 1; i < MaxClients; i++) {
    if (IsValidClient(i) && GetClientTeam(i) == team && IsPlayerAlive(i)) {
      ValidClients.Push(i);
    }
  }

  RandomClient = ValidClients.Get(GetRandomInt(0, ValidClients.Length - 1));

  delete ValidClients;

  return RandomClient;
}

public int GetRandomAllPlayer(int team) {
  int RandomClient;

  ArrayList ValidClients = new ArrayList();

  for (int i = 1; i < MaxClients; i++) {
    if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team) {
      ValidClients.Push(i);
    }
  }

  RandomClient = ValidClients.Get(GetRandomInt(0, ValidClients.Length - 1));

  delete ValidClients;

  return RandomClient;
}

stock bool IsValidClient(int client) {
  return (1 <= client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client) && IsPlayerAlive(client));
}

stock void StripAllWeapons(int client) {

  if (client < 1 || client > MaxClients || !IsClientInGame(client)) {

    return;

  }

  int weapon;
  for (int i; i < 4; i++) {

    if ((weapon = GetPlayerWeaponSlot(client, i)) != -1) {

      if (IsValidEntity(weapon)) {

        RemovePlayerItem(client, weapon);
        AcceptEntityInput(weapon, "Kill");

      }

    }

  }
}
stock void SparkIt(int client) {
  float g_bAngel[3], g_bPos[3];
  g_bAngel = {
    0.0,
    0.0,
    5.0
  };
  if (GetPlayerEye(client, g_bPos)) {
    TE_SetupMetalSparks(g_bPos, g_bAngel);
    TE_SendToAll();
  }
}
bool GetPlayerEye(int client, float pos[3]) {
  float vAngles[3], vOrigin[3];
  GetClientEyePosition(client, vOrigin);
  GetClientEyeAngles(client, vAngles);

  Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

  if (TR_DidHit(trace)) {
    TR_GetEndPosition(pos, trace);
    CloseHandle(trace);
    return true;
  }
  CloseHandle(trace);
  return false;
}
public bool TraceEntityFilterPlayer(int entity, int contentsMask) {
  return entity > GetMaxClients();
}

bool IsItemSafe(char[] Classname) {
  char Path[PLATFORM_MAX_PATH], i_nBannedClassName[32];
  BuildPath(Path_SM, Path, sizeof(Path), "configs/jailconfig.cfg");
  KeyValues kv = new KeyValues("jailbreakconfigs");
  kv.ImportFromFile(Path);
  if (kv.JumpToKey("safe_items")) {
    kv.GotoFirstSubKey(false);
    do {
      kv.GetSectionName(i_nBannedClassName, sizeof(i_nBannedClassName));
      if (StrEqual(i_nBannedClassName, Classname, false)) {
        delete kv;
        return true;
      } else if (kv.GotoNextKey(false)) {
        continue;
      } else {
        delete kv;
        return false;
      }
    }
    while (!StrEqual(i_nBannedClassName, Classname, false));
  } else {
    delete kv;
    return false;
  }
  delete kv;
  return false;
}

bool SetUselessClient(int client)
{
	char Path[PLATFORM_MAX_PATH], SteamAuth[32];
	BuildPath(Path_SM, Path, sizeof(Path), "configs/jailconfig.cfg");
	KeyValues kv = new KeyValues("jailbreakconfigs");
	kv.ImportFromFile(Path);
	if(kv.JumpToKey("useless_list", true))
	{
		GetClientAuthId(client, AuthId_Steam2, SteamAuth, sizeof(SteamAuth));
		kv.SetString(SteamAuth, "0");
		kv.Rewind();
		kv.ExportToFile(Path);
		delete kv;
		return true;
	}
	else
	{
		delete kv;
		return false;
	}
	delete kv;
	return false;
}
bool RemoveUselessClient(int client)
{
	char Path[PLATFORM_MAX_PATH], SteamAuth[32];
	BuildPath(Path_SM, Path, sizeof(Path), "configs/jailconfig.cfg");
	KeyValues kv = new KeyValues("jailbreakconfigs");
	kv.ImportFromFile(Path);
	if(kv.JumpToKey("useless_list", true))
	{
		GetClientAuthId(client, AuthId_Steam2, SteamAuth, sizeof(SteamAuth));
		if(kv.JumpToKey("SteamAuth", false))
		{
			kv.DeleteThis();
			kv.Rewind();
			kv.ExportToFile(Path);
			delete kv;
			return true;
		}
		else
		{
			delete kv;
			return false;
		}
	}
	else
	{
		delete kv;
		return false;
	}
	delete kv;
	return false;
}
bool IsUselessClient(int client)
{
	char Path[PLATFORM_MAX_PATH], SteamAuth[32], m_iSectionName[32];
	BuildPath(Path_SM, Path, sizeof(Path), "configs/jailconfig.cfg");
	KeyValues kv = new KeyValues("jailbreakconfigs");
	kv.ImportFromFile(Path);
	if(kv.JumpToKey("useless_list", false))
	{
		GetClientAuthId(client, AuthId_Steam2, SteamAuth, sizeof(SteamAuth));
		kv.GotoFirstSubKey(false);
		do
		{	
			kv.GetSectionName(m_iSectionName, sizeof(m_iSectionName));
			if(StrEqual(m_iSectionName, SteamAuth, false))
			{
				delete kv;
				return true;
			}
			else if(kv.GotoNextKey(false))
			{
				continue;
			}
			else
			{
				delete kv;
				return false;
			}
		}
		while(!StrEqual(m_iSectionName, SteamAuth, false));
	}
	else
	{
		delete kv;
		return false;
	}
	delete kv;
	return false;
}
