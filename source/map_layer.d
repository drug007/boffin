module map_layer;

struct Vertex
{
	import gfm.math : vec3f, vec4f;
	vec3f position;
	vec4f color;
}

import gfm.math : vec3f, vec4f;
import batcher : VertexSlice;

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


class MapLayer
{
	import gfm.opengl : OpenGL, GLProgram, VertexSpecification;
	import gfm.math : vec2i;
	import batcher : GLProvider;

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

		_glprovider = new GLProvider!Vertex(_gl, new VertexSpecification!Vertex(_line_program), vertices);
	}

	~this()
	{
		_glprovider.destroy();
		_line_program.destroy();
	}

	void draw(Matrix)(ref Matrix mvp, vec2i resolution)
	{
		{
			_line_program.uniform("mvp_matrix").set(mvp);
			_line_program.use();
			scope(exit) _line_program.unuse();

			_glprovider.drawVertices(symbols);

			_gl.runtimeCheck();
		}
	}

private:
	OpenGL _gl;
	GLProgram _line_program;
	GLProvider!Vertex _glprovider;
}
