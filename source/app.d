import dlangui.platforms.common.platform;

import uiwidget : UiWidget;

mixin APP_ENTRY_POINT;

/// entry point for dlangui based application
extern (C) int UIAppMain(string[] args)
{

	// create window
	Window window = Platform.instance.createWindow("Boffin", null, WindowFlag.Resizable, 600, 500);
	window.mainWidget = new UiWidget();

	// show window
	window.show();

	// run message loop
	return Platform.instance.enterMessageLoop();
}