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

class TrackLayer : ILayer
{
	import gfm.opengl : OpenGL, GLProgram;
	import gfm.math : vec2i;
	import vertex_data : VertexData;
	import vertex_spec : VertexSpec;

	this(R, I)(OpenGL gl, R vertices, I indices, VertexSlice[] lines, VertexSlice[] points)
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
				uniform mat4 mv_matrix;
				uniform mat4 p_matrix;
				void main()
				{
					gl_Position = mv_matrix * vec4(position.xyz, 1.0);
					vColor = color;
				}
				#endif

				#if GEOMETRY_SHADER
				// 4 vertices per-primitive -- 2 for the line (1,2) and 2 for adjacency (0,3)
				layout (lines_adjacency) in;
				layout (triangle_strip, max_vertices = 4) out;

				in vec4 vColor[]; // Output from vertex shader for each vertex
				out vec4 fColor;  // Output to fragment shader
				out float distance; // Distance from center of line

				uniform mat4 mv_matrix;
				uniform mat4 p_matrix;

				uniform ivec2 resolution;
				uniform float linewidth;

				void main()
				{
					fColor = vColor[0];

					float lw = linewidth / resolution.x;
					const vec3 a_normal = vec3(0, 1, 0);
					vec4 delta = vec4(a_normal * lw, 0);

					gl_Position = p_matrix * gl_in[1].gl_Position - delta;
					distance = -1;
					EmitVertex();

					gl_Position = p_matrix * gl_in[2].gl_Position - delta;
					distance = -1;
					EmitVertex();

					gl_Position = p_matrix * gl_in[1].gl_Position + delta;
					distance = 1;

					EmitVertex();

					gl_Position = p_matrix * gl_in[2].gl_Position + delta;
					distance = 1;

					EmitVertex();

					EndPrimitive();
				}
				#endif

				#if FRAGMENT_SHADER
				in vec4 fColor;
				in float distance;
				out vec4 color_out;

				void main()
				{
					float d = abs(distance);
					if (d < 0.5)
						color_out = fColor;
					else if (d < 1.0)
						color_out = vec4(fColor.rgb, (1 - d)*2);
					else
						discard;
				}
				#endif
			};

			_line_program = new GLProgram(_gl, program_source);
		}

		line_slices = lines;
		point_slices = points;

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

		draw_state.program.uniform("mv_matrix").set(cast()scene_state.camera.modelViewMatrix);
		draw_state.program.uniform("p_matrix").set(cast()scene_state.camera.projectionMatrix);
		draw_state.program.uniform("resolution").set(cast()scene_state.camera.viewport);
		draw_state.program.uniform("linewidth").set(5.0f);

		foreach(vslice; line_slices)
		{
			render.draw(vslice.kind, vslice.start, vslice.length, scene_state, draw_state);
		}
		
		draw_state.program = _point_program;
		draw_state.program.uniform("mvp_matrix").set(cast()scene_state.camera.modelViewProjection);
		draw_state.program.uniform("resolution").set(cast()scene_state.camera.viewport);

		foreach(vslice; point_slices)
		{
			render.draw(vslice.kind, vslice.start, vslice.length, scene_state, draw_state);
		}
	}

private:
	OpenGL _gl;
	GLProgram _line_program, _point_program;
	VertexData _vertex_data;
	VertexSlice[] line_slices, point_slices;
}
