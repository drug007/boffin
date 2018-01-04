module map_layer;

struct Vertex
{
	import gfm.math : vec3f, vec4f;
	vec3f position;
	vec4f color;
}

import gfm.math : vec3f, vec4f;
import vertex_data : VertexSlice;
import vertex_spec : VertexSpec;
import camera : Camera;
import layer_render : ILayerRender;
import render : Render;

auto symbolv = [
	Vertex(vec3f(2500.0,  25000.0, 0), vec4f(1.0, 0.5, 0.5, 1.0)),
	Vertex(vec3f(2500.0,  35000.0, 0), vec4f(1.0, 0.5, 0.5, 1.0)),
	Vertex(vec3f(5000.0,  35000.0, 0), vec4f(1.0, 0.5, 0.5, 1.0)),
	Vertex(vec3f(5000.0,  25000.0, 0), vec4f(1.0, 0.5, 0.5, 1.0)),
	Vertex(vec3f(2500.0,  25000.0, 0), vec4f(1.0, 0.5, 0.5, 1.0)),

	Vertex(vec3f(7500.0,  23000.0, 0), vec4f(1.0, 0.5, 0.5, 1.0)),
	Vertex(vec3f(7500.0,  33000.0, 0), vec4f(1.0, 0.5, 0.5, 1.0)),
	Vertex(vec3f(9000.0,  33000.0, 0), vec4f(1.0, 0.5, 0.5, 1.0)),
	Vertex(vec3f(9000.0,  23000.0, 0), vec4f(1.0, 0.5, 0.5, 1.0)),
	Vertex(vec3f(7500.0,  23000.0, 0), vec4f(1.0, 0.5, 0.5, 1.0)),
];

auto symbols = [
	VertexSlice(VertexSlice.Kind.LineStrip, 0, 5),
	VertexSlice(VertexSlice.Kind.LineStrip, 5, 5),
];


class MapLayer : ILayerRender
{
	import gfm.opengl : OpenGL, GLProgram;
	import gfm.math : vec2i;
	import vertex_data : VertexData;

	this(R)(OpenGL gl, R vertices)
	{
		import std.range : ElementType;
		static assert(is(ElementType!R == Vertex));
		
		_gl = gl;

		{
			const program_source =
				q{#version 330 core

				#if VERTEX_SHADER
				layout(location = 0) in vec3 position;
				layout(location = 1) in vec4 color;
				out vec4 vColor;
				uniform mat4 mvp_matrix;
				void main()
				{
					gl_Position = mvp_matrix * vec4(position.xyz, 1.0);
					vColor = color;
				}
				#endif

				#if FRAGMENT_SHADER
				in vec4 vColor;
				out vec4 color_out;

				void main()
				{
					color_out = vColor;
				}
				#endif
			};

			_line_program = new GLProgram(_gl, program_source);
		}

		import std.range : iota;
		auto indices = iota(0, cast(uint) vertices.length);
		_vertex_data = new VertexData(_gl, new VertexSpec!Vertex(_line_program), vertices, indices);
	}

	~this()
	{
		_vertex_data.destroy();
		_line_program.destroy();
	}

	void draw(Render render, Camera camera)
	{
		import std.typecons : scoped;
		import render : SceneState, DrawState;

		auto scene_state = scoped!SceneState(camera);
		auto draw_state  = scoped!DrawState(_gl, _line_program, _vertex_data);
		draw_state.program.uniform("mvp_matrix").set(cast()scene_state.camera.modelViewProjection);

		foreach(vslice; symbols)
		{
			render.draw(vslice.kind, vslice.start, vslice.length, scene_state, draw_state);
		}
	}

private:
	OpenGL _gl;
	GLProgram _line_program;
	VertexData _vertex_data;
}
