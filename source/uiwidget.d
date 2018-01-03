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
	import map_layer : MapLayer;
	import sprite_layer : SpriteLayer;
	import camera : Camera;
	import layer : ILayer;
	import render : Render;

	private
	{
		ILayer[]    _layer;
		Render      _render;
		Camera      _camera;
		vec2i       _last_mouse_pos;
		FileLogger  _logger;
		OpenGL      _gl;
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
			import data : v12_89, vs12_89_line, vs12_89_point;

			import track_layer : Vertex, vec4f;
			import vertex_data : VertexSlice;

			auto abcolor = vec4f(1.0, 1.0, 1.0, 1.0);
			auto crcolor = vec4f(0.0, 1.0, 0.0, 1.0);

			auto a = vec3f(  10000,  30000, 0);
			auto b = vec3f(  50000,  50000, 0);
			auto c = vec3f(  30000,  30000, 0);

			auto r = vec3f( 10000, 10000, 0);

			auto vd = [
				Vertex(a, abcolor, 0.0),
				Vertex(b, abcolor, 0.0),

				Vertex(c, crcolor, 0.0),
				Vertex(c + r, crcolor, 0.0),
			];

			// Дублируем первую и последнюю вершину в индексном буфере для работы в режиме
			// adjacency
			uint[] indices = [
				0, 0, 1, 1, // ab line
				2, 2, 3, 3, // cr line
			];

			_layer ~= new TrackLayer(_gl, vd, indices,
				[
					VertexSlice(VertexSlice.Kind.LineStripAdjacency, 0, 4),
					VertexSlice(VertexSlice.Kind.LineStripAdjacency, 4, 4)
				],
				[
					VertexSlice(VertexSlice.Kind.Points, 1, 2),
				]
			);

			//_layer ~= new TrackLayer(_gl, v12_89, indices, vs12_89_line, vs12_89_point);
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
			auto world_pos = _camera.projectWindowToPlane0(_last_mouse_pos);// + _camera.position;

			import std.format : format;
			childById("lblPosition").text = format("%d\t%d\t%.2f\t%.2f"d,
				_last_mouse_pos.x, _last_mouse_pos.y,
				world_pos.x, world_pos.y
			);
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
