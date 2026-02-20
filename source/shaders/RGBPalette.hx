package shaders;

import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.graphics.shader.FlxShader;

/**
 * RGBPalette shader
 */
class RGBPalette {
    public var shader(default, null):RGBPaletteShader;
    public var r(default, set):FlxColor;
    public var g(default, set):FlxColor;
    public var b(default, set):FlxColor;
    public var mult(default, set):Float;

    public function new() {
        r = 0xFFFF0000;
        g = 0xFF00FF00;
        b = 0xFF0000FF;
        mult = 1.0;
        shader = new RGBPaletteShader();

        set_r(r);
        set_g(g);
        set_b(b);
        set_mult(mult);
    }

    private function set_r(value:FlxColor):FlxColor {
        r = value;
        shader.r.value = [value.redFloat, value.greenFloat, value.blueFloat];
        return value;
    }

    private function set_g(value:FlxColor):FlxColor {
        g = value;
        shader.g.value = [value.redFloat, value.greenFloat, value.blueFloat];
        return value;
    }

    private function set_b(value:FlxColor):FlxColor {
        b = value;
        shader.b.value = [value.redFloat, value.greenFloat, value.blueFloat];
        return value;
    }

    private function set_mult(value:Float):Float {
        mult = FlxMath.bound(value, 0, 1);
        shader.mult.value = [mult];
        return mult;
    }
}

/**
 * RGBShaderReference for a sprite
 */
class RGBShaderReference {
    public var r(default, set):FlxColor;
    public var g(default, set):FlxColor;
    public var b(default, set):FlxColor;
    public var mult(default, set):Float;
    public var enabled(default, set):Bool;

    public var parent(default, null):RGBPalette;
    public var shader(default, null):RGBPaletteShader;

    private var _owner:FlxSprite;

    public static var instances:Array<RGBShaderReference> = [];

    public function new(owner:FlxSprite, palette:RGBPalette) {
        _owner = owner;
        parent = palette;
        shader = palette.shader;

        r = palette.r;
        g = palette.g;
        b = palette.b;
        mult = palette.mult;
        enabled = true;

        _owner.shader = shader;
        instances.push(this);
    }

    public function set_enabled(value:Bool):Bool {
        enabled = value;
        _owner.shader = value ? shader : null;
        return enabled;
    }

    public static function setGlobalEnabled(value:Bool):Void {
        for (ref in instances) {
            ref.enabled = value;
        }
    }
}

/**
 * FlxShader implementation for RGBPalette
 */
class RGBPaletteShader extends FlxShader {
    @:glFragmentHeader('
        #pragma header
        uniform vec3 r;
        uniform vec3 g;
        uniform vec3 b;
        uniform float mult;

        vec4 flixel_texture2DCustom(sampler2D bitmap, vec2 coord) {
            vec4 color = flixel_texture2D(bitmap, coord);
            if (!hasTransform || color.a == 0.0 || mult == 0.0) return color;
            vec4 newColor = color;
            newColor.rgb = min(color.r*r + color.g*g + color.b*b, vec3(1.0));
            newColor.a = color.a;
            color = mix(color, newColor, mult);
            if(color.a > 0.0) return vec4(color.rgb, color.a);
            return vec4(0.0,0.0,0.0,0.0);
        }
    ')

    @:glFragmentSource('
        #pragma header
        void main() { gl_FragColor = flixel_texture2DCustom(bitmap, openfl_TextureCoordv); }
    ')

    public function new() {
        super();
    }
}
