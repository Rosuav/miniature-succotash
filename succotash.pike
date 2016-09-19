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
NOTE: Does not work on Windows + Pike 8.0 + GTK 2.12.11. No idea which
part of that causes the problem.
*/
object root;
constant XSIZE = 50, YSIZE = 50; //NOTE: Some things may not work if it's not square. Untested.
constant XMID = XSIZE/2, YMID = YSIZE/2; //Used very frequently
array(Image.Image) circles = allocate(XMID);
array(GTK2.GdkBitmap) circlebmp;
GTK2.GdkBitmap empty;
mapping(string:GTK2.Window) markers = ([]);
Stdio.File sock;

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

void make_marker(string id, int x, int y)
{
	//Note that gravity doesn't apply to non-decorated windows.
	markers[id] = GTK2.Window(([
			"decorated": 0, "accept-focus": 0,
			"skip-pager-hint": 1, "skip-taskbar-hint": 1,
		]))
		//->add(GTK2.Label("Demo"))
		->resize(XSIZE, YSIZE)
		->modify_bg(GTK2.STATE_NORMAL, colors[0])
		->move(x-XMID, y-YMID)
		->shape_combine_mask(empty, 0, 0)
		->show_all()
		->set_keep_above(1)
	;
	//GTK2.move_cursor_abs(root, x, y);
	cycle(markers[id]);
}

string sockbuf = "";
string my_id;
void socketread(mixed id, string data)
{
	sockbuf += data;
	while (sscanf(sockbuf, "%s\n%s", string line, sockbuf))
	{
		if (sscanf(line, "OK %*sYour ID is: %s", my_id) == 2)
			write("My ID is: %s\n", my_id);
		if (sscanf(line, "POS %s %d %d", string id, int x, int y))
		{
			if (id == my_id) continue; //Don't show a marker for ourselves
			object win = markers[id];
			if (!win) make_marker(id, x, y);
			else win->move(x-XMID, y-YMID);
		}
		else if (sscanf(line, "GONE %s", string id))
		{
			object win = markers[id];
			if (!win) continue;
			win->destroy();
			destruct(win);
		}
	}
}

int main()
{
	sock = Stdio.File();
	sock->connect("gideon.rosuav.com", 42857);
	sock->write("room demo\n");
	sock->set_read_callback(socketread);
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

	call_out(make_marker, 2, "demo", 100, 100);
	write("Demo is active - Ctrl-C to halt\n");
	return -1;
}
