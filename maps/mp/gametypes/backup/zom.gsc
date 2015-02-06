/*
	classname	mp_tdm_spawn
	classname	mp_global_intermission
	Atleast one is required, any more and they are randomly chosen between.

	game["allies"] = "american";
	game["axis"] = "german";

	If using minefields or exploders... maps\mp\_load::main();

	game["american_soldiertype"] = "normandy";
	game["german_soldiertype"] = "normandy";

	american_soldiertype	normandy
	british_soldiertype	normandy, africa
	russian_soldiertype	coats, padded
	german_soldiertype	normandy, africa, winterlight, winterdark
*/

/*QUAKED mp_tdm_spawn (0.0 0.0 1.0) (-16 -16 0) (16 16 72)
Players spawn away from enemies and near their team at one of these positions.*/

/*
	TODO
	 - player-killcam on every player when the last hunter got killed... self maps\mp\gametypes\_killcam::killcam(attackerNum, delay, psOffsetTime, true);
	 - spectator können per "press f" hunter joinen, wenn eine neue runde anfing
*/

#include maps\BTM\UTILS;
#include maps\BTM\PLAYER;

main()
{
	level.callbackStartGameType = ::Callback_StartGameType;
	level.callbackPlayerConnect = ::Callback_PlayerConnect;
	level.callbackPlayerDisconnect = ::Callback_PlayerDisconnect;
	level.callbackPlayerDamage = ::Callback_PlayerDamage;
	level.callbackPlayerKilled = ::Callback_PlayerKilled;
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();

	level.autoassign = ::menuAutoAssign;
	level.allies = ::menuAllies;
	level.axis = ::menuAxis;
	level.spectator = ::menuSpectator;
	level.weapon = ::menuWeapon;
	//level.endgameconfirmed = ::endMap;

	// 123123231
	//maps\mp\gametypes\actionhandler::init();
}

Callback_StartGameType()
{
	// "level.splitscreen" must have a value, or the menus doesnt work
	// maybe an error in developer-mode
	level.splitscreen = isSplitScreen();

	if (!isDefined(game["allies"]))
		game["allies"] = "american";
	if (!isDefined(game["axis"]))
		game["axis"] = "german";

	precacheStatusIcon("hud_status_dead");
	precacheStatusIcon("hud_status_connecting");
	precacheRumble("damage_heavy");
	precacheString(&"PLATFORM_PRESS_TO_SPAWN");


	thread maps\mp\gametypes\_menus::init();
	thread maps\mp\gametypes\_serversettings::init();
	thread maps\mp\gametypes\_clientids::init();
	thread maps\mp\gametypes\_teams::init();
	thread maps\mp\gametypes\_weapons::init();
	thread maps\mp\gametypes\_scoreboard::init();
	thread maps\mp\gametypes\_killcam::init();
	thread maps\mp\gametypes\_shellshock::init();
	//thread maps\mp\gametypes\_hud_teamscore::init();
	thread maps\mp\gametypes\_deathicons::init();
	thread maps\mp\gametypes\_damagefeedback::init();
	thread maps\mp\gametypes\_healthoverlay::init();
	thread maps\mp\gametypes\_friendicons::init();
	thread maps\mp\gametypes\_spectating::init();
	thread maps\mp\gametypes\_grenadeindicators::init();
	thread maps\mp\gametypes\_quickmessages::init();

	// 123123231
	maps\BTM\WEAPONS::precache();
	thread maps\BTM\LIVESTATS::main();
	//thread maps\mp\gametypes\parser::main();

	setClientNameMode("auto_change"); // wtf?!

	spawnpointname = "mp_tdm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i=0; i<spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();

	allowed[0] = "tdm";
	maps\mp\gametypes\_gameobjects::main(allowed);

	level.timelimit = 30*60; // 30 minutes a map

	if(!isDefined(game["state"]))
		game["state"] = "playing";

	level.mapended = false;

	thread startGame();
}

dummy()
{
	waittillframeend;
	if(isdefined(self))
		level notify("connecting", self);
}

Callback_PlayerConnect()
{
	player = self;
	thread dummy();

	self.statusicon = "hud_status_connecting";
	self waittill("begin");
	self.statusicon = "";

	level notify("connected", self);

	iprintln(&"MP_CONNECTED", self.name);

	lpselfnum = self getEntityNumber();
	lpGuid = self getGuid();
	logPrint("J;" + lpGuid + ";" + lpselfnum + ";" + self.name + "\n");

	if(game["state"] == "intermission")
	{
		spawnIntermission();
		return;
	}

	level endon("intermission");

	if (isDefined(player.isBot))
	{
		player spawnPlayer();
		return;
	}

	player menuSpectator();

	/*hunters = getTeamMember("allies");
	if (hunters.size == 0)
		player.pers["team"] = "allies";
	else
		player.pers["team"] = "axis";*/

	player thread pressUseToSpawn();

	scriptMainMenu = game["menu_ingame"];
	self setClientCvar("g_scriptMainMenu", scriptMainMenu);
}

