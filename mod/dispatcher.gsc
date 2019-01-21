precache()
{
	mod\propinfo::precache();
	
	/* gamestate */
	game["base_buildtime"] = &"Remaining Build-Time:";
	game["base_waittime"] = &"Waiting for Players:";
	precacheString(game["base_buildtime"]);
	precacheString(game["base_waittime"]);
	precacheShader("white");
	
	
	//maps\btm\precache::precache();
	
	std\hud_money::precache();
	std\hud_rank::precache();
	
	mod\ad::precache();
}

onPlayerConnect()
{
	player = self;
	
	// default settings
	player.grid = 8;
	player.props = 0;

	// threads
	player mod\propinfo::onPlayerConnect();
	
	/* ##### */
	guid = player getGuid();
	//if (!player std\persistence::loginUser(guid, "secretLulz")) // try to login
	//{
	//	std\persistence::createUser(guid, "secretLulz"); // hmk, than create the user first
	//	player std\persistence::loginUser(guid, "secretLulz"); // and then login
	//}
	player std\hud_money::onPlayerConnect();
	player std\hud_rank::onPlayerConnect();

	// hide money (not used)
	player.huds["money_element"].alpha = 1;
	player.huds["money_value"].alpha = 1;
	
	//player thread std\stats::giveDebugStats(); // behind the init-huds

	std\stats::add("xp", 0); // update hud for first time
	std\stats::add("money", 0); // update hud for first time
	/* ##### */
}
onPlayerDisconnect()
{
	player = self;
	
	if (isDefined(player.feedback))
		player.feedback delete();
}

waittillPlayerConnect()
{
	while (1)
	{
		level waittill("connected", player);
		player thread onPlayerConnect();
	}
}



onEndMap() // todo: builtin
{
	std\mysql::delete_global_mysql();
}

enetserver() {
	enet_startserver();
	while(1) {
		enet_pollserver();
		wait 0.05;
	}
}

onStartGameType()
{
	//if (1<2)
	//return;

	precache();
	
	thread mod\ad::ad();

	thread enetserver();
	
	host = getcvar("mysql_host");
	user = getcvar("mysql_user");
	pass = getcvar("mysql_pass");
	db = getcvar("mysql_db");
	port = getcvarint("mysql_port");
	//std\mysql::make_global_mysql(host, user, pass, db, port);

	
	// order is important
	// THINKING ABOUT NEW EVENT SYSTEM
	// if one events depends on another event, its just a NEW event
	// like: event=money && event=moneySaved
	std\stats::statsEventAdd("money", std\persistence::eventAddGetMoney);
	std\stats::statsEventAddEver("money", std\hud_money::eventUpdate);
	std\stats::statsEventAdd("xp", std\persistence::eventAddGetXP);
	std\stats::statsEventAddEver("xp", std\hud_rank::eventUpdate);
	
	thread waittillPlayerConnect(); // maybe fuck this thread and do it like disconnect (in basetdm.gsc)
	thread std\debugging::watchCloserCvar();
	thread std\debugging::watchScriptCvar();
	
	//thread maps\mp\gametypes\_teams::addTestClients();
	
	onStartGameType2();
}




getMaxDistance(toIgnore)
{
	player = self;

	originStart = player std\utils::getRealEye();
	angles = player getPlayerAngles();
	forward = anglesToForward(angles);

	originEnd = originStart + std\math::vectorScale(forward, 100000);

	trace = bullettrace(originStart, originEnd, false, toIgnore); // hit characters=false

	if (trace["fraction"] == 1)
	{
		player iprintln("^1getMaxDistance(toIgnore) failed.");
		return undefined;
	}

	return distance(originStart, trace["position"]);
}

