package;

import nape.constraint.Constraint;
import nape.shape.Polygon;
import nape.shape.Shape;
import nape.space.Space;
import nape.util.Debug;
import nape.util.ShapeDebug;
import openfl.display.Sprite;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.util.BitmapDebug;
import openfl.events.Event;

class Main extends Sprite {
	var debugdraw:Debug;
	var space:Space;
	
	public function new () {
		super ();
		space = new Space();
		debugdraw = new ShapeDebug(stage.stageWidth, stage.stageHeight);
		
		addChild(debugdraw.display);
		addEventListener(Event.ENTER_FRAME, enterframe);
		graphics.beginFill(0xffffff);
		graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
		var fl = create_wheel();
		var fr = create_wheel();
		var rl = create_wheel();
		var rr = create_wheel();
		
		var body = create_body();
	}
	
	function enterframe(e:Event) {
		debugdraw.clear();
		debugdraw.draw(space);
	}
	
	function create_wheel() {
		var wheel = new Body(BodyType.DYNAMIC);
		var shape = new Polygon(Polygon.box(10, 20));
		shape.body = wheel;
		wheel.space = space;
		return wheel;
	}
	
	function create_body() {
		var body = new Body(BodyType.DYNAMIC);
		var shape = new Polygon(Polygon.box(40, 60));
		shape.body = body;
		body.space = space;
		return body;
	}
}
