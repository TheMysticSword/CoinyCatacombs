package;

import flixel.FlxG;

class ItemPool
{
	public var items:Array<String>;

	public function new(items:Array<String>)
	{
		this.items = items;
	}

	public function roll():Item
	{
		var randomItem = new Item();
		randomItem.makeFromTemplate(FlxG.random.getObject(items));
		return randomItem;
	}
}

class ItemPools
{
	public static var normal:ItemPool;
	public static var rare:ItemPool;

	public static function init()
	{
		normal = new ItemPool([
			"PAYPHONE", "FLASH_SALE", "DIRTY_MONEY", "MINT", "CROWDFUNDER", "SHOPHOP", "CRIPPLING_DEBT", "TRICKLE_DOWN", "MIDAS_TOUCH", "RESTOCK",
			"GLUED_PENNY", "SAVINGS"
		]);
		rare = new ItemPool([
			"AVARICE",
			"FLIGHT",
			"BANG_FOR_YOUR_BUCK",
			"PAYOFF",
			"PICKPOCKET",
			"HOT_SELLER",
			"DEVILS_DEAL",
			"GREEDY_CLAWS"
		]);
	}
}
