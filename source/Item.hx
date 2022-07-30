package;

import Coin.CoinType;
import CombatState.CombatItemPanel;
import Scripts.GlobalScripts;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import openfl.utils.Dictionary;

enum CoinSlot
{
	Normal;
	Gold;
	Heads;
	Tails;
	GoldHeads;
	GoldTails;
	Matching;
}

private typedef ItemTemplate =
{
	public var id:String;
	public var script:String;
	public var slots:Array<CoinSlot>;
	public var maxUses:Int;
	public var colour:FlxColor;
	public var script_beforeActivated:String;
	public var script_beforeStartTurn:String;
	public var script_onStartTurn:String;
	public var script_onEndTurn:String;
}

typedef PossibleToUseRightNowReturnValue =
{
	public var result:Bool;
	public var coinsToUse:Array<Array<Coin>>;
}

class Item
{
	public var id:String;
	public var nameFlag:String;
	public var descFlag:String;
	public var script:String;
	public var slots:Array<CoinSlot>;
	public var maxUses:Int;
	public var remainingUses:Int;
	public var reuseable(get, set):Bool;
	public var colour:FlxColor;

	public var script_beforeActivated:String;
	public var script_beforeStartTurn:String;
	public var script_onStartTurn:String;
	public var script_onEndTurn:String;

	public var owner:Fighter;
	public var insertedCoins:Array<Null<CoinType>>;
	public var cooldown:Int = 0;
	public var cooldownTextFlagOverride:String = "";

	public var canActivate:Bool = true;

	public function get_reuseable():Bool
	{
		return remainingUses == -1;
	}

	public function set_reuseable(value:Bool):Bool
	{
		if (value)
			remainingUses = -1;
		else
			remainingUses = 1;
		return value;
	}

	public function new()
	{
		slots = [];
		insertedCoins = [];
		colour = FlxColor.BLACK;
	}

	public function createFromThis():Item
	{
		var newItem = new Item();
		newItem.id = id;
		newItem.nameFlag = nameFlag;
		newItem.descFlag = descFlag;
		newItem.script = script;
		newItem.script_beforeActivated = script_beforeActivated;
		newItem.script_beforeStartTurn = script_beforeStartTurn;
		newItem.script_onStartTurn = script_onStartTurn;
		newItem.script_onEndTurn = script_onEndTurn;
		newItem.slots = slots.copy();
		newItem.maxUses = maxUses;
		newItem.remainingUses = remainingUses;
		newItem.colour = colour;
		newItem.owner = owner;
		newItem.insertedCoins = [];
		for (i in 0...insertedCoins.length)
			newItem.insertedCoins.push(insertedCoins[i]);
		newItem.cooldown = cooldown;
		newItem.cooldownTextFlagOverride = cooldownTextFlagOverride;
		newItem.canActivate = canActivate;
		return newItem;
	}

	public function possibleToUseRightNow(withCoins:Null<Array<Coin>> = null):PossibleToUseRightNowReturnValue
	{
		if (withCoins == null)
		{
			if (owner == null)
				return {result: false, coinsToUse: []};
			withCoins = owner.coinInstances.copy();
		}

		if (slots.length > 0)
		{
			var remainingCoins = withCoins.copy();
			remainingCoins = remainingCoins.filter(x -> x != null && x.alive && !x.consumed);

			if (slots[0] == Matching)
			{
				var totalHeads = remainingCoins.filter(x -> x.type == Heads || x.type == GoldHeads);
				var totalTails = remainingCoins.filter(x -> x.type == Tails || x.type == GoldTails);

				if (insertedCoins[0] == null)
				{
					if (totalHeads.length >= slots.length || totalTails.length >= slots.length)
					{
						var coinsToUse = new Array<Array<Coin>>();
						if (totalHeads.length >= slots.length)
							coinsToUse.push(totalHeads.slice(0, slots.length));
						if (totalTails.length >= slots.length)
							coinsToUse.push(totalTails.slice(0, slots.length));
						return {
							result: true,
							coinsToUse: coinsToUse
						};
					}
				}
				else
				{
					var unfilledSlots = insertedCoins.filter(x -> x == null).length;
					if (insertedCoins[0] == Heads || insertedCoins[0] == GoldHeads)
					{
						if (totalHeads.length >= unfilledSlots)
							return {
								result: true,
								coinsToUse: [totalHeads.slice(0, unfilledSlots)]
							};
					}
					else if (insertedCoins[0] == Tails || insertedCoins[0] == GoldTails)
					{
						if (totalTails.length >= unfilledSlots)
							return {
								result: true,
								coinsToUse: [totalTails.slice(0, unfilledSlots)]
							};
					}
				}
			}
			else
			{
				var filledSlots = 0;
				var coinsToUse = new Array<Coin>();
				for (i in 0...slots.length)
				{
					if (insertedCoins[i] != null)
					{
						filledSlots++;
					}
					else
					{
						for (coin in remainingCoins.copy())
						{
							if (slotAcceptsCoin(coin, i, false))
							{
								filledSlots++;
								coinsToUse.push(coin);
								remainingCoins.remove(coin);
								break;
							}
						}
					}
				}

				if (filledSlots >= slots.length && coinsToUse.length > 0)
					return {
						result: true,
						coinsToUse: [coinsToUse]
					};
			}
		}
		return {result: false, coinsToUse: []};
	}

