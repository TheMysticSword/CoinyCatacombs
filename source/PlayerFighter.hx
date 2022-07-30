package;

import CombatState.CombatFighterPanel;
import Scripts.GlobalScripts;
import flixel.FlxG;
import flixel.util.FlxColor;

class PlayerFighter extends Fighter
{
	public var skill:Skill;
	public var limitBreakCharge:Int = 0;
	public var limitBreakRequirement:Int = 1;

	public var maxHeadsThisTurn:Int = 0;
	public var currentHeadsThisTurn:Int = 0;
	public var maxTailsThisTurn:Int = 0;
	public var currentTailsThisTurn:Int = 0;
	public var bust:Bool = false;
	public var jackpot:Bool = false;

	public function new()
	{
		super();
		isPlayer = true;
		asPlayer = this;
		skill = new Skill();
		skill.makeFromTemplate("REFLIP_REMAINING_COINS");

		updateLimitBreakRequirement();
	}

	override function createFromThis():Fighter
	{
		var newFighter = super.createFromThis();
		newFighter.asPlayer.limitBreakCharge = limitBreakCharge;
		newFighter.asPlayer.limitBreakRequirement = limitBreakRequirement;
		return newFighter;
	}

	public function updateLimitBreakRequirement()
	{
		limitBreakRequirement = Std.int(maxhp / 3);
	}

	override function beforeStartTurn()
	{
		super.beforeStartTurn();

		if (skill != null)
		{
			if (skill.id == "COIN_TOSS")
			{
				bust = false;
				jackpot = false;

				var halfCoins = Math.floor(coins / 2);
				var extraCoins = coins - halfCoins * 2;
				maxHeadsThisTurn = halfCoins + ((CombatState.instance.turnNumber % 2) == 1 ? extraCoins : 0);
				maxTailsThisTurn = halfCoins + ((CombatState.instance.turnNumber % 2) == 0 ? extraCoins : 0);
			}
		}

		if (!skill.reuseable)
		{
			skill.remainingUses = skill.maxUses;
		}

		runForPanel(x -> x.refreshSkillButton());
	}

	override function onStartTurn()
	{
		super.onStartTurn();
	}

	override function tossInitialCoins()
	{
		if (skill != null && skill.id == "COIN_TOSS")
			return;
		super.tossInitialCoins();
	}

	public function onSkillUsed():Bool
	{
		if (skill == null)
			return false;

		if (skill.remainingUses <= 0 && !skill.reuseable)
			return false;

		if (skill.limitBreak && limitBreakCharge < limitBreakRequirement)
			return false;

		switch (skill.id)
		{
			case "COIN_TOSS":
				if (bust)
					return false;

				var givenCoinInfo = Scripts.CombatScripts.giveAnyCoin(this);
				switch (givenCoinInfo.type)
				{
					case Heads:
						currentHeadsThisTurn++;
					case Tails:
						currentTailsThisTurn++;
					default:
				}

				checkCoinTossLimit();
			default:
				skill.activate(this, (CombatState.instance != null && CombatState.instance.exists) ? CombatState.instance.enemy : null);
		}

		if (!skill.reuseable && skill.remainingUses > 0)
			skill.remainingUses--;

		if (skill.limitBreak)
		{
			if (skill.reuseable || skill.remainingUses <= 0)
			{
				limitBreakCharge = 0;
				updateLimitBreakRequirement();
			}
		}

		runForPanel(x -> x.updateSkillButton());

		return true;
	}

	public function checkCoinTossLimit()
	{
		if (skill != null && skill.id == "COIN_TOSS")
		{
			if (currentHeadsThisTurn > maxHeadsThisTurn || currentTailsThisTurn > maxTailsThisTurn)
			{
				bust = true;

				GlobalScripts.shakeCamera();
				GlobalScripts.flashCamera("0x2fffffff", 0.12);
			}
			if (currentHeadsThisTurn == maxHeadsThisTurn && currentTailsThisTurn == maxTailsThisTurn)
			{
				jackpot = true;

				GlobalScripts.flashCamera("0x2ffff23f", 0.9);

				Scripts.CombatScripts.giveHeads(this, maxHeadsThisTurn, true);
				Scripts.CombatScripts.giveTails(this, maxTailsThisTurn, true);
			}
		}
	}

	override function makeFromTemplate(id:String)
	{
		super.makeFromTemplate(id);
		updateLimitBreakRequirement();
	}
}
