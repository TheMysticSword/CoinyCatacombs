package;

import Coin.CoinType;
import CombatState.CombatFighterPanel;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.effects.particles.FlxEmitter.FlxTypedEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

typedef RunScriptReturnValue =
{
	public var ranScript:Bool;
	public var returnValue:Dynamic;
	public var variables:Map<String, Dynamic>;
}

class ScriptParsing
{
	public static var parser:hscript.Parser;

	public static function init()
	{
		parser = new hscript.Parser();
	}

	public static function runScript(script:String, variables:Map<String, Dynamic>):RunScriptReturnValue
	{
		if (script.length <= 0)
			return {ranScript: false, returnValue: null, variables: []};

		var program = parser.parseString(script);
		var interp = new hscript.Interp();
		interp.variables.set("Math", FlxMath);
		interp.variables.set("GlobalScripts", Scripts.GlobalScripts);
		interp.variables.set("CombatScripts", Scripts.CombatScripts);
		interp.variables.set("CoinType", Coin.CoinType);
		interp.variables.set("CoinSlot", Item.CoinSlot);
		interp.variables.set("STATUSMAX", StatusEffect.statusMax);
		interp.variables.set("simulation", CombatScripts.simulationMode);
		if (CombatState.instance != null && CombatState.instance.exists)
		{
			interp.variables.set("turn", CombatState.instance.turnNumber);
		}
		for (kvp in variables.keyValueIterator())
		{
			interp.variables.set(kvp.key, kvp.value);
		}
		var result = interp.execute(program);
		return {
			ranScript: true,
			returnValue: result,
			variables: interp.variables
		};
	}
}

class GlobalScripts
{
	public static function flashCamera(color:String, duration:Float)
	{
		if (CombatScripts.simulationMode)
			return;
		Main.fxCamera.flash(FlxColor.fromString(color), duration);
	}

	public static function shakeCamera(intensity:Float = 1, duration:Float = 0.1)
	{
		if (CombatScripts.simulationMode)
			return;
		FlxG.camera.shake(intensity / 100, duration);
	}

	public static function playSound(soundName:String, volume:Float = 1.0)
	{
		if (CombatScripts.simulationMode)
			return;
		FlxG.sound.play("assets/sounds/" + soundName, volume * 0.2);
	}

	public static var particleBurstEmitter(get, default):FlxTypedEmitter<FlxParticle>;

	static function get_particleBurstEmitter():FlxTypedEmitter<FlxParticle>
	{
		if (particleBurstEmitter == null || !particleBurstEmitter.alive)
		{
			particleBurstEmitter = new FlxTypedEmitter<FlxParticle>();
			FlxG.state.add(particleBurstEmitter);
			particleBurstEmitter.cameras = [Main.fxCamera];

			var size = 24 / 128;
			particleBurstEmitter.scale.active = true;
			particleBurstEmitter.scale.set(size, size, size, size, 0, 0, 0, 0);

			particleBurstEmitter.launchMode = CIRCLE;
			particleBurstEmitter.launchAngle.set(-90 + 50, -90 - 50);

			var gravity = 800;
			particleBurstEmitter.acceleration.active = true;
			particleBurstEmitter.acceleration.set(0, gravity, 0, gravity, 0, gravity, 0, gravity);

			particleBurstEmitter.angle.active = true;
			particleBurstEmitter.angle.set(0, 360, 0, 720);

			particleBurstEmitter.speed.set(140, 400);

			particleBurstEmitter.lifespan.set(0.3, 0.6);
		}
		return particleBurstEmitter;
	}

	public static function emitParticleBurst(X:Float, Y:Float, image:String, amount:Int)
	{
		if (CombatScripts.simulationMode)
			return;

		particleBurstEmitter.setPosition(X, Y);
		particleBurstEmitter.loadParticles(image, amount);
		particleBurstEmitter.start(true, 0, amount);
	}

	public static function chance(percent:Float):Bool
	{
		return FlxG.random.bool(percent);
	}

	public static function random(array:Array<Dynamic>):Dynamic
	{
		return array[FlxG.random.int(0, array.length - 1)];
	}

