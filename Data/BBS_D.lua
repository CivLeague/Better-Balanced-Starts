------------------------------------------------------------------------------
--	FILE:	 BBS_D.lua
--	AUTHOR:  D. / Jack The Narrator
--	PURPOSE: Gameplay script - Rebalance the map for CPL requirements
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
ExposedMembers.LuaEvents = LuaEvents

include "MapEnums"
include "MapUtilities"
include "MountainsCliffs"
include "RiversLakes"
include "FeatureGenerator"
include "TerrainGenerator"
include "NaturalWonderGenerator"
include "ResourceGenerator"

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
--	todo	Goodys Hut style
-- 	
-- todo	test it like Hell to ensure it is bug free
--
--
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
-----------------------------------------------------------------------------------------------------------------------------------

function BBS_Script()
	print ("Initialization", os.date("%c"))
	
	local currentTurn = Game.GetCurrentGameTurn();
	eContinents	= {};



	if currentTurn == GameConfiguration.GetStartTurn() then
		print ("Init: Map Seed", MapConfiguration.GetValue("RANDOM_SEED"));
		print ("Init: Game Seed", GameConfiguration.GetValue("GAME_SYNC_RANDOM_SEED"));
		print ("Init: Number of Players", PlayerManager.GetAliveMajorsCount());
		print ("Init: Number of City-States", PlayerManager.GetAliveMinorsCount());
		local mapName = MapConfiguration.GetValue("ReferenceMap") or MapConfiguration.GetValue("MapName")
		print ("Init: Loading "..tostring(mapName).." script");
		local startTemp = MapConfiguration.GetValue("temperature")
		local mapSize = Map.GetMapSize();
		local sea_level = MapConfiguration.GetValue("sea_level")
		local rainfall = MapConfiguration.GetValue("rainfall");
		local world_age = MapConfiguration.GetValue("world_age");
		print ("Init: Map Size: ", mapSize, "2 = Small, 5 = Huge");
		print ("Init: Climate: ", startTemp, "1 = Hot, 2 = Standard, 3 = Cold");
		local BBS_temp = false;
		if (GameConfiguration.GetValue("BBStemp") ~= nil) then 
			if (GameConfiguration.GetValue("BBStemp") == true) then
				BBS_temp = true;
				print ("Init: BBS Temperature: On");
				else
				BBS_temp = false;
				print ("Init: BBS Temperature: Off")
			end
			else
			BBS_temp = false;
			print ("Init: BBS Temperature: Off")
		end
		print ("Init: Rainfall: ", rainfall, "1 = Dry, 2 = Standard, 3 = Humid");
		print ("Init: World Age: ", world_age, "1 = New, 2 = Standard 3 = Old");
		print ("Init: Sea Level: ", sea_level, "1 = Low Sea Level, 2 = Standard, 3 = High Sea Level");
		local resourcesConfig = MapConfiguration.GetValue("resources");
		print ("Init: Resources: ", resourcesConfig, "1 = Sparse, 2 = Standard, 3 = Abundant");
		local startConfig = MapConfiguration.GetValue("start")
		print ("Init: Spawntype: ", startConfig, "1 = Standard, 2 = Balanced, 3 = Legendary");

		local iBalancingOne = 2;
		local iBalancingTwo = -1;
		local iBalancingThree = -1;
		local force_remap = true;
		local majList = {}
		local tempEval = {}
		local minFood = 7;
		local avgFood = 0;
		local maxFood = 0;
		local avgProd = 0;
		local maxProd = 0;
		local avgHill = 0;
		local dispersion = 1;
		local dispersion_2 = 0.1;
		local count = 0;	
		-------------------------------------------------------------------------------------
		-- Settings: 	
		--
		-- Strength: 	Controls how far away rom the average a spawn needs to be before getting rebalanced 
		--		(default = 1 / 33%) Note the balancing is slightly skewed (i.e. positive outliers
		--		are less rebalanced, focus is on negative outliers)
		--
		-- Bias: 	Controls how much additional food and production is added to the "average spawn"
		--		(default = 1 / +1 food +2 production) 
		--		As classic BBS corrects negative spawns it lift the average Civilization spawn
		--		quality (i.e. classic BBS spawns are on average better than standard Civ6
		--		spawn) 1 feels like original BBS. Setting it to 0
		--		would pass-through standard Civ 6
		--
		-- Style: 	Controls how Tundra/Desert starts are treated with no, light or heavy Terrain changes 
		--		(default = 1 / 20%) aim to natural balance tundra start warming up the climate
		--		(snow -> tundra -> plains -> grasslands -> plains -> desert)
		--		0 would return to original Civ 6 meaning Tudnra start for non-tundra civ
		--		can only be adjusted with deers / forest / salt resulting in a sub par balancing
		--		2 would favor pushing more toward tundra -> grasslands than tundra -> plains
		--
		-- Distance:	Controls how CIV are far from other CIVs, Natural Wonders, 0 is Civ6 Original
		--
		-------------------------------------------------------------------------------------

		--if (GameConfiguration.GetValue("BalancingTypeOne") and GameConfiguration.GetValue("BalancingTypeOne") ~= nil) then 
		--	iBalancingOne = GameConfiguration.GetValue("BalancingTypeOne");
		--end
		if (GameConfiguration.GetValue("AutoRemap") ~= nil) then 
			if (GameConfiguration.GetValue("AutoRemap") == true) then
				force_remap = true;
				print ("Init: Forced Remap: On");
				else
				force_remap = false;
			end
			else
			force_remap = false;
		end
		if (resourcesConfig ~= 4) then
			iBalancingTwo = math.min (resourcesConfig - 1.5,0);
			minFood = minFood + resourcesConfig;
			else
			minFood = 9;
		end
		if (startConfig == 3) then
			iBalancingTwo = iBalancingTwo + 3;
		end

		if (Game:GetProperty("BBS_RESPAWN") ~= nil) then 
			if (Game:GetProperty("BBS_RESPAWN") == false) then
				bBiasFail = true; 
				else
				bBiasFail = false; 
			end
			else
			bBiasFail = true; 
		end
		
		--
		--if (GameConfiguration.GetValue("BalancingTypeThree") and GameConfiguration.GetValue("BalancingTypeThree") ~= nil) then 
		--	iBalancingThree = GameConfiguration.GetValue("BalancingTypeThree");
		--end
		iBalancingThree = 1; -- Always tries to reallocate to better spawn if possible and apply limited terraforming if needed
		
		--if (GameConfiguration.GetValue("BalancingTypeFour") and GameConfiguration.GetValue("BalancingTypeFour") ~= nil) then 
		--	iBalancingFour = GameConfiguration.GetValue("BalancingTypeFour");
		--end
		iBalancingFour = 0;

		print ("D TURN STARTING: Initialisation:");
		print ("Init: ", Game:GetProperty("BBS_INIT_COUNT")," time.")
		print ("Init: Global Parameters: Natural Wonder Buffer:", GlobalParameters.START_DISTANCE_MAJOR_NATURAL_WONDER)
		print ("Init: Global Parameters: City-State Buffer:", GlobalParameters.START_DISTANCE_MINOR_MAJOR_CIVILIZATION)
		print ("Init: Global Parameters: Major Civs Buffer:", GlobalParameters.START_DISTANCE_MAJOR_CIVILIZATION - GlobalParameters.START_DISTANCE_RANGE_MAJOR)

		-------------------------------------------------------------------------------------
		-- Settings: Importing BBS Settings
		-------------------------------------------------------------------------------------
		if (iBalancingOne == 1) then
			dispersion = 0.33;
			elseif (iBalancingOne == 2) then
			dispersion = 0.25;
			elseif (iBalancingOne == 3) then
			dispersion = 0.10;
		end

		dispersion = 0.20;


		-------------------------------------------------------------------------------------
		-- Settings: Importing Map Variables
		-------------------------------------------------------------------------------------

		-- Firaxis Defaults from SetDefaultAssignedStartingPlots.lua
		local bTerraformingSpawn = true;

   		--Find Default Number
    		local MapSizeTypes = {};
    		for row in GameInfo.Maps() do
       			MapSizeTypes[row.RowId] = row.DefaultPlayers;
    		end
    		local sizekey = Map.GetMapSize() + 1;
    		local iDefaultNumberPlayers = MapSizeTypes[sizekey] or 8;
    		iDefaultNumberMajor = iDefaultNumberPlayers ;
    		iDefaultNumberMinor = math.floor(iDefaultNumberPlayers * 1.5);
		

		-------------------------------------------------------------------------------------
		-- Settings: Importing Player Variables
		-------------------------------------------------------------------------------------
		local iNumMajCivs = 0;
		local iNumMinCivs = 0;
		tempMajorList = PlayerManager.GetAliveMajorIDs();
		iNumMajCivs = PlayerManager.GetAliveMajorsCount();

		-- Check for Minor placement failure

		if (Game:GetProperty("BBS_MINOR_FAILING_TOTAL") ~= nil) then
			-- BBS placement true
			if (Game:GetProperty("BBS_MINOR_FAILING_TOTAL") > 0) then
				__Debug("Minor failure module:",Game:GetProperty("BBS_MINOR_FAILING_TOTAL")," Minor Civs are failing.")
				for j = 1, Game:GetProperty("BBS_MINOR_FAILING_TOTAL") do
					if (Game:GetProperty("BBS_MINOR_FAILING_ID_"..j) ~= nil) then
						local playerUnits;
						playerUnits = Players[Game:GetProperty("BBS_MINOR_FAILING_ID_"..j)]:GetUnits();
						for k, unit in playerUnits:Members() do
							playerUnits:Destroy(unit)			
						end
						__Debug("Minor failure module: Minor Player", Game:GetProperty("BBS_MINOR_FAILING_ID_"..j)," has been eliminated.")
					end
				end
				else
				__Debug("Minor failure module: All Minor Civs have been placed.")
			end
			else
			-- Firaxis placement true
			__Debug("Minor failure module: Firaxis placement only check if minimum distance are met")
		end


		-- Check Distances if Firaxis Placement Algo has been used
		local bError_proximity = false;

		if bBiasFail == true then
		for i = 0, PlayerManager.GetAliveMajorsCount() - 1 do
			if (PlayerConfigurations[i]:GetLeaderTypeName() ~= "LEADER_SPECTATOR" and PlayerConfigurations[i]:GetHandicapTypeID() ~= 2021024770 and PlayerConfigurations[i]:GetLeaderTypeName() ~= "LEADER_KUPE") then
				local pStartPlot_i = Players[i]:GetStartingPlot()
				for j = 0, PlayerManager.GetAliveMajorsCount() + PlayerManager.GetAliveMinorsCount() - 1 do
					if (PlayerConfigurations[j]:GetLeaderTypeName() ~= "LEADER_SPECTATOR" and PlayerConfigurations[j]:GetHandicapTypeID() ~= 2021024770 and PlayerConfigurations[j]:GetLeaderTypeName() ~= "LEADER_KUPE" and i ~= j) then
						local pStartPlot_j = Players[j]:GetStartingPlot()
						local distance = Map.GetPlotDistance(pStartPlot_i:GetIndex(),pStartPlot_j:GetIndex())
						__Debug("I:", i,"J:", j,"Distance:",distance)
						if (distance < 6 or (distance < 9 and j < PlayerManager.GetAliveMajorsCount())) then
							print ("Init: Minimum CPL distance rule breached");
							if (Game:GetProperty("BBS_MINOR_FAILING_TOTAL") == nil) then
								Game:SetProperty("BBS_MINOR_FAILING_TOTAL",0)
							end
							if ( j < PlayerManager.GetAliveMajorsCount() ) then
								bError_proximity = true;
								Game:SetProperty("BBS_DISTANCE_ERROR","Two Players are only "..distance.." tiles away from each other and allowed to remap as per CPL rules.")
								else
								-- Let's kill a CS to ensure the game is within CPL rules
								local playerUnits;
								playerUnits = Players[j]:GetUnits();
								for k, unit in playerUnits:Members() do
									playerUnits:Destroy(unit)			
								end
								__Debug("Minor failure module: Firaxis Placement: Minor Player", j," has been eliminated (too close to major).")
								Game:SetProperty("BBS_MINOR_FAILING_ID_"..j,j)
								Game:SetProperty("BBS_MINOR_FAILING_TOTAL",Game:GetProperty("BBS_MINOR_FAILING_TOTAL")+1)
							end
						end
					end
				end
			end
		end
		-- Minor Minor
		for i = PlayerManager.GetAliveMajorsCount(),  PlayerManager.GetAliveMajorsCount() + PlayerManager.GetAliveMinorsCount() - 1 do
			local pStartPlot_i = Players[i]:GetStartingPlot()
			for j = PlayerManager.GetAliveMajorsCount(),  PlayerManager.GetAliveMajorsCount() + PlayerManager.GetAliveMinorsCount() - 1 do
				local pStartPlot_j = Players[j]:GetStartingPlot()
				if (i ~= j and Game:GetProperty("BBS_MINOR_FAILING_ID_"..i) == nil and Game:GetProperty("BBS_MINOR_FAILING_ID_"..j) == nil) then
					local distance = Map.GetPlotDistance(pStartPlot_i:GetIndex(),pStartPlot_j:GetIndex())
					__Debug("I:", i,"J:", j,"Distance:",distance)
					if (distance < 7 ) then
						if (Game:GetProperty("BBS_MINOR_FAILING_TOTAL") == nil) then
							Game:SetProperty("BBS_MINOR_FAILING_TOTAL",0)
						end
						-- Let's kill a CS to avoid a CS settler roaming and breaking CPL rules
						local playerUnits;
						playerUnits = Players[j]:GetUnits();
						for k, unit in playerUnits:Members() do
							playerUnits:Destroy(unit)			
						end
						__Debug("Minor failure module: Firaxis Placement: Minor Player", j," has been eliminated (too close to minor).")
						Game:SetProperty("BBS_MINOR_FAILING_ID_"..j,j)
						Game:SetProperty("BBS_MINOR_FAILING_TOTAL",Game:GetProperty("BBS_MINOR_FAILING_TOTAL")+1)
					end
				end	
			end
		end
		end
		
		

		-- Kills everyone and force remap if needed
		local iNumMajCivs = 0;
		tempMajorList = PlayerManager.GetAliveMajorIDs();
		iNumMajCivs = PlayerManager.GetAliveMajorsCount();


		if (force_remap == true and bError_proximity == true) then
			print ("Init: Defeat all players");
			for i = 0, iNumMajCivs -1 do
				local pPlayer = Players[i]
				local playerUnits;
				local startPlot;
				playerUnits = pPlayer:GetUnits()

				for j, unit in playerUnits:Members() do
					playerUnits:Destroy(unit)			
				end
			end
			Game:SetProperty("BBS_DISTANCE_ERROR","Minimum distances between civilizations could not be met. You must remap as per CPL rules.");
			print ("Init: Exit");
			return
		end
		

		print ("Initialization - Completed", os.date("%c"))


		--------------------------------------------------------------------------------------
		-- Terrain Balancing - Init
		--------------------------------------------------------------------------------------		

		for i = 0, iNumMajCivs -1 do
			local sPlayerLeaderName = PlayerConfigurations[i]:GetLeaderTypeName()
			local sPlayerCivName = PlayerConfigurations[i]:GetCivilizationTypeName()
			local pPlayer = Players[i]
			local playerUnits;
			local startPlot;
			playerUnits = pPlayer:GetUnits()

			for j, unit in playerUnits:Members() do
				local unitTypeName = UnitManager.GetTypeName(unit)
				if "LOC_UNIT_SETTLER_NAME" == unitTypeName then
					SpawnTurn = 1;
					startPlot = Map.GetPlot(unit:GetX(), unit:GetY());
					if (startPlot ~= nil) then
						tempEval = EvaluateStartingLocation(startPlot)
						
					------------------------------------------------------------------------------------------------------------		
					-- Create the master major table assigning the data from the EvaluateStartingLocation function
					--	Then majList[i] object is used for the rest of the code to store each players information for balancing
					------------------------------------------------------------------------------------------------------------
					-- EvalType = {impassable,water,snow,desert, food_spawn_start, prod_spawn_start, culture_spawn_start, faith_spawn_start, impassable_start,water_start,snow_start,desert_start,impassable_inner,water_inner,snow_inner,desert_inner,impassable_outer,water_outer,snow_outer,desert_outer,flood,hill_start,hill_inner,best_tile,second_best_tile}
					----------------------------------------------------------------------------------------------
						majList[i] = {leader = sPlayerLeaderName, civ = sPlayerCivName, plotX = startPlot:GetX(), plotY = startPlot:GetY(), food_spawn_start = tempEval[5], prod_spawn_start = tempEval[6], culture_spawn_start = tempEval[7], faith_spawn_start = tempEval[8], impassable_start = tempEval[9],water_start = tempEval[10],snow_start = tempEval[11],desert_start = tempEval[12],impassable_inner = tempEval[13],water_inner = tempEval[14],snow_inner = tempEval[15],desert_inner = tempEval[16],impassable_outer = tempEval[17],water_outer = tempEval[18],snow_outer = tempEval[19],desert_outer = tempEval[20],flood = tempEval[21],hill_start = tempEval[22],hill_inner = tempEval[23],prod_adjust=tempEval[6],food_adjust=tempEval[5],best_tile = tempEval[24], best_tile_2 = tempEval[25]} 
						__Debug("Major Start X: ", majList[i].plotX, "Major Start Y: ", majList[i].plotY, "Player: ",i," ",majList[i].leader, majList[i].civ);
					end
							
				end
			end
		end

		--------------------------------------------------------------------------------------	
		-- Terraforming
		--------------------------------------------------------------------------------------

		__Debug("Terraforming Starts")

		-- Fix lack of freshwater

		for i = 0, iNumMajCivs -1 do
			-- Added Spectator mod handling if a major player isn't detected
			if (majList[i] ~= nil) then
				if(majList[i].leader ~= "LEADER_SPECTATOR" and PlayerConfigurations[i]:GetHandicapTypeID() ~= 2021024770) then
				-- Check for freshwater
					local wplot = Map.GetPlot(majList[i].plotX,majList[i].plotY)
					if (wplot:IsCoastalLand() == false and wplot:IsWater() == false and  wplot:IsRiver() == false and wplot:IsFreshWater() == false) then
					-- Fix No Water
						__Debug("Water Terraforming Start X: ", majList[i].plotX, "Start Y: ", majList[i].plotY, "Player: ",i," ",majList[i].leader, majList[i].civ);
						Terraforming_Water(Map.GetPlot(majList[i].plotX,majList[i].plotY));
					end
				end
			end
		end


		-- Look at Floodplains and remove the excess in the starting circle to allow the balancing to work properly

		for i = 0, iNumMajCivs -1 do
			-- Added Spectator mod handling if a major player isn't detected
			if (majList[i] ~= nil) then
				if(majList[i].leader ~= "LEADER_SPECTATOR" and PlayerConfigurations[i]:GetHandicapTypeID() ~= 2021024770) then
				-- Do not reduce floodplain for Egypt or Desert Civ with Desert Floodplains
				if ((majList[i].flood > 4) and majList[i].civ ~= "CIVILIZATION_EGYPT" and majList[i].civ ~= "CIVILIZATION_MALI" and (majList[i].civ == "CIVILIZATION_MALI" and majList[i].desert_start <2)) then
					-- Check for Floodplains Start
					__Debug("Floodplains Terraforming Start X: ", majList[i].plotX, "Start Y: ", majList[i].plotY, "Player: ",i," ",majList[i].leader, majList[i].civ);
					Terraforming_Flood(Map.GetPlot(majList[i].plotX,majList[i].plotY), iBalancingThree);
				end
				end
			end
		end

		-- Fix an error where Civ could spawn on a Luxury

		for i = 0, iNumMajCivs -1 do
			-- Added Spectator mod handling if a major player isn't detected
			if (majList[i] ~= nil) then
				if(majList[i].leader ~= "LEADER_SPECTATOR" and PlayerConfigurations[i]:GetHandicapTypeID() ~= 2021024770) then
					local start_plot = Map.GetPlot(majList[i].plotX,majList[i].plotY);
					if (start_plot ~= nil) then
						if (start_plot:GetResourceCount() > 0) then
							ResourceBuilder.SetResourceType(start_plot, -1);	
						end
					end
				end
			end
		end

		-- Check the style option selected by the player, default = 1

		if (bTerraformingSpawn == true) then

			-- Cycle through Civs to find the ones with odd starts

			for i = 0, iNumMajCivs -1 do
				-- Added Spectator mod handling if a major player isn't detected
				if (majList[i] ~= nil) then
					if(majList[i].leader ~= "LEADER_SPECTATOR" and PlayerConfigurations[i]:GetHandicapTypeID() ~= 2021024770) then
					-- Check for Tundra Starts
					if ( ( ( (majList[i].snow_start + majList[i].snow_inner + majList[i].snow_outer) > 12 or ( (majList[i].snow_start + majList[i].snow_inner + majList[i].snow_outer) > 6 and (majList[i].water_start + majList[i].water_inner + majList[i].water_outer) > 6 ) ) ) and ( (majList[i].civ ~= "CIVILIZATION_CANADA") and (majList[i].civ ~= "CIVILIZATION_RUSSIA") ) ) then
						__Debug("Terraforming Polar Start X: ", majList[i].plotX, "Start Y: ", majList[i].plotY, "Player: ",i," ",majList[i].leader, majList[i].civ);
						Terraforming_Polar_Start(Map.GetPlot(majList[i].plotX,majList[i].plotY));
						elseif( ( (majList[i].snow_start + majList[i].snow_inner + majList[i].snow_outer + majList[i].desert_start + majList[i].desert_inner + majList[i].desert_outer) > 3) and ( (majList[i].civ ~= "CIVILIZATION_CANADA") and (majList[i].civ ~= "CIVILIZATION_RUSSIA") and (majList[i].civ ~= "CIVILIZATION_MALI") ) )then
						__Debug("Terraforming Start X: ", majList[i].plotX, "Start Y: ", majList[i].plotY, "Player: ",i," ",majList[i].leader, majList[i].civ);
						Terraforming(Map.GetPlot(majList[i].plotX,majList[i].plotY), iBalancingThree,0);
						elseif( ( (majList[i].snow_start + majList[i].snow_inner + majList[i].snow_outer) > 0) and (majList[i].civ == "CIVILIZATION_MALI") ) then
						__Debug("Terraforming Start X: ", majList[i].plotX, "Start Y: ", majList[i].plotY, "Player: ",i," ",majList[i].leader, majList[i].civ);
						Terraforming(Map.GetPlot(majList[i].plotX,majList[i].plotY), iBalancingThree,2);
						elseif( ( (majList[i].civ == "CIVILIZATION_CANADA" or majList[i].civ == "CIVILIZATION_RUSSIA") ) ) then
						__Debug("Terraforming Start X: ", majList[i].plotX, "Start Y: ", majList[i].plotY, "Player: ",i," ",majList[i].leader, majList[i].civ);
						Terraforming(Map.GetPlot(majList[i].plotX,majList[i].plotY), iBalancingThree,1);
					end
					end
				end
			end



			else


			__Debug("Terraforming: Terrain Update Not Required (Use Original Civ 6 Map)");
		end

		-- Fix improper reef and ice placement in coastal start
		for i = 0, iNumMajCivs -1 do
			-- Added Spectator mod handling if a major player isn't detected
			if (majList[i] ~= nil) then
				if(majList[i].leader ~= "LEADER_SPECTATOR" and PlayerConfigurations[i]:GetHandicapTypeID() ~= 2021024770) then
				if (Map.GetPlot(majList[i].plotX,majList[i].plotY):IsCoastalLand() == true) then
					-- Check for Coastal Start
					__Debug("Coastal Terraforming Start X: ", majList[i].plotX, "Start Y: ", majList[i].plotY, "Player: ",i," ",majList[i].leader, majList[i].civ);
					Terraforming_Coastal(Map.GetPlot(majList[i].plotX,majList[i].plotY), iBalancingThree, false)
				end
				end
			end
		end

		-- Fix Natural Wonders mountains problem

		for iPlotIndex = 0, Map.GetPlotCount()-1 do
			local natPlot = Map.GetPlotByIndex(iPlotIndex)
			if (natPlot ~= nil) then
				if (natPlot:IsNaturalWonder() == true and natPlot:GetFeatureType() ~= 29) then
					for i = 0, 5 do
						local adjacentPlot = GetAdjacentTiles(natPlot, i);
						if (adjacentPlot ~= nil) then
							if (adjacentPlot:IsImpassable() == true and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO and adjacentPlot:IsNaturalWonder() == false) then
								TerrainBuilder.SetTerrainType(adjacentPlot,adjacentPlot:GetTerrainType()-1);
								if ( adjacentPlot:GetFeatureType() == g_FEATURE_VOLCANO) then
									TerrainBuilder.SetFeatureType(adjacentPlot,-1);
								end	
							end
						end
					end
				end
			end
		end

		-- Fix extreme Mountains Start
		for i = 0, iNumMajCivs -1 do
			-- Added Spectator mod handling if a major player isn't detected
			if (majList[i] ~= nil) then
				if(majList[i].leader ~= "LEADER_SPECTATOR" and PlayerConfigurations[i]:GetHandicapTypeID() ~= 2021024770 and majList[i].leader ~= "LEADER_LAUTARO" and majList[i].leader ~= "LEADER_PACHACUTI") then
				if ( ( (majList[i].impassable_start + majList[i].impassable_inner + majList[i].impassable_outer) >= 12) or ((majList[i].impassable_start + majList[i].impassable_inner + majList[i].impassable_outer) >= 8 and (majList[i].water_start + majList[i].water_inner + majList[i].water_outer) >= 4 ) ) then
					-- Check for Mountain Start
					__Debug("Mountain Terraforming Start X: ", majList[i].plotX, "Start Y: ", majList[i].plotY, "Player: ",i," ",majList[i].leader, majList[i].civ);
					Terraforming_Mountain(Map.GetPlot(majList[i].plotX,majList[i].plotY))

				end
				end
			end
		end




		__Debug("Terraforming: Completed")
		print ("Terraforming - Completed", os.date("%c"))

		---------------------------------------------------------------------------------------------------------------
		-- Starting the resources rebalancing in 3 phases: Strategic, Food and Production
		---------------------------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------------------------
		-- Phase 1: Strategic Resource Balancing / Original Firaxis Code from AddBalancedResources() reworked
		---------------------------------------------------------------------------------------------------------------

		__Debug("Phase 1: Strategic Resource Balancing")

		for i = 0, iNumMajCivs -1 do
		-- Added Spectator mod handling if a major player isn't detected
			if (majList[i] ~= nil) then
				if(majList[i].leader ~= "LEADER_SPECTATOR" and PlayerConfigurations[i]:GetHandicapTypeID() ~= 2021024770) then
				if (Map.GetPlot(majList[i].plotX,majList[i].plotY):IsWater() == false) then
					BalanceStrategic(Map.GetPlot(majList[i].plotX,majList[i].plotY))
				end
				end
			end
		end
		
		-- Phase 1 Completed
		print ("Strategic Resouce Balancing - Completed", os.date("%c"))
		
		---------------------------------------------------------------------------------------------------------------
		-- Phase 2: Food Resource Balancing / Original Fertility function Code from AddBalancedResources() reworked
		---------------------------------------------------------------------------------------------------------------
		local bStrategic_only = false
		if (bStrategic_only == true) then
			print("Debut Mode: Only Do Strategic Resources Rebalancing")
		end

		-- Check for Food in the starting area of each Major Civ
		if (bStrategic_only == false) then

		for i = 0, iNumMajCivs -1 do
			local temp = 0;
			count = 0;
			if (majList[i] == nil or majList[i].leader == "LEADER_SPECTATOR" and PlayerConfigurations[i]:GetHandicapTypeID() ~= 2021024770) then

				count = count + 1
				else
				startPlot = Map.GetPlot(majList[i].plotX, majList[i].plotY);
				tempEval = EvaluateStartingLocation(startPlot)
				majList[i].food_spawn_start = tempEval[5];
				majList[i].prod_spawn_start = tempEval[6];
				if (majList[i].civ == "CIVILIZATION_MALI" ) then
					majList[i].food_spawn_start = majList[i].food_spawn_start + tempEval[12] * 1.5
					elseif (majList[i].civ == "CIVILIZATION_CANADA" ) then
					majList[i].food_spawn_start = majList[i].food_spawn_start + tempEval[11] * 1.25
				end
				temp = majList[i].food_spawn_start;

				if (temp > maxFood) then
					maxFood = temp;
				end

				avgFood = avgFood + temp;
		
			end

		end
		
		if (count > 0) then
			__Debug(count , "Spectators detected.")
		end

		avgFood = avgFood / (iNumMajCivs - count)	
		
		__Debug("Phase 2: Food Balancing: Average:", avgFood)

		-- Check for Major Civ below threshold

		for i = 0, iNumMajCivs -1 do
			if (majList[i] ~= nil) then
				if(majList[i].leader ~= "LEADER_SPECTATOR" and PlayerConfigurations[i]:GetHandicapTypeID() ~= 2021024770) then
				if (majList[i].food_spawn_start < ((avgFood + iBalancingTwo) * (1 - dispersion)) or majList[i].food_spawn_start < minFood) then
					--__Debug("Need to adjust: ", majList[i].leader)
					-- Try to Understand the reason for the low food
					-- Is it Maori ?
					if (Map.GetPlot(majList[i].plotX,majList[i].plotY):IsWater() == true) then
						__Debug("Food balancing:", majList[i].leader, "Don't adjust Maori start");
	
				-- Is it a Mountain start?
						elseif (majList[i].impassable_start > 1) then
							__Debug("Food balancing:", majList[i].leader, "Mountains detected");

				-- But is the leader biased toward Mountains? 
							if (((majList[i].civ == "CIVILIZATION_INCA") and (math.floor(avgFood + iBalancingTwo - majList[i].food_spawn_start) < 4)) or ((majList[i].civ == "CIVILIZATION_MAPUCHE") and (math.floor(avgFood + iBalancingTwo - majList[i].food_spawn_start) < 4))) then
								__Debug("Food balancing:", majList[i].leader, "Mountain Civ Detected: No need to re-balance");
								else
								__Debug("Food balancing:", majList[i].leader, "Start Mountains re-Balancing");
								__Debug("Food balancing: Food missing:", math.max(math.floor(avgFood + iBalancingTwo - majList[i].food_spawn_start), minFood - majList[i].food_spawn_start));
								count = 0;
								for j = 1, math.max(math.floor(avgFood + iBalancingTwo + 1 - majList[i].food_spawn_start), minFood - majList[i].food_spawn_start) do
									if ((AddBonusFood(Map.GetPlot(majList[i].plotX,majList[i].plotY),iBalancingThree,3) == false)) then
										count = count + 1
										if (count == math.min(3 - iBalancingTwo,1)) then
											__Debug("Food balancing:", majList[i].leader, "Will grand a luxury");
											AddLuxuryStarting(Map.GetPlot(majList[i].plotX,majList[i].plotY),"food")
											count = count + 1;
										end
										if (count == math.min(7 - iBalancingTwo,1)) then
											__Debug("Food balancing:", majList[i].leader, "Will grand a luxury");
											AddLuxuryStarting(Map.GetPlot(majList[i].plotX,majList[i].plotY),"food")
										end
									end
								end
							end

						else

				-- Well it has to be a shitty start then....
							__Debug("Food balancing:", majList[i].leader, "Poor start detected");
							__Debug("Food balancing: Food missing:", math.max(math.floor(avgFood + iBalancingTwo - majList[i].food_spawn_start),minFood - majList[i].food_spawn_start));
							count = 0;
							for j = 1, math.max(math.floor(avgFood + iBalancingTwo + 1 - majList[i].food_spawn_start), minFood - majList[i].food_spawn_start) do
								if (majList[i].civ == "CIVILIZATION_MALI" and majList[i].desert_start > 2) then
										if ((AddBonusFood(Map.GetPlot(majList[i].plotX,majList[i].plotY),iBalancingThree,2) == false)) then
											count = count + 1;
											if (count == math.min(3 - iBalancingTwo,1)) then
												__Debug("Food balancing:", majList[i].leader, "Will grand a luxury");
												AddLuxuryStarting(Map.GetPlot(majList[i].plotX,majList[i].plotY),"food")
												count = count + 1;
											end
											if (count == math.min(7 - iBalancingTwo,1)) then
												__Debug("Food balancing:", majList[i].leader, "Will grand a luxury");
												AddLuxuryStarting(Map.GetPlot(majList[i].plotX,majList[i].plotY),"food")
											end
										end
									elseif (majList[i].civ == "CIVILIZATION_RUSSIA" or majList[i].civ == "CIVILIZATION_CANADA" and majList[i].snow_start > 2) then
										if ((AddBonusFood(Map.GetPlot(majList[i].plotX,majList[i].plotY),iBalancingThree,1) == false)) then
											count = count + 1;
											if (count == math.min(3 - iBalancingTwo,1)) then
												__Debug("Food balancing:", majList[i].leader, "Will grand a luxury");
												AddLuxuryStarting(Map.GetPlot(majList[i].plotX,majList[i].plotY),"food")
												count = count + 1;
											end
											if (count == math.min(7 - iBalancingTwo,1)) then
												__Debug("Food balancing:", majList[i].leader, "Will grand a luxury");
												AddLuxuryStarting(Map.GetPlot(majList[i].plotX,majList[i].plotY),"food")
											end
										end
									else 
									if ((AddBonusFood(Map.GetPlot(majList[i].plotX,majList[i].plotY),iBalancingThree,0) == false)) then
										count = count + 1;
										if (count == math.min(3 - iBalancingTwo,1)) then
											__Debug("Food balancing:", majList[i].leader, "Will grand a luxury");
											AddLuxuryStarting(Map.GetPlot(majList[i].plotX,majList[i].plotY),"food")
											count = count + 1;
										end
										if (count == math.min(7 - iBalancingTwo,1)) then
											__Debug("Food balancing:", majList[i].leader, "Will grand a luxury");
											AddLuxuryStarting(Map.GetPlot(majList[i].plotX,majList[i].plotY),"food")
										end
									end

								end
							end
	

					end
				end
				end
			end
		end
	

		-- Phase 2 reduce the positive outliers (Yes Firaxis intended to correct positive outliers! here this is skwed to extrem outlier with "dispersion * 2")

		-- Check for Major Civ below threshold
		
		if (startConfig ~= 3) then

		for i = 0, iNumMajCivs -1 do
			if (majList[i] ~= nil) then
				if(majList[i].leader ~= "LEADER_SPECTATOR" and PlayerConfigurations[i]:GetHandicapTypeID() ~= 2021024770) then
				if (majList[i].food_spawn_start > ((avgFood + iBalancingTwo) * (1 + dispersion * 2))) then
					__Debug("Need to adjust Food Down: ", majList[i].leader);

					if (math.ceil(majList[i].food_spawn_start - (avgFood + iBalancingTwo)-1) > 0) then
						for j = 1, math.ceil(majList[i].food_spawn_start - (avgFood + iBalancingTwo)-1) do
							RemoveFood(Map.GetPlot(majList[i].plotX,majList[i].plotY));
						end
					end
				end
				end
			end
		end

		end


		-- Phase 2 completed
		print ("Food Balancing - Completed", os.date("%c"))
		---------------------------------------------------------------------------------------------------------------------------------------------------------
		-- Phase 3: Production Balancing: Firaxis didn't have production rebalancing in their AddBalancedResources(), so this mimics the Phase 2
		----------------------------------------------------------------------------------------------------------------------------------------------------------

		-- First let's check the hills

		for i = 0, iNumMajCivs -1 do
			count = 0;
			if (majList[i] == nil or majList[i].leader == "LEADER_SPECTATOR" and PlayerConfigurations[i]:GetHandicapTypeID() ~= 2021024770) then
				count = count +1;
				else
				startPlot = Map.GetPlot(majList[i].plotX, majList[i].plotY);
				tempEval = EvaluateStartingLocation(startPlot)
				majList[i].food_spawn_start = tempEval[5];
				majList[i].prod_spawn_start = tempEval[6];
				majList[i].hill_start = tempEval[22];
				majList[i].hill_inner = tempEval[23];
				avgHill = avgHill + majList[i].hill_start * 2 + majList[i].hill_inner;
			end

		end
		
		avgHill = avgHill / (iNumMajCivs + count);	
		
		__Debug("Phase 3a: Prod - Hills Balancing: Average:", avgHill)
		
		-- Check for Major Civ below threshold	

		for i = 0, iNumMajCivs -1 do
			if (majList[i] ~= nil) then
				if(majList[i].leader ~= "LEADER_SPECTATOR" and PlayerConfigurations[i]:GetHandicapTypeID() ~= 2021024770) then
				if ((majList[i].hill_start * 2 + majList[i].hill_inner) < ((avgHill + 1)* (1 - dispersion))) then
					__Debug("Hill balancing: Need to adjust: ", majList[i].leader)

				-- Try to Understand the reason for the low hill count
				-- Is it Maori ?
					if (Map.GetPlot(majList[i].plotX,majList[i].plotY):IsWater() == true) then
						__Debug("Prod balancing:", majList[i].leader, "Don't adjust Maori start");
	
						else
						__Debug("Prod balancing:", majList[i].leader, "Start Hill Rebalancing");
						__Debug("Prod balancing: Hills missing:", math.floor((avgHill + iBalancingTwo - (majList[i].hill_start + majList[i].hill_inner))/2));
					
						if (math.floor((avgHill + iBalancingTwo + 1 - (majList[i].hill_start + majList[i].hill_inner))/2) > 0) then
							count = 0;
							for j = 1, math.floor((avgHill + iBalancingTwo + 1 - (majList[i].hill_start + majList[i].hill_inner))/2) do

									if (AddHills(Map.GetPlot(majList[i].plotX,majList[i].plotY),iBalancingThree,0) == false) then
										count = count + 1;

										if (count == math.min(3 - iBalancingTwo,1)) then
											__Debug("Hill balancing:", majList[i].leader, "Will Grant something to be defined");
										end
									end


							end
						end
					end
				end
				end
			end	
		end



		__Debug("Phase 3a: Prod - Hills Balancing: Completed")


		---
		for i = 0, iNumMajCivs -1 do
			count = 0;
			if (majList[i] == nil or majList[i].leader == "LEADER_SPECTATOR" and PlayerConfigurations[i]:GetHandicapTypeID() ~= 2021024770) then
				count = count +1;
				else
				startPlot = Map.GetPlot(majList[i].plotX, majList[i].plotY);
				tempEval = EvaluateStartingLocation(startPlot)
				majList[i].food_spawn_start = tempEval[5];
				majList[i].prod_spawn_start = tempEval[6];
				if (majList[i].civ == "CIVILIZATION_RUSSIA" ) then
					majList[i].prod_spawn_start = majList[i].prod_spawn_start + tempEval[11]*1.75 -- Add +0.75 prod per Tundra tile for the faith bonus
				end
				if (majList[i].civ == "CIVILIZATION_MALI" ) then
					majList[i].prod_spawn_start = majList[i].prod_spawn_start + tempEval[12]*0.75 -- Add +0.75 prod per Desert tile for the faith bonus
				end
				avgProd = avgProd + majList[i].prod_spawn_start;
			end

		end
		
		avgProd = avgProd / (iNumMajCivs + count);	
		
		__Debug("Phase 3b: Prod - Bonus Balancing: Average:", avgProd)

		-- Check for Major Civ below threshold	

		for i = 0, iNumMajCivs -1 do
			if (majList[i] ~= nil) then
				if(majList[i].leader ~= "LEADER_SPECTATOR" and PlayerConfigurations[i]:GetHandicapTypeID() ~= 2021024770) then
				if (majList[i].prod_spawn_start < ((avgProd + iBalancingTwo )* (1 - dispersion))) then
					__Debug("Prod balancing: Need to adjust: ", majList[i].leader)

				-- Try to Understand the reason for the low PRODUCTION
				-- Is it Maori ?
					if (Map.GetPlot(majList[i].plotX,majList[i].plotY):IsWater() == true) then
						__Debug("Prod balancing:", majList[i].leader, "Don't adjust Maori start");
	
						else
						__Debug("Prod balancing:", majList[i].leader, "Start Production Rebalancing");
						__Debug("Prod balancing: Prod missing:", math.floor((avgProd + iBalancingTwo - majList[i].prod_spawn_start)));
					
						if (math.floor(avgProd + iBalancingTwo - majList[i].prod_spawn_start) > 0) then
							count = 0;
							for j = 1, math.floor(avgProd + iBalancingTwo + 1 - majList[i].prod_spawn_start) do

								if (majList[i].civ == "CIVILIZATION_INCA") then

									if (AddBonusProd(Map.GetPlot(majList[i].plotX,majList[i].plotY),iBalancingThree,3) == false) then
										count = count + 1;

										if (count == math.min(3 - iBalancingTwo,1)) then
											__Debug("Prod balancing:", majList[i].leader, "Will try to grant a luxury");
											AddLuxuryStarting(Map.GetPlot(majList[i].plotX,majList[i].plotY),"prod");
											count = count + 1;
										end
										if (count == math.min(7 - iBalancingTwo,1)) then
											__Debug("Prod balancing:", majList[i].leader, "Will try to grant a luxury");
											AddLuxuryStarting(Map.GetPlot(majList[i].plotX,majList[i].plotY),"prod");
										end
									end
									
									else

									if (AddBonusProd(Map.GetPlot(majList[i].plotX,majList[i].plotY),iBalancingThree,0) == false) then
										count = count + 1;

										if (count == math.min(3 - iBalancingTwo,1)) then
											__Debug("Prod balancing:", majList[i].leader, "Will try to grant a luxury");
											AddLuxuryStarting(Map.GetPlot(majList[i].plotX,majList[i].plotY),"prod");
											count = count + 1;
										end
										if (count == math.min(7 - iBalancingTwo,1)) then
											__Debug("Prod balancing:", majList[i].leader, "Will try to grant a luxury");
											AddLuxuryStarting(Map.GetPlot(majList[i].plotX,majList[i].plotY),"prod");
										end
									end


								end
							end
						end
					end
				end
				end
			end	
		end

		-- Phase 3 reduce the positive outliers

		-- Check for Major Civ below threshold
		if (startConfig ~= 3) then
		
		for i = 0, iNumMajCivs -1 do
			if (majList[i] ~= nil) then
				if(majList[i].leader ~= "LEADER_SPECTATOR" and PlayerConfigurations[i]:GetHandicapTypeID() ~= 2021024770) then
				if (majList[i].prod_spawn_start > ((avgProd + iBalancingTwo) * (1 + dispersion * 2))) then
					__Debug("Need to adjust Production Down: ", majList[i].leader);
					if (math.ceil(majList[i].prod_spawn_start - (avgProd + iBalancingTwo) - 2) > 0) then
						for j = 1, math.ceil(majList[i].prod_spawn_start - (avgProd + iBalancingTwo) - 2) do
							RemoveProd(Map.GetPlot(majList[i].plotX,majList[i].plotY));
						end
					end
				end
				end
			end
		end

		end
		print ("Production Balancing - Completed", os.date("%c"))
		---------------------------------------------------------------------------------------------------------------------------------------------------------
		-- Phase 4: Best Tiles Balancing: Looking at the 2 best tiles for Ancient and Classical Starts
		----------------------------------------------------------------------------------------------------------------------------------------------------------;

		local iStartEra = GameInfo.Eras[ GameConfiguration.GetStartEra() ];
		local iStartIndex = 1;


		if iStartEra ~= nil then
			iStartIndex = iStartEra.ChronologyIndex;
		end

		if (iStartIndex == 1 or iStartIndex == 2) then

		-- Let's get the averages
		local avg_best_tile_1 = 0;
		local avg_best_tile_2 = 0;

		for i = 0, iNumMajCivs -1 do
			count = 0;
			if (majList[i] == nil or majList[i].leader == "LEADER_SPECTATOR" and PlayerConfigurations[i]:GetHandicapTypeID() ~= 2021024770) then
				count = count +1;
				else
				startPlot = Map.GetPlot(majList[i].plotX, majList[i].plotY);
				tempEval = EvaluateStartingLocation(startPlot)
				majList[i].best_tile = tempEval[24];
				majList[i].best_tile_2 = tempEval[25];
				avg_best_tile_1  = avg_best_tile_1 + majList[i].best_tile;
				avg_best_tile_2  = avg_best_tile_2 + majList[i].best_tile_2;
			end

		end

		avg_best_tile_1 = avg_best_tile_1 / (iNumMajCivs + count);
		avg_best_tile_2 = avg_best_tile_2 / (iNumMajCivs + count);

		__Debug("Phase 4: Best Tiles Balancing: Average Best tile:", avg_best_tile_1, "Second Best:", avg_best_tile_2)

		-- Check for Major Civ below threshold	

		for i = 0, iNumMajCivs -1 do
			if (majList[i] ~= nil) then
				if(majList[i].leader ~= "LEADER_SPECTATOR" and PlayerConfigurations[i]:GetHandicapTypeID() ~= 2021024770) then
					if ( ( majList[i].best_tile + majList[i].best_tile_2 ) < ( ( avg_best_tile_1 + avg_best_tile_2 ) * ( 1 - dispersion_2 ) ) ) then
						__Debug("Tile balancing: Need to adjust: ", majList[i].leader, "Missing score:", avg_best_tile_1 + avg_best_tile_2 - majList[i].best_tile - majList[i].best_tile_2 )
						if(majList[i].civ == "CIVILIZATION_INCA") then
							Terraforming_Best(Map.GetPlot(majList[i].plotX,majList[i].plotY), avg_best_tile_1, avg_best_tile_2, avg_best_tile_1 + avg_best_tile_2 - majList[i].best_tile - majList[i].best_tile_2, 3)
							elseif(majList[i].civ == "CIVILIZATION_EGYPT") then
							Terraforming_Best(Map.GetPlot(majList[i].plotX,majList[i].plotY), avg_best_tile_1, avg_best_tile_2, avg_best_tile_1 + avg_best_tile_2 - majList[i].best_tile - majList[i].best_tile_2, 4)
							elseif(majList[i].civ == "CIVILIZATION_MALI") then
							Terraforming_Best(Map.GetPlot(majList[i].plotX,majList[i].plotY), avg_best_tile_1, avg_best_tile_2, avg_best_tile_1 + avg_best_tile_2 - majList[i].best_tile - majList[i].best_tile_2, 2)
							elseif(majList[i].civ == "CIVILIZATION_CANADA" or majList[i].civ == "CIVILIZATION_RUSSIA") then
							Terraforming_Best(Map.GetPlot(majList[i].plotX,majList[i].plotY), avg_best_tile_1, avg_best_tile_2, avg_best_tile_1 + avg_best_tile_2 - majList[i].best_tile - majList[i].best_tile_2, 1)
							else
							Terraforming_Best(Map.GetPlot(majList[i].plotX,majList[i].plotY), avg_best_tile_1, avg_best_tile_2, avg_best_tile_1 + avg_best_tile_2 - majList[i].best_tile - majList[i].best_tile_2, 0)
						end
					end
				end
			end
		end


		print ("Best Tiles Balancing - Completed", os.date("%c"))
		end -- era check end
		---------------------------------------------------------------------------------------------------------------------------------------------------------
		-- Finalize
		----------------------------------------------------------------------------------------------------------------------------------------------------------

		-- Re-run coastal check if Reefs added are blocking a harbour
		for i = 0, iNumMajCivs -1 do
			-- Added Spectator mod handling if a major player isn't detected
			if (majList[i] ~= nil) then
				if(majList[i].leader ~= "LEADER_SPECTATOR" and PlayerConfigurations[i]:GetHandicapTypeID() ~= 2021024770) then
				if (Map.GetPlot(majList[i].plotX,majList[i].plotY):IsCoastalLand() == true) then
					-- Check for Coastal Start
					__Debug("Coastal Terraforming Start X: ", majList[i].plotX, "Start Y: ", majList[i].plotY, "Player: ",i," ",majList[i].leader, majList[i].civ);
					Terraforming_Coastal(Map.GetPlot(majList[i].plotX,majList[i].plotY), iBalancingThree, true)
				end
				end
			end
		end

		-- Run one last eval for debug

		for i = 0, iNumMajCivs -1 do
			local temp = 0;
			count = 0;
			if (majList[i] == nil or majList[i].leader == "LEADER_SPECTATOR" and PlayerConfigurations[i]:GetHandicapTypeID() ~= 2021024770) then
				count = count + 1
				else
				startPlot = Map.GetPlot(majList[i].plotX, majList[i].plotY);
				tempEval = EvaluateStartingLocation(startPlot)
				print ("BBS Script - Completed", os.date("%c"), "Player", i, "Food adjustement:", (tempEval[5]-majList[i].food_adjust), "Production adjustement:", (tempEval[6]-majList[i].prod_adjust) );
				if (bBiasFail == true) then
					Game:SetProperty("BBS_SAFE_MODE",true)
					else
					Game:SetProperty("BBS_SAFE_MODE",false)
				end
			end

		end

		end -- Strategic Only loop
		
		-- Gemedon's input to limit crash
		TerrainBuilder.AnalyzeChokepoints()
		-- Flag for the UI
		Game:SetProperty("BBS_PLOT_HIDDEN",false)
		
	else
		__Debug("D TURN STARTING: Any other turn");

	end
