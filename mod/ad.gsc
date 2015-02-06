precache()
{
	game["hud_ad_0"] = &"Visit http://killtube.org To Join The Clan!";
	game["hud_ad_1"] = &"Visit http://killtube.org To Join The Clan!";
	
	precacheString(game["hud_ad_0"]);
	precacheString(game["hud_ad_1"]);
}

ad()
{
	hud_ad = newHudElem();
	hud_ad.horzAlign = "fullscreen";
	hud_ad.vertAlign = "fullscreen";
	hud_ad.alignX = "center";
	hud_ad.alignY = "top";
	hud_ad.x = 320;
	hud_ad.y = 380;
	hud_ad.alpha = 0;
	hud_ad.color = (0.8,0.8,0.8);

	wait 10;

	while (1)
	{
		hud_ad.fontscale = 1.2;
	
		hud_ad fadeOverTime(1);
		hud_ad.alpha = 1;
		hud_ad.label = game["hud_ad_0"];
		wait 10;
		hud_ad fadeOverTime(1);
		hud_ad.alpha = 0;
		
		wait 20;
		
		// #####
		// #####
		
		hud_ad.fontscale = 1.6;
		
		hud_ad fadeOverTime(1);
		hud_ad.alpha = 1;
		hud_ad.label = game["hud_ad_1"];
		wait 10;
		hud_ad fadeOverTime(1);
		hud_ad.alpha = 0;
		
		wait 20;
	}
}