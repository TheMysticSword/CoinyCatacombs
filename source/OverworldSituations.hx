package;

import CombatState.CombatItemPanel;
import OverworldState.OverworldSituation;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUIButton;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import openfl.events.KeyboardEvent;

class Beginning extends OverworldSituation
{
	public var continueButton:FlxUIButton;

	public static var introMusic:FlxSound;

	public static var visitorName:String;
	public static var visitorWish:String;

	public function new(textPhase:Int = 0)
	{
		super();

		if (introMusic == null)
		{
			introMusic = FlxG.sound.load("assets/music/intro.wav", 0.3, true);
		}

		OverworldState.instance.background.color = FlxColor.BLACK;

		var firstVisit = Main.savefile.data.losses == null || Main.savefile.data.losses <= 0;

		var textPhases = [
			"$INTRO_1", "$INTRO_2", "$INTRO_3", "$INTRO_4", "$INTRO_5", "$INTRO_6", "$INTRO_7", "$INTRO_8", "$INTRO_9", "$INTRO_10", "$INTRO_11", "$INTRO_12",
			"$INTRO_13", "$INTRO_14", "$INTRO_15", "$INTRO_16"
		];

		if (!firstVisit)
		{
			textPhases = [
				"$INTRO_ABRIDGED_1",
				"$INTRO_ABRIDGED_2",
				"$INTRO_ABRIDGED_3",
				FlxG.random.getObject([
					"$INTRO_ABRIDGED_4_1",
					"$INTRO_ABRIDGED_4_2",
					"$INTRO_ABRIDGED_4_3",
					"$INTRO_ABRIDGED_4_4"
				])
			];
		}

		topText.text = firetongue.Replace.flags(Main.firetongue.get(textPhases[textPhase], "overworld"), ["<NAME>", "<WISH>"], [visitorName, visitorWish]);

		function centerText()
		{
			topText.y = 720 / 2 - topText.textField.textHeight / 2;
		}

		function setupTextInput(maxLetters:Int)
		{
			inputTextDisplay = [];

			var letterWidth = 48;
			var letterSpacing = 9;

			var totalWidth = maxLetters * letterWidth + (maxLetters - 1) * letterSpacing;

			for (i in 0...maxLetters)
			{
				var lx = 640 - totalWidth / 2 + i * (letterWidth + letterSpacing);

				var textLetter = new FlxText(lx, 360 - 24, 0, "", 48);
				add(textLetter);

				var underline = new FlxSprite(lx, 360 + 24 + 8);
				underline.makeGraphic(letterWidth, 3, FlxColor.WHITE);
				add(underline);

				inputTextDisplay.push(textLetter);
			}

			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}

		if (firstVisit)
		{
			switch (textPhase)
			{
				case 0:
					introMusic.play();
					centerText();
					OverworldState.instance.canToggleSidePanel = false;
				case 4:
					introMusic.pause();
					introMusic.volume = 0;
					centerText();
				case 11:
					introMusic.resume();
					introMusic.fadeIn(0.7, 0, 0.3);
					setupTextInput(12);
				case 12:
					setupTextInput(8);
				default:
					centerText();
			}
		}
		else
		{
			switch (textPhase)
			{
				case 0:
					introMusic.play();
					centerText();
					OverworldState.instance.canToggleSidePanel = false;
				case 1:
					setupTextInput(12);
				case 2:
					setupTextInput(8);
				default:
					centerText();
			}
		}

		topText.y -= 10;
		FlxTween.tween(topText, {y: topText.y + 10}, 0.7, {ease: FlxEase.cubeOut});

		continueButton = new FlxUIButton(640 - 80, 720 - 100, Main.firetongue.get("$GENERIC_BUTTON_CONTINUE"), () ->
		{
			if (firstVisit)
			{
				switch (textPhase)
				{
					case 11:
						if (inputText.length <= 0)
							return;
						visitorName = inputText;
					case 12:
						if (inputText.length <= 0)
							return;
						visitorWish = inputText;
				}
			}
			else
			{
				switch (textPhase)
				{
					case 1:
						if (inputText.length <= 0)
							return;
						visitorName = inputText;
					case 2:
						if (inputText.length <= 0)
							return;
						visitorWish = inputText;
				}
			}

			textPhase++;
			if (textPhase < textPhases.length)
			{
				OverworldState.instance.switchToSituation(Beginning, [textPhase]);
			}
			else
			{
				introMusic.fadeOut(0.3, 0, x ->
				{
					introMusic.stop();
					introMusic = null;
				});
				OverworldState.overworldMusic.resume();
				OverworldState.overworldMusic.fadeIn(0.3, 0, 0.3);
				FlxTween.color(OverworldState.instance.background, 1.2, FlxColor.BLACK, FlxColor.WHITE);

				OverworldState.instance.canToggleSidePanel = true;

				Main.player.nameFlag = visitorName;
				OverworldState.instance.updateName();

				FlxTween.tween(this, {alpha: 0}, 1.2, {
					onComplete: x ->
					{
						OverworldState.instance.switchToRandomSituation();
					}
				});

				if (continueButton.alive)
					continueButton.kill();
			}
		});
		continueButton.resize(160, 36);
		add(continueButton);
	}

