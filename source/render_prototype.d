module render_prototype;

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

import gfm.opengl : GL_COLOR_BUFFER_BIT, GL_DEPTH_BUFFER_BIT, GL_STENCIL_BUFFER_BIT;
enum ClearBuffers
	{
		ColorBuffer = GL_COLOR_BUFFER_BIT,
		DepthBuffer = GL_DEPTH_BUFFER_BIT,
		StencilBuffer = GL_STENCIL_BUFFER_BIT,
		ColorAndDepthBuffer = ColorBuffer | DepthBuffer, 
		All = ColorBuffer | DepthBuffer | StencilBuffer
	}

struct ClearState
{
	import gfm.math : vec4f;

	//ScissorTest scissor_test = new ScissorTest();
	//ColorMask color_mask = new ColorMask(true, true, true, true);
	bool DepthMask = true;
	//int front_stencil_mask = ~0;
	//int back_stencil_mask = ~0;

	ClearBuffers buffers = ClearBuffers.All;
	vec4f color = vec4f(1.0f, 0.0f, 0.0f, 0.5f);
	float depth = 1;
	//int stencil = 0;
}

import gfm.opengl : GL_POINTS, GL_LINES, GL_LINE_LOOP, GL_LINE_STRIP, 
	GL_TRIANGLES, GL_TRIANGLE_STRIP, GL_TRIANGLE_FAN, GL_LINES_ADJACENCY, 
	GL_LINE_STRIP_ADJACENCY, GL_TRIANGLES_ADJACENCY, GL_TRIANGLE_STRIP_ADJACENCY;

enum PrimitiveType
	{
		Points = GL_POINTS,
		Lines = GL_LINES,
		LineLoop = GL_LINE_LOOP,
		LineStrip = GL_LINE_STRIP,
		Triangles = GL_TRIANGLES,
		TriangleStrip = GL_TRIANGLE_STRIP,
		TriangleFan = GL_TRIANGLE_FAN,
		LinesAdjacency = GL_LINES_ADJACENCY,
		LineStripAdjacency = GL_LINE_STRIP_ADJACENCY,
		TrianglesAdjacency = GL_TRIANGLES_ADJACENCY,
		TriangleStripAdjacency = GL_TRIANGLE_STRIP_ADJACENCY,
	}

enum DepthTestFunction
	{
		Never,
		Less,
		Equal,
		LessThanOrEqual,
		Greater,
		NotEqual,
		GreaterThanOrEqual,
		Always,
	}

enum EnableCap
	{
		DepthTest,
	}

struct DepthTest
{
private:
	bool _enabled = true;
	DepthTestFunction _func = DepthTestFunction.Less;
public:
	@property
	{
		auto enabled() const { return _enabled; }
		auto enabled(bool value) { _enabled = value; }

		auto func() const { return _func; }
		auto func(DepthTestFunction value) { _func = value; }
	}
}

struct VertexArray
{
	import gfm.opengl : OpenGL;

	auto bind() const
	{
		(cast()_vao).bind();
	}

	this(VertexRange)(OpenGL gl, IVertexSpec vertex_specification, VertexRange vertices)
	{
		//import std.range : ElementType;
		//static assert(is(ElementType!VertexRange == Vertex));
		
		import std.array : array;
		import std.algorithm : map;
		import std.range : iota;

		import gfm.opengl : GL_ARRAY_BUFFER, GL_STATIC_DRAW,
			GL_ELEMENT_ARRAY_BUFFER;

		assert(vertices.length);

		auto indices = iota(0, vertices.length).map!"cast(uint)a";

		_vbo = new GLBuffer(gl, GL_ARRAY_BUFFER, GL_STATIC_DRAW, vertices.array);
		_ibo = new GLBuffer(gl, GL_ELEMENT_ARRAY_BUFFER, GL_STATIC_DRAW, indices.array);

		// Create an OpenGL vertex description from the Vertex structure.
		_vert_spec = vertex_specification;

		_vao = new GLVAO(gl);
		// prepare VAO
		{
			_vao.bind();
			_vbo.bind();
			_ibo.bind();
			_vert_spec.use();
			_vao.unbind();
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
		if(_vao)
		{
			_vao.destroy();
			_vao = null;
		}
	}
private:
	import gfm.opengl : GLVAO, VertexSpecification, GLBuffer;

	GLBuffer      _vbo, _ibo;
	GLVAO         _vao;
	IVertexSpec _vert_spec;
}

struct RenderState
{
	//PrimitiveRestart primitive_restart;
	//FacetCulling facet_culling;
	//RasterizationMode rasterization_mode;
	//ScissorTest scissor_test;
	//StencilTest stencil_test;
	DepthTest depth_test;
	//DepthRange depth_range;
	//Blending blending;
	//ColorMask color_mask;
	bool depth_mask;
}

struct DrawState
{
	import gfm.opengl : GLProgram;

