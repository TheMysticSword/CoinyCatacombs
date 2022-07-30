package;

import CombatState.CombatItemPanel;
import Scripts.GlobalScripts;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

enum CoinType
{
	Heads;
	Tails;
	GoldHeads;
	GoldTails;
}

class Coin extends FlxSprite
{
	public var type(default, set):CoinType;

	function set_type(value:CoinType):CoinType
	{
		var frameIndex = 0;
		switch (value)
		{
			case Heads:
				frameIndex = 0;
			case Tails:
				frameIndex = 1;
			case GoldHeads:
				frameIndex = 2;
			case GoldTails:
				frameIndex = 3;
		}
		frame = frames.getByIndex(frameIndex);

		return type = value;
	}

	public var gold(get, set):Bool;

	function get_gold():Bool
	{
		return type == GoldHeads || type == GoldTails;
	}

	function set_gold(value:Bool):Bool
	{
		if (value)
		{
			if (type == Heads)
				type = GoldHeads;
			if (type == Tails)
				type = GoldTails;
		}
		else
		{
			if (type == GoldHeads)
				type = Heads;
			if (type == GoldTails)
				type = Tails;
		}
		return value;
	}

	public var consumed:Bool = false;

	public var tweenCount:Int = 0;
	public var expectedX:Float;
	public var expectedY:Float;

	public var expectedScale:Float = 1;

	public var grabbed:Bool = false;
	public var grabOffset:FlxPoint;
	public var owner:Fighter;

	public static var anyCoinGrabbed:Bool = false;

	public function new(X:Float, Y:Float, type:CoinType, gold:Bool = false)
	{
		super(X, Y);

		cameras = [Main.uiCamera];

		loadGraphic("assets/images/coin.png", true, 38, 38);
		updateHitbox();

		this.type = type;

		expectedX = X;
		expectedY = Y;

		grabOffset = new FlxPoint();
	}

	public function createFromThis():Coin
	{
		var newCoin = new Coin(x, y, type, gold);
		newCoin.consumed = consumed;
		newCoin.owner = owner;
		return newCoin;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (tweenCount <= 0)
		{
			if (owner.isPlayer)
			{
				if (!grabbed && !anyCoinGrabbed && checkMouseOverlap() && FlxG.mouse.justPressed)
				{
					grabbed = true;
					anyCoinGrabbed = true;
					var mousePos = FlxG.mouse.getPosition();
					grabOffset.x = x - mousePos.x;
					grabOffset.y = y - mousePos.y;
				}
				if (grabbed && FlxG.mouse.justReleased)
				{
					grabbed = false;
					anyCoinGrabbed = false;
					onDropped(new FlxPoint(x + 38 / 2, y + 38 / 2));
				}
			}
		}
		else
		{
			grabbed = false;
		}

		if (grabbed)
		{
			var mousePos = FlxG.mouse.getPosition();
			x = mousePos.x + grabOffset.x;
			y = mousePos.y + grabOffset.y;
		}
	}

	function checkMouseOverlap():Bool
	{
		for (camera in cameras)
		{
			if (overlapsPoint(FlxG.mouse.getWorldPosition(camera, Main.point), true, camera))
			{
				return true;
			}
		}
		return false;
	}

	public function onDropped(dropPoint:FlxPoint)
	{
		for (itemPanel in CombatItemPanel.instances)
		{
			if (itemPanel != null && itemPanel.alive && itemPanel.item != null && itemPanel.item.owner == owner)
			{
				if (itemPanel.overlapsPoint(dropPoint))
				{
					for (i in 0...itemPanel.item.slots.length)
					{
						if (itemPanel.item.slotAcceptsCoin(this, i, true))
						{
							tweenCount++;
							var slot = itemPanel.coinSlots[i];
							FlxTween.tween(this, {x: slot.x, y: slot.y}, 0.12, {
								ease: FlxEase.cubeOut,
								onComplete: x ->
								{
									tweenCount--;
									tryInsertIntoSlot(itemPanel, i);
								}
							});
							return;
						}
					}
				}
			}
		}
	}

