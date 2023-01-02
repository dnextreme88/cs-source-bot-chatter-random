#include <sourcemod>
#include <cstrike>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION	    "1.3"
#define BOMBPLANT_MYSELF    "self"

new aliveCtPlayers[17];

new hitsTakenList[MAXPLAYERS + 1]; // Store hits made by players into an array
new String:playerNameWithMostKills[34];
int playerIndexWithMostKills = 0;

public Plugin:myinfo = {
    name = "Bot Chatter",
    author = "dnextreme88",
    description = "Random bot chatter like in CS 1.6. Created on December 23, 2022.",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net"
}

public OnPluginStart() {
    LoadTranslations("bot_chatter_random.phrases");

    HookEvent("round_start", Event_RoundStart);
    HookEvent("bomb_planted", Event_BombPlanted);
    HookEvent("player_hurt", Event_PlayerHurt);
    HookEvent("player_death", Event_PlayerDeath);
}

public OnMapStart() {
    aliveCtPlayers[0] = EOS;

    for (new i = 1; i <= MaxClients; i++) {
        hitsTakenList[i] = 0;
    }

    playerIndexWithMostKills = 0;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
    aliveCtPlayers[0] = EOS;

    GetPlayerMostFrags();

    for (new i = 1; i <= MaxClients; i++) {
        hitsTakenList[i] = 0;
    }
}

// Thanks to PC Gamer for this snippet (https://forums.alliedmods.net/showpost.php?p=2796195&postcount=2)
public Action DeadChatTimer(Handle timer, any client) {
    if (IsClientInGame(client) && !IsPlayerAlive(client)) {
        // RANDOMIZER
        int randomChatToUse = GetRandomInt(1, 42);
        int randomNum = GetRandomInt(0, 90);

        if (randomNum > 84){
            char buffer[512];

            // REF: https://forums.alliedmods.net/showpost.php?p=2795817&postcount=3
            FormatEx(buffer, sizeof(buffer), "Dead%i", randomChatToUse);

            // PrintToServer("==== LOG: randomChatToUse (from 1 - 42): %d", randomChatToUse);
            // PrintToServer("==== LOG: randomNum (if greater than 84, BOTS say something to chat based on value of randomChatToUse) %d", randomNum);
            // PrintToServer("==== LOG: playerNameWithMostKills: %s", playerNameWithMostKills);

            if (randomChatToUse >= 31 && randomChatToUse <= 42) { // Chats referring to player with most frags (upon start of round only)
                if (!StrEqual(playerNameWithMostKills, "")) { // Only works for round 2 and above
                    FakeClientCommand(client, "say %t", buffer, playerNameWithMostKills);
                }
            } else {
                FakeClientCommand(client, "say %t", buffer);
            }
        }

        return Plugin_Continue;
    } else {
        return Plugin_Stop;
    }
}

public Action TeamkillChatTimer(Handle timer, any client) {
    if (IsClientInGame(client) && !IsPlayerAlive(client)) {
        // RANDOMIZER
        int randomChatToUse = GetRandomInt(1, 7);
        int randomNum = GetRandomInt(0, 90);

        if (randomNum >= 70){
            char buffer[512];

            // REF: https://forums.alliedmods.net/showpost.php?p=2795817&postcount=3
            FormatEx(buffer, sizeof(buffer), "Teamkill%i", randomChatToUse);
            FakeClientCommand(client, "say %t", buffer);
        }

        return Plugin_Continue;
    } else {
        return Plugin_Stop;
    }
}

