module uiwidget;

import dlangui.widgets.layouts : VerticalLayout;
import dlangui.core.events : MouseEvent, KeyEvent;
import dlangui.core.types : Rect, FILL_PARENT;
import dlangui.widgets.styles : Align;
import dlangui.core.logger : Log;
import dlangui.graphics.resources : DrawableRef, OpenGLDrawable;
import dlangui.graphics.scene.scene3d : Scene3d;
import dlangui.graphics.scene.camera : Camera;
import dlangui.core.math3d : vec3;

class UiWidget : VerticalLayout
{
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

        _scene = new Scene3d();

        _cam = new Camera();
        _scale = 10_000.0f;

        _scene.activeCamera = _cam;

        import dlangui.graphics.scene.node : Node3d;
        import maplayer : MapLayer;
        _scene.addChild(new Node3d("RootNode", new MapLayer()));

        focusable = true;
    }

    float _scale;
    int lastMouseX;
    int lastMouseY;

    /// process key event, return true if event is processed.
    override bool onMouseEvent(MouseEvent event)
    {
    	import dlangui.core.events : MouseAction;

        if (event.action == MouseAction.ButtonDown)
        {
        	// do nothing
        }
        else if (event.action == MouseAction.Wheel)
        {
            if (event.wheelDelta)
            {
            	enum delta = 0.05;
            	_scale *= (1 + delta*event.wheelDelta);
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

    Scene3d _scene;
    Camera _cam;


    /// this is OpenGLDrawableDelegate implementation
    private void doDraw(Rect windowRect, Rect rc) {
    	
    	import dlangui.graphics.glsupport;

    	const int MAX_VIEW_DISTANCE = 120;

    	// clear the whole window
        glViewport(0, 0, width, height);
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        _cam.setOrtho(-_scale, _scale, -_scale, _scale, -_scale, _scale);
        _cam.setIdentity();
        
        _scene.drawScene(false);
    }

    ~this() {
        destroy(_scene);
    }
}