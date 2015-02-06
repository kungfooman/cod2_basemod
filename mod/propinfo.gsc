precache()
{
	level.propStats = [];


	level.propStats["PropStats"] = &"~^1~^7~ ^1M^7ax-^1P^7rops ~^1~^7~";
	level.propStats["PropCount"] = &"^1P^7rops: ";
	level.propStats["PropCountSlash"] = &"^1/^7 ";
	level.propStats["PropsAxis"] = &"^1P^7rops-^1A^7xis: ";
	level.propStats["PropsAllies"] = &"^1P^7rops-^1A^7llies: ";
	level.propStats["PropsUnknown"] = &"^7?^1?^7?";

	level.propStats["PropInfo"] = &"~^1~^7~ ^1P^7rop-^1I^7nfo ~^1~^7~ ";
	level.propStats["PropId"] = &"^1P^7rop-^1I^7D: ";
	level.propStats["PropOwner"] = &"^1O^7wner: ";
	level.propStats["PropOwnerNobody"] = &"^1N^7obody";

	precacheString(level.propStats["PropStats"]);
	precacheString(level.propStats["PropCount"]);
	precacheString(level.propStats["PropCountSlash"]);
	precacheString(level.propStats["PropsAxis"]);
	precacheString(level.propStats["PropsAllies"]);
	precacheString(level.propStats["PropsUnknown"]);

	precacheString(level.propStats["PropInfo"]);
	precacheString(level.propStats["PropId"]);
	precacheString(level.propStats["PropOwner"]);
	precacheString(level.propStats["PropOwnerNobody"]);
}


onPlayerConnect()
{
	player = self;

	
	// ~~~ Level-Info ~~~
	player.PropStats = NewClientHudElem(player);
	player.PropStats.x = 550;
	player.PropStats.y = 100;
	player.PropStats.label = level.propStats["PropStats"];
	
	
	// Props: $current 
	player.PropCount = NewClientHudElem(player);
	player.PropCount.x = 550;
	player.PropCount.y = 115;
	player.PropCount.label = level.propStats["PropCount"];
	player.PropCount setText(level.propStats["PropsUnknown"]);
	
	//                    / $max
	player.PropCountSlash = NewClientHudElem(player);
	player.PropCountSlash.x = 550 + 50;
	player.PropCountSlash.y = 115;
	player.PropCountSlash.label = level.propStats["PropCountSlash"];
	player.PropCountSlash setText(level.propStats["PropsUnknown"]);
	

}


onPlayerSpawn()
{
}

updateCurrentPropsMaxProps()
{
	player = self;
	
	player.PropCount setValue(player.props);
	player.PropCountSlash setValue(mod\prop::getMaxProps(player.pers["team"]));

	/*
	PropsAxis = NewClientHudElem(player);
	PropsAxis.x = 550;
	PropsAxis.y = 130;
	PropsAxis.label = player.propStats["PropsAxis"];
	PropsAxis setValue(getEntArray("axis", "targetname").size);

	PropsAllies = NewClientHudElem(player);
	PropsAllies.x = 550;
	PropsAllies.y = 145;
	PropsAllies.label = player.propStats["PropsAllies"];
	PropsAllies setValue(getEntArray("allies", "targetname").size);
	*/
}

onTrace(trace)
{
	player = self;

	
	deltaY = -100;
	
	// ~~~ Prop-Info ~~~
	if (!isDefined(player.PropInfo))
	{
		player.PropInfo = NewClientHudElem(player);
		player.PropInfo.x = 550;
		player.PropInfo.y = 240 + deltaY;
		player.PropInfo.label = level.propStats["PropInfo"];
	}
	
	// Prop-ID: $entityNumber
	if (!isDefined(player.PropId))
	{
		player.PropId = NewClientHudElem(player);
		player.PropId.x = 550;
		player.PropId.y = 255 + deltaY;
		player.PropId.label = level.propStats["PropId"];
	}
	
	// Owner: $name
	if (!isDefined(player.PropOwner))
	{
		player.PropOwner = NewClientHudElem(player);
		player.PropOwner.x = 550;
		player.PropOwner.y = 270 + deltaY;
		player.PropOwner.label = level.propStats["PropOwner"];
	}

	prop = trace["entity"];

	if (isDefined(prop) && prop mod\prop::isProp())
	{
		player.PropInfo.alpha = 1;
		player.PropId.alpha = 1;
		player.PropOwner.alpha = 1;

		// prop-info
		player.PropId setValue(prop getEntityNumber());
		if (isDefined(prop.owner))
		{
			player.PropOwner setPlayerNameString(prop.owner);
			//PropOwner.font = "default";
			player.PropOwner.alpha = 1;
			
		} else {
			player.PropOwner setText(level.propStats["PropOwnerNobody"]);
			//PropOwner.font = "smallfixed";
			player.PropOwner.alpha = 0.5;
		}
	} else {
		player.PropInfo.alpha = 0;
		player.PropId.alpha = 0;
		player.PropOwner.alpha = 0;
	}
}