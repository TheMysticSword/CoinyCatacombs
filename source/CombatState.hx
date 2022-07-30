package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.ui.FlxUIButton;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSort;

class CombatFighterPanel extends FlxTypedSpriteGroup<FlxSprite>
{
	public static var instances:Array<CombatFighterPanel>;

	public var fighter:Fighter;

	public var name:FlxText;
	public var hpBarGroup:FlxTypedSpriteGroup<FlxSprite>;
	public var hpBarBG:FlxSprite;
	public var hpBarFilling:FlxSprite;
	public var hpText:FlxText;

	public var skillButton:FlxUIButton;
	public var coinTossSlots:Array<Array<FlxSprite>>;
	public var skillDesc:FlxText;

	public var flavourText:FlxText;

	public var statusIcons:Array<CombatStatusIcon>;

	public function new(X:Float, Y:Float, fighter:Fighter)
	{
		super(X, Y);

		cameras = [Main.uiCamera];

		if (instances == null)
			instances = new Array<CombatFighterPanel>();
		instances.push(this);

		this.fighter = fighter;

		var bgRect = new FlxSprite(0, 0);
		bgRect.makeGraphic(1280, 180, FlxColor.BLACK);
		add(bgRect);

		var enemyInfoX = fighter.isPlayer ? 0 : 1280 - 320;
		var enemyInfoY = 0;

		name = new FlxText(enemyInfoX + 20, enemyInfoY + 20, 0, Main.firetongue.get(fighter.nameFlag, "fighters"), 18);
		add(name);

		hpBarGroup = new FlxTypedSpriteGroup<FlxSprite>(enemyInfoX + 20, enemyInfoY + 54);
		add(hpBarGroup);

		hpBarBG = new FlxSprite(0, 0);
		hpBarBG.makeGraphic(280, 28, FlxColor.fromString("0x910C00"));
		hpBarGroup.add(hpBarBG);

		var hpBarFillingPadding = 3;
		hpBarFilling = new FlxSprite(hpBarFillingPadding, hpBarFillingPadding);
		hpBarFilling.makeGraphic(Std.int(hpBarBG.width) - hpBarFillingPadding * 2, Std.int(hpBarBG.height) - hpBarFillingPadding * 2,
			FlxColor.fromString("0xF24741"));
		hpBarFilling.updateHitbox();
		hpBarGroup.add(hpBarFilling);
		hpBarFilling.clipRect = new FlxRect(0, 0, hpBarFilling.graphic.width, hpBarFilling.graphic.height);

		hpText = new FlxText(0, 0, 280, "", 18);
		hpText.alignment = CENTER;
		hpText.updateHitbox();
		hpBarGroup.add(hpText);

		updateHPBar();
		statusIcons = [];
		updateStatusIcons();

		if (fighter.isPlayer)
		{
			skillButton = new FlxUIButton(enemyInfoX + 20, enemyInfoY + 120, "", fighter.asPlayer.onSkillUsed);
			skillButton.resize(110, 28);
			add(skillButton);

			skillDesc = new FlxText(enemyInfoX + 20, enemyInfoY + 134, 108, "", 9);
			skillDesc.alignment = CENTER;
			skillDesc.updateHitbox();
			add(skillDesc);

			coinTossSlots = [[], []];
		}
		else
		{
			flavourText = new FlxText(enemyInfoX + 20, enemyInfoY + 94, 270, Main.firetongue.get(fighter.descFlag, "fighters"), 12);
			flavourText.alignment = CENTER;
			flavourText.updateHitbox();
			add(flavourText);
			flavourText.y = y + enemyInfoY + 86 + 76 / 2 - flavourText.textField.textHeight / 2;
		}

		var itemPanelX = fighter.isPlayer ? 320 : 0;
		var itemPanelY = 0;
		for (i in 0...6)
		{
			if (i < fighter.items.length)
			{
				var itemPanel = new CombatItemPanel(itemPanelX, itemPanelY, fighter.items[i]);
				add(itemPanel);
			}
			else
			{
				var itemPanel = new CombatEmptyItemPanel(itemPanelX, itemPanelY);
				add(itemPanel);
			}

			itemPanelX += 320;
			if (((i + 1) % 3) == 0)
			{
				itemPanelX -= 320 * 3;
				itemPanelY += 90;
			}
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		updateHPBar();
	}

	public function updateHPBar()
	{
		hpBarFilling.clipRect.width = hpBarFilling.graphic.width * (fighter.hp / fighter.maxhp);
		hpBarFilling.clipRect = hpBarFilling.clipRect;

		hpText.text = fighter.hp + " / " + fighter.maxhp;
		hpText.updateHitbox();
	}

	public function shakeHPBar(intensity:Float = 4, duration:Float = 0.1)
	{
		var shakePoints = new Array<FlxPoint>();
		var shakePointCount = Math.round(Math.max(160 * duration, 1));
		for (i in 0...shakePointCount)
			shakePoints.push(new FlxPoint(hpBarGroup.x + FlxG.random.float(-1, 1) * intensity, hpBarGroup.y + FlxG.random.float(-1, 1) * intensity));
		shakePoints.push(new FlxPoint(hpBarGroup.x, hpBarGroup.y));
		FlxTween.linearPath(hpBarGroup, shakePoints, duration, true, {
			ease: FlxEase.smoothStepInOut,
			onComplete: x -> resetHPBarPosition()
		});
		FlxTween.num(0, 1, duration + 0.09, {onComplete: x -> resetHPBarPosition()});
	}

	public function resetHPBarPosition()
	{
		hpBarGroup.x = x + (fighter.isPlayer ? 20 : 1280 - 300);
		hpBarGroup.y = y + 54;
	}

	public function updateStatusIcons()
	{
		var statusesWithMissingIcons:Array<StatusEffect> = fighter.statuses.copy();

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
			icon.owner = fighter;
			add(icon);
			statusIcons.push(icon);
		}

		for (i in 0...statusIcons.length)
		{
			var icon = statusIcons[i];

			var sx = x + (fighter.isPlayer ? 320 : 1280) - 16;
			var sy = y + 16;

			icon.x = sx - 32 - i * (32 + 4);
			icon.y = sy;
			icon.refresh();
		}
	}

