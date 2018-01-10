module uiwidget;

import dlangui.widgets.layouts : VerticalLayout;
import dlangui.core.events : MouseEvent, KeyEvent;
import dlangui.core.types : Rect, FILL_PARENT;
import dlangui.widgets.styles : Align;
import dlangui.core.logger : Log;
import dlangui.graphics.resources : DrawableRef, OpenGLDrawable;

class UiWidget : VerticalLayout
{
	import std.experimental.logger : FileLogger;
	import gfm.math : vec2i, vec3f;
	import gfm.opengl : OpenGL;
	import track_layer : TrackLayer;
	import track_layer_render : TrackLayerRender;
	import map_layer : MapLayer;
	import sprite_layer : SpriteLayer;
	import camera : Camera;
	import layer_render : ILayerRender;
	import render : Render;

	private
	{
		ILayerRender[]    _layer;
		Render      _render;
		Camera      _camera;
		vec2i       _last_mouse_pos;
		FileLogger  _logger;
		OpenGL      _gl;
		TrackLayer  _track_layer;
	}

	this()
	{
		import dlangui.dml.parser : parseML;

		super("OpenGLView");
		layoutWidth = FILL_PARENT;
		layoutHeight = FILL_PARENT;
		alignment = Align.Center;
		try {
			parseML(q{
				{
				  margins: 0
				  padding: 0
				  //backgroundImageId: "tx_fabric.tiled"
				  backgroundColor: 0x000000;
				  layoutWidth: fill
				  layoutHeight: fill

				  VerticalLayout {
					id: glView
					margins: 0
					padding: 0
					layoutWidth: fill
					layoutHeight: fill
					TextWidget { text: "Data Visualizer"; textColor: "red"; fontSize: 150%; fontWeight: 800; fontFace: "Arial" }
					VSpacer { layoutWeight: 30 }
					TextWidget { id: lblPosition; text: ""; backgroundColor: 0x80202020; textColor: 0xFFE0E0 }
				  }
				}
			}, "", this);
		} catch (Exception e) {
			Log.e("Failed to parse dml", e);
		}

		// assign OpenGL drawable to child widget background
		childById("glView").backgroundDrawable = DrawableRef(new OpenGLDrawable(&doDraw));

		_camera = new Camera(width, height);
		_camera.halfWorldWidth = 30_000.0f;
		_camera.position = vec3f(30_000, 30_000, 0);

		_render = new Render();

		import gfm.opengl : GLVersion;
		import std.stdio : stdout;

		_logger = new FileLogger(stdout);
		_gl = new OpenGL(_logger);

		// reload OpenGL now that a context exists
		_gl.reload(GLVersion.GL32, GLVersion.HighestSupported);

		// redirect OpenGL output to our Logger
		_gl.redirectDebugOutput();

		{
			import std.math : PI;
			import std.datetime : SysTime, UTC;
			import track_layer : TrackId, Report;

			_track_layer = new TrackLayer();
			
			_track_layer.add(TrackId(1, 1), [
				Report(TrackId(1, 202), PI/2, vec3f(20000, 30000,      0), SysTime(12_000_000, UTC())),
				Report(TrackId(1, 202), PI/2, vec3f(30000, 55000,      0), SysTime(22_000_000, UTC())),
			]);
			_track_layer.add(TrackId(1, 2), [
				Report(TrackId(2, 10), PI/3, vec3f(40000, 40000,      0), SysTime(10_000_000, UTC())),
				Report(TrackId(2, 10), PI/3, vec3f(60000, 45000,      0), SysTime(20_000_000, UTC())),
				Report(TrackId(2, 10), PI/3, vec3f(50000, 25000,      0), SysTime(30_000_000, UTC())),
			]);

			_track_layer.build(_gl);
			_layer ~= _track_layer;
		}

		{
			import map_layer : symbolv;

			_layer ~= new MapLayer(_gl, symbolv);
		}

		{
			import sprite_layer : sprite_data;

			_layer ~= new SpriteLayer(_gl, sprite_data);
		}

		focusable = true;
	}

