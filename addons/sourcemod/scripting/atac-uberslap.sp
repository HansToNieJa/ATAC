#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <atac>

#pragma newdecls required
#pragma semicolon 1

#define SOUND_EXPLODE "ambient/explosions/explode_8.wav"

public Plugin myinfo =
{
    name        = "ATAC - UberSlap Punishment",
    author      = "GameConnect",
    description = "Advanced Team Attack Control",
    version     = ATAC_VERSION,
    url         = "http://www.gameconnect.net"
};


/**
 * Globals
 */
int g_iExplosionModel;
int g_iLightningModel;
int g_iSmokeModel;


/**
 * Plugin Forwards
 */
public void OnPluginStart()
{
    // Load translations
    LoadTranslations("atac-uberslap.phrases");

    if (LibraryExists("atac")) {
        OnLibraryAdded("atac");
    }
}

public void OnMapStart()
{
    g_iExplosionModel = PrecacheModel("materials/effects/fire_cloud1.vmt");
    g_iLightningModel = PrecacheModel("materials/sprites/tp_beam001.vmt");
    g_iSmokeModel     = PrecacheModel("materials/effects/fire_cloud2.vmt");

    PrecacheSound(SOUND_EXPLODE, true);
}

public void OnLibraryAdded(const char[] name)
{
    if (!StrEqual(name, "atac")) {
        return;
    }

    char sName[32];
    Format(sName, sizeof(sName), "%T", "UberSlap", LANG_SERVER);
    ATAC_RegisterPunishment(sName, AtacPunishment_UberSlap);
}


/**
 * ATAC Punishments
 */
public void AtacPunishment_UberSlap(int victim, int attacker)
{
    PrintToChatAll("%c[ATAC]%c %t", CLR_GREEN, CLR_DEFAULT, "UberSlapped", attacker, ATAC_GetInfo(attacker, AtacInfo_Kills), ATAC_GetSetting(AtacSetting_KillsLimit));

    CreateTimer(0.1, Timer_UberSlap, attacker, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}


/**
 * Timers
 */
public Action Timer_UberSlap(Handle timer, any client)
{
    if (!IsClientInGame(client)) {
        return Plugin_Stop;
    }

    if (IsPlayerAlive(client) && GetClientHealth(client) > 1) {
        SlapEffects(client);
        SlapPlayer(client, 1);

        return Plugin_Continue;
    } else {
        SlayEffects(client);
        ForcePlayerSuicide(client);

        return Plugin_Stop;
    }
}


/**
 * Stocks
 */
void SlapEffects(int client)
{
    // Get player position to use as the ending coordinates
    float flEnd[3], flStart[3];
    GetClientAbsOrigin(client, flEnd);

    // Set the starting coordinates
    flStart     = flEnd;
    flStart[2] += 1000;

    TE_SetupBeamPoints(flStart, flEnd, g_iLightningModel, g_iLightningModel, 0, 1, 0.1, 5.0, 5.0, 1, 1.0, {255, 255, 255, 255}, 250);
    TE_SendToAll();
}

void SlayEffects(int client)
{
    float flEnd[3], flSparkDir[3], flSparkPos[3], flStart[3];
    // Get player position to use as the ending coordinates
    GetClientAbsOrigin(client, flEnd);

    // Set the starting coordinates
    flSparkDir     = flEnd;
    flSparkPos     = flEnd;
    flStart        = flEnd;

    flSparkDir[2] += 23;
    flSparkPos[2] += 13;
    flStart[2]    += 1000;

    // create lightning effects and sparks, and explosion
    TE_SetupBeamPoints(flStart, flEnd, g_iLightningModel, g_iLightningModel, 0, 1, 2.0, 5.0, 5.0, 1, 1.0, {255, 255, 255, 255}, 250);
    TE_SendToAll();

    TE_SetupExplosion(flEnd, g_iExplosionModel, 10.0, 10, TE_EXPLFLAG_NONE, 200, 255);
    TE_SendToAll();

    TE_SetupSmoke(flEnd,     g_iExplosionModel, 50.0, 2);
    TE_SendToAll();

    TE_SetupSmoke(flEnd,     g_iSmokeModel,     50.0, 2);
    TE_SendToAll();

    TE_SetupMetalSparks(flSparkPos, flSparkDir);
    TE_SendToAll();

    EmitAmbientSound(SOUND_EXPLODE, flEnd, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, 0.0);
}