removePressUseToSpawn()
{
	player = self;

	//player endon("spawned");

	while (player safeUseButtonPressed() == 0)
		wait 0.05;

	player maps\BTM\STARTHUD::hide();

	hunters = getTeamMember("allies");
	if (hunters.size == 0)
		player.pers["team"] = "allies";
	else
		player.pers["team"] = "axis";

	player notify("useButtonPressed");
	player spawnPlayer(); // is sending: player spawned_player
}
pressUseToSpawn()
{
	player = self;

	player endon("useButtonPressed"); // obsolete

	/*self.respawntext = newClientHudElem(player);
	self.respawntext.horzAlign = "center_safearea";
	self.respawntext.vertAlign = "center_safearea";
	self.respawntext.alignX = "center";
	self.respawntext.alignY = "middle";
	self.respawntext.x = 0;
	self.respawntext.y = 20;
	self.respawntext.archived = false;
	self.respawntext.font = "default";
	self.respawntext.fontscale = 2;
	self.respawntext setText(&"PLATFORM_PRESS_TO_SPAWN");*/

	player thread removePressUseToSpawn();

}

Callback_PlayerDisconnect()
{
	iprintln(&"MP_DISCONNECTED", self.name);

	if(isdefined(self.pers["team"]))
	{
		if(self.pers["team"] == "allies")
			setplayerteamrank(self, 0, 0);
		else if(self.pers["team"] == "axis")
			setplayerteamrank(self, 1, 0);
		else if(self.pers["team"] == "spectator")
			setplayerteamrank(self, 2, 0);
	}
	
	lpselfnum = self getEntityNumber();
	lpGuid = self getGuid();
	logPrint("Q;" + lpGuid + ";" + lpselfnum + ";" + self.name + "\n");
}

