package states;

class OutdatedState extends MusicBeatState
{
    // Mark as already left so nothing triggers
    public static var leftState:Bool = true;

    override function create()
    {
        super.create();
        // Immediately switch to main menu
        MusicBeatState.switchState(new MainMenuState());
    }

    override function update(elapsed:Float)
    {
        // Do nothing; no warnings, no buttons, no tweens
    }
}
