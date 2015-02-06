isPropInPlayers()
{
	prop = self;
	players = getentarray("player", "classname");
	for (i=0; i<players.size; i++)
		if (players[i] isTouching(prop))
			return 1;
	return 0;
}

isProp()
{
	prop = self;

	if (!isDefined(prop.targetname))
		return false;

	if (prop.targetname == "axis" || prop.targetname == "allies")
		return true;
	else
		return false;
}

getMaxProps(team)
{

	/*
	propsAxis = getEntArray("axis", "targetname").size;
	propsAllies = getEntArray("allies", "targetname").size;
	props = propsAxis + propsAllies;
	minPlayer = getActivePlayers();
	if (minPlayer <= 1)
		minPlayer = 2;
	level.propsPerPlayer = int(props / minPlayer);
	iprintln("Props/Player: " + level.propsPerPlayer);
	*/

	props = getEntArray(team, "targetname").size;
	players = std\player::countActivePlayers(team);
	return int(props / players);
}