module uiwidget2;

import dlangui.widgets.layouts : VerticalLayout;
import dlangui.core.events : MouseEvent, KeyEvent;
import dlangui.core.types : Rect, FILL_PARENT;
import dlangui.widgets.styles : Align;
import dlangui.core.logger : Log;
import dlangui.graphics.resources : DrawableRef, OpenGLDrawable;
import render;

struct Vertex
{
	import gfm.math : vec3f, vec4f;
	vec3f position;
	vec4f color;
	float heading;
}

class UiWidget2 : VerticalLayout
{
	import std.experimental.logger : FileLogger;
	import gfm.math : vec2i, vec3f;
	import gfm.opengl : OpenGL;

	private
	{
		vec2i       _last_mouse_pos;
		FileLogger  _logger;
		OpenGL      _gl;
		ClearState  _clear_state;
		DrawState   _draw_state;
		SceneState  _scene_state;
		Context     _context;
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

		import gfm.opengl : GLVersion;
		import std.stdio : stdout;

		_logger = new FileLogger(stdout);
		_gl = new OpenGL(_logger);

		// reload OpenGL now that a context exists
		_gl.reload(GLVersion.GL32, GLVersion.HighestSupported);

		// redirect OpenGL output to our Logger
		_gl.redirectDebugOutput();

		focusable = true;

		RenderState rs;
		rs.depth_mask = false;
		rs.depth_test.enabled = true;
		rs.depth_test.func = DepthTestFunction.Less;
		_draw_state.render_state = rs;

		_draw_state.program = makeGLProgram0();
		import gfm.opengl : VertexSpecification;
		import gfm.math : vec4f;
		import std.math : PI;
		auto vs = new VertexSpec!Vertex(_draw_state.program);
		_draw_state.va = VertexArray(_gl, vs, [
			Vertex(vec3f(2592.73,  29898.1, 0), vec4f(1.0, 1.0, 1.0, 1.0),   0 * PI/180.0),
			Vertex(vec3f(0000.28,  00000.3, 0), vec4f(1.0, 1.0, 1.0, 1.0),  30 * PI/180.0),
			Vertex(vec3f(7217.78,  31579.6, 0), vec4f(1.0, 1.0, 1.0, 1.0),  60 * PI/180.0),
			Vertex(vec3f(8803.98,  31867.5, 0), vec4f(1.0, 1.0, 1.0, 1.0),  90 * PI/180.0),
			Vertex(vec3f(10319.9,  32846.7, 0), vec4f(1.0, 1.0, 1.0, 1.0), 120 * PI/180.0),
			Vertex(vec3f(12101.3,  33290.6, 0), vec4f(1.0, 1.0, 1.0, 1.0), 150 * PI/180.0),
			Vertex(vec3f(  15099,    34126, 0), vec4f(1.0, 1.0, 1.0, 1.0), 180 * PI/180.0),
			Vertex(vec3f(15750.3,  34418.7, 0), vec4f(1.0, 1.0, 1.0, 1.0), 1.0),
			Vertex(vec3f(  18450,  35493.3, 0), vec4f(1.0, 1.0, 1.0, 1.0), 1.0),
			Vertex(vec3f(20338.8,  36117.9, 0), vec4f(1.0, 1.0, 1.0, 1.0), 1.0),
			Vertex(vec3f(22569.5,    36753, 0), vec4f(1.0, 1.0, 1.0, 1.0), 1.0),
			Vertex(vec3f(23030.3,  37399.1, 0), vec4f(1.0, 1.0, 1.0, 1.0), 1.0),
			Vertex(vec3f(26894.2,  38076.8, 0), vec4f(1.0, 1.0, 1.0, 1.0), 1.0),
			Vertex(vec3f(27829.2,  38624.7, 0), vec4f(1.0, 1.0, 1.0, 1.0), 1.0),
			Vertex(vec3f(30832.9,  39502.2, 0), vec4f(1.0, 1.0, 1.0, 1.0), 1.0),
			Vertex(vec3f(31785.5,  39910.8, 0), vec4f(1.0, 1.0, 1.0, 1.0), 1.0),
			Vertex(vec3f(34543.4,  39246.4, 0), vec4f(1.0, 1.0, 1.0, 1.0), 1.0),
			Vertex(vec3f(36346.9,  38694.4, 0), vec4f(1.0, 1.0, 1.0, 1.0), 1.0),
			Vertex(vec3f(38273.6,    38011, 0), vec4f(1.0, 1.0, 1.0, 1.0), 1.0),
			Vertex(vec3f(39485.8,    37357, 0), vec4f(1.0, 1.0, 1.0, 1.0), 1.0),
			Vertex(vec3f(  42242,  36425.5, 0), vec4f(1.0, 1.0, 1.0, 1.0), 1.0),
			Vertex(vec3f(43082.6,  36391.4, 0), vec4f(1.0, 1.0, 1.0, 1.0), 1.0),
			Vertex(vec3f(47068.2,  34976.8, 0), vec4f(1.0, 1.0, 1.0, 1.0), 1.0),
			Vertex(vec3f(48361.4,  34596.8, 0), vec4f(1.0, 1.0, 1.0, 1.0), 1.0),
			Vertex(vec3f(50459.5,  34002.1, 0), vec4f(1.0, 1.0, 1.0, 1.0), 1.0),
			Vertex(vec3f(53024.4,  33244.2, 0), vec4f(1.0, 1.0, 1.0, 1.0), 1.0),
			Vertex(vec3f(54822.9,  32615.2, 0), vec4f(1.0, 1.0, 1.0, 1.0), 1.0),
			Vertex(vec3f(56916.5,    31945, 0), vec4f(1.0, 1.0, 1.0, 1.0), 1.0),
			Vertex(vec3f(59601.7,  31186.4, 0), vec4f(1.0, 1.0, 1.0, 1.0), 1.0),
		]);
	}

