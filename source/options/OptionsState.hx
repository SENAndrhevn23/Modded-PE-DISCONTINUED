package options;

import states.MainMenuState;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.group.FlxGroup;

class OptionsState extends MusicBeatState
{
    public static var onPlayState:Bool = false;
    private static var curSelected:Int = 0;

    private var options:Array<String> = [
        'Note Colors',
        'Controls',
        'Adjust Delay and Combo',
        'Video Rendering',
        'Optimizations',
        'Graphics',
        'Visuals',
        'Gameplay',
        'V-Slice Options'
    ];

    private var grpOptions:FlxGroup;
    private var selectorLeft:Alphabet;
    private var selectorRight:Alphabet;

    private var mainCam:FlxCamera;
    private var camFollow:FlxObject;
    private var camFollowPos:FlxObject;
    public static var funnyCam:FlxCamera;

    // ------------------------
    // Substate handling
    // ------------------------
    function openSelectedSubstate(label:String)
    {
        switch(label)
        {
            case 'Note Colors': openSubState(new options.NotesColorSubState());
            case 'Controls': openSubState(new options.ControlsSubState());
            case 'Graphics': openSubState(new options.GraphicsSettingsSubState());
            case 'Visuals': openSubState(new options.VisualsSettingsSubState());
            case 'Gameplay': openSubState(new options.GameplaySettingsSubState());
            case 'Adjust Delay and Combo': MusicBeatState.switchState(new options.NoteOffsetState());
            case 'Video Rendering': openSubState(new options.GameRendererSettingsSubState());
            case 'Optimizations': openSubState(new options.OptimizeSettingsSubState());
            case 'V-Slice Options': openSubState(new BaseGameSubState());
        }
    }

    // ------------------------
    // Initialization
    // ------------------------
    override function create()
    {
        super.create();

        // Cameras
        mainCam = initPsychCamera();
        funnyCam = new FlxCamera();
        funnyCam.bgColor.alpha = 0;
        FlxG.cameras.add(funnyCam, false);

        camFollow = new FlxObject(0, 0, 1, 1);
        camFollowPos = new FlxObject(0, 0, 1, 1);
        add(camFollow);
        add(camFollowPos);
        funnyCam.follow(camFollowPos);

        // Background (graphic, not plain grey)
        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.antialiasing = ClientPrefs.data.antialiasing;
        bg.color = 0xFFea71fd;
        bg.updateHitbox();
        bg.screenCenter();
        add(bg);

        // Options
        grpOptions = new FlxGroup();
        add(grpOptions);

        for (i in 0...options.length)
        {
            var optionText:Alphabet = new Alphabet(0, 0, options[i], true);
            optionText.setScale(0.75);
            optionText.screenCenter();
            optionText.y += (60 * (i - (options.length / 2))) + 30;
            grpOptions.add(optionText);
        }

        // Selector arrows
        selectorLeft = new Alphabet(0, 0, ">>>", true);
        selectorLeft.setScale(0.75);
        selectorRight = new Alphabet(0, 0, "<<<", true);
        selectorRight.setScale(0.75);
        add(selectorLeft);
        add(selectorRight);

        changeSelection();
        ClientPrefs.saveSettings();
    }

    // ------------------------
    // Update loop
    // ------------------------
    override function update(elapsed:Float)
    {
        super.update(elapsed);

        // Navigation
        if (controls.UI_UP_P) changeSelection(-1);
        if (controls.UI_DOWN_P) changeSelection(1);

        // Smooth camera follow
        var lerpVal:Float = Math.max(0, Math.min(1, elapsed * 7.5));
        camFollowPos.setPosition(FlxG.width / 2, FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

        // Accept / Back
        if (controls.BACK)
        {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            if (onPlayState)
            {
                StageData.loadDirectory(PlayState.SONG);
                LoadingState.loadAndSwitchState(new PlayState());
                FlxG.sound.music.volume = 0;
            }
            else MusicBeatState.switchState(new MainMenuState());
        }
        else if (controls.ACCEPT)
        {
            openSelectedSubstate(options[curSelected]);
        }
    }

    // ------------------------
    // Change selection
    // ------------------------
    function changeSelection(change:Int = 0)
    {
        curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

        for (i in 0...grpOptions.members.length)
        {
            var item:Alphabet = cast grpOptions.members[i];
            item.y = Std.int((FlxG.height / 2) + (i - curSelected) * 60);
            item.alpha = (i == curSelected) ? 1 : 0.6;

            if (i == curSelected)
            {
                selectorLeft.x = item.x - 140;
                selectorLeft.y = item.y + 7;
                selectorRight.x = item.x + item.width + 35;
                selectorRight.y = item.y + 7;

                camFollow.setPosition(FlxG.width / 2, item.y);
            }
        }

        FlxG.sound.play(Paths.sound('scrollMenu'), ClientPrefs.data.sfxVolume);
    }

    // ------------------------
    // Cleanup
    // ------------------------
    override function destroy()
    {
        ClientPrefs.loadPrefs();
        super.destroy();
    }
}
