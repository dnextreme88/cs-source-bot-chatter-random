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

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
    aliveCtPlayers[0] = EOS;
}

// Announce the settings option after time set when timer created (default 10 secs)
public Action:TimerAnnounce(Handle:timer, any:client) {
    if (IsClientInGame(client)) {
        // RANDOMIZER
        new randomChatToUse = GetRandomInt(1, 14);
        new randomNum = GetRandomInt(0, 90);

        // PrintToServer("randomChatToUse (from 0 - 14): %d", randomChatToUse);
        // PrintToServer("randomNum (if equal to 90, BOTS say something to chat based on value of randomChatToUse) %d", randomNum);

        // for (int i = 1; i <= MaxClients; i++) {
        //     decl String:buffer[512];

        //     if (IsClientInGame(i) && IsFakeClient(i) && !IsPlayerAlive(i) && randomNum >= 80) {
        //         if (randomChatToUse == 1) {
        //             Format(buffer, sizeof(buffer), "say %t", "Dead1");
        //             FakeClientCommand(i, buffer);
        //         } else if (randomChatToUse == 2) {
        //             Format(buffer, sizeof(buffer), "say %t", "Dead2");
        //             FakeClientCommand(i, buffer);
        //         } else if (randomChatToUse == 3) {
        //             Format(buffer, sizeof(buffer), "say %t", "Dead3");
        //             FakeClientCommand(i, buffer);
        //         } else if (randomChatToUse == 4) {
        //             Format(buffer, sizeof(buffer), "say %t", "Dead4");
        //             FakeClientCommand(i, buffer);
        //         } else if (randomChatToUse == 5) {
        //             Format(buffer, sizeof(buffer), "say %t", "Dead5");
        //             FakeClientCommand(i, buffer);
        //         }
        //     }
        // }

        decl String:buffer[512];

        if (IsClientInGame(client) && IsFakeClient(client) && !IsPlayerAlive(client) && randomNum == 90) {
            // REF: https://forums.alliedmods.net/showpost.php?p=2795817&postcount=3
            FormatEx(buffer, sizeof(buffer), "Dead%i", randomChatToUse);
            FakeClientCommand(client, "say %t", buffer);
        }
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

    for (int i = 1; i <= MaxClients; i++) {
        decl String:buffer[512];
        CreateTimer(10.0, TimerAnnounce, victimClient);

        if (victimTeam != attackerTeam && randomNum >= 85 && IsFakeClient(attackerClient)) {
            // REF: https://forums.alliedmods.net/showpost.php?p=2795817&postcount=3
            FormatEx(buffer, sizeof(buffer), "Killed%i", randomChatToUse);
            FakeClientCommand(attackerClient, "say %t", buffer, victimName);
        }
    }
}