Callback_PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	player = self;

	// values for sMeansOfDeath: MOD_TRIGGER_HURT

	// prevent teamkill with:
	// throwing nades -> go spec
	// zombie gets hunter -> teddy is still exploding
	// but: allowed nading myself and teammembers
	if (player != eAttacker) // allow nading myself
	if (sMeansOfDeath == "MOD_GRENADE_SPLASH") // just check for teddy-explosions or nades
	if (eAttacker.pers["team"] != "allies")
		return;

	if (player.pers["team"] == "allies")
		player playSound("generic_pain_american_1");
	if (player.pers["team"] == "axis")
		player playSound("generic_meleecharge_german_3");

	switch (sHitLoc)
	{
		case "head":
		case "helmet":
			maps\BTM\BOUNCE::popHelmet(vDir, iDamage);
			break;
		case "none":
			if (iDamage >= 180)
				maps\BTM\BOUNCE::popHelmet(vDir, iDamage);
			break;
	}

	if (sMeansOfDeath == "MOD_FALLING")
		return;

	if (sMeansOfDeath == "MOD_MELEE")
	if (eAttacker.pers["team"] == "allies")
	if (self.pers["team"] == "axis")
	{
		//if (getcvarint("con_bashinstantkill") != 0)
		//	iDamage = 10000; // hunter = 1xbash 1xkill
		if (!isDefined(eAttacker.bashBonus))
			eAttacker.bashBonus = 0;

		eAttacker.bashBonus++;

		switch (eAttacker.bashBonus)
		{
			case 2:
				iprintlnbold("^8[^72x BASH REWARD^8]^7 " + eAttacker.name + "^8: ^71 mortar");
				eAttacker.mortarammo++;
				break;
			case 4:
				iprintlnbold("^8[^74x BASH REWARD^8]^7 " + eAttacker.name + "^8: ^71 teddy");
				eAttacker.teddies++;
				break;
			case 8:
				iprintlnbold("^8[^78x BASH REWARD^8]^7 " + eAttacker.name + "^8: ^7full ammo");

				type = eAttacker getWeaponSlotWeapon("primaryb");
				eAttacker giveMaxAmmo(type);
				type = eAttacker getWeaponSlotWeapon("primary");
				eAttacker giveMaxAmmo(type);
				//eAttacker.bashBonus = 0; // start again
				// bashBonus is resetted in playerSpawn();
				// prevents making rich on afk-zombies
				break;
		}
		//eAttacker iprintln("player.bashBonus="+player.bashBonus);
	}

	// Don't do knockback if the damage direction was not specified
	if(!isDefined(vDir))
		iDFlags |= level.iDFLAGS_NO_KNOCKBACK;

	friendly = undefined;

	// check for completely getting out of the damage
	if(!(iDFlags & level.iDFLAGS_NO_PROTECTION))
	{
		if(isPlayer(eAttacker) && (self != eAttacker) && (self.pers["team"] == eAttacker.pers["team"]))
		{
			if(level.friendlyfire == "0")
			{
				return;
			}
			else if(level.friendlyfire == "1")
			{
				// Make sure at least one point of damage is done
				if(iDamage < 1)
					iDamage = 1;

				self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

				// Shellshock/Rumble
				self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
				self playrumble("damage_heavy");
			}
			else if(level.friendlyfire == "2")
			{
				eAttacker.friendlydamage = true;

				iDamage = int(iDamage * .5);

				// Make sure at least one point of damage is done
				if(iDamage < 1)
					iDamage = 1;

				eAttacker finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				eAttacker.friendlydamage = undefined;

				friendly = true;
			}
			else if(level.friendlyfire == "3")
			{
				eAttacker.friendlydamage = true;

				iDamage = int(iDamage * .5);

				// Make sure at least one point of damage is done
				if(iDamage < 1)
					iDamage = 1;

				self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				eAttacker finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				eAttacker.friendlydamage = undefined;

				// Shellshock/Rumble
				self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
				self playrumble("damage_heavy");

				friendly = true;
			}
		}
		else
		{
			// Make sure at least one point of damage is done
			if(iDamage < 1)
				iDamage = 1;

			self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

			// Shellshock/Rumble
			//self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
			self playrumble("damage_heavy");
		}

		if(isdefined(eAttacker) && eAttacker != self)
			eAttacker thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback();
	}

	// Do debug print if it's enabled
	if(getCvarInt("g_debugDamage"))
		println("^7[^1DEBUG^7]client:" + self getEntityNumber() + " health:" + self.health + " damage:" + iDamage + " hitLoc:" + sHitLoc);

	if(self.sessionstate != "dead")
	{
		lpselfnum = self getEntityNumber();
		lpselfname = self.name;
		lpselfteam = self.pers["team"];
		lpselfGuid = self getGuid();
		lpattackerteam = "";

		if(isPlayer(eAttacker))
		{
			lpattacknum = eAttacker getEntityNumber();
			lpattackGuid = eAttacker getGuid();
			lpattackname = eAttacker.name;
			lpattackerteam = eAttacker.pers["team"];
		}
		else
		{
			lpattacknum = -1;
			lpattackGuid = "";
			lpattackname = "";
			lpattackerteam = "world";
		}

		if(isDefined(friendly))
		{
			lpattacknum = lpselfnum;
			lpattackname = lpselfname;
			lpattackGuid = lpselfGuid;
		}

		// prevent log-flooding...
		//logPrint("D;" + lpselfGuid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackGuid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");
	}

	if (isPlayer(eAttacker))
		eAttacker iprintlnbold("^7+^8"+iDamage+" "+player.health+"^7/^8"+player.maxhealth);
}

