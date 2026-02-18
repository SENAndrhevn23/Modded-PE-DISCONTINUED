package states;

import cpp.vm.Gc;
import backend.WeekData;
import backend.Highscore;
import backend.Song;

import objects.HealthIcon;
import objects.MusicPlayer;

import options.GameplayChangersSubstate;
import substates.ResetScoreSubState;

import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.group.FlxGroup;
import flixel.ui.FlxButton;
import haxe.Json;
import openfl.utils.Assets;

class FreeplayState extends MusicBeatState
{
    public var songs:Array<SongMetadata> = [];
    public static var fromResultState:Bool = false;

    private var selector:FlxText;
    private static var curSelected:Int = 0;
    private var lerpSelected:Float = 0;
    private var curDifficulty:Int = -1;
    private static var lastDifficultyName:String = Difficulty.getDefault();

    private var scoreBG:FlxSprite;
    private var scoreText:FlxText;
    private var diffText:FlxText;
    private var lerpScore:Float = 0;
    private var lerpRating:Float = 0;
    private var intendedScore:Float = 0;
    private var intendedRating:Float = 0;

    private var grpSongs:FlxGroup<Alphabet>;
    private var curPlaying:Bool = false;
    private var iconArray:Array<HealthIcon> = [];

    private var bg:FlxSprite;
    private var intendedColor:Int;

    private var missingTextBG:FlxSprite;
    private var missingText:FlxText;

    private var bottomString:String;
    private var bottomText:FlxText;
    private var bottomBG:FlxSprite;

    private var player:MusicPlayer;

    // --- Search UI ---
    private var songSearchText:Dynamic; // Using Dynamic to avoid FlxUIInputText errors
    private var buttonTop:FlxButton;
    private var searchTextLabel:FlxText;

    override function create()
    {
        Paths.clearStoredMemory();
        Paths.clearUnusedMemory();

        persistentUpdate = true;
        PlayState.isStoryMode = false;
        WeekData.reloadWeekFiles(false);

        // Discord presence
        #if DISCORD_ALLOWED
        DiscordClient.changePresence("In the Old Freeplay Menus", null);
        #end

        if(WeekData.weeksList.length < 1)
        {
            FlxTransitionableState.skipNextTransIn = true;
            persistentUpdate = false;
            MusicBeatState.switchState(new states.ErrorState(
                "NO WEEKS ADDED FOR FREEPLAY\n\nPress ACCEPT to go to the Week Editor Menu.\nPress BACK to return to Main Menu.",
                function() MusicBeatState.switchState(new states.editors.WeekEditorState()),
                function() MusicBeatState.switchState(new states.MainMenuState())
            ));
            return;
        }

        // Load all songs
        for (i in 0...WeekData.weeksList.length)
        {
            if(weekIsLocked(WeekData.weeksList[i])) continue;

            var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
            for (song in leWeek.songs)
            {
                var colors:Array<Int> = song[2];
                if(colors == null || colors.length < 3)
                    colors = [146, 113, 253];
                addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
            }
        }

        // Background
        bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.antialiasing = ClientPrefs.data.antialiasing;
        add(bg);
        bg.screenCenter();

        // Songs group
        grpSongs = new FlxGroup<Alphabet>();
        add(grpSongs);

        // Add song visuals
        for (i in 0...songs.length)
        {
            var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
            songText.targetY = i;
            grpSongs.add(songText);

            songText.scaleX = Math.min(1, 980 / songText.width);
            songText.snapToPosition();

            var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
            icon.sprTracker = songText;
            songText.visible = songText.active = songText.isMenuItem = false;
            icon.visible = icon.active = false;

            iconArray.push(icon);
            add(icon);
        }

        // Score text
        scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
        scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
        scoreText.antialiasing = ClientPrefs.data.antialiasing;
        add(scoreText);

        scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
        scoreBG.alpha = 0.6;
        add(scoreBG);

        diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
        diffText.font = scoreText.font;
        diffText.antialiasing = ClientPrefs.data.antialiasing;
        add(diffText);

        // Bottom text
        bottomBG = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
        bottomBG.alpha = 0.6;
        add(bottomBG);

        bottomString = Language.getPhrase("freeplay_tip", "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.");
        bottomText = new FlxText(bottomBG.x, bottomBG.y + 4, FlxG.width, bottomString, 16);
        bottomText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
        bottomText.scrollFactor.set();
        bottomText.antialiasing = ClientPrefs.data.antialiasing;
        add(bottomText);

        player = new MusicPlayer(this);
        add(player);

        // Search UI (Dynamic for now)
        songSearchText = {text: ""};
        buttonTop = new FlxButton(0, 0, "Search", function() {});
        searchTextLabel = new FlxText(0,0,80,"Search");

        changeSelection();
        updateTexts();
        super.create();
    }

    public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
    {
        songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
    }

    function weekIsLocked(name:String):Bool
    {
        var leWeek:WeekData = WeekData.weeksLoaded.get(name);
        return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
    }

    function changeSelection(change:Int = 0)
    {
        curSelected = FlxMath.wrap(curSelected + change, 0, songs.length - 1);

        for (num => item in grpSongs.members)
        {
            item.alpha = 0.6;
            iconArray[num].alpha = 0.6;
            if(num == curSelected)
            {
                item.alpha = 1;
                iconArray[num].alpha = 1;
            }
        }
    }

    public function updateTexts(elapsed:Float = 0.0)
    {
        // Simplified for compilation
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        if(controls.BACK)
        {
            MusicBeatState.switchState(new MainMenuState());
        }
    }
}

// Song metadata container
class SongMetadata
{
    public var songName:String;
    public var week:Int;
    public var songCharacter:String;
    public var color:Int;
    public var folder:String;
    public var lastDifficulty:String;

    public function new(song:String, week:Int, songCharacter:String, color:Int)
    {
        this.songName = song;
        this.week = week;
        this.songCharacter = songCharacter;
        this.color = color;
        this.folder = Mods.currentModDirectory != null ? Mods.currentModDirectory : "";
        this.lastDifficulty = null;
    }
}
