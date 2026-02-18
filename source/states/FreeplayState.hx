package states;

import cpp.vm.Gc;
import backend.WeekData;
import backend.Highscore;
import backend.Song;

import objects.HealthIcon;
import objects.MusicPlayer;

import options.GameplayChangersSubstate;
import substates.ResetScoreSubState;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;
import flixel.FlxSound;
import flixel.ui.FlxButton;

import openfl.utils.Assets;
import haxe.Json;

class FreeplayState extends FlxState
{
    var songs:Array<SongMetadata> = [];
    public static var fromResultState:Bool = false;

    var selector:FlxText;
    private static var curSelected:Int = 0;
    var lerpSelected:Float = 0;
    var curDifficulty:Int = -1;
    private static var lastDifficultyName:String = "Easy";

    var scoreBG:FlxSprite;
    var scoreText:FlxText;
    var diffText:FlxText;
    var lerpScore:Float = 0;
    var lerpRating:Float = 0;
    var intendedScore:Float = 0;
    var intendedRating:Float = 0;

    private var grpSongs:FlxGroup;
    private var curPlaying:Bool = false;

    private var iconArray:Array<HealthIcon> = [];

    var bg:FlxSprite;
    var intendedColor:Int;

    var missingTextBG:FlxSprite;
    var missingText:FlxText;

    var bottomString:String;
    var bottomText:FlxText;
    var bottomBG:FlxSprite;

    var player:MusicPlayer;

    // Optional Search UI
    #if flixel_ui
    import flixel.addons.ui.FlxUIInputText;
    var songSearchText:FlxUIInputText;
    #end
    var buttonTop:FlxButton;
    var searchTextLabel:FlxText;

    override public function create():Void
    {
        super.create();

        // Clear memory
        Paths.clearStoredMemory();
        Paths.clearUnusedMemory();

        if(ClientPrefs.data.disableGC)
        {
            MemoryUtil.compact();
            MemoryUtil.disable();
        }

        persistentUpdate = true;

        // Load weeks
        WeekData.reloadWeekFiles(false);

        if(WeekData.weeksList.length < 1)
        {
            MusicBeatState.switchState(new states.ErrorState("NO WEEKS ADDED FOR FREEPLAY\n\nPress ACCEPT to go to the Week Editor Menu.\nPress BACK to return to Main Menu."));
            return;
        }

        // Add all songs from weeks
        for(i in 0...WeekData.weeksList.length)
        {
            var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
            if(!leWeek.startUnlocked) continue;

            for(song in leWeek.songs)
            {
                var colors:Array<Int> = song[2];
                if(colors == null || colors.length < 3) colors = [146,113,253];
                addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
            }
        }

        // Background
        bg = new FlxSprite().loadGraphic(Paths.image("menuDesat"));
        bg.antialiasing = ClientPrefs.data.antialiasing;
        add(bg);
        bg.screenCenter();

        // Song group
        grpSongs = new FlxGroup();
        add(grpSongs);

        // Add song visuals
        for(i in 0...songs.length)
        {
            var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
            songText.targetY = i;
            grpSongs.add(songText);

            var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
            icon.sprTracker = songText;
            songText.visible = false;
            icon.visible = false;
            iconArray.push(icon);
            add(icon);
        }

        // Score & Difficulty
        scoreText = new FlxText(FlxG.width*0.7, 5, 0, "", 32);
        scoreText.setFormat(Paths.font("vcr.ttf"),32,FlxColor.WHITE, FlxText.ALIGN_RIGHT);
        add(scoreText);

        scoreBG = new FlxSprite(scoreText.x-6,0).makeGraphic(1,66,0xFF000000);
        scoreBG.alpha = 0.6;
        add(scoreBG);

        diffText = new FlxText(scoreText.x, scoreText.y+36,0,"",24);
        diffText.setFormat(scoreText.font,24,FlxColor.WHITE);
        add(diffText);

        // Bottom UI
        bottomBG = new FlxSprite(0,FlxG.height-26).makeGraphic(FlxG.width,26,0xFF000000);
        bottomBG.alpha = 0.6;
        add(bottomBG);

        bottomString = "Press SPACE to listen to Song / CTRL for Gameplay Changers / RESET to Reset Score";
        bottomText = new FlxText(bottomBG.x,bottomBG.y+4,FlxG.width,bottomString,16);
        bottomText.setFormat(Paths.font("vcr.ttf"),16,FlxColor.WHITE,FlxText.ALIGN_CENTER);
        add(bottomText);

        // Player
        player = new MusicPlayer(this);
        add(player);

        // Optional search
        #if flixel_ui
        songSearchText = new FlxUIInputText(0, scoreBG.y+scoreBG.height+5,500,'',16);
        songSearchText.x = FlxG.width - songSearchText.width - 10;
        add(songSearchText);

        buttonTop = new FlxButton(0, songSearchText.y + songSearchText.height +5, "Search", function() {
            checkForSongsThatMatch(songSearchText.text);
        });
        add(buttonTop);
        #end

        // Initialize selection
        if(curSelected >= songs.length) curSelected = 0;
        bg.color = songs[curSelected].color;
        intendedColor = bg.color;
        lerpSelected = curSelected;
        curDifficulty = 0;

        super.create();
    }

    public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
    {
        songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
    }

    // Basic song selection & update loop
    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed*9.6));
    }

}

class SongMetadata
{
    public var songName:String;
    public var week:Int;
    public var songCharacter:String;
    public var color:Int;
    public var folder:String;
    public var lastDifficulty:String = null;

    public function new(song:String, week:Int, songCharacter:String, color:Int)
    {
        this.songName = song;
        this.week = week;
        this.songCharacter = songCharacter;
        this.color = color;
        this.folder = Mods.currentModDirectory != null ? Mods.currentModDirectory : "";
    }
}
