module grid_layer_render;

struct Vertex
{
	import gfm.math : vec3f, vec4f;
	vec3f position;
	vec4f color;
}

import std.math : PI;
import gfm.math : vec3f, vec4f;
import vertex_data : VertexSlice;
import camera : Camera;
import layer_render : ILayerRender;
import render : Render;

class GridLayerRender : ILayerRender
{
	import gfm.opengl : OpenGL, GLProgram;
	import gfm.math : vec2i;
	import vertex_data : VertexData;
	import vertex_spec : VertexSpec;

	this()
	{
		{
			const line_program_source =
				q{#version 330 core

				#if VERTEX_SHADER
				layout(location = 0) in vec3 position;
				layout(location = 1) in vec4 color;
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

			_line_program = new GLProgram(_gl, line_program_source);
		}
	}

	~this()
	{
		_vertex_data.destroy();
		_line_program.destroy();
	}

	void setData(R, I)(OpenGL gl, R vertices, I indices, VertexSlice[] lines)
	{
		_gl = gl;
		line_slices = lines;

		if (_vertex_data !is null)
			_vertex_data.destroy();

		_vertex_data = new VertexData(_gl, new VertexSpec!Vertex(_line_program), vertices, indices);
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
		draw_state.program.uniform("linewidth").set(3.0f);

		foreach(vslice; line_slices)
		{
			render.draw(vslice.kind, vslice.start, vslice.length, scene_state, draw_state);
		}
	}

private:
	OpenGL _gl;
	GLProgram _line_program;
	VertexData _vertex_data;
	VertexSlice[] line_slices;
}
