/*  SM Translator
 *
 *  Copyright (C) 2018 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#include <sdktools>
#include <SteamWorks>
#include <colorvariables>


#define DATA "0.1"

public Plugin myinfo =
{
	name = "SM Translator",
	description = "Translate chat messages",
	author = "Franc1sco franug",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
};

char ServerLang[3];

public void OnPluginStart()
{
	AddCommandListener(Command_Say, "say");	
	
	GetLanguageInfo(GetServerLanguage(), ServerLang, 3);
}

public Action Command_Say(int client, const char[] command, int args)
{
	if (!IsValidClient(client))return;
	
	char buffer[255];
	GetCmdArgString(buffer,sizeof(buffer));
	StripQuotes(buffer);
	
	if (strlen(buffer) < 1)return;
	
	char temp[3];
	
	if(GetServerLanguage() != GetClientLanguage(client))
	{
		Handle request = CreateRequest(buffer, ServerLang, client, true);
		SteamWorks_SendHTTPRequest(request);
	}
	else
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && i != client && GetClientLanguage(client) != GetClientLanguage(i))
			{
				GetLanguageInfo(GetClientLanguage(i), temp, 3);
				Handle request = CreateRequest(buffer, temp, i, false);
				SteamWorks_SendHTTPRequest(request);
			}
		}
	}
}

Handle CreateRequest(char[] input, char[] target, int client, bool Foreign)
{
    Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, "http://www.headlinedev.xyz/translate/translate.php");
    SteamWorks_SetHTTPRequestGetOrPostParameter(request, "input", input);
    SteamWorks_SetHTTPRequestGetOrPostParameter(request, "target", target);
    
    SteamWorks_SetHTTPRequestContextValue(request, GetClientUserId(client), Foreign);
    SteamWorks_SetHTTPCallbacks(request, Callback_OnHTTPResponse);
    return request;
}

public int Callback_OnHTTPResponse(Handle request, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, int userid, bool Foreign)
{
    if (!bRequestSuccessful || eStatusCode != k_EHTTPStatusCode200OK)
    {        
        return;
    }

    int iBufferSize;
    SteamWorks_GetHTTPResponseBodySize(request, iBufferSize);
    
    char[] result = new char[iBufferSize];
    SteamWorks_GetHTTPResponseBodyData(request, result, iBufferSize);
    delete request;

    int client = GetClientOfUserId(userid);
    
    if (!client || !IsClientInGame(client))return;
    
    if(Foreign)
    {
    	CSetNextAuthor(client);
    	CPrintToChat(client, "{teamcolor}%N {TRANSLATED FOR OTHERS}{default}: %s", client, result);
    	
    	for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && i != client)
			{
				CSetNextAuthor(client);
				CPrintToChat(i, "{teamcolor}%N {TRANSLATED FOR YOU}{default}: %s", client, result);
			}
		}
    }
    else
    {
    	for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && i != client && GetServerLanguage() != GetClientLanguage(i))
			{
				CSetNextAuthor(client);
				CPrintToChat(i, "{teamcolor}%N {TRANSLATED FOR YOU}{default}: %s", client, result);
			}
		}
    }
}  

stock bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}