	public function refreshSkillButton()
	{
		if (fighter.isPlayer)
		{
			for (row in coinTossSlots)
				for (slot in row)
					slot.kill();
			coinTossSlots = [[], []];

			if (fighter.asPlayer.skill != null)
			{
				switch (fighter.asPlayer.skill.id)
				{
					case "COIN_TOSS":
						for (i in 0...fighter.asPlayer.maxHeadsThisTurn)
						{
							var newSlot = new FlxSprite(148 + (38 + 4) * i, 96);
							newSlot.loadGraphic("assets/images/coinslots.png", true, 38, 38);
							add(newSlot);
							coinTossSlots[0].push(newSlot);
						}

						for (i in 0...fighter.asPlayer.maxTailsThisTurn)
						{
							var newSlot = new FlxSprite(148 + (38 + 4) * i, 96 + 38 + 4);
							newSlot.loadGraphic("assets/images/coinslots.png", true, 38, 38);
							add(newSlot);
							coinTossSlots[1].push(newSlot);
						}

						skillButton.x = x + 20;
						skillDesc.x = x + 20;
						skillDesc.fieldWidth = 108;
					default:
						skillButton.x = x + 105;
						skillDesc.x = x + 20;
						skillDesc.fieldWidth = 280;
				}
			}
		}

		updateSkillButton();
	}

	public function updateSkillButton()
	{
		if (!fighter.isPlayer)
			return;

		var skill = fighter.asPlayer.skill;

		var skillFlag = skill != null ? skill.nameFlag : "";

		if (skill != null)
		{
			if (skill.id == "COIN_TOSS")
			{
				if (fighter.asPlayer.bust)
					skillFlag += "_BUST";
				else if (fighter.asPlayer.jackpot)
					skillFlag += "_JACKPOT";
			}

			if (skill.remainingUses <= 0 && !skill.reuseable) {}
		}

		skillButton.label.text = Main.firetongue.get(skillFlag, "skills");
		skillButton.updateHitbox();

		skillDesc.text = skill != null ? Main.firetongue.get(skill.descFlag, "skills") : "";
		if (skillDesc.text == "(should not appear)")
			skillDesc.text = "";
		if (skill != null)
		{
			if (skill.limitBreak)
			{
				if (skillDesc.text.length > 0)
					skillDesc.text += "\n";
				var hpRemaining = fighter.asPlayer.limitBreakRequirement - fighter.asPlayer.limitBreakCharge;
				if (hpRemaining > 0)
				{
					skillDesc.text += firetongue.Replace.flags(Main.firetongue.get("$LIMIT_BREAK_REMAINING"), ["<REMAINING_HP>"], [Std.string(hpRemaining)]);
				}
				else
				{
					skillDesc.text += Main.firetongue.get("$LIMIT_BREAK_READY");
				}
			}
			if (!skill.hideReuseable && (!skill.limitBreak || skill.maxUses > 1 || skill.reuseable))
			{
				var usesRemainingFlag = "$USES_REMAINING_GENERIC";
				if (skill.remainingUses >= 0 && skill.remainingUses <= 12)
					usesRemainingFlag = "$USES_REMAINING_" + skill.remainingUses;
				if (skill.reuseable)
					usesRemainingFlag = "$REUSEABLE";

				if (skillDesc.text.length > 0)
					skillDesc.text += "\n";
				skillDesc.text += Main.firetongue.get(usesRemainingFlag);
			}
		}
		if (skillDesc.text.length > 0)
		{
			skillButton.y = y + 100;
		}
		else
		{
			skillButton.y = y + 120;
		}

		for (i in 0...coinTossSlots.length)
		{
			for (j in 0...coinTossSlots[i].length)
			{
				var frameIndex = 0;
				switch (i)
				{
					case 0:
						frameIndex = 0;
						if (fighter.asPlayer.currentHeadsThisTurn <= fighter.asPlayer.maxHeadsThisTurn)
						{
							if (fighter.asPlayer.currentHeadsThisTurn > j)
								frameIndex = 3;
						}
						else
							frameIndex = 4;
					case 1:
						frameIndex = 1;
						if (fighter.asPlayer.currentTailsThisTurn <= fighter.asPlayer.maxTailsThisTurn)
						{
							if (fighter.asPlayer.currentTailsThisTurn > j)
								frameIndex = 3;
						}
						else
							frameIndex = 4;
				}
				coinTossSlots[i][j].frame = coinTossSlots[i][j].frames.getByIndex(frameIndex);
			}
		}
	}

	public static function findForFighter(fighter:Fighter):CombatFighterPanel
	{
		if (instances == null)
			return null;

		instances = instances.filter(x -> x != null && x.exists);
		for (instance in instances)
			if (instance.fighter == fighter)
				return instance;
		return null;
	}
}

class CombatItemPanel extends FlxTypedSpriteGroup<FlxSprite>
{
	public static var instances:Array<CombatItemPanel>;

	public var item:Item;

	public var bgRect:FlxSprite;
	public var bgRectDarker:FlxSprite;
	public var name:FlxText;
	public var desc:FlxText;
	public var coinSlots:Array<FlxSprite>;

