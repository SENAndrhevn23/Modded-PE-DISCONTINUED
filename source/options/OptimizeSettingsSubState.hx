package options;

class OptimizeSettingsSubState extends BaseOptionsMenu
{
	var limitCount:Option;
	var cacheCount:Option;

	public function new()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Optimizations Menu", null);
		#end
		
		title = 'Optimizations';
		rpcTitle = 'Optimization Settings Menu'; //for Discord Rich Presence

		//Working in Progress!
        var option:Option = new Option('Work in Progress', //Name
			"Make changes at your own risk.", //Description
			'openDoor', //Save data variable name
			STRING,
			['!']); //Variable type
		addOption(option);

        var option:Option = new Option('Show Notes',
			"If unchecked, appearTime is set to 0. All notes will be processed as skipped notes.\nBotplay is force-enabled.",
			'showNotes',
			BOOL);
		addOption(option);

        var option:Option = new Option('Show Notes again after Skip',
			"If checked, it tries preventing notes from showing only halfway through.",
			'showAfter',
			BOOL);
		addOption(option);

        var option:Option = new Option('Keep Notes in Screen',
		 	"If checked, notes will display from top to bottom, even if they are skippable.\nIf unchecked, it improves performance, especially if a lot of notes are displayed.",
		 	'keepNotes',
		 	BOOL);
		addOption(option);
		
        var option:Option = new Option('Sort Notes:',
			"If checked, the notes array is sorted every frame when notes are added.\nUnchecking improves performance, especially if a lot of notes are displayed.\nDefault: \"After Note Finalized\"",
			'sortNotes',
			STRING,
			[
				'Never',
				'After Note Spawned',
				'After Note Processed',
				'After Note Finalized',
				'Reversed',
				'Chaotic',
				'Random',
				'Shuffle',
			]); //Variable type
		addOption(option);

        var option:Option = new Option('Show Rating Pop-Up',
			"If checked, \"Rating Pop-Up\" shows up every time you hit notes.\nUnchecking reduces a little bit of memory usage.",
			'showRating',
			BOOL);
		addOption(option);

		var option:Option = new Option('Show Combo Number Pop-Up',
			"If checked, \"Combo Number Pop-Up\" shows up every time you hit notes.\nUnchecking reduces a little bit of memory usage.",
			'showComboNum',
			BOOL);
		addOption(option);

		var option:Option = new Option('Show Combo Pop-Up',
			"If checked, \"Combo Pop-Up\" shows up every time you hit notes.\n(I don't think anyone checks this option)",
			'showCombo',
			BOOL);
		addOption(option);

		var option:Option = new Option('Better Recycling',
			"If checked, the game will use NoteGroup's recycle system.\nIt boosts game performance massively.",
			'betterRecycle',
			BOOL);
		addOption(option);

		var option:Option = new Option('Max Notes Shown:',
			"How many notes do you wanna display? To unlimited, set the value to 0.",
			'limitNotes',
			INT);
		option.scrollSpeed = 30;
		option.minValue = 0;
		option.maxValue = 99999;
		option.changeValue = 1;
		option.decimals = 0;
		option.onChange = onChangeLimitCount;
		limitCount = option;
		addOption(option);

		var option:Option = new Option('Cache Notes:',
			"Enables recycling of a specified number of items before playing.\nIt cuts time of newing instances. To diable, set the value to 0.\nYou need the same amount of RAM as the value chosen.",
			'cacheNotes',
			INT);
		option.scrollSpeed = 30;
		option.minValue = 0;
		option.maxValue = 99999;
		option.changeValue = 1;
		option.decimals = 0;
		option.onChange = onChangeCacheCount;
		cacheCount = option;
		addOption(option);

        var option:Option = new Option('Process Notes before Spawning',
			"If checked, it process notes before they spawn.\nIt boosts game performance vastly.\nIt is recommended to enable this option.",
			'processFirst',
			BOOL);
		addOption(option);

        var option:Option = new Option('Skip Process for Spawned Note',
			"If checked, enables Skip Note Function.\nIt boosts game performance vastly, but it only works in specific situations.\nIf you don't understand, enable this.",
			'skipSpawnNote',
			BOOL);
		addOption(option);

        var option:Option = new Option('Optimize Process for Spawned Note',
			"If checked, it judges whether or not to do hit process\nimmediately when a note spawned. It boosts game performance vastly,\nbut it only works in specific situations. If you don't understand, enable this.",
			'optimizeSpawnNote',
			BOOL);
		addOption(option);

        var option:Option = new Option('noteHitPreEvent',
			"If unchecked, the game will not send any noteHitPreEvent on Lua/HScript.",
			'noteHitPreEvent',
			BOOL);
		addOption(option);

        var option:Option = new Option('noteHitEvent',
			"If unchecked, the game will not send any noteHitEvent on Lua/HScript.\nNot recommended to disable this option.",
			'noteHitEvent',
			BOOL);
		addOption(option);

		var option:Option = new Option('spawnNoteEvent',
			"If unchecked, the game will not send spawn event\non Lua/HScript for spawned notes. Improves performance.",
			'spawnNoteEvent',
			BOOL);
		addOption(option);

		var option:Option = new Option('noteHitEvents for Skipped Notes',
			"If unchecked, the game will not send any hit event\non Lua/HScript for skipped notes. Improves performance.",
			'skipNoteEvent',
			BOOL);
		addOption(option);

        var option:Option = new Option('Disable Garbage Collector',
			"If checked, You can play the main game without GC lag.\nIt only works on loading/playing charts.",
			'disableGC',
			BOOL);
		addOption(option);

        super();
    }

	function onChangeLimitCount(){
		limitCount.scrollSpeed = interpolate(30, 50000, (holdTime - 0.5) / 10, 3);
	}

	function onChangeCacheCount(){
		cacheCount.scrollSpeed = interpolate(30, 50000, (holdTime - 0.5) / 10, 3);
	}
}
