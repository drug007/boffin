module render;

import gfm.opengl;

final class SceneState
{
	import camera : Camera;

	this(Camera camera)
	{
		_camera = camera;
	}

	auto camera() { return _camera; }

private:
	Camera _camera;
}

final class DrawState
{
	import vertex_data : VertexData;

	OpenGL gl;
	GLProgram program;
	VertexData vertex_data;

	this(OpenGL gl, GLProgram program, VertexData vertex_data)
	{
		this.gl          = gl;
		this.program     = program;
		this.vertex_data = vertex_data;
	}
}

final class Render
{
	void draw(GLenum mode, size_t start, size_t length, SceneState scene_state, DrawState draw_state)
	{
		{
			draw_state.program.uniform("mvp_matrix").set(cast()scene_state.camera.modelViewProjection);
			draw_state.program.use();
			scope(exit) draw_state.program.unuse();

			with(draw_state.vertex_data)
			{
				import gfm.opengl : glDrawElements, GL_UNSIGNED_INT;

				vao_points.bind();
				glDrawElements(mode, cast(int) length, GL_UNSIGNED_INT, cast(void *)(start * indexSize()));
				vao_points.unbind();
			}

			draw_state.gl.runtimeCheck();
		}
	}
}