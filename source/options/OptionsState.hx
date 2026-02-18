package options;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxCamera;
import flixel.math.FlxMath;

class OptionsState extends FlxSubState
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
    private var selectorLeft:FlxText;
    private var selectorRight:FlxText;

    private var camFollow:FlxObject;
    private var camFollowPos:FlxObject;
    private var subCamera:FlxCamera;
    private var otherCamera:FlxCamera;

    // --- Open SubState ---
    function openSelectedSubstate(label:String)
    {
        switch(label)
        {
            case 'Note Colors': trace("Open NotesColorSubState");
            case 'Controls': trace("Open ControlsSubState");
            case 'Graphics': trace("Open GraphicsSettingsSubState");
            case 'Visuals': trace("Open VisualsSettingsSubState");
            case 'Gameplay': trace("Open GameplaySettingsSubState");
            case 'Adjust Delay and Combo': trace("Open NoteOffsetState");
            case 'Video Rendering': trace("Open GameRendererSettingsSubState");
            case 'Optimizations': trace("Open OptimizeSettingsSubState");
            case 'V-Slice Options': trace("Open BaseGameSubState");
        }
    }

    override function create()
    {
        super.create();

        // --- Cameras ---
        subCamera = new FlxCamera();
        otherCamera = new FlxCamera();
        subCamera.bgColor.alpha = 0;
        otherCamera.bgColor.alpha = 0;

        FlxG.cameras.add(subCamera, false);
        FlxG.cameras.add(otherCamera, false);

        camFollow = new FlxObject(0, 0, 1, 1);
        camFollowPos = new FlxObject(0, 0, 1, 1);
        add(camFollow);
        add(camFollowPos);
        subCamera.follow(camFollowPos);

        // --- Background ---
        var bg:FlxSprite = new FlxSprite();
        bg.makeGraphic(FlxG.width, FlxG.height, 0xFF222222);
        bg.scrollFactor.set(0, 0);
        bg.screenCenter();
        add(bg);

        // --- Options ---
        grpOptions = new FlxGroup();
        add(grpOptions);

        for (i in 0...options.length)
        {
            var optionText:FlxText = new FlxText(0, 0, 300, options[i]);
            optionText.screenCenter();
            optionText.y += 50 + i * 30;
            grpOptions.add(optionText);
        }

        // --- Selector ---
        selectorLeft = new FlxText(0, 0, 20, ">");
        selectorRight = new FlxText(0, 0, 20, "<");
        add(selectorLeft);
        add(selectorRight);

        changeSelection();
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (FlxG.keys.justPressed.UP) changeSelection(-1);
        if (FlxG.keys.justPressed.DOWN) changeSelection(1);

        // Smooth camera
        var lerpVal:Float = Math.min(Math.max(elapsed * 7.5, 0), 1);
        camFollowPos.setPosition(
            FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal),
            FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal)
        );

        if (FlxG.keys.justPressed.ENTER) openSelectedSubstate(options[curSelected]);
        if (FlxG.keys.justPressed.ESCAPE)
        {
            trace("Back pressed - closing options");
            closeSubState();
        }
    }

    function changeSelection(change:Int = 0)
    {
        curSelected += change;
        if (curSelected < 0) curSelected = options.length - 1;
        if (curSelected >= options.length) curSelected = 0;

        for (i in 0...grpOptions.members.length)
        {
            var item:FlxText = cast grpOptions.members[i];
            var yPos:Int = Std.int((FlxG.height/2) + (i - curSelected) * 90);
            item.y = yPos;
            item.alpha = (i == curSelected) ? 1 : 0.6;

            if (i == curSelected)
            {
                selectorLeft.x = item.x - 40;
                selectorLeft.y = item.y;
                selectorRight.x = item.x + item.width + 15;
                selectorRight.y = item.y;
            }
        }

        camFollow.setPosition(FlxG.width/2, curSelected * 90);
    }
}
