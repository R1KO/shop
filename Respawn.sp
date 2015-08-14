#pragma semicolon 1
#include <sourcemod>
#include <cstrike>
#include <shop>

#define CATEGORY	"stuff"

new g_iPrice,
	g_iSellPrice,
	g_iRoundUse,
	g_iRoundUsed[MAXPLAYERS+1],
	ItemId:id;

public Plugin:myinfo =
{
	name = "[Shop] Respawn",
	author = "R1KO",
	version = "1.2"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_respawn", Respawn_CMD);
	
	new Handle:hCvar;
	
	HookConVarChange((hCvar = CreateConVar("sm_shop_respawn_price", "1000", "Цена возрождения.")), PriceChange);
	g_iPrice = GetConVarInt(hCvar);
	
	HookConVarChange((hCvar = CreateConVar("sm_shop_respawn_sellprice", "500", "Цена продажи возрождения.")), SellPriceChange);
	g_iSellPrice = GetConVarInt(hCvar);
	
	HookConVarChange((hCvar = CreateConVar("sm_shop_per_round", "1", "Сколько раз за раунд игрок может возродиться.")), RoundUseChange);
	g_iRoundUse = GetConVarInt(hCvar);

	CloseHandle(hCvar);

	AutoExecConfig(true, "shop_respawn", "shop");
	
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_Post);
	
	if (Shop_IsStarted()) Shop_Started();
}

public Action:Respawn_CMD(client, args)
{
	if (client)
	{
		if (!Shop_UseClientItem(client, id)) PrintToChat(client, "У вас нет возрождений в инвентаре!");
	}

	return Plugin_Handled;
}

public OnPluginEnd() Shop_UnregisterMe();

public PriceChange(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
	g_iPrice = GetConVarInt(hCvar);
	if(id != INVALID_ITEM) Shop_SetItemPrice(id, g_iPrice);
}

public SellPriceChange(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
	g_iSellPrice = GetConVarInt(hCvar);
	if(id != INVALID_ITEM) Shop_SetItemSellPrice(id, g_iSellPrice);
}

public RoundUseChange(Handle:hCvar, const String:oldValue[], const String:newValue[]) g_iRoundUse = GetConVarInt(hCvar);

public Shop_Started()
{
	new CategoryId:category_id = Shop_RegisterCategory(CATEGORY, "Разное", "");
	if (Shop_StartItem(category_id, "Respawn"))
	{
		Shop_SetInfo("Возрождение", "Позволяет вам возродится", g_iPrice, g_iSellPrice, Item_Finite);
		Shop_SetCallbacks(OnItemRegistered, OnItemUse);
		Shop_EndItem();
	}
}

public OnItemRegistered(CategoryId:category_id, const String:category[], const String:item[], ItemId:item_id) id = item_id;

public OnClientPostAdminCheck(iClient) g_iRoundUsed[iClient] = 0;

public ShopAction:OnItemUse(iClient, CategoryId:category_id, const String:category[], ItemId:item_id, const String:item[])
{
	if (g_iRoundUse > 0 && g_iRoundUsed[iClient] >= g_iRoundUse)
	{
		PrintToChat(iClient, "Достигнут лимит возрождений (Лимит: %i)", g_iRoundUse);
		return Shop_Raw;
	}

	if(!IsPlayerAlive(iClient) && GetClientTeam(iClient) > 1)
	{
		CS_RespawnPlayer(iClient);
		g_iRoundUsed[iClient]++;
		PrintToChat(iClient, "Вы успешно возродились!");
		return Shop_UseOn;
	} else PrintToChat(iClient, "Вы должны быть мертвы и в команде!");
	return Shop_Raw;
}

public Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		g_iRoundUsed[i] = 0;
	}
}