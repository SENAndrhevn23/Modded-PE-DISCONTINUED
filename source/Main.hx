package;

import lime.ui.WindowAttributes;
import debug.FPSBg;
import debug.FPSCounter;

import flixel.graphics.FlxGraphic;
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

#if windows
// Windows-specific includes can go here
#end

class Main extends Sprite
{
    var game = {
        width: 1280,
        height: 720,
        initialState: TitleState,
        zoom: -1.0,
        framerate: 60,
        skipSplash: true,
        startFullscreen: false
    };

    public static var fpsBg:FPSBg;
    public static var fpsVar:FPSCounter;
    public static var debugBuild:Bool;
    public static var isConsoleAvailable:Bool = true;

    // Platform string for desktops only
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
        if (game.zoom == -1.0)
            game.zoom = 1.0;

        Mods.loadTopMod();

        FlxG.save.bind('funkin', CoolUtil.getSavePath());
        Highscore.load();

        Controls.instance = new Controls();
        ClientPrefs.loadDefaultKeys();

        var gameObject = new FlxGame(
            game.width, game.height,
            game.initialState,
            game.framerate, game.framerate,
            game.skipSplash, game.startFullscreen
        );

        @:privateAccess
        gameObject._customSoundTray = mikolka.vslice.components.FunkinSoundTray;

        addChild(gameObject);

        fpsBg = new FPSBg();
        fpsVar = new FPSCounter(6, 1, 0xFFFFFF);
        addChild(fpsBg);
        addChild(fpsVar);

        Lib.current.stage.align = "tl";
        Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
        if(fpsVar != null) fpsVar.visible = ClientPrefs.data.showFPS;
        if(fpsBg != null) fpsBg.visible = ClientPrefs.data.showFPS;

        FlxG.fixedTimestep = false;
        FlxG.game.focusLostFramerate = 60;

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

    static function resetSpriteCache(sprite:Sprite):Void
    {
        @:privateAccess {
            sprite.__cacheBitmap = null;
            sprite.__cacheBitmapData = null;
        }
    }
}