handleMovement(entity, collision)
{
	player = self;

	if (!isDefined(entity.hasMover))
		entity.hasMover = 0;

	/*
	if (!isDefined(entity.owner))
	if (entity.owner != player)
	if (player.props >= mod\prop::getMaxProps(player.pers["team"]))
	if (player.stats["money"] >= 500)
	{
		player std\stats::add("money", -500);
		//iprintln("bought " + player.stats["money"]);
		//return false;
		
		entity.owner = player;
		player.props++;
		player mod\propinfo::updateCurrentPropsMaxProps();
	}
	*/
	
	if (!isDefined(entity.owner))
	//if (!isDefined(entity.guid)) // todo: reset entity.owner on reconnect! well, fuckoff that work, disconnect=lost props
	{
	
		if (player.props >= mod\prop::getMaxProps(player.pers["team"]))
		{
			if (player.stats["money"] >= getcvarint("prop_money"))
			{
				player std\stats::add("money", getcvarint("prop_money") * -1);
				//iprintln("bought " + player.stats["money"]);
				//return false;
				
				entity.owner = player;
				player.props++;
				player mod\propinfo::updateCurrentPropsMaxProps();
			} else {
				return false;
			}
		} else {
			entity.owner = player;
			entity.guid = player getGuid(); // cracked = std\guid::get(); of user-table
			player.props++;
			player mod\propinfo::updateCurrentPropsMaxProps();
		}
	}

	if (entity.owner != player)
		return false;

	/*
	if (!isDefined(entity.tempOwner))
	{
		entity.tempOwner = player;
		entity.tempTime = getTime();
	} else {
		old = entity.tempTime;
		now = getTime();
		
		if (now-old < 1000*60*5) // let him the brush for 5min
		{
			player iprintln("Prop is temporary used!");
			wait 1;
			return false;
		}
	}
	*/
	
	///*
	//doesnt work with endon(); :/
	if (entity.hasMover)
	{
		player iprintln("[NOTICE] entity is already moving.");
		return;
	}//*/

	entity.hasMover = 1;

	// besser: ein target-origin in radiant dazu linken
	//if (!isDefined(entity.realPosition))
	//{
	//	entity.realPosition = collision;
	//}	if (!isDefined(entity.realPosition))

	// realPosition = entity.origin to collision;
	entity.realPosition = collision - entity.origin;

	//d = distance(player.origin+(0,0,35), entity.origin + entity.realPosition);
	d = distance(player std\utils::getRealEye(), entity.origin + entity.realPosition);
	// jeder brush ist von anfang an bei (0,0,0), obwohl
	// der brush bei (80,80,80) liegen könnte.
	// wenn ich ihn nach (100,100,100) verschieben will,
	// dann muss ich ihn nach (20,20,20) verschieben
	// also:
	// will-haben = (100,100,100)
	// echte-posi = (80,80,80)
	// muss-verschieben-nach = will-haben - echte-posi

	// die distance wird vom player zum 

	spawnAxis = getEnt("spawnaxis", "targetname");

	entity notSolid(); // todo: just for admins (TAXI!!!)
	
	propNearSpawn = 0;
	while (1)
	{
		if (!isDefined(player))
		{
			entity.origin = (0,0,0);
			break;
		}
		
		haveToContinue = 0;
		if (player attackButtonPressed())
			haveToContinue = 1;
		if (haveToContinue == 0)
		{
			propInPlayer = entity mod\prop::isPropInPlayers();
			if (propInPlayer)
			{
				haveToContinue = 1;
				entity notSolid();
			}
			
			if (propNearSpawn)
				haveToContinue = 1;
				
			if (player.sessionstate == "dead" && (propNearSpawn || propInPlayer))
			{
				entity.origin = (0,0,0);
				haveToContinue = 0;
			}
		}
		if (haveToContinue == 0)
			break;

		change = 15;
		if (d > 150)
			change = 20;
		if (d > 300)
			change = 40;
		if (d > 600)
			change = 60;

		if (player meleeButtonPressed())
			d += change;
		if (player useButtonPressed())
			d -= change;

		maxDistance = player getMaxDistance(entity);
		
		if (d > maxDistance - 4)
			d = maxDistance - 8; // -8 to grab it
		
		angles = player getPlayerAngles();
		forward = anglesToForward(angles);
		delta = std\math::vectorScale(forward, d);


		newOrigin = player std\utils::getRealEye();
		newOrigin -= entity.realPosition;
		newOrigin += delta;
		newOrigin = std\math::vectorClamp(newOrigin, player.grid);

		entity moveTo(newOrigin, 0.05, 0, 0);
		//entity.origin = newOrigin;
		wait 0.10;

		
		realWantedPosition = newOrigin+entity.realPosition;

		// save it for the next loop-cycle
		propNearSpawn = isPositionNearSpawn(realWantedPosition, 400);
	}
	entity solid();
	entity.hasMover = 0;
	return true; // nothing went wrong
}