	public function slotAcceptsCoin(coin:Coin, slotIndex:Int, checkOccupied:Bool = true):Bool
	{
		if (checkOccupied && insertedCoins[slotIndex] != null)
			return false;

		switch (slots[slotIndex])
		{
			case Normal:
				return true;
			case Gold:
				return coin.gold;
			case Heads:
				return coin.type == Heads || coin.type == GoldHeads;
			case Tails:
				return coin.type == Tails || coin.type == GoldTails;
			case GoldHeads:
				return coin.type == GoldHeads;
			case GoldTails:
				return coin.type == GoldTails;
			case Matching:
				if (insertedCoins[0] == null)
				{
					return true;
				}
				else
				{
					if (insertedCoins[0] == Heads || insertedCoins[0] == GoldHeads)
					{
						return coin.type == Heads || coin.type == GoldHeads;
					}
					if (insertedCoins[0] == Tails || insertedCoins[0] == GoldTails)
					{
						return coin.type == Tails || coin.type == GoldTails;
					}
				}
		}
		return false;
	}

	public function beforeStartTurn()
	{
		if (cooldown > 0)
		{
			cooldown--;
			if (cooldown <= 0)
			{
				canActivate = true;

				cooldownTextFlagOverride = "";

				runForPanel(x -> x.rollCooldownPanel(false, 0.4));
			}
		}

		if (!reuseable)
			remainingUses = maxUses;

		runScript(owner, Scripts.CombatScripts.getEnemy(owner), script_beforeStartTurn);

		runForPanel(x -> x.refresh());
	}

	public function onStartTurn()
	{
		runScript(owner, Scripts.CombatScripts.getEnemy(owner), script_onStartTurn);

		runForPanel(x -> x.refresh());
	}

	public function onEndTurn()
	{
		runScript(owner, Scripts.CombatScripts.getEnemy(owner), script_onEndTurn);

		runForPanel(x -> x.refresh());
	}

	public function onCoinInserted()
	{
		runForPanel(x -> x.onCoinInserted());

		tryActivate(owner, Scripts.CombatScripts.getEnemy(owner));
	}

	public function tryActivate(self:Fighter, target:Fighter)
	{
		if (!canActivate)
			return;

		if (cooldown > 0)
			return;

		if (insertedCoins.contains(null))
			return;

		if (script_beforeActivated.length > 0)
			runScript(self, target, script_beforeActivated);

		canActivate = false;

		if (remainingUses > 0)
			remainingUses--;
		if (remainingUses > 0 || reuseable)
		{
			runForPanel(x ->
			{
				x.refresh();
				x.tempDarkenBar(0.5);
			});
		}
		else
		{
			cooldown++;
			runForPanel(x ->
			{
				x.refresh();
				x.rollCooldownPanel(true, 0.4);
			});
		}

		FlxTween.num(0, 1, 0.5, {
			onComplete: x ->
			{
				runScript(self, target, script);

				for (status in self.statuses.copy())
				{
					status.runScript(self, target, status.script_onItemUsed, ["usedItem" => this]);
				}

				if (remainingUses > 0 || reuseable)
					canActivate = true;

				for (i in 0...insertedCoins.length)
					insertedCoins[i] = null;
				runForPanel(x -> x.refresh());
			}
		});
	}

