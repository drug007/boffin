module track_layer;

struct Vertex
{
    import gfm.math : vec2f, vec3f, vec4f;
    vec3f position;
    vec4f color;
    vec2f heading; // can't use float
}

class TrackLayer
{
	import gfm.opengl : OpenGL, GLProgram, VertexSpecification;
    import gfm.math : vec2i;
	import batcher : GLProvider;

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
                layout(location = 1) in vec4 color;
                layout(location = 2) in vec2 heading;
                out vec4 vColor;
                out float vHeading;
                uniform mat4 mvp_matrix;
                void main()
                {
                    gl_Position = mvp_matrix * vec4(position.xyz, 1.0);
                    gl_PointSize = 3.0;
                    vColor = color;
                    vHeading = heading.x;
                }
                #endif

                #if GEOMETRY_SHADER
                layout(points) in;
                layout(line_strip, max_vertices = 19) out;

                in vec4 vColor[]; // Output from vertex shader for each vertex
                in float vHeading[];
                out vec4 fColor;  // Output to fragment shader

                uniform ivec2 resolution;

                const float PI = 3.1415926;

                void main()
                {
                    fColor = vColor[0]; // Point has only one vertex
                    float fHeading = vHeading[0];

                    float size = 8.0 / resolution.x;
                    float heading_length = 4 * size;
                    float aspect_ratio = resolution.x / float(resolution.y);
                    const float sides = 16;

                    gl_Position = gl_in[0].gl_Position;
                    EmitVertex();

                    vec4 offset = vec4(cos(fHeading) * heading_length, -sin(fHeading) * aspect_ratio * heading_length, 0.0, 0.0);
                    gl_Position = gl_in[0].gl_Position + offset;
                    EmitVertex();

                    EndPrimitive();

                    for (int i = 0; i <= sides; i++) {
                        // Angle between each side in radians
                        float ang = PI * 2.0 / sides * i;

                        // Offset from center of point
                        vec4 offset = vec4(cos(ang) * size, -sin(ang) * aspect_ratio * size, 0.0, 0.0);
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
                layout(location = 2) in float heading;
                out vec4 vColor;
                uniform mat4 mvp_matrix;
                uniform ivec2 resolution;
                void main()
                {
                    gl_Position = mvp_matrix * vec4(position.xyz, 1.0);
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

        _glprovider = new GLProvider!Vertex(_gl, new VertexSpecification!Vertex(_point_program), vertices);
	}

	~this()
	{
		_glprovider.destroy();
        _point_program.destroy();
        _line_program.destroy();
	}

	void draw(Matrix)(ref Matrix mvp, vec2i resolution)
	{
        {
    		_line_program.uniform("mvp_matrix").set(mvp);
            _line_program.use();
            scope(exit) _line_program.unuse();

            import data : vs12_89_line;
            _glprovider.drawVertices(vs12_89_line);

            _gl.runtimeCheck();
        }

        {
            _point_program.uniform("mvp_matrix").set(mvp);
            _point_program.uniform("resolution").set(resolution);
            _point_program.use();
            scope(exit) _point_program.unuse();

            import data : vs12_89_point;
            _glprovider.drawVertices(vs12_89_point);

            _gl.runtimeCheck();
        }
    }

private:
	OpenGL _gl;
    GLProgram _line_program, _point_program;
    GLProvider!Vertex _glprovider;
}