package options;

class GameplaySettingsSubState extends BaseOptionsMenu
{
	var pastValue:Float = 0;
	var timerMethod:Option;
	var bgmVolume:Option;
	var sfxVolume:Option;
	var hitVolume:Option;
	var rateHold:Float;
	var stepRate:Option;
	var ghostRate:Option;
	public static final defaultBPM:Float = 15;

	public function new()
	{
		title = Language.getPhrase('gameplay_menu', 'Gameplay Settings');
		rpcTitle = 'Gameplay Settings Menu'; //for Discord Rich Presence

		//I'd suggest using "Downscroll" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Downscroll', //Name
			'If checked, notes go Down instead of Up, simple enough.', //Description
			'downScroll', //Save data variable name
			BOOL); //Variable type
		addOption(option);

		var option:Option = new Option('Middlescroll',
			'If checked, your notes get centered.',
			'middleScroll',
			BOOL);
		addOption(option);

		var option:Option = new Option('Opponent Notes',
			'If unchecked, opponent notes get hidden.',
			'opponentStrums',
			BOOL);
		addOption(option);

		var option:Option = new Option('Over Health',
			'If checked, health goes beyond 100%, but it returns to 100% immedietaly after 1 frame.',
			'overHealth',
			BOOL);
		addOption(option);

		var option:Option = new Option('Health Drain',
			'If checked, opponent drains your health when they hit a note.\n(Conflicts with other health drain scripts)',
			'healthDrain',
			BOOL);
		addOption(option);

		var option:Option = new Option('Health Drain - Accurate',
			'If checked, health drain will work for skipped notes, but it will take high CPU loads.',
			'drainAccurated',
			BOOL);
		addOption(option);