	override function destroy()
	{
		super.destroy();

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
	}

	public var inputText:String = "";

	public var inputTextDisplay:Array<FlxText>;

	private function onKeyDown(e:KeyboardEvent):Void
	{
		var key:Int = e.keyCode;

		// Do nothing for Shift, Ctrl, Esc, flixel console hotkey, left arrow, right arrow, End, Home, Delete, Enter
		var ignoredKeys = [16, 17, 220, 27, 37, 39, 35, 36, 46, 13];
		if (ignoredKeys.contains(key))
			return;

		// Backspace
		if (key == 8)
		{
			if (inputText.length > 0)
			{
				inputTextDisplay[inputText.length - 1].text = "";
				inputText = inputText.substring(0, inputText.length - 1);
			}
		}
		// Actually add some text
		else
		{
			if (inputText.length >= inputTextDisplay.length)
				return;

			if (e.charCode == 0) // non-printable characters crash String.fromCharCode
			{
				return;
			}
			var newText:String = String.fromCharCode(e.charCode).toUpperCase();

			if (newText.length > 0)
			{
				inputText += newText;
				inputTextDisplay[inputText.length - 1].text = newText;
			}
		}
	}
}

class Coinflippable extends OverworldSituation
{
	public var coin:FlxSprite;

	public var canFlip:Bool = true;

	public var continueButton:FlxUIButton;

	public function new()
	{
		super();

		coin = new FlxSprite(640 - 76, 360 - 76);
		coin.loadGraphic("assets/images/coin_upscaled.png", true, 152, 152);
		coin.frame = coin.frames.getByIndex(FlxG.random.int(0, 1));
		add(coin);

		continueButton = new FlxUIButton(640 - 80, 720 - 100, Main.firetongue.get("$GENERIC_BUTTON_IGNORE"), onContinue);
		continueButton.resize(160, 36);
		add(continueButton);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (checkCoinMouseOverlap() && canFlip && FlxG.mouse.justPressed)
		{
			canFlip = false;

			FlxG.sound.play("assets/sounds/clink" + FlxG.random.int(1, 4) + ".wav", 0.2);

			Scripts.GlobalScripts.emitParticleBurst(FlxG.mouse.x, FlxG.mouse.y, "assets/images/particle_star.png", 3);

			var duration = 1.0;
			var spins = 2;

			var result = 0;

			var halfSpinDuration = duration / (spins * 2);
			for (i in 0...spins)
			{
				FlxTween.num(0, 1, i * halfSpinDuration + halfSpinDuration / 2 * 3, {
					onComplete: x ->
					{
						result = FlxG.random.int(0, 1);
						coin.frame = coin.frames.getByIndex(result);
					}
				});
				FlxTween.tween(coin, {"scale.x": -1}, halfSpinDuration, {ease: FlxEase.linear, startDelay: i * halfSpinDuration * 2});
				FlxTween.tween(coin, {"scale.x": 1}, halfSpinDuration, {ease: FlxEase.linear, startDelay: i * halfSpinDuration * 2 + halfSpinDuration});
			}

			FlxTween.num(0, 1, duration, {
				onComplete: x ->
				{
					canFlip = true;

					if (result == 0)
						onHeads();
					else
						onTails();
				}
			});
		}
	}

