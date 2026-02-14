package backend;

import cpp.Float64;
import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;

#if windows
@:cppFileCode('
	#include <stdlib.h>
	#include <string>
	#include <chrono>
	#include <thread>
	#include <stdio.h>
	#include <iostream>
	#include <windows.h>
')
#elseif desktop
@:cppFileCode('
	#include <stdlib.h>
	#include <string>
	#include <chrono>
	#include <thread>
	#include <stdio.h>
	#include <iostream>
')
#else
@:cppFileCode('
	#include <stdlib.h>
	#include <string>
	#include <chrono>
	#include <thread>
')
#end

class CoolUtil
{
	public static final MIN_VALUE_DOUBLE = 2.225073858507201383090232717332404064219215980462331830553327416887204434813918195854283159012511020564067339731035811005152434161553460108856012385377718821130777993532002330479610147442583636071921565046942503734208375250806650616658158948720491179968591639648500635908770118304874799780887753749949451580451605050915399856582470818645113537935804992115981085766051992433352114352390148795699609591288891602992641511063466313393663477586513029371762047325631781485664350872122828637642044846811407613911477062801689853244110024161447421618567166150540154285084716752901903161322778896729707373123334086988983175067838846926092773977972858659654941091369095406136467568702398678315290680984617210924625396728515625e-308;

	inline public static function quantize(f:Float, snap:Float){
		// changed so this actually works lol
		var m:Float = Math.fround(f * snap);
		//trace(snap);
		return (m / snap);
	}

	inline public static function capitalize(text:String)
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();

	inline public static function coolTextFile(path:String):Array<String>
	{
		var daList:String = null;
		#if (sys && MODS_ALLOWED)
		if(FileSystem.exists(path)) daList = File.getContent(path);
		#else
		if(Assets.exists(path)) daList = Assets.getText(path);
		#end
		return daList != null ? listFromString(daList) : [];
	}

	/**
	 * Return string with first character uppercase'd, rest lowercase'd
	 * @param	str
	 * @return
	 */
	 inline public static function FUL(str:String):String
		{
			return str.substr(0, 1).toUpperCase() + str.substr(1, str.length - 1).toLowerCase();
		}

	inline public static function colorFromString(color:String):FlxColor
	{
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if(color.startsWith('0x')) color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if(colorNum == null) colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

	inline public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length)
			daList[i] = daList[i].trim();

		return daList;
	}
	
	/**
	 * Fill numbers with a specified number of digits and right-align with the number.
	 * @param value Floating-point number
	 * @param digits Integer
	 * @param code Integer (use fastCodeAt)
	 */
	static var format:StringBuf = new StringBuf();
	inline public static function fillNumber(value:Float, digits:Int, code:Int) {
		var length:Int = Std.string(value).length;
		var str:String = null;
		format = new StringBuf();

		if(length < digits) {
			for (i in 0...(digits - length))
				format.addChar(code);
			format.add(Std.string(value));
		} else format.add(Std.string(value));

		str = format.toString(); format = null;
		return str;
	}

	inline public static function logX(value:Float, exp:Float) {
		return Math.log(value) / Math.log(exp);
	}

	inline public static function interpolate(a:Float, b:Float, m:Float, e:Float = 1) {
		m = FlxMath.bound(m, 0, 1);
		return FlxMath.lerp(a, b, Math.pow(m, e));
	}

	inline public static function normalize(x:Float, min:Float, max:Float, isBound:Bool = true) {
		return isBound ? FlxMath.bound((x - min) / (max - min), 0, 1) : (x - min) / (max - min);
	}

	inline public static function bool(value:Dynamic):Null<Bool> {
		if (value is Int || value is Float) {
			return (value >= 1);
		}
		return null;
	}

	inline public static function int(value:Dynamic):Null<Int> {
		if (value is Int || value is Float) {
			return Std.int(value);
		} else if (value is Bool) {
			return value ? 1 : 0;
		} else if (value is String) {
			return Std.parseInt(value);
		} else return null;
	}

	inline public static function hex2bin(str:String, reversed:Bool = false) {
		var returnVal:String = "";
		var tmpStr:String = "";
		var hex:Int = 0;
		for (i in 0...str.length) {
			hex = Std.parseInt("0x"+str.charAt(i));
			tmpStr = "";
			for (j in 0...4) {
				tmpStr = ((hex & 1<<j) == 1<<j ? "1" : "0") + tmpStr;
			}
			returnVal += tmpStr + " ";
		}
		return returnVal.substr(0, returnVal.length-1);
	}

	inline public static function dec2bin(int:Int, digits:Int) {
		var str:String = "";
		digits = FlxMath.minInt(digits, 32);

		while (digits > 0) {
			str = Std.string(int % 2) + str;
			int >>= 1; digits--;
		}

		return str;
	}

	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if(decimals < 1)
			return Math.floor(value);

		var tempMult:Float = 1;
		for (i in 0...decimals)
			tempMult *= 10;

		var newValue:Float = Math.floor(value * tempMult);
		return newValue / tempMult;
	}
	
	inline public static function decimal(value:Float, decimals:Int, mode:Int = 1):Float
	{
		var up:Float = Math.pow(10, decimals);
		var down:Float = Math.pow(10, -decimals);
		var mod:Float = value * up;

		switch (mode) {
			case 0: // floor
				value = Math.ffloor(mod);
			case 2: // ceil
				value = Math.fceil(mod);
			case 1 | _: // round
				value = Math.fround(mod);
		}

		return value * down;
	}
	
	inline public static function floatToStringPrecision(number:Float, prec:Int, exponent:Bool = false){
		var str:String;
		var abs:Null<Float> = Math.abs(number);
		var len:Null<Int>;
		var result:String;
		if(!exponent || (abs >= Math.pow(0.1, prec) && abs < Math.pow(10, 6))) {
			str = Std.string(Math.fround(abs * Math.pow(10, prec)));
			len = str.length;
			if(len <= prec){
				// Smaller than 1
				while(len < prec){
					str = '0'+str;
					len++;
				}
				result = '0.'+str;
			} else {
				// Larger than 1
				if (str.length == prec) result = str;
				else {
					result = str.substr(0, str.length-prec) + (prec > 0 ? '.'+str.substr(str.length-prec) : '');
				}
			}
		} else {
			str = ''+Math.fround(
				abs * Math.pow(10, Math.floor( -logX(abs, 10) ) ) * Math.pow(10, prec) * 10
			);
			result = (number > MIN_VALUE_DOUBLE ? str.substr(0,1) + '.' + str.substr(1) : '0') + 'e' + Math.floor(logX(abs, 10));
		}
		str = null; len = null; abs = null;
		return (number < 0 ? "-" : "") + result;
	}

	public static function charAppearanceCnt(str:String, target:String):Int {
		var cnt:Int = 0;
		if (target == null || target.length == 0) return 0;
		for (i in 0...str.length) {
			if (target.length == 1) {
				if (str.charAt(i) == target) ++cnt;
			} else {
				for (j in 0...target.length) {
					if (str.charAt(i) == target.charAt(j)) ++cnt;
				}
			}
		}
		return cnt;
	}

	public static function reverseString(str:String) {
		var reversed:String = "";
		for (i in 0...str.length) {
			reversed = str.charAt(i) + reversed;
		}
		return reversed;
	}

	public static function sortAlphabetically(list:Array<String>):Array<String> {
		// This moster here fixes order of scrips to match the windows implementation
		// Why? because some people use this quirk (like me)

		list.sort((a,b) -> { 
				a = a.toUpperCase();
				b = b.toUpperCase();
			  
				if (a < b) {
				  return -1;
				}
				else if (a > b) {
				  return 1;
				} else {
				  return 0;
				}
			  });
		return list;
	}

	// @:functionCode('
	// 	LARGE_INTEGER freq;
	// 	LARGE_INTEGER time;

	// 	QueryPerformanceFrequency(&freq);
	// 	QueryPerformanceCounter(&time);

	// 	if (freq.QuadPart == 0L || time.QuadPart == 0L) return 0;
	// 	double get = static_cast<double>(time.QuadPart) / freq.QuadPart;

	// 	return get;
	// ')

	@:functionCode('		
		// Get the current time
		auto now = std::chrono::high_resolution_clock::now();
		
		// Time elapsed since the epoch is obtained as DURATION (converted to seconds)
		auto duration = now.time_since_epoch();
		auto seconds = std::chrono::duration_cast<std::chrono::duration<double>>(duration);
		
		// Returns the second as double
		return seconds.count();
	')
	static public function getNanoTime():Float64
	{
		return -1;
	}
	
	// stolen and modded from FlxStringUtil
	public static function formatTime(seconds:Float, precision:Int = 0):String
	{
		var timeString:String = Math.floor(seconds / 60) + ":";
		var timeStringHelper:Int = Math.floor(seconds) % 60;
		var timePresition:Int = Math.round(Math.pow(10, precision));

		if (timeStringHelper < 10)
		{
			timeString += "0";
		}
		timeString += timeStringHelper;
		if (precision > 0)
		{
			timeString += ".";
			timeStringHelper = Math.floor((seconds - Math.floor(seconds)) * timePresition);
			timeString += fillNumber(timeStringHelper, ClientPrefs.data.timePrec, '0'.charCodeAt(0));
		}

		return timeString;
	}

	// stolen and modded from FlxStringUtil
	public static function formatMoney(amount:Float, showDecimal:Int = 0, englishStyle:Bool = true):String
	{
		var isNegative:Null<Bool> = amount < 0;
		amount = Math.abs(amount);

		var string:String = "";
		var comma:String = "";
		var amount:Null<Float> = Math.ffloor(amount);
		var zeroes:String = "";
		var helper:Null<Float>;
		var power:Null<Float>;

		while (amount > 0)
		{
			if (string.length > 0 && comma.length <= 0)
				comma = (englishStyle ? "," : ".");

			zeroes = "";
			helper = amount - Math.ffloor(amount / 1000) * 1000;
			amount = Math.ffloor(amount / 1000);
			if (amount > 0)
			{
				if (helper < 100)
					zeroes += "0";
				if (helper < 10)
					zeroes += "0";
			}
			string = zeroes + helper + comma + string;
		}

		if (string == "")
			string = "0";

		if (showDecimal > 0)
		{
			power = Math.pow(10, showDecimal);
			amount = Math.ffloor(amount * power) - (Math.ffloor(amount) * power);
			string += (englishStyle ? "." : ",");
			if (amount < 10)
				string += "0";
			string += amount;
		}

		if (isNegative)
			string = "-" + string;

		comma = zeroes = null;
		amount = helper = power = null; isNegative = null;

		return string;
	}

	// stolen and modded from FlxStringUtil
	static final byteUnits:Array<String> = ["Bytes", "kB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB", "RB", "QB"];
	static var curUnit:Int;
	public static function formatBytes(bytes:Float, precision:Int = 2, keepPrec:Bool = false, fixedSI:Int = -1):String
	{
		curUnit = 0;
		if(fixedSI < 0) {
			while (bytes >= 1024 && curUnit < byteUnits.length - 1)
			{
				bytes /= 1024;
				curUnit++;
			}
		} else {
			while (curUnit < fixedSI && curUnit < byteUnits.length - 1)
			{
				bytes /= 1024;
				curUnit++;
			}
		}
		if(keepPrec) {
			if(fixedSI < 0) {
				precision = (precision+3) - Std.int(logX(bytes, 10) + 1);
				if (precision < 0) precision = 0;
			}
			return CoolUtil.floatToStringPrecision(bytes, precision) + byteUnits[curUnit];
		}
		else
			return CoolUtil.floorDecimal(bytes, precision) + byteUnits[curUnit];
	}

	inline public static function dominantColor(sprite:flixel.FlxSprite):Int
	{
		var countByColor:Map<Int, Int> = [];
		for(col in 0...sprite.frameWidth)
		{
			for(row in 0...sprite.frameHeight)
			{
				var colorOfThisPixel:FlxColor = sprite.pixels.getPixel32(col, row);
				if(colorOfThisPixel.alphaFloat > 0.05)
				{
					colorOfThisPixel = FlxColor.fromRGB(colorOfThisPixel.red, colorOfThisPixel.green, colorOfThisPixel.blue, 255);
					var count:Int = countByColor.exists(colorOfThisPixel) ? countByColor[colorOfThisPixel] : 0;
					countByColor[colorOfThisPixel] = count + 1;
				}
			}
		}

		var maxCount = 0;
		var maxKey:Int = 0; //after the loop this will store the max color
		countByColor[FlxColor.BLACK] = 0;
		for(key => count in countByColor)
		{
			if(count >= maxCount)
			{
				maxCount = count;
				maxKey = key;
			}
		}
		countByColor = [];
		return maxKey;
	}

	inline public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max) dumbArray.push(i);

		return dumbArray;
	}

	inline public static function browserLoad(site:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	inline public static function openFolder(folder:String, absolute:Bool = false) {
		#if sys
			if(!absolute) folder =  Sys.getCwd() + '$folder';

			folder = folder.replace('/', '\\');
			if(folder.endsWith('/')) folder.substr(0, folder.length - 1);

			#if linux
			var command:String = '/usr/bin/xdg-open';
			#else
			var command:String = 'explorer.exe';
			#end
			Sys.command(command, [folder]);
			trace('$command $folder');
		#else
			FlxG.error("Platform is not supported for CoolUtil.openFolder");
		#end
	}

	/**
		Helper Function to Fix Save Files for Flixel 5

		-- EDIT: [November 29, 2023] --

		this function is used to get the save path, period.
		since newer flixel versions are being enforced anyways.
		@crowplexus
	**/
	@:access(flixel.util.FlxSave.validate)
	inline public static function getSavePath():String {
		final company:String = FlxG.stage.application.meta.get('company');
		// #if (flixel < "5.0.0") return company; #else
		return '${company}/${flixel.util.FlxSave.validate("PsychEngine")}'; //! hardcoding for backwards compatibility
		// #end
	}

	@:functionCode('
		unsigned int cnt = std::thread::hardware_concurrency();
		return cnt;
	')
	public static function getThreadCount():Int {
		return 0;
	}

	public static function setTextBorderFromString(text:FlxText, border:String)
	{
		switch(border.toLowerCase().trim())
		{
			case 'shadow':
				text.borderStyle = SHADOW;
			case 'outline':
				text.borderStyle = OUTLINE;
			case 'outline_fast', 'outlinefast':
				text.borderStyle = OUTLINE_FAST;
			default:
				text.borderStyle = NONE;
		}
	}

	#if windows
	@:functionCode('
		HWND hWnd = GetActiveWindow();
        LPCSTR lwDesc = desc.c_str();
        LPCSTR lwCap = cap.c_str();

        res = MessageBoxA(
            hWnd,
            lwDesc,
            NULL,
            MB_OK
        );
	')
	static public function sendMsgBox(desc:String = "", cap:String = "", res:Int = 0) // TODO: Linux and macOS (will do soon)
	{
		return res;
	}
	#end

	public static function showPopUp(message:String, title:String):Void
	{
		#if android
		AndroidTools.showAlertDialog(title, message, {name: "OK", func: null}, null);
		#elseif windows
		sendMsgBox(message, title);
		#else
		FlxG.stage.window.alert(message, title);
		#end
	}
}
