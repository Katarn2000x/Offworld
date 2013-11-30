/**
 * Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
 */
class OWInventoryManager extends InventoryManager;

simulated function ClearPendingFire(Weapon InWeapon, int InFiringMode)
{
	`Log("Pending fire cleared");
	super.ClearPendingFire( InWeapon, InFiringMode);

}





event Destroyed()
{
	`Log("Inventory was destroyed");
	super.Destroyed();
}

/**
 * Attempts to remove an item from the inventory list if it exists.
 *
 * @param	Item	Item to remove from inventory
 */
simulated function RemoveFromInventory(Inventory ItemToRemove)
{
	`Log("Item was removed");
	super.RemoveFromInventory(ItemToRemove);
}

simulated event DiscardInventory()
{	
	`Log("Inventory was discarded");
	ScriptTrace();
	super.DiscardInventory();
}

simulated function ChangedWeapon()
{
	`Log("Changed the weapon");
	super.ChangedWeapon();
}

/**
 * Adds an existing inventory item to the list.
 * Returns true to indicate it was added, false if it was already in the list.
 *
 * @param	NewItem		Item to add to inventory manager.
 * @return	true if item was added, false otherwise.
 */
simulated function bool AddInventory(Inventory NewItem, optional bool bDoNotActivate)
{
	`Log("add something to inventory");
	return super.AddInventory( NewItem, bDoNotActivate);
}

simulated function Inventory CreateInventory(class<Inventory> NewInventoryItemClass, optional bool bDoNotActivate)
{
	`Log("Inventory item created");
	return super.CreateInventory(NewInventoryItemClass, bDoNotActivate);

}

defaultproperties
{
	PendingFire(0)=0
	PendingFire(1)=0
}
