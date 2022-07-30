package;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import openfl.utils.Dictionary;

private typedef SkillTemplate =
{
	public var id:String;
	public var script:String;
	public var maxUses:Int;
	public var limitBreak:Bool;
	public var hideReuseable:Bool;
}

class Skill
{
	public var id:String;
	public var nameFlag:String;
	public var descFlag:String;
	public var script:String;
	public var maxUses:Int;
	public var remainingUses:Int;
	public var reuseable(get, set):Bool;

	public function get_reuseable():Bool
	{
		return remainingUses == -1;
	}

	public function set_reuseable(value:Bool):Bool
	{
		if (value)
			remainingUses = -1;
		else
			remainingUses = 0;
		return value;
	}

	public var hideReuseable:Bool = false;

	public var limitBreak:Bool = false;

	public function new() {}

	public function activate(self:Fighter, target:Fighter)
	{
		runScript(self, target);
	}

	public function runScript(self:Fighter, target:Fighter):Scripts.RunScriptReturnValue
	{
		return Scripts.ScriptParsing.runScript(script, ["self" => self, "target" => target]);
	}

	public static var templates:Dictionary<String, SkillTemplate>;

	public static function reloadTemplates()
	{
		templates = new Dictionary<String, SkillTemplate>();
		templates.set("DEFAULT", {
			id: "DEFAULT",
			script: "",
			maxUses: -1,
			limitBreak: false,
			hideReuseable: false
		});

		var tsv:Array<Array<String>> = null;

		var filePath = "assets/data/skills.tsv";

		#if (js && html5)
		if (!lime.utils.Assets.exists(filePath))
		{
			throw "skills.tsv not found";
		}

		tsv = thx.csv.Tsv.decode(lime.utils.Assets.getText(filePath));
		#else
		filePath = "./" + filePath;
		if (!sys.FileSystem.exists(filePath))
			throw "skills.tsv not found";

		tsv = thx.csv.Tsv.decode(sys.io.File.getContent(filePath));
		#end

		for (i in 1...tsv.length)
		{
			var row = tsv[i];
			var newTemplate:SkillTemplate = {
				id: row[0],
				script: row[1],
				maxUses: Std.parseInt(row[2]),
				limitBreak: row[3] == "YES",
				hideReuseable: row[4] == "YES"
			};
			templates.set(newTemplate.id, newTemplate);
		}
	}

	public function makeFromTemplate(id:String)
	{
		if (!templates.exists(id))
		{
			trace("Skill template " + id + " not found, using default");
			id = "DEFAULT";
		}
		var template:SkillTemplate = templates[id];

		this.id = id;
		nameFlag = "$" + id + "_NAME";
		descFlag = "$" + id + "_DESC";
		script = template.script;
		maxUses = template.maxUses;
		remainingUses = maxUses;
		limitBreak = template.limitBreak;
	}
}
