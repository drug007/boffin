module layer_render;

import camera : Camera;
import render : Render;

interface ILayerRender
{
	void draw(Render render, Camera camera);
}