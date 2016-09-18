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

int main()
{
	GTK2.setup_gtk();
	object scrn = GTK2.GdkScreen();
	object root = scrn->get_root_window();
	write("scrn %O root %O\n", scrn, root);
	object gc = GTK2.GdkGC(root);
	write("gc %O\n", gc);
	//root->draw_text(gc, 100, 100, "Hello, world!");
	//root->draw_text(gc, 2000, 100, "Hello, world!");
	gc->set_foreground( GDK2.Color(255,0,0) );
	root->draw_line(gc, 0, 0, 500, 500);
	root->draw_line(gc, 2000, 0, 2500, 500);
	//return -1;
}
