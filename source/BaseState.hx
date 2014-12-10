package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.util.FlxColor;
import flixel.addons.nape.FlxNapeSpace;
import openfl.display.FPS;

class BaseState extends FlxState
{
    var fps:FPS;

    override public function create():Void
    {
        #if !FLX_NO_MOUSE
        FlxG.mouse.visible = false;
        #end
        FlxG.addChildBelowMouse(fps = new FPS(FlxG.width - 60, 5, FlxColor.BLACK));
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        #if !FLX_NO_KEYBOARD
        if (FlxG.keys.justPressed.TAB)
        {
            FlxG.debugger.drawDebug = !FlxG.debugger.drawDebug;
            FlxNapeSpace.drawDebug = !FlxNapeSpace.drawDebug;
        }

        if (FlxG.keys.justPressed.R)
            FlxG.resetState();
        #end
    }

    override public function destroy():Void
    {
        super.destroy();

        if (fps != null)
          FlxG.removeChild(fps);
    }
}
