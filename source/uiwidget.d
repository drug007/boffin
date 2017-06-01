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
        //_cam.translate(vec3(0, 14, -7));
        _scale = 10_000.0f;

        _scene.activeCamera = _cam;

        //static if (true) {
        //    _scene.skyBox.setFaceTexture(SkyBox.Face.Right, "skybox_night_right1");
        //    _scene.skyBox.setFaceTexture(SkyBox.Face.Left, "skybox_night_left2");
        //    _scene.skyBox.setFaceTexture(SkyBox.Face.Top, "skybox_night_top3");
        //    _scene.skyBox.setFaceTexture(SkyBox.Face.Bottom, "skybox_night_bottom4");
        //    _scene.skyBox.setFaceTexture(SkyBox.Face.Front, "skybox_night_front5");
        //    _scene.skyBox.setFaceTexture(SkyBox.Face.Back, "skybox_night_back6");
        //} else {
        //    _scene.skyBox.setFaceTexture(SkyBox.Face.Right, "debug_right");
        //    _scene.skyBox.setFaceTexture(SkyBox.Face.Left, "debug_left");
        //    _scene.skyBox.setFaceTexture(SkyBox.Face.Top, "debug_top");
        //    _scene.skyBox.setFaceTexture(SkyBox.Face.Bottom, "debug_bottom");
        //    _scene.skyBox.setFaceTexture(SkyBox.Face.Front, "debug_front");
        //    _scene.skyBox.setFaceTexture(SkyBox.Face.Back, "debug_back");
        //}

        //dirLightNode = new Node3d();
        //dirLightNode.rotateY(-15);
        //dirLightNode.translateX(2);
        //dirLightNode.translateY(3);
        //dirLightNode.translateZ(0);
        //dirLightNode.light = Light.createPoint(vec3(1.0, 1.0, 1.0), 55); //Light.createDirectional(vec3(1, 0.5, 0.5));
        ////dirLightNode.light = Light.createDirectional(vec3(1, 0.5, 0.5));
        //dirLightNode.light.enabled = true;
        //_scene.addChild(dirLightNode);


        //int x0 = 0;
        //int y0 = 0;
        //int z0 = 0;


        //_minerMesh = new Mesh(VertexFormat(VertexElementType.POSITION, VertexElementType.NORMAL, VertexElementType.COLOR, VertexElementType.TEXCOORD0));
        //_world = new World();

        //initWorldTerrain(_world);

        //int cy0 = 3;
        //for (int y = CHUNK_DY - 1; y > 0; y--)
        //    if (!_world.canPass(Vector3d(0, y, 0))) {
        //        cy0 = y;
        //        break;
        //    }
        //_world.camPosition = Position(Vector3d(0, cy0, 0), Vector3d(0, 0, 1));

        //_world.setCell(5, cy0 + 5, 7, BlockId.face_test);
        //_world.setCell(-5, cy0 + 5, 7, BlockId.face_test);
        //_world.setCell(5, cy0 + 5, -7, BlockId.face_test);
        //_world.setCell(3, cy0 + 5, 13, BlockId.face_test);


        ////_world.makeCastleWall(Vector3d(25, cy0 - 5, 12), Vector3d(1, 0, 0), 12, 30, 4, BlockId.brick);
        //_world.makeCastle(Vector3d(0, cy0, 60), 30, 12);

        //updateCamPosition(false);
        ////updateMinerMesh();

        //Material minerMaterial = new Material(EffectId("textured.vert", "textured.frag", null), "blocks");
        //minerMaterial.ambientColor = vec3(0.05,0.05,0.05);
        //minerMaterial.textureLinear = false;
        //minerMaterial.fogParams = new FogParams(vec4(0.01, 0.01, 0.01, 1), 12, 80);
        ////minerMaterial.specular = 10;
        //_minerDrawable = new MinerDrawable(_world, minerMaterial, _cam);
        ////_minerDrawable.autobindLights = false;
        ////Model minerDrawable = new Model(minerMaterial, _minerMesh);
        //Node3d minerNode = new Node3d("miner", _minerDrawable);
        //_scene.addChild(minerNode);

        import dlangui.graphics.scene.node : Node3d;
        import maplayer : MapLayer;
        _scene.addChild(new Node3d("RootNode", new MapLayer()));


        focusable = true;
    }

    //MinerDrawable _minerDrawable;

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

    //Node3d dirLightNode;

    ////void visit(World world, ref Position camPosition, Vector3d pos, cell_t cell, int visibleFaces) {
    ////    BlockDef def = BLOCK_DEFS[cell];
    ////    def.createFaces(world, world.camPosition, pos, visibleFaces, _minerMesh);
    ////}
    
    //bool flying = false;
    //bool enableMeshUpdate = true;
    //Vector3d _moveAnimationDirection;

    //void animateMoving() {
    //    if (_moveAnimationDirection != Vector3d(0,0,0)) {
    //        Vector3d animPos = _world.camPosition.pos + _moveAnimationDirection;
    //        vec3 p = vec3(animPos.x + 0.5f, animPos.y + 0.5f, animPos.z + 0.5f);
    //        if ((_animatingPosition - p).length < 2) {
    //            _world.camPosition.pos += _moveAnimationDirection;
    //            updateCamPosition(true);
    //        }
    //    }
    //}

    //void updateCamPosition(bool animateIt = true) {
    //    import std.string;
    //    import std.conv : to;
    //    import std.utf : toUTF32;
    //    import std.format;

    //    if (!flying) {
    //        animateMoving();
    //        while(_world.canPass(_world.camPosition.pos + Vector3d(0, -1, 0)))
    //            _world.camPosition.pos += Vector3d(0, -1, 0);
    //        if(!_world.canPass(_world.camPosition.pos + Vector3d(0, -1, 0))) {
    //            if (_world.canPass(_world.camPosition.pos + Vector3d(0, 1, 0)))
    //                _world.camPosition.pos += Vector3d(0, 1, 0);
    //            else if (_world.canPass(_world.camPosition.pos + Vector3d(1, 0, 0)))
    //                _world.camPosition.pos += Vector3d(1, 0, 0);
    //            else if (_world.canPass(_world.camPosition.pos + Vector3d(-1, 0, 0)))
    //                _world.camPosition.pos += Vector3d(-1, 0, 0);
    //            else if (_world.canPass(_world.camPosition.pos + Vector3d(0, 0, 1)))
    //                _world.camPosition.pos += Vector3d(0, 0, 1);
    //            else if (_world.canPass(_world.camPosition.pos + Vector3d(0, 0, -1)))
    //                _world.camPosition.pos += Vector3d(0, 0, -1);
    //            while(_world.canPass(_world.camPosition.pos + Vector3d(0, -1, 0)))
    //                _world.camPosition.pos += Vector3d(0, -1, 0);
    //        }
    //    }

    //    setPos(vec3(_world.camPosition.pos.x + 0.5f, _world.camPosition.pos.y + 0.5f, _world.camPosition.pos.z + 0.5f), animateIt);
    //    setAngle(_world.camPosition.direction.angle, animateIt);

    //    updatePositionMessage();
    //}

    //void updatePositionMessage() {
    //    import std.string : format;
    //    Widget w = childById("lblPosition");
    //    string dir = _world.camPosition.direction.dir.to!string;
    //    dstring s = format("pos(%d,%d) h=%d fps:%d %s    [F]lying: %s   [U]pdateMesh: %s", _world.camPosition.pos.x, _world.camPosition.pos.z, _world.camPosition.pos.y, 
    //                       _fps,
    //                       dir,
    //                       flying, 
    //                       enableMeshUpdate).toUTF32;
    //    w.text = s;
    //}

    //int _fps = 0;

    //void startMoveAnimation(Vector3d direction) {
    //    _moveAnimationDirection = direction;
    //    updateCamPosition();
    //}

    //void stopMoveAnimation() {
    //    _moveAnimationDirection = Vector3d(0, 0, 0);
    //    updateCamPosition();
    //}

    ////void updateMinerMesh() {
    ////    _minerMesh.reset();
    ////    long ts = currentTimeMillis;
    ////    _world.visitVisibleCells(_world.camPosition, this);
    ////    long duration = currentTimeMillis - ts;
    ////    Log.d("DiamondVisitor finished in ", duration, " ms  ", "Vertex count: ", _minerMesh.vertexCount);
    ////
    ////    invalidate();
    ////    //for (int i = 0; i < 20; i++)
    ////    //    Log.d("vertex: ", _minerMesh.vertex(i));
    ////}

    //World _world;
    //vec3 _position;
    //float _directionAngle = 0;
    //float _yAngle = -15;
    //float _angle;
    //vec3 _animatingPosition;
    //float _animatingAngle;
    //float _animatingYAngle;

    //void setPos(vec3 newPos, bool animateIt = false) {
    //    if (animateIt) {
    //        _position = newPos;
    //    } else {
    //        _animatingPosition = newPos;
    //        _position = newPos;
    //    }
    //}

    //void setAngle(float newAngle, bool animateIt = false) {
    //    if (animateIt) {
    //        _angle = newAngle;
    //    } else {
    //        _animatingAngle = newAngle;
    //        _angle = newAngle;
    //    }
    //}

    //void setYAngle(float newAngle, bool animateIt = false) {
    //    if (animateIt) {
    //        _yAngle = newAngle;
    //    } else {
    //        _animatingYAngle = newAngle;
    //        _yAngle = newAngle;
    //    }
    //}

    /// returns true is widget is being animated - need to call animate() and redraw
    @property override bool animating() { return true; }
    /// animates window; interval is time left from previous draw, in hnsecs (1/10000000 of second)
    override void animate(long interval) {
        ////Log.d("animating");
        //if (interval > 0) {
        //    int newfps = cast(int)(10000000.0 / interval);
        //    if (newfps < _fps - 3 || newfps > _fps + 3) {
        //        _fps = newfps;
        //        updatePositionMessage();
        //    }
        //}
        //animateMoving();
        //if (_animatingAngle != _angle) {
        //    float delta = _angle - _animatingAngle;
        //    if (delta > 180)
        //        delta -= 360;
        //    else if (delta < -180)
        //        delta += 360;
        //    float dist = delta < 0 ? -delta : delta;
        //    if (dist < 5) {
        //        _animatingAngle = _angle;
        //    } else {
        //        float speed = 360 / 2;
        //        float step = speed * interval / 10000000.0f;
        //        //Log.d("Rotate animation delta=", delta, " dist=", dist, " elapsed=", interval, " step=", step);
        //        if (step > dist)
        //            step = dist;
        //        delta = delta * (step /dist);
        //        _animatingAngle += delta;
        //    }
        //}
        //if (_animatingYAngle != _yAngle) {
        //    float delta = _yAngle - _animatingYAngle;
        //    if (delta > 180)
        //        delta -= 360;
        //    else if (delta < -180)
        //        delta += 360;
        //    float dist = delta < 0 ? -delta : delta;
        //    if (dist < 5) {
        //        _animatingYAngle = _yAngle;
        //    } else {
        //        float speed = 360 / 2;
        //        float step = speed * interval / 10000000.0f;
        //        //Log.d("Rotate animation delta=", delta, " dist=", dist, " elapsed=", interval, " step=", step);
        //        if (step > dist)
        //            step = dist;
        //        delta = delta * (step /dist);
        //        _animatingYAngle += delta;
        //    }
        //}
        //if (_animatingPosition != _position) {
        //    vec3 delta = _position - _animatingPosition;
        //    float dist = delta.length;
        //    if (dist < 0.01) {
        //        _animatingPosition = _position;
        //        // done
        //    } else {
        //        float speed = 8;
        //        if (dist > 2)
        //            speed = (dist - 2) * 3 + speed;
        //        float step = speed * interval / 10000000.0f;
        //        //Log.d("Move animation delta=", delta, " dist=", dist, " elapsed=", interval, " step=", step);
        //        if (step > dist)
        //            step = dist;
        //        delta = delta * (step / dist);
        //        _animatingPosition += delta;
        //    }
        //}
        //invalidate();
    }
    //float angle = 0;

    Scene3d _scene;
    Camera _cam;
    //Mesh _minerMesh;


    /// this is OpenGLDrawableDelegate implementation
    private void doDraw(Rect windowRect, Rect rc) {
    	
    	import dlangui.graphics.glsupport;

    	const int MAX_VIEW_DISTANCE = 120;

    	// clear the whole window
        glViewport(0, 0, width, height);
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        //_cam.setPerspective(rc.width, rc.height, 45.0f, 0.3, MAX_VIEW_DISTANCE);
        _cam.setOrtho(-_scale, _scale, -_scale, _scale, -_scale, _scale);
        _cam.setIdentity();
        //_cam.translate(_animatingPosition);
        //_cam.rotateY(_animatingAngle);
        //_cam.rotateX(_yAngle);
        

        ////dirLightNode.setIdentity();
        ////dirLightNode.translate(_animatingPosition);
        ////dirLightNode.rotateY(_animatingAngle);

        //checkgl!glEnable(GL_CULL_FACE);
        ////checkgl!glDisable(GL_CULL_FACE);
        //checkgl!glEnable(GL_DEPTH_TEST);
        //checkgl!glCullFace(GL_BACK);
        
        ////Log.d("Drawing position ", _animatingPosition, " angle ", _animatingAngle);

        _scene.drawScene(false);

        //checkgl!glDisable(GL_DEPTH_TEST);
        //checkgl!glDisable(GL_CULL_FACE);
    }

    private void doRootDraw(Rect windowRect, Rect rc)
    {

    }

    ~this() {
        destroy(_scene);
        //destroy(_world);
    }
}