end

------------------------------------------------------------------------------------------------------------------------------

function EvaluateStartingLocation(plot)
--Terrain Type
--0 Grassland
--1 Grass + hill
--2 grass + mountain
--3 plain
--4 plain + hill
--5 plain + mountain
--6 desert
--7 desert + hill
--8 desert + mountain
--9 tundra
--10 tundra + hill
--11 tundra + mountain
--12 snow
--13 snow + hill
--14 snow + mountain
--15 water
--16 ocean
	local plotX = plot:GetX();
	local plotY = plot:GetY();
	local impassable = 0;
	local snow = 0;
	local water = 0;
	local desert = 0;
	local flood = 0;
	local hill = 0;
	local flood_start = 0;
	local flood_inner = 0;
	local flood_outer = 0;
	local food_spawn_start = 0;
	local prod_spawn_start = 0;
	local culture_spawn_start = 0;
	local faith_spawn_start = 0;
	local best_yield_start = 0;
	local impassable_start = 0;
	local snow_start = 0;
	local water_start = 0;
	local desert_start = 0;
	local hill_start = 0;
	local impassable_inner = 0;
	local snow_inner = 0;
	local water_inner = 0;
	local desert_inner = 0;
	local hill_inner = 0;
	local impassable_outer = 0;
	local snow_outer = 0;
	local water_outer = 0;
	local desert_outer = 0
	local type = "Standard"
	local gridWidth, gridHeight = Map.GetGridSize();
	local terrainType = plot:GetTerrainType();
	local iResourcesInDB = 0;
	local bCulture = false;
	local bFaith = false;
	local direction = 0;
	eResourceType	= {};
	eResourceClassType = {};
	eRevealedEra = {};
	local count = 0;
	local adjacentPlot = nil;
	local adjacentPlot2 = nil;
	local adjacentPlot3 = nil;
	local adjacentPlot4 = nil;
	local temp_tile = 0;
	local best_tile = 0;
	local second_best_tile = 0;

