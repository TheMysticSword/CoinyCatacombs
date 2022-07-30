package;

import Scripts.GlobalScripts;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.util.FlxColor;
import openfl.utils.Dictionary;

private typedef StatusEffectTemplate =
{
	public var id:String;
	public var colour:FlxColor;
	public var icon:String;
	public var sound:String;
	public var stackable:Bool;
	public var negative:Bool;
	public var invisible:Bool;
	public var script_onInflicted:String;
	public var script_onRemoved:String;
	public var script_beforeStartTurn:String;
	public var script_onStartTurn:String;
	public var script_onEndTurn:String;
	public var script_onItemUsed:String;
	public var script_modifyDamage:String;
	public var script_onDamage:String;
}

class StatusEffect
{
	public var id:String;
	public var nameFlag:String;
	public var descFlag:String;
	public var colour:FlxColor;
	public var icon:String;
	public var sound:String;
	public var stackable:Bool;
	public var negative:Bool;
	public var invisible:Bool;
	public var script_onInflicted:String;
	public var script_onRemoved:String;
	public var script_beforeStartTurn:String;
	public var script_onStartTurn:String;
	public var script_onEndTurn:String;
	public var script_onItemUsed:String;
	public var script_modifyDamage:String;
	public var script_onDamage:String;

	public var value:Int = 1;
	public var owner:Fighter;

	public static final statusMax:Int = 9999;

	public function new() {}

	public function createFromThis():StatusEffect
	{
		var newStatus = new StatusEffect();
		newStatus.id = id;
		newStatus.nameFlag = nameFlag;
		newStatus.descFlag = descFlag;
		newStatus.colour = colour;
		newStatus.icon = icon;
		newStatus.sound = sound;
		newStatus.stackable = stackable;
		newStatus.negative = negative;
		newStatus.invisible = invisible;
		newStatus.script_onInflicted = script_onInflicted;
		newStatus.script_onRemoved = script_onRemoved;
		newStatus.script_beforeStartTurn = script_beforeStartTurn;
		newStatus.script_onStartTurn = script_onStartTurn;
		newStatus.script_onEndTurn = script_onEndTurn;
		newStatus.script_onItemUsed = script_onItemUsed;
		newStatus.script_modifyDamage = script_modifyDamage;
		newStatus.script_onDamage = script_onDamage;
		newStatus.value = value;
		newStatus.owner = owner;
		return newStatus;
	}

	public function beforeStartTurn()
	{
		runScript(owner, Scripts.CombatScripts.getEnemy(owner), script_beforeStartTurn);
	}

	public function onStartTurn()
	{
		runScript(owner, Scripts.CombatScripts.getEnemy(owner), script_onStartTurn);
	}

	public function onEndTurn()
	{
		runScript(owner, Scripts.CombatScripts.getEnemy(owner), script_onEndTurn);
	}

	public function runScript(self:Fighter, target:Fighter, script:String, ?extraVariables:Map<String, Dynamic> = null):Scripts.RunScriptReturnValue
	{
		var variables:Map<String, Dynamic> = ["self" => self, "target" => target, "thisStatus" => this];
		if (extraVariables != null)
			for (kvp in extraVariables.keyValueIterator())
				variables.set(kvp.key, kvp.value);
		return Scripts.ScriptParsing.runScript(script, variables);
	}

	public static var templates:Dictionary<String, StatusEffectTemplate>;
	public static var positiveStatuses:Array<String>;
	public static var negativeStatuses:Array<String>;

	public static function reloadTemplates()
	{
		templates = new Dictionary<String, StatusEffectTemplate>();
		positiveStatuses = [];
		negativeStatuses = [];
		templates.set("DEFAULT", {
			id: "DEFAULT",
			colour: FlxColor.WHITE,
			icon: "particle_star.png",
			sound: "magic1.wav",
			stackable: true,
			negative: false,
			invisible: false,
			script_onInflicted: "",
			script_onRemoved: "",
			script_beforeStartTurn: "",
			script_onStartTurn: "",
			script_onEndTurn: "",
			script_onItemUsed: "",
			script_modifyDamage: "",
			script_onDamage: ""
		});

		var tsv:Array<Array<String>> = null;

		var filePath = "assets/data/statuseffects.tsv";

		#if (js && html5)
		if (!lime.utils.Assets.exists(filePath))
		{
			throw "statuseffects.tsv not found";
		}

		tsv = thx.csv.Tsv.decode(lime.utils.Assets.getText(filePath));
		#else
		filePath = "./" + filePath;
		if (!sys.FileSystem.exists(filePath))
			throw "statuseffects.tsv not found";

		tsv = thx.csv.Tsv.decode(sys.io.File.getContent(filePath));
		#end

		for (i in 1...tsv.length)
		{
			var row = tsv[i];
			var newTemplate:StatusEffectTemplate = {
				id: row[0],
				colour: GlobalScripts.getColour(row[1]),
				icon: row[2],
				sound: (row[3].length > 0 ? row[3] : "none.wav"),
				stackable: row[4] == "YES",
				negative: row[5] == "YES",
				invisible: row[6] == "YES",
				script_onInflicted: row[7],
				script_onRemoved: row[8],
				script_beforeStartTurn: row[9],
				script_onStartTurn: row[10],
				script_onEndTurn: row[11],
				script_onItemUsed: row[12],
				script_modifyDamage: row[13],
				script_onDamage: row[14]
			};
			templates.set(newTemplate.id, newTemplate);

			if (!newTemplate.invisible)
			{
				if (!newTemplate.negative)
					positiveStatuses.push(newTemplate.id);
				else
					negativeStatuses.push(newTemplate.id);
			}
		}
	}

	public function makeFromTemplate(id:String)
	{
		if (!templates.exists(id))
		{
			trace("Status effect template " + id + " not found, using default");
			id = "DEFAULT";
		}
		var template:StatusEffectTemplate = templates[id];

		this.id = id;
		nameFlag = "$" + id + "_NAME";
		descFlag = "$" + id + "_DESC";
		colour = template.colour;
		icon = template.icon;
		sound = template.sound;
		stackable = template.stackable;
		negative = template.negative;
		invisible = template.invisible;
		script_onInflicted = template.script_onInflicted;
		script_onRemoved = template.script_onRemoved;
		script_beforeStartTurn = template.script_beforeStartTurn;
		script_onStartTurn = template.script_onStartTurn;
		script_onEndTurn = template.script_onEndTurn;
		script_onItemUsed = template.script_onItemUsed;
		script_modifyDamage = template.script_modifyDamage;
		script_onDamage = template.script_onDamage;
	}
}