	/// process key event, return true if event is processed.
	override bool onMouseEvent(MouseEvent event)
	{
		import dlangui.core.events : MouseAction;

		if (event.action == MouseAction.Move)
		{
			if (event.rbutton.isDown)
			{
				auto delta = vec2i(event.x, event.y) - _last_mouse_pos;
				auto scale = 2 * _camera.halfWorldWidth / _camera.viewport.x;
				_camera.position += vec3f(-delta.x, delta.y, 0) * scale;
			}

			_last_mouse_pos = vec2i(event.x, event.y);

			_camera.viewport = vec2i(width, height);
			auto world_pos = _camera.rayFromMouseCoord(_last_mouse_pos);// + _camera.position;

			auto nearest = _track_layer.search(world_pos.xy, 20 * _camera.scale);

			import std.format : format;
			import std.conv : text;
			childById("lblPosition").text = format("%d\t%d\t%.2f\t%.2f\t%.2f %s"d,
				_last_mouse_pos.x, _last_mouse_pos.y,
				world_pos.x, world_pos.y,
				_camera.scale, 
				nearest is null ? "null" : (*nearest).text
			);

			if (nearest)
				_track_layer.setHighlighted(nearest.id.source, nearest.id.number, nearest.timestamp.stdTime);
			else
				_track_layer.setHighlighted(0u, 0u, 0u);
		}
		else if (event.action == MouseAction.Wheel)
		{
			if (event.wheelDelta)
			{
				enum delta = 0.05;
				_camera.halfWorldWidth *= (1 + delta*event.wheelDelta);
				invalidate;
			}
		}
		return true;
	}

	/// process key event, return true if event is processed.
	override bool onKeyEvent(KeyEvent event) {
		//if (event.action == KeyAction.KeyDown) {
		//    switch(event.keyCode) with(KeyCode) {
		//        case KEY_W:
		//        case UP:
		//            _world.camPosition.forward(1);
		//            updateCamPosition();
		//            return true;
		//        case DOWN:
		//        case KEY_S:
		//            _world.camPosition.backward(1);
		//            updateCamPosition();
		//            return true;
		//        case KEY_A:
		//        case LEFT:
		//            _world.camPosition.turnLeft();
		//            updateCamPosition();
		//            return true;
		//        case KEY_D:
		//        case RIGHT:
		//            _world.camPosition.turnRight();
		//            updateCamPosition();
		//            return true;
		//        case HOME:
		//        case KEY_E:
		//            _world.camPosition.moveUp();
		//            updateCamPosition();
		//            return true;
		//        case END:
		//        case KEY_Q:
		//            _world.camPosition.moveDown();
		//            updateCamPosition();
		//            return true;
		//        case KEY_Z:
		//            _world.camPosition.moveLeft();
		//            updateCamPosition();
		//            return true;
		//        case KEY_C:
		//            _world.camPosition.moveRight();
		//            updateCamPosition();
		//            return true;
		//        case KEY_F:
		//            flying = !flying;
		//            if (!flying)
		//                _world.camPosition.pos.y = CHUNK_DY - 3;
		//            updateCamPosition();
		//            return true;
		//        case KEY_U:
		//            enableMeshUpdate = !enableMeshUpdate;
		//            updateCamPosition();
		//            return true;
		//        default:
		//            return false;
		//    }
		//}
		return false;
	}

	/// this is OpenGLDrawableDelegate implementation
	private void doDraw(Rect windowRect, Rect rc) {

		import dlangui.graphics.glsupport;
		import gfm.math : mat4f, vec2i;

		// clear the whole window
		glViewport(0, 0, rc.width, rc.height);
		glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		_camera.viewport(vec2i(rc.width, rc.height));
		_camera.updateMatrices();

		foreach(l; _layer)
			l.draw(_render, _camera);
	}

	~this() {
		destroy(_camera);
		destroy(_render);
		foreach(l; _layer)
		{
			destroy(l);
		}
	}
}
