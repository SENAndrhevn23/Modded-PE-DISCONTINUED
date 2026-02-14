package objects;

enum PopupType {
    NONE;
    RATING;
    COMBO;
    NUMBER;
}

class Popup extends FlxSprite {
    public var type:PopupType;
    public var popUpTime:Float = 0;
    // static var comboDigit:Int = 0;
	var placement:Float = FlxG.width * 0.35;
    var i:PlayState;

    public function new() {
        super();
        type = NONE;
        i = PlayState.instance;
    }

    var texture:Popup;
    public function reloadTexture(target:String) {
        popUpTime = Conductor.songPosition;
        if (Paths.popUpFramesMap.exists(target)) {
            this.frames = Paths.popUpFramesMap.get(target);
            return this;
        } else {
            texture = cast { loadGraphic(Paths.image(target)); }
            Paths.popUpFramesMap.set(target, this.frames);
            return texture;
        }
    }

    // ╔═════════════════════╗
    // ║ RATING SPRITE STUFF ║
    // ╚═════════════════════╝

    public function setupRatingData(rateImg:String) {
        type = RATING;
        reloadTexture(rateImg);
        screenCenter();
        x = placement - 40;
        y -= 60;
        acceleration.y = 550;
        velocity.y -= FlxG.random.int(140, 175);
        velocity.x -= FlxG.random.int(0, 10);

        visible = (!ClientPrefs.data.hideHud && i.showRating);
        x += ClientPrefs.data.comboOffset[0];
        y -= ClientPrefs.data.comboOffset[1];
        antialiasing = i.antialias;
        
        setGraphicSize(Std.int(width * (PlayState.isPixelStage ? 0.85 * PlayState.daPixelZoom : 0.7)));
        updateHitbox();
    }

    public function ratingOtherStuff() {
        FlxTween.tween(this, {alpha: 0}, 0.2 / i.playbackRate, {
            onComplete: function(tween:FlxTween)
            {
                kill();
            },
            startDelay: 0.7 / i.playbackRate
        });
    }

    // ╔═════════════════════╗
    // ║ NUMBER SPRITE STUFF ║
    // ╚═════════════════════╝

    public function setupNumberData(numberImg:String, daloop:Int, tempNotes:Float) {
        // comboDigit = Std.string(Math.fround(Math.abs(tempNotes))).length;
        type = NUMBER;
        reloadTexture(numberImg);
        screenCenter();
        x = placement + (43 * daloop) - 90 + ClientPrefs.data.comboOffset[2] - 43/2 * (Std.string(tempNotes).length - 3);
        y += 75 - ClientPrefs.data.comboOffset[3];

        setGraphicSize(Std.int(width * (PlayState.isPixelStage ? PlayState.daPixelZoom : 0.5)));
        updateHitbox();

        acceleration.y = FlxG.random.int(200, 300);
        velocity.y -= FlxG.random.int(140, 160);
        velocity.x = FlxG.random.float(-5, 5);
        
        visible = !ClientPrefs.data.hideHud;
        antialiasing = i.antialias;
    }

    public function numberOtherStuff() {
        FlxTween.tween(this, {alpha: 0}, 0.2 / i.playbackRate, {
            onComplete: function(tween:FlxTween)
            {
                kill();
            },
            startDelay: 1.4 / i.playbackRate
        });
    }

    // ╔════════════════════╗
    // ║ COMBO SPRITE STUFF ║
    // ╚════════════════════╝

    public function setupComboData(comboImg:String) {
        type = COMBO;
        reloadTexture(comboImg);
        screenCenter();
        x = placement;
        acceleration.y = FlxG.random.int(200, 300);
        velocity.y -= FlxG.random.int(140, 160);
        velocity.x += FlxG.random.int(1, 10);
        visible = (!ClientPrefs.data.hideHud && i.showCombo);
        x += 75 + ClientPrefs.data.comboOffset[4];
        y += 60 - ClientPrefs.data.comboOffset[5];
        antialiasing = i.antialias;
        setGraphicSize(Std.int(width * (PlayState.isPixelStage ? 0.7 * PlayState.daPixelZoom : 0.55)));
        updateHitbox();
    }

    public function comboOtherStuff() {
        FlxTween.tween(this, {alpha: 0}, 0.2 / i.playbackRate, {
            onComplete: function(tween:FlxTween)
            {
                kill();
            },
            startDelay: 1.4 / i.playbackRate
        });
    }

    override public function kill() {
        type = NONE;
        super.kill();
    }

    override public function revive() {
        super.revive();
        initVars();
        acceleration.x = acceleration.y = velocity.x = velocity.y = x = y = 0;
        alpha = 1;
        visible = true;
    }
}