	public var transparentDarkenBar:FlxSprite;
	public var transparentDarkenBarTween:FlxTween;

	public var cooldownPanelGroup:FlxTypedSpriteGroup<FlxSprite>;
	public var cooldownPanelTitle:FlxText;
	public var cooldownPanelSubtitle:FlxText;

	public function new(X:Float, Y:Float, item:Item)
	{
		super(X, Y);
		this.item = item;

		cameras = [Main.uiCamera];

		if (instances == null)
			instances = new Array<CombatItemPanel>();
		instances.push(this);

		bgRect = new FlxSprite(0, 0);
		bgRect.makeGraphic(320, 90, FlxColor.WHITE);
		add(bgRect);

		var darkerPadding = 4;
		bgRectDarker = new FlxSprite(darkerPadding, darkerPadding);
		bgRectDarker.makeGraphic(320 - darkerPadding * 2, 90 - darkerPadding * 2, FlxColor.WHITE.getDarkened(0.32));
		add(bgRectDarker);

		name = new FlxText(10, 8, 0, Main.firetongue.get(item.nameFlag, "items"), 18);
		add(name);

		desc = new FlxText(10, 32, 0, Main.firetongue.get(item.descFlag, "items"), 12);
		add(desc);

		transparentDarkenBar = new FlxSprite(0, 0);
		transparentDarkenBar.makeGraphic(320, 90, FlxColor.BLACK);
		transparentDarkenBar.alpha = 0.4;
		add(transparentDarkenBar);
		transparentDarkenBar.clipRect = new FlxRect(0, 0, 0, 90);
		transparentDarkenBar.clipRect = transparentDarkenBar.clipRect;

		cooldownPanelGroup = new FlxTypedSpriteGroup<FlxSprite>(0, 0);
		add(cooldownPanelGroup);

		var cooldownBGRect = new FlxSprite(0, 0);
		cooldownBGRect.makeGraphic(320, 90, FlxColor.BLACK);
		cooldownPanelGroup.add(cooldownBGRect);
		cooldownPanelGroup.health = 100;

		cooldownPanelTitle = new FlxText(20, 14, 280, Main.firetongue.get(item.nameFlag, "items"), 24);
		cooldownPanelTitle.alignment = CENTER;
		cooldownPanelGroup.add(cooldownPanelTitle);

		cooldownPanelSubtitle = new FlxText(20, 48, 280, "", 14);
		cooldownPanelSubtitle.alignment = CENTER;
		cooldownPanelGroup.add(cooldownPanelSubtitle);

		cooldownPanelGroup.clipRect = new FlxRect(0, 0, 320, 0);

		coinSlots = [];
		refresh();
	}

	public function onCoinInserted()
	{
		refresh();

		if (item.slots.length >= 2 && item.slots[0] == Matching && item.insertedCoins[0] != null && item.insertedCoins[1] == null)
		{
			for (i in 1...coinSlots.length)
			{
				var slot = coinSlots[i];
				var slotFlash = new FlxSprite(0, 0);
				slotFlash.loadGraphic("assets/images/coinslots.png", true, 38, 38);
				slotFlash.frame = slotFlash.frames.getByIndex(3);
				FlxTween.tween(slotFlash, {alpha: 0}, 0.6, {onComplete: x -> slotFlash.kill()});
				add(slotFlash);
				slotFlash.x = slot.x;
				slotFlash.y = slot.y;
			}
		}
	}

	public function rollCooldownPanel(show:Bool, duration:Float)
	{
		FlxTween.tween(cooldownPanelGroup, {"clipRect.height": show ? 90 : 0}, duration, {
			onUpdate: x ->
			{
				cooldownPanelGroup.clipRect = cooldownPanelGroup.clipRect;
			},
			onComplete: x ->
			{
				cooldownPanelGroup.clipRect = cooldownPanelGroup.clipRect;
			},
			ease: show ? FlxEase.bounceOut : FlxEase.sineOut
		});
	}

	public function tempDarkenBar(duration:Float)
	{
		if (transparentDarkenBarTween != null)
			transparentDarkenBarTween.cancel();

		transparentDarkenBar.clipRect.width = 320;
		transparentDarkenBar.clipRect = transparentDarkenBar.clipRect;
		transparentDarkenBarTween = FlxTween.tween(transparentDarkenBar, {"clipRect.width": 0}, duration, {
			onUpdate: x ->
			{
				transparentDarkenBar.clipRect = transparentDarkenBar.clipRect;
			},
			onComplete: x ->
			{
				transparentDarkenBar.clipRect = transparentDarkenBar.clipRect;
			},
			ease: FlxEase.linear
		});
	}

