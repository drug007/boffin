module batcher;

public import gfm.math: vec2f, vec3f, vec4f;
import gfm.opengl: GLenum, GL_TRIANGLES, GL_POINTS, GL_LINE_STRIP, GLBuffer, 
	OpenGL, GLVAO, GLProgram, VertexSpecification;

struct Vertex
{
    vec3f position;
    vec4f color;
    vec2f heading; // can't use float
}

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

class VertexProvider
{
    uint no;

	this(uint no, Vertex[] vertices, VertexSlice[] slices, bool visible = true)
	{
        assert(vertices.length);
        assert(slices.length);
        this.no      = no;
		_vertices    = vertices;
		_slices      = slices; 
		_curr_slices = slices.dup;
        _visible     = visible;
	}

	@property vertices()
	{
		return _vertices;
	}

	@property slices()
	{
		return _slices;
	}

	@property currSlices()
	{
		return _curr_slices;
	}

    @property currSlices(VertexSlice[] vs)
    {
        _curr_slices = vs;
    }

    @property visible()
    {
        return _visible;
    }

    @property visible(bool value)
    {
        _visible = value;
    }

private:
	VertexSlice[] _slices, _curr_slices;
	Vertex[]      _vertices;
    bool          _visible;
}

class GLProvider
{
    this(OpenGL gl, VertexSpecification!Vertex vertex_specification, Vertex[] vertices)
    {
    	import std.array : array;
    	import std.algorithm : map;
    	import std.range : iota;

    	import gfm.opengl : GL_ARRAY_BUFFER, GL_STATIC_DRAW,
    		GL_ELEMENT_ARRAY_BUFFER;

    	assert(vertices.length);

        _indices = iota(0, vertices.length).map!"cast(uint)a".array;

        _vbo = new GLBuffer(gl, GL_ARRAY_BUFFER, GL_STATIC_DRAW, vertices);
        _ibo = new GLBuffer(gl, GL_ELEMENT_ARRAY_BUFFER, GL_STATIC_DRAW, _indices);

        // Create an OpenGL vertex description from the Vertex structure.
        _vert_spec = vertex_specification;

        _vao_points = new GLVAO(gl);
        // prepare VAO
        {
            _vao_points.bind();
            _vbo.bind();
            _ibo.bind();
            _vert_spec.use();
            _vao_points.unbind();
        }
    }

    ~this()
    {
        if(_vbo)
        {
            _vbo.destroy();
            _vbo = null;
        }
        if(_ibo)
        {
            _ibo.destroy();
            _ibo = null;
        }
        if(_vert_spec)
        {
            _vert_spec.destroy();
            _vert_spec = null;
        }
        if(_vao_points)
        {
            _vao_points.destroy();
            _vao_points = null;
        }
    }

    void drawVertices(VertexSlice[] slices)
    {
    	import gfm.opengl : glDrawElements, GL_UNSIGNED_INT;

        _vao_points.bind();
        foreach(vslice; slices)
        {
            auto length = cast(int) vslice.length;
            auto start  = cast(int) vslice.start;

            glDrawElements(vslice.glKind, length, GL_UNSIGNED_INT, cast(void *)(start * 4));
        }
        _vao_points.unbind();
    }

    uint[]        _indices;
    GLBuffer      _vbo, _ibo;
    GLVAO         _vao_points;
    VertexSpecification!Vertex _vert_spec;
}