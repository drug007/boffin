module vertex_data;

public import gfm.math: vec2f, vec3f, vec4f;
import gfm.opengl: GLenum, GL_TRIANGLES, GL_POINTS, GL_LINE_STRIP, GLBuffer, 
	OpenGL, GLVAO, GLProgram, VertexSpecification;

struct VertexSlice
{
	private GLenum _kind;

	enum Kind { Triangles, Points, LineStrip, }

	auto glKind() const
	{
		return _kind;
	}

	auto kind() const
	{
		switch(_kind)
		{
			case GL_TRIANGLES:
				return Kind.Triangles;
			case GL_POINTS:
				return Kind.Points;
			case GL_LINE_STRIP:
				return Kind.LineStrip;
			default:
				assert(0);
		}
	}

	auto kind(Kind kind)
	{
		final switch(kind)
		{
			case Kind.Triangles:
				_kind = GL_TRIANGLES;
			break;
			case Kind.Points:
				_kind = GL_POINTS;
			break;
			case Kind.LineStrip:
				_kind = GL_LINE_STRIP;
			break;
		}
	}

	size_t start, length;

	this(Kind k, size_t start, size_t length)
	{
		kind(k);
		this.start  = start;
		this.length = length;
	}
}

class VertexData
{
	import vertex_spec : IVertexSpec;
	
	this(R)(OpenGL gl, IVertexSpec vertex_specification, R vertices)
	{
		import std.range : ElementType;
		
		import std.array : array;
		import std.algorithm : map;
		import std.range : iota;

		import gfm.opengl : GL_ARRAY_BUFFER, GL_STATIC_DRAW,
			GL_ELEMENT_ARRAY_BUFFER;

		assert(vertices.length);

		index_kind = IndexKind.Uint;
		auto indices = iota(0, vertices.length).map!"cast(uint)a";

		vbo = new GLBuffer(gl, GL_ARRAY_BUFFER, GL_STATIC_DRAW, vertices.array);
		ibo = new GLBuffer(gl, GL_ELEMENT_ARRAY_BUFFER, GL_STATIC_DRAW, indices.array);

		// Create an OpenGL vertex description from the Vertex structure.
		vert_spec = vertex_specification;

		vao_points = new GLVAO(gl);
		// prepare VAO
		{
			vao_points.bind();
			vbo.bind();
			ibo.bind();
			vert_spec.use();
			vao_points.unbind();
		}
	}

	~this()
	{
		if(vbo)
		{
			vbo.destroy();
			vbo = null;
		}
		if(ibo)
		{
			ibo.destroy();
			ibo = null;
		}
		if(vert_spec)
		{
			vert_spec.destroy();
			vert_spec = null;
		}
		if(vao_points)
		{
			vao_points.destroy();
			vao_points = null;
		}
	}

	import gfm.opengl : GL_UNSIGNED_BYTE, GL_UNSIGNED_SHORT, GL_UNSIGNED_INT;
	enum IndexKind : GLenum { Ubyte = GL_UNSIGNED_BYTE, Ushort = GL_UNSIGNED_SHORT, Uint = GL_UNSIGNED_INT, }

	/// Тип, используемый для хранения индексов
	IndexKind index_kind;
	GLBuffer      vbo, ibo;
	GLVAO         vao_points;
	IVertexSpec vert_spec;
}