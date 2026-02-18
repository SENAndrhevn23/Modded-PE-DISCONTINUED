package mikolka.vslice;

// Minimal preloader that immediately starts the game.
// Keeps the same class name so it replaces the existing preloader.
class FunkinPreloader extends flixel.system.FlxBasePreloader
{
    public function new()
    {
        // match original constructor signature (0.0) to avoid surprises
        super(0.0);
    }

    override function create():Void
    {
        // call base create to ensure Flixel/Lime internals are initialized
        super.create();

        // Immediately mark loaded and start the game
        immediatelyStartGame();
    }

    override function update(percent:Float):Void
    {
        // Keep forcing loaded so nothing in the original update logic stalls launch
        if (!_loaded) immediatelyStartGame();

        // Optionally call base update with 100% so any internal logging behaves normally
        super.update(1.0);
    }

    override function onLoaded():Void
    {
        // Lime/HTML5 may call this when initial downloads finish — treat it as finished.
        _loaded = true;
        super.onLoaded();

        // Make 100% sure the game starts.
        immediatelyStartGame();
    }

    // Keep the same helper name used in original file for safety
    function immediatelyStartGame():Void
    {
        _loaded = true;
    }

    override function destroy():Void
    {
        // No UI resources here, but call base destroy to be safe.
        super.destroy();
    }
}
