module uiwidget;

import dlangui.widgets.layouts : VerticalLayout;
import dlangui.core.events : MouseEvent, KeyEvent;
import dlangui.core.types : Rect, FILL_PARENT;
import dlangui.widgets.styles : Align;
import dlangui.core.logger : Log;
import dlangui.graphics.resources : DrawableRef, OpenGLDrawable;
import dlangui.graphics.scene.scene3d : Scene3d;

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
    private vec3f projectWindowToPlane0(in vec2i winCoords)
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

class UiWidget : VerticalLayout
{
    import maplayer : MapLayer;
    import gfm.math : vec2i, vec3f;

    this()
    {
    	import dlangui.dml.parser : parseML;

        super("OpenGLView");
        layoutWidth = FILL_PARENT;
        layoutHeight = FILL_PARENT;
        alignment = Align.Center;
        try {
            parseML(q{
                {
                  margins: 0
                  padding: 0
                  //backgroundImageId: "tx_fabric.tiled"
                  backgroundColor: 0x000000;
                  layoutWidth: fill
                  layoutHeight: fill

                  VerticalLayout {
                    id: glView
                    margins: 0
                    padding: 0
                    layoutWidth: fill
                    layoutHeight: fill
                    TextWidget { text: "Data Visualizer"; textColor: "red"; fontSize: 150%; fontWeight: 800; fontFace: "Arial" }
                    VSpacer { layoutWeight: 30 }
                    TextWidget { id: lblPosition; text: ""; backgroundColor: 0x80202020; textColor: 0xFFE0E0 }
                  }
                }
            }, "", this);
        } catch (Exception e) {
            Log.e("Failed to parse dml", e);
        }

        // assign OpenGL drawable to child widget background
        childById("glView").backgroundDrawable = DrawableRef(new OpenGLDrawable(&doDraw));

        _camera = new Camera(width, height);
        _camera.halfWorldWidth = 30_000.0f;
        _camera.position = vec3f(30_000, 30_000, 0);

        _layer = new MapLayer();

        focusable = true;
    }

    MapLayer _layer;
    Camera _camera;
    vec2i last_mouse_pos;

    /// process key event, return true if event is processed.
    override bool onMouseEvent(MouseEvent event)
    {
    	import dlangui.core.events : MouseAction;

        if (event.action == MouseAction.Move)
        {
        	auto delta = vec2i(event.x, event.y) - last_mouse_pos;
        	
        	if (event.rbutton.isDown)
        	{
        		_camera.position += vec3f(-delta.x, delta.y, 0) * _camera.halfWorldWidth / 1000.0f;
        	}
        	
        	last_mouse_pos = vec2i(event.x, event.y);

            _camera.viewport = vec2i(width, height);
            auto world_pos = _camera.projectWindowToPlane0(last_mouse_pos);// + _camera.position;

            import std.format : format;
            childById("lblPosition").text = format("%d\t%d\t%.2f\t%.2f"d, 
                last_mouse_pos.x, last_mouse_pos.y,
                world_pos.x, world_pos.y
            );
        }
        else if (event.action == MouseAction.Wheel)
        {
            if (event.wheelDelta)
            {
            	enum delta = 0.05;
            	_camera.halfWorldWidth *= (1 + delta*event.wheelDelta);
            }
        }
        return true;
    }

    /// process key event, return true if event is processed.
    override bool onKeyEvent(KeyEvent event) {
        //if (event.action == KeyAction.KeyDown) {
        //    switch(event.keyCode) with(KeyCode) {
        //        case KEY_W:
        //        case UP:
        //            _world.camPosition.forward(1);
        //            updateCamPosition();
        //            return true;
        //        case DOWN:
        //        case KEY_S:
        //            _world.camPosition.backward(1);
        //            updateCamPosition();
        //            return true;
        //        case KEY_A:
        //        case LEFT:
        //            _world.camPosition.turnLeft();
        //            updateCamPosition();
        //            return true;
        //        case KEY_D:
        //        case RIGHT:
        //            _world.camPosition.turnRight();
        //            updateCamPosition();
        //            return true;
        //        case HOME:
        //        case KEY_E:
        //            _world.camPosition.moveUp();
        //            updateCamPosition();
        //            return true;
        //        case END:
        //        case KEY_Q:
        //            _world.camPosition.moveDown();
        //            updateCamPosition();
        //            return true;
        //        case KEY_Z:
        //            _world.camPosition.moveLeft();
        //            updateCamPosition();
        //            return true;
        //        case KEY_C:
        //            _world.camPosition.moveRight();
        //            updateCamPosition();
        //            return true;
        //        case KEY_F:
        //            flying = !flying;
        //            if (!flying)
        //                _world.camPosition.pos.y = CHUNK_DY - 3;
        //            updateCamPosition();
        //            return true;
        //        case KEY_U:
        //            enableMeshUpdate = !enableMeshUpdate;
        //            updateCamPosition();
        //            return true;
        //        default:
        //            return false;
        //    }
        //}
        return false;
    }

    /// returns true is widget is being animated - need to call animate() and redraw
    @property override bool animating() { return true; }

    /// animates window; interval is time left from previous draw, in hnsecs (1/10000000 of second)
    override void animate(long interval) {
    }

    /// this is OpenGLDrawableDelegate implementation
    private void doDraw(Rect windowRect, Rect rc) {
    	
    	import dlangui.graphics.glsupport;
        import gfm.math : mat4f, vec2i;

    	const int MAX_VIEW_DISTANCE = 120;

    	// clear the whole window
        glViewport(0, 0, rc.width, rc.height);
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        _camera.viewport(vec2i(rc.width, rc.height));
        _camera.updateMatrices();

        mat4f mvp = _camera.modelViewProjection;
        auto aspect_ratio = _camera.aspectRatio;
        _layer.draw(mvp, aspect_ratio, rc.width);
    }

    ~this() {
    	destroy(_camera);
        destroy(_layer);
    }
}