	RenderState render_state;
	GLProgram program;
	VertexArray va;
}

struct SceneState
{

}

struct Device
{
private:

	import std.experimental.logger : FileLogger;
	import gfm.opengl : OpenGL, GLShader;

	OpenGL _gl;
	FileLogger _logger;

	@disable
	this(this);
	@disable
	this();

public:

	auto makeProgram(GLShader[] shaders)
	{
		import gfm.opengl : GLProgram;

		return new GLProgram(_gl, shaders);
	}

	static
	{
		auto make()
		{
			import gfm.opengl : GLVersion;
			import std.stdio : stdout;

			Device d = Device.init;
			
			d._logger = new FileLogger(stdout);
			d._gl = new OpenGL(d._logger);

			return d;
		}
	}
}

struct Context
{
public:

	this(int width, int height, ref const(DrawState) draw_state, 
		ref const(vec4f) clear_color,
		float clear_depth)
	{
		_viewport.x = width;
		_viewport.y = height;
		_render_state = draw_state.render_state;
		_clear_color = clear_color;
		_clear_depth = clear_depth;
	}

	void clear (ref const(ClearState) clear_state)
	{
		import gfm.opengl : glClear, glClearColor, glClearDepth;

		//ApplyFramebuffer();

		//ApplyScissorTest(clear_state.ScissorTest);
		//ApplyColorMask(clear_state.ColorMask);
		//ApplyDepthMask(clear_state.depth_mask);

		if (_clear_color != clear_state.color)
		{
			with(clear_state.color)
				glClearColor(r, g, b, a);
			_clear_color = clear_state.color;
		}

		//import std.math : approxEqual;
		//if (!_clear_depth.approxEqual(clear_state.depth))
		//{
		//	glClearDepth(cast(double)clear_state.depth);
		//	_clear_depth = clear_state.depth;
		//}

		////if (_clear_stencil != clear_state.stencil)
		////{
		////    glClearStencil(clear_state.stencil);
		////    _clear_stencil = clear_state.stencil;
		////}

		glClear(clear_state.buffers);
	}

	void draw (PrimitiveType primitiveType, 
		int offset, int count, 
		ref const(DrawState) draw_state, 
		ref const(SceneState) scene_state)
	{
		import gfm.opengl : glDrawArrays, glDrawRangeElements;

{
	import gfm.math;
	const halfWorldWidth = 10000;
	const _aspect_ratio = 4.0/3.0;
	const vec3f position = vec3f(0, 0, 0);
	auto _projection = mat4f.orthographic(-halfWorldWidth, +halfWorldWidth,-halfWorldWidth/_aspect_ratio, +halfWorldWidth/_aspect_ratio, -halfWorldWidth, +halfWorldWidth);
	const _model = mat4f.identity;

	// Матрица камеры
	auto _view = mat4f.lookAt(
		vec3f(position.x, position.y, +halfWorldWidth), // Камера находится в мировых координатах
		vec3f(position.x, position.y, -halfWorldWidth), // И направлена в начало координат
		vec3f(0, 1, 0)  // "Голова" находится сверху
	);

	// Итоговая матрица ModelViewProjection, которая является результатом перемножения наших трех матриц
	auto _mvp_matrix = _projection * _view * _model;

	(cast()draw_state.program).uniform("mvp_matrix").set(_mvp_matrix);
	(cast()draw_state.program).uniform("resolution").set(vec2i(400, 300));
}

		//verifyDraw(draw_state, scene_state);
		applyBeforeDraw(draw_state, scene_state);
		
		//VertexArrayGL3x vertexArray = (VertexArrayGL3x)draw_state.VertexArray;
		//IndexBufferGL3x indexBuffer = vertexArray.IndexBuffer as IndexBufferGL3x;
		
		if (draw_state.va._ibo !is null)
		{
			import gfm.opengl : glDrawElements, GL_UNSIGNED_INT;
			//glDrawRangeElements(TypeConverterGL3x.To(primitiveType),
		 //       0, vertexArray.MaximumArrayIndex(), count,
		 //       TypeConverterGL3x.To(indexBuffer.Datatype), new
		 //       IntPtr(offset * VertexArraySizes.SizeOf(indexBuffer.Datatype)));
			glDrawElements(primitiveType, 0, GL_UNSIGNED_INT, cast(void *) 0);
		}
		else
		{
			glDrawArrays(primitiveType, offset, count);
		}
	}

private:
	import gfm.opengl : GLProgram;
	import gfm.math: vec4f, vec2i;

