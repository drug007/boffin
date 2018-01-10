module track_layer_render;

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
import layer_render : ILayerRender;
import render : Render;

class TrackLayerRender : ILayerRender
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
					gl_PointSize = 13.0;
					vColor = color;
					vHeading = heading;
				}
				#endif

				#if FRAGMENT_SHADER
				in vec4 vColor;
				in float vHeading;
				out vec4 color_out;

				void main()
				{
					float r = 0.0, delta = 0.0, alpha = 1.0;
					vec2 cxy = 2.0 * gl_PointCoord - 1.0;
					r = dot(cxy, cxy);
					delta = fwidth(r);
					alpha = 1.0 - smoothstep(1.0 - delta, 1.0 + delta, r);
					color_out = vColor * alpha;
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
					vec3 diff = gl_in[2].gl_Position.xyz - gl_in[1].gl_Position.xyz;
					vec3 a_normal = normalize(vec3(diff.y, -diff.x, diff.z));
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

		import gfm.opengl : glEnable, GL_PROGRAM_POINT_SIZE;
		glEnable(GL_PROGRAM_POINT_SIZE);
		
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
