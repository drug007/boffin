module render;

struct RenderState
{

}

struct DrawState
{

}

struct ClearState
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

	auto makeVao()
	{
		import gfm.opengl : GLVAO;

		return new GLVAO(_gl);
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
private:
	import gfm.opengl : GLProgram, GLVAO;

	GLProgram[] _program;
	GLVAO[] _vao;
	RenderState _state;

public:

	@property
	{
		auto program() { return _program; }
		auto vao()     { return _vao;    }
		auto state()   { return _state;  }
	}

	void opUnary(string op, T)(T hrs) if (op == "~")
	{
		static if (is(T == GLProgram))
		{
			_program ~= hrs;
		}
		else static if (is(T == GLVAO))
		{
			_vao ~= hrs;
		}
	}

	void clear();
	void draw();
}