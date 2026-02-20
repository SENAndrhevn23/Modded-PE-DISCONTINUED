package shaders;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import openfl.display.Shader;
import openfl.display.ShaderFilter;

/**
 * RGBPalette shader data
 */
class RGBPalette {
    public var r(default, set):FlxColor;
    public var g(default, set):FlxColor;
    public var b(default, set):FlxColor;
    public var mult(default, set):Float;

    public var shader:Shader;

    public function new() {
        r = 0xFFFF0000; // red
        g = 0xFF00FF00; // green
        b = 0xFF0000FF; // blue
        mult = 1.0;

        shader = new Shader();
        updateShader();
    }

    private function updateShader():Void {
        shader.data.r = { value: [r.redFloat, r.greenFloat, r.blueFloat] };
        shader.data.g = { value: [g.redFloat, g.greenFloat, g.blueFloat] };
        shader.data.b = { value: [b.redFloat, b.greenFloat, b.blueFloat] };
        shader.data.mult = { value: [FlxMath.bound(mult, 0, 1)] };
    }

    private function set_r(value:FlxColor):FlxColor {
        r = value;
        updateShader();
        return r;
    }

    private function set_g(value:FlxColor):FlxColor {
        g = value;
        updateShader();
        return g;
    }

    private function set_b(value:FlxColor):FlxColor {
        b = value;
        updateShader();
        return b;
    }

    private function set_mult(value:Float):Float {
        mult = FlxMath.bound(value, 0, 1);
        updateShader();
        return mult;
    }
}

/**
 * Reference to a sprite's RGB shader
 * Allows toggling on/off globally or per-sprite
 */
class RGBShaderReference {
    public var r(default, set):FlxColor;
    public var g(default, set):FlxColor;
    public var b(default, set):FlxColor;
    public var mult(default, set):Float;
    public var enabled(default, set):Bool;

    private var _owner:FlxSprite;
    private var _palette:RGBPalette;

    /** Global list of all shader refs */
    public static var instances:Array<RGBShaderReference> = [];

    public function new(owner:FlxSprite, palette:RGBPalette) {
        _owner = owner;
        _palette = palette;

        r = palette.r;
        g = palette.g;
        b = palette.b;
        mult = palette.mult;
        enabled = true;

        // apply shader to sprite
        _owner.shader = palette.shader;

        instances.push(this);
    }

    public function set_r(value:FlxColor):FlxColor {
        r = value;
        _palette.r = value;
        return r;
    }

    public function set_g(value:FlxColor):FlxColor {
        g = value;
        _palette.g = value;
        return g;
    }

    public function set_b(value:FlxColor):FlxColor {
        b = value;
        _palette.b = value;
        return b;
    }

    public function set_mult(value:Float):Float {
        mult = FlxMath.bound(value, 0, 1);
        _palette.mult = mult;
        return mult;
    }

    public function set_enabled(value:Bool):Bool {
        enabled = value;
        _owner.shader = value ? _palette.shader : null;
        return enabled;
    }

    /** Toggle all shaders globally */
    public static function setGlobalEnabled(value:Bool):Void {
        for (ref in instances) {
            ref.enabled = value;
        }
    }
}
