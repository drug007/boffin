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
				out float v_size;
				uniform mat4 mvp_matrix;
				uniform float size;
				uniform float linewidth;
				uniform float antialias;

				const float M_SQRT_2 = 1.4142135623730951;
				
				void main()
				{
					gl_Position = mvp_matrix * vec4(position.xyz, 1.0);
					v_size = M_SQRT_2 * size + 2.0*(linewidth + 1.5*antialias);
					gl_PointSize = v_size;
					vColor = color;
					vHeading = heading;
				}
				#endif

				#if FRAGMENT_SHADER
				in vec4 vColor;
				in float vHeading;
				in float v_size;
				out vec4 color_out;

				uniform float size;
				uniform float linewidth;
				uniform float antialias;

				const float PI = 3.14159265358979323846264;
				const float M_SQRT_2 = 1.4142135623730951;

				vec4 filled(float distance, // Signed distance to line
					float linewidth,        // Stroke line width
					float antialias,        // Stroke antialiased area
					vec4 fill)              // Fill color
				{
					float t = linewidth / 2.0 - antialias;
					float signed_distance = distance;
					float border_distance = abs(signed_distance) - t;
					float alpha = border_distance / antialias;
					alpha = exp(-alpha * alpha);
					if( border_distance < 0.0 )
						return fill;
					else if( signed_distance < 0.0 )
						return fill;
					else
						return vec4(fill.rgb, alpha * fill.a);
				}

				vec4 outline(float distance, // Signed distance to line
					float linewidth,         // Stroke line width
					float antialias,         // Stroke antialiased area
					vec4 stroke,             // Stroke color
					vec4 fill)               // Fill color
				{
					float t = linewidth / 2.0 - antialias;
					float signed_distance = distance;
					float border_distance = abs(signed_distance) - t;
					float alpha = border_distance / antialias;
					
					alpha = exp(-alpha * alpha);

					if( border_distance < 0.0 )
						return stroke;
					else if( signed_distance < 0.0 )
						return mix(fill, stroke, sqrt(alpha));
					else
						return vec4(stroke.rgb, stroke.a * alpha);
				}

				float disc(vec2 P, float size)
				{
					return length(P) - size/2;
				}

				float heart(vec2 P, float size)
				{
					float x = M_SQRT_2/2.0 * (P.x - P.y);
					float y = M_SQRT_2/2.0 * (P.x + P.y);
					float r1 = max(abs(x),abs(y))-size/3.5;
					float r2 = length(P - M_SQRT_2/2.0*vec2(+1.0,-1.0)*size/3.5)
						- size/3.5;
					float r3 = length(P - M_SQRT_2/2.0*vec2(-1.0,-1.0)*size/3.5)
						- size/3.5;
					return min(min(r1,r2),r3);
				}

				// Computes the signed distance from a line
				float line_distance(vec2 p, vec2 p1, vec2 p2) {
					vec2 center = (p1 + p2) * 0.5;
					float len = length(p2 - p1);
					vec2 dir = (p2 - p1) / len;
					vec2 rel_p = p - center;
					return dot(rel_p, vec2(dir.y, -dir.x));
				}

				// Computes the signed distance from a line segment
				float segment_distance(vec2 p, vec2 p1, vec2 p2) {
					vec2 center = (p1 + p2) * 0.5;
					float len = length(p2 - p1);
					vec2 dir = (p2 - p1) / len;
					vec2 rel_p = p - center;
					float dist1 = abs(dot(rel_p, vec2(dir.y, -dir.x)));
					float dist2 = abs(dot(rel_p, dir)) - 0.5*len;
					return max(dist1, dist2);
				}

				// Computes the centers of a circle with
				// given radius passing through p1 & p2
				vec4 inscribed_circle(vec2 p1, vec2 p2, float radius)
				{
					float q = length(p2-p1);
					vec2 m = (p1+p2)/2.0;
					vec2 d = vec2( sqrt(radius*radius - (q*q/4.0)) * (p1.y-p2.y)/q,
					sqrt(radius*radius - (q*q/4.0)) * (p2.x-p1.x)/q);
					return vec4(m+d, m-d);
				}

				float arrow_curved(vec2 texcoord, float body_, float head,
					float linewidth, float antialias)
				{
					float w = linewidth/2.0 + antialias;
					vec2 start = -vec2(body_/2.0, 0.0);
					vec2 end = +vec2(body_/2.0, 0.0);
					float height = 0.5;
					vec2 p1 = end - head*vec2(+1.0,+height);
					vec2 p2 = end - head*vec2(+1.0,-height);
					vec2 p3 = end;
					// Head : 3 circles
					vec2 c1 = inscribed_circle(p1, p3, 1.25*body_).zw;
					float d1 = length(texcoord - c1) - 1.25*body_;
					vec2 c2 = inscribed_circle(p2, p3, 1.25*body_).xy;
					float d2 = length(texcoord - c2) - 1.25*body_;
					vec2 c3 = inscribed_circle(p1, p2, max(body_-head, 1.0*body_)).xy;
					float d3 = length(texcoord - c3) - max(body_-head, 1.0*body_);
					// Body : 1 segment
					float d4 = segment_distance(texcoord,
					start, end - vec2(linewidth,0.0));
					// Outside rejection (because of circles)

					if( texcoord.y > +(2.0*head + antialias) )
						return 1000.0;
					if( texcoord.y < -(2.0*head + antialias) )
						return 1000.0;
					if( texcoord.x < -(body_/2.0 + antialias) )
						return 1000.0;
					if( texcoord.x > c1.x )
						return 1000.0;
					return min( d4, -min(d3,min(d1,d2)));
				}

				float arrow_angle(vec2 texcoord,
					float body_, float head, float height,
					float linewidth, float antialias)
				{
					float d;
					float w = linewidth/2.0 + antialias;
					vec2 start = -vec2(body_/2.0, 0.0);
					vec2 end = +vec2(body_/2.0, 0.0);
					// Arrow tip (beyond segment end)
					if( texcoord.x > body_/2.0) {
						// Head : 2 segments
						float d1 = line_distance(texcoord,
							end, end - head*vec2(+1.0,-height));
						float d2 = line_distance(texcoord,
							end - head*vec2(+1.0,+height), end);
						// Body : 1 segment
						float d3 = end.x - texcoord.x;
						d = max(max(d1,d2), d3);
					} else {
						// Head : 2 segments
						float d1 = segment_distance(texcoord,
							end - head*vec2(+1.0,-height), end);
						float d2 = segment_distance(texcoord,
							end - head*vec2(+1.0,+height), end);
						// Body : 1 segment
						float d3 = segment_distance(texcoord,
							start, end - vec2(linewidth,0.0));
						d = min(min(d1,d2), d3);
					}
					return d;
				}

				float arrow_angle_30(vec2 texcoord,
					float body_, float head,
					float linewidth, float antialias)
				{
					return arrow_angle(texcoord, body_, head,
						0.25, linewidth, antialias);
				}
				
				void main()
				{
					vec2 rotation = vec2(cos(vHeading), sin(vHeading));

					vec2 p = gl_PointCoord.xy - vec2(0.5,0.5);
					p = vec2(rotation.x*p.x - rotation.y*p.y,
						rotation.y*p.x + rotation.x*p.y);
					// float distance = heart(p*v_size, size);
					float distance = arrow_angle_30(p*v_size, size, size/2, linewidth, antialias);
					// color_out = outline(distance, linewidth, antialias, fg_color, bg_color);
					color_out = filled(distance, linewidth, antialias, vColor);
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
		draw_state.program.uniform("linewidth").set(3.0f);

		foreach(vslice; line_slices)
		{
			render.draw(vslice.kind, vslice.start, vslice.length, scene_state, draw_state);
		}

		import gfm.opengl : glEnable, GL_PROGRAM_POINT_SIZE;
		glEnable(GL_PROGRAM_POINT_SIZE);
		
		draw_state.program = _point_program;
		draw_state.program.uniform("mvp_matrix").set(cast()scene_state.camera.modelViewProjection);
		draw_state.program.uniform("size").set(20.0f);
		draw_state.program.uniform("linewidth").set(2.0f);
		draw_state.program.uniform("antialias").set(1.0f);

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
