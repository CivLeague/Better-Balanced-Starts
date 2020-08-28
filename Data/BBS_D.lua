------------------------------------------------------------------------------
--	FILE:	 BBS_D.lua
--	AUTHOR:  D. / Jack The Narrator
--	PURPOSE: Gameplay script - Rebalance the map for CPL requirements
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
ExposedMembers.LuaEvents = LuaEvents

include "MapEnums"


local bBiasFail = false; 



-- logs
-- v0.1 added Spectator Support
--	added Luxury type correction handling
-- v0.2 consider changing the terrain for non bias desert/tundra spawn when food deficit is too severe
-- v0.3 corrected line 2400 bug (=> VonHolio)
--	corrected French to Nubia bug (=> VonHolio)
--	added style support
-- v0.4 fix hills on floodplains
-- v0.5	do coastal terraforming to fix blocked water starts
-- v0.6 implemented the floodplains terraforming
-- v0.7	adjusted the terraforming involved in the Food / Prod function to avoid grassland jungles, ease reef placement in coastal
-- v0.8	fix the Oasis bug, checked resources validation (=> Wazabaza)
--	added version number (=> VonHolio)
--	commented the code a bit more to help readability (=> kilua)
-- v0.9	adjusted the luxury placement to ensure it is coming from the same continent (=> Wazabaza)
--	fixed a logical error that would lead to too many woods being placed during terrain changes
-- v0.91add a hills balancing (=> Deluxe Philippe)
-- 	floodplains on spawn "bug" (=> Deluxe Philippe)	
-- v0.92streamlined the code with a GetAdjacentTiles() function	
-- v0.93minor changes to Tundra / Snow treatment for more organic looking results
--	added notification to the player about the balancing
-- 	removed desert woods (=> Bisbis)
--	reworked reefs (=> Bisbis / Coloo)
-- v0.94rework coastal production (=> Bisbis / Coloo)
-- 	Nubia is now reconsidered a Desert Civ (=> kilua)
-- v0.95integrating the Bias Replacement
--	fix the coastal crazyness with reef
--	Ensure compatibility with Spectator Civs
--	Ensure random number are using Firaxis seed
-- v0.96Integrated an UI fix for player visions and hiding the old starts
--	Introduce Minimum Distance Slider
-- v0.97Corrected the spawn correction ( => VonHolio)
--	Fixed a Bug allowing Desert/Snow Mountains to be turned into grassland (=> Vonholio)
-- v0.98Fixing the Natural Wonders mountains (=> VonHolio)	
-- 	More balancing, tweaked reefs
-- v0.99Updated Kilua's scoring
--	Fixed a rare case of Tundra spawn for non tundra Civ 
--	Introduce Firaxis Fallback (a.k.a. No Settler Bug Ultimate Fix)
--	wip city state distance in hybrid palcement
--	Cleaned up GetValidAdjacent()
-- 	a	Removed Style, Distance, Ressources Sliders
--		Balanced the woods added
--		Added more failsafe to the reassign spawn segment
--		Reduce greatly the chances to spawn on an Oasis tile with Nubia
-- 	b	Added PBC / Hotseat support
--		Added re-lobby support
--		Added support for Difficulty Based Stand Alone Spectator mods (e.g. Sir Roger's)
--		Built a launch sequence for reloading (=> Eiffel, vonHolio)
--		Built an environement to save the Hidden Plots
--		Disabled by default the spawn reallocation to avoid glitches ( => Eiffel, Je, vonHolio)
--		Added some quality of life UI element (=> Sukrit)
--	c	Added the SQL edit for Minimum Distances (=> codenaught)
--		Added some quality of life UI element (=> Je, better to do standalone UI mod at one point)
--		Improved in Advanced Option interface (=> Je)
--	d	Changed the Natural wonder buffer to 2 (=>Vonholio)
--	e	Fixed a rare bug leaving a volcano near to a natural wonder (=> VonHolio)
--	f	Tweaked a bit more Minor placement & Natural wonder (=> VonHolio)
--		Tweaked the Strategic Resources balancing to avoid a rare case when a strategic resource would be granted then removed
--		Minor tweak on the default setting (slightly more rebalancing)
--	g	Narrow the MP settings to only 20% and hide the UI option (=> codenaught)
--		Fixed the non-Desert Mali on Floodplain situation
--		Introduce Polar Terraforming for extrem Tundra spawns
--		Allowed East / West Terraforming (not for Tilted_Axis maps)
--		best 2 tiles adjsutements	
--		Linked spawn Resources Settings with global resources settings
--		Reworked the reallocation to move it at map stage and implemented a failsafe for no settler bug
--		Add an UI signaling you have the relocation algorythm on
--	h	Minor Edit for Mountains start
--		increase the GetAdjacentTiles() to 90 tiles
--	i	Would not remove Volcano next to wonders (=> Je)
--	j	Consider resources in evaluation (=> Braizh)
--		Introduce a Hard minimum of 8 food for the start (=> Braizh)
--		Change the % balance back to 20% (=> eiffel)
--		Pushed Natural wonders for city state from 3 to 4 (=> VonHolio)
--	k	Changed Bias for Nubia to favour floodplains rather than simple desert (=> codenaught)
--		Changed Information message for minimum distance warning (=> codenaught)
--		Slightly extended CS distances (=> VonHolio)
--		Take into account Mali/Canada BBG adjustments for terrain (=> Braizh)
--		Change the minimum food to be a function of the resources setting 8=sparse (=>Braizh)
--	l 	Never spawn on a luxury (=> Jack)
--		Adjusted Mali slightly based on feedback (=> Jack, Eiffel, Braizh, Je)
--		Rework of prod/food add algo for better spacing and more diversity
--		Introduce forced remap in the very rares cases civs are too close (=> codenaught)
--		Now uses the old BBS desert/snow % instead of firaxis for firaxis script (=> codenaught)
--	m	Rare bug with March giving an extra production (=> Je) 
--		Never spawn on a luxury now working for real (=> Jack)
--		Better implementation of the BBS temperature settings (=> Waza)
--	n	Included codenaught's terrain settings (=> Codenaught)
--		Increase the ability to place a strategic resource to the 5th ring to reduce the chance of not getting it (=> VonHolio)
--	o	Reduced Fertility requirements for CS for better spacing
--		Introduced a progressive buffer for CS for better spacing
--		Hide Autoremap and defaulted it to 0 (=> codenaught)
--		Hide BBS temp and default it to 1 (=> codenaught)
--		Corrected a seed-dependent bug on larger map where CS placement would leave the algo in limbo and not delegate back to firaxis (=> VonHolio)
--	oo	Fix the wheat on Oasis (=> VonHolio)
--		Bumped floodplains tiers for Nubia (but would need a BBG fix here)
-- 	v1.0 Aka v9.1
--		removed Nubia references as Desert civ (=> codenaught)
--		Introduced hard minimum to minor minor of 5 to reducing clumping (=> codenaught)
-- 	1.01	Nubia doesn't get its floodplains reduced 
--		Slightly lowered the amount of sea in Pangaea map to reduce clumping
--		Reduced the required fertility for CS
--		Introduced low level biases for CS for better spacing
--	1.02	Guarantee Fresh Water for Major Civ even if Firaxis placement is incorrect (=> Slay)
--		Increase the minimum distance between CS, CS to Major in BBS placement
--		Introduce a new system removing CS if they are too close in BBS placement
--		Introduce a new system removing CS if they are too close in Firaxis placement 
--		Coastal Terraforming now take into account existing reef (=> We4x)
--		Remap warning message will stay on for a much longer duration (=> Eiffel)
--	1.03	Remove Nubia's file => moved to BBG
--		Added an sql dependency for people not owning the Viking DLC (=> DeluxePhilippe)
--	1.04	Added Error handler in the CS destroying loop
--		Oasis desert hill hard fix (=> waza)
--		No water fix coast -> lake (=> Jack)
--		More detailed reporting for debugging + code clean up
--		Remove some misleading notifications (=> code)
--	1.05	Reducing Tundra size a little bit
--		Small nerf to Russia and Canada (to make them have less food like Mali)
--		Now used locking on spawn using GetStartingPlot()
--		No-Water-spawn-fixing-lake would now avoid spawning if there is an unit in non-ancient start
--		BBS would not remove food to equalize production if their is a resources (to avoid non forest fur)
--		Slightly increase message display time
--		Desert should be on average less scattered but in total less desert tiles 
--	1.06	Beef up the oasis desert check and put debug to catch it if it happens again
--		Strenghten the no water fix condition
--	1.07	Added also the water-fix at the end of the code to ensure it is not blocked
-- 		Added an extra layer to Polar Terraforming to ensure the map doesn t look too odd
--		Reduced desert from 26% to 18%
--		Tweaked Mali's treatment to allow them to get larger deserts (but less resources)
--	1.08	Remove the max 12 players limit
--	1.09	Corrected a bug preventing BBS to correctly work with games containing open slots
--	1.10	Avoided walled-in starts
--			Mapuche no longer get skipped for mountain start (only Inca does)
--  	1.12		Balance strategic now does a continent wide check for Oil, Niter and Aluminium (to do coal)
--			Guarantee a best tile round if you are below average
--			Added an OP tiles check
--			Jack's no Plains Hills start if you are above 20% average in best tiles
--			Now consider food + prop on the second ring (25%)
--			Slightly less random Costal routine to help getting two resources for celestial boost
--			Fixed a typo that could lead to some CS spawning close to each other
--			Improve the lua.log output for debugging
--	1.13		Legendary starts can spawn close to wonder like in the original game
--			Fixed some missing text
--			Reduced the maximum reefs by 1
--			Introduced a Mountain chain option to add more passages in mountain ridges
--			Floodplains now have a proximity malus for non Egyptian players
--	1.14	Integrated the BBS options in MPH logics
--			Players should no longer spawn on the edge of the map in BBS placement
--			Added a Ridge Control
--	1.15		Added Iterative logic placement to BBS Placement
--			Cleaned map code
--			Remove lobby frontend control => MPH
--			Add Flat Earther BBS Ridge setting (Red Phoenix)
--			Added Regional Bias: Spain: Multi Continent
--			Added Regional Bias: Inca: Mountains
--			Added Regional Bias: Australia: Less Floodplains/jungle
--	1.16	Tundra Civs no longer have snow reduction in their region but only on their spawn
--			Reworked BBS placement algorithm to grant more spawns
--			Always do the Tundra/Desert proximity check when non Tundra/Desert Civ (used to be min 3 tiles)
--			Always do a Desert base adjustment if Mali has at least one desert tile in his spawn
--			Coastal bias is no longer dependent on the number of coastal tile
--			Structured a bit better the code on terraforming Tundra/Desert
--			Inca now gets more consistent spawn in terms of Mountains even if close to the coast.
--  1.17	Put 8jaaround Unix support for BBS
--			Fixed Ghost CS bug (hopefully)
--			Tightened the balancing
--  1.2		Restructure the code
--			Latitude of the spawn is better controlled
--			Scoring consider district (e.g. River, Moutnaints)
--			Minimum distance between CS depends on their type (3x as much if of the same type)
--			Less Terraforming
--			Added "Classic" a pre-GS ridge setting
--			When forced to terraform to add food BBS will also add prod e.g. Mountains -> Grassland + Stone instead of just Grassland
--			When adding food on plains now offer a Sheep + Plains combo instead of Grassland to avoid lossing production
--			No longer Remove extra food for Egypt on Floodplains (as it would fail to add production on Floodplains afterward)
-- 1.3		Support New Frontier Pass
--		Remove Flat Earth setting - redundant with large openings
--		Remove Polarstart as Civ should no longer spawn by the polar cap
--		Stone on non grassland should be fixed
--		Classic Ridge will now have Volcanos spawning as well
--		Brazil has a slight tilt toward Jungle continent
--		Added one more tile to the border to settle the 5 or 6 or 7 remap debate
-- 1.3.1		Maya spawn is no longer penalized if spawning next to > 1 luxuries
--			Maya spawn is no longer driven by Fresh Water, avoid Coast (still benefit from River)
--			Maya spawn is no longer receiving a lake if spawning without any Fresh water
-- 1.3.2  	Maya further tilt placement away from the coast -done
-- 		Tweak 1:3 best tile scoring to lowering in order to reflect that tiles might not be workable to allow growth - done
-- 		Best tiles only value more production if food > 1 on that tile - done
--		Minor adjustment in the % random chances of forest/hills when adjusting spawns - done
--		More severe Penalties for higher latidude spawns for non Tundra civs - done
--		Non coastal Civ would no longer spawn as often on peninsulas for non water map - done
--		Adapt the distance function for Niter - done Only needed for ancient start actually maximum strength of the function is about 7-8 range (c. 100 tiles)
-- 1.4		August patch 27 support
--		Ban spice & cocoa banned from the first ring and low probability on second ring under normal circumstances 
--		Mountains now counts a little bit toward food and prod min 
--		Detect biases (to allow non-BBG support for Russian community)
--		Bug fix for Volcanoes introduced by the NFP
--		Fixed an error on Egypt with floodplains
--		Fixed an error on Amber not scoring culture
--		Fixed an error whereby a civ would get overly compensated (getting a 2:3 instead of 2:2) while starting on Plains Hills
--		Culture and Faith tiles with no production are scored lower. So a 2f 1c is < 2f 2p for the algo
--		Tweaked the density of wood close to the Tundra/Grass/Plains limits (Not sure if NFP reduced the woods or if it was a consequence of Maize removing previously placed wood)
--		Tweaked the nerf on Russia now that mountains are counted ~= 0 for food and prod
--		Plain starts can no longer receive over 2 rounds of bonus resources when rebalancing a spawn for food.
--		Change slightly the best tiles scoring


-- Code structure: Code is run right before the first turn starts
--	Get settings (Strenght, Bias, and Style)
--	Get players
--	Run evaluation of each players' starting location
--	Run spawn correction (if needed) for Tundra/Desert/Floodplains/Coastal aka "Phase 0"
--	Re-evaluate spawn quality
--	Run strategic ressources rebalancing (fixed original Firaxis function) aka "Phase 1"
--	Re-evaluate spawn quality
--	Run food rebalancing (enhanced original Firaxis function) aka "Phase 2"
--	Re-evaluate spawn quality
--	Run production rebalancing (enhanced original Firaxis function) aka "Phase 3"
--	Run spawn correction Coastal (failsafe to prevent harbor blocked by reefs) 
--	Run Choke point analysis (prevent crashes)

g_version = "1.40"

-----------------------------------------------------------------------------
function __Debug(...)
    --print (...);
end
------------------------------------------------------------------------------
-- UI to Gameplay Script Storage -- Obsolete with the Map Injection
------------------------------------------------------------------------------




function Init_D_Balance()
	print ("---------------------------------------------------------");
	print ("------------- BBS Script v"..g_version.." -D- Init -------------");
	print ("---------------------------------------------------------");
	if (Game:GetProperty("BBS_INIT_COUNT") == nil) then
		Game:SetProperty("BBS_INIT_COUNT",1)
		else
		Game:SetProperty("BBS_INIT_COUNT",Game:GetProperty("BBS_INIT_COUNT")+1)
	end
	if ( Game:GetProperty("BBS_INIT_COUNT") ) > 1 then
		print ("Init: ", Game:GetProperty("BBS_INIT_COUNT")," times. Turn: ", Game.GetCurrentGameTurn())
	end
	
end

--LuaEvents.UIOnLocalPlayerHidePlotsEvent.Add( OnLocalPlayerHidePlots )
--LuaEvents.UIOnLocalPlayerRevealPlotsEvent.Add( OnLocalPlayerRevealPlots )
--LuaEvents.UIOnLocalPlayerTotalRevealPlotsEvent.Add( OnLocalPlayerTotalRevealPlots )
--LuaEvents.UIOnLocalPlayerTotalHidePlotsEvent.Add( OnLocalPlayerTotalHidePlots )
--LuaEvents.UIOnLocalPlayerRevealSpawnEvent.Add ( OnLocalPlayerRevealSpawn );


Init_D_Balance();
