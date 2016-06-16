package;

import nape.constraint.AngleJoint;
import nape.constraint.PivotJoint;
import nape.constraint.WeldJoint;
import nape.dynamics.InteractionGroup;
import nape.geom.Mat23;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.Material;
import nape.shape.Polygon;
import nape.space.Space;
import nape.util.BitmapDebug;
import nape.util.Debug;
import nape.util.ShapeDebug;
import openfl.Assets;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.ui.Keyboard;

class Main extends Sprite {
	var text:TextField;
	var debugdraw:Debug;
	var space:Space;
	var car:InteractionGroup;
	var fl:Wheel;
	var fr:Wheel;
	var rl:Wheel;
	var rr:Wheel;
	var car_body:Body;
	
	var keys:Array<Bool>; // key helper
	
	var LINEAR_DRAG:Float = 10.0;
	var ANGLE_OFFSET = Math.PI / 6;
	static inline var ROTATE_LIMIT = 0.1;
	
	// entry function
	public function new () {
		super();
		if (stage != null)
            initialise(null);
        else
            addEventListener(Event.ADDED_TO_STAGE, initialise);
	}
	
	function initialise(e:Event) {
		if (e != null) removeEventListener(Event.ADDED_TO_STAGE, initialise);
		
		// debug bitmap, for debug purpose
		#if flash
		debugdraw = new BitmapDebug(stage.stageWidth, stage.stageHeight);
		#else
		debugdraw = new ShapeDebug(stage.stageWidth, stage.stageHeight, 0x666666);
		#end
		debugdraw.transform = Mat23.translation(stage.stageWidth / 2, stage.stageHeight / 2);
		
		text = new TextField();
		text.defaultTextFormat = new TextFormat(Assets.getFont("Assets/font.ttf").fontName, 16, 0xffffff);
		text.text = "Use WASD or arrow keys to control, R to reset";
		text.autoSize = LEFT;
		
		setup();
		
		addChild(debugdraw.display);
		addChild(text);
		
		stage.addEventListener(Event.ENTER_FRAME, enterframe);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, keydown);
		stage.addEventListener(KeyboardEvent.KEY_UP, keyup);
	}
	
	function setup() {	
		keys = new Array<Bool>();
		space = new Space(); // setup a physics space
		car = new InteractionGroup(true); // ignore interactions within the car
		
		fl = create_wheel(); // front left wheel
		fr = create_wheel(); // front right wheel
		rl = create_wheel(); // rear left wheel
		rr = create_wheel(); // rear right wheel
		car_body = create_body(); // car body
		
		// constrain both front wheel
		pin(fl.m_body, car_body, Vec2.weak(-18, -25));
		pin(fr.m_body, car_body, Vec2.weak( 18, -25));
		
		// stable both rear wheels to the car
		weld(rl.m_body, car_body, Vec2.weak(-18, 25));
		weld(rr.m_body, car_body, Vec2.weak( 18, 25));
	}
	
	// reset rotation to 0
	function reset_rotation(value:Float):Float {
		if (value > 0) {
			return value > ROTATE_LIMIT?ROTATE_LIMIT:value;
		} else if (value < 0) {
			return -value > ROTATE_LIMIT? -ROTATE_LIMIT: -value;
		} else return 0;
	}
	
	// called on each frame
	function enterframe(e:Event) {		
		if (keys[Keyboard.A] || keys[Keyboard.LEFT]) {
			update_turn(ANGLE_OFFSET);
		} else if (keys[Keyboard.D] || keys[Keyboard.RIGHT]) {
			update_turn(-ANGLE_OFFSET);
		} else {
			update_turn(0);
		}
		if (keys[Keyboard.W] || keys[Keyboard.UP]) {
			rl.m_body.applyImpulse(Vec2.fromPolar(10, rl.m_body.rotation-Math.PI/2));
			rr.m_body.applyImpulse(Vec2.fromPolar(10, rr.m_body.rotation-Math.PI/2));
		} else if (keys[Keyboard.S] || keys[Keyboard.DOWN]) {
			rl.m_body.applyImpulse(Vec2.fromPolar(10, rl.m_body.rotation+Math.PI/2));
			rr.m_body.applyImpulse(Vec2.fromPolar(10, rr.m_body.rotation+Math.PI/2));
		}
		
		// cancel lateral velocities
		fl.update();
		fr.update();
		rl.update();
		rr.update();
		
		space.step(1 / stage.frameRate);
		car_body.velocity.muleq(0.99); // stop the car from getting too fast
		debugdraw.clear();
		debugdraw.draw(space);
		debugdraw.flush();
	}
	
	function keydown(e:KeyboardEvent) {
		if (e.keyCode == Keyboard.R) setup();
		keys[e.keyCode] = true;
	}
	
	function update_turn(turn:Float) {
		update_turn_single(turn, fl.m_body);
		update_turn_single(turn, fr.m_body);
	}
	
	function update_turn_single(turn:Float, wheel:Body) {
		var current = car_body.rotation - wheel.rotation;
		var offset:Float;
		var da = turn - current;
		if (da > ROTATE_LIMIT) offset = ROTATE_LIMIT;
		else if (da < -ROTATE_LIMIT) offset = -ROTATE_LIMIT;
		else offset = da;
		wheel.rotation -= offset;
	}
	
	function keyup(e:KeyboardEvent) {
		keys[e.keyCode] = false;
	}
	
	function create_wheel():Wheel {
		var wheel = new Wheel(space);
		wheel.m_body.group = car;
		return wheel;
	}
	
	function create_body():Body {
		var body = new Body(BodyType.DYNAMIC);
		var shape = new Polygon(Polygon.box(40, 80));
		shape.body = body;
		body.space = space;
		body.group = car;
		return body;
	}
	
	function weld(wheel:Body, car_body:Body, pos:Vec2) {
		var joint = new WeldJoint(wheel, car_body, Vec2.weak(0, 0), pos);
		joint.space = space;
	}
	
	function pin(wheel:Body, car_body:Body, pos:Vec2) {
		// there is no such revolute joint like in Box2D, using 2 joints combined instead
		var pjoint = new PivotJoint(wheel, car_body, Vec2.weak(0, 0), pos);
		pjoint.space = space;
		var ajoint = new AngleJoint(wheel, car_body, -ANGLE_OFFSET, ANGLE_OFFSET);
		ajoint.space = space;
	}
}

class Wheel {
	public var m_body:Body;
	
	public function new(space:Space) {
		// a wheel should be dynamic
		m_body = new Body(BodyType.DYNAMIC);
		m_body.space = space;
		var shape = new Polygon(Polygon.box(10, 20));
		shape.body = m_body;
	}
	
	public function update() {
		// slide the velocity with the forward direction
		var direction_normalized = Vec2.fromPolar(1, m_body.rotation - Math.PI / 2);
		m_body.velocity = direction_normalized.mul(m_body.velocity.dot(direction_normalized)); // this equation is written in the report
	}
}