Callback_PlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	player = self;

	// !force 123123231 spectator
	if (self.sessionstate == "spectator")
		return;

	if (player.pers["team"] == "allies")
		player playSound("generic_pain_american_1");
	if (player.pers["team"] == "axis")
		player playSound("generic_meleecharge_german_3");

	execMyCode = 1;
	if (isDefined(self.isRespawning))
	if (self.isRespawning)
	{
		self.isRespawning = 0;
		execMyCode = 0;
		//return;
	}

	//iprintln("[KILLED] " + self.name+" - " + execMyCode);

	self endon("spawned");
	self notify("killed_player");

	if (execMyCode)
	{
	// 123123231
	player = self;
	if (player.pers["team"] == "allies")
	{
		hunters = getTeamMember("allies");
		if (hunters.size == 1) // 1 == the died hunter
		{
			zombies = getTeamMember("axis");
			for (i=0; i<zombies.size; i++)
			{
				zombies[i].pers["savedmodel"] = undefined;
				zombies[i].pers["team"] = "allies";
				zombies[i] iprintlnbold("you became a hunter^8...");
				zombies[i] respawn();
			}
		}

		player iprintlnbold("you became a zombie^8...");
		player.pers["team"] = "axis";
		player.pers["savedmodel"] = undefined;

	} else {
		hunter = getTeamMember("allies");
		zombies = getTeamMember("axis");

		if (hunter.size == 0 && zombies.size == 1)
		{
			player iprintlnbold("you became a hunter^8...");
			player.pers["savedmodel"] = undefined;
			player.pers["team"] = "allies";
		}
		else if (hunter.size == 0)
		{
			for (i=0; i<zombies.size; i++)
			{
				if (zombies[i] == player)
				{
					player iprintlnbold("you are the new zombie^8...");
					continue;
				}
				zombies[i].pers["savedmodel"] = undefined;
				zombies[i].pers["team"] = "allies";
				zombies[i] iprintlnbold("you became a hunter^8...");
				zombies[i] respawn();
			}
		}
		else
		{
			player iprintlnbold("you stay a zombie till the round restarts^8...");
		}
	}
	}
	if(self.sessionteam == "spectator")
		return;

	// If the player was killed by a head shot, let players know it was a head shot kill
	if(sHitLoc == "head" && sMeansOfDeath != "MOD_MELEE")
		sMeansOfDeath = "MOD_HEAD_SHOT";

	// send out an obituary message to all clients about the kill
	obituary(self, attacker, sWeapon, sMeansOfDeath);

	// 123123231
	//self maps\mp\gametypes\_weapons::dropWeapon();
	//self maps\mp\gametypes\_weapons::dropOffhand();



	self.sessionstate = "dead";
	self.statusicon = "hud_status_dead";

	lpselfnum = self getEntityNumber();
	lpselfname = self.name;
	lpselfguid = self getGuid();
	lpselfteam = self.pers["team"];
	lpattackerteam = "";

	attackerNum = -1;
	if(isPlayer(attacker))
	{
		if(attacker == self) // killed himself
		{
			doKillcam = false;

			if(isdefined(attacker.friendlydamage))
				attacker iprintln(&"MP_FRIENDLY_FIRE_WILL_NOT");
		}
		else
		{
			attackerNum = attacker getEntityNumber();
			doKillcam = true;
			attacker.score++;
			player.deaths++;
		}

		lpattacknum = attacker getEntityNumber();
		lpattackguid = attacker getGuid();
		lpattackname = attacker.name;
		lpattackerteam = attacker.pers["team"];
	}
	else // If you weren't killed by a player, you were in the wrong place at the wrong time
	{
		doKillcam = false;

		lpattacknum = -1;
		lpattackname = "";
		lpattackguid = "";
		lpattackerteam = "world";
	}

	logPrint("K;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");

	// Stop thread if map ended on this death
	if(level.mapended)
		return;

	body = self cloneplayer(deathAnimDuration);
	thread maps\mp\gametypes\_deathicons::addDeathicon(body, self.clientid, self.pers["team"], 5);

	delay = 2;	// Delay the player becoming a spectator till after he's done dying
	wait delay;	// ?? Also required for Callback_PlayerKilled to complete before respawn/killcam can execute

	if(doKillcam && level.killcam)
		self maps\mp\gametypes\_killcam::killcam(attackerNum, delay, psOffsetTime, true);

	self thread respawn();
}

getSpawnpoints()
{
	spawnpoints = getentarray("mp_dm_spawn", "classname");
	spawns = [];
	for (i=0; i<spawnpoints.size; i++)
	{
		spawns[i] = spawnstruct();
		spawns[i].origin = spawnpoints[i].origin;
		spawns[i].angles = spawnpoints[i].angles;
	}
	spawnpoints = getentarray("mp_tdm_spawn", "classname");
	for (i=0; i<spawnpoints.size; i++)
	{
		spawns[i] = spawnstruct();
		spawns[i].origin = spawnpoints[i].origin;
		spawns[i].angles = spawnpoints[i].angles;
	}
	return spawns;
}
arrayAdd(theArray, theElement)
{
	theArray[theArray.size] = theElement;
}
getActiveHunters()
{
	hunters = getentarray("player", "classname");
	activeHunters = [];
	for (i=0; i<hunters.size; i++)
	{
		hunter = hunters[i];
		if (hunter.pers["team"] == "allies")
		if (hunter.sessionstate == "playing")
			activeHunters[activeHunters.size] = hunter;
	}
	return activeHunters;
}
findSpawnpoint()
{
	spawnpoints = getSpawnpoints();
	activeHunters = getActiveHunters();

	if (activeHunters.size == 0)
	{
		// todo: pick random!
		spawnpoint = spawnpoints[0];
		return spawnpoint;
	}

	// den nähesten hunter für jeden spawnpoint berechnen
	for (i=0; i<spawnpoints.size; i++)
	{
		spawnpoint = spawnpoints[i];
		for (j=0; j<activeHunters.size; j++)
		{
			hunter = activeHunters[j];
			dist = distance(hunter.origin, spawnpoint.origin);

			if (!isDefined(spawnpoint.nearestHunter))
			{
				spawnpoint.nearestHunter = dist;
			} else if (dist < spawnpoint.nearestHunter) {
					spawnpoint.nearestHunter = dist;
			}
		}
	}

	bestSpawnpoint = spawnpoints[0];
	// erst den schlechtesten finden (am weitesten weg)
	for (i=1; i<spawnpoints.size; i++)
	{
		spawnpoint = spawnpoints[i];
		if (spawnpoint.nearestHunter > bestSpawnpoint.nearestHunter)
			bestSpawnpoint = spawnpoint;
	}
	// jetzt immer besser werden (weiter weg als 1000 aber näher als der beste)
	for (i=1; i<spawnpoints.size; i++)
	{
		spawnpoint = spawnpoints[i];
		if (spawnpoint.nearestHunter > 1000)
		if (spawnpoint.nearestHunter < bestSpawnpoint.nearestHunter)
			bestSpawnpoint = spawnpoint;
	}
	return bestSpawnpoint;
}

