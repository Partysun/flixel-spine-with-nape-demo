package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;

import flixel.addons.nape.FlxNapeSpace;
import flixel.addons.nape.FlxNapeSprite;
import flixel.addons.editors.spine.FlxSpine;

import spinehaxe.animation.Animation;


class PlayState extends BaseState
{
    var hero:Creature;

    /**
     * Function that is called up when to state is created to set it up.
     */
    override public function create():Void
    {
        super.create();
		FlxNapeSpace.init();
		FlxNapeSpace.space.gravity.setxy(0, 500);
        FlxNapeSpace.drawDebug = true;

        FlxG.camera.bgColor = FlxColor.WHITE;

        //add out hero
        hero = new Creature(300, 450);
        var walkEntry = hero.state.setAnimationByName(0, "walk", true);
        walkEntry.timeScale = 1.0;
        add(hero);

        //draw a ground
        var ground_offset:Int = 15;
        var ground_offset_y:Float = .1;
        var ground_height:Int = 2;
        var ground_color:FlxColor = 0x88000000;
        var ground = new FlxSprite(ground_offset, FlxG.height - FlxG.height * ground_offset_y - ground_height * .5);
        ground.makeGraphic(FlxG.width - ground_offset * 2, ground_height, ground_color);
        ground.immovable = true;
        add(ground);
        hero.y = FlxG.height - FlxG.height * ground_offset_y - ground_height * .5;

        //add some boxes
        for (i in 0...20)
            add(createBox(10 + Math.random() * 48, 100));

        //create physysic walls
		FlxNapeSpace.createWalls(20, 20, 940, FlxG.height - FlxG.height * ground_offset_y - ground_height * .5);
    }

    //helper for create a simple physic box
    private function createBox(x:Float, y:Float):FlxNapeSprite
    {
        var box = new FlxNapeSprite(x, y, "assets/images/box.png");
        box.antialiasing = true;
        box.setBodyMaterial(1, .2, .4, .5);
        return box;
    }

    /**
     * Function that is called once every frame.
     */
    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        #if !FLX_NO_KEYBOARD
        if (FlxG.keys.justPressed.SPACE)
        {
            hero.state.setAnimation(0, getNextAnimation(hero), true);
        }
        if (FlxG.keys.justPressed.X)
        { 
            FlxG.camera.zoom += 0.1;
        }
        else if (FlxG.keys.justPressed.Z)
        {
            FlxG.camera.zoom -= 0.1;
        }
        if (FlxG.keys.anyPressed([W, UP]))
        {
            hero.state.timeScale += 0.1;
        }
        else if (FlxG.keys.anyPressed([S, DOWN]))
        {
            hero.state.timeScale -= 0.1;
        }
        if (FlxG.keys.anyPressed([D, RIGHT]))
        {
            hero.skeleton.flipX = false;
        }
        else if (FlxG.keys.anyPressed([A, LEFT]))
        {
            hero.skeleton.flipX = true;
        }
        #end

        #if !FLX_NO_TOUCH

        for (swipe in FlxG.swipes)
        {
            if (swipe.distance > 100)
            {
                // Vertical long swipe up or down resets game state
                if ((swipe.angle < 10 && swipe.angle > -10) || (swipe.angle > 170 || swipe.angle < -170))
                {
                    FlxG.resetState();
                    break;
                }
                // Horizontal swipe change hero's animation
                if ((swipe.angle < 0 || swipe.angle > 0))
                {
                    hero.state.setAnimation(0, getNextAnimation(hero), true);
                }
            }
        }
	    #end
    }

    /**
     * Helper methods for get next animation of Spine object
     */
    public static function getNextAnimation(spine:FlxSpine):Animation {
        var animations:Array<Animation> = spine.skeleton.data.animations;
        var current_animation:Animation = null;
        if (spine.state.tracks[0] != null)
            current_animation = spine.state.tracks[0].animation;
        else
            current_animation = getFirstAnimation(spine);
        var index_of_current_animation = spine.skeleton.data.animations.indexOf(current_animation);
        var next_animation:Animation = null;
        var next_animation_index = 0;
        while (current_animation != next_animation) {
            next_animation_index = index_of_current_animation + 1;
            if (next_animation_index >= spine.skeleton.data.animations.length) {
                next_animation_index = 0;
            }
            next_animation = spine.skeleton.data.animations[next_animation_index];
            if (next_animation.timelines.length != 0) {
                return next_animation;
            }
            else
                index_of_current_animation = next_animation_index;
        }
        //If we have only one animation with timelines
        return current_animation;
    }

    private static function getFirstAnimation(spine:FlxSpine):Animation
    {
        var animations:Array<Animation> = spine.skeleton.data.animations;
        for (animation in animations) {
            if (isRealAnimation(animation))
                return animation;
        }
        throw "First animation not found";
        return null;
    }

    private static function isRealAnimation(animation:Animation):Bool
    {
        return animation.timelines.length != 0;
    }

}