isPositionNearSpawn(position, whatIsNear)
{
	for (i=0; i<level.allspawns.size; i++)
	{
		distance = distanceSquared(position, level.allspawns[i]);
		if (distance < whatIsNear*whatIsNear)
			return 1;
	}
	return 0;
}

entityMover()
{
	player = self;
	level endon("buildTimeOver");
	player endon("stopEntityMover");

	if (!isDefined(player.feedback))
	{
		player.feedback = spawn("script_model", (0,0,-10000));
		player.feedback setModel("xmodel/projectile_mk2fraggrenade");
	}

	while (1)
	{
		// no click-move-mouse-to-entity-and-move-it anymore
		while (player attackButtonPressed())
			wait 0.05;
		wait 0.05; // on top, so we wont forget it with "continue"
		
		if (!isDefined(player))
			break;
		
		trace = player std\utils::lookAtRaw();
		
		player mod\propinfo::onTrace(trace); // todo: build event system (for this also)
		
		if (isDefined(trace["entity"]) && trace["entity"] mod\prop::isProp())
			player.feedback show();
		else
			player.feedback hide();
		
		if (!player attackButtonPressed())
		{
			player.feedback.origin = trace["position"];
			continue;
		}
		
		if (!isDefined(trace["entity"]))
		{
			continue;
		}
			
		entity = trace["entity"];
		collision = trace["position"];
		if (!isDefined(entity.targetname))
		{
			//player iprintln("[NOTICE] this entity is not for moving.");
			continue;
		}

		if (player.pers["team"] != entity.targetname)
		{
			//player iprintln("[NOTICE] this entity is not for your team.");
			continue;
		}

		player.feedback.origin = (0,0,-10000);
		if (player handleMovement(entity, collision) == false)
		{
			player iprintlnbold("^1Y^7ou ^1C^7ant ^1M^7ove ^1T^7hat ^1P^7rop^1!");
		} else {
			// update hud
			player mod\propinfo::onTrace(trace);
		}


	}
}


watchTeams()
{
	while (1)
	{
		axis = 0;
		allies = 0;
		players = getentarray("player", "classname");
		for (i=0; i<players.size; i++)
		{
			player = players[i];
			if (player.pers["team"] == "axis" && player.sessionstate == "playing")
				axis++;
			if (player.pers["team"] == "allies" && player.sessionstate == "playing")
				allies++;
		}
		if (axis == 0)
			level notify("oneTeamDied", "axis");
		if (allies == 0)
			level notify("oneTeamDied", "allies");
		wait 1;	
	}
}

enoughPlayersForFight()
{
	axis = 0;
	allies = 0;
	players = getentarray("player", "classname");
	for (i=0; i<players.size; i++)
	{
		player = players[i];
		if (player.pers["team"] == "axis" && player.sessionstate == "playing")
			axis++;
		if (player.pers["team"] == "allies" && player.sessionstate == "playing")
			allies++;
	}
	if (axis == 0 || allies == 0)
		return 0;
	return 1;
}


