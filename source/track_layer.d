module track_layer;

struct Vertex
{
	import gfm.math : vec3f, vec4f;
	vec3f position;
	vec4f color;
	float heading;
}

import std.math : PI;
import gfm.math : vec3f, vec4f;
import vertex_data : VertexSlice;
import camera : Camera;
import layer : ILayer;
import render : Render;

auto v12_89 = [
	Vertex(vec3f(2592.73,  29898.1, 0), vec4f(1.0, 1.0, 1.0, 1.0),   0 * PI/180.0),
	Vertex(vec3f(4718.28,  30201.3, 0), vec4f(1.0, 1.0, 1.0, 1.0),  30 * PI/180.0),
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
	Vertex(vec3f(54822.9,  32615.2, 0), vec4f(1.0, 0.0, 0.0, 1.0), 0.0),
	Vertex(vec3f(56916.5,    31945, 0), vec4f(0.0, 1.0, 0.0, 1.0), -0.5),
	Vertex(vec3f(59601.7,  31186.4, 0), vec4f(0.0, 0.0, 1.0, 1.0), +0.50),
];

auto vs12_89_line = [
	VertexSlice(VertexSlice.Kind.LineStripAdjacency, 0, 31),
];

auto vs12_89_point = [
	VertexSlice(VertexSlice.Kind.Points, 1, 29),
];


class TrackLayer : ILayer
{
	import gfm.opengl : OpenGL, GLProgram;
	import gfm.math : vec2i;
	import vertex_data : VertexData;
	import vertex_spec : VertexSpec;

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

			_point_program = new GLProgram(_gl, program_source);
		}

		{
			const program_source =
				q{#version 330 core

				#if VERTEX_SHADER
				layout(location = 0) in vec3 position;
				layout(location = 1) in vec4 color;
				layout(location = 2) in float heading;
				out vec4 vColor;
				uniform mat4 mvp_matrix;
				uniform ivec2 resolution;
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

		import std.algorithm : copy;
		import std.range : iota;
		uint[] indices;
		indices.length = vertices.length + 2;

		copy(iota(0, cast(uint) vertices.length), indices[1..$-1]);
		// Дублируем первую и последнюю вершину в индексном буфере для работы в режиме
		// adjacency
		indices[0] = indices[1];
		indices[$-1] = indices[$-2];

		_vertex_data = new VertexData(_gl, new VertexSpec!Vertex(_point_program), vertices, indices);
	}

	~this()
	{
		_vertex_data.destroy();
		_point_program.destroy();
		_line_program.destroy();
	}

	void draw(Render render, Camera camera)
	{
		import std.typecons : scoped;
		import render : SceneState, DrawState;

		auto scene_state = scoped!SceneState(camera);
		auto draw_state  = scoped!DrawState(_gl, _line_program, _vertex_data);

		draw_state.program.uniform("mvp_matrix").set(cast()scene_state.camera.modelViewProjection);

		foreach(vslice; vs12_89_line)
		{
			render.draw(vslice.kind, vslice.start, vslice.length, scene_state, draw_state);
		}
		
		draw_state.program = _point_program;
		draw_state.program.uniform("mvp_matrix").set(cast()scene_state.camera.modelViewProjection);
		draw_state.program.uniform("resolution").set(cast()scene_state.camera.viewport);

		foreach(vslice; vs12_89_point)
		{
			render.draw(vslice.kind, vslice.start, vslice.length, scene_state, draw_state);
		}
	}

private:
	OpenGL _gl;
	GLProgram _line_program, _point_program;
	VertexData _vertex_data;
}
