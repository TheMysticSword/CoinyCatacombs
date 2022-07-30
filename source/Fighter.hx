package;

import CombatState.CombatFighterPanel;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import openfl.utils.Dictionary;

private typedef FighterTemplate =
{
	public var id:String;
	public var combatImage:String;
	public var combatImageOffset:FlxPoint;
	public var combatAnimationType:String;
	public var maxhp:Int;
	public var coins:Int;
	public var items:Array<String>;
	public var script_onStartTurn:String;
	public var script_onEndTurn:String;
	public var script_onCoinsTossed:String;
}

class Fighter
{
	public var id:String;
	public var combatImage:String;
	public var combatImageOffset:FlxPoint;
	public var combatAnimationType:String;
	public var nameFlag:String;
	public var descFlag:String;
	public var maxhp:Int = 12;
	public var hp:Int = 12;
	public var coins:Int = 2;

	public var script_onStartTurn:String = "";
	public var script_onEndTurn:String = "";
	public var script_onCoinsTossed:String = "";

	public var isPlayer:Bool = false;
	public var asPlayer:PlayerFighter;

	public var items:Array<Item>;
	public var coinInstances:Array<Coin>;
	public var statuses:Array<StatusEffect>;

	public function new()
	{
		items = [];
		coinInstances = [];
		statuses = [];
	}

	public function createFromThis():Fighter
	{
		var newFighter:Fighter;
		if (isPlayer)
		{
			newFighter = new PlayerFighter();
		}
		else
		{
			newFighter = new Fighter();
		}
		newFighter.id = id;
		newFighter.combatImage = combatImage;
		newFighter.combatImageOffset = combatImageOffset;
		newFighter.combatAnimationType = combatAnimationType;
		newFighter.nameFlag = nameFlag;
		newFighter.descFlag = descFlag;
		newFighter.maxhp = maxhp;
		newFighter.hp = hp;
		newFighter.coins = coins;
		newFighter.items = [];
		for (item in items)
		{
			var newItem = item.createFromThis();
			newItem.owner = this;
			newFighter.items.push(newItem);
		}
		newFighter.coinInstances = [];
		for (coin in coinInstances)
		{
			var newCoin = coin.createFromThis();
			newCoin.owner = this;
			newFighter.coinInstances.push(newCoin);
		}
		for (status in statuses)
		{
			var newStatus = status.createFromThis();
			newStatus.owner = this;
			newFighter.statuses.push(newStatus);
		}
		newFighter.script_onStartTurn = script_onStartTurn;
		newFighter.script_onEndTurn = script_onEndTurn;
		newFighter.script_onCoinsTossed = script_onCoinsTossed;
		return newFighter;
	}

	public function addStatus(source:Fighter, id:String, amount:Int = 1)
	{
		if (amount <= 0)
			return;

		var status:StatusEffect = null;
		for (_status in statuses)
		{
			if (_status.id == id)
			{
				status = _status;
				break;
			}
		}

		var valueDelta = 0;

		if (status == null)
		{
			status = new StatusEffect();
			status.makeFromTemplate(id);
			status.owner = this;
			status.value = FlxMath.minInt(amount, StatusEffect.statusMax);
			statuses.push(status);
			valueDelta = status.value;
		}
		else
		{
			var oldValue = status.value;
			status.value += amount;
			if (status.value > StatusEffect.statusMax)
				status.value = StatusEffect.statusMax;
			valueDelta = status.value - oldValue;
		}

		status.runScript(this, Scripts.CombatScripts.getEnemy(this), status.script_onInflicted, ["valueDelta" => valueDelta]);

		if (Scripts.CombatScripts.simulationMode)
		{
			Scripts.CombatScripts.simulationScore += valueDelta * (status.negative == (CombatState.instance.currentTurnFighter == this) ? -100 : 100);
		}
		else
		{
			FlxG.sound.play("assets/sounds/" + status.sound, 0.2);
			if (status.negative)
			{
				Scripts.GlobalScripts.shakeCamera();
			}
			runForPanel(x -> x.updateStatusIcons());
		}
	}

	public function removeStatus(id:String, amount:Int = 1)
	{
		if (amount <= 0)
			return;

		for (status in statuses.copy())
		{
			if (status.id == id)
			{
				var oldValue = status.value;
				status.value -= amount;
				if (status.value <= 0)
				{
					status.value = 0;
					statuses.remove(status);
				}
				status.runScript(this, Scripts.CombatScripts.getEnemy(this), status.script_onRemoved, [
					"valueDelta" => status.value - oldValue,
					"removedCompletely" => status.value <= 0
				]);
				break;
			}
		}

		if (!Scripts.CombatScripts.simulationMode)
		{
			runForPanel(x -> x.updateStatusIcons());
		}
	}

