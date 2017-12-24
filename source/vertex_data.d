module vertex_data;

public import gfm.math: vec2f, vec3f, vec4f;
import gfm.opengl: GLenum, GLBuffer, OpenGL, GLVAO, GLProgram, 
	VertexSpecification;

import gfm.opengl : GL_TRIANGLES, GL_POINTS, GL_LINE_STRIP;

struct VertexSlice
{
	private GLenum _kind;

	enum Kind : GLenum { 
		Triangles = GL_TRIANGLES, 
		Points    = GL_POINTS, 
		LineStrip = GL_LINE_STRIP,
	}

	auto kind() const
	{
		return _kind;
	}

	auto kind(Kind kind)
	{
		final switch(kind)
		{
			case Kind.Triangles:
			case Kind.Points:
			case Kind.LineStrip:
				_kind = kind;
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
	
	private const GLenum _indexKind;
	private const ubyte  _indexTypeSize;
	
	this(R)(OpenGL gl, IVertexSpec vertex_specification, R vertices)
	{
		import std.range : ElementType;
		import std.typecons : Unqual, AliasSeq;
		import std.meta : staticIndexOf;

		import std.range : iota;
		auto indices = iota(0, cast(uint) vertices.length);

		// Unqualified element type of the index range
		alias IndexElementType = Unqual!(ElementType!(typeof(indices)));
		// Only unsigned byte, short and int are permitted to be used as element type
		// IndexElementKind is equal to 0 if element type is unsigned byte, 1 in case of
		// unsigned short, 2 in case of unsigned int and -1 in case of some other type
		enum IndexElementKind = staticIndexOf!(IndexElementType, AliasSeq!(ubyte, ushort, uint));
		// Check if element type of the index range is permitted one
		static assert (IndexElementKind >= 0 && IndexElementKind < 3, "Index has wrong type: `" ~ IndexElementType.stringof ~
			"`. Possible types are ubyte, ushort and uint.");

		import gfm.opengl : GL_UNSIGNED_BYTE, GL_UNSIGNED_SHORT, GL_UNSIGNED_INT;
		_indexKind = AliasSeq!(GL_UNSIGNED_BYTE, GL_UNSIGNED_SHORT, GL_UNSIGNED_INT)[IndexElementKind];
		_indexTypeSize = AliasSeq!(1, 2, 4)[IndexElementKind];
		
		import std.array : array;
		import gfm.opengl : GL_ARRAY_BUFFER, GL_STATIC_DRAW,
			GL_ELEMENT_ARRAY_BUFFER;

		assert(vertices.length);

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

	/// Тип, используемый для хранения индексов
	auto indexKind() { return _indexKind; }
	auto indexSize() { return _indexTypeSize; }

	GLBuffer      vbo, ibo;
	GLVAO         vao_points;
	IVertexSpec vert_spec;
}