	public function tryInsertIntoSlot(itemPanel:CombatItemPanel, slotIndex:Int)
	{
		if (itemPanel == null
			|| itemPanel.item == null
			|| itemPanel.item.insertedCoins.length <= slotIndex
			|| !itemPanel.item.slotAcceptsCoin(this, slotIndex, true))
			return;

		consume(0.03);
		itemPanel.item.insertedCoins[slotIndex] = type;
		itemPanel.item.onCoinInserted();

		FlxG.sound.play("assets/sounds/slot" + FlxG.random.int(1, 3) + ".wav", 0.11);
	}

	public function consume(duration:Float = 0.06)
	{
		consumed = true;
		FlxTween.tween(this, {alpha: 0}, duration);

		tweenCount++;
		FlxTween.num(0, 1, duration, {
			onComplete: x ->
			{
				tweenCount--;
				kill();
			}
		});
	}

	public function reflip(delay:Float = 0)
	{
		var duration = 0.3;

		FlxG.sound.play("assets/sounds/clink" + FlxG.random.int(1, 4) + ".wav", 0.12);
		bump(20, delay, duration);
		spin(duration, delay, 2);
		FlxTween.num(0, 1, duration / 2, {
			startDelay: delay,
			onComplete: x ->
			{
				if (alive)
				{
					type = FlxG.random.getObject(!gold ? [Heads, Tails] : [GoldHeads, GoldTails]);
				}
			}
		});

		tweenCount++;
		FlxTween.num(0, 1, duration, {startDelay: delay, onComplete: x -> tweenCount--});
	}

	public function vanish(delay:Float = 0)
	{
		tweenCount++;
		var duration = 0.3;
		spin(duration * 2, delay, 2);
		FlxTween.num(0, 1, duration, {
			onComplete: x ->
			{
				GlobalScripts.shakeCamera(0.23);
				GlobalScripts.emitParticleBurst(this.x + 38 / 2, this.y + 38 / 2, "assets/images/particle_star.png", 7);
				FlxG.sound.play("assets/sounds/clink" + FlxG.random.int(1, 4) + ".wav", 0.12);
				tweenCount--;
				kill();
			},
			startDelay: delay
		});
	}

	public function makeGold(delay:Float = 0)
	{
		var duration = 0.3;

		bump(20, delay, duration);
		spin(duration, delay, 2);
		FlxTween.num(0, 1, duration / 2, {
			startDelay: delay,
			onComplete: x ->
			{
				if (alive)
				{
					switch (type)
					{
						case Heads:
							type = GoldHeads;
						case Tails:
							type = GoldTails;
						default:
					}
				}
			}
		});

		tweenCount++;
		FlxTween.num(0, 1, duration, {startDelay: delay, onComplete: x -> tweenCount--});
	}

	public function bump(offset:Float = 20, delay:Float = 0, duration:Float = 0.2, midAirTime:Float = 0)
	{
		var floatUpTime = (duration - midAirTime) / 2;
		FlxTween.tween(this, {y: y - offset}, floatUpTime, {ease: FlxEase.quadOut, startDelay: delay});
		y -= offset;
		FlxTween.tween(this, {y: y + offset}, floatUpTime, {ease: FlxEase.sineIn, startDelay: delay + floatUpTime + midAirTime});
		y += offset;

		tweenCount++;
		FlxTween.num(0, 1, duration, {startDelay: delay, onComplete: x -> tweenCount--});
	}

	public function spin(duration:Float = 0.3, delay:Float = 0, spins:Int = 1)
	{
		var halfSpinDuration = duration / (spins * 2);
		for (i in 0...spins)
		{
			FlxTween.tween(this, {"scale.x": -expectedScale}, halfSpinDuration, {ease: FlxEase.linear, startDelay: delay + i * halfSpinDuration * 2});
			FlxTween.tween(this, {"scale.x": expectedScale}, halfSpinDuration,
				{ease: FlxEase.linear, startDelay: delay + i * halfSpinDuration * 2 + halfSpinDuration});
		}

		tweenCount++;
		FlxTween.num(0, 1, duration, {startDelay: delay, onComplete: x -> tweenCount--});
	}
}
