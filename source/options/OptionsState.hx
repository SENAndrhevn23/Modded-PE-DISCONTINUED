package options;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.group.FlxGroup;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class OptionsState extends FlxState
{
    // REQUIRED by other files
    public static var onPlayState:Bool = false;

    var curSelected:Int = 0;

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
    private var camFollow:FlxObject;
    private var camFollowPos:FlxObject;

    var selectorLeft:FlxText;
    var selectorRight:FlxText;

    override function create()
    {
        super.create();

        camFollow = new FlxObject(0, 0, 1, 1);
        camFollowPos = new FlxObject(0, 0, 1, 1);
        add(camFollow);
        add(camFollowPos);
        FlxG.camera.follow(camFollowPos);

        var bg = new FlxSprite();
        bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(30, 30, 30));
        bg.scrollFactor.set();
        bg.screenCenter();
        add(bg);

        grpOptions = new FlxGroup();
        add(grpOptions);

        for (i in 0...options.length)
        {
            var txt = new FlxText(0, 0, 0, options[i], 16);
            txt.screenCenter(X);
            txt.y = 80 + i * 32;
            txt.ID = i;
            grpOptions.add(txt);
        }

        selectorLeft = new FlxText(0, 0, 20, ">");
        selectorRight = new FlxText(0, 0, 20, "<");
        add(selectorLeft);
        add(selectorRight);

        changeSelection(0);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (FlxG.keys.justPressed.UP)
            changeSelection(-1);

        if (FlxG.keys.justPressed.DOWN)
            changeSelection(1);

        if (FlxG.keys.justPressed.ENTER)
            openSelected();

        if (FlxG.keys.justPressed.ESCAPE)
        {
            OptionsState.onPlayState = false;
            FlxG.switchState(new MainMenuState());
        }

        var lerp = FlxMath.bound(elapsed * 8, 0, 1);
        camFollowPos.setPosition(
            FlxMath.lerp(camFollowPos.x, camFollow.x, lerp),
            FlxMath.lerp(camFollowPos.y, camFollow.y, lerp)
        );
    }

    function changeSelection(change:Int)
    {
        curSelected += change;

        if (curSelected < 0)
            curSelected = options.length - 1;
        if (curSelected >= options.length)
            curSelected = 0;

        for (item in grpOptions.members)
        {
            var txt:FlxText = cast item;
            if (txt == null) continue;

            txt.color = (txt.ID == curSelected) ? FlxColor.YELLOW : FlxColor.WHITE;

            if (txt.ID == curSelected)
            {
                camFollow.setPosition(txt.x, txt.y);
                selectorLeft.setPosition(txt.x - 20, txt.y);
                selectorRight.setPosition(txt.x + txt.width + 4, txt.y);
            }
        }
    }

    function openSelected()
    {
        switch (options[curSelected])
        {
            case 'Note Colors':
                openSubState(new NotesColorSubState());

            case 'Controls':
                openSubState(new ControlsSubState());

            // ❗ MUST be switchState (NOT a substate)
            case 'Adjust Delay and Combo':
                OptionsState.onPlayState = true;
                FlxG.switchState(new NoteOffsetState());

            case 'Video Rendering':
                openSubState(new GameRendererSettingsSubState());

            case 'Optimizations':
                openSubState(new OptimizeSettingsSubState());

            case 'Graphics':
                openSubState(new GraphicsSettingsSubState());

            case 'Visuals':
                openSubState(new VisualsSettingsSubState());

            case 'Gameplay':
                openSubState(new GameplaySettingsSubState());

            case 'V-Slice Options':
                openSubState(new BaseGameSubState());
        }
    }
}