	public function refresh()
	{
		name.text = Main.firetongue.get(item.nameFlag, "items");
		cooldownPanelTitle.text = name.text;
		if (cooldownPanelTitle.text.length >= 11)
			cooldownPanelTitle.size = 24 - (cooldownPanelTitle.text.length - 11);

		var descText = Main.firetongue.get(item.descFlag, "items");
		if (item.maxUses > 1 || item.reuseable)
		{
			var usesRemainingFlag = "$USES_REMAINING_GENERIC";
			if (item.remainingUses >= 0 && item.remainingUses <= 12)
				usesRemainingFlag = "$USES_REMAINING_" + item.remainingUses;
			if (item.reuseable)
				usesRemainingFlag = "$REUSEABLE";

			if (descText.length > 0)
				descText += "\n";
			descText += Main.firetongue.get(usesRemainingFlag);
		}
		desc.text = descText;

		for (slot in coinSlots)
			slot.kill();
		coinSlots = [];
		var slotCount = item.slots.length;
		var slotX = 255.0 - 38 / 2 - (38 / 2 + 4.5) * (slotCount - 1);
		var slotY = 4.5;
		if (slotCount <= 3)
			slotY = 90 / 2 - 38 / 2;
		for (i in 0...item.slots.length)
		{
			var slot = item.slots[i];

			var slotSprite = new FlxSprite(slotX, slotY);
			add(slotSprite);

			if (item.insertedCoins[i] == null)
			{
				var graphicPath = "assets/images/coinslots.png";
				var graphicFrame = 0;
				var goldColor = FlxColor.fromString("0xFFF247");
				switch (slot)
				{
					case Normal:
						graphicFrame = 2;
					case Gold:
						graphicFrame = 5;
						slotSprite.color = goldColor;
					case Heads:
						graphicFrame = 0;
					case Tails:
						graphicFrame = 1;
					case GoldHeads:
						graphicFrame = 0;
						slotSprite.color = goldColor;
					case GoldTails:
						graphicFrame = 1;
						slotSprite.color = goldColor;
					case Matching:
						if (item.insertedCoins[0] == null)
							graphicFrame = 6;
						else
						{
							switch (item.insertedCoins[0])
							{
								case Heads | GoldHeads:
									graphicFrame = 0;
								case Tails | GoldTails:
									graphicFrame = 1;
							}
						}
				}
				slotSprite.loadGraphic(graphicPath, true, 38, 38);
				slotSprite.frame = slotSprite.frames.getByIndex(graphicFrame);
			}
			else
			{
				var graphicPath = "assets/images/coin.png";
				var graphicFrame = 0;
				switch (item.insertedCoins[i])
				{
					case Heads:
						graphicFrame = 0;
					case Tails:
						graphicFrame = 1;
					case GoldHeads:
						graphicFrame = 2;
					case GoldTails:
						graphicFrame = 3;
				}
				slotSprite.loadGraphic(graphicPath, true, 38, 38);
				slotSprite.frame = slotSprite.frames.getByIndex(graphicFrame);
			}

			slotX += 38 + 4.5;
			if (((i + 1) % 3) == 0)
			{
				slotX -= (38 + 4.5) * 3;
				slotY += 38 + 4.5;
			}

			slotSprite.health = 2;
			coinSlots.push(slotSprite);
		}

		bgRect.color = item.colour;
		bgRectDarker.color = item.colour;

		if (item.cooldown > 0)
		{
			var cooldownTextFlag = "$ITEM_COOLDOWN_GENERIC" + item.cooldown;
			if (item.cooldown >= 1 && item.cooldown <= 12)
				cooldownTextFlag = "$ITEM_COOLDOWN_" + item.cooldown;
			if (item.cooldownTextFlagOverride.length > 0)
				cooldownTextFlag = item.cooldownTextFlagOverride;
			cooldownPanelSubtitle.text = firetongue.Replace.flags(Main.firetongue.get(cooldownTextFlag), ["<TURNS>"], [Std.string(item.cooldown)]);
		}

		sort(function(Order:Int, Obj1:FlxObject, Obj2:FlxObject)
		{
			return FlxSort.byValues(Order, Obj1.health, Obj2.health);
		});
	}

	public static function findForItem(item:Item):CombatItemPanel
	{
		instances = instances.filter(x -> x != null && x.exists);
		for (instance in instances)
			if (instance.item == item)
				return instance;
		return null;
	}
}

class CombatEmptyItemPanel extends FlxTypedSpriteGroup<FlxSprite>
{
	public var bgRect:FlxSprite;
	public var bgRectDarker:FlxSprite;

	public function new(X:Float, Y:Float)
	{
		super(X, Y);

		cameras = [Main.uiCamera];

		bgRect = new FlxSprite(0, 0);
		bgRect.makeGraphic(320, 90, FlxColor.WHITE);
		add(bgRect);

		var darkerPadding = 4;
		bgRectDarker = new FlxSprite(darkerPadding, darkerPadding);
		bgRectDarker.makeGraphic(320 - darkerPadding * 2, 90 - darkerPadding * 2, FlxColor.WHITE.getDarkened(0.32));
		add(bgRectDarker);

		color = FlxColor.fromString("0x2D2D2D");
	}
}

class CombatStatusIcon extends FlxTypedSpriteGroup<FlxSprite>
{
	public var status:StatusEffect;

	public var icon:FlxSprite;
	public var stackText:FlxText;

	public var tooltipGroup:FlxTypedSpriteGroup<FlxSprite>;
	public var tooltipBG:FlxSprite;
	public var tooltipText:FlxText;

	public var owner:Fighter;

	public function new(X:Float, Y:Float, status:StatusEffect)
	{
		super(X, Y);

		this.status = status;

		icon = new FlxSprite(0, 0);
		icon.makeGraphic(128, 128, FlxColor.WHITE);
		add(icon);

		stackText = new FlxText(20, 20, 0, "1", 9);
		add(stackText);

		tooltipGroup = new FlxTypedSpriteGroup<FlxSprite>(0, 0);
		add(tooltipGroup);

		tooltipBG = new FlxSprite(0, 0);
		tooltipBG.makeGraphic(100, 100, FlxColor.BLACK);
		tooltipBG.alpha = 0.7;
		tooltipGroup.add(tooltipBG);

		tooltipText = new FlxText(3, 3, 0, "", 12);
		tooltipGroup.add(tooltipText);

		refresh();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (checkMouseOverlap())
		{
			tooltipGroup.visible = true;
		}
		else
		{
			tooltipGroup.visible = false;
		}
	}

