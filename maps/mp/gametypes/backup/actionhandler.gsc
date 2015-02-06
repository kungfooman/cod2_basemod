#include maps\BTM\INTERFACE;
#include maps\BTM\UTILS;
#include maps\BTM\BOT;
#include maps\BTM\WEAPONS;

init()
{
	thread main();
}

getPlayerByEntityId(id)
{
	players = getentarray("player", "classname");
	for (i=0; i<players.size; i++)
		if (players[i] getEntityNumber() == id)
			return players[i];
	return undefined;
}

// danger: somehow getGuid() isnt reliable... will return players with another guid
getPlayerByGuid(guid)
{
	players = getentarray("player", "classname");
	for (i=0; i<players.size; i++)
		if (players[i] getGuid() == guid)
			return players[i];
	return undefined;
}

getPlayerByName(name)
{
	players = getentarray("player", "classname");
	for (i=0; i<players.size; i++)
		if (isSubStr(players[i].name, name))
			if (name.size > 0)
				return players[i];
	return undefined;
}

showEntities()
{
	player = self;
	//countdefined = 0;
	/#
	player iprintln("EXECUTED1 START!");
	for (i=0; i<1024; i++)
	{
		ent = getEntByNum(i);
		if (isDefined(ent) && isDefined(ent.classname))
		{
			player iprintln("ent["+i+"]="+ent.classname);
			//countdefined++;
		}
	}
	player iprintln("EXECUTED1 END!");
	#/
	//player iprintln("[NOTICE] entities with classname: "+countdefined);
}

fireeyes(seconds)
{
	player = self;
	player endon("firestop");

	start = gettime();

	iprintlnbold(player.name + " ^7got ^1fire^7-eyes!");

	while (isDefined(player))
	{
		now = gettime();
		diff = now - start;
		secs = diff/1000;

		if (secs > seconds)
			break;

		pos = player lookAt();
		if (!isDefined(pos))
			continue;

		playfx(level.fx["tank_fire_engine"], pos);
		wait 0.10;
	}

	iprintln("^1fire^7-eyes ended.");
}
firewalk(seconds)
{
	player = self;
	player endon("firestop");

	start = gettime();

	iprintlnbold(player.name + " ^7got a ^1fire^7-walk!");

	while (isDefined(player))
	{
		now = gettime();
		diff = now - start;
		secs = diff/1000;

		if (secs > seconds)
			break;

		playfx(level.fx["tank_fire_engine"], player.origin);

		wait 0.10;
	}

	iprintln("^1fire^7-walk ended.");
}
firering(seconds)
{
	player = self;
	player endon("firestop");

	start = gettime();

	iprintlnbold(player.name + " ^7got a ^1fire^7-ring!");

	angle = 0;
	while (isDefined(player))
	{
		now = gettime();
		diff = now - start;
		secs = diff/1000;
		if (secs > seconds)
			break;

		forward = maps\BTM\LOOKUP::lookupAngleToForward(angle);
		delta = (forward[0]*100, forward[1]*100, 0);
		playfx(level.fx["tank_fire_engine"], player.origin+delta);

		angle += 8;
		wait 0.10;
	}

	iprintln("^1fire^7-ring ended.");
}
/*
firespiral(seconds)
{
	player = self;
	player endon("firestop");

	start = gettime();

	iprintlnbold(player.name + " ^7got a ^1fire^7-spiral!");

	angle = 0;
	spirale = 55;
	spiraleAdd = 5;
	while (isDefined(player))
	{
		now = gettime();
		diff = now - start;
		secs = diff/1000;
		if (secs > seconds)
			break;

		spirale += spiraleAdd;
		if (spirale > 200 || spirale < 50)
			spiraleAdd *= -1;

		forward = maps\BTM\LOOKUP::lookupAngleToForward(angle);
		scale = spirale;
		delta = (forward[0]*scale, forward[1]*scale, 0);
		playfx(level.fx["tank_fire_engine"], player.origin+delta);

		angle += 8;
		wait 0.10;
	}
	iprintln("^1fire^7-spiral ended.");
}
*/
firespiral(seconds)
{
	player = self;
	player endon("firestop");

	start = gettime();

	iprintlnbold(player.name + " ^7got a ^1fire^7-spiral!");

	angle = 0;
	spirale = 25;
	spiraleAdd = 2;
	while (isDefined(player))
	{
		now = gettime();
		diff = now - start;
		secs = diff/1000;
		if (secs > seconds)
			break;

		spirale += spiraleAdd;
		// wenn spirale höher als 200: invertieren
		// wenn spirale niedriger als 50: invertieren
		if (spirale > 200 || spirale < 20)
			spiraleAdd *= -1;

		forward = anglesToForward( (0,angle,0) );
		delta = (forward[0]*180, forward[1]*180, spirale);
		playfx(level.fx["tank_fire_engine"], player.origin+delta);

		angle += 8;
		wait 0.10;
	}
	iprintln("^1fire^7-spiral ended.");
}

