main()
{
	if (1 < 2)
		return;

	// set g_log "scriptdata/rickroll.cfg"
	// logfile = openfile(getcvar("g_log"), "read");
	logfile = openfile("testfile.txt", "read");

	while (1)
	{
		line = freadln(logfile);

		if (line == -1)
		{
			//iprintln("nothing");
			wait 0.25;
			continue;
		}

		text = fgetarg(line, 0);

		iprintln("line: " + text);
	}

}

main1()
{
	testfile = openfile("testfile.txt", "write");
	iprintln(testfile, "my test-content!\nanother line.");
}