-- EvalType is the result table to then be used as the basis for later balancing opperation

	local EvalType = {impassable,water,snow,desert, food_spawn_start, prod_spawn_start, culture_spawn_start, faith_spawn_start, impassable_start,water_start,snow_start,desert_start,impassable_inner,water_inner,snow_inner,desert_inner,impassable_outer,water_outer,snow_outer,desert_outer}

	for row in GameInfo.Resources() do
		eResourceType[iResourcesInDB] = row.Hash;
		eResourceClassType[iResourcesInDB] = row.ResourceClassType;
		eRevealedEra[iResourcesInDB] = row.RevealedEra;
		iResourcesInDB = iResourcesInDB + 1;
	end


-- Starting plot:
-- Tile #-1

	for i = -1, 35 do
		adjacentPlot = GetAdjacentTiles(plot, i)
		if (adjacentPlot ~= nil) then
			terrainType = adjacentPlot:GetTerrainType();
				if (i == -1) then
					if(adjacentPlot:IsImpassable() == true) then
						impassable = impassable + 1;
					end

					-- Checks to see if the plot is water
					if(adjacentPlot:IsWater() == true) then
						water = water + 1;
					end

					-- Add to the Snow counter if snow shows up
					if(terrainType == 9 or terrainType == 10 or terrainType == 12 or terrainType == 13) then
						snow = snow + 1;
					end

					-- Add to the hills counter if Hill shows up
					if(terrainType == 1 or terrainType == 7 or terrainType == 4 or terrainType == 10) then
						hill = hill + 1;
					end
			
					-- Add to the Desert counter if desert shows up
					if(terrainType == 6 or terrainType == 7) then
						desert = desert + 1;
					end

					-- Add to Floodplains if they are showing up
					if (adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS or adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS_PLAINS or adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS_GRASSLAND) then
						flood = flood +1;
					end
                    			-- Gets the food and production counts
                   			food_spawn_start = food_spawn_start + adjacentPlot:GetYield(g_YIELD_FOOD);
                    			prod_spawn_start = prod_spawn_start + adjacentPlot:GetYield(g_YIELD_PRODUCTION);
					bCulture = false;
					bFaith = false;
					for row = 0, iResourcesInDB do
						if (eResourceClassType[row]== "RESOURCECLASS_LUXURY") then
							if(adjacentPlot:GetResourceCount() > 0) then
								-- Check for Coffee, Jade, Marble, Incense, dyes and clams
								if (adjacentPlot:GetResourceType() == 12 or adjacentPlot:GetResourceType() == 20 or adjacentPlot:GetResourceType() == 21) then
									bCulture = true;
									elseif (adjacentPlot:GetResourceType() == 15 or adjacentPlot:GetResourceType() == 18 or adjacentPlot:GetResourceType() == 23) then
									bFaith = true;
								end
							end
						end
					end
					if (bCulture == true) then
						culture_spawn_start = culture_spawn_start + 1;
					end
					if (bFaith == true) then
						faith_spawn_start = faith_spawn_start + 1;
					end
-- Starting ring
-- Tiles #0 #5
				elseif (i > -1 and i < 6) then

					temp_tile = 0;

					if(adjacentPlot:IsImpassable() == true) then
						impassable_start = impassable_start + 1;
					end

					-- Checks to see if the plot is water
					if(adjacentPlot:IsWater() == true) then
						water_start = water_start + 1;
					end

					-- Add to the Snow counter if snow shows up
					if(terrainType == 9 or terrainType == 10 or terrainType == 12 or terrainType == 13) then
						snow_start = snow_start + 1;
					end
			
					-- Add to the Desert counter if desert shows up
					if(terrainType == 6 or terrainType == 7) then
						desert_start = desert_start + 1;
					end

					-- Add to the hills counter if Hill shows up
					if(terrainType == 1 or terrainType == 7 or terrainType == 4 or terrainType == 10) then
						hill_start = hill_start + 1;
					end

					-- Add to Floodplains if they are showing up
					if (adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS or adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS_PLAINS or adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS_GRASSLAND) then
						flood_start = flood_start +1;
					end

                    			-- Gets the food and production counts
                   			food_spawn_start = food_spawn_start + adjacentPlot:GetYield(g_YIELD_FOOD);
                    			prod_spawn_start = prod_spawn_start + adjacentPlot:GetYield(g_YIELD_PRODUCTION);
					temp_tile = adjacentPlot:GetYield(g_YIELD_FOOD) + adjacentPlot:GetYield(g_YIELD_PRODUCTION) * 1.5 + adjacentPlot:GetYield(g_YIELD_GOLD) * 0.5;

					-- Adjust for non discovered resources
					if(adjacentPlot:GetResourceCount() > 0) then
						if (adjacentPlot:GetResourceType() == 41 or adjacentPlot:GetResourceType() == 46) then
							temp_tile = temp_tile - 2 * 1.5
							prod_spawn_start = prod_spawn_start - 2
							elseif (adjacentPlot:GetResourceType() == 42 or adjacentPlot:GetResourceType() == 44) then
							temp_tile = temp_tile - 1 * 1.5 - 1 
							food_spawn_start = food_spawn_start - 1
							prod_spawn_start = prod_spawn_start - 1
							elseif (adjacentPlot:GetResourceType() == 45) then
							temp_tile = temp_tile - 3 * 1.5
							prod_spawn_start = prod_spawn_start - 3
						end
					end

					bCulture = false;
					bFaith = false;
					for row = 0, iResourcesInDB do
						if (eResourceClassType[row]== "RESOURCECLASS_LUXURY") then
							if(adjacentPlot:GetResourceCount() > 0) then
								-- Check for Coffee, Jade, Marble, Incense, dyes and clams
								if (adjacentPlot:GetResourceType() == 12 or adjacentPlot:GetResourceType() == 20 or adjacentPlot:GetResourceType() == 21) then
									bCulture = true;
									elseif (adjacentPlot:GetResourceType() == 15 or adjacentPlot:GetResourceType() == 18 or adjacentPlot:GetResourceType() == 23) then
									bFaith = true;
								end
							end
						end
					end
					if (bCulture == true) then
						culture_spawn_start = culture_spawn_start + 1;
						temp_tile = temp_tile + 2;
					end
					if (bFaith == true) then
						faith_spawn_start = faith_spawn_start + 1;
						temp_tile = temp_tile + 1.5;
					end
					if (temp_tile > best_tile or temp_tile == best_tile) then
						second_best_tile = best_tile
						best_tile = temp_tile
						else
						if (temp_tile > second_best_tile and temp_tile < best_tile) then
							second_best_tile = temp_tile
						end
					end
					temp_tile = 0	
-- Inner ring
-- Tiles #6 to #17
			elseif (i > 5 and i < 18) then

				-- Checks to see if the plot is impassable
			if(adjacentPlot:IsImpassable() == true) then
				impassable_inner = impassable_inner + 1;
			end

				-- Checks to see if the plot is water
			if(adjacentPlot:IsWater() == true) then
				water_inner = water_inner + 1;
			end

				-- Add to the Snow counter if snow shows up
			if(terrainType == 9 or terrainType == 10 or terrainType == 12 or terrainType == 13) then
				snow_inner = snow_inner + 1;
			end

			-- Add to the hills counter if Hill shows up
			if(terrainType == 1 or terrainType == 7 or terrainType == 4 or terrainType == 10) then
				hill_inner = hill_inner + 1;
			end

				-- Add to Floodplains if they are showing up
			if (adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS or adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS_PLAINS or adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS_GRASSLAND) then
				flood_inner = flood_inner +1;
			end
	
				-- Add to the Desert counter if desert shows up
			if(terrainType == 6 or terrainType == 7) then
				desert_inner = desert_inner + 1;
			end


-- Outer ring
-- Tiles #18 to #35
			elseif (i > 17 and i < 36) then

				if(adjacentPlot:IsImpassable() == true) then
					impassable_outer = impassable_outer + 1;
				end

						-- Checks to see if the plot is water
				if(adjacentPlot:IsWater() == true) then
					water_outer = water_outer + 1;
				end

				-- Add to the Snow counter if snow shows up
				if(terrainType == 9 or terrainType == 10 or terrainType == 12 or terrainType == 13) then
					snow_outer = snow_outer + 1;
				end
			
				-- Add to the Desert counter if desert shows up
				if(terrainType == 6 or terrainType == 7) then
					desert_outer = desert_outer + 1;
				end

				-- Add to Floodplains if they are showing up
				if (adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS or adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS_PLAINS or adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS_GRASSLAND) then
					flood_outer = flood_outer +1;
				end


			end
		end
	end

	impassable = impassable + impassable_start + impassable_inner + impassable_outer
	water = water + water_start + water_inner + water_outer
	snow = snow + snow_start + snow_inner + snow_outer
	flood = flood + flood_start + flood_inner + flood_outer
	desert = desert + desert_start + desert_inner + desert_outer
	hill = hill + hill_start + hill_inner
	__Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Total mountain: ", impassable, "Total water: ", water, "Total snow: ", snow, "Total desert: ", desert, "Total hill", hill, "Immediate Food: ", food_spawn_start, "Immediate Prod: ", prod_spawn_start, "Immediate Culture: ", culture_spawn_start, "Immediate Faith: ",faith_spawn_start,"Floodplains",flood,"Best_tile",best_tile,"Best_tile_2",second_best_tile)
	EvalType = {impassable,water,snow,desert, food_spawn_start, prod_spawn_start, culture_spawn_start, faith_spawn_start, impassable_start,water_start,snow_start,desert_start,impassable_inner,water_inner,snow_inner,desert_inner,impassable_outer,water_outer,snow_outer,desert_outer,flood,hill_start,hill_inner,best_tile,second_best_tile}
	return EvalType
end

------------------------------------------------------------------------------------------------------------------------------------------------

function AddBonusFood(plot,intensity, flag)
	-- flag = 0 normal
	-- flag = 1 tundra civ
	-- flag = 2 desert civ
	-- flag = 3 mountain civ
	local iResourcesInDB = 0;
	local terrainType = plot:GetTerrainType();
	local featureType = plot:GetFeatureType();
	local gridWidth, gridHeight = Map.GetGridSize();
	local direction = 0;
	eResourceType	= {};
	eResourceClassType = {};
	aBonus = {};
	local limit_1 = 0;
	local max_unFeature = 2;
	local adjacentPlot = nil;
	local adjacentPlot2 = nil;
	local adjacentPlot3 = nil;
	local adjacentPlot4 = nil;
	local count = 0;
	local increment = 1;
	local start_range = 0;
	local end_range = 5;

	if (intensity == 0) then
		limit_1 = 0.9;
		elseif (intensity == 1) then
			limit_1 = 0.5;
		elseif (intensity == 2) then
			limit_1 = 0.25;
	end

	for k = 0, 1 do
	
	if k == 0 then	
		if (flag == 2 or flag == 1) then
			start_range = 0;
			end_range = 16;
			increment = 2;
			else
			start_range = 0;
			end_range = 5;
			increment = 1;
		end
	elseif k == 1 then
		if (flag == 2 or flag == 1) then
			start_range = 17;
			end_range = 0;
			increment = -1;
			else
			start_range = 0;
			end_range = 5;
			increment = 1;
		end
	end

	for i = start_range, end_range, increment do
		adjacentPlot = GetAdjacentTiles(plot, i)
		
		if (adjacentPlot ~= nil) then

		terrainType = adjacentPlot:GetTerrainType();

			if (adjacentPlot:GetResourceCount() < 1 and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND and adjacentPlot:GetFeatureType() ~= g_FEATURE_MARSH) then

				rng = TerrainBuilder.GetRandomNumber(100,"test")/100;

				if(adjacentPlot:GetFeatureType() == g_FEATURE_JUNGLE) then
				--banana
					if(ResourceBuilder.CanHaveResource(adjacentPlot, 0)) then
						ResourceBuilder.SetResourceType(adjacentPlot, 0, 1);
						__Debug("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: Banana");
						return true;
					end

				elseif((terrainType == 3 and adjacentPlot:GetFeatureType() ~= g_FEATURE_JUNGLE and flag ~= 1 and flag ~= 2) or (terrainType == 6 and flag ~= 2 and adjacentPlot:GetFeatureType() ~= g_FEATURE_OASIS) or (terrainType == 9 and flag ~= 1) or (terrainType == 2 and flag ~= 3 and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO) or (terrainType == 5 and flag ~= 3 and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO) or (terrainType == 8 and flag ~= 3 and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO) or (terrainType == 11 and flag ~= 3 and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO) or  (terrainType == 14 and flag ~= 3 and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO) ) then
					-- Convert to Grassland
					if(rng > limit_1) then
						TerrainBuilder.SetTerrainType(adjacentPlot,0);
						if ( adjacentPlot:GetFeatureType() == g_FEATURE_VOLCANO) then
							TerrainBuilder.SetFeatureType(adjacentPlot,-1);
						end
						__Debug("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Turned the tile to a Grassland");
						return true;
					end
					rng = TerrainBuilder.GetRandomNumber(100,"test")/100;
				elseif((terrainType == 4 and flag ~= 1 and flag ~= 2) or (terrainType == 7 and flag ~= 2) or (terrainType == 10 and flag ~= 1)) then
					-- Convert to Grassland
					if(rng > limit_1) then
						TerrainBuilder.SetTerrainType(adjacentPlot,1);
						__Debug("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Turned the tile to a Hills Grassland");
						return true;
					end

				elseif(terrainType == 0) then
					-- Add Cattle / Rice
					if(rng > 0.5) then
						if(ResourceBuilder.CanHaveResource(adjacentPlot, 1)) then
							ResourceBuilder.SetResourceType(adjacentPlot, 1, 1);
							__Debug("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: Cattle");
							return true;
						end
						else
						if(ResourceBuilder.CanHaveResource(adjacentPlot, 6)) then
							ResourceBuilder.SetResourceType(adjacentPlot, 6, 1);
							__Debug("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: Rice");
							return true;
						end
					end
	
				elseif(terrainType == 3 and adjacentPlot:GetFeatureType() == -1) then
					--wheat
					if(ResourceBuilder.CanHaveResource(adjacentPlot, 9)) then
						ResourceBuilder.SetResourceType(adjacentPlot, 9, 1);
						__Debug("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: Wheat");
						return true;
					end
				
				elseif((terrainType == 4 and adjacentPlot:GetFeatureType() == -1) or (terrainType == 1 and adjacentPlot:GetFeatureType() == -1) or (terrainType == 7 and adjacentPlot:GetFeatureType() == -1 and rng < 0.5) or (terrainType == 10 and adjacentPlot:GetFeatureType() == -1)) then
					-- sheep
					if(ResourceBuilder.CanHaveResource(adjacentPlot, 7)) then
						ResourceBuilder.SetResourceType(adjacentPlot, 7, 1);
						__Debug("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: Sheep");
						return true;
					end

				elseif(terrainType == 6 and adjacentPlot:GetFeatureType() == -1 and rng < 0.1) then
					-- Desert Sheep on Hill
					TerrainBuilder.SetTerrainType(adjacentPlot,7);
					ResourceBuilder.SetResourceType(adjacentPlot, 7, 1);
					__Debug("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: Sheep on Desert Hill");
					return true;
			
				elseif(terrainType == 6 and adjacentPlot:GetFeatureType() == -1 and adjacentPlot:GetResourceCount() < 1) then
					-- Oasis
					local bOasis = true
					for j = 0, 5 do
						adjacentPlot2 = GetAdjacentTiles(adjacentPlot, j)
						if (adjacentPlot2 ~= nil ) then
							if (adjacentPlot2:GetTerrainType() ~= 6 and adjacentPlot2:GetTerrainType() ~= 7 and adjacentPlot2:GetTerrainType() ~= 8 or adjacentPlot2:GetFeatureType() == g_FEATURE_OASIS ) then
								bOasis = false	
							end 	
						end
							
					end
					rng = TerrainBuilder.GetRandomNumber(100,"test")/100;
					if (bOasis == true and rng < 0.25) then
						ResourceBuilder.SetResourceType(adjacentPlot, -1);
						TerrainBuilder.SetFeatureType(adjacentPlot,4)
						__Debug("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: Oasis");
						return true;
					end


				elseif(terrainType == 15) then
					-- fish
					if(ResourceBuilder.CanHaveResource(adjacentPlot, 5)) then
						ResourceBuilder.SetResourceType(adjacentPlot, 5, 1);
						__Debug("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: Fish");
						return true;
					end
			
				elseif((terrainType == 4 and adjacentPlot:GetFeatureType() == 3) or (terrainType == 1 and adjacentPlot:GetFeatureType() == 3) or (terrainType == 7 and adjacentPlot:GetFeatureType() == 3) or (terrainType == 10 and adjacentPlot:GetFeatureType() == 3) and count < max_unFeature) then
					-- sheep instead of forest
					TerrainBuilder.SetFeatureType(adjacentPlot,-1)
					count = count + 1;
					ResourceBuilder.SetResourceType(adjacentPlot, 7, 1);
					__Debug("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: Sheep");
					return true;


				end
			end
		end


		if (adjacentPlot ~= nil) then
			terrainType = adjacentPlot:GetTerrainType();
			if( (terrainType == 6 and flag == 2 and adjacentPlot:IsRiver() == true and adjacentPlot:GetFeatureType() == -1 and adjacentPlot:GetResourceCount() < 1) ) then
				-- Add Desert Floodplains
				TerrainBuilder.SetFeatureType(adjacentPlot,g_FEATURE_FLOODPLAINS);
				__Debug("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Turned the tile to a Desert Floodplains");
				return true;
			end

			if( (terrainType == 2 and flag ~= 3 and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO) or (terrainType == 5 and flag ~= 3 and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO) or (terrainType == 8 and flag ~= 3 and flag ~= 2 and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO) or (terrainType == 11 and flag ~= 3 and flag ~= 1 and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO) or  (terrainType == 14 and flag ~= 3 and flag ~= 1 and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO) and adjacentPlot:GetResourceCount() < 1) then
				-- Convert to Grassland
				TerrainBuilder.SetTerrainType(adjacentPlot,terrainType - 2);
				if ( adjacentPlot:GetFeatureType() == g_FEATURE_VOLCANO) then
					TerrainBuilder.SetFeatureType(adjacentPlot,-1);
				end
				__Debug("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Turned the tile to a Grassland");
				return true;
			end
		end
	end


	end -- k end loop


	__Debug("Food balancing: Couldn't add Food Bonus");
	return false;
