//Copyright (C) 2012 Potix Corporation. All Rights Reserved.
//History: Mon, Apr 23, 2012  6:10:07 PM
// Author: tomyeh

/**
 * The dashboard view.
 */
class Dashboard extends View {
	Dashboard() {
		layout.type = "linear";
		layout.orient = "vertical";

		appendChild(new TextView(html: '<h1 style="margin:0">Rikulo Simulator</h1>'));
		_addOrientation(this);
	}
	void _addOrientation(View parent) {
		View view = new View();
		_setHLayout(view);
		parent.appendChild(view);

		TextView text = new TextView("Orientation");
		view.appendChild(text);

		RadioButton horz = new RadioButton("horizontal", groupName: "orientation");
		view.appendChild(horz);
		RadioButton vert = new RadioButton("vertical", checked: true, groupName: "orientation");
		view.appendChild(vert);
	}
	void _setHLayout(View view) {
		view.layout.type = "linear";
		view.layout.width = "content";
		view.profile.width = "flex";
		view.profile.height = "content";
	}
}