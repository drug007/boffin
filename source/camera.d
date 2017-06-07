module camera;

class Camera
{
    import gfm.math : mat4f, vec3f, vec2i;

    this(int width, int height)
    {
        viewport = vec2i(width, height);
        halfWorldWidth = 1.0;
        _model = mat4f.identity;
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

        // Итоговая матрица ModelViewProjection, которая является результатом перемножения наших трех матриц
        _mvp_matrix = _projection * _view * _model;
    }

    /// Проекция оконной координаты в точку на плоскости z = 0
    vec3f projectWindowToPlane0(in vec2i winCoords)
    {
        assert(winCoords.x >= 0);
        assert(winCoords.x <= _viewport.x);

        assert(winCoords.y >= 0);
        assert(winCoords.y <= _viewport.y);

        auto scale_x = 2 * halfWorldWidth / _viewport.x;
        auto scale_y = 2 * halfWorldWidth / _viewport.y / _aspect_ratio;

        auto x = winCoords.x * scale_x + position.x - halfWorldWidth;
        auto y = (_viewport.y - winCoords.y) * scale_y + position.y - halfWorldWidth / _aspect_ratio;

        return vec3f(x, y, 0.0f);
    }

    @property modelViewProjection() const
    {
        return _mvp_matrix;
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

protected:

    vec2i _viewport;

    float _aspect_ratio;

    mat4f _projection = void, 
          _view = void, 
          _mvp_matrix = void, 
          _model = void;
}