	/// process key event, return true if event is processed.
	override bool onMouseEvent(MouseEvent event)
	{
		import dlangui.core.events : MouseAction;

		if (event.action == MouseAction.Move)
		{
			if (event.rbutton.isDown)
			{
				//auto delta = vec2i(event.x, event.y) - _last_mouse_pos;
				//auto scale = 2 * _camera.halfWorldWidth / _camera.viewport.x;
				//_camera.position += vec3f(-delta.x, delta.y, 0) * scale;
			}

			_last_mouse_pos = vec2i(event.x, event.y);

			//_camera.viewport = vec2i(width, height);
			//auto world_pos = _camera.projectWindowToPlane0(_last_mouse_pos);

			//import std.format : format;
			//childById("lblPosition").text = format("%d\t%d\t%.2f\t%.2f"d,
			//	_last_mouse_pos.x, _last_mouse_pos.y,
			//	world_pos.x, world_pos.y
			//);
		}
		else if (event.action == MouseAction.Wheel)
		{
			if (event.wheelDelta)
			{
				enum delta = 0.05;
				//_camera.halfWorldWidth *= (1 + delta*event.wheelDelta);
				invalidate;
			}
		}
		return true;
	}

	/// process key event, return true if event is processed.
	override bool onKeyEvent(KeyEvent event) {
		return false;
	}

	/// this is OpenGLDrawableDelegate implementation
	private void doDraw(Rect windowRect, Rect rc) {

		//import dlangui.graphics.glsupport;
		//import gfm.math : mat4f, vec2i;

		//// clear the whole window
		//glViewport(0, 0, rc.width, rc.height);
		//glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
		//glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		//_camera.viewport(vec2i(rc.width, rc.height));
		//_camera.updateMatrices();

		//mat4f mvp = _camera.modelViewProjection;
		//auto aspect_ratio = _camera.aspectRatio;
		//_map_layer.draw(mvp, _camera.viewport);
		//_track_layer.draw(mvp, _camera.viewport);
		//_sprite_layer.draw(mvp, _camera.viewport);
//import gfm.opengl;// : glViewport;
//glViewport(0, 0, rc.width, rc.height);
//glClearColor(0, 1, 0, 1.0);
//glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		_context.clear(_clear_state);
		_context.draw(PrimitiveType.LineStrip, 
			0, 28, 
			_draw_state, 
			_scene_state);
	}

	auto makeGLProgram0()
	{
		import gfm.opengl : GLProgram;

		const program_source =
			q{#version 330 core

			#if VERTEX_SHADER
			layout(location = 0) in vec3 position;
			layout(location = 1) in vec4 color;
			layout(location = 2) in float heading;
			out vec4 vColor;
			out float vHeading;
			uniform mat4 mvp_matrix;
			void main()
			{
				gl_Position = mvp_matrix * vec4(position.xyz, 1.0);
				gl_PointSize = 3.0;
				vColor = color;
				vHeading = heading;
			}
			#endif

			#if GEOMETRY_SHADER
			layout(points) in;
			layout(line_strip, max_vertices = 19) out;

			in vec4 vColor[]; // Output from vertex shader for each vertex
			in float vHeading[];
			out vec4 fColor;  // Output to fragment shader

			uniform ivec2 resolution;

			const float PI = 3.1415926;

			void main()
			{
				fColor = vColor[0]; // Point has only one vertex
				float fHeading = vHeading[0];

				float size = 8.0 / resolution.x;
				float heading_length = 4 * size;
				float aspect_ratio = resolution.x / float(resolution.y);
				const float sides = 16;

				gl_Position = gl_in[0].gl_Position;
				EmitVertex();

				vec4 offset = vec4(cos(fHeading) * heading_length, -sin(fHeading) * aspect_ratio * heading_length, 0.0, 0.0);
				gl_Position = gl_in[0].gl_Position + offset;
				EmitVertex();

				EndPrimitive();

				for (int i = 0; i <= sides; i++) {
					// Angle between each side in radians
					float ang = PI * 2.0 / sides * i;

					// Offset from center of point
					vec4 offset = vec4(cos(ang) * size, -sin(ang) * aspect_ratio * size, 0.0, 0.0);
					gl_Position = gl_in[0].gl_Position + offset;

					EmitVertex();
				}

				EndPrimitive();
			}
			#endif

			#if FRAGMENT_SHADER
			in vec4 fColor;
			out vec4 color_out;

			void main()
			{
				color_out = fColor;
			}
			#endif
		};

		return new GLProgram(_gl, program_source);
	}
}