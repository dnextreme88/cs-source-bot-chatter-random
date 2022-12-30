#include <sourcemod>
#include <cstrike>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION	"1.0"
#define BOMBPLANT_MYSELF    "self"

new aliveCtPlayers[17];

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
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("bomb_planted", Event_BombPlanted);
}

public OnMapStart() {
    aliveCtPlayers[0] = EOS;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
    aliveCtPlayers[0] = EOS;
}

// Thanks to PC Gamer for this snippet (https://forums.alliedmods.net/showpost.php?p=2796195&postcount=2)
public Action DeadChatTimer(Handle timer, any client) {
    if (IsClientInGame(client) && !IsPlayerAlive(client)) {
        // RANDOMIZER
        int randomChatToUse = GetRandomInt(1, 14);
        int randomNum = GetRandomInt(0, 90);

        // PrintToServer("LOG: randomChatToUse (from 1 - 14): %d", randomChatToUse);
        // PrintToServer("LOG: randomNum (if greater than 84, BOTS say something to chat based on value of randomChatToUse) %d", randomNum);

        if (randomNum > 84){
            char buffer[512];
            // REF: https://forums.alliedmods.net/showpost.php?p=2795817&postcount=3
            FormatEx(buffer, sizeof(buffer), "Dead%i", randomChatToUse);
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
        }
    }
}
