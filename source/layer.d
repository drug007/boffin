module layer;

import camera : Camera;
import render : Render;

interface ILayer
{
	void draw(Render render, Camera camera);
}