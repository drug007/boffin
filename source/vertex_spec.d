module vertex_spec;

interface IVertexSpec
{
	import gfm.opengl : GLuint;

	void use(GLuint divisor = 0);

    /// Unuse this vertex specification. If you are using a VAO, you don't need to call it,
    /// since the attributes would be tied to the VAO activation.
    /// Throws: $(D OpenGLException) on error.
    void unuse();

    /// Returns the size of the Vertex; this size can be computer
    /// after you added all your attributes
    size_t vertexSize() pure const nothrow;
}

final class VertexSpec(Vertex) : IVertexSpec
{
	import gfm.opengl : GLProgram, VertexSpecification;

	this(GLProgram program)
	{
		_vs = new VertexSpecification!Vertex(program);
	}

	void use(GLuint divisor = 0)
	{
		_vs.use(divisor);
	}

    void unuse()
    {
    	_vs.unuse();
    }

    size_t vertexSize() pure const nothrow
    {
    	return _vs.vertexSize();
    }

private:
	VertexSpecification!Vertex _vs;
}