deleteHud()
{
	player = self;
	player waittill("lookat end");
	player.hud destroy();
}
showLookAt()
{
	player = self;

	hud = newHudElem();
	hud.alpha = 1;
	hud.archived = false;
	hud setShader("objpoint_bomb");
	hud setWayPoint(0); // 1=scaleWithDistance, 0=constantSmall
	player.hud = hud;

	player thread deleteHud();
	player endon("lookat end");
	while (isDefined(player))
	{
		pos = player lookAt();
		player.hud.x = pos[0];
		player.hud.y = pos[1];
		player.hud.z = pos[2];
		wait 0.10;
	}
}
waitForUse()
{
	player = self;
	while (player safeUseButtonPressed() == 0)
		wait 0.05;
	while (player safeUseButtonPressed() == 1)	
		wait 0.05;
}
playerAddMortar()
{
	player = self;

	player thread showLookAt();

	player iprintlnbold("Press Use to add the Mortar!");
	player waitForUse();
	pos = player lookAt();
	mortar = maps\BTM\MORTAR::addMortar(pos, player getPlayerAngles()[1]);

	player iprintlnbold("Press Use to add the Target!");
	player waitForUse();
	pos = player lookAt();
	ent = spawnEntity(pos);
	mortar.targets[mortar.targets.size] = ent;

	player iprintlnbold("Mortar created!");

	player notify("lookat end");
}

teleportAbort()
{
	player = self;
	player notify("abortTeleporting");
	player iprintln("^7[^8NOTICE^7] ^7teleporting has been aborted");
}
teleportPlayer(movePlayer)
{
	player = self;
	player endon("abortTeleporting");

	// wait till player pressed USE...
	player iprintln("^7[^8NOTICE^7] press [[{+activate}]] to teleport " + movePlayer.name);
	while (player safeUseButtonPressed() == 0)
		wait 0.05;

	if (isPlayer(player) && isPlayer(movePlayer))
	{
		look = player lookAt();
		movePlayer setOrigin(look+(0,0,15));
		player iprintln("^7[^8NOTICE^7] "+movePlayer.name+" ^7has been teleported");
	}
}

