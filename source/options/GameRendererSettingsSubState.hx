package options;

class GameRendererSettingsSubState extends BaseOptionsMenu
{
	var fpsOption:Option;
	var bitOption:Option;
	var gcRateOption:Option;
	public function new()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Game Renderer", null);
		#end
		
		title = 'Game Renderer';
		rpcTitle = 'Game Renderer Settings Menu'; //for Discord Rich Presence

		//Working in Progress!
        var option:Option = new Option('Working in Progress', //Name
			"Make changes at your own risk.", //Description
			'openDoor', //Save data variable name
			STRING,
			['!']); //Variable type
		addOption(option);

        var option:Option = new Option('Use Game Renderer',
			"If checked, It renders a video.\nAnd It forces turn on Botplay and disable debug menu key.",
			'ffmpegMode',
			BOOL);
		option.onChange = resetTimeScale;
		addOption(option);

        // var option:Option = new Option('Skip Notes Even Rendering',
		// 	"If checked, The note can skips in rendering.\nBut It wouldn't big impact any perfomance.",
		// 	'allowSkipInRendering',
		// 	BOOL);
		// option.onChange = resetTimeScale;
		// addOption(option);

        var option:Option = new Option('Garbage Collection Rate',
			"Have GC run automatically based on this option.\nSpecified by Frame and It turn on GC forcely.\n0 means disabled. Beware of memory leaks!",
			'gcRate',
			INT);
		addOption(option);
		
		option.minValue = 0;
		option.maxValue = 10000;
		option.scrollSpeed = 60;
		option.decimals = 0;
		option.onChange = onChangeGCRate;
		gcRateOption = option;

		var option:Option = new Option('Run Major Garbage Collection',
			"Increase the GC range and reduce memory usage.\nIt's for upper option.",
			'gcMain',
			BOOL);
		addOption(option);

        var option:Option = new Option('Video Framerate',
			"How much do you need fps in your video?",
			'targetFPS',
			INT);
		final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
		option.minValue = 1;
		option.maxValue = 1000;
		option.scrollSpeed = 30;
		option.decimals = 0;
		option.defaultValue = Std.int(FlxMath.bound(refreshRate, option.minValue, option.maxValue));
		option.displayFormat = '%v FPS';
		option.onChange = onChangeFramerate;
		fpsOption = option;
		addOption(option);

		var option:Option = new Option('Video Codec',
			"It's advanced Option. If you don't know, leave this 'H.264'.",
			'codec',
			STRING,
			[
				'H.264',
				'H.264 (QSV)',
				'H.264 (NVENC)',
				'H.264 (AMF)',
				'H.264 (VAAPI)',
				'H.265',
				'H.265 (QSV)',
				'H.265 (NVENC)',
				'H.265 (AMF)',
				'H.265 (VAAPI)',
				'VP8',
				'VP8 (VAAPI)',
				'VP9',
				'VP9 (VAAPI)',
				'AV1',
				'AV1 (NVENC for RTX40)'
			]); //Variable type
		addOption(option);

		var option:Option = new Option('Encode Mode',
			"It's advanced Option.\nSelect the mode of rendering you want.",
			'encodeMode',
			STRING,
			['CRF/CQP', 'VBR', 'CBR']);
		option.onChange = resetTimeScale;
		addOption(option);

		var option:Option = new Option('Video Bitrate',
			"Set bitrate in here.",
			'bitrate',
			FLOAT);
		final bitrate:Int = option.getValue();
		option.minValue = 0.01;
		option.maxValue = 100;
		option.changeValue = 0.01;
		option.scrollSpeed = 3;
		option.decimals = 2;
		option.defaultValue = Std.int(FlxMath.bound(bitrate, option.minValue, option.maxValue));
		option.displayFormat = '%v Mbps';
		bitOption = option;
		option.onChange = onChangeBitrate;

		addOption(option);

		var option:Option = new Option('Video Quality',
			"The quality which set here is constant.",
			'constantQuality',
			FLOAT);
		addOption(option);

		final bitrate:Int = option.getValue();
		option.minValue = 0;
		option.maxValue = 51;
		option.scrollSpeed = 20;
		option.decimals = 1;
		option.defaultValue = Std.int(FlxMath.bound(bitrate, option.minValue, option.maxValue));
		option.displayFormat = '%v';
		bitOption = option;

        var option:Option = new Option('Unlock Framerate',
			"If checked, fps limit goes 1000 in rendering.",
			'unlockFPS',
			BOOL);
		addOption(option);

        var option:Option = new Option('Pre Rendering',
			"If checked, Render current screen in the first of update method.\nIf unchecked, It does in the last of it.",
			'preshot',
			BOOL);
		addOption(option);

        var option:Option = new Option('Preview Mode',
			"If checked, Skip rendering.\nIf ffmpeg not found, force enabling this.\nIt's for a function for debug too.",
			'previewRender',
			BOOL);
		addOption(option);

        super();
    }

	function onChangeGCRate()
	{
		gcRateOption.scrollSpeed = interpolate(30, 1000, (holdTime - 0.5) / 5, 3);
	}

	function onChangeFramerate()
	{
		fpsOption.scrollSpeed = interpolate(30, 1000, (holdTime - 0.5) / 5, 3);
	}

	function onChangeBitrate()
	{
		bitOption.scrollSpeed = interpolate(1, 100, (holdTime - 0.5) / 5, 3);
	}

	function resetTimeScale()
	{
		FlxG.timeScale = 1;
	}
}