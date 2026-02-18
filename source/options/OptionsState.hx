package options;

import Controls;
import flixel.graphics.FlxGraphic;
import flixel.input.keyboard.FlxKey;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.group.FlxTypedGroup;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.FlxObject;

#if android
import mobile.options.MobileOptionsSubState;
#end

class OptionsState extends MusicBeatState
{
    var kId = 0;
    var keys:Array<FlxKey> = [D, E, B, U, G, SEVEN];
    var konamiIndex:Int = 0;
    var konamiCode = [];
    var isEnteringKonamiCode:Bool = false;

    var options:Array<String> = [
        'Note Colors',
        'Controls',
        'Adjust Delay and Combo',
        #if desktop 'Video Rendering', #end
        'Optimizations',
        'Graphics',
        'Visuals',
        'Gameplay',
        'V-Slice Options'
        #if (TOUCH_CONTROLS_ALLOWED || mobile) , 'Mobile Options' #end
        #if TRANSLATIONS_ALLOWED , 'Language' #end
        ,'Misc'
    ];

    private var grpOptions:FlxTypedGroup<Alphabet>;
    private static var curSelected:Int = 0;
    public static var menuBG:FlxSprite;
    public static var onPlayState:Bool = false;
    public var enteringDebugMenu:Bool = false;
    private var mainCamera:FlxCamera;
    private var subCamera:FlxCamera;
    private var otherCamera:FlxCamera;
    private var camFollow:FlxObject;
    private var camFollowPos:FlxObject;

    function openSelectedSubstate(label:String)
    {
        switch(label)
        {
            case 'Note Colors':
                if (!ClientPrefs.enableColorShader)
                    CoolUtil.coolError("You need 'Enable Note Colors' in Visuals & UI to access this menu.", "JS Engine Anti-Crash Tool");
                else
                    openSubState(new options.NotesColorSubState());

            case 'Controls':
                openSubState(new options.ControlsSubState());

            case 'Adjust Delay and Combo':
                LoadingState.loadAndSwitchState(() -> new options.NoteOffsetState());

            #if desktop
            case 'Video Rendering':
                openSubState(new options.GameRendererSettingsSubState());
            #end

            case 'Optimizations':
                openSubState(new options.OptimizeSettingsSubState());

            case 'Graphics':
                openSubState(new options.GraphicsSettingsSubState());

            case 'Visuals':
                openSubState(new options.VisualsSettingsSubState());

            case 'Gameplay':
                openSubState(new options.GameplaySettingsSubState());

            case 'V-Slice Options':
                openSubState(new BaseGameSubState());

            #if (TOUCH_CONTROLS_ALLOWED || mobile)
            case 'Mobile Options':
                openSubState(new MobileOptionsSubState());
            #end

            case 'Language':
                openSubState(new options.LanguageSubState());

            case 'Misc':
                openSubState(new options.MiscSettingsSubState());
        }
    }

    var selectorLeft:Alphabet;
    var selectorRight:Alphabet;

    override function create()
    {
        Paths.clearStoredMemory();
        Paths.clearUnusedMemory();

        mainCamera = initPsychCamera();
        subCamera = new FlxCamera();
        otherCamera = new FlxCamera();
        subCamera.bgColor.alpha = 0;
        otherCamera.bgColor.alpha = 0;

        if (onPlayState && PlayState.SONG.disableNoteRGB)
            options.remove('Note Colors');

        FlxG.cameras.add(subCamera, false);
        FlxG.cameras.add(otherCamera, false);

        camFollow = new FlxObject(0, 0, 1, 1);
        camFollowPos = new FlxObject(0, 0, 1, 1);
        add(camFollow);
        add(camFollowPos);
        FlxG.cameras.list[FlxG.cameras.list.indexOf(subCamera)].follow(camFollowPos);

        #if desktop
        DiscordClient.changePresence("Options Menu", null);
        #end

        var yScroll:Float = Math.max(0.25 - (0.05 * (options.length - options.length)), 0.1);
        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.color = 0xFFea71fd;
        bg.updateHitbox();
        bg.scrollFactor.set(0, 0);
        bg.screenCenter();
        bg.y -= 5;
        bg.antialiasing = ClientPrefs.globalAntialiasing;
        add(bg);

        grpOptions = new FlxTypedGroup<Alphabet>();
        add(grpOptions);

        for (i in 0...options.length)
        {
            var optionText:Alphabet = new Alphabet(0, 0, options[i], true);
            optionText.screenCenter();
            optionText.y += (100 * (i - (options.length / 2))) + 50;
            optionText.scrollFactor.set(0, yScroll*1.5);
            optionText.cameras = [subCamera];
            grpOptions.add(optionText);
        }

        selectorLeft = new Alphabet(0, 0, '>', true);
        selectorLeft.scrollFactor.set(0, yScroll*1.5);
        selectorLeft.cameras = [subCamera];
        add(selectorLeft);

        selectorRight = new Alphabet(0, 0, '<', true);
        selectorRight.scrollFactor.set(0, yScroll*1.5);
        selectorRight.cameras = [subCamera];
        add(selectorRight);

        changeSelection();
        ClientPrefs.saveSettings();
        super.create();
    }

