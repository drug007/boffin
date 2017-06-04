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

        {
            const program_source =
                q{#version 330 core

                #if VERTEX_SHADER
                layout(location = 0) in vec3 position;
                layout(location = 1) in vec4 color;
                out vec4 vColor;
                uniform mat4 mvp_matrix;
                void main()
                {
                    gl_Position = mvp_matrix * vec4(position.xyz, 1.0);
                    gl_PointSize = 3.0;                
                    vColor = color;
                }
                #endif

                #if GEOMETRY_SHADER
                layout(points) in;
                layout(line_strip, max_vertices = 17) out;

                in vec4 vColor[]; // Output from vertex shader for each vertex
                out vec4 fColor;  // Output to fragment shader

                const float PI = 3.1415926;

                void main()
                {
                    fColor = vColor[0]; // Point has only one vertex

                    float size = 0.002;
                    float sides = 16;

                    for (int i = 0; i <= sides; i++) {
                        // Angle between each side in radians
                        float ang = PI * 2.0 / sides * i;

                        // Offset from center of point (3 and 4 to accomodate for aspect ratio)
                        vec4 offset = vec4(cos(ang) * 3 * size, -sin(ang) * 4 * size, 0.0, 0.0);
                        gl_Position = gl_in[0].gl_Position + offset;

                        EmitVertex();
                    }

                    EndPrimitive();
                }
                #endif

                #if FRAGMENT_SHADER
                in vec4 fColor;
                out vec4 color_out;

                void main()
                {
                    color_out = fColor;
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
                out vec4 vColor;
                uniform mat4 mvp_matrix;
                void main()
                {
                    gl_Position = mvp_matrix * vec4(position.xyz, 1.0);
                    gl_PointSize = 3.0;                
                    vColor = color;
                }
                #endif

                #if FRAGMENT_SHADER
                in vec4 vColor;
                out vec4 color_out;

                void main()
                {
                    color_out = vColor;
                }
                #endif
            };

            _line_program = new GLProgram(_gl, program_source);
        }

        import data : v12_89;

        glprovider = new GLProvider(_gl, new VertexSpecification!Vertex(_point_program), v12_89);
	}

	~this()
	{
		glprovider.destroy();
        _point_program.destroy();
        _line_program.destroy();

        _gl.destroy();
	}

	void draw(M)(ref M mvp)
	{
        {
    		_line_program.uniform("mvp_matrix").set(mvp);
            _line_program.use();
            scope(exit) _line_program.unuse();

            import data : vs12_89_line;
            glprovider.drawVertices(vs12_89_line);

            _gl.runtimeCheck();
        }

        {
            _point_program.uniform("mvp_matrix").set(mvp);
            _point_program.use();
            scope(exit) _point_program.unuse();

            import data : vs12_89_point;
            glprovider.drawVertices(vs12_89_point);

            _gl.runtimeCheck();
        }
    }

private:
	FileLogger _logger;
    OpenGL _gl;
    GLProgram _line_program, _point_program;
    GLProvider glprovider;
    VertexProvider vprovider;
    Vertex[] vertices;
}