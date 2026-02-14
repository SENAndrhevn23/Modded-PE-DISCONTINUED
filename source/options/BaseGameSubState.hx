package options;

class BaseGameSubState extends BaseOptionsMenu {
    public function new() {
        title = "V-Slice settings";
        rpcTitle = "V-Slice settings menu";
        var option:Option = new Option('Use New Freeplay State',
			'If disabled, it uses the original Freeplay State.',
			'vsliceFreeplay',
			BOOL);
		addOption(option);

        var option:Option = new Option('Freeplay Dynamic Coloring',
			'Enables dynamic freeplay background color.\nDisable this if you prefer original V-slice freeplay menu colors',
			'vsliceFreeplayColors',
			BOOL);
		addOption(option);

		var option:Option = new Option('Use Results Screen',
			'If disabled, it will not show the result screen.',
			'vsliceResults',
			BOOL);
		addOption(option);

		var option:Option = new Option('Smooth Song Position',
			'If enabled, it reduces the stuttering whole gameplay,\nin exchange for maybe cause problems with scripts.',
			'vsliceSongPosition',
			BOOL);
		addOption(option);

		var option:Option = new Option('Smooth Health Bar',
			'If enabled, makes health bar move move smoothly.',
			'vsliceSmoothBar',
			BOOL);
		addOption(option);

		var option:Option = new Option('- Smoothness Speed',
			'Change the speed of the Health Bar smoothness.\n0 = Disabled, 1 = No Smoothness.',
			'vsliceSmoothNess',
			PERCENT);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1.0;
		option.changeValue = 0.01;
		option.decimals = 2;
		addOption(option);

		var option:Option = new Option('Special Freeplay Cards',
			"If disabled, it will force every character to use BF's card. (including pico)",
			'vsliceSpecialCards',
			BOOL);
		addOption(option);

		var option:Option = new Option('Listen Whole Song Of Freeplay',
			'If enabled, it will load every song in Freeplay State,\nVery CPU Intensive.',
			'vsliceLoadInstAll',
			BOOL);
		addOption(option);

		var option:Option = new Option('Botplay Text Location: ',
			'Change the Botplay Text Location.',
			'vsliceBotPlayPlace',
			STRING,
			[
				"Near the Time Bar",
				"Near the Health Bar",
			]);
		addOption(option);
		var option:Option = new Option('Force "New" tag',
			'If enabled will force every uncompleted song to show "new" tag even if it\'s disabled',
			'vsliceForceNewTag',
			'bool');
		addOption(option);
        super();
    }
}