zombieSpawn(position, angles)
{
	player = self;

	player playsound("grenade_explode_dirt");
	playfx(level.fx["large_mud"], position);

	player spawn(position+(0,0,-80),angles);
	helper = spawnEntity(position+(0,0,-80));
	player linkto(helper);
	wait 0.05; // let it happen
	helper moveTo(position, 0.8);
	helper waittill("movedone");
	player unlink();
	helper delete();
	//player.origin = position;
}

spawnPlayer()
{
	player = self;

	self endon("disconnect");
	self notify("end_respawn");
	self notify("spawned");

	resettimeout();

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");

	player setClientCvar("ui_allow_joinallies", "0");
	player setClientCvar("ui_allow_joinaxis", "0");
	player setClientCvar("ui_allow_joinauto", "1");
	player setClientCvar("ui_allow_weaponchange", "1");


	player.pers["savedmodel"] = undefined;
	player maps\BTM\STARTHUD::hide();

	player.bashBonus = 0;

	/*hunters = getTeamMember("allies");
	if (hunters.size == 0)
		player.pers["team"] = "allies";
	else
		player.pers["team"] = "axis";*/

	if (!isDefined(self.pers["team"]))
	{
		player iprintln("[^1NOTICE^7] team was undefined^8...");
		player.pers["team"] = "axis";

	}
	zombies = getTeamMember("axis");
	//iprintlnbold("ZOMBIE COUNT: " + zombies.size);
	if (zombies.size == 0)
	{
		for (i=0; i<zombies.size; i++)
		{
			zombie = zombies[i];
			if (zombie == self)
				continue;
			zombie.pers["team"] = "allies";
			zombie respawn();
		}
	}

	// true, when joining from playerconnect-spectating
	if (self.pers["team"] != "axis" && self.pers["team"] != "allies")
		self.pers["team"] = "axis";

	self.sessionteam = self.pers["team"];
	self.sessionstate = "playing";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.statusicon = "";
	self.maxhealth = getcvarint("healthhunter"); // melee damage of kar89k

	// 123123231
	//iprintlnbold("ZOMBIE COUNT: " + zombies.size);
	if (self.pers["team"] == "axis")
	{
		cvarhealth = getcvarint("healthzom");
		if (isDefined(cvarhealth))
			self.maxhealth = cvarhealth;
		else
			self.maxhealth = 270;
		axis = getTeamMember("axis"); // isAtLeast3Zombies()
		allies = getTeamMember("allies");
		//axisCount = 0;
		//for (i=0; i<axis.size; i++)
		//	if (axis[i].sessionstate == "playing") // bugged: 2zoms, 1isDead=>just 1
		//		axisCount++;

		// just one powerzombie with atleast three hunters
		if (axis.size == 1 && allies.size > 2)
		{
			cvarhealthpowerzom = getcvarint("healthpowerzom");
			if (isDefined(cvarhealthpowerzom))
				self.maxhealth = cvarhealthpowerzom;
			else
				self.maxhealth = 420;

			iprintlnbold(self.name + " ^7is a power-zombie! health: "+self.maxhealth+"^8...");
		}
	}

	self.health = self.maxhealth;
	self.friendlydamage = undefined;



	if (player.pers["team"] == "axis")
	{
		spawnpoint = findSpawnpoint();
		//if (isDefined(spawnpoint.nearestHunter))
		//	iprintln("[DEBUG] spawnpoint.nearestHunter: " + spawnpoint.nearestHunter);
		//else
		//	iprintln("[DEBUG] spawnpoint.nearestHunter: not defined");

		self thread zombieSpawn(spawnpoint.origin, spawnpoint.angles);
	} else {
		spawnpointname = "mp_tdm_spawn";
		spawnpoints = getentarray(spawnpointname, "classname");
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnpoints);
		if(isDefined(spawnpoint))
			self spawn(spawnpoint.origin, spawnpoint.angles);
		else
			maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}

	// mario wollte jumpen:
	// !exclude Unknown

	// eyeless wollte bots kicken:
	// !kick aaa*

	if(!isDefined(self.pers["savedmodel"]))
		maps\mp\gametypes\_teams::model();
	else
		maps\mp\_utility::loadModel(self.pers["savedmodel"]);

	// 123123231
	//maps\mp\gametypes\_weapons::givePistol();
	//maps\mp\gametypes\_weapons::giveGrenades();
	//maps\mp\gametypes\_weapons::giveBinoculars();
	//self giveWeapon(self.pers["weapon"]);
	//self giveMaxAmmo(self.pers["weapon"]);
	//self setSpawnWeapon(self.pers["weapon"]);

	self setClientCvar("cg_objectiveText", &"MP_GAIN_POINTS_BY_ELIMINATING1_NOSCORE");

	// 123123231
	player = self;
	player takeAllWeapons();

	weapon = "kar98k_mp";
	player giveWeapon(weapon);
	player setWeaponSlotWeapon("primaryb", "tt30_mp");
	player setSpawnWeapon(weapon);
	if (player.pers["team"] == "allies")
	{
		//player setWeaponSlotAmmo("primary", 40); // reloadable ammunition
		//player setWeaponSlotClipAmmo("primary", 5); // currently in weapon
		player setWeaponSlotAmmo("primaryb", 30); // reloadable ammunition
		player setWeaponSlotClipAmmo("primaryb", 15); // currently in weapon
		player giveWeapon("frag_grenade_american_mp");
		player setWeaponClipAmmo("frag_grenade_american_mp", 3);

		player giveMaxAmmo(weapon);
		player giveMaxAmmo("tt30_mp");

		//player takeWeapon("smoke_grenade_american_mp");
		//player giveWeapon("smoke_grenade_american_mp");
		//player setWeaponClipAmmo("smoke_grenade_american_mp", 1);
	}
	if (player.pers["team"] == "axis")
	{
		player setWeaponSlotAmmo("primary", 0); // reloadable ammunition
		player setWeaponSlotClipAmmo("primary", 0); // currently in weapon
		player setWeaponSlotAmmo("primaryb", 0); // reloadable ammunition
		player setWeaponSlotClipAmmo("primaryb", 0); // currently in weapon
	}

	waittillframeend;
	self notify("spawned_player");
}