    override function closeSubState()
    {
        super.closeSubState();
        ClientPrefs.saveSettings();
        FlxG.mouse.visible = false;
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (controls.UI_UP_P) changeSelection(-1);
        if (controls.UI_DOWN_P) changeSelection(1);

        var lerpVal:Float = CoolUtil.clamp(elapsed * 7.5, 0, 1);
        camFollowPos.setPosition(
            FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal),
            FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal)
        );

        if (controls.BACK && !isEnteringKonamiCode)
        {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            if(PauseSubState.inPause)
            {
                PauseSubState.inPause = false;
                StageData.loadDirectory(PlayState.SONG);
                LoadingState.loadAndSwitchState(PlayState.new);
                FlxG.sound.music.volume = 0;
            }
            else FlxG.switchState(MainMenuState.new);
        }

        if (controls.ACCEPT && !isEnteringKonamiCode)
        {
            openSelectedSubstate(options[curSelected]);
        }

        // Konami code check
        if (FlxG.keys.justPressed.ANY)
        {
            var k = keys[kId];
            if (FlxG.keys.anyJustPressed([k]))
            {
                #if desktop
                kId++;
                #end
                if (kId >= keys.length)
                {
                    enteringDebugMenu = true;
                    kId = 0;
                    FlxTween.tween(FlxG.camera, {alpha:0}, 1.5, {startDelay:1, ease:FlxEase.cubeOut});
                    if (FlxG.sound.music != null)
                        FlxTween.tween(FlxG.sound.music, {pitch:0, volume:0}, 2.5, {ease:FlxEase.cubeOut});
                    FlxTween.tween(FlxG.camera, {zoom:0.1, angle:-15}, 2.5, {ease:FlxEase.cubeIn, onComplete: function(t) {
                        FlxG.camera.angle = 0;
                        openSubState(new options.SuperSecretDebugMenu());
                    }});
                }
            }
        }
    }

    function changeSelection(change:Int = 0)
    {
        curSelected += change;
        if (curSelected < 0) curSelected = options.length - 1;
        if (curSelected >= options.length) curSelected = 0;

        var bullShit:Int = 0;
        for (item in grpOptions.members)
        {
            item.targetY = bullShit - curSelected;
            bullShit++;
            item.alpha = 0.6;
            var thing:Float = 0;
            if (item.targetY == 0)
            {
                item.alpha = 1;
                if (grpOptions.members.length > 4) thing = grpOptions.members.length * 8;
                selectorLeft.x = item.x - 63;
                selectorLeft.y = item.y;
                selectorRight.x = item.x + item.width + 15;
                selectorRight.y = item.y;
            }
        }
        camFollow.setPosition(FlxG.width / 2, (curSelected * (grpOptions.members.length * 10)));
        FlxG.sound.play(Paths.sound('scrollMenu'));
    }

    function checkKonamiCode():Bool
    {
        if (konamiCode[konamiIndex].justPressed)
        {
            konamiIndex++;
            if (konamiIndex > 6) isEnteringKonamiCode = true;
            if (konamiIndex >= konamiCode.length)
            {
                konamiIndex = 0;
                return true;
            }
        }
        else
        {
            konamiIndex = 0;
            isEnteringKonamiCode = false;
        }
        return false;
    }
}
