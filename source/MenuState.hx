package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUITypedButton;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class MenuState extends FlxState
{
	override function create()
	{
		super.create();

		var bg = new FlxSprite(0, 0);
		bg.loadGraphic("assets/images/title.png");
		bg.scale.set(1 / 3, 1 / 3);
		bg.updateHitbox();
		bg.color = FlxColor.WHITE.getDarkened(0.15);
		add(bg);

		var gameInfo = new FlxText(100, 720 - 60, 1080, Main.firetongue.get("$GAME_INFO"), 14);
		gameInfo.alignment = CENTER;
		add(gameInfo);

		var startButton = new FlxUIButton(1280 - 400, 350, Main.firetongue.get("$GENERIC_BUTTON_PLAY"), () -> startGame());
		startButton.resize(200, 50);
		startButton.label.size = 24;
		startButton.autoCenterLabel();
		add(startButton);

		// Debug
		if (false)
		{
			Main.player = new PlayerFighter();
			Main.player.makeFromTemplate("MAINCHAR");
			Main.player.isPlayer = true;

			CombatState.startCombatMusic("assets/music/combat.wav");
			var enemy = new Fighter();
			enemy.makeFromTemplate("PLANT");
			FlxG.switchState(new CombatState(enemy));

			FlxG.switchState(new OverworldState());
			return;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	public function startGame()
	{
		Main.player = new PlayerFighter();
		Main.player.makeFromTemplate("MAINCHAR");
		Main.player.isPlayer = true;

		FlxG.switchState(new OverworldState(true));
	}
}
