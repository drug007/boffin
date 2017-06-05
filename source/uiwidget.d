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
    import gfm.math : mat4f, vec3f, vec2f;

    this(float width, float height)
    {
        _viewport = vec2f(width, height);
        size = 1.0;
        _model = mat4f.identity;
        position = vec3f(0, 0, 0);

        updateMatrices();
    }

    vec3f position;
    float size;

    void updateMatrices()
    {
        _aspect_ratio = _viewport.x / _viewport.y;

        _projection = mat4f.orthographic(-size, +size,-size/_aspect_ratio, +size/_aspect_ratio, -size, +size);

        // Матрица камеры
        _view = mat4f.lookAt(
            vec3f(position.x, position.y, +size), // Камера находится в мировых координатах
            vec3f(position.x, position.y, -size), // И направлена в начало координат
            vec3f(0, 1, 0)  // "Голова" находится сверху
        );

        // Итоговая матрица ModelViewProjection, которая является результатом перемножения наших трех матриц
        _mvp_matrix = _projection * _view * _model;
    }

    @property modelViewProjection() const
    {
        return _mvp_matrix;
    }

    @property viewport() const
    {
        return _viewport;
    }

    @property viewport(vec2f v)
    {
        _viewport = v;
    }

    @property aspectRatio() const
    {
        return _aspect_ratio;
    }

protected:

    vec2f _viewport;

    float _aspect_ratio;

    mat4f _projection = void, 
          _view = void, 
          _mvp_matrix = void, 
          _model = void;
}

class UiWidget : VerticalLayout
{
    import maplayer : MapLayer;
    import gfm.math : vec3f;

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

        _camera = new Camera(100, 100);
        _camera.size = 30_000.0f;
        _camera.position = vec3f(30_000, 30_000, 0);

        _layer = new MapLayer();

        focusable = true;
    }

    MapLayer _layer;
    Camera _camera;
    int lastMouseX;
    int lastMouseY;

    /// process key event, return true if event is processed.
    override bool onMouseEvent(MouseEvent event)
    {
    	import dlangui.core.events : MouseAction;

        if (event.action == MouseAction.Move)
        {
        	int deltaX = event.x - lastMouseX;
            int deltaY = event.y - lastMouseY;
        	
        	if (event.rbutton.isDown)
        	{
        		_camera.position += vec3f(-deltaX, deltaY, 0) * _camera.size / 1000.0f;
        	}
        	
        	lastMouseX = event.x;
            lastMouseY = event.y;
        }
        else if (event.action == MouseAction.Wheel)
        {
            if (event.wheelDelta)
            {
            	enum delta = 0.05;
            	_camera.size *= (1 + delta*event.wheelDelta);
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
        import gfm.math : mat4f, vec2f;

    	const int MAX_VIEW_DISTANCE = 120;

    	// clear the whole window
        glViewport(0, 0, rc.width, rc.height);
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        _camera.viewport(vec2f(rc.width, rc.height));
        _camera.updateMatrices();

        mat4f mvp = _camera.modelViewProjection;
        auto aspect_ratio = _camera.aspectRatio;
        _layer.draw(mvp, aspect_ratio);
    }

    ~this() {
    	destroy(_camera);
        destroy(_layer);
    }
}