	function checkMouseOverlap():Bool
	{
		for (camera in icon.cameras)
		{
			if (icon.overlapsPoint(FlxG.mouse.getWorldPosition(camera, Main.point), true, camera))
			{
				return true;
			}
		}
		return false;
	}

	public function refresh()
	{
		icon.loadGraphic("assets/images/" + status.icon);
		icon.scale.set(26 / icon.graphic.width, 26 / icon.graphic.height);
		icon.updateHitbox();

		icon.color = status.colour;

		if (status.stackable)
		{
			stackText.visible = true;
			stackText.text = Std.string(status.value);
			stackText.color = status.colour;
		}
		else
		{
			stackText.visible = false;
		}

		tooltipText.text = firetongue.Replace.flags(Main.firetongue.get("$STATUS_EFFECT_NAME_FORMAT", "statuseffects"),
			["<NAME>", "<SPACE_IF_STACKABLE>", "<VALUE>"], [
				Main.firetongue.get(status.nameFlag, "statuseffects"),
				status.stackable ? " " : "",
				Std.string(status.value)
			])
			+ "\n"
			+ firetongue.Replace.flags(Main.firetongue.get(status.descFlag, "statuseffects"), ["<VALUE>"], [Std.string(status.value)]);
		tooltipBG.scale.set((tooltipText.textField.textWidth + 9) / tooltipBG.graphic.height,
			(tooltipText.textField.textHeight + 9) / tooltipBG.graphic.height);
		tooltipBG.updateHitbox();

		tooltipGroup.x = x - tooltipText.textField.textWidth / 2 - 3;
		if (tooltipGroup.x < 10)
			tooltipGroup.x = 10;
		if ((tooltipGroup.x + tooltipGroup.width) > 1270)
			tooltipGroup.x = 1270 - tooltipGroup.width;
		tooltipGroup.y = y + (owner != null
			&& owner.isPlayer
			&& CombatState.instance != null ? -tooltipText.textField.textHeight - 40 : 40);
	}
}

class CombatState extends FlxState
{
	public static var instance:CombatState;

	public var enemy:Fighter;

	public var playerPanel:CombatFighterPanel;
	public var enemyPanel:CombatFighterPanel;

	public var currentTurnFighter:Fighter;
	public var turnNumber:Int = 0;
	public var turnTransition:Bool = false;

	public var background:FlxSprite;
	public var firstPerson:FlxTypedSpriteGroup<FlxSprite>;
	public var firstPersonTweenPoint:FlxObject;
	public var firstPersonTween:FlxTween;
	public var enemyImage:FlxSprite;
	public var enemyImageBottomY:Float;

	public var endTurnGroup:FlxTypedSpriteGroup<FlxSprite>;
	public var endTurnHitbox:FlxSprite;

	public var enemyAI:CombatAI;

	public function new(enemy:Fighter)
	{
		super();
		this.enemy = enemy;
	}

	public static var combatMusic:FlxSound;
	private static var playingTrack:String = "";

	public static function startCombatMusic(newTrack:String)
	{
		if (playingTrack != newTrack)
		{
			if (combatMusic != null && combatMusic.alive && combatMusic.exists)
			{
				combatMusic.stop();
				combatMusic.kill();
			}

			combatMusic = FlxG.sound.load(newTrack, 0, true);
			combatMusic.persist = true;
			combatMusic.play();

			playingTrack = newTrack;
		}
	}

	override public function create()
	{
		super.create();

		Main.setupCameras();

		if (combatMusic != null)
		{
			combatMusic.fadeIn(0.3, 0, 0.2);
		}
		if (OverworldState.overworldMusic != null)
		{
			OverworldState.overworldMusic.fadeIn(0.3, 0.3, 0);
		}

		instance = this;

		background = new FlxSprite(0, 0);
		background.loadGraphic("assets/images/battle_bg_summer.png");
		add(background);

		enemyImage = new FlxSprite(0, 0);
		enemyImage.visible = false;
		add(enemyImage);

		firstPerson = new FlxTypedSpriteGroup<FlxSprite>(0, 0);
		add(firstPerson);
		var firstPersonSprite = new FlxSprite(0, 0);
		firstPersonSprite.loadGraphic("assets/images/fps.png");
		firstPerson.add(firstPersonSprite);
		firstPersonTweenPoint = new FlxObject();
		firstPersonTween = FlxTween.linearPath(firstPersonTweenPoint, [
			new FlxPoint(0, 40),
			new FlxPoint(0, 20),
			new FlxPoint(0, 10),
			new FlxPoint(0, 0),
			new FlxPoint(0, 40)
		], 2.0, true, {
			ease: FlxEase.circInOut,
			type: LOOPING
		});

		endTurnGroup = new FlxTypedSpriteGroup<FlxSprite>(1280 - 60, 540 - 60);
		add(endTurnGroup);

		var hitboxExtents = 30;
		endTurnHitbox = new FlxSprite(-hitboxExtents, -hitboxExtents);
		endTurnHitbox.makeGraphic(29 + hitboxExtents * 2, 29 + hitboxExtents * 2, FlxColor.TRANSPARENT);
		endTurnGroup.add(endTurnHitbox);

		var endTurnSprite = new FlxSprite(0, 0);
		endTurnSprite.loadGraphic("assets/images/end_turn.png");
		endTurnGroup.add(endTurnSprite);

		var endTurnText = new FlxText(-150 + endTurnSprite.width / 2, 28, 300, Main.firetongue.get("$END_TURN"), 12);
		endTurnText.alignment = CENTER;
		endTurnGroup.add(endTurnText);

		playerPanel = new CombatFighterPanel(0, 540, Main.player);
		add(playerPanel);

		enemyPanel = new CombatFighterPanel(0, 0, enemy);
		add(enemyPanel);

		if (enemy.combatImage.length > 0)
		{
			enemyImage.visible = true;

			enemyImage.loadGraphic("assets/images/" + enemy.combatImage);
			enemyImage.updateHitbox();

			enemyImage.x = FlxG.width / 2 - enemyImage.width / 2 + enemy.combatImageOffset.x;
			enemyImage.y = FlxG.height / 2 - enemyImage.height / 2 + enemy.combatImageOffset.y;

			switch (enemy.combatAnimationType)
			{
				case "float":
					enemyImage.y -= 20;
					enemyMotionDown();
				case "idle":
					enemyImageBottomY = enemyImage.y + enemyImage.height;
					enemyMotionBreatheIn();
			}
		}

		currentTurnFighter = Main.player;
		turnNumber = 1;

		enemyAI = new CombatAI(enemy, Main.player);

		beforeStartTurn();
	}