spawnSpectator(origin, angles)
{
	self notify("spawned");
	self notify("end_respawn");

	resettimeout();

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");

	self.sessionstate = "spectator";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.friendlydamage = undefined;

	if(self.pers["team"] == "spectator")
		self.statusicon = "";

	maps\mp\gametypes\_spectating::setSpectatePermissions();

	if(isDefined(origin) && isDefined(angles))
		self spawn(origin, angles);
	else
	{
		spawnpointname = "mp_global_intermission";
		spawnpoints = getentarray(spawnpointname, "classname");
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);

		if(isDefined(spawnpoint))
			self spawn(spawnpoint.origin, spawnpoint.angles);
		else
			maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}

	self setClientCvar("cg_objectiveText", "");
}

spawnIntermission()
{
	self notify("spawned");
	self notify("end_respawn");

	resettimeout();

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");

	self.sessionstate = "intermission";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.friendlydamage = undefined;

	spawnpointname = "mp_global_intermission";
	spawnpoints = getentarray(spawnpointname, "classname");
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);

	if(isDefined(spawnpoint))
		self spawn(spawnpoint.origin, spawnpoint.angles);
	else
		maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
}

respawn()
{
	self endon("end_respawn");

	// 123123231
	/*if(getCvarInt("scr_forcerespawn") <= 0)
	{
		self thread waitRespawnButton();
		self waittill("respawn");
	}*/

	if (self.sessionstate != "dead")
	{
		self.isRespawning = 1;
		self suicide();
	}

	if (self.sessionstate == "spectator")
		self.isRespawning = 0;

	self thread spawnPlayer();
}