	function checkCoinMouseOverlap():Bool
	{
		for (camera in coin.cameras)
		{
			if (coin.overlapsPoint(FlxG.mouse.getWorldPosition(camera, Main.point), true, camera))
			{
				return true;
			}
		}
		return false;
	}

	public function onHeads() {}

	public function onTails() {}

	public function onContinue() {}
}

class FoundItem extends OverworldSituation
{
	public var item:Item;

	public var itemPanel:CombatItemPanel;

	public var takeButton:FlxUIButton;
	public var ignoreButton:FlxUIButton;

	public var inventoryFull:Bool = false;

	public function new(item:Item)
	{
		super();

		FlxG.sound.play("assets/sounds/found_item.wav", 0.2);

		this.item = item;

		itemPanel = new CombatItemPanel(640 - 160, 360 - 45, item);
		add(itemPanel);

		inventoryFull = Main.player.items.length >= 6;

		takeButton = new FlxUIButton(640 - 80, 720 - 100, Main.firetongue.get("$GENERIC_BUTTON_TAKE"), () ->
		{
			if (!inventoryFull)
			{
				item.owner = Main.player;
				Main.player.items.push(item);
				OverworldState.instance.updateInventory();
			}
			OverworldState.instance.switchToRandomSituation();
		});
		takeButton.resize(160, 36);
		add(takeButton);

		var topTextStr = firetongue.Replace.flags(Main.firetongue.get("$FOUND_ITEM", "overworld"), ["<ITEM>"], [Main.firetongue.get(item.nameFlag, "items")]);

		if (inventoryFull)
		{
			topTextStr += "\n" + Main.firetongue.get("$FOUND_ITEM_INVENTORYFULL", "overworld");
			takeButton.label.text = Main.firetongue.get("$GENERIC_BUTTON_IGNORE");
		}

		topText.text = topTextStr;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.mouse.justPressed && OverworldState.instance.sidePanelVisible)
		{
			for (i in 0...OverworldState.instance.itemPanels.length)
			{
				var itemPanel = OverworldState.instance.itemPanels[i];
				if (Scripts.GlobalScripts.checkMouseOverlap(itemPanel))
				{
					Main.player.items[i] = item;
					OverworldState.instance.updateInventory();
					OverworldState.instance.switchToRandomSituation();
					break;
				}
			}
		}
	}
}

class TrappedChest extends Coinflippable
{
	public var damage:Int = 2;

	public function new()
	{
		super();

		topText.text = firetongue.Replace.flags(Main.firetongue.get("$TRAPPED_CHEST", "overworld"), ["<DAMAGE>"], [Std.string(damage)]);
	}

	override function onHeads()
	{
		super.onHeads();
		OverworldState.instance.switchToSituation(FoundItem, [ItemPools.normal.roll()]);
	}

	override function onTails()
	{
		super.onTails();
		Scripts.CombatScripts.attack(null, Main.player, damage);
	}

	override function onContinue()
	{
		OverworldState.instance.switchToRandomSituation();
	}
}

class ShrineChance extends Coinflippable
{
	public function new()
	{
		super();

		topText.text = Main.firetongue.get("$SHRINE_CHANCE", "overworld");
	}

	override function onHeads()
	{
		super.onHeads();
		OverworldState.instance.switchToSituation(FoundItem, [FlxG.random.bool(33) ? ItemPools.rare.roll() : ItemPools.normal.roll()]);
	}

	override function onTails()
	{
		super.onTails();
		Main.player.addStatus(null, "LESS_COINS");
		OverworldState.instance.updateStatusIcons();
	}

	override function onContinue()
	{
		OverworldState.instance.switchToRandomSituation();
	}
}

class ShrineBlood extends Coinflippable
{
	public var damage:Int = 2;

	public function new()
	{
		super();

		topText.text = firetongue.Replace.flags(Main.firetongue.get("$SHRINE_BLOOD", "overworld"), ["<DAMAGE>"], [Std.string(damage)]);
	}

