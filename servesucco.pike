//Runs inside Hogan: pike hogan succotash
/*
Protocol is TCP/IP line-based. All client->server communication begins with
a lower-case command word (in future this may become case insensitive), and
all server->client communication begins with an upper-case status word - one
of "OK" or "BAD" if in response to a command, otherwise is a notification
command that may be sent at any time.

Positions sent with "pos 123 234" are sent out to all clients in your room
(including yourself) as "POS <id> 123 234". This command is not acknowledged
with an explicit "OK", as the POS response serves the same purpose.
*/
mapping(int:function) services=([42857|HOGAN_LINEBASED: succotash]);
mapping(string:array(mapping)) connections = G->G->connections;

string(0..255) succotash(mapping(string:mixed) conn,string(0..255) line)
{
	if (!line)
	{
		if (!conn->_closing)
		{
			conn->state = "room";
			//TODO: Guarantee uniqueness (just in case - it's pretty unlikely we'll get collisions)
			conn->id = MIME.encode_base64(random_string(6));
			return "OK Welcome, please select a room. Your ID is: " + conn->id;
		}
		//Closing connection.
		if (conn->room)
		{
			connections[conn->room] -= ({conn});
			G->send(connections[conn->room][*], "GONE " + conn->id);
		}
		return 0;
	}
	if (line == "quit")
	{
		conn->_close = 1;
		return "OK Bye! [00:08:53]";
	}
	if (conn->state == "room")
	{
		if (sscanf(line, "id %s", conn->id))
		{
			//You may choose your own ID only before joining a room.
			return "OK Your ID is: " + conn->id;
		}
		if (sscanf(line, "room %s", conn->room))
		{
			conn->state = "main";
			connections[conn->room] += ({conn});
			return "OK Room selected - you are participant " + sizeof(connections[conn->room]) + ".";
		}
		return "BAD Please select a room.";
	}
	//Normal usage: broadcast stuff.
	if (sscanf(line, "pos %d %d", int x, int y))
	{
		G->send(connections[conn->room][*], sprintf("POS %s %d %d", conn->id, x, y));
		return 0; //The echo of POS should be enough.
	}
	if (line == "hide")
	{
		G->send(connections[conn->room][*], "GONE " + conn->id);
		return 0; //Again, just the echo should be enough
	}
	return "BAD Unrecognized command.";
}

void create()
{
	if (!connections) G->G->connections = connections = ([]);
}