	function enemyMotionUp()
	{
		FlxTween.tween(enemyImage, {y: enemyImage.y - 40}, 1.0, {ease: FlxEase.sineInOut, onComplete: x -> enemyMotionDown()});
	}

	function enemyMotionDown()
	{
		FlxTween.tween(enemyImage, {y: enemyImage.y + 40}, 1.0, {ease: FlxEase.sineInOut, onComplete: x -> enemyMotionUp()});
	}

	function enemyMotionBreatheOut()
	{
		FlxTween.tween(enemyImage, {"scale.x": 1, "scale.y": 1}, 3.0, {
			ease: FlxEase.sineInOut,
			onUpdate: x ->
			{
				enemyImage.updateHitbox();
				enemyImage.x = FlxG.width / 2 - enemyImage.width / 2 + enemy.combatImageOffset.x;
				enemyImage.y = enemyImageBottomY - enemyImage.height;
			},
			onComplete: x -> enemyMotionBreatheIn()
		});
	}

	function enemyMotionBreatheIn()
	{
		FlxTween.tween(enemyImage, {"scale.x": 0.95, "scale.y": 1.05}, 3.0, {
			ease: FlxEase.sineInOut,
			onUpdate: x ->
			{
				enemyImage.updateHitbox();
				enemyImage.x = FlxG.width / 2 - enemyImage.width / 2;
				enemyImage.y = enemyImageBottomY - enemyImage.height;
			},
			onComplete: x -> enemyMotionBreatheOut()
		});
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		firstPerson.forEachAlive(child ->
		{
			child.x = firstPerson.x + firstPersonTweenPoint.x;
			child.y = firstPerson.y + firstPersonTweenPoint.y;
		});

		if (!turnTransition)
		{
			if (currentTurnFighter == Main.player)
			{
				endTurnGroup.alpha = 0.4;
				if (endTurnHitbox.overlapsPoint(FlxG.mouse.getWorldPosition(Main.uiCamera, Main.point), true, Main.uiCamera))
				{
					endTurnGroup.alpha = 0.7;

					if (FlxG.mouse.justPressed)
						endTurn();
				}
			}
			else
			{
				endTurnGroup.alpha = 0;

				enemyAI.update(elapsed);

				if (enemyAI.noMoreMoves)
					endTurn();
			}
		}
		else
		{
			endTurnGroup.alpha = 0;
		}
	}

	public function beforeStartTurn()
	{
		if (currentTurnFighter == Main.player)
		{
			turnNumber++;

			FlxTween.tween(firstPerson, {y: 0}, 0.9, {ease: FlxEase.sineOut});
			FlxTween.tween(playerPanel, {y: 540}, 0.5, {ease: FlxEase.sineOut});
		}
		else
		{
			FlxTween.tween(firstPerson, {y: FlxG.height}, 0.7, {ease: FlxEase.sineIn});
			FlxTween.tween(playerPanel, {y: FlxG.height - 90}, 0.5, {ease: FlxEase.sineOut});

			enemyAI.delay = 1.0;
			enemyAI.noMoreMoves = false;
		}

		currentTurnFighter.beforeStartTurn();

		FlxTween.num(0, 1, 0.5, {
			onComplete: x ->
			{
				for (coin in currentTurnFighter.coinInstances)
					if (coin.exists && coin.alive)
						coin.kill();
				currentTurnFighter.coinInstances = [];
				currentTurnFighter.tossInitialCoins();
			}
		});

		turnTransition = true;
		FlxTween.num(0, 1, 1.0, {
			onComplete: x ->
			{
				turnTransition = false;
				startTurn();
			}
		});
	}

	public function startTurn()
	{
		currentTurnFighter.onStartTurn();
	}

	public function endTurn()
	{
		currentTurnFighter.onEndTurn();

		var c = 0;
		for (coin in currentTurnFighter.coinInstances)
			if (coin.alive && !coin.consumed)
			{
				coin.vanish(0.1 * c);
				c++;
			}

		currentTurnFighter.coinInstances = [];

		var newTurnFighter:Fighter = Main.player;
		if (currentTurnFighter == Main.player)
			newTurnFighter = enemy;
		if (currentTurnFighter.hasStatus("EXTRATURN"))
		{
			currentTurnFighter.removeStatus("EXTRATURN");
			newTurnFighter = currentTurnFighter;
		}

		turnTransition = true;
		FlxTween.num(0, 1, 0.5 + 0.1 * c, {
			onComplete: x ->
			{
				currentTurnFighter = newTurnFighter;
				beforeStartTurn();
			}
		});
	}

