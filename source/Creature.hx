package;

import openfl.display.Graphics;

import flixel.addons.editors.spine.FlxSpine;
import flixel.addons.nape.FlxNapeSpace;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.math.FlxAngle;

import spinehaxe.SkeletonData;
import spinehaxe.attachments.BoundingBoxAttachment;
import spinehaxe.Slot;
import spinehaxe.SkeletonBounds;
import spinehaxe.Bone;

import nape.geom.Vec2;
import nape.geom.Vec2List;
import nape.geom.GeomPoly;
import nape.geom.GeomPolyList;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.Material;
import nape.shape.Polygon;
import nape.shape.Shape;
import nape.shape.ValidationResult;


class Creature extends FlxSpine {

    public var bounds:SkeletonBounds;
    public var material:Material = new Material(0.65, 0.57, 1.2, 1, 0);

    private var bodyOfBone:Map<Bone, Body> = new Map<Bone, Body>();
    private var currentFlipBone:Map<Bone, Flips> = new Map<Bone, Flips>();

    public function new(x:Int, y:Int, scale:Float = 0.25) {
        var skeletonData:SkeletonData = FlxSpine.readSkeletonData('spineboy', 'assets/skeletons/', scale);
        super(skeletonData, 0, 0);
        this.antialiasing = true;
        this.x = x;
        this.y = y;
        bounds = new SkeletonBounds();
        bodyOfBone = new Map<Bone, Body>();

        var slots:Array<Slot> = skeleton.slots;
        for (slot in slots) {
            var boundingBox:BoundingBoxAttachment = try cast(slot.attachment, BoundingBoxAttachment) catch(e:Dynamic) null;
            if (boundingBox == null)
                continue;
            var body:Body = new Body(BodyType.KINEMATIC, Vec2.weak(x, y));
            body.space = FlxNapeSpace.space;
            body.allowMovement = false;
            body.allowRotation = false;
            body = createShape(body, boundingBox.vertices);
            if (body != null)
            {
                bodyOfBone.set(slot.bone, body);
                currentFlipBone.set(slot.bone, {flipX: slot.bone.worldFlipX, flipY: slot.bone.worldFlipY});
            }
        }

    }

    /**
     * Create shapes from Spine Bounding Boxes
     */	
    public function createShape(body:Body, points:Array<Float>):Body
    {
        var shape:Shape = null;
        //TODO: organize structure for less Vec2Lists.
        var verts:Vec2List = new Vec2List();
        var vertsConcave:Vec2List = new Vec2List();

        var i:Int = 0;
        while(i < points.length) {
            var x:Float = points[i];
            var y:Float = points[i + 1];
                      verts.push(Vec2.weak(-x, y));
            vertsConcave.push(Vec2.weak(-x, y));
            i += 2;
        }

        var polygon:Polygon = new Polygon(verts, material);
        var validation:ValidationResult = polygon.validity();

        if (validation == ValidationResult.VALID)
        {
            shape = polygon;
            body.shapes.add(shape);
            return body;
        }
        else if (validation == ValidationResult.CONCAVE)
        {
            try{
                var concave:GeomPoly = new GeomPoly(vertsConcave);
                vertsConcave = null;
                var convex:GeomPolyList = concave.simplify(1.0).convexDecomposition();
                convex.foreach(function(p:GeomPoly):Void {
                    body.shapes.add(new Polygon(p));
                });  
                // Recycle list nodes
                convex.clear();
                // Recycle GeomPoly and its vertices
                concave.dispose();
            }catch(e:Dynamic){
                trace(e + "");
                return null;
            }
            return body;
        } 
        else throw "Invalid polygon/polyline";
        return null;
    }

    override public function update(elapsed:Float):Void
    {
        //recalculate bounding boxes (polygons)
        bounds.update(skeleton, true);

        for (bone in bodyOfBone.keys())
        {
            var x:Float = skeleton.x + bone.worldX;
            var y:Float = skeleton.y + bone.worldY;
            var rotation:Float = bone.worldRotation; 
            var body:Body = bodyOfBone.get(bone);

            body.position.setxy(x, y);
            var flipx:Int = bone.worldFlipX ? -1 : 1;
            var flipy:Int = bone.worldFlipY ? -1 : 1;
            if (bone.worldFlipX != currentFlipBone.get(bone).flipX)
            {
                currentFlipBone.get(bone).flipX = bone.worldFlipX;
                body.shapes.at(0).scale(1, flipy);
            }

            body.rotation = rotation * FlxAngle.TO_RAD;
        }
        
        super.update(elapsed);
    }

    override public function draw() {
        super.draw();
        #if !FLX_NO_DEBUG
        if(FlxG.debugger.drawDebug) drawDebugOnCamera(FlxG.camera);
        #end
    }

    #if !FLX_NO_DEBUG
    override public function drawDebugOnCamera(Camera:FlxCamera):Void
    {
        var gfx:Graphics = beginDrawDebug(FlxG.camera);
        gfx.clear();

        var skeletonX:Float = skeleton.x;
        var skeletonY:Float = skeleton.y;

        inline function line(x1, y1, x2, y2) {
            gfx.moveTo(x1, y1);
            gfx.lineTo(x2, y2);
        }

        // draw bones
        //gfx.lineStyle(1, 0xff0000);
        //for (bone in skeleton.bones) {
          //if (bone.parent == null) continue;
          //var x:Float = skeletonX + bone.data.length * bone.m00 + bone.worldX;
          //var y:Float = skeletonY + bone.data.length * bone.m10 + bone.worldY;
          //line(skeletonX + bone.worldX, skeletonY + bone.worldY, x, y);
        //}
        // draw min and max x/y for bounding polygons
        gfx.lineStyle(1, 0x00ff22);
        gfx.moveTo(bounds.minX, bounds.minY);
        gfx.lineTo(bounds.minX, bounds.maxY);
        gfx.lineTo(bounds.maxX, bounds.maxY);
        gfx.lineTo(bounds.maxX, bounds.minY);
        gfx.lineTo(bounds.minX, bounds.minY);
        
        //// draw bounding polygons
        gfx.beginFill(FlxColor.BLUE, .4);
        gfx.lineStyle(1, FlxColor.BLUE);
        for (polygon in bounds.polygons)
        {
            gfx.moveTo(polygon.vertices[0], polygon.vertices[1]);
            var i:Int = 0;
            while(i < polygon.vertices.length) {
                var x:Float = polygon.vertices[i];
                var y:Float = polygon.vertices[i + 1];
                gfx.lineTo(x, y);
                i += 2;
            }
        }
        gfx.endFill();

        // draw bones dots
        gfx.lineStyle(1, 0x00ff00);
        for (bone in skeleton.bones) {
            gfx.drawCircle(skeletonX + bone.worldX, skeletonY + bone.worldY, 3);
        }

        endDrawDebug(FlxG.camera);
    }
    #end
}

typedef Flips =
{
    var flipX:Bool;
    var flipY:Bool;
}
