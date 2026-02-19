package options;

import states.MainMenuState;
import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.FlxObject;

class OptionsState extends MusicBeatState
{
    var options:Array<String> = [
        'Note Colors',
        'Controls',
        'Adjust Delay and Combo',
        'Graphics',
        'Visuals',
        'Gameplay',
        'V-Slice Options',
        'Video Rendering',
        'Optimizations'
    ];

    private var grpOptions:FlxGroup;
    private static var curSelected:Int = 0;
    public static var onPlayState:Bool = false;

    var selectorLeft:Alphabet;
    var selectorRight:Alphabet;
    var camFollow:FlxObject;
    var camFollowPos:FlxObject;

    function openSelectedSubstate(label:String) {
        switch(label) {
            case 'Note Colors': openSubState(new options.NotesColorSubState());
            case 'Controls': openSubState(new options.ControlsSubState());
            case 'Graphics': openSubState(new options.GraphicsSettingsSubState());
            case 'Visuals': openSubState(new options.VisualsSettingsSubState());
            case 'Gameplay': openSubState(new options.GameplaySettingsSubState());
            case 'Adjust Delay and Combo': MusicBeatState.switchState(new options.NoteOffsetState());
            case 'V-Slice Options': openSubState(new BaseGameSubState());
            case 'Video Rendering': openSubState(new options.GameRendererSettingsSubState());
            case 'Optimizations': openSubState(new options.OptimizeSettingsSubState());
        }
    }

    override function create()
    {
        super.create();

        // STATIC background, attached to default camera
        var bg:FlxSprite = new FlxSprite();
        bg.makeGraphic(FlxG.width, FlxG.height, 0xFF1E1E1E);
        bg.scrollFactor.set(0, 0);  // background will not move
        bg.cameras = [FlxG.cameras.list[0]];  // attach only to main camera
        add(bg);

        // Objects for menu scrolling
        camFollow = new FlxObject(FlxG.width / 2, FlxG.height / 2, 1, 1);
        camFollowPos = new FlxObject(camFollow.x, camFollow.y, 1, 1);
        add(camFollow);
        add(camFollowPos);

        // Options group (scrolling)
        grpOptions = new FlxGroup();
        add(grpOptions);

        for (i in 0...options.length) {
            var optionText:Alphabet = new Alphabet(0, 0, options[i], true);
            optionText.screenCenter();
            optionText.y += (80 * (i - (options.length / 2))) + 40;
            grpOptions.add(optionText);
        }

        // Selectors
        selectorLeft = new Alphabet(0, 0, '>', true);
        selectorRight = new Alphabet(0, 0, '<', true);
        add(selectorLeft);
        add(selectorRight);

        changeSelection();
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        // Smooth camera movement for options (does NOT affect background)
        var lerpVal:Float = Math.min(Math.max(elapsed * 7.5, 0), 1);
        camFollowPos.setPosition(
            camFollow.x,
            FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal)
        );

        if (controls.UI_UP_P) changeSelection(-1);
        if (controls.UI_DOWN_P) changeSelection(1);

        if (controls.BACK) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            MusicBeatState.switchState(new MainMenuState());
        } else if (controls.ACCEPT) {
            openSelectedSubstate(options[curSelected]);
        }
    }

    function changeSelection(change:Int = 0)
    {
        curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

        for (i in 0...grpOptions.members.length) {
            var item:Alphabet = cast grpOptions.members[i];
            item.alpha = 0.6;
            if (i == curSelected) {
                item.alpha = 1;
                selectorLeft.x = item.x - 50;
                selectorLeft.y = item.y;
                selectorRight.x = item.x + item.width + 10;
                selectorRight.y = item.y;

                camFollow.y = item.y;  // scroll options independently
            }
        }
        FlxG.sound.play(Paths.sound('scrollMenu'));
    }

    override function destroy()
    {
        ClientPrefs.loadPrefs();
        super.destroy();
    }
}