	public static function getColour(colourString:String):FlxColor
	{
		switch (colourString)
		{
			case "RED":
				return FlxColor.fromString("0xFF3419");
			case "ORANGE":
				return FlxColor.fromString("0xFF7F35");
			case "YELLOW" | "GOLD":
				return FlxColor.fromString("0xFFD232");
			case "GREEN":
				return FlxColor.fromString("0x6DFF4C");
			case "BLUE":
				return FlxColor.fromString("0x38C3FF");
			case "PURPLE":
				return FlxColor.fromString("0x9C6BFF");
			case "PINK":
				return FlxColor.fromString("0xE97FFF");
			case "BRIGHTPINK":
				return FlxColor.fromString("0xFF42A0");
			case "SILVER":
				return FlxColor.fromString("0xD2E0E0");
			case "BLACK":
				return FlxColor.fromString("0x000000");
			default:
				return FlxColor.fromString(colourString);
		}
	}

	public static function checkMouseOverlap(object:FlxObject):Bool
	{
		for (camera in object.cameras)
		{
			if (object.overlapsPoint(FlxG.mouse.getWorldPosition(camera, Main.point), true, camera))
			{
				return true;
			}
		}
		return false;
	}
}

typedef GiveAnyCoinsReturnValue =
{
	public var coins:Array<Coin>;
	public var types:Array<CoinType>;
}

typedef GiveAnyCoinReturnValue =
{
	public var coin:Coin;
	public var type:CoinType;
}

class CombatScripts
{
	public static var simulationScore:Int = 0;
	public static var simulationMode:Bool = false;
	public static var simulationEnemy:Fighter;

	public static function attack(source:Fighter, target:Fighter, damage:Int)
	{
		if (target == null)
			return;

		if (damage > 0)
		{
			var allStatuses:Array<StatusEffect> = target.statuses;
			if (source != null && source != target)
				allStatuses = allStatuses.concat(source.statuses);

			var attackTarget = target;
			var attackInflictor = source;

			for (status in allStatuses)
			{
				var result = status.runScript(status.owner, getEnemy(status.owner), status.script_modifyDamage,
					["attackTarget" => target, "attackInflictor" => source, "damage" => damage]);
				if (result.ranScript)
				{
					damage = result.variables["damage"];
					attackTarget = result.variables["attackTarget"];
					attackInflictor = result.variables["attackInflictor"];
				}
			}

			target = attackTarget;
			source = attackInflictor;

			if (target == null)
			{
				return;
			}

			target.hp -= damage;
			if (CombatState.instance != null && CombatState.instance.exists)
			{
				if (target.hp <= 0)
				{
					target.hp = 0;
					if (!simulationMode)
						CombatState.instance.triggerLoss(target);
				}
			}
			else
			{
				if (target.hp < 1)
					target.hp = 1;
			}

			if (target.isPlayer)
			{
				target.asPlayer.limitBreakCharge += damage;
				target.runForPanel(x -> x.updateSkillButton());
			}

			if (!simulationMode)
			{
				var hitType = "normal";
				if (damage <= 2)
					hitType = "small";
				if (damage >= 7)
					hitType = "huge";
				FlxG.sound.play("assets/sounds/hit_" + hitType + ".wav", 0.2);

				FlxG.camera.shake(0.007, 0.1);
				target.runForPanel(x -> x.shakeHPBar());
				if (target.isPlayer && OverworldState.instance != null && OverworldState.instance.exists)
					OverworldState.instance.updateHPBar();

				for (status in allStatuses)
				{
					status.runScript(source, target, status.script_onDamage, ["attackTarget" => target, "attackInflictor" => source, "damage" => damage]);
				}
			}
			else
			{
				if (target.isPlayer)
				{
					simulationScore += damage * 100;
					if (target.hp <= 0)
						simulationScore += 1000000;
				}
				else
				{
					simulationScore -= damage * 10;
					if (target.hp <= 0)
						simulationScore -= 1000000;
				}
			}
		}
		else
		{
			var healing = FlxMath.minInt(-damage, target.maxhp - target.hp);
			if (healing > 0)
			{
				target.hp += healing;

				if (!simulationMode)
				{
					FlxG.sound.play("assets/sounds/heal.wav", 0.2);

					target.runForPanel(x -> x.shakeHPBar(2));
					if (target.isPlayer && OverworldState.instance != null && OverworldState.instance.exists)
						OverworldState.instance.updateHPBar();
				}
				else
				{
					if (source != target)
					{
						simulationScore -= healing * 100;
					}
					else
					{
						simulationScore += healing * 1;
					}
				}
			}
		}
	}

