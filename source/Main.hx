package;

import Scripts.ScriptParsing;
import firetongue.FireTongue;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import openfl.display.Sprite;

class Main extends Sprite
{
	public static var firetongue:FireTongue;

	public static var player:PlayerFighter;

	public static var uiCamera:FlxCamera;
	public static var fxCamera:FlxCamera;

	public static var savefile:FlxSave;

	public static var point:FlxPoint;

	public function new()
	{
		super();

		point = new FlxPoint();

		savefile = new FlxSave();
		savefile.bind("savefile");

		firetongue = new FireTongue();
		firetongue.initialize({
			locale: "en-US"
		});

		ScriptParsing.init();
		Fighter.reloadTemplates();
		Item.reloadTemplates();
		ItemPools.init();
		Skill.reloadTemplates();
		StatusEffect.reloadTemplates();

		addChild(new FlxGame(0, 0, MenuState, 1, 60, 60, true));

		FlxG.autoPause = false;
		FlxG.camera.antialiasing = true;
		FlxG.mouse.useSystemCursor = true;
		/*
			FlxG.sound.muteKeys = null;
			FlxG.sound.volumeUpKeys = null;
			FlxG.sound.volumeDownKeys = null;
		 */
	}

	public static function setupCameras()
	{
		uiCamera = new FlxCamera(0, 0, FlxG.width, FlxG.height, 1);
		uiCamera.bgColor = FlxColor.TRANSPARENT;
		uiCamera.antialiasing = true;
		FlxG.cameras.add(uiCamera, false);

		fxCamera = new FlxCamera(0, 0, FlxG.width, FlxG.height, 1);
		fxCamera.bgColor = FlxColor.TRANSPARENT;
		fxCamera.antialiasing = true;
		FlxG.cameras.add(fxCamera, false);
	}
}
