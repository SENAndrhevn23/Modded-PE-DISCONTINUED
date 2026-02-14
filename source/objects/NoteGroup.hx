package objects;

import objects.Note.CastNote;

class NoteGroup extends FlxTypedGroup<Note>
{
    var pool:Array<Note> = [];
    var poolAvail:Array<Bool> = [];
    var _ecyc_e:Note;
    var living:Int = 0;

    public function new() {
        super();
    }

    public function push(n:Note) {
        pool.push(n);
    }

    public function spawnNote(castNote:CastNote, ?oldNote:Note) {
        if (pool.length > 0) {
            _ecyc_e = pool.pop();
            _ecyc_e.exists = true;
        } else {
            _ecyc_e = null;
            _ecyc_e = new Note();
            members.push(_ecyc_e);
            ++length;
        }
        return _ecyc_e.recycleNote(castNote, oldNote);
    }

    public function debugInfo():Array<Float> {
        living = 0;
        for (obj in pool) if (obj != null) ++living;

        return [living, length, living * 100.0 / Math.max(length, 1), poolAvail.length];
    }
}