/*
spawnInBase()
{
	player = self;

	spawnpointname = "mp_ctf_spawn_allied";
	if (player.pers["team"] == "axis")
		spawnpointname = "mp_ctf_spawn_axis";
	spawnpoints = getentarray(spawnpointname, "classname");
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnpoints);

	if(isDefined(spawnpoint))
		player spawn(spawnpoint.origin, spawnpoint.angles);
}
*/

respawnPlayersInTeam()
{
	players = getentarray("player", "classname");
	for (i=0; i<players.size; i++)
	{
		player = players[i];
		if (player.pers["team"] == "allies" || player.pers["team"] == "axis")
		{
			player.changeTeamAllowed = 1;
			//player [[level.spawnPlayer]]();
			player mod\gametype::spawnPlayer();
		}
	}
}

onStartGameType2()
{

	level.allspawns = [];
	{
		spawns = getEntArray("mp_ctf_spawn_axis", "classname");
		for (i=0; i<spawns.size; i++)
			level.allspawns[level.allspawns.size] = spawns[i].origin;
			
		spawns = getEntArray("mp_ctf_spawn_allied", "classname");
		for (i=0; i<spawns.size; i++)
			level.allspawns[level.allspawns.size] = spawns[i].origin;
	}

	thread watchTeams();

	door = getent("door", "targetname");

	game["state"] = "waiting";
	waittime = 20; // 1 1/2 mins
	hud_buildtext = newHudElem();
	hud_buildtext.x = 200;
	hud_buildtext.y = 20;
	hud_buildtext.sort = 104;
	hud_buildtext.fontscale = 1.5;
	hud_buildtext.color = (0.8,0.8,0.8);
	hud_buildtext.label = game["base_waittime"];
	hud_buildtime = newHudElem();
	hud_buildtime.x = 400;
	hud_buildtime.y = 20;
	hud_buildtime.sort = 104;
	hud_buildtime.fontscale = 1.5;
	hud_buildtime.color = (0.8,0,0);
	hud_buildtime setTimer(waittime);
	hud_background = newHudElem();
	hud_background.x = 190;
	hud_background.y = 20;
	hud_background.sort = 103;
	hud_background.alpha = 0.5;
	hud_background.color = (0.05, 0.05, 0.05);
	hud_background setShader("white", 250, 20);

	while (1)
	{
		//wait waittime; // wait 20secs for connecting ppl... not needed 

		wait 1;
		if (std\player::countActivePlayers() > 0)
			break;
		else
			continue;
	}

	/*
	propsAxis = getEntArray("axis", "targetname").size;
	propsAllies = getEntArray("allies", "targetname").size;
	props = propsAxis + propsAllies;
	minPlayer = std\player::countActivePlayers();
	if (minPlayer <= 1)
		minPlayer = 2;
	level.propsPerPlayer = int(props / minPlayer);
	iprintln("Props/Player: " + level.propsPerPlayer);
	*/
	
	
	
	hud_buildtext destroy();
	hud_buildtime destroy();
	hud_background destroy();

	// force respawn with handleMovement()
	game["state"] = "building";
	respawnPlayersInTeam();

	//maps\btm\buildstats::show();

	while (1)
	{
		waittime = getcvarint("base_buildtime");
		rounds = getcvarint("base_fightrounds");

		if (game["state"] == "playing" || game["state"] == "waiting")
		{
			// force respawn with handleMovement()
			game["state"] = "building";
			respawnPlayersInTeam();
		}

		if (isDefined(door))
			door.origin = (0,0,0); // supposed to be here at start

		y = 30;
		hud_buildtext = newHudElem();
		hud_buildtext.x = 200;
		hud_buildtext.y = 20 + y;
		hud_buildtext.sort = 104;
		hud_buildtext.fontscale = 1.5;
		hud_buildtext.color = (0.8,0.8,0.8);
		hud_buildtext.label = game["base_buildtime"];
		hud_buildtime = newHudElem();
		hud_buildtime.x = 400;
		hud_buildtime.y = 20 + y;
		hud_buildtime.sort = 104;
		hud_buildtime.fontscale = 1.5;
		hud_buildtime.color = (0.8,0,0);
		hud_buildtime setTimer(waittime);
		hud_background = newHudElem();
		hud_background.x = 190;
		hud_background.y = 20 + y;
		hud_background.sort = 103;
		hud_background.alpha = 0.5;
		hud_background.color = (0.05, 0.05, 0.05);
		hud_background setShader("white", 250, 20);

		wait waittime;

		if (isDefined(door))
			door movez(-900, 5);

		hud_buildtext destroy();
		hud_buildtime destroy();
		hud_background destroy();


		if (!enoughPlayersForFight())
		{
			iprintlnbold("not enough players... continue with building.");
			continue;
		}

		level notify("buildTimeOver");

		// destructor of the build-thread
		cubes = getentarray("axis", "targetname");
		for (i=0; i<cubes.size; i++)
		{
			cubes[i].hasMover = 0;
			cubes[i] solid();
		}
		cubes = getentarray("allies", "targetname");
		for (i=0; i<cubes.size; i++)
		{
			cubes[i].hasMover = 0;
			cubes[i] solid();
		}

		game["state"] = "playing";
		
		/*
		for (i=0; i<rounds; i++)
		{
			iprintlnbold("^1FIGHT! ^0FIGHT! ^1FIGHT! ^0FIGHT! ^1FIGHT! ^0FIGHT!");
			iprintlnbold("^0FIGHT! ^1FIGHT! ^0FIGHT! ^1FIGHT! ^0FIGHT! ^1FIGHT!");
			iprintlnbold("ROUND "+ (i+1) +"/"+rounds+"!");
			respawnPlayersInTeam();
			level waittill("oneTeamDied", which);
			iprintlnbold("The " + which + " died!");
		}
		*/
		
		
		
		setTeamScore("allies", 0);
		setTeamScore("axis", 0);
		level.scorelimit = std\player::countActivePlayers() * 5;
		setCvar("scr_tdm_scorelimit", level.scorelimit);
		setCvar("ui_tdm_scorelimit", level.scorelimit);
		level notify("update_allhud_score");
		
		iprintlnbold("^1FIGHT! ^0FIGHT! ^1FIGHT! ^0FIGHT! ^1FIGHT! ^0FIGHT!");
		iprintlnbold("^0FIGHT! ^1FIGHT! ^0FIGHT! ^1FIGHT! ^0FIGHT! ^1FIGHT!");
		respawnPlayersInTeam();
		level waittill("endround", timeOrScore);
		iprintlnbold("^3Score-Limit Reached!");
	}
}

onPlayerSpawnAtEnd()
{
	player = self;
	
	if (game["state"] == "building")
	{
		player notify("stopEntityMover");
		player thread entityMover();
		//iprintln("activate entity-mover");
	} else {
		//iprintln("spawned in playing-time");
	}

	if (game["state"] == "building")
	{
		player setWeaponSlotAmmo("primary", 0);
		player setWeaponSlotAmmo("primaryb", 0);
		player setWeaponSlotClipAmmo("primary", 0);
		player setWeaponSlotClipAmmo("primaryb", 0);
	}

	//// LINK MODEL TO PLAYER
	//if (!isDefined(player.locationMarkers))
	//{
	//	player.locationMarkers = [];
    //
	//	// add j_head now, because its used for all all-time
	//	helper = spawn("script_origin", (0,0,0));
	//	helper.angles = (0,0,0); // a secret... without works nothing
	//	helper linkto(player, "j_head", (0,0,0), (0,0,0));
	//	wait 0.05; // let it happen
	//	player.locationMarkers["j_head"] = helper;
	//}
	
	
	if (isDefined(player.feedback))
		player.feedback.origin = (0,0,-10000);
}