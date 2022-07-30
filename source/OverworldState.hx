package;

import CombatState.CombatEmptyItemPanel;
import CombatState.CombatItemPanel;
import CombatState.CombatStatusIcon;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class OverworldState extends FlxState
{
	public static var instance:OverworldState;

	public var background:FlxSprite;

	public var sidePanelGroup:FlxTypedSpriteGroup<FlxSprite>;

	public var sidePanelToggleButton:FlxSprite;

	public var sidePanelBG:FlxSprite;

	public var playerName:FlxText;

	public var hpBarGroup:FlxTypedSpriteGroup<FlxSprite>;
	public var hpBarBG:FlxSprite;
	public var hpBarFilling:FlxSprite;
	public var hpText:FlxText;

	public var itemPanels:Array<CombatItemPanel>;

	public var statusIcons:Array<CombatStatusIcon>;

	public static var overworldMusic:FlxSound;

	public var situation:OverworldSituation;

	private var playBeginning:Bool;

	public function new(playBeginning:Bool = false)
	{
		super();
		this.playBeginning = playBeginning;
	}

	override function create()
	{
		super.create();

		Main.setupCameras();

		instance = this;

		if (overworldMusic == null)
		{
			overworldMusic = FlxG.sound.load("assets/music/overworld.wav", 0, true);
			overworldMusic.persist = true;
			overworldMusic.play();
		}

		CombatState.startCombatMusic("assets/music/combat.wav");

		background = new FlxSprite(0, 0);
		background.loadGraphic("assets/images/overworld_bg.png");
		add(background);

		var bgDarken = new FlxSprite(0, 0);
		bgDarken.makeGraphic(1280, 720, FlxColor.BLACK);
		bgDarken.alpha = 0.11;
		add(bgDarken);

		sidePanelGroup = new FlxTypedSpriteGroup<FlxSprite>(1280 - 320, 0);
		sidePanelGroup.cameras = [Main.uiCamera];
		add(sidePanelGroup);

		sidePanelToggleButton = new FlxSprite(-38, 10);
		sidePanelToggleButton.loadGraphic("assets/images/side_panel_hide.png");
		sidePanelGroup.add(sidePanelToggleButton);

		sidePanelBG = new FlxSprite(0, 0);
		sidePanelBG.makeGraphic(320, 720, FlxColor.BLACK);
		sidePanelGroup.add(sidePanelBG);

		playerName = new FlxText(10, 10, 280, Main.firetongue.get(Main.player.nameFlag, "fighters"), 18);
		sidePanelGroup.add(playerName);

		hpBarGroup = new FlxTypedSpriteGroup<FlxSprite>(10, 44);
		sidePanelGroup.add(hpBarGroup);

		hpBarBG = new FlxSprite(0, 0);
		hpBarBG.makeGraphic(300, 28, FlxColor.fromString("0x910C00"));
		hpBarGroup.add(hpBarBG);

		var hpBarFillingPadding = 3;
		hpBarFilling = new FlxSprite(hpBarFillingPadding, hpBarFillingPadding);
		hpBarFilling.makeGraphic(Std.int(hpBarBG.width) - hpBarFillingPadding * 2, Std.int(hpBarBG.height) - hpBarFillingPadding * 2,
			FlxColor.fromString("0xF24741"));
		hpBarFilling.updateHitbox();
		hpBarGroup.add(hpBarFilling);
		hpBarFilling.clipRect = new FlxRect(0, 0, hpBarFilling.graphic.width, hpBarFilling.graphic.height);

		hpText = new FlxText(0, 0, 300, "", 18);
		hpText.alignment = CENTER;
		hpText.updateHitbox();
		hpBarGroup.add(hpText);

		updateHPBar();
		itemPanels = [];
		updateInventory();
		statusIcons = [];
		updateStatusIcons();

		setSidePanelVisible(false, 0);

		if (playBeginning)
		{
			switchToSituation(OverworldSituations.Beginning);
		}
		else
		{
			switchToRandomSituation();
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!canToggleSidePanel)
		{
			sidePanelToggleButton.visible = false;
		}
		else
		{
			sidePanelToggleButton.visible = true;
			if (FlxG.mouse.justPressed)
			{
				for (camera in sidePanelToggleButton.cameras)
				{
					if (sidePanelToggleButton.overlapsPoint(FlxG.mouse.getWorldPosition(camera, Main.point), true, camera))
					{
						setSidePanelVisible(!sidePanelVisible);
						break;
					}
				}
			}
		}
	}

	public function updateName()
	{
		playerName.text = Main.firetongue.get(Main.player.nameFlag, "fighters");
	}

	public function updateHPBar()
	{
		hpBarFilling.clipRect.width = hpBarFilling.graphic.width * (Main.player.hp / Main.player.maxhp);
		hpBarFilling.clipRect = hpBarFilling.clipRect;

		hpText.text = Main.player.hp + " / " + Main.player.maxhp;
	}

	public function updateStatusIcons()
	{
		var statusesWithMissingIcons:Array<StatusEffect> = Main.player.statuses.copy();

		for (statusIcon in statusIcons.copy())
		{
			var foundMatch = false;
			for (i in 0...statusesWithMissingIcons.length)
				if (statusesWithMissingIcons[i] == statusIcon.status)
				{
					foundMatch = true;
					statusesWithMissingIcons.splice(i, 1);
					break;
				}
			if (!foundMatch)
			{
				statusIcon.kill();
				statusIcons.remove(statusIcon);
			}
		}

		for (status in statusesWithMissingIcons)
		{
			var icon = new CombatStatusIcon(0, 0, status);
			icon.owner = Main.player;
			sidePanelGroup.add(icon);
			statusIcons.push(icon);
		}

		for (i in 0...statusIcons.length)
		{
			var icon = statusIcons[i];

			var sx = sidePanelGroup.x + 320 - 16;
			var sy = sidePanelGroup.y + 16;

			icon.x = sx - 32 - i * (32 + 4);
			icon.y = sy;
			icon.refresh();
		}
	}

	public function updateInventory()
	{
		for (itemPanel in itemPanels)
			itemPanel.kill();
		itemPanels = [];

		var c = 0;
		for (item in Main.player.items)
		{
			var itemPanel = new CombatItemPanel(0, 90 + c * 90, item);
			sidePanelGroup.add(itemPanel);
			c++;
		}
		for (i in c...6)
		{
			var itemPanel = new CombatEmptyItemPanel(0, 90 + i * 90);
			sidePanelGroup.add(itemPanel);
		}
	}

	public var sidePanelVisible = true;
	public var canToggleSidePanel = true;

	public function setSidePanelVisible(newVisible:Bool, tweenDuration:Float = 1)
	{
		if (!canToggleSidePanel)
			return;

		sidePanelVisible = newVisible;

		var newX = newVisible ? 1280 - 320 : 1280;
		if (tweenDuration <= 0)
		{
			sidePanelGroup.x = newX;
			return;
		}
		FlxTween.tween(sidePanelGroup, {x: newX}, tweenDuration, {ease: FlxEase.cubeOut});
	}

	public function switchToSituation(newSituationType:Class<OverworldSituation>, ?args:Array<Dynamic> = null)
	{
		if (situation != null)
			situation.destroy();

		if (args == null)
			args = [];

		situation = Type.createInstance(newSituationType, args);
		add(situation);
	}

	public static var guaranteedEnemyEncounterTurns = 0;
	public static var guaranteedEnemyEncounterTurnsMax = 5;
	public static var lastRandomSituationType:Int = -1;

	public function switchToRandomSituation()
	{
		if (overworldMusic.volume <= 0.01)
		{
			overworldMusic.fadeIn(0.3, 0, 0.3);
		}

		var situationType = lastRandomSituationType;

		// Don't roll the same situation twice in a row
		while (lastRandomSituationType == situationType)
		{
			situationType = FlxG.random.getObject([0, 1, 2, 3, 4, 5], [1, 1, 1, 0.01, 2, 0.7]);
		}
		lastRandomSituationType = situationType;

		guaranteedEnemyEncounterTurns++;
		if (guaranteedEnemyEncounterTurns >= guaranteedEnemyEncounterTurnsMax)
		{
			guaranteedEnemyEncounterTurns = 0;
			situationType = 4;
		}

		switch (situationType)
		{
			case 0:
				switchToSituation(OverworldSituations.TrappedChest);
			case 1:
				var shrines:Array<Class<OverworldSituation>> = [OverworldSituations.ShrineChance, OverworldSituations.ShrineBlood];
				switchToSituation(FlxG.random.getObject(shrines));
			case 2:
				switchToSituation(OverworldSituations.HealingFountain);
			case 3:
				switchToSituation(OverworldSituations.FoundDice);
			case 4:
				var enemyName = FlxG.random.getObject(["GOLDEN_DRAGON", "BUNNY_ROBOT", "PLANT"]);
				var enemy = new Fighter();
				enemy.makeFromTemplate(enemyName);
				guaranteedEnemyEncounterTurns = 0;
				switchToSituation(OverworldSituations.EnemyEncounter, [enemy]);
			case 5:
				switchToSituation(OverworldSituations.MagicPotion);
		}
	}

	public function switchToFight(enemy:Fighter)
	{
		FlxG.switchState(new CombatState(enemy));
	}

	override function onFocus()
	{
		// super.onFocus();
	}

	override function onFocusLost()
	{
		// super.onFocusLost();
	}
}

class OverworldSituation extends FlxTypedSpriteGroup<FlxSprite>
{
	public var topText:FlxText;

	public function new()
	{
		super(0, 0);

		topText = new FlxText(190, 60, 900, "Generic overworld situation text.", 16);
		topText.alignment = CENTER;
		add(topText);
	}
}