	public function hasStatus(id:String):Bool
	{
		for (status in statuses)
		{
			if (status.id == id && status.value > 0)
				return true;
		}
		return false;
	}

	public function getStatus(id:String):Int
	{
		for (status in statuses)
		{
			if (status.id == id)
				return status.value;
		}
		return 0;
	}

	public function beforeStartTurn()
	{
		for (item in items)
		{
			item.beforeStartTurn();
		}
		for (status in statuses.copy())
		{
			status.beforeStartTurn();
		}
	}

	public function onStartTurn()
	{
		runScript(script_onStartTurn);

		for (item in items)
		{
			item.onStartTurn();
		}
		for (status in statuses.copy())
		{
			status.onStartTurn();
		}
	}

	public function onEndTurn()
	{
		runScript(script_onEndTurn);

		for (item in items)
		{
			item.onEndTurn();
		}
		for (status in statuses.copy())
		{
			status.onEndTurn();
		}
	}

	public function runScript(script:String):Scripts.RunScriptReturnValue
	{
		return Scripts.ScriptParsing.runScript(script, ["self" => this, "target" => Scripts.CombatScripts.getEnemy(this)]);
	}

	public function tossInitialCoins()
	{
		Scripts.CombatScripts.giveAnyCoins(this, coins);
		runScript(script_onCoinsTossed);
	}

	public function runForPanel(func:CombatFighterPanel->Void)
	{
		var combatPanel = CombatFighterPanel.findForFighter(this);
		if (combatPanel != null)
		{
			func(combatPanel);
		}
	}

	public static var templates:Dictionary<String, FighterTemplate>;

	public static function reloadTemplates()
	{
		templates = new Dictionary<String, FighterTemplate>();
		templates.set("DEFAULT", {
			id: "DEFAULT",
			combatImage: "",
			combatImageOffset: new FlxPoint(),
			combatAnimationType: "",
			maxhp: 4,
			coins: 0,
			items: [],
			script_onStartTurn: "",
			script_onEndTurn: "",
			script_onCoinsTossed: ""
		});

		var tsv:Array<Array<String>> = null;

		var filePath = "assets/data/fighters.tsv";

		#if (js && html5)
		if (!lime.utils.Assets.exists(filePath))
		{
			throw "fighters.tsv not found";
		}

		tsv = thx.csv.Tsv.decode(lime.utils.Assets.getText(filePath));
		#else
		filePath = "./" + filePath;
		if (!sys.FileSystem.exists(filePath))
			throw "fighters.tsv not found";

		tsv = thx.csv.Tsv.decode(sys.io.File.getContent(filePath));
		#end

		for (i in 1...tsv.length)
		{
			var row = tsv[i];
			var newTemplate:FighterTemplate = {
				id: row[0],
				combatImage: row[1],
				combatImageOffset: new FlxPoint(),
				combatAnimationType: row[3],
				maxhp: Std.parseInt(row[4]),
				coins: Std.parseInt(row[5]),
				items: row[6].split(","),
				script_onStartTurn: row[7],
				script_onEndTurn: row[8],
				script_onCoinsTossed: row[9]
			};

			if (row[2].indexOf("|") != -1)
			{
				var s = row[2].split("|");
				newTemplate.combatImageOffset.x = Std.parseFloat(s[0]);
				newTemplate.combatImageOffset.y = Std.parseFloat(s[1]);
			}

			templates.set(newTemplate.id, newTemplate);
		}
	}

	public function makeFromTemplate(id:String)
	{
		if (!templates.exists(id))
		{
			trace("Fighter template " + id + " not found, using default");
			id = "DEFAULT";
		}
		var template:FighterTemplate = templates[id];

		this.id = id;
		nameFlag = "$" + id + "_NAME";
		descFlag = "$" + id + "_DESC";
		combatImage = template.combatImage;
		combatImageOffset = template.combatImageOffset;
		combatAnimationType = template.combatAnimationType;
		maxhp = template.maxhp;
		hp = maxhp;
		coins = template.coins;
		items = new Array<Item>();
		for (itemID in template.items)
		{
			var newItem = new Item();
			newItem.makeFromTemplate(itemID);
			newItem.owner = this;
			items.push(newItem);
		}
		script_onStartTurn = template.script_onStartTurn;
		script_onEndTurn = template.script_onEndTurn;
		script_onCoinsTossed = template.script_onCoinsTossed;
	}
}