	public function activateInSimulation(self:Fighter, target:Fighter):Int
	{
		var score:Int = 0;

		remainingUses--;
		if (remainingUses <= 0 && !reuseable)
		{
			canActivate = false;
			cooldown++;
		}

		Scripts.CombatScripts.simulationMode = true;
		Scripts.CombatScripts.simulationScore = 0;
		Scripts.CombatScripts.simulationEnemy = target;

		runScript(self, target, script_beforeActivated);
		runScript(self, target, script);

		for (status in self.statuses.copy())
		{
			status.runScript(self, target, status.script_onItemUsed, ["usedItem" => this]);
		}

		score += Scripts.CombatScripts.simulationScore;
		Scripts.CombatScripts.simulationMode = false;

		for (i in 0...insertedCoins.length)
			insertedCoins[i] = null;

		return score;
	}

	public function runScript(self:Fighter, target:Fighter, script:String):Scripts.RunScriptReturnValue
	{
		return Scripts.ScriptParsing.runScript(script, [
			"self" => self,
			"target" => target,
			"thisItem" => this,
			"goldUsed" => (insertedCoins.contains(GoldHeads) || insertedCoins.contains(GoldTails))
		]);
	}

	public function runForPanel(func:CombatItemPanel->Void)
	{
		var combatPanel = CombatItemPanel.findForItem(this);
		if (combatPanel != null)
		{
			func(combatPanel);
		}
	}

	public function changeSlots(newSlots:Array<CoinSlot>)
	{
		Scripts.CombatScripts.giveCoins(owner, insertedCoins);
		slots = newSlots.copy();
		insertedCoins = [];
		for (i in 0...newSlots.length)
			insertedCoins.push(null);
		runForPanel(x -> x.refresh());
	}

	public static var templates:Dictionary<String, ItemTemplate>;

	public static function reloadTemplates()
	{
		templates = new Dictionary<String, ItemTemplate>();
		templates.set("DEFAULT", {
			id: "DEFAULT",
			script: "",
			slots: [CoinSlot.Normal],
			maxUses: 1,
			colour: FlxColor.BLACK,
			script_beforeActivated: "",
			script_beforeStartTurn: "",
			script_onStartTurn: "",
			script_onEndTurn: ""
		});

		var tsv:Array<Array<String>> = null;

		var filePath = "assets/data/items.tsv";

		#if (js && html5)
		if (!lime.utils.Assets.exists(filePath))
		{
			throw "items.tsv not found";
		}

		tsv = thx.csv.Tsv.decode(lime.utils.Assets.getText(filePath));
		#else
		filePath = "./" + filePath;
		if (!sys.FileSystem.exists(filePath))
			throw "items.tsv not found";

		tsv = thx.csv.Tsv.decode(sys.io.File.getContent(filePath));
		#end

		for (i in 1...tsv.length)
		{
			var row = tsv[i];
			var newTemplate:ItemTemplate = {
				id: row[0],
				script: row[1],
				slots: [],
				maxUses: Std.parseInt(row[3]),
				colour: GlobalScripts.getColour(row[4]),
				script_beforeActivated: row[5],
				script_beforeStartTurn: row[6],
				script_onStartTurn: row[7],
				script_onEndTurn: row[8]
			};

			var slotNames = row[2].split(",");
			for (slotName in slotNames)
			{
				var slot = CoinSlot.createByName(slotName);
				if (slot == null)
					slot = CoinSlot.Normal;
				newTemplate.slots.push(slot);
			}

			templates.set(newTemplate.id, newTemplate);
		}
	}

	public function makeFromTemplate(id:String)
	{
		if (!templates.exists(id))
		{
			trace("Item template " + id + " not found, using default");
			id = "DEFAULT";
		}
		var template:ItemTemplate = templates[id];

		this.id = id;
		nameFlag = "$" + id + "_NAME";
		descFlag = "$" + id + "_DESC";
		script = template.script;
		slots = template.slots.copy();
		insertedCoins = [];
		for (i in 0...slots.length)
			insertedCoins.push(null);
		maxUses = template.maxUses;
		remainingUses = maxUses;
		colour = template.colour;
		script_beforeActivated = template.script_beforeActivated;
		script_beforeStartTurn = template.script_beforeStartTurn;
		script_onStartTurn = template.script_onStartTurn;
		script_onEndTurn = template.script_onEndTurn;
	}
}