waitRespawnButton()
{
	self endon("disconnect");
	self endon("end_respawn");
	self endon("respawn");

	wait 0; // Required or the "respawn" notify could happen before it's waittill has begun

	self.respawntext = newClientHudElem(self);
	self.respawntext.horzAlign = "center_safearea";
	self.respawntext.vertAlign = "center_safearea";
	self.respawntext.alignX = "center";
	self.respawntext.alignY = "middle";
	self.respawntext.x = 0;
	self.respawntext.y = -50;
	self.respawntext.archived = false;
	self.respawntext.font = "default";
	self.respawntext.fontscale = 2;
	self.respawntext setText(&"PLATFORM_PRESS_TO_SPAWN");

	thread removeRespawnText();
	thread waitRemoveRespawnText("end_respawn");
	thread waitRemoveRespawnText("respawn");

	while(self useButtonPressed() != true)
		wait .05;

	self notify("remove_respawntext");

	self notify("respawn");
}

removeRespawnText()
{
	self waittill("remove_respawntext");

	if(isDefined(self.respawntext))
		self.respawntext destroy();
}

waitRemoveRespawnText(message)
{
	self endon("remove_respawntext");

	self waittill(message);
	self notify("remove_respawntext");
}

waitForEnd()
{
	level endon("timechange");
	wait level.timelimit;
	iprintln(&"MP_TIME_LIMIT_REACHED");

	allPlayers = getentarray("player", "classname");
	for (i=0; i<allPlayers.size; i++)
	{
		player = allPlayers[i];
		player.oldTeam = player.pers["team"];
		player.sessionstate = "spectator";
		player.sessionteam = "spectator";
	}
	newMap = maps\BTM\MAPVOTE::run();
	for (i=0; i<allPlayers.size; i++)
	{
		player = allPlayers[i];
		player.sessionteam = player.oldTeam;
		player.sessionstate = "playing";
	}

	// search best player...
	isTie = false;
	bestPlayer = undefined;
	players = getentarray("player", "classname");
	if (players.size == 0) {
		isTie = true;
	} else {
		bestPlayer = players[0];
		for (i=1; i<players.size; i++)
		{
			player = players[i];
			if (player.score > bestPlayer.score) {
				bestPlayer = player;
				isTie = false;
			} else if (player.score == bestPlayer.score) {
				isTie = true;
			}
		}
	}
	players = getentarray("player", "classname");
	for (i=0; i<players.size; i++)
	{
		player = players[i];
		player closeMenu();
		player closeInGameMenu();

		if (isTie)
			player setClientCvar("cg_objectiveText", &"MP_THE_GAME_IS_A_TIE");
		else
			player setClientCvar("cg_objectiveText", &"MP_WINS", bestPlayer.name);

		// player showscoreboard(player, 1); doesnt work at all
		player maps\mp\gametypes\zom::spawnIntermission();
	}
	wait 10;

	gametype = getcvar("g_gametype");
	tmp = "gametype "+gametype+" map "+newMap;
	setcvar("sv_mapRotation", tmp);
	exitLevel(false);
}
startGame()
{
	//level.starttime = getTime();

	level.clock = newHudElem();
	level.clock.horzAlign = "left";
	level.clock.vertAlign = "top";
	level.clock.x = 8;
	level.clock.y = 2;
	level.clock.font = "default";
	level.clock.fontscale = 2;
	level.clock setTimer(level.timelimit);

	thread waitForEnd();
}

//logPrint("W;some;data\n");

menuAutoAssign()
{
	// 123123231
	player = self;
	player iprintlnbold("you joined the zombie-team^8...");
	player.pers["team"] = "axis";
	player.pers["savedmodel"] = undefined;
	player respawn();
	if (1 < 2)
		return;

	numonteam["allies"] = 0;
	numonteam["axis"] = 0;

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(!isDefined(player.pers["team"]) || player.pers["team"] == "spectator" || player == self)
			continue;

		numonteam[player.pers["team"]]++;
	}

	// if teams are equal return the team with the lowest score
	if(numonteam["allies"] == numonteam["axis"])
	{
		if(getTeamScore("allies") == getTeamScore("axis"))
		{
			teams[0] = "allies";
			teams[1] = "axis";
			assignment = teams[randomInt(2)];
		}
		else if(getTeamScore("allies") < getTeamScore("axis"))
			assignment = "allies";
		else
			assignment = "axis";
	}
	else if(numonteam["allies"] < numonteam["axis"])
		assignment = "allies";
	else
		assignment = "axis";

	if(assignment == self.pers["team"] && (self.sessionstate == "playing" || self.sessionstate == "dead"))
	{
	    if(!isdefined(self.pers["weapon"]))
	    {
		    if(self.pers["team"] == "allies")
			    self openMenu(game["menu_weapon_allies"]);
		    else
			    self openMenu(game["menu_weapon_axis"]);
	    }

		return;
	}

	if(assignment != self.pers["team"] && (self.sessionstate == "playing" || self.sessionstate == "dead"))
	{
		self.switching_teams = true;
		self.joining_team = assignment;
		self.leaving_team = self.pers["team"];
		self suicide();
	}

	self.pers["team"] = assignment;
	self.pers["weapon"] = undefined;
	self.pers["savedmodel"] = undefined;

	self setClientCvar("ui_allow_weaponchange", "1");

	if(self.pers["team"] == "allies")
	{	
		self openMenu(game["menu_weapon_allies"]);
		self setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);
	}
	else
	{	
		self openMenu(game["menu_weapon_axis"]);
		self setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);
	}

	self notify("joined_team");
	self notify("end_respawn");
}