	public function triggerLoss(lostFighter:Fighter)
	{
		combatMusic.fadeOut(0.01, 0.0);

		turnTransition = true;

		for (coin in currentTurnFighter.coinInstances)
		{
			coin.tweenCount++;
			FlxTween.tween(coin, {y: coin.owner.isPlayer ? 720 + 20 : -20 - 38}, 0.5, {ease: FlxEase.cubeOut});
		}

		if (lostFighter.isPlayer)
		{
			FlxG.sound.play("assets/sounds/combat_loss.wav", 0.3);

			if (Main.savefile.data.losses == null)
				Main.savefile.data.losses = 0;
			Main.savefile.data.losses++;
			Main.savefile.flush();

			FlxTween.tween(firstPerson, {y: FlxG.height}, 0.7, {ease: FlxEase.sineIn});
			FlxTween.tween(playerPanel, {y: FlxG.height}, 0.5, {ease: FlxEase.sineOut});

			var lossTextStr = firetongue.Replace.flags(Main.firetongue.get("$FIGHTER_LOSS"), ["<NAME>"],
				[Main.firetongue.get(Main.player.nameFlag, "fighters")]);
			lossTextStr += "\r\n";
			lossTextStr += firetongue.Replace.flags(Main.firetongue.get("$POST_GAME_INFO"), ["<LOSSES>"], [Std.string(Main.savefile.data.losses)]);

			var lossText = new FlxText(100, -100, 1080, lossTextStr, 14);
			lossText.alignment = CENTER;
			add(lossText);
			FlxTween.tween(lossText, {y: 300}, 0.4, {ease: FlxEase.cubeOut, startDelay: 1.0});

			var continueButton = new FlxUIButton(640 - 80, 800, Main.firetongue.get("$GENERIC_BUTTON_BACK_TO_MENU"), () ->
			{
				FlxG.switchState(new MenuState());
			});
			continueButton.resize(160, 36);
			add(continueButton);
			FlxTween.tween(continueButton, {y: 720 - 100}, 0.4, {ease: FlxEase.cubeOut, startDelay: 1.0});
		}
		else
		{
			FlxG.sound.play("assets/sounds/combat_win.wav", 0.3);

			FlxTween.cancelTweensOf(enemyImage);
			FlxTween.tween(enemyImage, {"scale.x": 0, "scale.y": 0}, 0.5, {ease: FlxEase.cubeOut, onComplete: x -> enemyImage.updateHitbox()});
			FlxTween.tween(enemyPanel, {y: -180}, 0.5, {ease: FlxEase.sineOut});

			FlxTween.tween(firstPerson, {y: FlxG.height}, 0.7, {ease: FlxEase.sineIn});
			FlxTween.tween(playerPanel, {y: FlxG.height}, 0.5, {ease: FlxEase.sineOut});

			var winText = new FlxText(100, -100, 1080,
				firetongue.Replace.flags(Main.firetongue.get("$FIGHTER_WIN"), ["<NAME>"], [Main.firetongue.get(Main.player.nameFlag, "fighters")]), 14);
			winText.alignment = CENTER;
			add(winText);
			FlxTween.tween(winText, {y: 300}, 0.4, {ease: FlxEase.cubeOut, startDelay: 1.0});

			var continueButton = new FlxUIButton(640 - 80, 800, Main.firetongue.get("$GENERIC_BUTTON_CONTINUE"), () ->
			{
				FlxG.switchState(new OverworldState());
			});
			continueButton.resize(160, 36);
			add(continueButton);
			FlxTween.tween(continueButton, {y: 720 - 100}, 0.4, {ease: FlxEase.cubeOut, startDelay: 1.0});

			/*
				FlxTween.num(0, 1, 1.0, {
					onComplete: x -> {}
				});
			 */
		}
	}

