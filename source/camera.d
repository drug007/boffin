module camera;

class Camera
{
	import gfm.math : mat4f, vec3f, vec2i;

	this(int width, int height)
	{
		viewport = vec2i(width, height);
		halfWorldWidth = 1.0;
		position = vec3f(0, 0, 0);

		updateMatrices();
	}

	vec3f position;
	float halfWorldWidth;

	void updateMatrices()
	{
		_projection = mat4f.orthographic(-halfWorldWidth, +halfWorldWidth,-halfWorldWidth/_aspect_ratio, +halfWorldWidth/_aspect_ratio, -halfWorldWidth, +halfWorldWidth);

		// Матрица камеры
		_view = mat4f.lookAt(
			vec3f(position.x, position.y, +halfWorldWidth), // Камера находится в мировых координатах
			vec3f(position.x, position.y, -halfWorldWidth), // И направлена в начало координат
			vec3f(0, 1, 0)  // "Голова" находится сверху
		);

		auto model = mat4f.identity;

		_model_view = _view * model;

		// Итоговая матрица ModelViewProjection, которая является результатом перемножения наших трех матриц
		_mvp_matrix = _projection * _model_view;
	}

	/// create ray in world coordinate system from mouse coord
	vec3f rayFromMouseCoord(in vec2i mouse)
	{
		import gfm.math : vec4f;

		float x = (2.0f * mouse.x) / viewport.x - 1.0f;
		float y = 1.0f - (2.0f * mouse.y) / viewport.y;

		auto ray_nds = vec3f(x, y, 1.0f);
		auto ray_clip = vec4f(ray_nds.xy, -1.0, 1.0);
		auto ray_eye = _projection.inverse * ray_clip;
		ray_eye = vec4f(ray_eye.xy, -1.0, 0.0);
		auto ray_wor = (_view.inverse * ray_eye).xyz + position;

		return ray_wor;
	}

	@property modelViewProjection() const
	{
		return _mvp_matrix;
	}

	@property modelViewMatrix() const
	{
		return _model_view;
	}

	@property projectionMatrix() const
	{
		return _projection;
	}

	@property viewport() const
	{
		return _viewport;
	}

	@property viewport(vec2i v)
	{
		_aspect_ratio = v.x / cast(float) v.y;
		_viewport = v;
	}

	@property aspectRatio() const
	{
		return _aspect_ratio;
	}

	@property scale() const
	{
		return 2 * halfWorldWidth / _viewport.x;
	}

protected:

	vec2i _viewport;

	float _aspect_ratio;

	mat4f _projection = void, 
		  _model_view = void, 
		  _view = void, 
		  _mvp_matrix = void;
}