main()
{
	while (1)
	{
		if (getcvar("run") == "1")
		{
			setcvar("run", "0");

			time = getcvarint("time");
			cmd = getcvar("cmd");
			guid = getcvarint("guid");
			id = getcvarint("id");
			name = getcvar("name");
			type = getcvar("type");
			message = getcvar("message");
			commandtype = getcvar("commandtype");
			arg0 = getcvar("arg0");
			arg1 = getcvar("arg1");
			arg2 = getcvar("arg2");
			arg3 = getcvar("arg3");
			arg4 = getcvar("arg4");
			arg5 = getcvar("arg5");
			arg6 = getcvar("arg6");
			arg7 = getcvar("arg7");
			arg8 = getcvar("arg8");
			arg9 = getcvar("arg9");
			// easier...
			cmd = arg0;

			/*
			iprintln("time = " + time);
			iprintln("cmd = " + cmd);
			iprintln("guid = " + guid);
			iprintln("id = " + id);
			iprintln("name = " + name);
			iprintln("type = " + type);
			iprintln("message = " + message);
			iprintln("commandtype = " + commandtype);
			iprintln("arg0 = " + arg0);
			iprintln("arg1 = " + arg1);
			iprintln("arg2 = " + arg2);
			iprintln("arg3 = " + arg3);
			iprintln("arg4 = " + arg4);
			iprintln("arg5 = " + arg5);
			iprintln("arg6 = " + arg6);
			iprintln("arg7 = " + arg7);
			iprintln("arg8 = " + arg8);
			iprintln("arg9 = " + arg9);
			*/

			/*if (guid == "629770")
				iprintln("du bist es!");
			else
				iprintln("du bist es nicht!");
			*/

			// SOOO, funzt jetzt. war nur wegen getcvarINT();
			// player = getPlayerByGuid(guid); // getGuid() is bugged or so
			player = getPlayerByEntityId(id);
			if (!isDefined(player))
			{
				iprintln("couldnt get the player of the id!");
				continue;
			}

			//iprintln("found the player: name="+player.name+" guid="+player getGuid() + " cvarguid="+guid);
			//iprintln("found the player: name="+player.name+" id="+player getEntityNumber() + " cvarid="+id);

			/*
			if (player getGuid() == "629770") // brutzel or james
			if (player getGuid() == "1363923")
			if (player getGuid() == "1552606") // eyeless
			if (player getGuid() == "1571009") // brutzel REAL
			if (player getGuid() == "634193") // brutzel REAL
			*/

			if (cmd == "fireeyes")
				player thread fireeyes(getcvarfloat("arg1"));
			if (cmd == "firewalk")
				player thread firewalk(getcvarfloat("arg1"));
			if (cmd == "firering")
				player thread firering(getcvarfloat("arg1"));
			if (cmd == "firespiral")
				player thread firespiral(getcvarfloat("arg1"));
			if (cmd == "firestop")
			{
				player iprintlnbold(player.name+" stopped his fire^8...");
				player notify("firestop");
			}

			if (cmd == "velocity")
			{
				toKick = getPlayerByName(arg1);
				x = arg2;
				y = arg3;
				z = arg4;
				toKick addVelocity( (x,y,z) );
			}

			if (cmd == "forward")
			{
				toKick = getPlayerByName(arg1);
				scale = arg2;
				forward = anglesToForward(toKick getPlayerAngles());
				velocity = vectorScale(forward, scale);
				toKick addVelocity(velocity);
				toKick thread airControl();
			}

			// player.stats["timeJoin"] = gettime(); at start
			if (cmd == "thirdperson")
			{
				if (!isDefined(player.is))
					player.is = [];
				if (!isDefined(player.is["thirdperson"]))
					player.is["thirdperson"] = 0;

				if (player.is["thirdperson"] == 0)
				{
					player iprintln("^7[^8NOTICE^7] thirdperson activated.");
					player setclientcvar("cg_thirdperson", "1");
					player.is["thirdperson"] = 1;
				} else {
					player iprintln("^7[^8NOTICE^7] thirdperson deactivated.");
					player setclientcvar("cg_thirdperson", "0");
					player.is["thirdperson"] = 0;
				}
			}

			if (cmd == "normal")
			{
				player maps\mp\gametypes\_teams::model();
			}
			if (cmd == "cowme")
			{
				iprintlnbold(player.name + "^6: MUUUUUUH!");
				player detachAll();
				player setModel("xmodel/cow_dead_1");
			}
			if (cmd == "doghouseme")
			{
				iprintlnbold(player.name + "^6: WUFF WUFF!");
				player detachAll();
				player setModel("xmodel/prop_doghouse1");
			}
			if (cmd == "tractorme")
			{
				iprintlnbold(player.name + "^6: TUF TUF TUF!");
				player detachAll();
				player setModel("xmodel/prop_tractor");
			}
			if (cmd == "tombstoneme")
			{
				iprintlnbold(player.name + "^7 = tombstone^8...");
				player detachAll();
				player setModel("xmodel/prop_tombstone1");
			}
			if (cmd == "mattressme")
			{
				iprintlnbold(player.name + "^7 = mattress^8...");
				player detachAll();
				player setModel("xmodel/furniture_bedmattress1");
			}
			if (cmd == "toiletme")
			{
				iprintlnbold(player.name + "^7 = toilet^8...");
				player detachAll();
				player setModel("xmodel/furniture_toilet");
			}
				
			if (cmd == "saybold")
			{
				iprintlnbold(getcvar("partWithoutCmd")); // FIX: when ";" is in text
			}

			if (cmd == "save")
			{
				player iprintln("^7[^8NOTICE^7] position saved at ", player.origin, "^8...");
				player.savedOrigin = player.origin;
				player.savedAngles = player getPlayerAngles();
			}

			if (cmd == "load")
			{
				if (!isDefined(player.savedOrigin))
				{
					player iprintln("^7[^8NOTICE^7] no saved position^8...");
					continue;
				}
				player iprintln("[^1NOTICE^7] position loaded^8...");
				player setOrigin(player.savedOrigin);
				player setPlayerAngles(player.savedAngles);
			}

			if (cmd == "cheats")
			{
				if (getcvarint("sv_cheats") == 0)
				{
					player iprintln("^7[^8NOTICE^7] cheats activated.");
					setcvar("sv_cheats", "1");
				} else {
					player iprintln("^7[^8NOTICE^7] cheats deactivated.");
					setcvar("sv_cheats", "0");
				}
			}

			if (cmd == "force")
			{
				name = arg1;
				team = arg2;

				toForce = getPlayerByName(name);
				if (!isDefined(toForce))
				{
					player iprintln("^7[^8NOTICE^7] couldn't find player \""+name+"\"!");
					continue;
				}
				switch (team)
				{
					case "axis":
						toForce.pers["team"] = "axis";
						toForce.pers["savedmodel"] = undefined;
						toForce maps\mp\gametypes\zom::respawn();
						break;
					case "allies":
						toForce.pers["team"] = "allies";
						toForce.pers["savedmodel"] = undefined;
						toForce maps\mp\gametypes\zom::respawn();
						break;
					case "intermission":
						toForce.pers["team"] = "intermission";
						toForce.pers["savedmodel"] = undefined;
						toForce suicide();
						toForce maps\mp\gametypes\zom::spawnIntermission();
						break;
					case "spectator":
						//toForce.pers["team"] = "spectator";
						//toForce.pers["savedmodel"] = undefined;
						//toForce suicide();
						toForce maps\mp\gametypes\zom::menuSpectator();
						break;
				}
			}

			if (cmd == "turretsprint")
			{
				turrets = getEntArray("misc_turret", "classname");
				msg = "";
				for (i=0; i<turrets.size; i++)
				{
					msg += "turret["+i+"].model = "+turrets[i].model+";\n";
				}
				player iprintln(msg);
			}
			if (cmd == "turretsdelete")
			{

				turretsDelete();
			}

			if (cmd == "debugplayer")
			{
				toDebug = getPlayerByName(arg1);
				if (!isDefined(toDebug))
					continue;

				player iprintln("sessionstate: " + toDebug.sessionstate);
				player iprintln("team: " + toDebug.pers["team"]);
				player iprintln("sessionteam: " + player.sessionteam);
				player iprintln("psoffsettime: " + player.psoffsettime);
				player iprintln("health: " + player.health);
				player iprintln("maxhealth: " + player.maxhealth);
					
			}

			if (cmd == "fognight")
				SetExpFog(0.002, 0.001, 0.001, 0.001, 1);
			if (cmd == "fogday")
				SetExpFog(0.00001, 0, 0, 0, 0);
			if (cmd == "fog")
			{
				r = getcvarfloat("arg1");
				g = getcvarfloat("arg2");
				b = getcvarfloat("arg3");
				d = getcvarfloat("arg4");

				error = false;
				if (d <= 0 || d >= 1) error = true;
				if (r < 0 || r > 1) error = true;
				if (g < 0 || g > 1) error = true;
				if (b < 0 || b > 1) error = true;

				if (error)
				{
					player iprintln("^7[^1NOTICE^7] distance: >0 && <1");
					continue;
				}

				SetExpFog(d, r, g, b, 1);
				iprintln("Fog: (",r,",",g,",",b,"); distance: ", d);
			}

			if (cmd == "botAdd") // !botAdd !tf !fn !fd
			{
				BOT_add("zombie");
			}
			if (cmd == "tf") // to flag
			{
				maps\BTM\BOT::botsToFlags();
			}
			if (cmd == "fn") // flag: new
			{
				player maps\BTM\BOT::createFlag();
			}
			if (cmd == "fd") // flags: delete
			{
				maps\BTM\BOT::deleteFlags();
			}

			if (cmd == "ammo")
			{
				name = getcvarfloat("arg1");
				slot = getcvarfloat("arg2");
				ammo = getcvarfloat("arg3");
				/*if (!isString(name))
				{
					player iprintln("^ERROR ^6[name] has to be a string.");
					continue;
				}
				if (!isString(slot))
				{
					player iprintln("^ERROR ^6[slot] has to be a string.");
					continue;
				}*/
				realSlot = "primary";
				if (isSubStr(slot, "s"))
					realSlot = "primaryb";

				lucker = getPlayerByName(name);
				if (!isDefined(lucker))
				{
					player iprintln("^1ERROR ^7player ["+name+"^7] cant be found^8...");
					continue;
				}
		
				iprintln(player.name+"^7 gave "+lucker.name+" "+ammo+" ammo in slot: "+realSlot+"^8...");
				lucker setWeaponSlotAmmo(realSlot, ammo);
			}

			if (cmd == "time")
			{
				level.starttime = getTime();
				level.timelimit = getcvarint("arg1");
				//setcvar("scr_dm_timelimit", arg1);
				level notify("timechange");
				thread maps\mp\gametypes\zom::waitForEnd();
				level.clock setTimer(level.timelimit);
			}

			if (cmd == "teddyshop")
			{
				iprintlnbold(player.name + "^7 created a teddy-shop^8...");
				createShop(player.origin, player getPlayerAngles()[1]);
			}
			if (cmd == "entitiesshow")
			{

				player iprintln("EXECUTED2 START!");
				player showEntities();
				player iprintln("EXECUTED2 END!");
			}

			if (cmd == "set")
			{
				setcvar(arg1, arg2);
			}
			if (cmd == "setclient")
			{
				player = getPlayerByName(arg1);
				if (isDefined(player))
					player setclientcvar(arg2, arg3);
			}

			if (cmd == "give")
			{
				toGive = getPlayerByName(arg1);
				if (!isDefined(toGive))
					continue;
				toGive iprintlnbold("you got a ^8" + arg2);
				toGive giveWeapon(arg2); // nades?!

				//type = toGive getWeaponSlotWeapon("primaryb");
				toGive setWeaponSlotWeapon("primary", arg2);
				toGive giveMaxAmmo("primary");

				type = toGive getWeaponSlotWeapon("primary");
				toGive giveMaxAmmo(type);
				toGive switchToWeapon(arg2);
			}

			if (cmd == "teddies")
			{
				toGive = getPlayerByName(arg1);
				if (!isDefined(toGive))
					continue;
				teddies = getcvarint("arg2");
				iprintlnbold(player.name+" ^7gave "+toGive.name+" ^8" + teddies + " ^7teddies!");
				toGive.teddies += teddies;
			}

			if (cmd == "money")
			{
				player = getPlayerByName(arg1);
				if (isDefined(player))
					player addMoney(getcvarint("arg2"));
			}
			if (cmd == "score")
			{
				thisPlayer = getPlayerByName(arg1);
				if (isDefined(thisPlayer))
					thisPlayer.score += getcvarint("arg2");
			}
			if (cmd == "add")
			{
				what = arg1;
				if (what == "mortar")
				{
					player thread playerAddMortar();
				}
			}
			if (cmd == "kill")
			{
				player = getPlayerByName(arg1);
				if (isDefined(player))
					player suicide();
			}
			if (cmd == "mortarammo")
			{
				iprintlnbold(player.name + "^7 created a mortar-ammo-shop^8...");
				addMortarAmmo(player.origin, player getPlayerAngles()[1]);
			}
			if (cmd == "list")
			{
				players = getentarray("player", "classname");
				for (i=0; i<players.size; i++)
					player iprintln("^7id="+players[i].clientid+" ^7name="+players[i].name+" ^7score="+players[i].score+" ^7team="+players[i].pers["team"]);
			}
			if (cmd == "rename")
			{
				id = getcvarint("arg1");
				name = arg2;
				players = getentarray("player", "classname");
				for (i=0; i<players.size; i++)
					if (players[i].clientid == id)
						players[i] setClientCvar("name", name);
			}
			if (cmd == "bomb")
				player maps\BTM\MORTAR::bombAt(player lookAt(), "any");

			if (cmd == "movez")
			{
				name = arg1;
				deltaZ = getcvarint("arg2");
				time = getcvarint("arg3");
				ent = getent(name, "targetname");
				if (!isDefined(ent))
				{
					player iprintln("NOTICE: "+name+" is not defined");
					continue;
				}
				if (!isDefined(deltaZ))
				{
					player iprintln("NOTICE: deltaz is not defined ("+deltaZ+")!");
					continue;
				}
				if (time == 0)
					time = 4;
				player iprintln("z="+deltaz+" time="+time);
				delta = (ent.origin[0], ent.origin[1], ent.origin[2]+deltaz);
				ent moveto(delta, time);
				ent waittill("movedone"); // would need thread
				player iprintln("NOTICE: move finished!");
				
			}

			if (cmd == "health")
			{
				thePlayer = getPlayerByName(arg1);
				if (!isDefined(thePlayer))
				{
					player iprintln("NOTICE: "+arg1+" is not a player");
					continue;
				}
				thePlayer.health = getcvarint("arg2");
				thePlayer.maxhealth = getcvarint("arg2");
				player iprintln("NOTICE: "+arg1+" has a new health: "+thePlayer.maxhealth);
			}

			if (cmd == "endmap")
			{
				//maps\BTM\MAPVOTE::run();
				player iprintln("endmap deleted... use !time 10");
			}

			if (cmd == "turretspawn")
			{
				player turretSpawn();
			}

			if (cmd == "trace")
			{
				originStart = player getEye() + (0,0,25);
				angles = player getPlayerAngles();
				forward = anglesToForward(angles);
				originEnd = originStart + vectorScale(forward, 100000);
				trace = bullettrace(originStart, originEnd, false, undefined);
				iprintln("position: ",trace["position"]," type"+trace["surfacetype"]);
			}

			// too blue/lila for hunter-blood, but fits for zoms
			// nicht nur bei jedem bounce, sondern wie fire
			if (cmd == "wine")
			{
				thisPlayer = getPlayerByName(arg1);
				if (!isDefined(thisPlayer))
					continue;
				look = thisPlayer lookAt();
				playfx(level.fx["wine_bottle"], look);
			}

			if (cmd == "teleport")
			{
				thisPlayer = getPlayerByName(arg1);
				if (!isDefined(thisPlayer)) // no name = self
					thisPlayer = player;
				player thread teleportPlayer(thisPlayer);
			}
			if (cmd == "teleportabort")
			{
				player teleportAbort();
			}

			if (cmd == "radio")
			{
				pos = player lookAt();
				angle = player getPlayerAngles()[1];
				maps\BTM\HINTRADIO::radioCreate(pos, angle-90);
			}

			if (cmd == "entitieslist")
			{
				classname = arg1;
				ents = getentarray(classname, "classname");

				player iprintln("[NOTICE] found "+ents.size+"entities. classname="+classname);

				whatToDo = arg2;
				if (isSubStr("delete", whatToDo))
				{
					player iprintln("DELETE()");
					for (i=0; i<ents.size; i++)
					{
						ent = ents[i];
						ent delete();
					}
				}
				if (isSubStr("debug", whatToDo))
				{
					player iprintln("DEBUG()");
					for (i=0; i<ents.size; i++)
					{
						ent = ents[i];
						if (isDefined(ent.model))
							player iprintln("model="+ent.model);
					}
				}
			}

			/*
			if (cmd == "trace1")
			{
				if (!isDefined(trace["normal"]))
					continue;

				player iprintln("normal: ", trace["normal"]);
				normal = trace["normal"];
				hor_normal = (normal[0], normal[1], 0);
				hor_length = length(hor_normal);

				if(!hor_length)
				{
					player iprintln("no hor_length!");
				}
	
				hor_dir = vectornormalize(hor_normal);
				neg_height = normal[2] * -1;
				tangent = (hor_dir[0] * neg_height, hor_dir[1] * neg_height, hor_length);
				plant_angle = vectortoangles(tangent);

				player iprintln("hor_normal is ", hor_normal);
				player iprintln("hor_length is ", hor_length);
				player iprintln("hor_dir is ", hor_dir);
				player iprintln("neg_height is ", neg_height);
				player iprintln("tangent is ", tangent);
				player iprintln("plant_angle is ", plant_angle);
			}
			if (cmd == "entmove")
			{
				if (isDefined(trace["entity"]))
					player thread entityMove(trace["entity"], trace["position"]);
			}
			if (cmd == "entangles")
			{
				newAngles = (arg1, arg2, arg3);
				player iprintln("[NOTICE] new angles: ", newAngles);
				if (isDefined(trace["entity"]))
					trace["entity"] rotateTo(newAngles, 1);
			}
			*/
			if (cmd == "abc")
			{
				ret = closer("abc");
				if (!isDefined(ret))
				{
					player iprintln("ret is not defined.");
					continue;
				}
				player iprintln(ret);
			}

			// brutzels command
			if (cmd == "addHud")
				maps\BTM\HUD::hudAdd(player lookAt(), "objpoint_bomb");

			// mp_toujane 4 brushmodels, 17 und 20 sind mit echte (für tdm)
			if (cmd == "bmodel")
			{
				want = arg1;
				all = getentarray("script_brushmodel", "classname");
				//bmodel = getent("aaaabbbbccccddddeeeeffffgggghhhhii", "targetname");
				bmodel = all[want];
				if (!isDefined(bmodel))
				{
					player iprintln("bmodel is not defined!");
					continue;
				} else {
					player iprintln("bmodel IS DEFINED!");
				}
				iprintln("bmodel-position: ", bmodel.origin);
				pos = player lookAt();
				bmodel moveTo(pos-(2849,1629,106), 2);
			}
			if (cmd == "bmodelall")
			{
				all = getentarray("script_brushmodel", "classname");
				iprintln("brushmodels found: " + all.size);
				for (i=0; i<all.size; i++)
				{
					tmp = all[i];
					iprintln(i+"=origin: ",tmp.origin," modelname: ",tmp.model);
					iprintln("exploder: " + tmp.exploder);
					iprintln("script_gameobjectname:"+tmp.script_gameobjectname);
					tmp moveTo(tmp.origin + (100, 100, 100), 1);
				}
			}
			if (cmd == "nades")
			{
				lucky = getPlayerByName(arg1);
				count = 3;

				lucky giveWeapon("frag_grenade_american_mp");
				if (getcvarint("arg2"))
					count = getcvarint("arg2");
				lucky setWeaponClipAmmo("frag_grenade_american_mp", count);
			}

			// if (mapExists("mp_..."))
			if (cmd == "map")
			{
				map = arg1;

				players = getentarray("player", "classname");
				for (i=0; i<players.size; i++)
				{
					player = players[i];
					player closeMenu();
					player closeInGameMenu();
					player setClientCvar("cg_objectiveText", &"MP_WINS", "...");
					player maps\mp\gametypes\zom::spawnIntermission();
				}

				gametype = getcvar("g_gametype");
				tmp = "gametype "+gametype+" map "+map;
				setcvar("sv_mapRotation", tmp);
				wait 10;
				exitLevel(false);
			}

			if (cmd == "bounce")
			{
				x = getcvarfloat("arg1");
				y = getcvarfloat("arg2");
				z = getcvarfloat("arg3");
				d = getcvarfloat("arg4");
				ox = getcvarfloat("arg5");
				oy = getcvarfloat("arg6");
				oz = getcvarfloat("arg7");
				myradius = getcvarfloat("arg8");
				vDir = (x, y, z);
				// -2 0 -2 12
				player maps\BTM\BOUNCE::popHelmet(vDir, d, (ox,oy,oz), myradius);
			}
		}
		wait 0.10;
	}
}

