package mikolka.compatibility;

import mikolka.vslice.components.crash.UserErrorSubstate;
import mikolka.vslice.freeplay.pslice.FreeplayColorTweener;
import mikolka.vslice.freeplay.pslice.BPMCache;
import mikolka.vslice.freeplay.FreeplayState;
import openfl.utils.AssetType;
import backend.Song;
import backend.Highscore;
import states.StoryMenuState;
import backend.WeekData;

class FreeplayHelpers {
	public static var BPM(get,set):Float;
	public static function set_BPM(value:Float) {
		Conductor.bpm = value;
		return value;
	}
	public static function get_BPM() {
		return Conductor.bpm;
	}

	static var songs = [];
	static var leWeek:WeekData;
	static var colors:Array<Int>;
	static var sngCard:FreeplaySongData;
	static var offset:Int;
	static var songCount:Int;
    public inline static function loadSongs(){
		songs = []; 
        songCount = offset = 0;
        WeekData.reloadWeekFiles(false);
		// programmatically adds the songs via LevelRegistry and SongRegistry
		for (week in WeekData.weeksList)
		{
			songCount += WeekData.weeksLoaded.get(week).songs.length;
		}
		for (i => week in WeekData.weeksList)
		{
			if (weekIsLocked(week))
				continue;

			leWeek = WeekData.weeksLoaded.get(week); // TODO tweak this
			
			WeekData.setDirectoryFromWeek(leWeek);
			for (j => song in leWeek.songs)
			{
				if (Main.isConsoleAvailable) Sys.stdout().writeString('\x1b[0GLoading Song (${j+offset+1}/$songCount)');
				colors = song[2];
				if (colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				sngCard = new FreeplaySongData(i, song[0], song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
				// songName, weekNum, songCharacter, color
				if (sngCard.songDifficulties.length == 0)
					continue;

				songs.push(sngCard);
			}
			offset += leWeek.songs.length;
		}
		Sys.print("\n");
        return songs;
    }
    public static function moveToPlaystate(state:FreeplayState,cap:FreeplaySongData,currentDifficulty:String,?targetInstId:String){
        // FunkinSound.emptyPartialQueue();

			// Paths.setCurrentLevel(cap.songData.levelId);
			state.persistentUpdate = false;
			Mods.currentModDirectory = cap.folder;

			var diffId = cap.loadAndGetDiffId();
			if (diffId == -1)
			{
				trace("SELECTED DIFFICULTY IS MISSING: " + currentDifficulty);
				diffId = 0;
			}
			if(targetInstId != null && targetInstId != "default"){
				var instPath = '${Paths.formatToSongPath(targetInstId)}/Inst.ogg';
				if(Paths.fileExists(instPath,AssetType.BINARY,false,"songs")){
					PlayState.altInstrumentals = targetInstId;
				}
				else{
					state.openSubState(new UserErrorSubstate("Missing instrumentals",
					'Couldn\'t find Inst in \nsongs/${instPath}\nMake sure that there is a Inst.ogg file'
					));
					return;
				}
			}
			else PlayState.altInstrumentals = null; //? P-Slice

			var songLowercase:String = Paths.formatToSongPath(cap.songId);
			var poop:String = Highscore.formatSong(songLowercase, diffId); // TODO //currentDifficulty);
			/*#if MODS_ALLOWED
				if(!FileSystem.exists(Paths.modsJson(songLowercase + '/' + poop)) && !FileSystem.exists(Paths.json(songLowercase + '/' + poop))) {
				#else
				if(!OpenFlAssets.exists(Paths.json(songLowercase + '/' + poop))) {
				#end
					poop = songLowercase;
					curDifficulty = 1;
					trace('Couldnt find file');
			}*/
			trace(poop);

			try
			{
				PlayState.SONG = Song.loadFromJson(poop, false, songLowercase);
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = diffId;

				trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
			}
			catch (e:Dynamic)
			{
				trace('ERROR! $e');
				state.openSubState(new UserErrorSubstate("Failed to load a song",
					'$e'
					));
                @:privateAccess{
                    state.busy = false;
                    state.letterSort.inputEnabled = true;
                }
				return;
			}
			LoadingState.loadAndSwitchState(new PlayState());

			FlxG.sound.music.volume = 0;

			#if (MODS_ALLOWED && DISCORD_ALLOWED)
			DiscordClient.loadModRPC();
			#end
    }

    static function weekIsLocked(name:String):Bool
        {
            var leWeek:WeekData = WeekData.weeksLoaded.get(name);
            return (!leWeek.startUnlocked
                && leWeek.weekBefore.length > 0
                && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
        }
	public static function exitFreeplay() {
		BPMCache.instance.clearCache();	
		Mods.loadTopMod();
		FlxG.signals.postStateSwitch.dispatch(); //? for the screenshot plugin to clean itself

		
	}
	public static function loadDiffsFromWeek(songData:FreeplaySongData){
		Mods.currentModDirectory = songData.folder;
		PlayState.storyWeek = songData.levelId; // TODO
		Difficulty.loadFromWeek();
	}
	public static function getDifficultyName() {
		return Difficulty.list[PlayState.storyDifficulty].toUpperCase();
	}

	public static function updateConductorSongTime(time:Float) {
		Conductor.songPosition = time;
	}
}