end

------------------------------------------------------------------------------------------------------------------------------------------------

function AddBonusProd(plot, intensity,flag)
	local iResourcesInDB = 0;
	local terrainType = plot:GetTerrainType();
	local featureType = plot:GetFeatureType();
	local gridWidth, gridHeight = Map.GetGridSize();
	local bWater = true;
	local count = 0;
	eResourceType	= {};
	eResourceClassType = {};
	aBonus = {};
	local limit_1 = 0;
	local range = 17;
	local adjacentPlot = nil;
	local adjacentPlot2 = nil;
	local adjacentPlot3 = nil;
	local adjacentPlot4 = nil;
	local start_range = 0;
	local end_range = 5;
	local increment = 1;	

	if (intensity == 0) then
		limit_1 = 0.9;
		elseif (intensity == 1) then
			limit_1 = 0.75;
		elseif (intensity == 2) then
			limit_1 = 0.5;
	end

	for k = 0, 1 do
	
	if k == 0 then	
		if (flag == 2 or flag == 1) then
			start_range = 0;
			end_range = 16;
			increment = 2;
			else
			start_range = 0;
			end_range = 5;
			increment = 1;
		end
	elseif k == 1 then
		if (flag == 2 or flag == 1) then
			start_range = 17;
			end_range = 0;
			increment = -1;
			else
			start_range = 0;
			end_range = 5;
			increment = 1;
		end
	end

	for i = start_range, end_range, increment do
		adjacentPlot = GetAdjacentTiles(plot, i);
		

		if (adjacentPlot ~= nil) then

		if (adjacentPlot:GetResourceCount() < 1) then
			terrainType = adjacentPlot:GetTerrainType();
			rng = TerrainBuilder.GetRandomNumber(100,"test")/100;
			if((adjacentPlot:GetFeatureType() == -1) and (adjacentPlot:IsImpassable() == false) and (adjacentPlot:IsWater() == false) and  (adjacentPlot:GetTerrainType() ~= 6) and (adjacentPlot:GetTerrainType() ~= 7) and (adjacentPlot:GetTerrainType() ~= 12) and (adjacentPlot:GetTerrainType() ~= 13)) then
				--Wood
				--__Debug("Prod balancing: Wood");
				TerrainBuilder.SetFeatureType(adjacentPlot,3);
				__Debug("Prod Balancing X: ", adjacentPlot:GetX(), "Prod Balancing Y: ", adjacentPlot:GetY(), "Added: Wood");
				return true;
			elseif(terrainType == 0 and adjacentPlot:GetResourceType() == -1 and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND and adjacentPlot:GetFeatureType() ~= g_FEATURE_MARSH) then
				-- Convert to Hills
				if(rng > limit_1) then
					TerrainBuilder.SetTerrainType(adjacentPlot,1);
					__Debug("Prod Balancing X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Turned the tile to a Grassland Hill");
					return true;
				end
			elseif(terrainType == 3 and adjacentPlot:GetResourceType() == -1 and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND and adjacentPlot:GetFeatureType() ~= g_FEATURE_MARSH) then
				-- Convert to Hills
				if(rng > limit_1) then
					TerrainBuilder.SetTerrainType(adjacentPlot,4);
					__Debug("Prod Balancing X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Turned the tile to a Plain Hill");
					return true;
				end
				rng = TerrainBuilder.GetRandomNumber(100,"test")/100;
			elseif(terrainType == 6 and adjacentPlot:GetResourceType() == -1 and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND and adjacentPlot:GetFeatureType() ~= g_FEATURE_OASIS) then
				-- Convert to Hills
				if(rng > limit_1) then
					TerrainBuilder.SetTerrainType(adjacentPlot,7);
					__Debug("Prod Balancing X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Turned the tile to a Desert Hill");
					return true;
				end
			elseif((terrainType == 2 and flag ~= 3 and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO) or (terrainType == 5 and flag ~= 3 and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO) or (terrainType == 8 and flag ~= 3 and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO) or (terrainType == 11 and flag ~= 3 and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO) or  (terrainType == 14 and flag ~= 3 and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO) ) then
				-- Convert to Plain Hills
				if(rng > limit_1) then
					TerrainBuilder.SetTerrainType(adjacentPlot,terrainType - 1);
					if ( adjacentPlot:GetFeatureType() == g_FEATURE_VOLCANO) then
						TerrainBuilder.SetFeatureType(adjacentPlot,-1);
					end
					__Debug("Prod Balancing X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Turned the Mountain tile to a Hill");
					return true;
				end
				rng = TerrainBuilder.GetRandomNumber(100,"test")/100;
			elseif(terrainType == 9 and adjacentPlot:GetResourceType() == -1 and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND and adjacentPlot:GetFeatureType() ~= g_FEATURE_MARSH) then
				-- Convert to Hills
				if(rng > limit_1) then
					TerrainBuilder.SetTerrainType(adjacentPlot,10);
					__Debug("Prod Balancing X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Turned the tile to a Tundra Hill");
					return true;
				end
			elseif((terrainType == 7 and adjacentPlot:GetResourceType() == -1) or (terrainType == 10 and adjacentPlot:GetResourceType() == -1)) then
				-- copper
				--__Debug("Food balancing: Copper");
				if(ResourceBuilder.CanHaveResource(adjacentPlot, 2)) then
					ResourceBuilder.SetResourceType(adjacentPlot, 2, 1);
					__Debug("Prod Balancing X: ", adjacentPlot:GetX(), "Prod Balancing Y: ", adjacentPlot:GetY(), "Added: Copper");
					return true;
				end
				return true;
			elseif((terrainType == 9 or terrainType == 10) and adjacentPlot:GetResourceType() == -1) then
				-- Deer

				if(ResourceBuilder.CanHaveResource(adjacentPlot, 4)) then
					ResourceBuilder.SetResourceType(adjacentPlot, 4, 1);
					__Debug("Prod Balancing X: ", adjacentPlot:GetX(), "Prod Balancing Y: ", adjacentPlot:GetY(), "Added: Deer");
					return true;
				end
			end
		end

		end


		if (adjacentPlot ~= nil) then
			rng = TerrainBuilder.GetRandomNumber(100,"test")/100;
			terrainType = adjacentPlot:GetTerrainType();
			if(terrainType == 15 and adjacentPlot:GetFeatureType() == -1 and adjacentPlot:GetResourceType() ~= 45) then
				bWater = true;
				for j = 0, 5 do
					if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
						if(Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), j) ~= nil) then

							if(Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), j):IsWater() == false)	then
								bWater = false;
							end
							else
							bWater = false;	
						end
					end	
				end
				-- Small Island

				if(rng > limit_1 and bWater == true) then
					__Debug("Prod Balancing X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Added: Island");
					TerrainBuilder.SetTerrainType(adjacentPlot,1);
					return true;
				end

				elseif(terrainType == 15 and adjacentPlot:GetFeatureType() == -1 and adjacentPlot:GetResourceType() ~= 45) then

				rng = TerrainBuilder.GetRandomNumber(100,"test")/100;
				if(rng > limit_1) then 
					-- Reef

					__Debug("Prod Balancing X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Added: Reef");
					TerrainBuilder.SetFeatureType(adjacentPlot,g_FEATURE_REEF);
					rng = TerrainBuilder.GetRandomNumber(100,"test")/100;
					if(rng > limit_1 * 1.25 and adjacentPlot:GetResourceType() == -1) then 
						-- Reef with fish 
	
						__Debug("Prod Balancing X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Added: Fish");
						ResourceBuilder.SetResourceType(adjacentPlot, 5, 1);
					end
					return true;
				end

				elseif(terrainType == 15 and adjacentPlot:GetFeatureType() == g_FEATURE_REEF and adjacentPlot:GetResourceType() == -1) then
					__Debug("Prod Balancing X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Added: Fish");
					ResourceBuilder.SetResourceType(adjacentPlot, 5, 1);
					return true;
			end
		end

	end	

	end -- k end loop


	__Debug("Prod balancing: Couldn't add Prod Bonus");
	return false;
end

------------------------------------------------------------------------------------------------------------------------------------------------

function AddHills(plot, intensity,flag)
	local iResourcesInDB = 0;
	local terrainType = plot:GetTerrainType();
	local featureType = plot:GetFeatureType();
	local gridWidth, gridHeight = Map.GetGridSize();
	local direction = 0;
	eResourceType	= {};
	eResourceClassType = {};
	aBonus = {};
	local limit_1 = 0;
	local limit_2 = 0;
	local limit = 0;
	local adjacentPlot = nil;
	local adjacentPlot2 = nil;
	local adjacentPlot3 = nil;
	local adjacentPlot4 = nil;
	local start_range = -1;
	local end_range = 17;
	local increment = 1;	

	if (intensity == 0) then
		limit_1 = 0.9;
		limit_2 = 0.75;
		elseif (intensity == 1) then
			limit_1 = 0.33;
			limit_2 = 0.20;
		elseif (intensity == 2) then
			limit_1 = 0.20;
			limit_2 = 0.10;
	end

	for k = 0, 1 do
	
	if k == 0 then	
		if (flag == 2 or flag == 1) then
			start_range = -1;
			end_range = 17;
			increment = 3;
			else
			start_range = -1;
			end_range = 17;
			increment = 3;
		end
	elseif k == 1 then
		if (flag == 2 or flag == 1) then
			start_range = 17;
			end_range = -1;
			increment = -1;
			else
			start_range = 17;
			end_range = -1;
			increment = -1;
		end
	end

	for i = start_range, end_range, increment do
		adjacentPlot = GetAdjacentTiles(plot, i);

		if (i < 6) then
			limit = limit_1
			else
			limit = limit_2
		end

		if (adjacentPlot ~= nil) then
			terrainType = adjacentPlot:GetTerrainType();
			rng = TerrainBuilder.GetRandomNumber(100,"test")/100;
			if(terrainType == 0 and adjacentPlot:GetResourceType() == -1 and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_MARSH and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND) then
				if(rng > limit) then
					TerrainBuilder.SetTerrainType(adjacentPlot,1);
					__Debug("Prod Balancing X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Turned the tile to a Grassland Hill");
					return true;
				end
			elseif(terrainType == 3 and adjacentPlot:GetResourceType() == -1 and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND and adjacentPlot:GetFeatureType() ~= g_FEATURE_MARSH) then
				if(rng > limit) then
					TerrainBuilder.SetTerrainType(adjacentPlot,4);
					__Debug("Prod Balancing X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Turned the tile to a Plain Hill");
					return true;
				end
			elseif(terrainType == 6 and adjacentPlot:GetResourceType() == -1 and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND and adjacentPlot:GetFeatureType() ~= g_FEATURE_MARSH) then
				if(rng > limit) then
					TerrainBuilder.SetTerrainType(adjacentPlot,7);
					__Debug("Prod Balancing X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Turned the tile to a Desert Hill");
					return true;
				end
			elseif(terrainType == 9 and adjacentPlot:GetResourceType() == -1 and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_MARSH and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND) then
				if(rng > limit) then
					TerrainBuilder.SetTerrainType(adjacentPlot,10);
					__Debug("Prod Balancing X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Turned the tile to a Tundra Hill");
					return true;
				end
			elseif(adjacentPlot:GetResourceType() == -1 and adjacentPlot:GetFeatureType() == g_FEATURE_MARSH and (terrainType == 0 or terrainType == 3)) then
				if(rng > limit * 2) then
					TerrainBuilder.SetTerrainType(adjacentPlot,terrainType + 1);
					TerrainBuilder.SetFeatureType(adjacentPlot,-1);
					__Debug("Prod Balancing X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Turned the Marsh tile to a Hill");
					return true;
				end
			end


		end
	end

	end -- end k loop

	__Debug("Hill balancing: Couldn't add Prod Bonus");
	return false;
end
------------------------------------------------------------------------------

