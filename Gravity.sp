#pragma semicolon 1
#include <sourcemod>
#include <shop>

#define CATEGORY	"ability"
#define ITEM	"gravity"

new bool:g_bHasGrav[MAXPLAYERS+1];
new Handle:g_hPrice,
	Handle:g_hSellPrice,
	Handle:g_hDuration,
	Handle:g_hGravityValue,
	ItemId:id;

public Plugin:myinfo =
{
	name = "[Shop] Gravity",
	author = "R1KO",
	version = "1.4"
};

public OnPluginStart()
{
	g_hPrice = CreateConVar("sm_shop_gravity_price", "1000", "Стоимость пониженой гравитации.");
	HookConVarChange(g_hPrice, OnConVarChange);
	
	g_hSellPrice = CreateConVar("sm_shop_gravity_sellprice", "500", "Стоимость продажи пониженой гравитации. -1 - запрет продажи");
	HookConVarChange(g_hSellPrice, OnConVarChange);
	
	g_hDuration = CreateConVar("sm_shop_gravity_duration", "86400", "Длительность пониженой гравитации в секундах.");
	HookConVarChange(g_hDuration, OnConVarChange);
	
	g_hGravityValue = CreateConVar("sm_shop_gravity_value", "0.6", "Значение изменения гравитации.", _, true, 0.1, true, 0.9);
	HookConVarChange(g_hGravityValue, OnConVarChange);

	AutoExecConfig(true, "shop_gravity", "shop");

	if (Shop_IsStarted()) Shop_Started();
}

public OnConVarChange(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
	if(id != INVALID_ITEM)
	{
		if(hCvar == g_hPrice) Shop_SetItemPrice(id, GetConVarInt(hCvar));
		if(hCvar == g_hSellPrice) Shop_SetItemSellPrice(id, GetConVarInt(hCvar));
		else if(hCvar == g_hDuration) Shop_SetItemValue(id, GetConVarInt(hCvar));
	}
}

public OnPluginEnd() Shop_UnregisterMe();

public Shop_Started()
{
	new CategoryId:category_id = Shop_RegisterCategory(CATEGORY, "Способности", "");
	
	if (Shop_StartItem(category_id, ITEM))
	{
		Shop_SetInfo("Пониженая гравитация", "", GetConVarInt(g_hPrice), GetConVarInt(g_hSellPrice), Item_Togglable, GetConVarInt(g_hDuration));
		Shop_SetCallbacks(OnItemRegistered, OnGravUsed);
		Shop_EndItem();
	}
}

public OnItemRegistered(CategoryId:category_id, const String:category[], const String:item[], ItemId:item_id) id = item_id;

public OnClientPostAdminCheck(iClient) g_bHasGrav[iClient] = false;

public ShopAction:OnGravUsed(iClient, CategoryId:category_id, const String:category[], ItemId:item_id, const String:item[], bool:isOn, bool:elapsed)
{
	if (isOn || elapsed)
	{
		g_bHasGrav[iClient] = false;
		SetEntityGravity(iClient, 1.0);

		return Shop_UseOff;
	}

	g_bHasGrav[iClient] = true;

	SetEntityGravity(iClient, GetConVarFloat(g_hGravityValue));

	return Shop_UseOn;
}