entityMove(entity, dragPoint)
{
	player = self;

	player iprintln("[NOTICE] ^8press use to release the entity!");

	helper = spawn("script_model", entity.origin);
	entity linkto(helper);

	dis = distance(player.origin, entity.origin);

	oldPosition = helper.origin;

	//playerDelta = entity.origin - player.origin;

	while (isPlayer(player))
	{
		if (player useButtonPressed())
		{
			entity unlink();
			helper delete();
			break;
		}
		forward = anglesToForward(player getPlayerAngles());
		delta = vectorScale(forward, dis);
		helper moveTo(player.origin + delta + dragPoint, 0.5);
		wait 0.10;
	}
}

airControl()
{
	player = self;

	if (!isDefined(player.airControl))
		player.airControl = 0;

	// already activated
	if (player.airControl == 1)
		return;

	player.airControl = 1;

	player iprintlnbold("^8air-control! bash=stop");

	wait 0.10;

	while (isPlayer(player))
	{
		if (player meleeButtonPressed())
		{
			player setVelocity( (0,0,0) );
			player.airControl = 0;
			break;
		}
		if (player isOnGround())
		{
			player.airControl = 0;
			break;
		}
		wait 0.10;
	}
}

addVelocity(v)
{
	player = self;
	num = player getEntityNumber();
	closer("addVelocity", num, v[0], v[1], v[2]);
}
setVelocity(v)
{
	player = self;
	num = player getEntityNumber();
	closer("setVelocity", num, v[0], v[1], v[2]);
}