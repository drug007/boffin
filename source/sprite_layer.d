module sprite_layer;

struct Vertex
{
	import gfm.math : vec3f, vec4f;
	vec3f position;
	vec4f tex_data; // x, y - center of subtexture
	                // z - size of the subtexture in texture coords
	                // w - size of the subtexture in pixels
}

import gfm.math : vec3f, vec4f;
import vertex_data : VertexSlice;
import camera : Camera;
import layer : ILayer;
import render : Render;

auto sprite_data = [
	Vertex(vec3f(24500.0,  25000.0, 0), vec4f(0.25, 0.25, 0.25, 15)),
	Vertex(vec3f(28500.0,  23000.0, 0), vec4f(0.50, 0.50, 0.50, 50)),
];

auto symbols = [
	VertexSlice(VertexSlice.Kind.Points, 0, 2),
];


class SpriteLayer : ILayer
{
	import gfm.opengl : OpenGL, GLProgram, VertexSpecification, GLTexture2D;
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
				layout(location = 1) in vec4 tex_data;
				uniform mat4 mvp_matrix;
				out vec4 texture_data;
				void main()
				{
					gl_Position = mvp_matrix * vec4(position.xyz, 1.0);
					texture_data = tex_data;
				}
				#endif

				#if GEOMETRY_SHADER
				layout(points) in;
				layout(triangle_strip, max_vertices = 4) out;

				in vec4 texture_data[];
				out vec2 tex_coord;

				uniform ivec2 resolution;

				void main()
				{
					// sprite size in texture coords
					float ts = texture_data[0].z;
					// sprite size in pixels
					float ps = texture_data[0].w;
					// center of sprite in texture coords
					vec2 td = texture_data[0].xy;

					float size = ps / resolution.x;
					float aspect_ratio = resolution.x / float(resolution.y);
					vec4 offset;

					// Left bottom vertex
					offset = vec4(-size, -aspect_ratio * size, 0.0, 0.0);
					gl_Position = gl_in[0].gl_Position + offset;
					tex_coord = td.xy + vec2(-ts, -ts);
					EmitVertex();

					// Left top vertex
					offset = vec4(-size, aspect_ratio * size, 0.0, 0.0);
					gl_Position = gl_in[0].gl_Position + offset;
					tex_coord = td.xy + vec2(-ts, +ts);
					EmitVertex();

					// Right bottom vertex
					offset = vec4(size, -aspect_ratio * size, 0.0, 0.0);
					gl_Position = gl_in[0].gl_Position + offset;
					tex_coord = td.xy + vec2(+ts, -ts);
					EmitVertex();

					// Right top vertex
					offset = vec4(size, aspect_ratio * size, 0.0, 0.0);
					gl_Position = gl_in[0].gl_Position + offset;
					tex_coord = td.xy + vec2(+ts, +ts);
					EmitVertex();

					EndPrimitive();
				}
				#endif

				#if FRAGMENT_SHADER
				in vec2 tex_coord;
				out vec4 color_out;

				uniform sampler2D sampler;

				void main()
				{
					vec4 tex = texture2D ( sampler, tex_coord );
  					color_out = vec4(tex.r, tex.g, tex.b, tex.a);
				}
				#endif
			};

			_line_program = new GLProgram(_gl, program_source);
		}

		_glprovider = new VertexData!Vertex(_gl, new VertexSpecification!Vertex(_line_program), vertices);

		import gfm.opengl;
		int texWidth = 1024;
		int texHeight = 1024;
		ubyte[] tex_data = new ubyte[texWidth * texHeight * 4];
		size_t j;
		foreach(i; 0..tex_data.length / 4)
		{
			auto flag = (i % texWidth) < (texWidth / 2);
			ubyte red = flag ? 255 :   0;
			ubyte grn = flag ?   0 : 255;
			tex_data[j++] = red;
			tex_data[j++] = grn;
			tex_data[j++] =   0;
			tex_data[j++] = 128;
		}
		_texture = new GLTexture2D(_gl);
		_texture.setMinFilter(GL_LINEAR_MIPMAP_LINEAR);
		_texture.setMagFilter(GL_LINEAR);
		_texture.setWrapS(GL_REPEAT);
		_texture.setWrapT(GL_REPEAT);
		_texture.setImage(0, GL_RGBA, texWidth, texHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, tex_data.ptr);
		_texture.generateMipmap();
	}

	~this()
	{
		_texture.destroy();
		_glprovider.destroy();
		_line_program.destroy();
	}

	void draw(Render render, Camera camera)
	{
		{
			int tex_unit = 0;
			_texture.use(tex_unit);

			_line_program.uniform("sampler").set(tex_unit);
			_line_program.uniform("mvp_matrix").set(cast()camera.modelViewProjection);
			_line_program.uniform("resolution").set(cast()camera.viewport);
			_line_program.use();
			scope(exit) _line_program.unuse();

			with(_glprovider)
			{
				import gfm.opengl : glDrawElements, GL_UNSIGNED_INT;

				vao_points.bind();
				foreach(vslice; symbols)
				{
					auto length = cast(int) vslice.length;
					auto start  = cast(int) vslice.start;

					glDrawElements(vslice.glKind, length, GL_UNSIGNED_INT, cast(void *)(start * 4));
				}
				vao_points.unbind();
			}

			_gl.runtimeCheck();
		}
	}

private:
	OpenGL _gl;
	GLProgram _line_program;
	VertexData!Vertex _glprovider;
	GLTexture2D _texture;
}
