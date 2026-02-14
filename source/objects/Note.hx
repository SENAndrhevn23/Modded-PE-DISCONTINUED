package objects;

import flixel.graphics.FlxGraphic;
import backend.animation.PsychAnimationController;
import backend.NoteTypesConfig;

import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

import objects.StrumNote;

import flixel.math.FlxRect;

using StringTools;

typedef EventNote = {
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

typedef NoteSplashData = {
	disabled:Bool,
	texture:String,
	useGlobalShader:Bool, //breaks r/g/b but makes it copy default colors for your custom note
	useRGBShader:Bool,
	antialiasing:Bool,
	a:Float
}

typedef CastNote = {
	var strumTime:Float;
	// noteData and flags
	// 1st-8th bits are for noteData (256keys)
	// 9th bit is for mustHit
	// 10th bit is for isHold
	// 11th bit is for isHoldEnd
	// 12th bit is for gfNote
	// 13th bit is for altAnim
	// 14th bit is for noAnim & noMissAnim
	// 15th bit is for blockHit
	// 16th bit is for ignoreNote
	var noteData:Int;
	@:optional var noteType:String;
	var holdLength:Null<Float>;
	var noteSkin:String;
}

var toBool = CoolUtil.bool;
var toInt = CoolUtil.int;

/**
 * The note object used as a data structure to spawn and manage notes during gameplay.
 * 
 * If you want to make a custom note type, you should search for: "function set_noteType"
**/
class Note extends FlxSprite
{
	//This is needed for the hardcoded note types to appear on the Chart Editor,
	//It's also used for backwards compatibility with 0.1 - 0.3.2 charts.
	public static final defaultNoteTypes:Array<String> = [
		'', //Always leave this one empty pls
		'Alt Animation',
		'Hey!',
		'Hurt Note',
		'GF Sing',
		'No Animation'
	];

	public static final DEFAULT_CAST:CastNote = {
		strumTime: 0,
		noteData: 0,
		noteType: "",
		holdLength: 0,
		noteSkin: ""
	};

	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var strumTime:Float = 0;
	public var noteData:Int = 0;
	public var strum:StrumNote = null;

	public var mustPress:Bool = false;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var followed:Bool = false;

	public var wasGoodHit:Bool = false;
	public var missed:Bool = false;

	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;

	public var spawned:Bool = false;

	public var tail:Array<Note> = []; // for sustains
	public var parent:Note;
	
	public var blockHit:Bool = false; // only works for player

	public var sustainLength:Float = 0;
	public var sustainScale:Float = 1.0;
	public var isSustainNote:Bool = false;
	public var isSustainEnds:Bool = false;
	public var noteType(default, set):String = null;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var rgbShader:RGBShaderReference;
	public static var globalRgbShaders:Array<RGBPalette> = [];
	public var inEditor:Bool = false;

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var earlyHitMult:Float = 1;
	public var lateHitMult:Float = 1;
	public var lowPriority:Bool = false;

	public static var isBotplay:Bool = false;

	public static var SUSTAIN_SIZE:Int = 44;
	public static var swagWidth:Float = 160 * 0.7;
	public static var originalWidth:Float = 160 * 0.7;
	public static var originalHeight:Float = 160 * 0.7;
	public static var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];
	public static var defaultNoteSkin(default, never):String = 'noteSkins/NOTE_assets';

	public var noteSplashData:NoteSplashData = {
		disabled: false,
		texture: null,
		antialiasing: !PlayState.isPixelStage,
		useGlobalShader: false,
		useRGBShader: (PlayState.SONG != null) ? !(PlayState.SONG.disableNoteRGB == true) : true,
		a: ClientPrefs.data.splashAlpha
	};
	public var noteHoldSplash:SustainSplash;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Float = 0.02;
	public var missHealth:Float = 0.1;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; //9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String = null;
	public var downScr:Bool = false;
	public var prevDownScr:Bool = false;

	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000; //plan on doing scroll directions soon -bb

	public var hitsoundDisabled:Bool = false;
	public var hitsoundChartEditor:Bool = true;
	/**
	 * Forces the hitsound to be played even if the user's hitsound volume is set to 0
	**/
	public var hitsoundForce:Bool = false;
	public var hitsoundVolume(get, default):Float = 1.0;
	function get_hitsoundVolume():Float {
		if(ClientPrefs.data.hitsoundVolume > 0)
			return ClientPrefs.data.hitsoundVolume;
		return hitsoundForce ? hitsoundVolume : 0.0;
	}
	public var hitsound:String = 'hitsound';

	private function set_multSpeed(value:Float):Float {
		resizeByRatio(value / multSpeed);
		multSpeed = value;
		//trace('fuck cock');
		return value;
	}

	inline public function resizeByRatio(ratio:Float) //haha funny twitter shit
	{
		if(isSustainNote && animation != null && animation.curAnim != null && !animation.curAnim.name.endsWith('end'))
		{
			scale.y *= ratio;
			updateHitbox();
		}
	}

	// It's only used newing instances
	private function set_texture(value:String):String {
		if (value == null || value.length == 0) {
			value = defaultNoteSkin + getNoteSkinPostfix();
		}
		if (!PlayState.isPixelStage) {
			if(texture != value) {
				if (!Paths.noteSkinFramesMap.exists(value)) inline Paths.initNote(value);
				frames = Paths.noteSkinFramesMap.get(value);
				animation.copyFrom(Paths.noteSkinAnimsMap.get(value));
				antialiasing = ClientPrefs.data.antialiasing;

				setGraphicSize(Std.int(width * 0.7));
				updateHitbox();
				originalWidth = width;
				originalHeight = height;
			} else return value;
		} else reloadNote(value);
		texture = value;
		return value;
	}

	static var colArr:Array<FlxColor>;
	public function defaultRGB()
	{
		colArr = PlayState.isPixelStage ? ClientPrefs.data.arrowRGBPixel[noteData] : ClientPrefs.data.arrowRGB[noteData];

		if (colArr != null && noteData > -1 && noteData <= colArr.length)
		{
			rgbShader.r = colArr[0];
			rgbShader.g = colArr[1];
			rgbShader.b = colArr[2];
		}
		else
		{
			rgbShader.r = 0xFFFF0000;
			rgbShader.g = 0xFF00FF00;
			rgbShader.b = 0xFF0000FF;
		}
	}

	private function set_noteType(value:String):String {
		noteSplashData.texture = PlayState.SONG != null ? PlayState.SONG.splashSkin : 'noteSplashes';
		if (rgbShader != null && rgbShader.enabled) defaultRGB();

		if (noteData > -1) {
			if (value == 'Hurt Note') {
				ignoreNote = mustPress && isBotplay;
				//reloadNote('HURTNOTE_assets');
				//this used to change the note texture to HURTNOTE_assets.png,
				//but i've changed it to something more optimized with the implementation of RGBPalette:

				// note colors
				rgbShader.r = 0xFF101010;
				rgbShader.g = 0xFFFF0000;
				rgbShader.b = 0xFF990022;

				// splash data and colors
				//noteSplashData.r = 0xFFFF0000;
				//noteSplashData.g = 0xFF101010;
				noteSplashData.texture = 'noteSplashes-electric';

				// gameplay data
				lowPriority = true;
				missHealth = isSustainNote ? 0.25 : 0.1;
				hitCausesMiss = true;
				hitsound = 'cancelMenu';
				hitsoundChartEditor = false;
			}
			if (value != null && value.length > 1) NoteTypesConfig.applyNoteTypeData(this, value);
			if (hitsound != 'hitsound' && hitsoundVolume > 0) Paths.sound(hitsound); //precache new sound for being idiot-proof
			noteType = value;
		}
		return value;
	}

	// strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?createdFrom:Dynamic = null
	public function new()
	{
		super();
		animation = new PsychAnimationController(this);
		antialiasing = ClientPrefs.data.antialiasing;

		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		x += (ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		y -= 2000;

		rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData));
		if (PlayState.SONG != null && PlayState.SONG.disableNoteRGB) rgbShader.enabled = false;
	}

	static var newRGB:RGBPalette;
	public static function initializeGlobalRGBShader(noteData:Int)
	{
		if(globalRgbShaders[noteData] == null)
		{
			newRGB = null; // Memory deallocation
			newRGB = new RGBPalette();
			colArr = PlayState.isPixelStage ? ClientPrefs.data.arrowRGBPixel[noteData] : ClientPrefs.data.arrowRGB[noteData];
			
			if (colArr != null && noteData > -1 && noteData <= colArr.length)
			{
				newRGB.r = colArr[0];
				newRGB.g = colArr[1];
				newRGB.b = colArr[2];
			}
			else
			{
				newRGB.r = 0xFFFF0000;
				newRGB.g = 0xFF00FF00;
				newRGB.b = 0xFF0000FF;
			}
			
			globalRgbShaders[noteData] = newRGB;
		}
		return globalRgbShaders[noteData];
	}

	var _lastNoteOffX:Float = 0;
	var rSkin:String;
	var rAnimName:String;

	var rSkinPixel:String;
	var rLastScaleY:Float;
	var rSkinPostfix:String;
	var rCustomSkin:String;
	var rPath:String;

	var rGraphic:FlxGraphic;

	static var _lastValidChecked:String; //optimization
	public var pixelHeight:Float = 6;
	public var correctionOffset:Float = 0; //dont mess with this
	public function reloadNote(texture:String = '', postfix:String = '') {
		if(texture == null) texture = '';
		if(postfix == null) postfix = '';

		rSkin = texture + postfix;
		if(texture.length < 1)
		{
			rSkin = PlayState.SONG != null ? PlayState.SONG.arrowSkin : null;
			if(rSkin == null || rSkin.length < 1)
				rSkin = defaultNoteSkin + postfix;
		}
		else rgbShader.enabled = false;

		rAnimName = null;
		if(animation.curAnim != null) {
			rAnimName = animation.curAnim.name;
		}

		rPath = PlayState.isPixelStage ? 'pixelUI/' : '';
		rSkinPixel = rPath + rSkin;
		rLastScaleY = scale.y;
		rSkinPostfix = getNoteSkinPostfix();
		rCustomSkin = rSkin + rSkinPostfix;

		if (rCustomSkin == _lastValidChecked || Paths.fileExists('images/' + rPath + rCustomSkin + '.png', IMAGE))
		{
			rSkin = rCustomSkin;
			_lastValidChecked = rCustomSkin;
		}
		else rSkinPostfix = '';

		if (PlayState.isPixelStage) {
			if (isSustainNote) {
				rGraphic = Paths.image(rSkinPixel + 'ENDS' + rSkinPostfix);
				loadGraphic(rGraphic, true, Math.floor(rGraphic.width / 4), Math.floor(rGraphic.height / 2));
				pixelHeight = rGraphic.height / 2;
			} else {
				rGraphic = Paths.image(rSkinPixel + rSkinPostfix);
				loadGraphic(rGraphic, true, Math.floor(rGraphic.width / 4), Math.floor(rGraphic.height / 5));
			}
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			loadPixelNoteAnims();
			antialiasing = false;

			if (isSustainNote) {
				offsetX += _lastNoteOffX;
				_lastNoteOffX = (width - 7) * (PlayState.daPixelZoom / 2);
				offsetX -= _lastNoteOffX;
			}
		} else {
			frames = Paths.getSparrowAtlas(rSkin);
			loadNoteAnims();
			if(!isSustainNote)
			{
				centerOffsets();
				centerOrigin();
			}
		}

		if(isSustainNote) {
			scale.y = rLastScaleY;
		}
		updateHitbox();

		if(rAnimName != null)
			animation.play(rAnimName, true);
	}

	static var skin:String = '';
	public static function getNoteSkinPostfix()
	{
		skin = '';
		if(ClientPrefs.data.noteSkin != ClientPrefs.defaultData.noteSkin)
			skin = '-' + ClientPrefs.data.noteSkin.trim().toLowerCase().replace(' ', '_');
		return skin;
	}

	function loadNoteAnims() {
		if (colArray[noteData] == null)
			return;

		if (isSustainNote)
		{
			attemptToAddAnimationByPrefix('purpleholdend', 'pruple end hold', 24, true); // this fixes some retarded typo from the original note .FLA
			animation.addByPrefix(colArray[noteData] + 'holdend', colArray[noteData] + ' hold end', 24, true);
			animation.addByPrefix(colArray[noteData] + 'hold', colArray[noteData] + ' hold piece', 24, true);
		}
		else animation.addByPrefix(colArray[noteData] + 'Scroll', colArray[noteData] + '0');

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
	}

	function loadPixelNoteAnims() {
		if (colArray[noteData] == null)
			return;

		if(isSustainNote)
		{
			animation.add(colArray[noteData] + 'holdend', [noteData + 4], 24, true);
			animation.add(colArray[noteData] + 'hold', [noteData], 24, true);
		} else animation.add(colArray[noteData] + 'Scroll', [noteData + 4], 24, true);
	}

	
	function attemptToAddAnimationByPrefix(name:String, prefix:String, framerate:Float = 24, doLoop:Bool = true)
	{
		var animFrames = [];
		@:privateAccess
		animation.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
		if(animFrames.length < 1) return;

		animation.addByPrefix(name, prefix, framerate, doLoop);
	}

	var songTime:Float = 0;
	var safeZone:Float = 0;
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		followed = false;

		songTime = Conductor.songPosition;
		safeZone = Conductor.safeZoneOffset;

		if (mustPress)
		{
			canBeHit = (strumTime > songTime - (safeZone * lateHitMult) &&
						strumTime < songTime + (safeZone * earlyHitMult));

			if (strumTime < songTime - safeZone && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (!wasGoodHit && strumTime <= songTime)
			{
				if(!isSustainNote || (prevNote.wasGoodHit && !ignoreNote))
					wasGoodHit = true;
			}
		}

		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}

	override public function destroy()
	{
		super.destroy();
		_lastValidChecked = '';
	}
	
	var strumX:Float;
	var strumY:Float;
	var strumAngle:Float;
	var strumAlpha:Float;
	var strumDirection:Float;
	var angleDir:Float;
	public function followStrumNote(songSpeed:Float = 1)
	{
		if (followed) return;
		strumX = strum.x;
		strumY = strum.y;
		strumAngle = strum.angle;
		strumAlpha = strum.alpha;
		strumDirection = strum.direction;

		if (isSustainNote)
		{
			downScr = ClientPrefs.data.downScroll;
			flipY = downScr;

			if (prevDownScr != downScr) {
				correctionOffset = isSustainNote && !downScr ? originalHeight * 0.5 : 0;
				prevDownScr = downScr;
			}

			scale.set(0.7, animation != null && animation.curAnim != null && animation.curAnim.name.endsWith('end') ? 1 : Conductor.stepCrochet * 0.0105 * (songSpeed * multSpeed) * sustainScale);
			if (PlayState.isPixelStage)
			{
				scale.x = PlayState.daPixelZoom;
				scale.y *= PlayState.daPixelZoom * 1.19;
			}

			updateHitbox();
		}

		distance = (0.45 * (Conductor.songPosition - strumTime) * songSpeed * multSpeed);
		if (!strum.downScroll) distance *= -1;

		angleDir = strumDirection * Math.PI / 180;
		if (copyAngle)
			angle = strumDirection - 90 + strumAngle + offsetAngle;

		if(copyAlpha)
			alpha = strumAlpha * multAlpha;

		if(copyX)
			x = strumX + offsetX + Math.cos(angleDir) * distance;

		if(copyY)
		{
			y = strumY + offsetY + correctionOffset + Math.sin(angleDir) * distance;
			if(strum.downScroll && isSustainNote)
			{
				if(PlayState.isPixelStage)
				{
					y -= PlayState.daPixelZoom * 9.5;
				}
				y -= (frameHeight * scale.y) - (Note.swagWidth * 0.5);
			}
		}
		followed = true;
	}

	var clipCenter:Float;
	var swagRect:FlxRect;
	public function clipToStrumNote()
	{
		clipCenter = strum.y + offsetY + Note.swagWidth / 2;
		if((mustPress || !ignoreNote) && (wasGoodHit || hitByOpponent || (prevNote.wasGoodHit && !canBeHit)))
		{
			swagRect = clipRect;
			if(swagRect == null) swagRect = new FlxRect(0, 0, frameWidth, frameHeight);

			if (strum.downScroll)
			{
				if(y - offset.y * scale.y + height >= clipCenter)
				{
					swagRect.width = frameWidth;
					swagRect.height = (clipCenter - y) / scale.y;
					swagRect.y = frameHeight - swagRect.height;
				}
			}
			else if (y + offset.y * scale.y <= clipCenter)
			{
				swagRect.y = (clipCenter - y) / scale.y;
				swagRect.width = width / scale.x;
				swagRect.height = (height / scale.y) - swagRect.y;
			}
			clipRect = swagRect;
		}
	}

	@:noCompletion
	override function set_clipRect(rect:FlxRect):FlxRect
	{
		clipRect = rect;

		if (frames != null)
			frame = frames.frames[animation.frameIndex];

		return rect;
	}

	override function kill() {
		active = visible = false;
		super.kill();
	}
	
	var initSkin:String = Note.defaultNoteSkin + getNoteSkinPostfix();
	var colorRef:RGBPalette;
	var correctY:Float;
	var playbackRate:Float;

	public function recycleNote(target:CastNote, ?oldNote:Note) {
		wasGoodHit = hitByOpponent = tooLate = false;
		canBeHit = spawned = followed = false; // Don't make an update call of this for the note group
		exists = true; flipY = false;

		isBotplay = PlayState.instance != null ? PlayState.instance.cpuControlled : false;

		strumTime = target.strumTime;
		if (!inEditor) strumTime += ClientPrefs.data.noteOffset;

		mustPress = toBool(target.noteData & (1<<8));						 // mustHit
		isSustainNote = hitsoundDisabled = toBool(target.noteData & (1<<9)); // isHold
		isSustainEnds = toBool(target.noteData & (1<<10));					 // isHoldEnd
		gfNote = toBool(target.noteData & (1<<11));							 // gfNote
		animSuffix = toBool(target.noteData & (1<<12)) ? "-alt" : "";		 // altAnim
		noAnimation = noMissAnimation = toBool(target.noteData & (1<<13));	 // noAnim
		blockHit = toBool(target.noteData & (1<<14));				 		 // blockHit
		ignoreNote = toBool(target.noteData & (1<<15));				 		 // ignoreNote
		noteData = target.noteData & 3;

		// Absoluty should be here, or messing pixel texture glitches...
		if (!PlayState.isPixelStage) {
			if (target.noteSkin == null || target.noteSkin.length == 0 && texture != initSkin) texture = initSkin;
			else if (target.noteSkin.length > 0 && target.noteSkin != texture) texture = target.noteSkin;
		} else reloadNote(texture);

		if (rgbShader.enabled) {
			colorRef = inline initializeGlobalRGBShader(noteData);
			rgbShader.r = colorRef.r;
			rgbShader.g = colorRef.g;
			rgbShader.b = colorRef.b;
		}

		try {
			if (target.noteType is String) noteType = target.noteType; // applying note color on damage notes
			else noteType = defaultNoteTypes[Std.parseInt(target.noteType)];
		} catch (e:Dynamic) {}

		sustainLength = target.holdLength ?? 0;

		prevNote = oldNote ?? this;
		// this.parent = parent;
		// if (this.parent != null) parent.tail = [];

		copyAngle = !isSustainNote;
		downScr = prevDownScr = ClientPrefs.data.downScroll;

		animation.play(colArray[noteData % colArray.length] + 'Scroll', true);
		correctionOffset = isSustainNote && !downScr ? originalHeight * 0.5 : 0;

		if (PlayState.isPixelStage) offsetX = -5;

		if (isSustainNote)
		{
			alpha = multAlpha = 0.6;

			offsetX += width * 0.5;
			animation.play(colArray[noteData % colArray.length] + (isSustainEnds ? 'holdend' : 'hold'));  // isHoldEnd
			updateHitbox();
			offsetX -= width * 0.5;
			
			scale.y *= Conductor.stepCrochet * 0.0105;

			if (PlayState.isPixelStage) {
				offsetX += 35;

				if(!isSustainEnds) {
					scale.y *= 1.05 * (6 / height); //Auto adjust note size
				}
			} else {
				sustainScale = Note.SUSTAIN_SIZE / frameHeight;
			}
			updateHitbox();
		} else {
			alpha = multAlpha = sustainScale = 1;

			if (!PlayState.isPixelStage) 
			{
				// Juuuust in case we recycle a sustain note to a regular note
				offsetX = 0;
				scale.set(0.7, 0.7);
			} else {
				scale.set(PlayState.daPixelZoom, PlayState.daPixelZoom);
			}

			width = originalWidth;
			height = originalHeight;

			centerOffsets(true);
			centerOrigin();
		}

		if (isSustainNote && sustainScale != 1 && !isSustainEnds)
			resizeByRatio(sustainScale);
		clipRect = null;
		x += offsetX;
		return this;
	}

	// it used on spawning hold splashes
	public function toCastNote():CastNote {
		var lmfao:Int = 
			this.noteData & 255 |
			toInt(mustPress) << 8 |
			toInt(isSustainNote) << 9 |
			toInt(isSustainEnds) << 10 |
			toInt(gfNote) << 11 |
			toInt(animSuffix != "")	<< 12 |
			toInt(noAnimation) << 13 |
			toInt(blockHit) << 14 |
			toInt(ignoreNote) << 15;
		
		var converted:CastNote = {
			strumTime: this.strumTime,
			noteData: lmfao,
			noteType: this.noteType,
			holdLength: this.sustainLength,
			noteSkin: this.texture,
		};

		return converted;
	}
}
