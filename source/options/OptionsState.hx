package options;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;

class OptionsState extends MusicBeatState
{
    public static var onPlayState:Bool = false;

    // Options list
    var options:Array<String> = [
        'Note Colors',
        'Controls',
        'Adjust Delay and Combo',
        'Graphics',
        'Visuals',
        'Gameplay',
        'Video Rendering',
        'Optimizations',
        'V-Slice Options'
    ];

    // Group for menu items
    private var grpOptions:FlxGroup;

    // Selector arrows
    private var selectorLeft:Alphabet;
    private var selectorRight:Alphabet;

    // Smooth scroll objects
    private var camFollow:FlxObject;
    private var camFollowPos:FlxObject;

    // Current selection index
    private static var curSelected:Int = 0;

    // ---------- Substate logic ----------
    function openSelectedSubstate(label:String)
    {
        switch(label)
        {
            case 'Note Colors': openSubState(new options.NotesColorSubState());
            case 'Controls': openSubState(new options.ControlsSubState());
            case 'Adjust Delay and Combo': openSubState(new options.NoteOffsetState());
            case 'Graphics': openSubState(new options.GraphicsSettingsSubState());
            case 'Visuals': openSubState(new options.VisualsSettingsSubState());
            case 'Gameplay': openSubState(new options.GameplaySettingsSubState());
            case 'Video Rendering': openSubState(new options.GameRendererSettingsSubState());
            case 'Optimizations': openSubState(new options.OptimizeSettingsSubState());
            case 'V-Slice Options': openSubState(new options.BaseGameSubState());
        }
    }

    // ---------- Create ----------
    override function create()
    {
        super.create();

        // Cameras
        camFollow = new FlxObject(0, 0, 1, 1);
        camFollowPos = new FlxObject(0, 0, 1, 1);
        add(camFollow);
        add(camFollowPos);

        // Background
        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF222222);
        bg.scrollFactor.set(0, 0);
        bg.screenCenter();
        bg.antialiasing = true;
        add(bg);

        // Options group
        grpOptions = new FlxGroup();
        add(grpOptions);

        var startY:Float = FlxG.height / 2;
        for (i in 0...options.length)
        {
            var optionText:Alphabet = new Alphabet(0, 0, options[i], true);
            optionText.screenCenter();
            optionText.y = startY + (i - options.length/2) * 90;
            optionText.targetY = optionText.y;
            grpOptions.add(optionText);
        }

        // Selector arrows
        selectorLeft = new Alphabet(0, 0, '>', true);
        add(selectorLeft);
        selectorRight = new Alphabet(0, 0, '<', true);
        add(selectorRight);

        // Initial selection
        changeSelection();
    }

    // ---------- Update ----------
    override function update(elapsed:Float)
    {
        super.update(elapsed);

        // Selection input
        if (controls.UI_UP_P) changeSelection(-1);
        if (controls.UI_DOWN_P) changeSelection(1);

        if (controls.ACCEPT) openSelectedSubstate(options[curSelected]);
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

        // Smooth scrolling
        var lerpVal:Float = Math.min(Math.max(elapsed * 7.5, 0), 1);
        camFollowPos.setPosition(
            FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal),
            FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal)
        );
    }

    // ---------- Change selection ----------
    function changeSelection(change:Int = 0)
    {
        curSelected += change;
        if (curSelected < 0) curSelected = options.length - 1;
        if (curSelected >= options.length) curSelected = 0;

        for (i in 0...grpOptions.members.length)
        {
            var item:Alphabet = cast grpOptions.members[i];
            item.targetY = (FlxG.height/2) + (i - curSelected) * 90;
            item.alpha = if (i == curSelected) 1 else 0.6;

            if (i == curSelected)
            {
                selectorLeft.x = item.x - 63;
                selectorLeft.y = item.y;
                selectorRight.x = item.x + item.width + 15;
                selectorRight.y = item.y;
            }
        }

        camFollow.setPosition(FlxG.width / 2, curSelected * 90);
        FlxG.sound.play(Paths.sound('scrollMenu'));
    }
}