		var option:Option = new Option('Update Count of stepHit',
			'In this setting, you can set the stepHit to be accurate up to ${
				ClientPrefs.data.updateStepLimit != 0 ?
				Std.string(ClientPrefs.data.updateStepLimit * defaultBPM * ClientPrefs.data.framerate) : "Infinite"
			} BPM.',
			'updateStepLimit',
			INT);
		option.scrollSpeed = 20;
		option.minValue = 0;
		option.maxValue = 1000;
		option.changeValue = 1;
		option.decimals = 0;
		option.onChange = onStepUpdateRate;
		addOption(option);
		stepRate = option;

		var option:Option = new Option('Ghost Tapping',
			"If checked, you won't get misses from pressing keys\nwhile there are no notes able to be hit.",
			'ghostTapping',
			BOOL);
		addOption(option);

		var option:Option = new Option('Remove Overlapped Notes',
			"If checked, the game will remove notes which are hidden behind the others.\nRange is controlled by the option below.",
			'skipGhostNotes',
			BOOL);
		addOption(option);

		var option:Option = new Option(' - Threshold',
			"Threshold of the option above.\nYou can set it in millisecond.",
			'ghostRange',
			FLOAT);
		option.displayFormat = '%v ms';
		option.scrollSpeed = 0.1;
		option.minValue = 0.001;
		option.maxValue = 1000;
		option.changeValue = 0.001;
		option.decimals = 3;
		addOption(option);
		option.onChange = onRangeUpdateRate;
		ghostRate = option;
		
		var option:Option = new Option('Auto Pause',
			"If checked, the game automatically pauses if the screen isn't on focus.",
			'autoPause',
			BOOL);
		addOption(option);
		option.onChange = onChangeAutoPause;
		
		#if CHECK_FOR_UPDATES
		var option:Option = new Option('Check for Updates',
			'On Release builds, turn this on to check for updates when you start the game.',
			'checkForUpdates',
			BOOL);
		addOption(option);
		#end

		// It may conflict on my feature
		// var option:Option = new Option('Pop Up Score',
		// 	"If unchecked, hitting notes won't make \"sick\", \"good\".. and combo popups\n(Useful for low end " + Main.platform + ").",
		// 	'popUpRating',
		// 	BOOL);
		// addOption(option);

		var option:Option = new Option('Disable Reset Button',
			"If checked, pressing Reset won't do anything.",
			'noReset',
			BOOL);
		addOption(option);

		var option:Option = new Option('Accurate Song Position',
			"If checked, songPosition supports microSeconds. Unsupported for very old CPUs",
			'nanoPosition',
			BOOL);
		option.onChange = onChangeCounterMethod;
		timerMethod = option;
		addOption(option);

		var option:Option = new Option('BGM/Music Volume',
			"I wonder why doesn't this option exists in official build? xd",
			'bgmVolume',
			PERCENT);
		addOption(option);
		option.scrollSpeed = 1;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.01;
		option.decimals = 2;
		option.onChange = onChangebgmVolume;
		bgmVolume = option;

		var option:Option = new Option('SE/SFX Volume',
			"I wonder why doesn't this option exists in official build? xd",
			'sfxVolume',
			PERCENT);
		addOption(option);
		option.scrollSpeed = 1;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.01;
		option.decimals = 2;
		option.onChange = onChangeSfxVolume;
		sfxVolume = option;
		
		var option:Option = new Option('Hitsound Volume',
			'Funny notes do a \"Tick!\" sound when you hit them.',
			'hitsoundVolume',
			PERCENT);
		addOption(option);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		option.onChange = onChangeHitsoundVolume;
		hitVolume = option;

		var option:Option = new Option('Vibrations',
			"If checked, your device will vibrate at some cases.",
			'vibrating',
			BOOL);
		addOption(option);
		option.onChange = onChangeVibration;

		var option:Option = new Option('Rating Offset',
			'Changes how late/early you have to hit for a "Sick!"\nHigher values mean you have to hit later.',
			'ratingOffset',
			INT);
		option.displayFormat = '%vms';
		option.scrollSpeed = 20;
		option.minValue = -30;
		option.maxValue = 30;
		addOption(option);

		var option:Option = new Option('Sick! Hit Window',
			'Changes the amount of time you have\nfor hitting a "Sick!" in milliseconds.',
			'sickWindow',
			INT);
		option.displayFormat = '%vms';
		option.scrollSpeed = 15;
		option.minValue = 15;
		option.maxValue = 45;
		addOption(option);

		var option:Option = new Option('Good Hit Window',
			'Changes the amount of time you have\nfor hitting a "Good" in milliseconds.',
			'goodWindow',
			INT);
		option.displayFormat = '%vms';
		option.scrollSpeed = 30;
		option.minValue = 15;
		option.maxValue = 90;
		addOption(option);

		var option:Option = new Option('Bad Hit Window',
			'Changes the amount of time you have\nfor hitting a "Bad" in milliseconds.',
			'badWindow',
			INT);
		option.displayFormat = '%vms';
		option.scrollSpeed = 60;
		option.minValue = 15;
		option.maxValue = 135;
		addOption(option);

		var option:Option = new Option('Safe Frames',
			'Changes how many frames you have for\nhitting a note earlier or late.',
			'safeFrames',
			FLOAT);
		option.scrollSpeed = 5;
		option.minValue = 2;
		option.maxValue = 10;
		option.changeValue = 0.1;
		addOption(option);

		#if desktop
		var option:Option = new Option('Full Screen shortcut on F11',
			"If checked, the F11 key will toggle full screen, just like Alt+Enter.\nIt's for avoiding other processing interruptions.",
			'f11Shortcut',
			'bool');
		addOption(option);
		#end

		// var option:Option = new Option('Sustains as One Note',
		// 	"If checked, Hold Notes can't be pressed if you miss,\nand count as a single Hit/Miss.\nUncheck this if you prefer the old Input System.",
		// 	'guitarHeroSustains',
		// 	BOOL);
		// addOption(option);

		super();
	}

	function onStepUpdateRate(){
		stepRate.scrollSpeed = interpolate(20.0, 1000.0, (holdTime - 0.5) / 3.0, 3.0);
		descText.text = stepRate.description = 
		'In this settings, you can set the stepHit to be accurate up to ${
			stepRate.getValue() != 0 ?
			Std.string(stepRate.getValue() * defaultBPM * ClientPrefs.data.framerate) : "Infinite"
		} BPM.';
	}

	function onRangeUpdateRate(){
		ghostRate.scrollSpeed = interpolate(0.1, 1000.0, (holdTime - 0.5) / 8.0, 5.0);
	}

	function onChangebgmVolume(){
		if(pastValue != bgmVolume.getValue()) {
			FlxG.sound.music.volume = pastValue = bgmVolume.getValue();
		}
	}

	function onChangeSfxVolume(){
		if(pastValue != sfxVolume.getValue()) {
			if(holdTime - rateHold > 0.05 || holdTime <= 0.5) {
				rateHold = holdTime;
				FlxG.sound.play(Paths.sound('scrollMenu'), ClientPrefs.data.hitsoundVolume);
			}
			pastValue = sfxVolume.getValue();
		}
	}

	function onChangeHitsoundVolume(){
		if(pastValue != hitVolume.getValue()) {
			if(holdTime - rateHold > 0.05 || holdTime <= 0.5) {
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.data.hitsoundVolume);
				rateHold = holdTime;
			}
			pastValue = hitVolume.getValue();
		}
	}

	function onChangeCounterMethod() {
		if (timerMethod.getValue() == true) {
			var check:Float = CoolUtil.getNanoTime();
			if (check == 0) {
				CoolUtil.showPopUp("This device doesn't support this feature.", "Error");
				FlxG.sound.play(Paths.sound('cancelMenu'), ClientPrefs.data.sfxVolume);
				timerMethod.setValue(false);
			}
		}
	}

	function onChangeAutoPause()
		FlxG.autoPause = ClientPrefs.data.autoPause;

	function onChangeVibration()
	{
		if(ClientPrefs.data.vibrating)
			lime.ui.Haptic.vibrate(0, 500);
	}
}