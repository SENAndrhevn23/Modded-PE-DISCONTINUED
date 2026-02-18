package options;

import flixel.FlxG;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.text.FlxText;

class OptionsState extends FlxState
{
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
    private var mainCamera:FlxCamera;
    private var subCamera:FlxCamera;
    private var otherCamera:FlxCamera;
    private var camFollow:FlxObject;
    private var camFollowPos:FlxObject;

    var selectorLeft:FlxText;
    var selectorRight:FlxText;

    function openSelectedSubstate(label:String)
    {
        switch(label)
        {
            case 'Note Colors': openSubState(new NotesColorSubState());
            case 'Controls': openSubState(new ControlsSubState());
            case 'Adjust Delay and Combo': openSubState(new NoteOffsetState());
            case 'Video Rendering': openSubState(new GameRendererSettingsSubState());
            case 'Optimizations': openSubState(new OptimizeSettingsSubState());
            case 'Graphics': openSubState(new GraphicsSettingsSubState());
            case 'Visuals': openSubState(new VisualsSettingsSubState());
            case 'Gameplay': openSubState(new GameplaySettingsSubState());
            case 'V-Slice Options': openSubState(new BaseGameSubState());
        }
    }

    override function create()
    {
        super.create();

        mainCamera = new FlxCamera();
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
        FlxG.cameras.list[0].follow(camFollowPos);

        // Background
        var bg:FlxSprite = new FlxSprite();
        bg.makeGraphic(FlxG.width, FlxG.height, 0xFF222222);
        bg.scrollFactor.set(0, 0);
        bg.screenCenter();
        bg.antialiasing = true;
        add(bg);

        // Options
        grpOptions = new FlxGroup();
        add(grpOptions);

        for (i in 0...options.length)
        {
            var optionText:FlxText = new FlxText(0, 0, 200, options[i]);
            optionText.screenCenter();
            optionText.y += 50 + i * 30;
            optionText.scrollFactor.set(0, 0.2);
            grpOptions.add(optionText);
        }

        selectorLeft = new FlxText(0, 0, 20, ">");
        selectorRight = new FlxText(0, 0, 20, "<");
        add(selectorLeft);
        add(selectorRight);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        var lerpVal:Float = Math.min(Math.max(elapsed * 7.5, 0), 1);
        camFollowPos.setPosition(
            FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal),
            FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal)
        );
    }
}
