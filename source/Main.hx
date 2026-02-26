package;

import lime.ui.WindowAttributes;
import debug.FPSBg;
import debug.FPSCounter;

import flixel.FlxGame;
import flixel.FlxG;
import flixel.FlxState;
import haxe.io.Path;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import lime.app.Application;
import states.TitleState;

#if linux
import lime.graphics.Image;
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('
    #define GAMEMODE_AUTO
')
#end

class Main extends Sprite
{
    // Game config
    var game = {
        width: 1280,
        height: 720,
        initialState: TitleState,
        zoom: -1.0,
        framerate: 60,
        skipSplash: true,
        startFullscreen: false
    };

    // Debug tools
    public static var fpsBg:FPSBg;
    public static var fpsVar:FPSCounter;
    public static var debugBuild:Bool;
    public static var isConsoleAvailable:Bool = true;

    public static final platform:String = "PCs";

    public static function main():Void
    {
        Lib.current.addChild(new Main());
    }

    public function new()
    {
        super();
        debugBuild = false;

        try {
            Sys.stdout().writeString("Console Available!\n");
        } catch (e:Dynamic) {
            isConsoleAvailable = false;
        }

        backend.CrashHandler.init();

        if (stage != null) init();
        else addEventListener(Event.ADDED_TO_STAGE, init);
    }

    private function init(?E:Event):Void
    {
        if (hasEventListener(Event.ADDED_TO_STAGE))
            removeEventListener(Event.ADDED_TO_STAGE, init);

        setupGame();
    }

    private function setupGame():Void
    {
        // Ensure zoom is sane
        if (game.zoom == -1.0) game.zoom = 1.0;

        // --- PRELOADING PHASE ---
        preloadAssets();

        // Bind save and load highscore
        FlxG.save.bind('funkin', CoolUtil.getSavePath());
        Highscore.load();

        // Initialize controls
        Controls.instance = new Controls();
        ClientPrefs.loadDefaultKeys();

        // --- GAME OBJECT ---
        var gameObject = new FlxGame(
            game.width, game.height,
            game.initialState,
            game.framerate, game.framerate,
            game.skipSplash, game.startFullscreen
        );

        @:privateAccess
        gameObject._customSoundTray = mikolka.vslice.components.FunkinSoundTray;

        addChild(gameObject);

        // --- DEBUG OVERLAY ---
        fpsBg = new FPSBg();
        fpsVar = new FPSCounter(6, 1, 0xFFFFFF);
        addChild(fpsBg);
        addChild(fpsVar);

        Lib.current.stage.align = "tl";
        Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;

        fpsVar.visible = ClientPrefs.data.showFPS;
        fpsBg.visible = ClientPrefs.data.showFPS;

        // --- PERFORMANCE SETTINGS ---
        FlxG.fixedTimestep = true;            // Fixed timestep = smoother physics
        FlxG.fixedTimestepStep = 1.0/60.0;
        FlxG.game.focusLostFramerate = 60;   // Maintain FPS when unfocused

        FlxG.signals.gameResized.add(function(w, h)
        {
            if (FlxG.cameras != null)
                for (cam in FlxG.cameras.list)
                    if (cam != null && cam.filters != null)
                        resetSpriteCache(cam.flashSprite);

            if (FlxG.game != null)
                resetSpriteCache(FlxG.game);
        });
    }

    /**
     * Preloads all assets, mods, and sounds to prevent runtime stutter
     */
    private function preloadAssets():Void
    {
        // Load top mod
        Mods.loadTopMod();

        // Preload essential textures
        Assets.loadBitmapData("assets/images/characters.png", null, true);
        Assets.loadBitmapData("assets/images/backgrounds.png", null, true);

        // Preload sounds
        Assets.loadSound("assets/sounds/music1.ogg", true);
        Assets.loadSound("assets/sounds/music2.ogg", true);

        // Preload fonts (if any)
        Assets.loadFont("assets/fonts/gameFont.ttf");

        // Optional: preload object pools (notes, enemies, etc.)
        PoolManager.init();
    }

    /**
     * Resets cached bitmap data for smooth rendering after resize
     */
    static function resetSpriteCache(sprite:Sprite):Void
    {
        @:privateAccess {
            sprite.__cacheBitmap = null;
            sprite.__cacheBitmapData = null;
        }
    }
}