menuAllies()
{
	// 123123231
	player = self;
	player iprintln("[^1NOTICE^7] weapon-change disabled (for allies)");
	if (1 < 2)
		return;

	if(self.pers["team"] != "allies")
	{
		if(self.sessionstate == "playing")
		{
			self.switching_teams = true;
			self.joining_team = "allies";
			self.leaving_team = self.pers["team"];
			self suicide();
		}

		self.pers["team"] = "allies";
		self.pers["weapon"] = undefined;
		self.pers["savedmodel"] = undefined;

		self setClientCvar("ui_allow_weaponchange", "1");
		self setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);

		self notify("joined_team");
		self notify("end_respawn");
	}

	if(!isdefined(self.pers["weapon"]))
		self openMenu(game["menu_weapon_allies"]);
}

menuAxis()
{
	// 123123231
	player = self;
	player iprintln("[^1NOTICE^7] team-change disabled (for axis)");
	if (1 < 2)
		return;

	if(self.pers["team"] != "axis")
	{
		if(self.sessionstate == "playing")
		{
			self.switching_teams = true;
			self.joining_team = "axis";
			self.leaving_team = self.pers["team"];
			self suicide();
		}

		self.pers["team"] = "axis";
		self.pers["weapon"] = undefined;
		self.pers["savedmodel"] = undefined;

		self setClientCvar("ui_allow_weaponchange", "1");
		self setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);

		self notify("joined_team");
		self notify("end_respawn");
	}

	if(!isdefined(self.pers["weapon"]))
		self openMenu(game["menu_weapon_axis"]);
}

menuSpectator()
{
	if(self.pers["team"] != "spectator")
	{

		self.pers["team"] = "spectator";
		self.pers["weapon"] = undefined;
		self.pers["savedmodel"] = undefined;

		self.sessionteam = "spectator";
		self setClientCvar("ui_allow_weaponchange", "0");

		self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);
		self notify("joined_spectators");

		if (isAlive(self))
			self suicide();

		spawnSpectator();
	}
}

menuWeapon(response)
{
	// 123123231
	player = self;
	player iprintln("[^1NOTICE^7] weapon-change disabled");
	//player maps\BTM\WEAPONCHOOSE::main();

	if (1 < 2)
		return;

	if(!isDefined(self.pers["team"]) || (self.pers["team"] != "allies" && self.pers["team"] != "axis"))
		return;

	weapon = self maps\mp\gametypes\_weapons::restrictWeaponByServerCvars(response);

	if(weapon == "restricted")
	{
		if(self.pers["team"] == "allies")
			self openMenu(game["menu_weapon_allies"]);
		else if(self.pers["team"] == "axis")
			self openMenu(game["menu_weapon_axis"]);

		return;
	}

	self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);

	if(isDefined(self.pers["weapon"]) && self.pers["weapon"] == weapon)
		return;

	if(!isDefined(self.pers["weapon"]))
	{
		self.pers["weapon"] = weapon;
		spawnPlayer();
	}
	else
	{
		self.pers["weapon"] = weapon;

		weaponname = maps\mp\gametypes\_weapons::getWeaponName(self.pers["weapon"]);

		if(maps\mp\gametypes\_weapons::useAn(self.pers["weapon"]))
			self iprintln(&"MP_YOU_WILL_RESPAWN_WITH_AN", weaponname);
		else
			self iprintln(&"MP_YOU_WILL_RESPAWN_WITH_A", weaponname);
	}

	self thread maps\mp\gametypes\_spectating::setSpectatePermissions();
}

playSoundOnPlayers(sound, team)
{
	players = getentarray("player", "classname");

	if(isdefined(team))
	{
		for(i = 0; i < players.size; i++)
		{
			if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
				players[i] playLocalSound(sound);
		}
	}
	else
	{
		for(i = 0; i < players.size; i++)
			players[i] playLocalSound(sound);
	}
}