public Event_BombPlanted(Handle:event, const String:name[], bool:dontBroadcast) {
    decl String:buffer[512];
    int aliveCtBotsCount = 0;

    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i)) {
            new String:playerName[64];
            GetClientName(i, playerName, 33);

            if (IsPlayerAlive(i) && GetClientTeam(i) == 3 && IsFakeClient(i)) { // Alive CT bots only
                aliveCtPlayers[aliveCtBotsCount] = i;
                aliveCtBotsCount++;
            }
        }
    }

    if (aliveCtBotsCount > 0) {
        int aliveCtPlayersSizeUsingIndex = aliveCtBotsCount - 1;

        // RANDOMIZER
        new randomChatToUse = GetRandomInt(1, 5);
        new randomCtPlayerIndex = GetRandomInt(0, aliveCtPlayersSizeUsingIndex);

        // REF: https://forums.alliedmods.net/showpost.php?p=2795817&postcount=3
        FormatEx(buffer, sizeof(buffer), "BombPlant%i", randomChatToUse);

        if (randomChatToUse == 1) {
            // A random CT teammate
            new randomCtPlayerIndexTeammate = GetRandomInt(0, aliveCtPlayersSizeUsingIndex);
            new String:secondPlayerName[64];
            GetClientName(aliveCtPlayers[randomCtPlayerIndexTeammate], secondPlayerName, 33);

            if (randomCtPlayerIndex == randomCtPlayerIndexTeammate) {
                FakeClientCommand(aliveCtPlayers[randomCtPlayerIndex], "say %t", buffer, BOMBPLANT_MYSELF); // Let him talk to himself, for his own motivation
            } else {
                FakeClientCommand(aliveCtPlayers[randomCtPlayerIndex], "say %t", buffer, secondPlayerName);
            }
        } else {
            FakeClientCommand(aliveCtPlayers[randomCtPlayerIndex], "say %t", buffer);
        }
    }
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) {
    new damageDealt = GetEventInt(event, "dmg_health");

    new attackerId = GetEventInt(event, "attacker");
    new attackerClient = GetClientOfUserId(attackerId);

    // Used to determine player with the most frags at the start of each round to be used by the dead chats
    hitsTakenList[attackerClient] += damageDealt;
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
    new victimId = GetEventInt(event, "userid");
    new victimClient = GetClientOfUserId(victimId);
    new victimTeam = GetClientTeam(victimClient);

    new attackerId = GetEventInt(event, "attacker");
    new attackerClient = GetClientOfUserId(attackerId);
    new attackerTeam = GetClientTeam(attackerClient);

    new String:attackerName[64];
    new String:victimName[64];

    GetClientName(attackerClient, attackerName, 33);
    GetClientName(victimClient, victimName, 33);

    // RANDOMIZER
    new randomChatToUse = GetRandomInt(1, 14);
    new randomNum = GetRandomInt(0, 90);

    if (IsFakeClient(victimClient)) {
        CreateTimer(10.0, DeadChatTimer, victimClient, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
    }

    for (int i = 1; i <= MaxClients; i++) {
        decl String:buffer[512];

        if (victimTeam != attackerTeam && randomNum >= 85 && IsFakeClient(attackerClient)) {
            // REF: https://forums.alliedmods.net/showpost.php?p=2795817&postcount=3
            FormatEx(buffer, sizeof(buffer), "Killed%i", randomChatToUse);
            FakeClientCommand(attackerClient, "say %t", buffer, victimName);
        } else if (victimTeam == attackerTeam && randomNum >= 70 && IsFakeClient(victimClient)) {
            CreateTimer(5.0, TeamkillChatTimer, victimClient, TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

void GetPlayerMostFrags() {
    int kills = 0;
    int playerDeathsCurrentMostKills = 0;
    int playerDeathsCurrentIteration = 0;
    int mostKillsCount = 0;

    // Finding out who has the most frags / kills
    for (new i = 1; i <= MaxClients; i++) {
        kills = 0;

        if (IsClientInGame(i)) {
            kills = GetClientFrags(i);

            if (kills > 0 && kills > mostKillsCount) {
                mostKillsCount = kills;
                playerIndexWithMostKills = i;
                GetClientName(i, playerNameWithMostKills, 33);
            } else if (kills > 0 && kills >= mostKillsCount) { // Tied with kills
                playerDeathsCurrentMostKills = GetClientDeaths(playerIndexWithMostKills); // Player with the current most kills
                playerDeathsCurrentIteration = GetClientDeaths(i); // Player being compared

                new String:playerNameTiedWithMostKills[34];
                GetClientName(i, playerNameTiedWithMostKills, 33);

                // In case of a tie, check if current iteration has lesser deaths first.
                // If not, we check if it dealt more damage than the current holder on the previous round
                if (playerDeathsCurrentIteration < playerDeathsCurrentMostKills) {
                    playerIndexWithMostKills = i;
                    GetClientName(i, playerNameWithMostKills, 33); // Overwrite as new player with most kills
                    continue;
                }

                if (hitsTakenList[i] > hitsTakenList[playerIndexWithMostKills]) {
                    playerIndexWithMostKills = i;
                    GetClientName(i, playerNameWithMostKills, 33); // Overwrite as new player with most kills
                }
            }
        }
    }
}