function Terraforming_Mountain(plot)
	-- flag = 0 normal
	-- flag = 1 tundra civ
	-- flag = 2 desert civ
	-- flag = 3 mountain civ
	local terrainType = plot:GetTerrainType();
	local featureType = plot:GetFeatureType();
	local gridWidth, gridHeight = Map.GetGridSize();
	local distance = 0;
	local min_distance = 99;
	local minimal_effort_i = nil;
	local adjacentPlot = nil;
	local adjacentPlot2 = nil;
	local adjacentPlot3 = nil;
	local adjacentPlot4 = nil;
	


	--------------------------------------------------------------------------------------------------------------
	-- Terraforming Mountain -------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------
		
	for i = 0, 5 do
		if (GetAdjacentTiles(plot, i) ~= nil) then
			if ( GetAdjacentTiles(plot, i):IsImpassable() == true ) then
				-- immediate wall
				__Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "Analysing the plot");
				if (i == 0) then
					if ( GetAdjacentTiles(plot, 5) ~= nil and GetAdjacentTiles(plot, i+1) ~= nil ) then
						if ( GetAdjacentTiles(plot, 5):IsImpassable() == true and GetAdjacentTiles(plot, i+1):IsImpassable() == true ) then
							-- Walled-in is there actual terrain on the other side ?
							if ( GetAdjacentTiles(plot, 5*i+60) ~= nil ) then
								if ( GetAdjacentTiles(plot, 5*i+60):IsImpassable() == false and GetAdjacentTiles(plot, 5*i+60):IsWater() == false  ) then
									-- Ok there is land let measure the distance to dig through
									if ( GetAdjacentTiles(plot, 2*i+6) ~= nil and GetAdjacentTiles(plot, 3*i+18) ~= nil and GetAdjacentTiles(plot, 4*i+36) ~= nil) then
										if ( GetAdjacentTiles(plot, 2*i+6):IsImpassable() == true) then
											distance = 2;
											else
											distance = 1;
										end
										if ( GetAdjacentTiles(plot, 3*i+18):IsImpassable() == true) then
											distance = distance + 1;
										end
										if ( GetAdjacentTiles(plot, 4*i+36):IsImpassable() == true) then
											distance = distance + 1;
										end
										__Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "Distance to dig is", distance);
										if (distance < min_distance) then
											min_distance = distance;
											minimal_effort_i = i;
										end
									end
									else
									__Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "No good Terrain on the other side");
								end
								else
								__Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "No Terrain on the other side");
							end
							else
							__Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "Can move around the Mountain");
						end
					end
					elseif (i>0 and i <5) then
					if ( GetAdjacentTiles(plot, i-1) ~= nil and GetAdjacentTiles(plot, i+1) ~= nil ) then
						if ( GetAdjacentTiles(plot, i-1):IsImpassable() == true and GetAdjacentTiles(plot, i+1):IsImpassable() == true ) then
							-- Walled-in is there actual terrain on the other side ?
							if ( GetAdjacentTiles(plot, 5*i+60) ~= nil ) then
								if ( GetAdjacentTiles(plot, 5*i+60):IsImpassable() == false and GetAdjacentTiles(plot, 5*i+60):IsWater() == false  ) then
									-- Ok there is land let measure the distance to dig through
									if ( GetAdjacentTiles(plot, 2*i+6) ~= nil and GetAdjacentTiles(plot, 3*i+18) ~= nil and GetAdjacentTiles(plot, 4*i+36) ~= nil) then
										if ( GetAdjacentTiles(plot, 2*i+6):IsImpassable() == true) then
											distance = 2;
											else
											distance = 1;
										end
										if ( GetAdjacentTiles(plot, 3*i+18):IsImpassable() == true) then
											distance = distance + 1;
										end
										if ( GetAdjacentTiles(plot, 4*i+36):IsImpassable() == true) then
											distance = distance + 1;
										end
										__Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "Distance to dig is", distance);
										if (distance < min_distance) then
											min_distance = distance;
											minimal_effort_i = i;
										end
									end
									else
									__Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "No good Terrain on the other side");
								end
								else
								__Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "No Terrain on the other side");
							end
							else
							__Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "Can move around the Mountain");
						end
					end
					elseif (i == 5) then
					if ( GetAdjacentTiles(plot, i-1) ~= nil and GetAdjacentTiles(plot, 0) ~= nil ) then
						if ( GetAdjacentTiles(plot, i-1):IsImpassable() == true and GetAdjacentTiles(plot, 0):IsImpassable() == true ) then
							-- Walled-in is there actual terrain on the other side ?
							if ( GetAdjacentTiles(plot, 5*i+60) ~= nil ) then
								if ( GetAdjacentTiles(plot, 5*i+60):IsImpassable() == false and GetAdjacentTiles(plot, 5*i+60):IsWater() == false  ) then
									-- Ok there is land let measure the distance to dig through
									if ( GetAdjacentTiles(plot, 2*i+6) ~= nil and GetAdjacentTiles(plot, 3*i+18) ~= nil and GetAdjacentTiles(plot, 4*i+36) ~= nil) then
										if ( GetAdjacentTiles(plot, 2*i+6):IsImpassable() == true) then
											distance = 2;
											else
											distance = 1;
										end
										if ( GetAdjacentTiles(plot, 3*i+18):IsImpassable() == true) then
											distance = distance + 1;
										end
										if ( GetAdjacentTiles(plot, 4*i+36):IsImpassable() == true) then
											distance = distance + 1;
										end
										__Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "Distance to dig is", distance);
										if (distance < min_distance) then
											min_distance = distance;
											minimal_effort_i = i;
										end
									end
									else
									__Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "No good Terrain on the other side");
								end
								else
								__Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "No Terrain on the other side");
							end
							else
							__Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "Can move around the Mountain");
						end
					end
				end
				else
				-- one tile away wall
				if (GetAdjacentTiles(plot, 2*i+6) ~= nil) then
					__Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, 2*i+6):GetX(), "Y: ", GetAdjacentTiles(plot, 2*i+6):GetY(), "Analysing the plot");
					if ( GetAdjacentTiles(plot, 2*i+6):IsImpassable() == true ) then
						if (i == 0) then
							if ( GetAdjacentTiles(plot, 17) ~= nil and GetAdjacentTiles(plot, 2*i+6+1) ~= nil ) then
								if ( GetAdjacentTiles(plot, 17):IsImpassable() == true and GetAdjacentTiles(plot, 2*i+1+6):IsImpassable() == true ) then
								-- Walled-in is there actual terrain on the other side ?
									if ( GetAdjacentTiles(plot, 5*i+60) ~= nil ) then
										if ( GetAdjacentTiles(plot, 5*i+60):IsImpassable() == false and GetAdjacentTiles(plot, 5*i+60):IsWater() == false  ) then
										-- Ok there is land let measure the distance to dig through
											if ( GetAdjacentTiles(plot, 3*i+18) ~= nil and GetAdjacentTiles(plot, 4*i+36) ~= nil) then
												if ( GetAdjacentTiles(plot, 3*i+18):IsImpassable() == true) then
													distance = 1;
													else
													distance = 0;
												end
												if ( GetAdjacentTiles(plot, 4*i+36):IsImpassable() == true) then
													distance = distance + 1;
												end
												__Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "Distance to dig is", distance)
												if (distance < min_distance) then
													min_distance = distance;
													minimal_effort_i = i;
												end
											end
											else
											__Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "No good Terrain on the other side");

										end
										else
										__Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "No Terrain on the other side");
									end
									else
									__Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, 2*i+6):GetX(), "Y: ", GetAdjacentTiles(plot, 2*i+6):GetY(), "Can move around the Mountain");
								end
							end
						elseif (i>0) then
							if ( GetAdjacentTiles(plot, 2*i+6-1) ~= nil and GetAdjacentTiles(plot, 2*i+1+6) ~= nil ) then
								if ( GetAdjacentTiles(plot, 2*i+6-1):IsImpassable() == true and GetAdjacentTiles(plot, 2*i+1+6):IsImpassable() == true ) then
								-- Walled-in is there actual terrain on the other side ?
									if ( GetAdjacentTiles(plot, 5*i+60) ~= nil ) then
										if ( GetAdjacentTiles(plot, 5*i+60):IsImpassable() == false and GetAdjacentTiles(plot, 5*i+60):IsWater() == false  ) then
										-- Ok there is land let measure the distance to dig through
											if ( GetAdjacentTiles(plot, 3*i+18) ~= nil and GetAdjacentTiles(plot, 4*i+36) ~= nil) then
												if ( GetAdjacentTiles(plot, 3*i+18):IsImpassable() == true) then
													distance = 1;
													else
													distance = 0;
												end
												if ( GetAdjacentTiles(plot, 4*i+36):IsImpassable() == true) then
													distance = distance + 1;
												end
												__Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "Distance to dig is", distance)
												if (distance < min_distance) then
													min_distance = distance;
													minimal_effort_i = i;
												end
											end
											else
											__Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "No good Terrain on the other side");

										end
										else
										__Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "No Terrain on the other side");
									end
									else
									__Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, 2*i+6):GetX(), "Y: ", GetAdjacentTiles(plot, 2*i+6):GetY(), "Can move around the Mountain");
								end
							end
						end
					end

				end
			end	
		end
	end
	if (minimal_effort_i ~= nil) then
		__Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, minimal_effort_i):GetX(), "Y: ", GetAdjacentTiles(plot, minimal_effort_i):GetY(), "Digging an openning");
		if (GetAdjacentTiles(plot, minimal_effort_i) ~= nil and GetAdjacentTiles(plot, 2*minimal_effort_i+6) ~= nil and GetAdjacentTiles(plot, 3*minimal_effort_i+18) ~= nil and GetAdjacentTiles(plot, 4*minimal_effort_i+36) ~= nil) then
			adjacentPlot = GetAdjacentTiles(plot, minimal_effort_i);
			adjacentPlot2 = GetAdjacentTiles(plot, 2*minimal_effort_i+6);
			adjacentPlot3 = GetAdjacentTiles(plot, 3*minimal_effort_i+18);
			adjacentPlot4 = GetAdjacentTiles(plot, 4*minimal_effort_i+36);
			if (adjacentPlot:IsImpassable() == true and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO) then
				TerrainBuilder.SetTerrainType(adjacentPlot,adjacentPlot:GetTerrainType()-1)
				TerrainBuilder.SetFeatureType(adjacentPlot,-1)
				rng = TerrainBuilder.GetRandomNumber(100,"test")/100
				if rng > 0.75 then
					TerrainBuilder.SetFeatureType(adjacentPlot,3)
				end
				__Debug("Terraforming_Mountain X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "turn Mountain into a Hill");
			end
			if (adjacentPlot2:IsImpassable() == true and adjacentPlot2:GetFeatureType() ~= g_FEATURE_VOLCANO) then
				TerrainBuilder.SetTerrainType(adjacentPlot2,adjacentPlot2:GetTerrainType()-1)
				TerrainBuilder.SetFeatureType(adjacentPlot2,-1)
				rng = TerrainBuilder.GetRandomNumber(100,"test")/100
				if rng > 0.75 then
					TerrainBuilder.SetFeatureType(adjacentPlot2,3)
				end
				__Debug("Terraforming_Mountain X: ", adjacentPlot2:GetX(), "Y: ", adjacentPlot2:GetY(), "turn Mountain into a Hill");
			end
			if (adjacentPlot3:IsImpassable() == true and adjacentPlot3:GetFeatureType() ~= g_FEATURE_VOLCANO) then
				TerrainBuilder.SetTerrainType(adjacentPlot3,adjacentPlot3:GetTerrainType()-1)
				TerrainBuilder.SetFeatureType(adjacentPlot3,-1)
				rng = TerrainBuilder.GetRandomNumber(100,"test")/100
				if rng > 0.75 then
					TerrainBuilder.SetFeatureType(adjacentPlot3,3)
				end
				__Debug("Terraforming_Mountain X: ", adjacentPlot3:GetX(), "Y: ", adjacentPlot3:GetY(), "turn Mountain into a Hill");
			end
			if (adjacentPlot4:IsImpassable() == true and adjacentPlot4:GetFeatureType() ~= g_FEATURE_VOLCANO) then
				TerrainBuilder.SetTerrainType(adjacentPlot4,adjacentPlot4:GetTerrainType()-1)
				TerrainBuilder.SetFeatureType(adjacentPlot4,-1)
				rng = TerrainBuilder.GetRandomNumber(100,"test")/100
				if rng > 0.75 then
					TerrainBuilder.SetFeatureType(adjacentPlot4,3)
				end
				__Debug("Terraforming_Mountain X: ", adjacentPlot4:GetX(), "Y: ", adjacentPlot4:GetY(), "turn Mountain into a Hill");
			end

		end
	end

end


------------------------------------------------------------------------------

function Terraforming_Polar_Start(plot)
	-- flag = 0 normal
	-- flag = 1 tundra civ
	-- flag = 2 desert civ
	-- flag = 3 mountain civ
	local terrainType = plot:GetTerrainType();
	local featureType = plot:GetFeatureType();
	local gridWidth, gridHeight = Map.GetGridSize();
	local ContinentNum = nil;
	local ContinentPlots = {};

	ContinentNum = plot:GetContinentType()
	ContinentPlots =  Map.GetContinentPlots(ContinentNum);
	__Debug("Terraforming Polar Continent",ContinentNum);

	--------------------------------------------------------------------------------------------------------------
	-- Terraforming Polar Start ----------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------
		
	for i, plot in ipairs(ContinentPlots) do
		if plot ~= nil then
			local pPlot = Map.GetPlotByIndex(plot)
			local terrainType = pPlot:GetTerrainType();
			local featureType = pPlot:GetFeatureType();

			-- Let Tundra warm to Plains

			if (terrainType == 9 or terrainType == 10 or terrainType == 11) then
				TerrainBuilder.SetTerrainType(pPlot,terrainType - 6);
				if (pPlot:GetResourceCount() > 0 ) then
					local resourceType = pPlot:GetResourceType();
					if (resourceType == 45) then
						-- Oil requires a Marsh to spawn on Plains
						TerrainBuilder.SetFeatureType(pPlot,-1);
						TerrainBuilder.SetFeatureType(pPlot,5);
						elseif (resourceType == 16) then
						-- Fur requires a Wood to spawn on Plains
						TerrainBuilder.SetFeatureType(pPlot,-1);
						TerrainBuilder.SetFeatureType(pPlot,3);
						elseif (resourceType == 26) then
						-- Silver cannot spawn on Plains
						ResourceBuilder.SetResourceType(pPlot,-1);
						TerrainBuilder.SetFeatureType(pPlot,3);
						elseif (resourceType == 4) then
						-- Deer requires Wood
						TerrainBuilder.SetFeatureType(pPlot,-1);
						TerrainBuilder.SetFeatureType(pPlot,3);
					end
				end
			end

			-- Let Snow warm to Tundra

			if (terrainType == 12 or terrainType == 13 or terrainType == 14) then
				TerrainBuilder.SetTerrainType(pPlot,terrainType - 3);
			end		
			
		end
	end

	-- Removing the Ice

	for i = 0, 90 do
		adjacentPlot = GetAdjacentTiles(plot, i)
		rng = TerrainBuilder.GetRandomNumber(100,"test")/100
		if (adjacentPlot ~= nil) then
			if (adjacentPlot:GetFeatureType() == 1 and rng > 0.1) then
				__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Removing Ice",i);
				TerrainBuilder.SetFeatureType(adjacentPlot,-1);
			end
		end
	end

end

------------------------------------------------------------------------------

------------------------------------------------------------------------------

function Terraforming_Best(plot, avg_best, avg_best_2, missing_amount, flag)
	-- flag = 0 normal
	-- flag = 1 tundra civ
	-- flag = 2 desert civ
	-- flag = 3 mountain civ
	-- flag = 4 floodplains civ
	local iResourcesInDB = 0;
	local terrainType = plot:GetTerrainType();
	local featureType = plot:GetFeatureType();
	local gridWidth, gridHeight = Map.GetGridSize();
	local direction = 0;
	local bTerraform = true;
	local temp_tile = 0;
	local best_tile = 0;
	local valid_target_1 = nil;
	local valid_target_2 = nil;
	local second_best_tile = 0;
	local best_plot = nil;
	local best_plot_2 = nil;
	local adjacentPlot = nil;
	local bCulture = false;
	local bFaith = false;
	local adjust = 0;


	--------------------------------------------------------------------------------------------------------------
	-- Step: 0: Figuring out where are the best tiles ------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------

	for i = 0, 5 do
		adjacentPlot = GetAdjacentTiles(plot, i)
		if (adjacentPlot ~= nil and adjacentPlot:IsWater() == false) then
			terrainType = adjacentPlot:GetTerrainType();
			temp_tile = 0;
			temp_tile = adjacentPlot:GetYield(g_YIELD_FOOD) + adjacentPlot:GetYield(g_YIELD_PRODUCTION) * 1.5 + adjacentPlot:GetYield(g_YIELD_GOLD) * 0.5;

					-- Adjust for non discovered resources
			if(adjacentPlot:GetResourceCount() > 0) then
				if (adjacentPlot:GetResourceType() == 41 or adjacentPlot:GetResourceType() == 46) then
					temp_tile = temp_tile - 2 * 1.5
					elseif (adjacentPlot:GetResourceType() == 42 or adjacentPlot:GetResourceType() == 44) then
					temp_tile = temp_tile - 1 * 1.5 - 1 
					elseif (adjacentPlot:GetResourceType() == 45) then
					temp_tile = temp_tile - 3 * 1.5
					else
					if (adjacentPlot:GetResourceType() < 10 and (valid_target_1 == nil or valid_target_2 == nil)) then 
						if (valid_target_1 == nil) then
							valid_target_1 = i;
							else
							valid_target_2 = i
						end
						else
						if (adjacentPlot:GetResourceType() < 40 and (valid_target_1 == nil or valid_target_2 == nil)) then 
							if (valid_target_1 == nil) then
								valid_target_1 = i;
								else
								valid_target_2 = i
							end
						end
					end
				end
				else
				if (valid_target_1 == nil or valid_target_2 == nil) then
					if (valid_target_1 == nil) then
						valid_target_1 = i;
						else
						valid_target_2 = i
					end
					else
					valid_target_1 = i;
				end
			end

			bCulture = false;
			bFaith = false;


			if(adjacentPlot:GetResourceCount() > 0) then
				-- Check for Coffee, Jade, Marble, Incense, dyes and clams
				if (adjacentPlot:GetResourceType() == 12 or adjacentPlot:GetResourceType() == 20 or adjacentPlot:GetResourceType() == 21) then
					bCulture = true;
					elseif (adjacentPlot:GetResourceType() == 15 or adjacentPlot:GetResourceType() == 18 or adjacentPlot:GetResourceType() == 23) then
					bFaith = true;
				end
			end


			if bCulture == true then
				temp_tile = temp_tile + 2;
			end
			if bFaith == true then
				temp_tile = temp_tile + 1.5;
			end


			if (temp_tile > best_tile or temp_tile == best_tile) then
				second_best_tile = best_tile;
				best_plot_2 = best_plot;
				best_tile = temp_tile;
				best_plot = i;
				else
				if (temp_tile > second_best_tile and temp_tile < best_tile) then
					second_best_tile = temp_tile
					best_plot_2 = i
				end
			end
			temp_tile = 0	
		end
	end	

	--------------------------------------------------------------------------------------------------------------
	-- Step: 1: Rebalancing Best Plot ----------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------

	
	if ( valid_target_1 ~= nil) then
		target_plot_1 = GetAdjacentTiles(plot, valid_target_1)
		if ( target_plot_1 == nil) then
			__Debug("Terraforming Best: No Valid Target 1 plot");
			return
			else
			if (target_plot_1:GetResourceType() > 39 and target_plot_1:GetResourceType() < 46) then
				__Debug("Terraforming Best: No Valid Target 1 plot: Preserve Strategic Resource");
				return
			end
		end
		if ( valid_target_1 == best_plot or valid_target_1 == best_plot_2 ) then
			adjust = 0
			else
			adjust = -1
		end
		if ( avg_best > 4.75 + adjust and avg_best < 5.25 + adjust) then	
		-- On average player have a 2/2 tile
		-- Player doesn't have a 2/2 tile
			
				target_plot_1 = GetAdjacentTiles(plot, valid_target_1)
				-- Grassland
				if ( target_plot_1:GetTerrainType() == 0 or target_plot_1:GetTerrainType() == 1 or (target_plot_1:GetTerrainType() == 2 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO) ) then
					if ( target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND or ( target_plot_1:GetFeatureType() == g_FEATURE_FLOODPLAINS_GRASSLAND and flag ~= 4) ) then
					-- +5 on Grassland		
					rng = TerrainBuilder.GetRandomNumber(100,"test")/100
						if (rng >= 0.75) then
							-- Forested Hill
							TerrainBuilder.SetTerrainType(target_plot_1,1);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							TerrainBuilder.SetFeatureType(target_plot_1,3);
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Forested Grassland Hill");
							elseif (rng >= 0.5 and rng < 0.75) then
							-- Flat Deer Forest
							TerrainBuilder.SetTerrainType(target_plot_1,0);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							TerrainBuilder.SetFeatureType(target_plot_1,3);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 4, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Grassland Forest with Deers");
							elseif (rng >= 0.2 and rng < 0.5) then
							-- Stone Hill
							TerrainBuilder.SetTerrainType(target_plot_1,1);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 8, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Stone Grassland Hill");
							elseif (rng >= 0.0 and rng < 0.2) then
							-- Copper Hill
							TerrainBuilder.SetTerrainType(target_plot_1,1);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/1/2 Copper Grassland Hill");
						end
						else
						-- floodplains and floodplains Civs
						if (target_plot_1:GetResourceCount() < 1) then
							ResourceBuilder.SetResourceType(target_plot_1, 6, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/0 Rice Grassland Floodplains");
						end
					end
				-- Plains
				elseif ( target_plot_1:GetTerrainType() == 3 or target_plot_1:GetTerrainType() == 4 or (target_plot_1:GetTerrainType() == 5 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
					if ( target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS or ( target_plot_1:GetFeatureType() == g_FEATURE_FLOODPLAINS_PLAINS and flag ~= 4) ) then
					-- +5 on Plains		
					rng = TerrainBuilder.GetRandomNumber(100,"test")/100
						if (rng >= 0.75) then
							-- Hill with Sheep
							TerrainBuilder.SetTerrainType(target_plot_1,4);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Sheep Plain Hill");
							elseif (rng >= 0.25 and rng < 0.75) then
							-- Copper Plain Hill
							TerrainBuilder.SetTerrainType(target_plot_1,4);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/2/2 Copper Plain Hill");
							elseif (rng >= 0.0 and rng < 0.25) then
								if (target_plot_1:GetY() > gridHeight * 0.25 and target_plot_1:GetY() < gridHeight * 0.75) then
								-- Jungle Plain Hill
									TerrainBuilder.SetTerrainType(target_plot_1,4);
									TerrainBuilder.SetFeatureType(target_plot_1,-1);
									ResourceBuilder.SetResourceType(target_plot_1, -1);
									TerrainBuilder.SetFeatureType(target_plot_1,2);
									__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Jungle Plain Hill");
									else
									-- Hill with Sheep
									TerrainBuilder.SetTerrainType(target_plot_1,4);
									TerrainBuilder.SetFeatureType(target_plot_1,-1);
									ResourceBuilder.SetResourceType(target_plot_1, -1);
									ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
									__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Sheep Plain Hill");
								end
						end
						else
						-- floodplains and floodplains Civs
						if (target_plot_1:GetResourceCount() < 1 and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
							ResourceBuilder.SetResourceType(target_plot_1, 9, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/0 Wheat Plains Floodplains");
						end
					end
				-- Desert
				elseif ( target_plot_1:GetTerrainType() == 6 or target_plot_1:GetTerrainType() == 7 or (target_plot_1:GetTerrainType() == 8 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
					if ( target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
					-- +5 on Desert -> impossible	
					rng = TerrainBuilder.GetRandomNumber(100,"test")/100
						if (rng >= 0.5) then
							-- Hill with Sheep
							TerrainBuilder.SetTerrainType(target_plot_1,7);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/1 Sheep Desert Hill");
							elseif (rng >= 0.0 and rng < 0.5) then
							-- Copper Hill
							TerrainBuilder.SetTerrainType(target_plot_1,7);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Copper Desert Hill");
						end
						else
						-- floodplains
						if (target_plot_1:GetResourceCount() < 1 and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
							ResourceBuilder.SetResourceType(target_plot_1, 9, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/0 Wheat Desert Floodplains");
						end
					end
				-- Tundra
				elseif ( target_plot_1:GetTerrainType() == 9 or target_plot_1:GetTerrainType() == 10 or (target_plot_1:GetTerrainType() == 11 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
					if ( target_plot_1:GetFeatureType() ~= g_FEATURE_MARSH) then
					-- +5 on Tundra -> impossible	
					rng = TerrainBuilder.GetRandomNumber(100,"test")/100
						if (rng >= 0.75) then
							-- Hill with Sheep
							TerrainBuilder.SetTerrainType(target_plot_1,10);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/1 Sheep Tundra Hill");
							elseif (rng >= 0.2 and rng < 0.75) then
							-- Copper Hill
							TerrainBuilder.SetTerrainType(target_plot_1,10);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Copper Tundra Hill");
							elseif (rng >= 0.0 and rng < 0.2) then
							-- Forested Deer
							TerrainBuilder.SetTerrainType(target_plot_1,10);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							TerrainBuilder.SetFeatureType(target_plot_1,3);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 4, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Deer Tundra Hill");
						end
					end
				end
			
		elseif ( avg_best > 5.5 + adjust ) then

				target_plot_1 = GetAdjacentTiles(plot, valid_target_1)
				
				-- Grassland
				if ( target_plot_1:GetTerrainType() == 0 or target_plot_1:GetTerrainType() == 1 or (target_plot_1:GetTerrainType() == 2 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO) ) then
					if ( target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND or ( target_plot_1:GetFeatureType() == g_FEATURE_FLOODPLAINS_GRASSLAND and flag ~= 4) ) then
					-- +5.5 on Grassland	
					rng = TerrainBuilder.GetRandomNumber(100,"test")/100	
						if (rng >= 0) then
							-- Forested Hill with deer
							TerrainBuilder.SetTerrainType(target_plot_1,1);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 4, 1)
							TerrainBuilder.SetFeatureType(target_plot_1,3);
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/3 Forested Deer Grassland Hill");

						end
						else
						-- floodplains and floodplains Civs
						if (target_plot_1:GetResourceCount() < 1) then
							ResourceBuilder.SetResourceType(target_plot_1, 6, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/0 Rice Grassland Floodplains");
						end
					end
				-- Plains
				elseif ( target_plot_1:GetTerrainType() == 3 or target_plot_1:GetTerrainType() == 4 or (target_plot_1:GetTerrainType() == 5 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
					if ( target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS or ( target_plot_1:GetFeatureType() == g_FEATURE_FLOODPLAINS_PLAINS and flag ~= 4) ) then
					-- +5.5 on Plains		
					rng = TerrainBuilder.GetRandomNumber(100,"test")/100
						if (rng >= 0.9) then
							-- Forested Hill with Deer
							TerrainBuilder.SetTerrainType(target_plot_1,4);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							TerrainBuilder.SetFeatureType(target_plot_1,3);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 4, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/4 Forested Plain Hill with Deer");
							elseif (rng >= 0.5 and rng < 0.9) then
							-- Forested Plain Hill
							TerrainBuilder.SetTerrainType(target_plot_1,4);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							TerrainBuilder.SetFeatureType(target_plot_1,3);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/3 Forested Plain Hill");
							elseif (rng >= 0 and rng < 0.5) then
							-- Banana Jungle Hill
								if (target_plot_1:GetY() > gridHeight * 0.25 and target_plot_1:GetY() < gridHeight * 0.75) then
									TerrainBuilder.SetTerrainType(target_plot_1,4);
									TerrainBuilder.SetFeatureType(target_plot_1,-1);
									ResourceBuilder.SetResourceType(target_plot_1, -1);
									ResourceBuilder.SetResourceType(target_plot_1, 0, 1);
									TerrainBuilder.SetFeatureType(target_plot_1,2);
									__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/2 Jungle Plain Hill with Banana");
									else
									-- Forested Plain Hill
									TerrainBuilder.SetTerrainType(target_plot_1,4);
									TerrainBuilder.SetFeatureType(target_plot_1,-1);
									TerrainBuilder.SetFeatureType(target_plot_1,3);
									ResourceBuilder.SetResourceType(target_plot_1, -1);
									__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/3 Forested Plain Hill");
								end

						end
						else
						-- floodplains and floodplains Civs
						if (target_plot_1:GetResourceCount() < 1 and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
							ResourceBuilder.SetResourceType(target_plot_1, 9, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/0 Wheat Plains Floodplains");
						end
					end
				-- Desert
				elseif ( target_plot_1:GetTerrainType() == 6 or target_plot_1:GetTerrainType() == 7 or (target_plot_1:GetTerrainType() == 8 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
					if ( target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
					-- on Desert -> impossible	
					rng = TerrainBuilder.GetRandomNumber(100,"test")/100
						if (rng >= 0.5) then
							-- Hill with Sheep
							TerrainBuilder.SetTerrainType(target_plot_1,7);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/1 Sheep Desert Hill");
							elseif (rng >= 0.0 and rng < 0.5) then
							-- Copper Hill
							TerrainBuilder.SetTerrainType(target_plot_1,7);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Copper Desert Hill");
						end
						else
						-- floodplains
						if (target_plot_1:GetResourceCount() < 1 and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
							ResourceBuilder.SetResourceType(target_plot_1, 9, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/0 Wheat Desert Floodplains");
						end
					end
				-- Tundra
				elseif ( target_plot_1:GetTerrainType() == 9 or target_plot_1:GetTerrainType() == 10 or (target_plot_1:GetTerrainType() == 11 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
					if ( target_plot_1:GetFeatureType() ~= g_FEATURE_MARSH) then
					-- +5 on Tundra -> impossible	
					rng = TerrainBuilder.GetRandomNumber(100,"test")/100
						if (rng >= 0.75) then
							-- Hill with Sheep
							TerrainBuilder.SetTerrainType(target_plot_1,10);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/1 Sheep Tundra Hill");
							elseif (rng >= 0.5 and rng < 0.75) then
							-- Copper Hill
							TerrainBuilder.SetTerrainType(target_plot_1,10);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Copper Tundra Hill");
							elseif (rng >= 0.0 and rng < 0.5) then
							-- Forested Deer
							TerrainBuilder.SetTerrainType(target_plot_1,10);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							TerrainBuilder.SetFeatureType(target_plot_1,3);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 4, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Deer Tundra Hill");
						end
					end


		elseif ( avg_best > 4.25 + adjust and avg_best < 4.75 + adjust) then
				-- 3/1

				target_plot_1 = GetAdjacentTiles(plot, valid_target_1)
				-- Grassland
				if ( target_plot_1:GetTerrainType() == 0 or target_plot_1:GetTerrainType() == 1 or (target_plot_1:GetTerrainType() == 2 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO) ) then
					if ( target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND or ( target_plot_1:GetFeatureType() == g_FEATURE_FLOODPLAINS_GRASSLAND and flag ~= 4) ) then
					-- +4.5 on Grassland	
					rng = TerrainBuilder.GetRandomNumber(100,"test")/100	
						if (rng >= 0) then
							-- Hill with Sheep
							TerrainBuilder.SetTerrainType(target_plot_1,1);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 7, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/1 Sheep Grassland Hill");

						end
						else
						-- floodplains and floodplains Civs
						if (target_plot_1:GetResourceCount() < 1) then
							ResourceBuilder.SetResourceType(target_plot_1, 6, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/0 Rice Grassland Floodplains");
						end
					end
				-- Plains
				elseif ( target_plot_1:GetTerrainType() == 3 or target_plot_1:GetTerrainType() == 4 or (target_plot_1:GetTerrainType() == 5 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
					if ( target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS or ( target_plot_1:GetFeatureType() == g_FEATURE_FLOODPLAINS_PLAINS and flag ~= 4) ) then
					-- +4.5 on Plains		
					rng = TerrainBuilder.GetRandomNumber(100,"test")/100
						if (rng >= 0.0) then
							-- Banana Jungle Hill
								if (target_plot_1:GetY() > gridHeight * 0.25 and target_plot_1:GetY() < gridHeight * 0.75) then
									TerrainBuilder.SetTerrainType(target_plot_1,3);
									TerrainBuilder.SetFeatureType(target_plot_1,-1);
									ResourceBuilder.SetResourceType(target_plot_1, -1);
									ResourceBuilder.SetResourceType(target_plot_1,0, 1);
									TerrainBuilder.SetFeatureType(target_plot_1,2);
									__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/1 Jungle Plain with Banana");
									else
									-- Forested Plain Hill
									TerrainBuilder.SetTerrainType(target_plot_1,3);
									TerrainBuilder.SetFeatureType(target_plot_1,-1);
									TerrainBuilder.SetFeatureType(target_plot_1,3);
									ResourceBuilder.SetResourceType(target_plot_1, -1);
									ResourceBuilder.SetResourceType(target_plot_1, 4, 1);
									__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Forested Plain with Deer");
								end

						end
						else
						-- floodplains and floodplains Civs
						if (target_plot_1:GetResourceCount() < 1 and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
							ResourceBuilder.SetResourceType(target_plot_1, 9, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/0 Wheat Plains Floodplains");
						end
					end
				-- Desert
				elseif ( target_plot_1:GetTerrainType() == 6 or target_plot_1:GetTerrainType() == 7 or (target_plot_1:GetTerrainType() == 8 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
					if ( target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
					-- on Desert -> impossible	
					rng = TerrainBuilder.GetRandomNumber(100,"test")/100
						if (rng >= 0.5) then
							-- Hill with Sheep
							TerrainBuilder.SetTerrainType(target_plot_1,7);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/1 Sheep Desert Hill");
							elseif (rng >= 0.0 and rng < 0.5) then
							-- Copper Hill
							TerrainBuilder.SetTerrainType(target_plot_1,7);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Copper Desert Hill");
						end
						else
						-- floodplains
						if (target_plot_1:GetResourceCount() < 1 and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
							ResourceBuilder.SetResourceType(target_plot_1, 9, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/0 Wheat Desert Floodplains");
						end
					end
				-- Tundra
				elseif ( target_plot_1:GetTerrainType() == 9 or target_plot_1:GetTerrainType() == 10 or (target_plot_1:GetTerrainType() == 11 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
					if ( target_plot_1:GetFeatureType() ~= g_FEATURE_MARSH) then
					-- +5 on Tundra -> impossible	
					rng = TerrainBuilder.GetRandomNumber(100,"test")/100
						if (rng >= 0.66) then
							-- Hill with Sheep
							TerrainBuilder.SetTerrainType(target_plot_1,10);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/1 Sheep Tundra Hill");
							elseif (rng >= 0.1 and rng < 0.66) then
							-- Copper Hill
							TerrainBuilder.SetTerrainType(target_plot_1,10);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Copper Tundra Hill");
							elseif (rng >= 0.0 and rng < 0.1) then
							-- Forested Deer
							TerrainBuilder.SetTerrainType(target_plot_1,10);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							TerrainBuilder.SetFeatureType(target_plot_1,3);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 4, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Deer Tundra Hill");
						end
					end


				end
			end
		end
	end

	--------------------------------------------------------------------------------------------------------------
	-- Step: 2: Rebalancing Second Best Plot ---------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------

	
	if ( valid_target_2 ~= nil) then
		target_plot_1 = GetAdjacentTiles(plot, valid_target_2)
		if ( target_plot_1 == nil) then
			__Debug("Terraforming Best: No Valid Target 2 plot");
			return
			else
			if (target_plot_1:GetResourceType() > 39 and target_plot_1:GetResourceType() < 46) then
				__Debug("Terraforming Best: No Valid Target 2 plot: Preserve Strategic Resource");
				return
			end
		end
		if ( valid_target_2 == best_plot or valid_target_2 == best_plot_2 ) then
			adjust = 0
			else
			adjust = -1
		end
		
		if ( avg_best_2 > 4.75 + adjust and avg_best_2 < 5.25 + adjust) then	
		-- On average player have a 2/2 tile
		-- Player doesn't have a 2/2 tile
			
				target_plot_1 = GetAdjacentTiles(plot, valid_target_2)
				-- Grassland
				if ( target_plot_1:GetTerrainType() == 0 or target_plot_1:GetTerrainType() == 1 or (target_plot_1:GetTerrainType() == 2 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO) ) then
					if ( target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND or ( target_plot_1:GetFeatureType() == g_FEATURE_FLOODPLAINS_GRASSLAND and flag ~= 4) ) then
					-- +5 on Grassland		
					rng = TerrainBuilder.GetRandomNumber(100,"test")/100
						if (rng >= 0.75) then
							-- Forested Hill
							TerrainBuilder.SetTerrainType(target_plot_1,1);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							TerrainBuilder.SetFeatureType(target_plot_1,3);
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Forested Grassland Hill");
							elseif (rng >= 0.5 and rng < 0.75) then
							-- Flat Deer Forest
							TerrainBuilder.SetTerrainType(target_plot_1,0);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							TerrainBuilder.SetFeatureType(target_plot_1,3);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 4, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Grassland Forest with Deers");
							elseif (rng >= 0.2 and rng < 0.5) then
							-- Stone Hill
							TerrainBuilder.SetTerrainType(target_plot_1,1);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 8, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Stone Grassland Hill");
							elseif (rng >= 0.0 and rng < 0.2) then
							-- Copper Hill
							TerrainBuilder.SetTerrainType(target_plot_1,1);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/1/2 Copper Grassland Hill");
						end
						else
						-- floodplains and floodplains Civs
						if (target_plot_1:GetResourceCount() < 1) then
							ResourceBuilder.SetResourceType(target_plot_1, 6, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/0 Rice Grassland Floodplains");
						end
					end
				-- Plains
				elseif ( target_plot_1:GetTerrainType() == 3 or target_plot_1:GetTerrainType() == 4 or (target_plot_1:GetTerrainType() == 5 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
					if ( target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS or ( target_plot_1:GetFeatureType() == g_FEATURE_FLOODPLAINS_PLAINS and flag ~= 4) ) then
					-- +5 on Plains		
					rng = TerrainBuilder.GetRandomNumber(100,"test")/100
						if (rng >= 0.75) then
							-- Hill with Sheep
							TerrainBuilder.SetTerrainType(target_plot_1,4);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Sheep Plain Hill");
							elseif (rng >= 0.25 and rng < 0.75) then
							-- Copper Plain Hill
							TerrainBuilder.SetTerrainType(target_plot_1,4);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/2/2 Copper Plain Hill");
							elseif (rng >= 0.0 and rng < 0.25) then
								if (target_plot_1:GetY() > gridHeight * 0.25 and target_plot_1:GetY() < gridHeight * 0.75) then
								-- Jungle Plain Hill
									TerrainBuilder.SetTerrainType(target_plot_1,4);
									TerrainBuilder.SetFeatureType(target_plot_1,-1);
									ResourceBuilder.SetResourceType(target_plot_1, -1);
									TerrainBuilder.SetFeatureType(target_plot_1,2);
									__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Jungle Plain Hill");
									else
									-- Hill with Sheep
									TerrainBuilder.SetTerrainType(target_plot_1,4);
									TerrainBuilder.SetFeatureType(target_plot_1,-1);
									ResourceBuilder.SetResourceType(target_plot_1, -1);
									ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
									__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Sheep Plain Hill");
								end
						end
						else
						-- floodplains and floodplains Civs
						if (target_plot_1:GetResourceCount() < 1 and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
							ResourceBuilder.SetResourceType(target_plot_1, 9, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/0 Wheat Plains Floodplains");
						end
					end
				-- Desert
				elseif ( target_plot_1:GetTerrainType() == 6 or target_plot_1:GetTerrainType() == 7 or (target_plot_1:GetTerrainType() == 8 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
					if ( target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
					-- +5 on Desert -> impossible	
					rng = TerrainBuilder.GetRandomNumber(100,"test")/100
						if (rng >= 0.5) then
							-- Hill with Sheep
							TerrainBuilder.SetTerrainType(target_plot_1,7);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/1 Sheep Desert Hill");
							elseif (rng >= 0.0 and rng < 0.5) then
							-- Copper Hill
							TerrainBuilder.SetTerrainType(target_plot_1,7);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Copper Desert Hill");
						end
						else
						-- floodplains
						if (target_plot_1:GetResourceCount() < 1 and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
							ResourceBuilder.SetResourceType(target_plot_1, 9, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/0 Wheat Desert Floodplains");
						end
					end
				-- Tundra
				elseif ( target_plot_1:GetTerrainType() == 9 or target_plot_1:GetTerrainType() == 10 or (target_plot_1:GetTerrainType() == 11 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
					if ( target_plot_1:GetFeatureType() ~= g_FEATURE_MARSH) then
					-- +5 on Tundra -> impossible	
					rng = TerrainBuilder.GetRandomNumber(100,"test")/100
						if (rng >= 0.75) then
							-- Hill with Sheep
							TerrainBuilder.SetTerrainType(target_plot_1,10);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/1 Sheep Tundra Hill");
							elseif (rng >= 0.2 and rng < 0.75) then
							-- Copper Hill
							TerrainBuilder.SetTerrainType(target_plot_1,10);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Copper Tundra Hill");
							elseif (rng >= 0.0 and rng < 0.2) then
							-- Forested Deer
							TerrainBuilder.SetTerrainType(target_plot_1,10);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							TerrainBuilder.SetFeatureType(target_plot_1,3);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 4, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Deer Tundra Hill");
						end
					end
				end
			
		elseif ( avg_best_2 > 5.5 + adjust ) then

				target_plot_1 = GetAdjacentTiles(plot, valid_target_2)
				-- Grassland
				if ( target_plot_1:GetTerrainType() == 0 or target_plot_1:GetTerrainType() == 1 or (target_plot_1:GetTerrainType() == 2 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO) ) then
					if ( target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND or ( target_plot_1:GetFeatureType() == g_FEATURE_FLOODPLAINS_GRASSLAND and flag ~= 4) ) then
					-- +5.5 on Grassland	
					rng = TerrainBuilder.GetRandomNumber(100,"test")/100	
						if (rng >= 0) then
							-- Forested Hill with deer
							TerrainBuilder.SetTerrainType(target_plot_1,1);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 4, 1)
							TerrainBuilder.SetFeatureType(target_plot_1,3);
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/3 Forested Deer Grassland Hill");

						end
						else
						-- floodplains and floodplains Civs
						if (target_plot_1:GetResourceCount() < 1) then
							ResourceBuilder.SetResourceType(target_plot_1, 6, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/0 Rice Grassland Floodplains");
						end
					end
				-- Plains
				elseif ( target_plot_1:GetTerrainType() == 3 or target_plot_1:GetTerrainType() == 4 or (target_plot_1:GetTerrainType() == 5 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
					if ( target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS or ( target_plot_1:GetFeatureType() == g_FEATURE_FLOODPLAINS_PLAINS and flag ~= 4) ) then
					-- +5.5 on Plains		
					rng = TerrainBuilder.GetRandomNumber(100,"test")/100
						if (rng >= 0.9) then
							-- Forested Hill with Deer
							TerrainBuilder.SetTerrainType(target_plot_1,4);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							TerrainBuilder.SetFeatureType(target_plot_1,3);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 4, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/4 Forested Plain Hill with Deer");
							elseif (rng >= 0.5 and rng < 0.9) then
							-- Forested Plain Hill
							TerrainBuilder.SetTerrainType(target_plot_1,4);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							TerrainBuilder.SetFeatureType(target_plot_1,3);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/3 Forested Plain Hill");
							elseif (rng >= 0 and rng < 0.5) then
							-- Banana Jungle Hill
								if (target_plot_1:GetY() > gridHeight * 0.25 and target_plot_1:GetY() < gridHeight * 0.75) then
									TerrainBuilder.SetTerrainType(target_plot_1,4);
									TerrainBuilder.SetFeatureType(target_plot_1,-1);
									ResourceBuilder.SetResourceType(target_plot_1, -1);
									ResourceBuilder.SetResourceType(target_plot_1, 0, 1);
									TerrainBuilder.SetFeatureType(target_plot_1,2);
									__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/2 Jungle Plain Hill with Banana");
									else
									-- Forested Plain Hill
									TerrainBuilder.SetTerrainType(target_plot_1,4);
									TerrainBuilder.SetFeatureType(target_plot_1,-1);
									TerrainBuilder.SetFeatureType(target_plot_1,3);
									ResourceBuilder.SetResourceType(target_plot_1, -1);
									__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/3 Forested Plain Hill");
								end

						end
						else
						-- floodplains and floodplains Civs
						if (target_plot_1:GetResourceCount() < 1 and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
							ResourceBuilder.SetResourceType(target_plot_1, 9, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/0 Wheat Plains Floodplains");
						end
					end
				-- Desert
				elseif ( target_plot_1:GetTerrainType() == 6 or target_plot_1:GetTerrainType() == 7 or (target_plot_1:GetTerrainType() == 8 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
					if ( target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
					-- on Desert -> impossible	
					rng = TerrainBuilder.GetRandomNumber(100,"test")/100
						if (rng >= 0.5) then
							-- Hill with Sheep
							TerrainBuilder.SetTerrainType(target_plot_1,7);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/1 Sheep Desert Hill");
							elseif (rng >= 0.0 and rng < 0.5) then
							-- Copper Hill
							TerrainBuilder.SetTerrainType(target_plot_1,7);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Copper Desert Hill");
						end
						else
						-- floodplains
						if (target_plot_1:GetResourceCount() < 1 and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
							ResourceBuilder.SetResourceType(target_plot_1, 9, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/0 Wheat Desert Floodplains");
						end
					end
				-- Tundra
				elseif ( target_plot_1:GetTerrainType() == 9 or target_plot_1:GetTerrainType() == 10 or (target_plot_1:GetTerrainType() == 11 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
					if ( target_plot_1:GetFeatureType() ~= g_FEATURE_MARSH) then
					-- +5 on Tundra -> impossible	
					rng = TerrainBuilder.GetRandomNumber(100,"test")/100
						if (rng >= 0.75) then
							-- Hill with Sheep
							TerrainBuilder.SetTerrainType(target_plot_1,10);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/1 Sheep Tundra Hill");
							elseif (rng >= 0.5 and rng < 0.75) then
							-- Copper Hill
							TerrainBuilder.SetTerrainType(target_plot_1,10);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Copper Tundra Hill");
							elseif (rng >= 0.0 and rng < 0.5) then
							-- Forested Deer
							TerrainBuilder.SetTerrainType(target_plot_1,10);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							TerrainBuilder.SetFeatureType(target_plot_1,3);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 4, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Deer Tundra Hill");
						end
					end


			elseif ( avg_best_2 > 4.25 + adjust and avg_best_2 < 4.75 + adjust) then
				-- 3/1

				target_plot_1 = GetAdjacentTiles(plot, valid_target_2)
				-- Grassland
				if ( target_plot_1:GetTerrainType() == 0 or target_plot_1:GetTerrainType() == 1 or (target_plot_1:GetTerrainType() == 2 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO) ) then
					if ( target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND or ( target_plot_1:GetFeatureType() == g_FEATURE_FLOODPLAINS_GRASSLAND and flag ~= 4) ) then
					-- +4.5 on Grassland	
					rng = TerrainBuilder.GetRandomNumber(100,"test")/100	
						if (rng >= 0) then
							-- Hill with Sheep
							TerrainBuilder.SetTerrainType(target_plot_1,1);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 7, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/1 Sheep Grassland Hill");

						end
						else
						-- floodplains and floodplains Civs
						if (target_plot_1:GetResourceCount() < 1) then
							ResourceBuilder.SetResourceType(target_plot_1, 6, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/0 Rice Grassland Floodplains");
						end
					end
				-- Plains
				elseif ( target_plot_1:GetTerrainType() == 3 or target_plot_1:GetTerrainType() == 4 or (target_plot_1:GetTerrainType() == 5 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
					if ( target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS or ( target_plot_1:GetFeatureType() == g_FEATURE_FLOODPLAINS_PLAINS and flag ~= 4) ) then
					-- +4.5 on Plains		
					rng = TerrainBuilder.GetRandomNumber(100,"test")/100
						if (rng >= 0.0) then
							-- Banana Jungle plains
								if (target_plot_1:GetY() > gridHeight * 0.25 and target_plot_1:GetY() < gridHeight * 0.75) then
									TerrainBuilder.SetTerrainType(target_plot_1,3);
									TerrainBuilder.SetFeatureType(target_plot_1,-1);
									ResourceBuilder.SetResourceType(target_plot_1, -1);
									ResourceBuilder.SetResourceType(target_plot_1, 0, 1);
									TerrainBuilder.SetFeatureType(target_plot_1,2);
									__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/1 Jungle Plain with Banana");
									else
									-- Forested Plain Hill
									TerrainBuilder.SetTerrainType(target_plot_1,3);
									TerrainBuilder.SetFeatureType(target_plot_1,-1);
									TerrainBuilder.SetFeatureType(target_plot_1,3);
									ResourceBuilder.SetResourceType(target_plot_1, -1);
									ResourceBuilder.SetResourceType(target_plot_1, 4, 1);
									__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Forested Plain with Deer");
								end

						end
						else
						-- floodplains and floodplains Civs
						if (target_plot_1:GetResourceCount() < 1 and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
							ResourceBuilder.SetResourceType(target_plot_1, 9, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/0 Wheat Plains Floodplains");
						end
					end
				-- Desert
				elseif ( target_plot_1:GetTerrainType() == 6 or target_plot_1:GetTerrainType() == 7 or (target_plot_1:GetTerrainType() == 8 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
					if ( target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
					-- on Desert -> impossible	
					rng = TerrainBuilder.GetRandomNumber(100,"test")/100
						if (rng >= 0.5) then
							-- Hill with Sheep
							TerrainBuilder.SetTerrainType(target_plot_1,7);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/1 Sheep Desert Hill");
							elseif (rng >= 0.0 and rng < 0.5) then
							-- Copper Hill
							TerrainBuilder.SetTerrainType(target_plot_1,7);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Copper Desert Hill");
						end
						else
						-- floodplains
						if (target_plot_1:GetResourceCount() < 1 and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
							ResourceBuilder.SetResourceType(target_plot_1, 9, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/0 Wheat Desert Floodplains");
						end
					end
				-- Tundra
				elseif ( target_plot_1:GetTerrainType() == 9 or target_plot_1:GetTerrainType() == 10 or (target_plot_1:GetTerrainType() == 11 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
					if ( target_plot_1:GetFeatureType() ~= g_FEATURE_MARSH) then
					-- +5 on Tundra -> impossible	
					rng = TerrainBuilder.GetRandomNumber(100,"test")/100
						if (rng >= 0.66) then
							-- Hill with Sheep
							TerrainBuilder.SetTerrainType(target_plot_1,10);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 7,1);
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/1 Sheep Tundra Hill");
							elseif (rng >= 0.1 and rng < 0.66) then
							-- Copper Hill
							TerrainBuilder.SetTerrainType(target_plot_1,10);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Copper Tundra Hill");
							elseif (rng >= 0.0 and rng < 0.1) then
							-- Forested Deer
							TerrainBuilder.SetTerrainType(target_plot_1,10);
							TerrainBuilder.SetFeatureType(target_plot_1,-1);
							TerrainBuilder.SetFeatureType(target_plot_1,3);
							ResourceBuilder.SetResourceType(target_plot_1, -1);
							ResourceBuilder.SetResourceType(target_plot_1, 4, 1)
							__Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Deer Tundra Hill");
						end
					end

				end
			end
		end
	end
		

end

------------------------------------------------------------------------------

------------------------------------------------------------------------------

function Terraforming_Water(plot)
	local iResourcesInDB = 0;
	local terrainType = plot:GetTerrainType();
	local featureType = plot:GetFeatureType();
	local gridWidth, gridHeight = Map.GetGridSize();
	local adjacentPlot = nil;

	--------------------------------------------------------------------------------------------------------------
	-- Terraforming Water Start ----------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------
		
	for i = 0, 5 do
		adjacentPlot = GetAdjacentTiles(plot, i);

		if (adjacentPlot ~=nil) then
			if (adjacentPlot:GetResourceCount() < 1) then
				__Debug("Terraforming Water X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Added: Water Lake");
				TerrainBuilder.SetFeatureType(adjacentPlot,-1);
				TerrainBuilder.SetTerrainType(adjacentPlot, 15);
				return
			end
		end

	end
end

------------------------------------------------------------------------------


------------------------------------------------------------------------------

function Terraforming_Flood(plot, intensity)
	-- flag = 0 normal
	-- flag = 1 tundra civ
	-- flag = 2 desert civ
	-- flag = 3 mountain civ
	local max_water = 0;
	local harborplot_index = nil;
	local iResourcesInDB = 0;
	local terrainType = plot:GetTerrainType();
	local featureType = plot:GetFeatureType();
	local gridWidth, gridHeight = Map.GetGridSize();
	local direction = 0;
	local bTerraform = true;
	local limit = 0;
	local limit_1 = 1;
	local limit_2 = 1;
	local limit_3 = 1;
	local limit_4 = 1;
	local adjacentPlot = nil;
	local adjacentPlot2 = nil;
	local adjacentPlot3 = nil;
	local adjacentPlot4 = nil;


	--------------------------------------------------------------------------------------------------------------
	-- Terraforming Floodplains Start ----------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------

	if (intensity == 1) then
		limit_1 = 0.25;
		limit_2 = 0.50;
		limit_3 = 0.33;
		limit_4 = 0.66;

		elseif (intensity == 2) then
			limit_1 = 0.10;
			limit_2 = 0.25;
			limit_3 = 0.25;
			limit_4 = 0.50;

	end
		
	for i = -1, 17 do
		adjacentPlot = GetAdjacentTiles(plot, i);

		if (i < 6) then
			limit = limit_1
			else
			limit = limit_2
		end

		if (adjacentPlot ~=nil) then
			if (adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS or adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS_PLAINS or adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS_GRASSLAND) then
				local rng = TerrainBuilder.GetRandomNumber(100,"test")/100;
				if ( rng > limit ) then
					__Debug("Terraforming Floodplains X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Removed: Floodplains");
					TerrainBuilder.SetFeatureType(plot,-1);
					TerrainBuilder.SetFeatureType(adjacentPlot,-1);
				end
			end
		end

	end
end

------------------------------------------------------------------------------

function Terraforming_Coastal(plot, intensity, post_correction)
	-- flag = 0 normal
	-- flag = 1 tundra civ
	-- flag = 2 desert civ
	-- flag = 3 mountain civ
	local max_water = 0;
	local harborplot_index = nil;
	local iResourcesInDB = 0;
	local terrainType = plot:GetTerrainType();
	local featureType = plot:GetFeatureType();
	local gridWidth, gridHeight = Map.GetGridSize();
	local direction = 0;
	local bTerraform = true;
	local count = 0;
	local limit = 0;
	local limit_1 = 0.75;
	local limit_2 = 0.5;
	local limit_3 = 0.33;
	local limit_4 = 0.5;
	local limit_5 = 0.5;
	local adjacentPlot = nil;
	local adjacentPlot2 = nil;
	local adjacentPlot3 = nil;
	local adjacentPlot4 = nil;


	--------------------------------------------------------------------------------------------------------------
	-- Terraforming Coastal Start --------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------

	if (intensity == 1) then
		limit_1 = 0.15;
		limit_2 = 0.075;
		limit_3 = 0.10;
		limit_4 = 0.05;
		limit_5 = 0.05;

		elseif (intensity == 2) then
			limit_1 = 0.10;
			limit_2 = 0.05;
			limit_3 = 0.10;
			limit_4 = 0.05;
			limit_5 = 0.05;

	end
		
	

	-- Step 1  Getting a Valid Harbor
	for i = 0, 5 do
		adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), i);

		if (adjacentPlot ~=nil) then
			if (adjacentPlot:IsWater() == true) then
				if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
					local count = 0;
					for j = 0, 5 do
						adjacentPlot2 = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), j);
						if (adjacentPlot2 ~=nil) then
							if (adjacentPlot2:IsWater() == true) then
								count = count + 1;
							end
						end
						if (count > max_water) then
							max_water = count;
							harborplot_index = i;
						end
					end
				end
			end
		end
	end

	-- Step 2 Cleaning the Location

	if (harborplot_index ~= nil) then
		local harborPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), harborplot_index);
		if (harborPlot ~= nil) then
			__Debug("Coastal Terraforming X: ", harborPlot:GetX(), "Y: ", harborPlot:GetY(), "Found a valid Harbor tile");
			ResourceBuilder.SetResourceType(harborPlot, -1);
			TerrainBuilder.SetFeatureType(harborPlot,-1);
		end
	end

	-- count reefs
	count = 0
	for i = 0, 60 do
		adjacentPlot = GetAdjacentTiles(plot, i);
		if (adjacentPlot ~=nil) then
			if (adjacentPlot:GetFeatureType() == g_FEATURE_REEF) then
				count = count + 1;
			end
		end
	end


	if (post_correction == false) then
	-- Step 3 Populating the harbor surrounding tiles
	if (harborplot ~= nil) then
		if(harborPlot:GetX() >= 0 and harborPlot:GetY() < gridHeight) then
			for i = 0, 17 do
				adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), i);
				local rng = TerrainBuilder.GetRandomNumber(100,"test")/100;
				if (adjacentPlot ~=nil) then
					if (adjacentPlot:IsWater() == true and adjacentPlot:GetFeatureType() == -1 and adjacentPlot:GetResourceType() ~= 45) then
						if (rng > limit_1 and count <3) then
							__Debug("Coastal Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Added: Reef");
							TerrainBuilder.SetFeatureType(adjacentPlot,g_FEATURE_REEF);
							count = count + 1;
							local rng = TerrainBuilder.GetRandomNumber(100,"test")/100;
							elseif (rng/count > limit_2 and adjacentPlot:GetResourceType() == -1) then
								if(ResourceBuilder.CanHaveResource(adjacentPlot, 5)) then
									ResourceBuilder.SetResourceType(adjacentPlot, 5, 1);
									__Debug("Coastal Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Added: Fish");
								end
						
						end
					end
				end
			end
		end
	end
		
	-- Step 4 Ocean to Coast and Ice removal
	for i = 0, 60 do

		if (i < 6) then
			limit = limit_3;
			elseif( i>5 and i <18) then
			limit = limit_4;
			elseif( i>18) then
			limit = limit_5;
		end
	
		adjacentPlot = GetAdjacentTiles(plot, i);
		if (adjacentPlot ~=nil) then
			terrainType = adjacentPlot:GetTerrainType();
			rng = TerrainBuilder.GetRandomNumber(100,"test")/100;
			if((terrainType == 16) and rng > limit) then
				__Debug("Terraforming Coastal X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing Ocean to Coast tile",i);
				TerrainBuilder.SetTerrainType(adjacentPlot,15);
				local rng = TerrainBuilder.GetRandomNumber(100,"test")/100;
				if (adjacentPlot:GetFeatureType() == -1 and rng > limit and adjacentPlot:GetResourceType() == -1 and ( (count <3 and i <17) or (count < 4 and i > 30) ) and (post_correction == false) ) then
					TerrainBuilder.SetFeatureType(adjacentPlot,g_FEATURE_REEF);
					__Debug("Coastal Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Added: Reef",i);
					count = count + 1;
					local rng = TerrainBuilder.GetRandomNumber(100,"test")/100;
					if( (rng / count / count ) > limit and adjacentPlot:GetResourceType() == -1) then 
						-- Reef with fish 
						__Debug("Coastal Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Added: Fish");
						ResourceBuilder.SetResourceType(adjacentPlot, 5, 1);
					end
				end

				if (adjacentPlot:GetFeatureType() == 1 and rng > limit/2) then
					__Debug("Costal Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Removing Ice",i);
					TerrainBuilder.SetFeatureType(adjacentPlot,-1);
				end
			end
		end



	end

	end
	__Debug("Coastal Terraforming : Total Reefs Count:", count);

end

------------------------------------------------------------------------------

function Terraforming(plot, intensity, flag)
	-- flag = 0 normal
	-- flag = 1 tundra civ
	-- flag = 2 desert civ
	-- flag = 3 mountain civ
	local iResourcesInDB = 0;
	local terrainType = plot:GetTerrainType();
	local featureType = plot:GetFeatureType();
	local gridWidth, gridHeight = Map.GetGridSize();
	local direction = 0;
	local bTerraform = true;
	local limit = 0;
	local limit_1 = 0;
	local limit_2 = 0;
	local limit_3 = 0;
	local limit_4 = 0;
	local limit_tree = 0;
	local max_wood = 5;
	local adjacentPlot = nil;
	local adjacentPlot2 = nil;
	local adjacentPlot3 = nil;
	local adjacentPlot4 = nil;
	local count_wood = 0;


	--------------------------------------------------------------------------------------------------------------
	-- Terraforming the Tundra/Snow/Desert  ----------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------

	if (intensity == 1) then
		limit_1 = 0.00;
		limit_2 = 0.00;
		limit_3 = 0.05;
		limit_4 = 0.5;
		limit_tree = 0.5;

		elseif (intensity == 2) then
			limit_1 = 0;
			limit_2 = 0.00;
			limit_3 = 0.05;
			limit_4 = 0.10;
			limit_tree = 0.33;
	end
		


	-- Spawn
	--if(plot:GetTerrainType() == 9 or plot:GetTerrainType() == 12 or plot:GetTerrainType() == 6) then
--
--		if (intensity == 1 and flag ~=1 and flag ~=2) then
--			__Debug("Terraforming X: ", plot:GetX(), "Y: ", plot:GetY(), "Changing to Plains tile, Spawn");
--			TerrainBuilder.SetTerrainType(plot,g_TERRAIN_TYPE_PLAINS);
--			else
---			__Debug("Terraforming X: ", plot:GetX(), "Y: ", plot:GetY(), "Changing to Grassland tile, Spawn");
--			TerrainBuilder.SetTerrainType(plot,0)
--		end

--		elseif(plot:GetTerrainType() == 10 or plot:GetTerrainType() == 13 or plot:GetTerrainType() == 7) then
--			if (intensity == 1 and flag ~=1 and flag ~=2) then
--				__Debug("Terraforming X: ", plot:GetX(), "Y: ", plot:GetY(), "Changing to Plains Hills tile, Spawn");
--				TerrainBuilder.SetTerrainType(plot,g_TERRAIN_TYPE_PLAINS_HILLS);
--				else
--				__Debug("Terraforming X: ", plot:GetX(), "Y: ", plot:GetY(), "Changing to Grasslands Hills tile, Spawn");
--				TerrainBuilder.SetTerrainType(plot,1);
--			end
--	end

	-- #0 to #100 Tiles
	for i = -1, 100 do
		if (i < 6) then
			limit = limit_1
			elseif( i >5 and i <18) then
				limit = limit_2
			elseif( i >17 and i <36) then
				limit = limit_3
			else
				limit = limit_4
		end
		adjacentPlot = GetAdjacentTiles(plot, i);
		--__Debug("Evaluate Start X: ", adjacentPlot:GetX(), "Evaluate Start Y: ", adjacentPlot:GetY(), "Terrain Type: ", terrainType);
		--__Debug("Evaluate Start X: ", adjacentPlot:GetX(), "Evaluate Start Y: ", adjacentPlot:GetY(), "Feature Type: ", adjacentPlot:GetFeatureType());

		if (adjacentPlot ~= nil) then
			terrainType = adjacentPlot:GetTerrainType()
			if (adjacentPlot:GetFeatureType() == g_FEATURE_OASIS and flag ~=2) then
				__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Remove Oasis",i);
				TerrainBuilder.SetFeatureType(adjacentPlot,-1);
			end
			if (adjacentPlot:GetFeatureType() == 1) then
				__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Remove Ice",i);
				TerrainBuilder.SetFeatureType(adjacentPlot,-1);
			end
			rng = TerrainBuilder.GetRandomNumber(100,"test")/100;
			if((terrainType == 9) and rng > limit and flag ~=1) then
				__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Plains tile",i);
				TerrainBuilder.SetTerrainType(adjacentPlot,g_TERRAIN_TYPE_PLAINS);
			end
			if((terrainType == 10) and rng > limit and flag ~=1) then
				__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Plains Hills tile",i);
				TerrainBuilder.SetTerrainType(adjacentPlot,g_TERRAIN_TYPE_PLAINS_HILLS);
			end
			if((terrainType == 6) and rng > limit and flag ~=2) then
				__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Plains tile",i);
				TerrainBuilder.SetTerrainType(adjacentPlot,g_TERRAIN_TYPE_PLAINS);
				if (adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS) then
					TerrainBuilder.SetFeatureType(adjacentPlot,-1);
					TerrainBuilder.SetFeatureType(adjacentPlot,g_FEATURE_FLOODPLAINS_PLAINS);
				end
			end
			if((terrainType == 7) and rng > limit and flag ~=2) then
				__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Plains Hills tile",i);
				TerrainBuilder.SetTerrainType(adjacentPlot,g_TERRAIN_TYPE_PLAINS_HILLS);
			end
			if(terrainType == 12) then
				if(i < 18 and flag ~=1) then
					__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Plain tile",i);
					TerrainBuilder.SetTerrainType(adjacentPlot,g_TERRAIN_TYPE_PLAINS);
					else
					__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Tundra tile",i);
					TerrainBuilder.SetTerrainType(adjacentPlot,9);
				end
			end
			if(terrainType == 13) then
				if(i < 18 and flag ~=1) then
					__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Plain tile",i);
					TerrainBuilder.SetTerrainType(adjacentPlot,g_TERRAIN_TYPE_PLAINS_HILLS);
					else
					__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Tundra tile",i);
					TerrainBuilder.SetTerrainType(adjacentPlot,10);
				end
			end
			if((terrainType == 4) and rng > limit and adjacentPlot:GetFeatureType() ~= g_FEATURE_JUNGLE and flag ~=1 and flag ~=2) then
				__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Grassland Hills tile",i);
				TerrainBuilder.SetTerrainType(adjacentPlot,1);
			end
			if((terrainType == 3) and rng > limit and adjacentPlot:GetFeatureType() ~= g_FEATURE_JUNGLE and flag ~=1 and flag ~=2) then
				__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Grassland tile",i);
				TerrainBuilder.SetTerrainType(adjacentPlot,0);
			end
			rng = TerrainBuilder.GetRandomNumber(100,"test")/100;
			if (adjacentPlot:IsWater() == false and adjacentPlot:IsImpassable() == false and terrainType ~= 12 and terrainType ~= 13 and terrainType ~= 6 and terrainType ~= 7 and adjacentPlot:GetFeatureType() == -1 and rng > limit_tree and adjacentPlot:GetResourceType() == -1 and count_wood < max_wood) then
				TerrainBuilder.SetFeatureType(adjacentPlot,3);
				count_wood = count_wood + 1;
				__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Added: Wood",i);
			end
		end


	end
	count_wood = 0;
	__Debug("Terraforming East Side");

	if(MapConfiguration.GetValue("MapName") == nil) then
		return
		else
		if(MapConfiguration.GetValue("MapName") == "Tilted_Axis") then
			__Debug("Terraforming: Tilted Axis map");
			return
		end
	end

	local east_plot = GetAdjacentTiles(plot, 52);

	if (east_plot == nil) then
		return
	end

	-- #0 to #100 Tiles
	for i = -1, 100 do
		if (i < 6) then
			limit = limit_1
			elseif( i >5 and i <18) then
				limit = limit_2
			elseif( i >17 and i <36) then
				limit = limit_3
			else
				limit = limit_4
		end
		adjacentPlot = GetAdjacentTiles(east_plot, i);
		--__Debug("Evaluate Start X: ", adjacentPlot:GetX(), "Evaluate Start Y: ", adjacentPlot:GetY(), "Terrain Type: ", terrainType);
		--__Debug("Evaluate Start X: ", adjacentPlot:GetX(), "Evaluate Start Y: ", adjacentPlot:GetY(), "Feature Type: ", adjacentPlot:GetFeatureType());

		if (adjacentPlot ~= nil) then
			terrainType = adjacentPlot:GetTerrainType()
			if (adjacentPlot:GetFeatureType() == g_FEATURE_OASIS and flag ~=2) then
				__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Remove Oasis",i);
				TerrainBuilder.SetFeatureType(adjacentPlot,-1);
			end
			if (adjacentPlot:GetFeatureType() == 1) then
				__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Remove Ice",i);
				TerrainBuilder.SetFeatureType(adjacentPlot,-1);
			end
			rng = TerrainBuilder.GetRandomNumber(100,"test")/100;
			if((terrainType == 9) and rng > limit and flag ~=1) then
				__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Plains tile",i);
				TerrainBuilder.SetTerrainType(adjacentPlot,g_TERRAIN_TYPE_PLAINS);
			end
			if((terrainType == 10) and rng > limit and flag ~=1) then
				__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Plains Hills tile",i);
				TerrainBuilder.SetTerrainType(adjacentPlot,g_TERRAIN_TYPE_PLAINS_HILLS);
			end
			if((terrainType == 6) and rng > limit and flag ~=2) then
				__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Plains tile",i);
				TerrainBuilder.SetTerrainType(adjacentPlot,g_TERRAIN_TYPE_PLAINS);
				if (adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS) then
					TerrainBuilder.SetFeatureType(adjacentPlot,-1);
					TerrainBuilder.SetFeatureType(adjacentPlot,g_FEATURE_FLOODPLAINS_PLAINS);
				end
			end
			if((terrainType == 7) and rng > limit and flag ~=2) then
				__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Plains Hills tile",i);
				TerrainBuilder.SetTerrainType(adjacentPlot,g_TERRAIN_TYPE_PLAINS_HILLS);
			end
			if(terrainType == 12) then
				if(i < 18 and flag ~=1) then
					__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Plain tile",i);
					TerrainBuilder.SetTerrainType(adjacentPlot,g_TERRAIN_TYPE_PLAINS);
					else
					__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Tundra tile",i);
					TerrainBuilder.SetTerrainType(adjacentPlot,9);
				end
			end
			if(terrainType == 13) then
				if(i < 18 and flag ~=1) then
					__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Plain tile",i);
					TerrainBuilder.SetTerrainType(adjacentPlot,g_TERRAIN_TYPE_PLAINS_HILLS);
					else
					__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Tundra tile",i);
					TerrainBuilder.SetTerrainType(adjacentPlot,10);
				end
			end
			rng = TerrainBuilder.GetRandomNumber(100,"test")/100;
			if (adjacentPlot:IsWater() == false and adjacentPlot:IsImpassable() == false and terrainType ~= 12 and terrainType ~= 13 and terrainType ~= 6 and terrainType ~= 7 and adjacentPlot:GetFeatureType() == -1 and rng > limit_tree and adjacentPlot:GetResourceType() == -1 and count_wood < max_wood) then
				TerrainBuilder.SetFeatureType(adjacentPlot,3);
				count_wood = count_wood + 1;
				__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Added: Wood",i);
			end
		end


	end
	count_wood = 0;
	__Debug("Terraforming West Side");
	local west_plot = GetAdjacentTiles(plot, 52);

	if (west_plot == nil) then
		return
	end

	-- #0 to #100 Tiles
	for i = 90, 0, -1 do
		if (i < 6) then
			limit = limit_1
			elseif( i >5 and i <18) then
				limit = limit_2
			elseif( i >17 and i <36) then
				limit = limit_3
			else
				limit = limit_4
		end
		adjacentPlot = GetAdjacentTiles(west_plot, i);
		--__Debug("Evaluate Start X: ", adjacentPlot:GetX(), "Evaluate Start Y: ", adjacentPlot:GetY(), "Terrain Type: ", terrainType);
		--__Debug("Evaluate Start X: ", adjacentPlot:GetX(), "Evaluate Start Y: ", adjacentPlot:GetY(), "Feature Type: ", adjacentPlot:GetFeatureType());

		if (adjacentPlot ~= nil) then
			terrainType = adjacentPlot:GetTerrainType()
			if (adjacentPlot:GetFeatureType() == g_FEATURE_OASIS and flag ~=2) then
				__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Remove Oasis",i);
				TerrainBuilder.SetFeatureType(adjacentPlot,-1);
			end
			if (adjacentPlot:GetFeatureType() == 1) then
				__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Remove Ice",i);
				TerrainBuilder.SetFeatureType(adjacentPlot,-1);
			end
			rng = TerrainBuilder.GetRandomNumber(100,"test")/100;
			if((terrainType == 9) and rng > limit and flag ~=1) then
				__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Plains tile",i);
				TerrainBuilder.SetTerrainType(adjacentPlot,g_TERRAIN_TYPE_PLAINS);
			end
			if((terrainType == 10) and rng > limit and flag ~=1) then
				__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Plains Hills tile",i);
				TerrainBuilder.SetTerrainType(adjacentPlot,g_TERRAIN_TYPE_PLAINS_HILLS);
			end
			if((terrainType == 6) and rng > limit and flag ~=2) then
				__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Plains tile",i);
				TerrainBuilder.SetTerrainType(adjacentPlot,g_TERRAIN_TYPE_PLAINS);
				if (adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS) then
					TerrainBuilder.SetFeatureType(adjacentPlot,-1);
					TerrainBuilder.SetFeatureType(adjacentPlot,g_FEATURE_FLOODPLAINS_PLAINS);
				end
			end
			if((terrainType == 7) and rng > limit and flag ~=2) then
				__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Plains Hills tile",i);
				TerrainBuilder.SetTerrainType(adjacentPlot,g_TERRAIN_TYPE_PLAINS_HILLS);
			end
			if(terrainType == 12) then
				if(i < 18 and flag ~=1) then
					__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Plain tile",i);
					TerrainBuilder.SetTerrainType(adjacentPlot,g_TERRAIN_TYPE_PLAINS);
					else
					__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Tundra tile",i);
					TerrainBuilder.SetTerrainType(adjacentPlot,9);
				end
			end
			if(terrainType == 13) then
				if(i < 18 and flag ~=1) then
					__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Plain tile",i);
					TerrainBuilder.SetTerrainType(adjacentPlot,g_TERRAIN_TYPE_PLAINS_HILLS);
					else
					__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Tundra tile",i);
					TerrainBuilder.SetTerrainType(adjacentPlot,10);
				end
			end
			rng = TerrainBuilder.GetRandomNumber(100,"test")/100;
			if (adjacentPlot:IsWater() == false and adjacentPlot:IsImpassable() == false and terrainType ~= 12 and terrainType ~= 13 and terrainType ~= 6 and terrainType ~= 7 and adjacentPlot:GetFeatureType() == -1 and rng > limit_tree and adjacentPlot:GetResourceType() == -1 and count_wood < max_wood) then
				TerrainBuilder.SetFeatureType(adjacentPlot,3);
				count_wood = count_wood + 1;
				__Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Added: Wood",i);
			end
		end


	end
	----------------------------------------------------------------------
	--------------------- Terraforming Completed -------------------------
	----------------------------------------------------------------------


end


------------------------------------------------------------------------------
function RemoveProd(plot)
	local iResourcesInDB = 0;
	eResourceType	= {};
	eResourceClassType = {};
	aBonus = {};
	local direction = 0;

	for row in GameInfo.Resources() do
		eResourceType[iResourcesInDB] = row.Hash;
		eResourceClassType[iResourcesInDB] = row.ResourceClassType;
	    iResourcesInDB = iResourcesInDB + 1;
	end

	for row = 0, iResourcesInDB do
		if (eResourceClassType[row] == "RESOURCECLASS_BONUS") then
			for row2 in GameInfo.TypeTags() do
				if(GameInfo.Resources[row2.Type] ~= nil) then
					if(GameInfo.Resources[row2.Type].Index == eResourceType[row] and row2.Tag=="CLASS_PRODUCTION") then
						table.insert(aBonus, eResourceType[row]);
					end
				end
			end
		end
	end

	for j = 0, 17 do
		local otherPlot = GetAdjacentTiles(plot, j);
		--__Debug("Evaluate Start X: ", otherPlot:GetX(), "Evaluate Start Y: ", otherPlot:GetY(), "Terrain Type: ", terrainType);
		for i, resource in ipairs(eResourceType) do
			if(otherPlot) then
				if(resource  == otherPlot:GetResourceTypeHash()) then
					if (otherPlot:GetResourceType() ~= 40 and otherPlot:GetResourceType() ~= 41 and otherPlot:GetResourceType() ~= 42 and otherPlot:GetResourceType() ~= 43 and otherPlot:GetResourceType() ~= 44 and otherPlot:GetResourceType() ~= 45 and otherPlot:GetResourceType() ~= 46) then
						__Debug("Prod balancing: Prod Removed", otherPlot:GetResourceType());
						ResourceBuilder.SetResourceType(otherPlot, -1);
						return true;
					end
				end
				if (otherPlot:GetFeatureType() == 3) then
					TerrainBuilder.SetFeatureType(otherPlot,-1);
					__Debug("Prod balancing: Wood Removed");
					return true;
				end
			end
		end
	end 
	__Debug("Prod balancing: Couldn't Remove Production");
	return false;
end

------------------------------------------------------------------------------
function RemoveFood(plot)
	local iResourcesInDB = 0;
	eResourceType	= {};
	eResourceClassType = {};
	aBonus = {};
	local direction = 0;

	for row in GameInfo.Resources() do
		eResourceType[iResourcesInDB] = row.Hash;
		eResourceClassType[iResourcesInDB] = row.ResourceClassType;
	    iResourcesInDB = iResourcesInDB + 1;
	end

	for row = 0, iResourcesInDB do
		if (eResourceClassType[row] == "RESOURCECLASS_BONUS") then
			for row2 in GameInfo.TypeTags() do
				if(GameInfo.Resources[row2.Type] ~= nil) then
					if(GameInfo.Resources[row2.Type].Index == eResourceType[row] and row2.Tag=="CLASS_FOOD") then
						table.insert(aBonus, eResourceType[row]);
					end
				end
			end
		end
	end

	for j = 0, 17 do
		local otherPlot = GetAdjacentTiles(plot, j);
		--__Debug("Evaluate Start X: ", otherPlot:GetX(), "Evaluate Start Y: ", otherPlot:GetY(), "Terrain Type: ", terrainType);
		for i, resource in ipairs(eResourceType) do
			if(otherPlot) then
				if(resource  == otherPlot:GetResourceTypeHash()) then
					if (otherPlot:GetResourceType() ~= 40 and otherPlot:GetResourceType() ~= 41 and otherPlot:GetResourceType() ~= 42 and otherPlot:GetResourceType() ~= 43 and otherPlot:GetResourceType() ~= 44 and otherPlot:GetResourceType() ~= 45 and otherPlot:GetResourceType() ~= 46) then
						__Debug("Food balancing: Food Removed", otherPlot:GetResourceType());
						ResourceBuilder.SetResourceType(otherPlot, -1);
						return true;
					end
				end
				if (otherPlot:GetFeatureType() == 2) then
					TerrainBuilder.SetFeatureType(otherPlot,-1);
					__Debug("Food balancing: Jungle Removed");
					return true;
				end
			end
		end
	end 
	__Debug("Food balancing: Couldn't Remove Food");
	return false;
end

------------------------------------------------------------------------------

function BalanceStrategic(plot)
	local iResourcesInDB = 0;
	local iStartEra = GameInfo.Eras[ GameConfiguration.GetStartEra() ];
	local iStartIndex = 1;
	local direction = 0;

	if iStartEra ~= nil then
		iStartIndex = iStartEra.ChronologyIndex;
	end

-- 40 Aluminium
-- 41 Coal
-- 42 Horse
-- 43 Iron
-- 44 Niter
-- 45 Oil
-- 46 Uranium

	if (iStartIndex == 1) then
		local bHasResource = false;
		__Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Horse");
		bHasResource = FindResource(42, plot);
		if(bHasResource == false) then
			__Debug("Balance Resources: Need to add Horses");
			PlaceResource(42, plot);
		end
		__Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Iron");
		bHasResource = FindResource(43, plot);
		if(bHasResource == false) then
			__Debug("Balance Resources: Need to add Iron");
			PlaceResource(43, plot);
		end
	-- Classical or Medieval
		elseif (iStartIndex == 2 or iStartIndex == 3) then
		__Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Horse");
		bHasResource = FindResource(42, plot);
		if(bHasResource == false) then
			__Debug("Balance Resources: Need to add Horses");
			PlaceResource(42, plot);
		end
		__Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Iron");
		bHasResource = FindResource(43, plot);
		if(bHasResource == false) then
			__Debug("Balance Resources: Need to add Iron");
			PlaceResource(43, plot);
		end
		__Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Niter");
		bHasResource = FindResource(44, plot);
		if(bHasResource == false) then
			__Debug("Balance Resources: Need to add Niter");
			PlaceResource(44, plot);
		end

	-- 
		elseif (iStartIndex == 4 or iStartIndex == 5) then
		__Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Coal");
		bHasResource = FindResource(41, plot);
		if(bHasResource == false) then
			__Debug("Balance Resources: Need to add Coal");
			PlaceResource(41, plot);
		end
		__Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Iron");
		bHasResource = FindResource(43, plot);
		if(bHasResource == false) then
			__Debug("Balance Resources: Need to add Iron");
			PlaceResource(43, plot);
		end
		__Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Niter");
		bHasResource = FindResource(44, plot);
		if(bHasResource == false) then
			__Debug("Balance Resources: Need to add Niter");
			PlaceResource(44, plot);
		end

	--

		elseif (iStartIndex == 6) then
		__Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Coal");
		bHasResource = FindResource(41, plot);
		if(bHasResource == false) then
			__Debug("Balance Resources: Need to add Coal");
			PlaceResource(41, plot);
		end
		__Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Oil");
		bHasResource = FindResource(45, plot);
		if(bHasResource == false) then
			__Debug("Balance Resources: Need to add Niter");
			PlaceResource(45, plot);
		end

	-- 
		elseif (iStartIndex > 6) then
		__Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Aluminium");
		bHasResource = FindResource(40, plot);
		if(bHasResource == false) then
			__Debug("Balance Resources: Need to add Aluminium");
			PlaceResource(40, plot);
		end
		__Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Oil");
		bHasResource = FindResource(45, plot);
		if(bHasResource == false) then
			__Debug("Balance Resources: Need to add Oil");
			PlaceResource(45, plot);
		end

	end
end

------------------------------------------------------------------------------
function PlaceResource(eResourceType, plot)
	local gridWidth, gridHeight = Map.GetGridSize();
	local direction = 0;
	local adjacentPlot = nil;
	-- Place a ressource, first inner ring, then anywhere in 4 tiles


-- Inner ring
-- Tiles #6 to #17
	for i = 6, 17 do
		adjacentPlot = GetAdjacentTiles(plot, i);
		if (adjacentPlot ~= nil) then
			if(adjacentPlot:GetResourceCount() == 0) then
				if(ResourceBuilder.CanHaveResource(adjacentPlot, eResourceType) and adjacentPlot:IsImpassable() == false) then
					ResourceBuilder.SetResourceType(adjacentPlot, eResourceType,1);
					__Debug("Evaluate Start X: ", adjacentPlot:GetX(), "Evaluate Start Y: ", adjacentPlot:GetY(), "Added: ", eResourceType);
					return true;
				end
			end

		end
	end

-- Anywhere within in a 5 tiles radius
	for i = 0, 90 do
		adjacentPlot = GetAdjacentTiles(plot, i);
		if (adjacentPlot ~= nil) then
			if(adjacentPlot:GetResourceCount() == 0) then
				if(ResourceBuilder.CanHaveResource(adjacentPlot, eResourceType) and adjacentPlot:IsImpassable() == false) then
					ResourceBuilder.SetResourceType(adjacentPlot, eResourceType,1);
					__Debug("Evaluate Start X: ", adjacentPlot:GetX(), "Evaluate Start Y: ", adjacentPlot:GetY(), "Added: ", eResourceType);
					return true;
				end
			end

		end
	end

	__Debug("Balance Resources: Failed to Add:", eResourceType);
	return false;
end

------------------------------------------------------------------------------
function FindResource(eResourceType, plot)
	local gridWidth, gridHeight = Map.GetGridSize();
	-- Checks to see if there is a specific strategic in a given distance
	local adjacentPlot = nil;


	for i = 0, 60 do
		adjacentPlot = GetAdjacentTiles(plot, i);
		if (adjacentPlot ~= nil) then
			if(adjacentPlot:GetResourceCount() > 0) then
				if(eResourceType == adjacentPlot:GetResourceType()) then
					__Debug("Evaluate Start X: ", adjacentPlot:GetX(), "Evaluate Start Y: ", adjacentPlot:GetY(), "Found Type: ", adjacentPlot:GetResourceType());
					return true;
				end
			end

		end

	end

	return false;
end

------------------------------------------------------------------------------
function AddLuxuryStarting(plot, type)
	-- Checks to see if it can place a nearby luxury
	local terrainType = plot:GetTerrainType();
	local gridWidth, gridHeight = Map.GetGridSize();
	local iResourcesInDB = 0;
	local plotX = plot:GetX();
	local plotY = plot:GetY();
	local currentContinent = plot:GetContinentType();
	local direction = 0;
	local bHasLuxury = false;
	local adjacentPlot = plot;
	eAddLux	= {};
	eAddLux_Terrain	= {};
	eAddLux_Feature = {};
	local count = 0;

	-- Find what luxury are on the current continent
	plots = Map.GetContinentPlots(currentContinent);
	for i, plot in ipairs(plots) do

		local pPlot = Map.GetPlotByIndex(plot);
		if (pPlot~=nil) then
				if (pPlot:GetResourceCount() > 0) then
					-- 10 is citrus, 34 is jeans
					if (pPlot:GetResourceType() >= 10 and pPlot:GetResourceType() < 34) then
						bHasLuxury = true;
						--__Debug("found luxury at X",  pPlot:GetX(), "Y: ", pPlot:GetY());
						count = count + 1;
						table.insert(eAddLux, pPlot:GetResourceType());
						table.insert(eAddLux_Terrain, pPlot:GetTerrainType());
						table.insert(eAddLux_Feature, pPlot:GetFeatureType());
					end
				end
		end
		
	end

	-- Try placing a Luxury in the 2 inner rings

	if(bHasLuxury == true) then
		for i = 17, 0, -1 do
			adjacentPlot = GetAdjacentTiles(plot, i);
			if (adjacentPlot ~= nil) then
				for j = 1, count do
					if((adjacentPlot:GetTerrainType() == eAddLux_Terrain[j]) and (adjacentPlot:GetResourceType() == -1)) then
						TerrainBuilder.SetFeatureType(adjacentPlot,eAddLux_Feature[j]);
						__Debug("Balancing X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Added a Luxury:",eAddLux[j]);
						ResourceBuilder.SetResourceType(adjacentPlot, eAddLux[j], 1);
						return true;
					end
				end
			end

		end
	end

	__Debug("Balancing X: ", plotX, "Y: ", plotY, "Failed to add a Luxury");
	return false;
end


-------------------------------------------------------------------------------------------------------

function GetAdjacentTiles(plot, index)
	-- This is an extended version of Firaxis, moving like a clockwise snail on the hexagon grids
	local gridWidth, gridHeight = Map.GetGridSize();
	local count = 0;
	local k = 0;
	local adjacentPlot = nil;
	local adjacentPlot2 = nil;
	local adjacentPlot3 = nil;
	local adjacentPlot4 = nil;
	local adjacentPlot5 = nil;


	-- Return Spawn if index < 0
	if(plot ~= nil and index ~= nil) then
		if (index < 0) then
			return plot;
		end

		else

		__Debug("GetAdjacentTiles: Invalid Arguments");
		return nil;
	end

	

	-- Return Starting City Circle if index between #0 to #5 (like Firaxis' GetAdjacentPlot) 
	for i = 0, 5 do
		if(plot:GetX() >= 0 and plot:GetY() < gridHeight) then
			adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), i);
			if (adjacentPlot ~= nil and index == i) then
				return adjacentPlot
			end
		end
	end

	-- Return Inner City Circle if index between #6 to #17

	count = 5;
	for i = 0, 5 do
		if(plot:GetX() >= 0 and plot:GetY() < gridHeight) then
			adjacentPlot2 = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), i);
		end

		for j = i, i+1 do
			--__Debug(i, j)
			k = j;
			count = count + 1;

			if (k == 6) then
				k = 0;
			end

			if (adjacentPlot2 ~= nil) then
				if(adjacentPlot2:GetX() >= 0 and adjacentPlot2:GetY() < gridHeight) then
					adjacentPlot = Map.GetAdjacentPlot(adjacentPlot2:GetX(), adjacentPlot2:GetY(), k);

					else

					adjacentPlot = nil;
				end
			end
		

			if (adjacentPlot ~=nil) then
				if(index == count) then
					return adjacentPlot
				end
			end

		end
	end

	-- #18 to #35 Outer city circle
	count = 0;
	for i = 0, 5 do
		if(plot:GetX() >= 0 and plot:GetY() < gridHeight) then
			adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), i);
			adjacentPlot2 = nil;
			adjacentPlot3 = nil;
			else
			adjacentPlot = nil;
			adjacentPlot2 = nil;
			adjacentPlot3 = nil;
		end
		if (adjacentPlot ~=nil) then
			if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
				adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i);
			end
			if (adjacentPlot3 ~= nil) then
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i);
				end
			end
		end

		if (adjacentPlot2 ~= nil) then
			count = 18 + i * 3;
			if(index == count) then
				return adjacentPlot2
			end
		end

		adjacentPlot2 = nil;

		if (adjacentPlot3 ~= nil) then
			if (i + 1) == 6 then
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), 0);
				end
				else
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i +1);
				end
			end
		end

		if (adjacentPlot2 ~= nil) then
			count = 18 + i * 3 + 1;
			if(index == count) then
				return adjacentPlot2
			end
		end

		adjacentPlot2 = nil;

		if (adjacentPlot ~= nil) then
			if (i+1 == 6) then
				if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), 0);
				end
				if (adjacentPlot3 ~= nil) then
					if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
						adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), 0);
					end
				end
				else
				if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i+1);
				end
				if (adjacentPlot3 ~= nil) then
					if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
						adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i+1);
					end
				end
			end
		end

		if (adjacentPlot2 ~= nil) then
			count = 18 + i * 3 + 2;
			if(index == count) then
				return adjacentPlot2;
			end
		end

	end

	--  #35 #59 These tiles are outside the workable radius of the city
	local count = 0
	for i = 0, 5 do
		if(plot:GetX() >= 0 and plot:GetY() < gridHeight) then
			adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), i);
			adjacentPlot2 = nil;
			adjacentPlot3 = nil;
			adjacentPlot4 = nil;
			else
			adjacentPlot = nil;
			adjacentPlot2 = nil;
			adjacentPlot3 = nil;
			adjacentPlot4 = nil;
		end
		if (adjacentPlot ~=nil) then
			if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
				adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i);
			end
			if (adjacentPlot3 ~= nil) then
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i);
					if (adjacentPlot4 ~= nil) then
						if(adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
							adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i);
						end
					end
				end
			end
		end

		if (adjacentPlot2 ~= nil) then
			terrainType = adjacentPlot2:GetTerrainType();
			if (adjacentPlot2 ~=nil) then
				count = 36 + i * 4;
				if(index == count) then
					return adjacentPlot2;
				end
			end

		end

		if (adjacentPlot3 ~= nil) then
			if (i + 1) == 6 then
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), 0);
				end
				else
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i +1);
				end
			end
		end

		if (adjacentPlot4 ~= nil) then
			if(adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
				adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i);
				if (adjacentPlot2 ~= nil) then
					count = 36 + i * 4 + 1;
					if(index == count) then
						return adjacentPlot2;
					end
				end
			end


		end

		adjacentPlot4 = nil;

		if (adjacentPlot ~= nil) then
			if (i+1 == 6) then
				if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), 0);
				end
				if (adjacentPlot3 ~= nil) then
					if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
						adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), 0);
					end
				end
				else
				if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i+1);
				end
				if (adjacentPlot3 ~= nil) then
					if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
						adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i+1);
					end
				end
			end
		end

		if (adjacentPlot4 ~= nil) then
			if (adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
				adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i);
				if (adjacentPlot2 ~= nil) then
					count = 36 + i * 4 + 2;
					if(index == count) then
						return adjacentPlot2;
					end

				end
			end

		end

		adjacentPlot4 = nil;

		if (adjacentPlot ~= nil) then
			if (i+1 == 6) then
				if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), 0);
				end
				if (adjacentPlot3 ~= nil) then
					if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
						adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), 0);
					end
				end
				else
				if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i+1);
				end
				if (adjacentPlot3 ~= nil) then
					if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
						adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i+1);
					end
				end
			end
		end

		if (adjacentPlot4 ~= nil) then
			if (adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
				if (i+1 == 6) then
					adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), 0);
					else
					adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i+1);
				end
				if (adjacentPlot2 ~= nil) then
					count = 36 + i * 4 + 3;
					if(index == count) then
						return adjacentPlot2;
					end

				end
			end

		end

	end

	--  > #60 to #90

local count = 0
	for i = 0, 5 do
		if(plot:GetX() >= 0 and plot:GetY() < gridHeight) then
			adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), i); --first ring
			adjacentPlot2 = nil;
			adjacentPlot3 = nil;
			adjacentPlot4 = nil;
			adjacentPlot5 = nil;
			else
			adjacentPlot = nil;
			adjacentPlot2 = nil;
			adjacentPlot3 = nil;
			adjacentPlot4 = nil;
			adjacentPlot5 = nil;
		end
		if (adjacentPlot ~=nil) then
			if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
				adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i); --2nd ring
			end
			if (adjacentPlot3 ~= nil) then
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i); --3rd ring
					if (adjacentPlot4 ~= nil) then
						if(adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
							adjacentPlot5 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i); --4th ring
							if (adjacentPlot5 ~= nil) then
								if(adjacentPlot5:GetX() >= 0 and adjacentPlot5:GetY() < gridHeight) then
									adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), i); --5th ring
								end
							end
						end
					end
				end
			end
		end

		if (adjacentPlot2 ~= nil) then
			count = 60 + i * 5;
			if(index == count) then
				return adjacentPlot2; --5th ring
			end
		end

		adjacentPlot2 = nil;

		if (adjacentPlot5 ~= nil) then
			if (i + 1) == 6 then
				if(adjacentPlot5:GetX() >= 0 and adjacentPlot5:GetY() < gridHeight) then
					adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), 0);
				end
				else
				if(adjacentPlot5:GetX() >= 0 and adjacentPlot5:GetY() < gridHeight) then
					adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), i +1);
				end
			end
		end


		if (adjacentPlot2 ~= nil) then
			count = 60 + i * 5 + 1;
			if(index == count) then
				return adjacentPlot2;
			end

		end

		adjacentPlot2 = nil;

		if (adjacentPlot ~=nil) then
			if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
				adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i);
			end
			if (adjacentPlot3 ~= nil) then
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i);
					if (adjacentPlot4 ~= nil) then
						if(adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
							if (i+1 == 6) then
								adjacentPlot5 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), 0);
								else
								adjacentPlot5 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i+1);
							end
							if (adjacentPlot5 ~= nil) then
								if(adjacentPlot5:GetX() >= 0 and adjacentPlot5:GetY() < gridHeight) then
									if (i+1 == 6) then
										adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), 0);
										else
										adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), i+1);
									end
								end
							end
						end
					end
				end
			end
		end

		if (adjacentPlot2 ~= nil) then
			count = 60 + i * 5 + 2;
			if(index == count) then
				return adjacentPlot2;
			end

		end

		if (adjacentPlot ~=nil) then
			if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
				if (i+1 == 6) then
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), 0); -- 2 ring
					else
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i+1); -- 2 ring
				end
			end
			if (adjacentPlot3 ~= nil) then
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					if (i+1 == 6) then
						adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), 0); -- 3ring
						else
						adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i+1); -- 3ring

					end
					if (adjacentPlot4 ~= nil) then
						if(adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
							if (i+1 == 6) then
								adjacentPlot5 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), 0); --4th ring
								else
								adjacentPlot5 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i+1); --4th ring
							end
							if (adjacentPlot5 ~= nil) then
								if(adjacentPlot5:GetX() >= 0 and adjacentPlot5:GetY() < gridHeight) then
									adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), i); --5th ring
								end
							end
						end
					end
				end
			end
		end

		if (adjacentPlot2 ~= nil) then
			count = 60 + i * 5 + 3;
			if(index == count) then
				return adjacentPlot2;
			end

		end
		
		adjacentPlot2 = nil

		if (adjacentPlot ~=nil) then
			if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
				if (i+1 == 6) then
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), 0); -- 2 ring
					else
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i+1); -- 2 ring
				end
			end
			if (adjacentPlot3 ~= nil) then
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					if (i+1 == 6) then
						adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), 0); -- 3ring
						else
						adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i+1); -- 3ring

					end
					if (adjacentPlot4 ~= nil) then
						if(adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
							if (i+1 == 6) then
								adjacentPlot5 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), 0); --4th ring
								else
								adjacentPlot5 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i+1); --4th ring
							end
							if (adjacentPlot5 ~= nil) then
								if(adjacentPlot5:GetX() >= 0 and adjacentPlot5:GetY() < gridHeight) then
									if (i+1 == 6) then
										adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), 0); --5th ring
										else
										adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), i+1); --5th ring
									end
								end
							end
						end
					end
				end
			end
		end

		if (adjacentPlot2 ~= nil) then
			count = 60 + i * 5 + 4;
			if(index == count) then
				return adjacentPlot2;
			end

		end

	end