	GLProgram _program;
	RenderState _render_state;
	vec4f _clear_color;
	float _clear_depth;
	vec2i _viewport;

	//void VerifyDraw(ref const(DrawState) draw_state, ref const(SceneState) scene_state)
	//{
	//	//if (draw_state == null)
	//	//{
	//	//	throw new ArgumentNullException("draw_state");
	//	//}

	//	//if (draw_state.RenderState == null)
	//	//{
	//	//	throw new ArgumentNullException("draw_state.RenderState");
	//	//}

	//	if (draw_state.ShaderProgram == null)
	//	{
	//		throw new ArgumentNullException("draw_state.ShaderProgram");
	//	}

	//	if (draw_state.VertexArray == null)
	//	{
	//		throw new ArgumentNullException("draw_state.VertexArray");
	//	}

	//	if (scene_state == null)
	//	{
	//		throw new ArgumentNullException("scene_state");
	//	}

	//	if (_setFramebuffer != null)
	//	{
	//		if (draw_state.render_state.DepthTest.Enabled &&
	//			!((_setFramebuffer.DepthAttachment != null) || 
	//			  (_setFramebuffer.DepthStencilAttachment != null)))
	//		{
	//			throw new ArgumentException("The depth test is enabled (draw_state.render_state.DepthTest.Enabled) but the context's Framebuffer property doesn't have a depth or depth/stencil attachment (DepthAttachment or DepthStencilAttachment).", "draw_state");
	//		}
	//	}
	//}

	void applyBeforeDraw(ref const(DrawState) draw_state, ref const(SceneState) scene_state)
    {
        //applyRenderState(draw_state.render_state);
        applyVertexArray(draw_state.va);
        applyShaderProgram(draw_state, scene_state);

        //_textureUnits.clean();
        //applyFramebuffer();
    }

    void applyRenderState(ref const(RenderState) render_state)
    {
        //ApplyPrimitiveRestart(renderState.PrimitiveRestart);
        //ApplyFacetCulling(renderState.FacetCulling);
        //ApplyProgramPointSize(renderState.ProgramPointSize);
        //ApplyRasterizationMode(renderState.RasterizationMode);
        //ApplyScissorTest(renderState.ScissorTest);
        //ApplyStencilTest(renderState.StencilTest);
        applyDepthTest(render_state.depth_test);
        //ApplyDepthRange(renderState.DepthRange);
        //ApplyBlending(renderState.Blending);
        //ApplyColorMask(renderState.ColorMask);
        //ApplyDepthMask(renderState.DepthMask);
    }

    void applyVertexArray(ref const(VertexArray) vertex_array)
    {
        vertex_array.bind();
        //vertex_array.clean();
    }

    void applyShaderProgram(ref const(DrawState) draw_state, ref const(SceneState) scene_state)
    {
        //if (_program !is draw_state.program)
        {
            (cast()draw_state.program).use();
            _program = cast() draw_state.program;
        }
        //draw_state.program.clean(this, drawState, sceneState);

     //   debug
     //   {
	    //    GL.ValidateProgram(_boundShaderProgram.Handle.Value);

	    //    int validateStatus;
	    //    GL.GetProgram(_boundShaderProgram.Handle.Value, ProgramParameter.ValidateStatus, out validateStatus);
	    //    if (validateStatus == 0)
	    //    {
	    //        throw new ArgumentException(
	    //            "Shader program validation failed: " + _boundShaderProgram.Log, 
	    //            "drawState.ShaderProgram");
	    //    }
	    //}
    }

	void applyDepthTest(ref const(DepthTest) depth_test)
	{
		import gfm.opengl : glDepthFunc;

		if (_render_state.depth_test.enabled != depth_test.enabled)
		{
			enable(EnableCap.DepthTest, depth_test.enabled) ;
			_render_state.depth_test.enabled = depth_test.enabled;
		}

		if (depth_test.enabled)
		{
			if (_render_state.depth_test.func != depth_test.func)
			{
				glDepthFunc(depth_test.func);
				_render_state.depth_test.func = depth_test.func;
			}
		}
	}

	void enable(EnableCap enable_cap, bool enable)
	{
		import gfm.opengl : glEnable, glDisable;

		if ( enable )
			glEnable(enable_cap);
		else
			glDisable(enable_cap);
	}
}