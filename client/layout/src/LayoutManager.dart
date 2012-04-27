//Copyright (C) 2012 Potix Corporation. All Rights Reserved.
//History: Thu, Mar 15, 2012  9:56:30 AM
// Author: tomyeh

/**
 * The layout mananger that manages the layout controllers ([Layout]).
 * There is exactly one layout manager per application.
 */
class LayoutManager extends RunOnceViewManager implements Layout {
	final Map<String, Layout> _layouts;
	final Set<String> _imgWaits;

	LayoutManager(): super(true), _layouts = {}, _imgWaits = new Set() {
		addLayout("linear", new LinearLayout());
		FreeLayout freeLayout = new FreeLayout();
		addLayout("none", freeLayout);
		addLayout("", freeLayout);
	}

	/** Adds the layout for the given name.
	 */
	Layout addLayout(String name, Layout layout) {
		final Layout old = _layouts[name];
		_layouts[name] = layout;
		return old;
	}
	/** Removes the layout of the given name if any.
	 */
	Layout removeLayout(String name) {
		return _layouts.remove(name);
	}
	/** Returns the layout of the given name, or null if not found.
	 */
	Layout getLayout(String name) {
		return _layouts[name];
	}

	//@Override Layout
	int measureWidth(MeasureContext mctx, View view)
	=> _layoutOfView(view).measureWidth(mctx, view);
	//@Override Layout
	int measureHeight(MeasureContext mctx, View view)
	=> _layoutOfView(view).measureHeight(mctx, view);
	//@Override Layout
	void layout(MeasureContext mctx, View view) {
		if (mctx === null) {
			if (_imgWaits.isEmpty())
				flush(view);
			else if (view !== null)
				queue(view); //do it later
		} else {
			_doLayout(mctx, view);
		}
	}

	Layout _layoutOfView(View view) {
		final String name = view.layout.type;
		final Layout clayout = getLayout(name);
		if (clayout == null)
			throw new UiException("Unknown layout, ${name}");
		return clayout;
	}

	//@Override RunOnceViewManager
	void handle_(View view) {
		_doLayout(new MeasureContext(), view);
	}
	void _doLayout(MeasureContext mctx, View view) {
		_layoutOfView(view).layout(mctx, view);
		view.onLayout();
	}

	/** Set the width of the given view based on its profile.
	 * It is an utility for implementing a layout.
	 * <p>[defaultWidth] is used if the profile's width is not specified. Ignored if null.
	 */
	void setWidthByProfile(MeasureContext mctx, View view, AsInt width, [AsInt defaultWidth]) {
		final LayoutAmountInfo amt = new LayoutAmountInfo(view.profile.width);
		switch (amt.type) {
		case LayoutAmountInfo.NONE:
			if (defaultWidth !== null)
				view.width = defaultWidth();
			break;
		case LayoutAmountInfo.FIXED:
			view.width = amt.value;
			break;
		case LayoutAmountInfo.FLEX:
			view.width = width();
			break;
		case LayoutAmountInfo.RATIO:
			view.width = (width() * amt.value).round().toInt();
			break;
		case LayoutAmountInfo.CONTENT:
			final int wd = view.measureWidth(mctx);
			if (wd != null)
				view.width = wd;
			break;
		}
	}
	/** Set the height of the given view based on its profile.
	 * It is an utility for implementing a layout.
	 * <p>[defaultHeight] is used if the profile's height is not specified. Ignored if null.
	 */
	void setHeightByProfile(MeasureContext mctx, View view, AsInt height, [AsInt defaultHeight]) {
		final LayoutAmountInfo amt = new LayoutAmountInfo(view.profile.height);
		switch (amt.type) {
		case LayoutAmountInfo.NONE:
			if (defaultHeight !== null)
				view.height = defaultHeight();
			break;
		case LayoutAmountInfo.FIXED:
			view.height = amt.value;
			break;
		case LayoutAmountInfo.FLEX:
			view.height = height();
			break;
		case LayoutAmountInfo.RATIO:
			view.height = (height() * amt.value).round().toInt();
			break;
		case LayoutAmountInfo.CONTENT:
			final int hgh = view.measureHeight(mctx);
			if (hgh != null)
				view.height = hgh;
			break;
		}
	}
	/** Measures the width based on the view's content.
	 * It is an utility for implementing a view's [View.measureWidth].
	 * This method assumes the browser will resize the view automatically,
	 * so it is applied only to a leaf view with some content, such as [TextView]
	 * and [Button].
	 * <p>[autowidth] specifies whether to adjust the width automatically.
	 */
	int measureWidthByContent(MeasureContext mctx, View view, bool autowidth) {
		int wd = mctx.widths[view];
		return wd !== null || mctx.widths.containsKey(view) ? wd:
			_measureByContent(mctx, view, autowidth).width;
	}
	/** Measures the height based on the view's content.
	 * It is an utility for implementing a view's [View.measureHeight].
	 * This method assumes the browser will resize the view automatically,
	 * so it is applied only to a leaf view with some content, such as [TextView]
	 * and [Button].
	 * <p>[autowidth] specifies whether to adjust the width automatically.
	 */
	int measureHeightByContent(MeasureContext mctx, View view, bool autowidth) {
		int hgh = mctx.heights[view];
		return hgh !== null || mctx.heights.containsKey(view) ? hgh:
			_measureByContent(mctx, view, autowidth).height;
	}
	Size _measureByContent(MeasureContext mctx, View view, bool autowidth) {
		CSSStyleDeclaration nodestyle;
		String orgval;
		if (autowidth) {
			nodestyle = view.node.style;
			orgval = nodestyle.position;
			if (orgval != "fixed" && orgval != "static") {
				orgval = nodestyle.whiteSpace;
				if (orgval === null) orgval = ""; //TODO: no need if Dart handles it
				nodestyle.whiteSpace = "nowrap";
				//Node: an absolute DIV's width will be limited by its parent's width
				//so we have to unlimit it (by either nowrap or fixed/staic position)
			} else {
				orgval = null;
			}
		}

		final DomQuery qview = new DomQuery(view);
		final Size size = new Size(qview.outerWidth, qview.outerHeight);

		if (orgval !== null) {
			nodestyle.whiteSpace = orgval; //restore
		}

		if (autowidth && size.width > browser.size.width) { //TODO: use profile.maxWidth instead
			orgval = nodestyle.width;
			if (orgval === null) orgval = ""; //TODO: no need if Dart handles it
			nodestyle.width = browser.size.width; //TODO: use profile.maxWidth

			size.width = qview.outerWidth;
			size.height = qview.outerHeight;

			nodestyle.width = orgval; //restore
		}

		mctx.widths[view] = size.width;
		mctx.heights[view] = size.height;
		return size;
	}

	/** Wait until the given image is loaded.
	 * If the width and height of the image is not known in advance, this method
	 * shall be called to make the layout manager wait until the image is loaded.
	 * <p>Currently, [Image] will invoke this method if the width or height of
	 * the image is not specified.
	 */
	void waitImageLoaded(String imgURI) {
		if (!_imgWaits.contains(imgURI)) {
			_imgWaits.add(imgURI);
			final ImageElement img = new Element.tag("img");
			var func = (event) {
				_onImageLoaded(imgURI);
			};
			img.on.load.add(func);
			img.on.error.add(func);
			img.src = imgURI;
		}
	}
	void _onImageLoaded(String imgURI) {
		_imgWaits.remove(imgURI);
		if (_imgWaits.isEmpty())
			flush(); //flush all
	}
}

/** The layout manager.
 */
LayoutManager layoutManager;