end

-----------------------------------------------------------------------------
function __Debug(...)
    --print (...);
end
------------------------------------------------------------------------------
-- UI to Gameplay Script Storage -- Obsolete with the Map Injection
------------------------------------------------------------------------------
function OnLocalPlayerHidePlots(player : number,plotIndex : number, index : number)
	Game:SetProperty("BBS_PLOT_HIDDEN_"..player.."_"..index,plotIndex);
	Game:SetProperty("BBS_PLOT_HIDDEN",true)
	-- Example "BBS_PLOT_HIDDEN_0_10"
end

function OnLocalPlayerRevealPlots(player : number,index : number)
	Game:SetProperty("BBS_PLOT_HIDDEN_"..player.."_"..index,nil);
	local iPlotstoHideCount = Game:GetProperty("BBS_TOTAL_PLOT_HIDDEN_"..player);
	local bAllReveal = true;
	if (iPlotstoHideCount ~= nil) then
		for i = 1, iPlotstoHideCount do
			local temp_plot = Game:GetProperty("BBS_PLOT_HIDDEN_"..player.."_"..i);	
			if (temp_plot ~= nil) then
				bAllReveal = false;
			end
		end
	end
	if (bAllReveal == true) then
		Game:SetProperty("BBS_TOTAL_PLOT_HIDDEN_"..player,0);
	end