	override function destroy()
	{
		super.destroy();

		instance = null;
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

typedef CombatAIMove =
{
	public var parent:CombatAIMove;
	public var score:Int;

	public var coinTypes:Array<Coin.CoinType>;
	public var slotIndices:Array<Int>;
	public var itemIndex:Int;
	public var furtherMoves:Array<CombatAIMove>;
}

class CombatAI
{
	public var fighter:Fighter;
	public var enemy:Fighter;

	public var delay:Float = 0;
	public var noMoreMoves:Bool = false;
	public var logicFailedSkipCurrent:Int = 0;
	public var logicFailedSkipThreshold:Int = 6;

	public var currentMove:CombatAIMove;

	public function new(fighter:Fighter, enemy:Fighter)
	{
		this.fighter = fighter;
		this.enemy = enemy;
	}

	public function update(elapsed:Float)
	{
		delay -= elapsed;
		if (delay <= 0)
		{
			runLogic();
		}
	}

	private function runLogic()
	{
		function onLogicFailed()
		{
			trace("AI logic failed!");
			trace("Tried inserting " + currentMove.coinTypes + " into item #" + currentMove.itemIndex + " in slots " + currentMove.slotIndices
				+ ". Move has parent?: " + (currentMove.parent != null));

			currentMove = null;
			delay = 0.5;

			logicFailedSkipCurrent++;
			if (logicFailedSkipCurrent >= logicFailedSkipThreshold)
			{
				noMoreMoves = true;
				trace("AI got softlocked, skipping this turn...");
			}
		}

		if (currentMove == null)
		{
			var moves = calculateMovesRecursive(fighter.createFromThis(), enemy.createFromThis()).filter(x -> x.score > -500);
			if (moves.length > 0)
			{
				currentMove = pickBestMove(moves);
			}

			if (currentMove != null)
			{
				delay = 0.3;
			}
			else
			{
				noMoreMoves = true;
				delay = 9999.0;
			}
		}
		else
		{
			if (fighter.items.length < currentMove.itemIndex)
			{
				onLogicFailed();
				return;
			}

			var item = fighter.items[currentMove.itemIndex];
			var itemPanel = CombatItemPanel.findForItem(item);

			if (itemPanel == null)
			{
				onLogicFailed();
				return;
			}

			var coinsToUse:Array<Coin> = [];
			var availableCoins = fighter.coinInstances.filter(x -> x.alive && !x.consumed);
			for (coinType in currentMove.coinTypes)
			{
				var foundCoins = availableCoins.filter(x -> x.type == coinType);
				if (foundCoins.length > 0)
				{
					coinsToUse.push(foundCoins[0]);
					availableCoins.remove(foundCoins[0]);
				}
			}

			if (coinsToUse.length <= 0)
			{
				onLogicFailed();
				return;
			}

			for (c in 0...coinsToUse.length)
			{
				var coin = coinsToUse[c];
				var slotIndex = currentMove.slotIndices[c];
				var slot = itemPanel.coinSlots[slotIndex];

				FlxTween.tween(coin, {x: slot.x, y: slot.y}, 0.5, {
					ease: t ->
					{
						return t * t * ((1.1 + 1) * t - 1.1); // This is the backIn function, just with less "bounce"
					},
					onComplete: x ->
					{
						coin.tryInsertIntoSlot(itemPanel, slotIndex);
					},
					startDelay: 0.4 * c
				});
			}

			delay += 0.5 + 0.4 * (coinsToUse.length - 1) + 0.5 + 0.1;

			if (currentMove.furtherMoves.length > 0)
			{
				currentMove = pickBestMove(currentMove.furtherMoves);
			}
			else
			{
				currentMove = null;
			}

			logicFailedSkipCurrent = 0;
		}
	}

	private function pickBestMove(moves:Array<CombatAIMove>)
	{
		var bestMove = moves[0];
		for (move in moves)
		{
			if (move.score > bestMove.score)
				bestMove = move;
		}
		return bestMove;
	}

	private function calculateMovesRecursive(simulationFighter:Fighter, simulationEnemy:Fighter, ?parentMove:CombatAIMove = null):Array<CombatAIMove>
	{
		var moves:Array<CombatAIMove> = [];

		// Go through all items that can be used immediately
		for (itemThatCanBeUsedRightNow in simulationFighter.items.filter(x -> x.canActivate))
		{
			var possibleToUseRightNow = itemThatCanBeUsedRightNow.possibleToUseRightNow(simulationFighter.coinInstances);
			if (possibleToUseRightNow.result == true)
			{
				for (coinSequence in possibleToUseRightNow.coinsToUse)
					if (coinSequence.length > 0)
					{
						var bonusScore = 0;
						var newSimulationFighter = simulationFighter.createFromThis();
						var newSimulationEnemy = simulationEnemy.createFromThis();

						bonusScore += 10; // Add 10 points to this branch each time an item is used

						var newMove:CombatAIMove = {
							parent: parentMove != null ? parentMove : null,
							score: 0,
							coinTypes: [],
							slotIndices: [],
							itemIndex: simulationFighter.items.indexOf(itemThatCanBeUsedRightNow),
							furtherMoves: []
						};

						var itemIndex = simulationFighter.items.indexOf(itemThatCanBeUsedRightNow);
						var itemCopy = newSimulationFighter.items[itemIndex];

						for (i in 0...itemCopy.slots.length)
						{
							if (itemCopy.insertedCoins[i] == null)
							{
								var usedCoin = coinSequence.pop();
								itemCopy.insertedCoins[i] = usedCoin.type;
								newSimulationFighter.coinInstances[simulationFighter.coinInstances.indexOf(usedCoin)].consumed = true;

								// Deduct points for using coins, so that moves with similar outcome but less coin cost are worth more
								bonusScore -= 5;

								newMove.coinTypes.push(usedCoin.type);
								newMove.slotIndices.push(i);
							}
						}

						// Add bonus score for each action that the item does
						bonusScore += itemCopy.activateInSimulation(newSimulationFighter, newSimulationEnemy);

						newMove.score += bonusScore;
						if (newMove.parent != null)
						{
							newMove.parent.score += bonusScore;
						}

						newMove.furtherMoves = calculateMovesRecursive(newSimulationFighter, newSimulationEnemy, newMove);

						moves.push(newMove);
					}
			}
		}

		if (moves.length <= 0)
		{
			// Just try to put leftover coins in fitting slots if no items can be fully activated at this point
			for (c in 0...simulationFighter.coinInstances.length)
				if (simulationFighter.coinInstances[c].alive && !simulationFighter.coinInstances[c].consumed)
				{
					var newSimulationFighter = simulationFighter.createFromThis();
					var coin = newSimulationFighter.coinInstances[c];

					var coinInserted = false;
					for (item in newSimulationFighter.items)
						if (item.canActivate)
						{
							for (i in 0...item.slots.length)
							{
								if (item.slotAcceptsCoin(coin, i))
								{
									coinInserted = true;

									coin.consumed = true;

									var newMove = {
										parent: parentMove != null ? parentMove : null,
										score: 1,
										coinTypes: [coin.type],
										slotIndices: [i],
										itemIndex: newSimulationFighter.items.indexOf(item),
										furtherMoves: []
									};
									if (newMove.parent != null)
									{
										newMove.parent.score += 1;
									}
									newMove.furtherMoves = calculateMovesRecursive(newSimulationFighter, simulationEnemy, parentMove);

									moves.push(newMove);
								}
							}
							if (coinInserted)
								break;
						}
					if (coinInserted)
						continue;
				}
		}

		return moves;
	}
}
