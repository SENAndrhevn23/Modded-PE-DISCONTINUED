package debug;

import flixel.FlxG;
import openfl.text.TextField;
import openfl.text.TextFormat;
import cpp.vm.Gc;

/**
	A lightweight FPS counter for OpenFL / HaxeFlixel projects
**/
class FPSCounter extends TextField
{
	// Singleton instance
	public static var instance:FPSCounter;

	// FPS counter variables
	public var currentFPS(default, null):Int;
	public var updateRate:Float = 50; // used by old code
	public var memoryMegas(get, never):Float;

	private var times:Array<Float>;
	private var deltaTimeout:Float = 0.0;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0xFFFFFFFF)
	{
		super();

		instance = this; // restore the static reference

		this.x = x;
		this.y = y;

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		autoSize = LEFT;
		multiline = true;
		defaultTextFormat = new TextFormat("_sans", 14, color);
		text = "FPS: ";

		times = [];
	}

	// Called every frame automatically
	private override function __enterFrame(deltaTime:Float):Void
	{
		final now:Float = haxe.Timer.stamp() * 1000;
		times.push(now);

		// Remove timestamps older than 1 second
		while (times.length > 0 && times[0] < now - 1000) times.shift();

		// Use updateRate from old code for throttle
		if (deltaTimeout < 1000 / updateRate) {
			deltaTimeout += deltaTime;
			return;
		}

		currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;
		updateText();
		deltaTimeout = 0.0;
	}

	// Updates the text display
	public dynamic function updateText():Void
	{
		text = 'FPS: ${currentFPS}\nMemory: ${flixel.util.FlxStringUtil.formatBytes(memoryMegas)}';
		textColor = currentFPS < FlxG.drawFramerate * 0.5 ? 0xFFFF0000 : 0xFFFFFFFF;
	}

	// Restore positionFPS function for old code
	public function positionFPS(X:Float, Y:Float, ?isWide:Bool = false, ?scale:Float = 1):Void
	{
		scaleX = scaleY = scale;
		x = X;
		y = Y;
	}

	inline function get_memoryMegas():Float
		return Gc.memInfo64(Gc.MEM_INFO_USAGE);
}
