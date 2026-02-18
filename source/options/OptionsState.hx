package options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.FlxObject;
import states.MainMenuState;
import backend.StageData;

class OptionsState extends MusicBeatState
{
    public static var onPlayState:Bool = false;
    private static var curSelected:Int = 0;

    var options:Array<String> = [
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
    var selectorLeft:Alphabet;
    var selectorRight:Alphabet;
    var camFollow:FlxObject;
    var camFollowPos:FlxObject;

    function openSelectedSubstate(label:String)
    {
        switch(label)
        {
            case 'Note Colors': openSubState(new options.NotesColorSubState());
            case 'Controls': openSubState(new options.ControlsSubState());
            case 'Adjust Delay and Combo': openSubState(new options.NoteOffsetState());
            case 'Video Rendering': openSubState(new options.GameRendererSettingsSubState());
            case 'Optimizations': openSubState(new options.OptimizeSettingsSubState());
            case 'Graphics': openSubState(new options.GraphicsSettingsSubState());
            case 'Visuals': openSubState(new options.VisualsSettingsSubState());
            case 'Gameplay': openSubState(new options.GameplaySettingsSubState());
            case 'V-Slice Options': openSubState(new options.BaseGameSubState());
        }
    }

    override function create()
    {
        super.create();

        camFollow = new FlxObject(0, 0, 1, 1);
        camFollowPos = new FlxObject(0, 0, 1, 1);
        add(camFollow);
        add(camFollowPos);

        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.color = 0xFFea71fd;
        bg.updateHitbox();
        bg.scrollFactor.set(0, 0);
        bg.screenCenter();
        add(bg);

        grpOptions = new FlxGroup();
        add(grpOptions);

        for (i in 0...options.length)
        {
            var optionText:Alphabet = new Alphabet(0, 0, options[i], true);
            optionText.screenCenter();
            optionText.y += (100 * (i - (options.length / 2))) + 50;
            optionText.targetY = Std.int(optionText.y);
            grpOptions.add(optionText);
        }

        selectorLeft = new Alphabet(0, 0, '>', true);
        selectorRight = new Alphabet(0, 0, '<', true);
        add(selectorLeft);
        add(selectorRight);

        changeSelection();
        ClientPrefs.saveSettings();
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (controls.UI_UP_P) changeSelection(-1);
        if (controls.UI_DOWN_P) changeSelection(1);

        var lerpVal:Float = Math.min(Math.max(elapsed * 7.5, 0), 1);
        camFollowPos.setPosition(
            FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal),
            FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal)
        );

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

        for (item in grpOptions.members)
        {
            item.y += (item.targetY - Std.int(item.y)) * 0.2;
        }
    }

    function changeSelection(change:Int = 0)
    {
        curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

        var idx:Int = 0;
        for (item in grpOptions.members)
        {
            item.targetY = 50 + 100 * (idx - curSelected);
            item.alpha = if (idx == curSelected) 1 else 0.6;

            if (idx == curSelected)
            {
                selectorLeft.x = item.x - 63;
                selectorLeft.y = item.y;
                selectorRight.x = item.x + item.width + 15;
                selectorRight.y = item.y;
            }
            idx++;
        }

        camFollow.setPosition(FlxG.width / 2, 50 + 100 * curSelected);
        FlxG.sound.play(Paths.sound('scrollMenu'));
    }
}