end

function OnLocalPlayerTotalRevealPlots(player : number)
	local iPlotstoHideCount = Game:GetProperty("BBS_TOTAL_PLOT_HIDDEN_"..player);
	if (iPlotstoHideCount ~= nil) then
		for i = 1, iPlotstoHideCount do
			local temp_plot = Game:SetProperty("BBS_PLOT_HIDDEN_"..player.."_"..i,nil);	
		end
	end
	Game:SetProperty("BBS_TOTAL_PLOT_HIDDEN_"..player,0);
end

function OnLocalPlayerTotalHidePlots(player : number,totalplots : number)
	Game:SetProperty("BBS_TOTAL_PLOT_HIDDEN_"..player,totalplots);
	-- Example "BBS_TOTAL_PLOT_HIDDEN_0"
end

function OnLocalPlayerRevealSpawn(player : number)
	Game:SetProperty("BBS_SPAWN_HIDDEN_"..player,false);
end



function Init_D_Balance()
	print ("---------------------------------------------------------");
	print ("------------- BBS Script v.1.02    -D- Init -------------");
	print ("---------------------------------------------------------");
	if (Game:GetProperty("BBS_INIT_COUNT") == nil) then
		Game:SetProperty("BBS_INIT_COUNT",1)
		else
		Game:SetProperty("BBS_INIT_COUNT",Game:GetProperty("BBS_INIT_COUNT")+1)
	end
	if ( Game:GetProperty("BBS_INIT_COUNT") ) > 1 then
		print ("Init: ", Game:GetProperty("BBS_INIT_COUNT")," times. Turn: ", Game.GetCurrentGameTurn())
	end
	
	if ( Game:GetProperty("BBS_INIT_COUNT") > 1 ) then
		bLaunch = false;
		else
		bLaunch = true
	end
		
	if (Game.GetCurrentGameTurn() == GameConfiguration.GetStartTurn() and bLaunch == true) then
		BBS_Script();
	end

	

end

LuaEvents.UIOnLocalPlayerHidePlotsEvent.Add( OnLocalPlayerHidePlots )
LuaEvents.UIOnLocalPlayerRevealPlotsEvent.Add( OnLocalPlayerRevealPlots )
LuaEvents.UIOnLocalPlayerTotalRevealPlotsEvent.Add( OnLocalPlayerTotalRevealPlots )
LuaEvents.UIOnLocalPlayerTotalHidePlotsEvent.Add( OnLocalPlayerTotalHidePlots )
LuaEvents.UIOnLocalPlayerRevealSpawnEvent.Add ( OnLocalPlayerRevealSpawn );

Init_D_Balance();
