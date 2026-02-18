package states;

import cpp.vm.Gc;
import backend.WeekData;
import backend.Highscore;
import backend.Song;

import objects.HealthIcon;
import objects.MusicPlayer;

import options.GameplayChangersSubstate;
import substates.ResetScoreSubState;

import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;

import openfl.utils.Assets;
// removed: import flixel.addons.ui.FlxUIInputText;
import flixel.ui.FlxButton;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxSprite;

import haxe.Json;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	public static var fromResultState:Bool = false;

	var selector:FlxText;
	private static var curSelected:Int = 0;
	var lerpSelected:Float = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = Difficulty.getDefault();

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Float = 0;
	var lerpRating:Float = 0;
	var intendedScore:Float = 0;
	var intendedRating:Float = 0;

	// use FlxGroup instead of FlxTypedGroup
	private var grpSongs:FlxGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int;

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	var bottomString:String;
	var bottomText:FlxText;
	var bottomBG:FlxSprite;

	var player:MusicPlayer;
	var interpolate = CoolUtil.interpolate;

	// --- Search UI (replaced FlxUIInputText with FlxText fallback) ---
	var songSearchText:FlxText;
	var buttonTop:FlxButton;
	var searchTextLabel:FlxText;
	// --------------------------------------------

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		
		if (ClientPrefs.data.disableGC) {
			MemoryUtil.compact();
			MemoryUtil.disable();
		}
		
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Old Freeplay Menus", null);
		#end

		if(WeekData.weeksList.length < 1)
		{
			FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			MusicBeatState.switchState(new states.ErrorState("NO WEEKS ADDED FOR FREEPLAY\n\nPress ACCEPT to go to the Week Editor Menu.\nPress BACK to return to Main Menu.",
				function() MusicBeatState.switchState(new states.editors.WeekEditorState()),
				function() MusicBeatState.switchState(new states.MainMenuState())));
			return;
		}

		for (i in 0...WeekData.weeksList.length)
		{
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
			if(Main.isConsoleAvailable) Sys.stdout().writeString('\x1b[0GLoading Weeklist (${i+1}/${WeekData.weeksList.length})');
		}
		Sys.print("\n");
		Mods.loadTopMod();

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();

		// use FlxGroup
		grpSongs = new FlxGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
			songText.targetY = i;
			grpSongs.add(songText);

			songText.scaleX = Math.min(1, 980 / songText.width);
			songText.snapToPosition();

			Mods.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;
			
			// performance: lazy visibility (keep your original optimization)
			songText.visible = songText.active = songText.isMenuItem = false;
			icon.visible = icon.active = false;

			iconArray.push(icon);
			add(icon);

			if(Main.isConsoleAvailable) Sys.stdout().writeString('\x1b[0GLoading Song (${i+1}/${songs.length})');
		}
		Sys.println('\nLoading Done');
		WeekData.setDirectoryFromWeek();

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		scoreText.antialiasing = ClientPrefs.data.antialiasing;

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		diffText.antialiasing = ClientPrefs.data.antialiasing;
		add(diffText);
		add(scoreText);


		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		missingText.antialiasing = ClientPrefs.data.antialiasing;
		add(missingText);

		// ensure current selection valid
		if(curSelected >= songs.length) curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;
		lerpSelected = curSelected;

		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

		bottomBG = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		bottomBG.alpha = 0.6;
		add(bottomBG);

		var leText:String = Language.getPhrase("freeplay_tip", "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.");
		bottomString = leText;
		var size:Int = 16;
		bottomText = new FlxText(bottomBG.x, bottomBG.y + 4, FlxG.width, leText, size);
		bottomText.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, CENTER);
		bottomText.scrollFactor.set();
		bottomText.antialiasing = ClientPrefs.data.antialiasing;
		add(bottomText);
		
		player = new MusicPlayer(this);
		add(player);

		// --- Search UI placement (FlxText fallback) ---
		songSearchText = new FlxText(0, scoreBG.y + scoreBG.height + 5, 500, "");
		songSearchText.x = FlxG.width - Std.int(songSearchText.width) - 10;
		add(songSearchText);

		buttonTop = new FlxButton(0, songSearchText.y + Std.int(songSearchText.height) + 5, "Search", function() {
			checkForSongsThatMatch(songSearchText.text);
		});
		buttonTop.setGraphicSize(Std.int(songSearchText.width), 40);
		buttonTop.updateHitbox();
		buttonTop.label.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.BLACK, RIGHT);
		buttonTop.x = FlxG.width - buttonTop.width - 10;
		add(buttonTop);

		searchTextLabel = new FlxText(Std.int(songSearchText.x - 90), songSearchText.y + 2, 80, "Search", 18);
		searchTextLabel.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE);
		searchTextLabel.scrollFactor.set();
		add(searchTextLabel);
		// ---------------------------------------------------

		changeSelection();
		updateTexts();
		super.create();
		
		#if debug trace(fromResultState); #end
		if (fromResultState && !ClientPrefs.data.vsliceFreeplay && (!FlxG.sound.music.playing || FlxG.sound.music.volume == 0)) {
			FlxG.sound.playMusic(Paths.music('freakyMenu'), ClientPrefs.data.bgmVolume);
			fromResultState = false;
		}
		
		#if TOUCH_CONTROLS_ALLOWED
		addTouchPad('LEFT_FULL', 'A_B_X_Y');
		#end
		
		if (ClientPrefs.data.disableGC && !MemoryUtil.isGcEnabled) {
			MemoryUtil.enable();
			MemoryUtil.collect(true);
		}
	}

	...
	// rest of file unchanged (update/regenerate/regenList/etc.)
	// just make sure references to songSearchText.hasFocus (if any) are removed or replaced
}
