module maplayer;

class MapLayer
{
	import std.experimental.logger : NullLogger, FileLogger;
	import gfm.opengl : OpenGL, GLProgram;
	import batcher : GLProvider, Vertex, VertexProvider, VertexSlice;

	this()
	{
		import gfm.opengl;

		import std.stdio : stdout;
        _logger = new FileLogger(stdout);
        _gl = new OpenGL(_logger);

        // reload OpenGL now that a context exists
        _gl.reload();

        // redirect OpenGL output to our Logger
        _gl.redirectDebugOutput();

        glEnable( GL_PROGRAM_POINT_SIZE );

        // create a shader program made of a single fragment shader
        const program_source =
            q{#version 330 core

            #if VERTEX_SHADER
            layout(location = 0) in vec3 position;
            layout(location = 1) in vec4 color;
            out vec4 fragment;
            uniform mat4 mvp_matrix;
            void main()
            {
                gl_Position = mvp_matrix * vec4(position.xyz, 1.0);
                gl_PointSize = 3.0;                
                fragment = color;
            }
            #endif

            #if FRAGMENT_SHADER
            in vec4 fragment;
            out vec4 color_out;

            void main()
            {
                color_out = fragment;
            }
            #endif
        };

        import gfm.math : vec3f, vec4f;
        vertices = [
        	Vertex(vec3f(-10000.0, -10000.0, 0.0), vec4f(1.0, 0.0, 0.0, 1.0)), 
            Vertex(vec3f( 10000.0, -10000.0, 0.0), vec4f(1.0, 1.0, 0.0, 1.0)),
            Vertex(vec3f( 10000.0,  10000.0, 0.0), vec4f(1.0, 0.0, 1.0, 1.0)),
            Vertex(vec3f(-10000.0,  10000.0, 0.0), vec4f(1.0, 1.0, 1.0, 1.0)),
            Vertex(vec3f(-10000.0, -10000.0, 0.0), vec4f(0.0, 0.0, 1.0, 1.0)), 
        ];

        program = new GLProgram(_gl, program_source);
        glprovider = new GLProvider(_gl, program, vertices);
	}

	~this()
	{
		glprovider.destroy();
		program.destroy();

        _gl.destroy();
	}

	void draw(M)(ref M mvp)
	{
		program.uniform("mvp_matrix").set(mvp);
        program.use();
        scope(exit) program.unuse();

        glprovider.drawVertices([VertexSlice(VertexSlice.Kind.LineStrip, 0, 5)]);

        _gl.runtimeCheck();
    }
private:
	FileLogger _logger;
    OpenGL _gl;
    GLProgram program;
    GLProvider glprovider;
    VertexProvider vprovider;
    Vertex[] vertices;
}