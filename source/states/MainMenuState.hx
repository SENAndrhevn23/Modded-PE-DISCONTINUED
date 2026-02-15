package states;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;

import mikolka.compatibility.ModsHelper;
import mikolka.vslice.freeplay.FreeplayState as NewFreeplayState;

import options.OptionsState;
import states.editors.MasterEditorMenu;

class MainMenuState extends MusicBeatState
{
	// Versions
	public static var psychEngineVersion:String = '1.0';
	public static var pSliceVersion:String = '';
	public static var funkinVersion:String = '0.5.3';
	public static var hrkVersion:String = '0.0.1';

	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var selectedSomethin:Bool = false;

	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		'credits',
		#if !switch 'donate', #end
		'options'
	];

	public function new(isDisplayingRank:Bool = false)
	{
		super();
	}

	override function create()
	{
		Paths.clearUnusedMemory();
		ModsHelper.clearStoredWithoutStickers();

		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Main Menu", null);
		#end

		persistentUpdate = true;
		persistentDraw = true;

		// Background
		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.antialiasing = ClientPrefs.data.antialiasing;
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.color = 0xFFfd719b;
		add(magenta);

		// Menu items
		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var item:FlxSprite = new FlxSprite(0, (i * 140) + offset);
			item.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			item.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			item.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			item.animation.play('idle');
			item.antialiasing = ClientPrefs.data.antialiasing;

			var scr:Float = (optionShit.length - 4) * 0.135;
			if (optionShit.length < 6) scr = 0;
			item.scrollFactor.set(0, scr);

			item.updateHitbox();
			item.screenCenter(X);
			menuItems.add(item);
		}

		// Version text
		var padding:Int = 8;

		var hrkVer:FlxText = new FlxText(padding, FlxG.height - 78 - padding, 0, "Modded PE " + hrkVersion);
		var psliceVer:FlxText = new FlxText(padding, FlxG.height - 58 - padding, 0, "P-Slice " + pSliceVersion);
		var psychVer:FlxText = new FlxText(padding, FlxG.height - 38 - padding, 0, "Psych Engine v" + psychEngineVersion);
		var fnfVer:FlxText = new FlxText(padding, FlxG.height - 18 - padding, 0, "Friday Night Funkin' v" + funkinVersion);

		for (txt in [hrkVer, psliceVer, psychVer, fnfVer])
		{
			txt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT,
				FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			txt.scrollFactor.set();
			txt.antialiasing = ClientPrefs.data.antialiasing;
			add(txt);
		}

		changeItem();

		super.create();
		FlxG.camera.follow(camFollow, null, 0.2);
	}

	override function update(elapsed:Float)
	{
		if (!selectedSomethin)
		{
			if (controls.UI_UP_P) changeItem(-1);
			if (controls.UI_DOWN_P) changeItem(1);

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'), ClientPrefs.data.sfxVolume);
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				selectItem();
			}

			if (#if TOUCH_CONTROLS_ALLOWED touchPad.buttonE.justPressed || #end controls.justPressed('debug_1'))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
		}

		super.update(elapsed);
	}

	function selectItem()
	{
		FlxG.sound.play(Paths.sound('confirmMenu'), ClientPrefs.data.sfxVolume);
		selectedSomethin = true;

		if (ClientPrefs.data.flashing)
			FlxFlicker.flicker(magenta, 1.1, 0.15, false);

		FlxFlicker.flicker(menuItems.members[curSelected], 1, 0.06, false, false, function(_)
		{
			switch (optionShit[curSelected])
			{
				case 'story_mode':
					MusicBeatState.switchState(new StoryMenuState());

				case 'freeplay':
					MusicBeatState.switchState(new FreeplayState());

				#if MODS_ALLOWED
				case 'mods':
					MusicBeatState.switchState(new ModsMenuState());
				#end

				#if ACHIEVEMENTS_ALLOWED
				case 'awards':
					MusicBeatState.switchState(new AchievementsMenuState());
				#end

				case 'credits':
					MusicBeatState.switchState(new CreditsState());

				case 'options':
					MusicBeatState.switchState(new OptionsState());
			}
		});
	}

	function changeItem(huh:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), ClientPrefs.data.sfxVolume);

		menuItems.members[curSelected].animation.play('idle');
		curSelected += huh;

		if (curSelected >= menuItems.length) curSelected = 0;
		if (curSelected < 0) curSelected = menuItems.length - 1;

		menuItems.members[curSelected].animation.play('selected');

		camFollow.setPosition(
			menuItems.members[curSelected].getGraphicMidpoint().x,
			menuItems.members[curSelected].getGraphicMidpoint().y
		);
	}
}