	override function onHeads()
	{
		super.onHeads();
		Main.player.addStatus(null, "MORE_COINS");
		OverworldState.instance.updateStatusIcons();
	}

	override function onTails()
	{
		super.onTails();
		Scripts.CombatScripts.attack(null, Main.player, damage);
	}

	override function onContinue()
	{
		OverworldState.instance.switchToRandomSituation();
	}
}

class HealingFountain extends Coinflippable
{
	public var heal:Int = 3;
	public var maxhp:Int = 2;

	public function new()
	{
		super();

		topText.text = firetongue.Replace.flags(Main.firetongue.get("$HEALING_FOUNTAIN", "overworld"), ["<HEAL>", "<MAXHP>"],
			[Std.string(heal), Std.string(maxhp)]);
	}

	override function onHeads()
	{
		super.onHeads();
		Scripts.CombatScripts.attack(null, Main.player, -heal);
	}

	override function onTails()
	{
		super.onTails();
		Main.player.maxhp += maxhp;
		Scripts.CombatScripts.attack(null, Main.player, -maxhp);
		OverworldState.instance.switchToRandomSituation();
	}

	override function onContinue()
	{
		OverworldState.instance.switchToRandomSituation();
	}
}

class MagicPotion extends Coinflippable
{
	public var buff:StatusEffect;
	public var debuff:StatusEffect;

	public function new()
	{
		super();

		buff = new StatusEffect();
		buff.makeFromTemplate(FlxG.random.getObject(["DODGE"]));

		debuff = new StatusEffect();
		debuff.makeFromTemplate(FlxG.random.getObject(["BURN", "SHOCK", "DECAY"]));

		topText.text = firetongue.Replace.flags(Main.firetongue.get("$MAGIC_POTION", "overworld"), ["<BUFF>", "<DEBUFF>"], [
			Main.firetongue.get(buff.nameFlag, "statuseffects"),
			Main.firetongue.get(debuff.nameFlag, "statuseffects")
		]);
	}

	override function onHeads()
	{
		super.onHeads();
		Main.player.addStatus(null, buff.id);
		OverworldState.instance.updateStatusIcons();
	}

	override function onTails()
	{
		super.onTails();
		Main.player.addStatus(null, debuff.id);
		OverworldState.instance.updateStatusIcons();
	}

	override function onContinue()
	{
		OverworldState.instance.switchToRandomSituation();
	}
}

class FoundDice extends OverworldSituation
{
	public var continueButton:FlxUIButton;

	public function new()
	{
		super();

		topText.text = Main.firetongue.get("$DICE", "overworld");

		var dice = new FlxSprite(640 - 100, 360 - 100);
		dice.loadGraphic("assets/images/dice.png");
		add(dice);

		continueButton = new FlxUIButton(640 - 80, 720 - 100, Main.firetongue.get("$GENERIC_BUTTON_CONTINUE"), () ->
		{
			OverworldState.instance.switchToRandomSituation();
		});
		continueButton.resize(160, 36);
		add(continueButton);
	}
}

class EnemyEncounter extends OverworldSituation
{
	public var enemy:Fighter;

	public var enemyImage:FlxSprite;

	public var fightButton:FlxUIButton;

	public function new(enemy:Fighter)
	{
		super();

		this.enemy = enemy;

		enemyImage = new FlxSprite(0, 0);
		enemyImage.loadGraphic("assets/images/" + enemy.combatImage);
		enemyImage.setPosition(640 - enemyImage.width / 2, 360 - enemyImage.height / 2);
		add(enemyImage);

		fightButton = new FlxUIButton(640 - 80, 720 - 100, Main.firetongue.get("$GENERIC_BUTTON_FIGHT"), () ->
		{
			OverworldState.instance.switchToFight(enemy);
		});
		fightButton.resize(160, 36);
		add(fightButton);

		topText.text = firetongue.Replace.flags(Main.firetongue.get("$ENEMY_ENCOUNTER_" + FlxG.random.int(1, 5), "overworld"), ["<ENEMY>"],
			[Main.firetongue.get(enemy.nameFlag, "fighters")]);
	}
}