	public static function giveCoins(target:Fighter, coins:Array<CoinType>):Array<Coin>
	{
		if (CombatState.instance != null && CombatState.instance.exists && CombatState.instance.currentTurnFighter == target)
		{
			var coinNumber = 0;
			for (coinType in coins)
			{
				var newCoinX:Float = 20;
				var newCoinY:Float = 20;
				if (!simulationMode)
				{
					var combatFighterPanel = CombatFighterPanel.findForFighter(target);
					newCoinX = target.isPlayer ? 20 : 1280 - 38 - 20;
					newCoinY = target.isPlayer ? combatFighterPanel.y - 60 : combatFighterPanel.height + 22;

					FlxG.sound.play("assets/sounds/coin_roll" + FlxG.random.int(1, 3) + ".wav", 0.1);
				}
				else
				{
					simulationScore += 1;
				}

				var newCoin = new Coin(newCoinX, newCoinY, coinType);
				newCoin.owner = target;
				target.coinInstances.push(newCoin);

				if (!simulationMode)
				{
					CombatState.instance.add(newCoin);
					CombatState.instance.forEachOfType(Coin, otherCoin ->
					{
						if (otherCoin == newCoin || !otherCoin.alive || !otherCoin.exists)
							return;

						var oldX = otherCoin.x;
						var oldY = otherCoin.y;
						if (otherCoin.tweenCount > 0)
						{
							otherCoin.x = otherCoin.expectedX;
							otherCoin.y = otherCoin.expectedY;
						}

						if (newCoin.overlaps(otherCoin))
						{
							newCoin.x += (38 + 4) * (target.isPlayer ? 1 : -1);
							if (newCoin.x >= FlxG.width - 40)
							{
								newCoin.x = newCoinX;
								newCoin.y += (38 + 4) * (target.isPlayer ? -1 : 1);
							}
						}

						if (otherCoin.tweenCount > 0)
						{
							otherCoin.x = oldX;
							otherCoin.y = oldY;
						}
					});
					newCoin.expectedX = newCoin.x;
					newCoin.expectedY = newCoin.y;

					var oldY = newCoin.y;
					newCoin.y = target.isPlayer ? FlxG.height + 38 : -38;
					newCoin.tweenCount++;

					var floatTime = 0.3;
					var floatDelay = 0.14 * coinNumber;
					FlxTween.tween(newCoin, {y: oldY}, floatTime, {ease: FlxEase.cubeOut, onComplete: x -> newCoin.tweenCount--, startDelay: floatDelay});
					newCoin.spin(floatTime, floatDelay);

					if (!target.isPlayer)
					{
						CombatState.instance.enemyAI.delay += floatDelay;
					}
				}

				coinNumber++;
			}
		}
		return [];
	}

	public static function giveAnyCoins(target:Fighter, amount:Int = 1, gold:Bool = false):GiveAnyCoinsReturnValue
	{
		var coins:Array<CoinType> = [];
		for (i in 0...amount)
			coins.push(FlxG.random.getObject(gold ? [GoldHeads, GoldTails] : [Heads, Tails]));
		var givenCoins = giveCoins(target, coins);
		return {
			coins: givenCoins,
			types: coins
		};
	}

	public static function giveAnyCoin(target:Fighter, gold:Bool = false):GiveAnyCoinReturnValue
	{
		var givenCoins = giveAnyCoins(target, 1, gold);
		return {
			coin: givenCoins.coins.length > 0 ? givenCoins.coins[0] : null,
			type: givenCoins.types[0]
		};
	}

	public static function giveHeads(target:Fighter, amount:Int = 1, gold:Bool = false)
	{
		var coins:Array<CoinType> = [];
		for (i in 0...amount)
			coins.push(gold ? GoldHeads : Heads);
		giveCoins(target, coins);
	}

	public static function giveTails(target:Fighter, amount:Int = 1, gold:Bool = false)
	{
		var coins:Array<CoinType> = [];
		for (i in 0...amount)
			coins.push(gold ? GoldTails : Tails);
		giveCoins(target, coins);
	}

	public static function delayAI(delay:Float)
	{
		if (!simulationMode && CombatState.instance != null && CombatState.instance.exists)
		{
			CombatState.instance.enemyAI.delay += delay;
		}
	}

	public static function simulationBonus(bonusScore:Int)
	{
		if (simulationMode)
		{
			simulationScore += bonusScore;
		}
	}

	public static function getEnemy(self:Fighter):Fighter
	{
		if (simulationMode)
			return simulationEnemy;

		var enemy:Fighter = null;
		if (CombatState.instance != null && CombatState.instance.exists)
		{
			enemy = CombatState.instance.enemy;
			if (self != null && !self.isPlayer)
				enemy = Main.player;
		}
		return enemy;
	}
}
