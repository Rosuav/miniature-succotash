//Huh. Something's completely not working here.
//I may have run into a Pike bug, or it may be a GTK2 limitation (no
//drawing on the root), or it could just be that I'm misunderstanding
//what's going on. Hrm.

/* The theory here was to be able to "point" to someone else's screen.
It may be possible to create an always-on-top window that is mostly
transparent, but this may depend on display compositing. Does that even
exist on non-Linux platforms? */

/* Alternatively, could move the pointer thus:
GTK2.move_cursor_abs(root, 300,300); //disp->get_pointer();
The get_pointer is critical if no backend is active. I don't understand
this, but presumably the actual movement happens in an event loop.
*/
object root;
constant XSIZE = 50, YSIZE = 50; //NOTE: Some things may not work if it's not square. Untested.
constant XMID = XSIZE/2, YMID = YSIZE/2; //Used very frequently
array(Image.Image) circles = allocate(XMID);
array(GTK2.GdkBitmap) circlebmp;
GTK2.GdkBitmap empty;

//Borrowed from Gypsum
array bits = map(enumerate(8),lambda(int x) {return ({x&1,!!(x&2),!!(x&4)});});
array color_defs = bits[*][*]*255;
array colors;

void cycle(object win, int|void pos, int|void col)
{
	if (!win) return; //Window is gone.
	if (pos == XMID)
	{
		pos = 0;
		col = (col + 1) % sizeof(colors);
		win->modify_bg(GTK2.STATE_NORMAL, colors[col]);
	}
	win->shape_combine_mask(circlebmp[pos], 0, 0);
	call_out(cycle, 0.01, win, pos + 1, col);
}

void make_marker(int x, int y)
{
	//Note that gravity doesn't apply to non-decorated windows.
	object win = GTK2.Window(([
			"decorated": 0, "accept-focus": 0,
			"skip-pager-hint": 1, "skip-taskbar-hint": 1,
		]))
		//->add(GTK2.Label("Demo"))
		->resize(XSIZE, YSIZE)
		->modify_bg(GTK2.STATE_NORMAL, colors[0])
		->move(x-XMID, y-YMID)
		->shape_combine_mask(empty, 0, 0)
		->set_keep_above(1)
		->show_all();
	//GTK2.move_cursor_abs(root, x, y);
	cycle(win);
}

int main()
{
	for (int i=0; i<XMID; ++i)
		circles[i] = Image.Image(XSIZE, YSIZE)
			->setcolor(255, 255, 255)
			->circle(XMID, YMID, i, i);
	GTK2.setup_gtk();
	circlebmp = GTK2.GdkBitmap(circles[*]);
	empty = GTK2.GdkBitmap(1, 1, "\0");
	colors = Function.splice_call(color_defs[*],GTK2.GdkColor);
	/*object scrn = GTK2.GdkScreen();
	root = scrn->get_root_window();
	write("scrn %O root %O\n", scrn, root);
	object gc = GTK2.GdkGC(root);
	write("gc %O\n", gc);*/
	//root->draw_text(gc, 100, 100, "Hello, world!");
	//root->draw_text(gc, 2000, 100, "Hello, world!");

	/*gc->set_foreground( GDK2.Color(255,0,0) );
	root->draw_line(gc, 0, 0, 500, 500);
	root->draw_line(gc, 2000, 0, 2500, 500);*/

	call_out(make_marker, 2, 100, 100);
	write("Demo is active - Ctrl-C to halt\n");
	return -1;
}
