
------------------------------------------------------------------------------
include "MapEnums"
include "MapUtilities"

------------------------------------------------------------------------------
AssignStartingPlots = {};
------------------------------------------------------------------------------
function AssignStartingPlots.Create(args)
	local instance  = {

		-- Core Process member methods
		__InitStartingData					= AssignStartingPlots.__InitStartingData,
		__SetStartMajor						= AssignStartingPlots.__SetStartMajor,
		__SetStartMinor						= AssignStartingPlots.__SetStartMinor,
		__GetWaterCheck						= AssignStartingPlots.__GetWaterCheck,
		__GetValidAdjacent					= AssignStartingPlots.__GetValidAdjacent,
		__NaturalWonderBuffer				= AssignStartingPlots.__NaturalWonderBuffer,
		__BonusResource						= AssignStartingPlots.__BonusResource,
		__TryToRemoveBonusResource			= AssignStartingPlots.__TryToRemoveBonusResource,
		__LuxuryBuffer						= AssignStartingPlots.__LuxuryBuffer,
		__StrategicBuffer					= AssignStartingPlots.__StrategicBuffer,
		__CivilizationBuffer				= AssignStartingPlots.__CivilizationBuffer,
		__MajorCivBuffer					= AssignStartingPlots.__MajorCivBuffer,
		__MinorMajorCivBuffer				= AssignStartingPlots.__MinorMajorCivBuffer,
		__MinorMinorCivBuffer				= AssignStartingPlots.__MinorMinorCivBuffer,
		__BaseFertility						= AssignStartingPlots.__BaseFertility,
		__WeightedFertility					= AssignStartingPlots.__WeightedFertility,
		__AddBonusFoodProduction			= AssignStartingPlots.__AddBonusFoodProduction,
		__AddFood							= AssignStartingPlots.__AddFood,
		__AddProduction						= AssignStartingPlots.__AddProduction,
		__InitStartBias						= AssignStartingPlots.__InitStartBias,
		__StartBiasResources				= AssignStartingPlots.__StartBiasResources,
		__StartBiasFeatures					= AssignStartingPlots.__StartBiasFeatures,
		__StartBiasTerrains					= AssignStartingPlots.__StartBiasTerrains,
		__StartBiasRivers					= AssignStartingPlots.__StartBiasRivers,
		__StartBiasPlotRemoval				= AssignStartingPlots.__StartBiasPlotRemoval,
		__SortByArray						= AssignStartingPlots.__SortByArray,
		__ArraySize							= AssignStartingPlots.__ArraySize,				
		__PreFertilitySort					= AssignStartingPlots.__PreFertilitySort,			
		__SortByFertilityArray				= AssignStartingPlots.__SortByFertilityArray,	
		__AddResourcesBalanced				= AssignStartingPlots.__AddResourcesBalanced,
		__AddResourcesLegendary				= AssignStartingPlots.__AddResourcesLegendary,
		__BalancedStrategic					= AssignStartingPlots.__BalancedStrategic,
		__FindSpecificStrategic				= AssignStartingPlots.__FindSpecificStrategic,
		__AddStrategic						= AssignStartingPlots.__AddStrategic,
		__AddLuxury							= AssignStartingPlots.__AddLuxury,
		__AddBonus							= AssignStartingPlots.__AddBonus,
		__IsContinentalDivide				= AssignStartingPlots.__IsContinentalDivide,
		__RemoveBonus						= AssignStartingPlots.__RemoveBonus,

		iNumMajorCivs = 0,
		iNumWaterMajorCivs = 0,
		iResourceEraModifier = 1,
		iNumMinorCivs = 0,			
		iNumRegions		= 0,
		iDefaultNumberMajor = 0,
		iDefaultNumberMinor = 0,
		uiMinMajorCivFertility = args.MIN_MAJOR_CIV_FERTILITY or 0,
		uiMinMinorCivFertility = args.MIN_MINOR_CIV_FERTILITY or 0,
		uiStartMinY = args.START_MIN_Y or 0,
		uiStartMaxY = args.START_MAX_Y or 0,
		uiStartConfig = args.START_CONFIG or 2,
		waterMap  = args.WATER or false,
		landMap  = args.LAND or false,
		majorStartPlots = {},
		majorCopy = {},
		minorStartPlots = {},	
		minorCopy = {},
		majorList		= {},
		minorList		= {},
		playerstarts = {},
		sortedArray = {},
		sortedFertilityArray = {},

		-- Team info variables (not used in the core process, but necessary to many Multiplayer map scripts)
		
	}

	instance:__InitStartingData()
	


	return instance
end
------------------------------------------------------------------------------
--function shuffle(tbl)
--  size = #tbl
--  for i = size, 0, -1 do
--    local rand = math.random(size)
--    tbl[i], tbl[rand] = tbl[rand], tbl[i]
--  end
--  return tbl
--end

function AssignStartingPlots:__InitStartingData()
	if(self.uiMinMajorCivFertility <= 0) then
		self.uiMinMajorCivFertility = 5;
	end

	if(self.uiMinMinorCivFertility <= 0) then
		self.uiMinMinorCivFertility = 5;
	end

	--Find Default Number
	MapSizeTypes = {};
	for row in GameInfo.Maps() do
		MapSizeTypes[row.RowId] = row.DefaultPlayers;
	end
	local sizekey = Map.GetMapSize() + 1;
	local iDefaultNumberPlayers = MapSizeTypes[sizekey] or 8;
	self.iDefaultNumberMajor = iDefaultNumberPlayers ;
	self.iDefaultNumberMinor = math.floor(iDefaultNumberPlayers * 1.5);

	-- See if there are any civs starting out in the water
	local tempMajorList = {};
	self.majorList = {};
	self.waterMajorList = {};
	self.iNumMajorCivs = 0;
	self.iNumWaterMajorCivs = 0;

	tempMajorList = PlayerManager.GetAliveMajorIDs();
	for i = 1, PlayerManager.GetAliveMajorsCount() do
		local leaderType = PlayerConfigurations[tempMajorList[i]]:GetLeaderTypeName();
		if (GameInfo.Leaders_XP2[leaderType] ~= nil and GameInfo.Leaders_XP2[leaderType].OceanStart == true) then
			table.insert(self.waterMajorList, tempMajorList[i]);
			self.iNumWaterMajorCivs = self.iNumWaterMajorCivs + 1;
			print ("Found the Maori");
		else
			table.insert(self.majorList, tempMajorList[i]);
			self.iNumMajorCivs = self.iNumMajorCivs + 1;
		end
	end 

	-- Do we have enough water on this map for the number of water civs specified?
	local TILES_NEEDED_FOR_WATER_START = 8;
	if (self.waterMap == true) then
		TILES_NEEDED_FOR_WATER_START = 1;
	end
	local iCandidateWaterTiles = StartPositioner.GetTotalOceanStartCandidates(self.waterMap);
	if (iCandidateWaterTiles < (TILES_NEEDED_FOR_WATER_START * self.iNumWaterMajorCivs)) then
		-- Not enough so reset so all civs start on land
		self.iNumMajorCivs = 0;
		self.majorList = {};
		for i = 1, PlayerManager.GetAliveMajorsCount() do
			table.insert(self.majorList, tempMajorList[i]);
			self.iNumMajorCivs = self.iNumMajorCivs + 1;
		end
	end

	self.iNumMinorCivs = PlayerManager.GetAliveMinorsCount();
	self.minorList = {};
	self.minorList = PlayerManager.GetAliveMinorIDs();
	self.iNumRegions = self.iNumMajorCivs + self.iNumMinorCivs * 2;
	local iMinNumBarbarians = self.iNumMajorCivs / 2;
	
	StartPositioner.DivideMapIntoMajorRegions(self.iNumMajorCivs, self.uiMinMajorCivFertility, self.uiMinMinorCivFertility);
	local iMajorCivStartLocs = StartPositioner.GetNumMajorCivStarts();

	print ("-- MAJOR CIV START LOCS: " .. tostring(iMajorCivStartLocs) .. " --");	
	self.majorStartPlots = {};
	local failed = 0;
	for i = self.iNumMajorCivs - 1, 0, - 1 do
		plots = StartPositioner.GetMajorCivStartPlots(i);
		local startPlot = self:__SetStartMajor(plots, i);
		if(startPlot ~= nil) then
			StartPositioner.MarkMajorRegionUsed(i);
			table.insert(self.majorStartPlots, startPlot);
			info = StartPositioner.GetMajorCivStartInfo(i);
			print ("ContinentType: " .. tostring(info.ContinentType));
			print ("LandmassID: " .. tostring(info.LandmassID));
			print ("Fertility: " .. tostring(info.Fertility));
			print ("TotalPlots: " .. tostring(info.TotalPlots));
			print ("WestEdge: " .. tostring(info.WestEdge));
			print ("EastEdge: " .. tostring(info.EastEdge));
			print ("NorthEdge: " .. tostring(info.NorthEdge));
			print ("SouthEdge: " .. tostring(info.SouthEdge));
		else
			failed = failed + 1;
			info = StartPositioner.GetMajorCivStartInfo(i);
			print ("-- START FAILED MAJOR --");
			print ("ContinentType: " .. tostring(info.ContinentType));
			print ("LandmassID: " .. tostring(info.LandmassID));
			print ("Fertility: " .. tostring(info.Fertility));
			print ("TotalPlots: " .. tostring(info.TotalPlots));
			print ("WestEdge: " .. tostring(info.WestEdge));
			print ("EastEdge: " .. tostring(info.EastEdge));
			print ("NorthEdge: " .. tostring(info.NorthEdge));
			print ("SouthEdge: " .. tostring(info.SouthEdge));
			print ("-- END FAILED MAJOR --");
		end
	end
	
	print ("-- START FAILED MAJOR LOOP--");
	local count = self.iNumMajorCivs;
	while failed > 0 and iMajorCivStartLocs > count do
		print ("FAILED == " .. tostring(failed));
		print ("count == " .. tostring(count));
		plots = StartPositioner.GetMajorCivStartPlots(count);
		local startPlot = self:__SetStartMajor(plots, count);
		if(startPlot ~= nil) then
			StartPositioner.MarkMajorRegionUsed(count);
			table.insert(self.majorStartPlots, startPlot);
			info = StartPositioner.GetMajorCivStartInfo(count);
			print ("ContinentType2: " .. tostring(info.ContinentType));
			print ("LandmassID2: " .. tostring(info.LandmassID));
			print ("Fertility2: " .. tostring(info.Fertility));
			print ("TotalPlots2: " .. tostring(info.TotalPlots));
			print ("WestEdge2: " .. tostring(info.WestEdge));
			print ("EastEdge2: " .. tostring(info.EastEdge));
			print ("NorthEdge2: " .. tostring(info.NorthEdge));
			print ("SouthEdge2: " .. tostring(info.SouthEdge));
			failed = failed - 1;
		else
			info = StartPositioner.GetMajorCivStartInfo(count);
			print ("X2ContinentType: " .. tostring(info.ContinentType));
			print ("X2LandmassID: " .. tostring(info.LandmassID));
			print ("X2Fertility: " .. tostring(info.Fertility));
			print ("X2TotalPlots: " .. tostring(info.TotalPlots));
			print ("X2WestEdge: " .. tostring(info.WestEdge));
			print ("X2EastEdge: " .. tostring(info.EastEdge));
			print ("X2NorthEdge: " .. tostring(info.NorthEdge));
			print ("X2SouthEdge: " .. tostring(info.SouthEdge));
			print("faILed MAJOR MINOR");
		end
		count = count + 1;
	end
	print ("-- END FAILED MAJOR LOOP--");

	for k, plot in ipairs(self.majorStartPlots) do
		table.insert(self.majorCopy, plot);
	end

	--Begin Start Bias for major
	self:__InitStartBias(false);

	if(self.uiStartConfig == 1 ) then
		self:__AddResourcesBalanced();
	elseif(self.uiStartConfig == 3 ) then
		self:__AddResourcesLegendary();
	end

	local aMajorStartPlotIndices = {};
	for i = 1, self.iNumMajorCivs do
		local player = Players[self.majorList[i]]
		
		if (player == nil) then
			print("THIS PLAYER FAILED");
		else
			local hasPlot = false;
			for k, v in pairs(self.playerStarts[i]) do
				if (v~= nil and hasPlot == false) then
					hasPlot = true;
					player:SetStartingPlot(v);
					table.insert(aMajorStartPlotIndices, v:GetIndex());
					print("Major Start X: ", v:GetX(), "Major Start Y: ", v:GetY());
				end
			end
		end
	end

	StartPositioner.DivideMapIntoMinorRegions(self.iNumMinorCivs * 2);

	local iMinorCivStartLocs = StartPositioner.GetNumMinorCivStarts() * 2;
	local i = 0;
	local valid = 0;
	print ("-- MINOR CIV START LOCS: " .. tostring(iMinorCivStartLocs) .. " --");
	while i <= iMinorCivStartLocs - 1 and valid < self.iNumMinorCivs do
		plots = StartPositioner.GetMinorCivStartPlots(i);
		local startPlot = self:__SetStartMinor(plots);
		info = StartPositioner.GetMinorCivStartInfo(i);
		if(startPlot ~= nil) then
			table.insert(self.minorStartPlots, startPlot);
			print ("Minor ContinentType: " .. tostring(info.ContinentType));
			print ("Minor LandmassID: " .. tostring(info.LandmassID));
			print ("Minor Fertility: " .. tostring(info.Fertility));
			print ("Minor TotalPlots: " .. tostring(info.TotalPlots));
			print ("Minor WestEdge: " .. tostring(info.WestEdge));
			print ("Minor EastEdge: " .. tostring(info.EastEdge));
			print ("Minor NorthEdge: " .. tostring(info.NorthEdge));
			print ("Minor SouthEdge: " .. tostring(info.SouthEdge));
			valid = valid + 1;
		else
			print ("-- START FAILED MINOR --");
			print ("Minor ContinentType: " .. tostring(info.ContinentType));
			print ("Minor LandmassID: " .. tostring(info.LandmassID));
			print ("Minor Fertility: " .. tostring(info.Fertility));
			print ("Minor TotalPlots: " .. tostring(info.TotalPlots));
			print ("Minor WestEdge: " .. tostring(info.WestEdge));
			print ("Minor EastEdge: " .. tostring(info.EastEdge));
			print ("Minor NorthEdge: " .. tostring(info.NorthEdge));
			print ("Minor SouthEdge: " .. tostring(info.SouthEdge));
			print ("-- END FAILED MINOR --");
		end
		i = i + 1;
	end
	
	for k, plot in ipairs(self.minorStartPlots) do
		table.insert(self.minorCopy, plot);
	end

	--Begin Start Bias for minor
	self:__InitStartBias(true);

	for i = 1, self.iNumMinorCivs do
		local player = Players[self.minorList[i]]
		
		if (player == nil) then
			print("THIS PLAYER FAILED");
		else
			local hasPlot = false;
			for k, v in pairs(self.playerStarts[i + self.iNumMajorCivs]) do
				if (v~= nil and hasPlot == false) then
					hasPlot = true;
					player:SetStartingPlot(v);
					print("Minor Start X: ", v:GetX(), "Minor Start Y: ", v:GetY());
				end
			end
		end
	end
	
	-- Finally place the ocean civs
	if (self.iNumWaterMajorCivs > 0) then
		local iWaterCivs = StartPositioner.PlaceOceanStartCivs(self.waterMap, self.iNumWaterMajorCivs, aMajorStartPlotIndices);
		for i = 1, iWaterCivs do
			local waterPlayer = Players[self.waterMajorList[i]]
			local iStartIndex = StartPositioner.GetOceanStartTile(i - 1);  -- Indices start at 0 here
			local pStartPlot = Map.GetPlotByIndex(iStartIndex);
			waterPlayer:SetStartingPlot(pStartPlot);
			print("Water Start X: ", pStartPlot:GetX(), "Water Start Y: ", pStartPlot:GetY());
		end
		if (iWaterCivs < self.iNumWaterMajorCivs) then
			print("FAILURE PLACING WATER CIVS - Missing civs: " .. tostring(self.iNumWaterMajorCivs - iWaterCivs));
		end
	end
end

------------------------------------------------------------------------------
function AssignStartingPlots:__SetStartMajor(plots, iMajorIndex)
	-- Sort by fertility of all the plots
	-- eliminate them if they do not meet the following:
	-- distance to another civilization
	-- distance to a natural wonder
	-- minimum production
	-- minimum food
	-- minimum luxuries
	-- minimum strategic

	sortedPlots ={};

	if plots == nil then
		return;
	end

	local iSize = #plots;
	local iContinentIndex = 1;
	
	-- Nothing there?  Just exit, returing nil
	if iSize == 0 then
		return;
	end
	
	for i, plot in ipairs(plots) do
		row = {};
		row.Plot = plot;
		row.Fertility = self:__WeightedFertility(plot, iMajorIndex, true);
		table.insert (sortedPlots, row);
	end

	if(self.uiStartConfig > 1 ) then
		table.sort (sortedPlots, function(a, b) return a.Fertility > b.Fertility; end);
	else
		self.sortedFertilityArray = {};
		sortedPlotsFertility = {};
		sortedPlotsFertility = self:__PreFertilitySort(sortedPlots);
		self:__SortByFertilityArray(sortedPlots, sortedPlotsFertility);
		for k, v in pairs(sortedPlots) do
			sortedPlots[k] = nil;
		end
		for i, newPlot in ipairs(self.sortedFertilityArray) do
			row = {};
			row.Plot = newPlot.Plot;
			row.Fertility = newPlot.Fertility;
			table.insert (sortedPlots, row);
		end
	end

	local bValid = false;
	local pFallback:table = Map.GetPlotByIndex(sortedPlots[1].Plot);
	local iFallBackScore = -1;
	while bValid == false and iSize >= iContinentIndex do
		bValid = true;
		local NWMajor = 0;
		pTempPlot = Map.GetPlotByIndex(sortedPlots[iContinentIndex].Plot);
		iContinentIndex = iContinentIndex + 1;
		--print("Fertility: ", sortedPlots[iContinentIndex].Fertility)

		-- Checks to see if the plot is impassable
		if(pTempPlot:IsImpassable() == true) then
			bValid = false;
		else
			local iFallBackScoreTemp = 0;
			if (iFallBackScore < iFallBackScoreTemp) then
				pFallback = pTempPlot;
				iFallBackScore = iFallBackScoreTemp;
			end
		end

		-- Checks to see if the plot is water
		if(pTempPlot:IsWater() == true) then
			bValid = false;
		else
			local iFallBackScoreTemp = 1;
			if (iFallBackScore < iFallBackScoreTemp and bValid == true) then
				pFallback = pTempPlot;
				iFallBackScore = iFallBackScoreTemp;
			end
		end
		
		-- Checks to see if there are any major civs in the given distance
		local bMajorCivCheck = self:__MajorCivBuffer(pTempPlot); 
		if(bMajorCivCheck == false) then
			bValid = false;
		else
			local iFallBackScoreTemp = 2;
			if (iFallBackScore < iFallBackScoreTemp and bValid == true) then
				pFallback = pTempPlot;
				iFallBackScore = iFallBackScoreTemp;
			end
		end	

		-- Checks to see if there are luxuries
		if (math.ceil(self.iDefaultNumberMajor * 1.25) + self.iDefaultNumberMinor > self.iNumMinorCivs + self.iNumMajorCivs) then
			local bLuxuryCheck = self:__LuxuryBuffer(pTempPlot); 
			if(bLuxuryCheck  == false) then
				bValid = false;
			else
				local iFallBackScoreTemp = 3;
			if (iFallBackScore < iFallBackScoreTemp and bValid == true) then
				pFallback = pTempPlot;
				iFallBackScore = iFallBackScoreTemp;
			end
			end
		end
		

		--Checks to see if there are strategics
		-- local bStrategicCheck = self:__StrategicBuffer(pTempPlot); 
		-- if(bStrategicCheck  == false) then
		-- 	bValid = false;
		-- end

		-- Checks to see if there is fresh water or coast
		local bWaterCheck = self:__GetWaterCheck(pTempPlot); 
		if(bWaterCheck == false) then
			bValid = false;
		else
			local iFallBackScoreTemp = 4;
			if (iFallBackScore < iFallBackScoreTemp and bValid == true) then
				pFallback = pTempPlot;
				iFallBackScore = iFallBackScoreTemp;
			end
		end

		local bValidAdjacentCheck = self:__GetValidAdjacent(pTempPlot, 0); 
		if(bValidAdjacentCheck == false) then
			bValid = false;
		else
			local iFallBackScoreTemp = 5;
			if (iFallBackScore < iFallBackScoreTemp and bValid == true) then
				pFallback = pTempPlot;
				iFallBackScore = iFallBackScoreTemp;
			end
		end

		-- Checks to see if there are natural wonders in the given distance
		local bNaturalWonderCheck = self:__NaturalWonderBuffer(pTempPlot, false); 
		if(bNaturalWonderCheck == false) then
			bValid = false;
		else
			local iFallBackScoreTemp = 6;
			if (iFallBackScore < iFallBackScoreTemp and bValid == true) then
				pFallback = pTempPlot;
				iFallBackScore = iFallBackScoreTemp;
			end
		end
		
		-- Checks to see if there are resources
		if(pTempPlot:GetResourceCount() > 0) then
		   local bValidResource = self:__BonusResource(pTempPlot);
		    if(bValidResource == false) then
		       bValid = false;
			end
		else
			local iFallBackScoreTemp = 7;
			if (iFallBackScore < iFallBackScoreTemp and bValid == true) then
				pFallback = pTempPlot;
				iFallBackScore = iFallBackScoreTemp;
			end
		end

		-- Checks to see if there is an Oasis
		local featureType = pTempPlot:GetFeatureType();
		if(featureType == g_FEATURE_OASIS) then
			bValid = false;
		end

		-- If the plots passes all the checks then the plot equals the temp plot
		if(bValid == true) then
			self:__TryToRemoveBonusResource(pTempPlot);
			self:__AddBonusFoodProduction(pTempPlot);
			return pTempPlot;
		end
	end
	return nil;
	--return pFallback;
end

------------------------------------------------------------------------------
function AssignStartingPlots:__SetStartMinor(plots)
	-- Sort by fertility of all the plots
	-- eliminate them if they do not meet the following:
	-- distance to another civilization
	-- distance to a natural wonder
	-- minimum production
	-- minimum food

	sortedPlots ={};
	
	if plots == nil then
		return;
	end
	
	local iSize = #plots;

	-- Nothing there?  Just exit, returing nil
	if iSize == 0 then
		return;
	end

	local iContinentIndex = 1;

	for i, plot in ipairs(plots) do
		row = {};
		row.Plot = plot;
		row.Fertility = self:__BaseFertility(plot);
		table.insert (sortedPlots, row);
	end

	table.sort (sortedPlots, function(a, b) return a.Fertility > b.Fertility; end);

	local bValid = false;
	local pFallback:table = Map.GetPlotByIndex(sortedPlots[1].Plot);
	local iFallBackScore = -1;
	while bValid == false and iSize >= iContinentIndex do
		bValid = true;
		local NWMinor = 2;
		pTempPlot = Map.GetPlotByIndex(sortedPlots[iContinentIndex].Plot);
		iContinentIndex = iContinentIndex + 1;
		--print("Fertility: ", sortedPlots[iContinentIndex].Fertility)

		-- Checks to see if the plot is impassable
		if(pTempPlot:IsImpassable() == true) then
			bValid = false;
		else
			local iFallBackScoreTemp = 0;
			if (iFallBackScore < iFallBackScoreTemp) then
				pFallback = pTempPlot;
				iFallBackScore = iFallBackScoreTemp;
			end
		end

		-- Checks to see if the plot is water
		if(pTempPlot:IsWater() == true) then
			bValid = false;
		else
			local iFallBackScoreTemp = 1;
			if (iFallBackScore < iFallBackScoreTemp and bValid == true) then
				pFallback = pTempPlot;
				iFallBackScore = iFallBackScoreTemp;
			end
		end
		
		-- Checks to see if there are any minor civs in the given distance
		local bMinorCivCheck = self:__MinorMajorCivBuffer(pTempPlot); 
		if(bMinorCivCheck == false) then
			bValid = false;
		else
			local iFallBackScoreTemp = 2;
			if (iFallBackScore < iFallBackScoreTemp and bValid == true) then
				pFallback = pTempPlot;
				iFallBackScore = iFallBackScoreTemp;
			end
		end		

		-- Checks to see if there are any minor civs in the given distance
		local bMinorCivCheck = self:__MinorMinorCivBuffer(pTempPlot); 
		if(bMinorCivCheck == false) then
			bValid = false;
		else
			local iFallBackScoreTemp = 3;
			if (iFallBackScore < iFallBackScoreTemp and bValid == true) then
				pFallback = pTempPlot;
				iFallBackScore = iFallBackScoreTemp;
			end
		end		

		local bValidAdjacentCheck = self:__GetValidAdjacent(pTempPlot, 2); 
		if(bValidAdjacentCheck == false) then
			bValid = false;
		else
			local iFallBackScoreTemp = 4;
			if (iFallBackScore < iFallBackScoreTemp and bValid == true) then
				pFallback = pTempPlot;
				iFallBackScore = iFallBackScoreTemp;
			end
		end

		-- Checks to see if there are natural wonders in the given distance
		local bNaturalWonderCheck = self:__NaturalWonderBuffer(pTempPlot, true); 
		if(bNaturalWonderCheck == false) then
			bValid = false;
		else
			local iFallBackScoreTemp = 5;
			if (iFallBackScore < iFallBackScoreTemp and bValid == true) then
				pFallback = pTempPlot;
				iFallBackScore = iFallBackScoreTemp;
			end
		end

		-- Checks to see if there are resources
		if(pTempPlot:GetResourceCount() > 0) then
			local bValidResource = self:__BonusResource(pTempPlot);
			if(bValidResource == false) then
				bValid = false;
			end
		else
			local iFallBackScoreTemp = 6;
			if (iFallBackScore < iFallBackScoreTemp and bValid == true) then
				pFallback = pTempPlot;
				iFallBackScore = iFallBackScoreTemp;
			end
		end

		-- Checks to see if there is an Oasis
		local featureType = pTempPlot:GetFeatureType();
		if(featureType == g_FEATURE_OASIS) then
			bValid = false;
		end

		-- If the plots passes all the checks then the plot equals the temp plot
		if(bValid == true) then
			self:__TryToRemoveBonusResource(pTempPlot);
			return pTempPlot;
		end
	end
 
	--return pFallback;
	return nil;
end

------------------------------------------------------------------------------
function AssignStartingPlots:__GetWaterCheck(plot)

	--Checks to see if there is water: rivers, it is a coastal hex, or adjacent fresh water
	local gridWidth, gridHeight = Map.GetGridSize();

	if(plot:IsFreshWater() == true) then
		return true;
	elseif( plot:IsCoastalLand() == true) then
		return true;
	end

	return false;
end
------------------------------------------------------------------------------
function AssignStartingPlots:__GetValidAdjacent(plot, minor)
	
	local impassable = 0;
	local food = 0;
	local production = 0;
	local water = 0;
	local desert = 0;
	local snow = 0;
	local tundra = 0;
	local gridWidth, gridHeight = Map.GetGridSize();
	local terrainType = plot:GetTerrainType();

	-- Add to the Snow Desert counter if snow shows up
	if(terrainType == g_TERRAIN_TYPE_SNOW or terrainType == g_TERRAIN_TYPE_SNOW_HILLS) then
		snow = snow + 2;
	end
	
	-- Add to the Snow Desert counter if desert shows up
	if(terrainType == g_TERRAIN_TYPE_DESERT or terrainType == g_TERRAIN_TYPE_DESERT_HILLS) then
		desert = desert + 2;
	end

	local max = 0;
	local min = 0; 
	if(minor == 0) then
		max = math.ceil(gridHeight * self.uiStartMaxY / 100);
		min = math.ceil(gridHeight * self.uiStartMinY / 100);
	end

	if(plot:GetY() <= min or plot:GetY() > gridHeight - max) then
		return false;
	end

	for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
		local adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), direction);
		if (adjacentPlot ~= nil) then
			terrainType = adjacentPlot:GetTerrainType();
			if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
				-- Checks to see if the plot is impassable
				if(adjacentPlot:IsImpassable() == true) then
					impassable = impassable + 1;
				end

				-- Checks to see if the plot is water
				if(adjacentPlot:IsWater() == true) then
					water = water + 1;
				end

				-- Add to the Snow Desert counter if snow shows up
				if(terrainType == g_TERRAIN_TYPE_SNOW or terrainType == g_TERRAIN_TYPE_SNOW_HILLS) then
					snow = snow + 2;
				end

				-- Add to the Tundra counter if tundra shows up
				if(terrainType == g_TERRAIN_TYPE_TUNDRA or terrainType == g_TERRAIN_TYPE_TUNDRA_HILLS) then
					tundra = tundra + 2;
				end
			
				-- Add to the Snow Desert counter if desert shows up
				if(terrainType == g_TERRAIN_TYPE_DESERT or terrainType == g_TERRAIN_TYPE_DESERT_HILLS) then
					desert = desert + 2;
				end

				food = food + adjacentPlot:GetYield(g_YIELD_FOOD);
				production = production + adjacentPlot:GetYield(g_YIELD_PRODUCTION);
			else
				impassable = impassable + 1;
			end
		end
	end 

	--if(minor == 0) then
	--	print("X: ", plot:GetX(), " Y: ", plot:GetY(), " Food ", food, "Production: ", production);
	--end

	local balancedStart = 0;
	if(self.uiStartConfig == 1 and  minor == 0) then
		balancedStart = 1;
	end

	if((impassable >= 2 + minor - balancedStart or (self.landMap == true and impassable >= 2 + minor)) and self.waterMap == false) then
		return false;
	elseif(self.waterMap == true and impassable >= 2 + minor * 2 - balancedStart) then
		return false;
	elseif(water + impassable  >= 4 + minor - balancedStart and self.waterMap == false) then
		return false;
	elseif(water >= 3 + minor - balancedStart) then
		return false;
	elseif(water >= 4 + minor and self.waterMap == true) then
		return false;
	elseif(minor == 0 and desert > 1 - balancedStart) then
		return false;
	elseif(minor == 0 and snow > 1 - balancedStart) then
		return false;
	elseif(minor == 0 and tundra > 1 - balancedStart) then
		return false;
	elseif(minor > 0 and snow > 2) then
		return false;
	else
		return true;
	end
end

------------------------------------------------------------------------------
function AssignStartingPlots:__BaseFertility(plot)

	-- Calculate the fertility of the starting plot
	local pPlot = Map.GetPlotByIndex(plot);
	local iFertility = StartPositioner.GetPlotFertility(pPlot:GetIndex(), -1);
	return iFertility;
end

------------------------------------------------------------------------------
function AssignStartingPlots:__WeightedFertility(plot, iMajorIndex, bCheckOthers)

	-- Calculate the fertility of the starting plot
	local pPlot = Map.GetPlotByIndex(plot);
	local iFertility = StartPositioner.GetPlotFertility(pPlot:GetIndex(), iMajorIndex, bCheckOthers);
	return iFertility;
end

------------------------------------------------------------------------------
function AssignStartingPlots:__NaturalWonderBuffer(plot, minor)
	-- Returns false if the player can start because there is a natural wonder too close.

	-- If Start position config equals legendary you can start near Natural wonders
	if(self.uiStartConfig == 3) then
		return true;
	end

	local iMaxNW = 4;
	
	
	if(minor == true) then
		iMaxNW = GlobalParameters.START_DISTANCE_MINOR_NATURAL_WONDER or 3;
	else
		iMaxNW = GlobalParameters.START_DISTANCE_MAJOR_NATURAL_WONDER or 3;
	end


	local plotX = plot:GetX();
	local plotY = plot:GetY();
	for dx = -iMaxNW, iMaxNW do
		for dy = -iMaxNW,iMaxNW do
			local otherPlot = Map.GetPlotXY(plotX, plotY, dx, dy, iMaxNW);
			if(otherPlot and otherPlot:IsNaturalWonder()) then
				return false;
			end
		end
	end 

	return true;
end

------------------------------------------------------------------------------
function AssignStartingPlots:__BonusResource(plot)
	--Finds bonus resources

	local iResourcesInDB = 0;
	eResourceType	= {};
	eResourceClassType = {};

	for row in GameInfo.Resources() do
		eResourceType[iResourcesInDB] = row.Index;
		eResourceClassType[iResourcesInDB] = row.ResourceClassType;
	    iResourcesInDB = iResourcesInDB + 1;
	end

	--Find bonus resource
	for row = 0, iResourcesInDB do
		if (eResourceClassType[row] == "RESOURCECLASS_BONUS") then
			if(eResourceType[row] == plot:GetResourceType()) then
				return true;
			end
		end		
	end 

	return false;
end

------------------------------------------------------------------------------
function AssignStartingPlots:__TryToRemoveBonusResource(plot)
	--Removes Bonus Resources underneath starting players

	--Remove bonus resource
	local iResourcesInDB = 0;
	eResourceType	= {};
	eResourceClassType = {};

	for row in GameInfo.Resources() do
		eResourceType[iResourcesInDB] = row.Index;
		eResourceClassType[iResourcesInDB] = row.ResourceClassType;
	    iResourcesInDB = iResourcesInDB + 1;
	end

	for row = 0, iResourcesInDB do
		if (eResourceClassType[row] == "RESOURCECLASS_BONUS") then
			if(eResourceType[row] == plot:GetResourceType()) then
				ResourceBuilder.SetResourceType(plot, -1);
			end
		end		
	end 
end

------------------------------------------------------------------------------
function AssignStartingPlots:__LuxuryBuffer(plot)
	-- Checks to see if there are luxuries in the given distance

	local iResourcesInDB = 0;
	eResourceType	= {};
	eResourceClassType = {};

	for row in GameInfo.Resources() do
		eResourceType[iResourcesInDB] = row.Index;
		eResourceClassType[iResourcesInDB] = row.ResourceClassType;
	    iResourcesInDB = iResourcesInDB + 1;
	end

	local plotX = plot:GetX();
	local plotY = plot:GetY();
	for dx = -2, 2 do
		for dy = -2,2 do
			local otherPlot = Map.GetPlotXY(plotX, plotY, dx, dy, 2);
			if(otherPlot) then
				if(otherPlot:GetResourceCount() > 0) then
					for row = 0, iResourcesInDB do
						if (eResourceClassType[row]== "RESOURCECLASS_LUXURY") then
							if(eResourceType[row] == otherPlot:GetResourceType()) then
								return true;
							end
						end
					end
				end
			end
		end
	end 

	return false;
end

------------------------------------------------------------------------------
function AssignStartingPlots:__StrategicBuffer(plot)
	-- Checks to see if there are strategics in the given distance

	local iResourcesInDB = 0;
	eResourceType	= {};
	eResourceClassType = {};

	for row in GameInfo.Resources() do
		eResourceType[iResourcesInDB] = row.Index;
		eResourceClassType[iResourcesInDB] = row.ResourceClassType;
	    iResourcesInDB = iResourcesInDB + 1;
	end

	local plotX = plot:GetX();
	local plotY = plot:GetY();
	for dx = -2, 2 do
		for dy = -2,2 do
			local otherPlot = Map.GetPlotXY(plotX, plotY, dx, dy, 2);
			if(otherPlot) then
				if(otherPlot:GetResourceCount() > 0) then
					for row = 0, iResourcesInDB do
						if (eResourceClassType[row]== "RESOURCECLASS_STRATEGIC") then
							if(eResourceType[row] == otherPlot:GetResourceType()) then
								return true;
							end
						end
					end
				end
			end
		end
	end 

	return false;
end

------------------------------------------------------------------------------
function AssignStartingPlots:__MajorCivBuffer(plot)
	-- Checks to see if there are major civs in the given distance for this major civ

--	local iMaxStart = GlobalParameters.START_DISTANCE_MAJOR_CIVILIZATION or 9;
--	iMaxStart = iMaxStart - GlobalParameters.START_DISTANCE_RANGE_MAJOR or 2;
	local iMaxStart = 10;
	
	local iSourceIndex = plot:GetIndex();
	for i, majorPlot in ipairs(self.majorStartPlots) do
		if(Map.GetPlotDistance(iSourceIndex, majorPlot:GetIndex()) <= iMaxStart) then
			return false;
		end
	end 

	return true;
end

------------------------------------------------------------------------------
function AssignStartingPlots:__MinorMajorCivBuffer(plot)
	-- Checks to see if there are majors in the given distance for this minor civ

	--local iMaxStart = GlobalParameters.START_DISTANCE_MINOR_MAJOR_CIVILIZATION or 7;
	local iMaxStart = 8;

	local iSourceIndex = plot:GetIndex();
	
	if(self.waterMap == true) then
		iMaxStart = iMaxStart - 1;
	end
	
	for i, majorPlot in ipairs(self.majorCopy) do
		if(Map.GetPlotDistance(iSourceIndex, majorPlot:GetIndex()) <= iMaxStart) then
			return false;
		end
	end 

	return true;
end

------------------------------------------------------------------------------
function AssignStartingPlots:__MinorMinorCivBuffer(plot)
	-- Checks to see if there are minors in the given distance for this minor civ

	--local iMaxStart = GlobalParameters.START_DISTANCE_MINOR_CIVILIZATION_START or 5;
	--iMaxStart = iMaxStart - GlobalParameters.START_DISTANCE_RANGE_MINOR or 2;
	local iMaxStart = 7;

	local iSourceIndex = plot:GetIndex();

	for i, minorPlot in ipairs(self.minorStartPlots) do
		if(Map.GetPlotDistance(iSourceIndex, minorPlot:GetIndex()) <= iMaxStart) then
			return false;
		end
	end 

	return true;
end

------------------------------------------------------------------------------
function AssignStartingPlots:__AddBonusFoodProduction(plot)
	local food = 0;
	local production = 0;
	local maxFood = 0;
	local maxProduction = 0;
	local gridWidth, gridHeight = Map.GetGridSize();
	local terrainType = plot:GetTerrainType();
	local keepTryingP = true;
	local keepTryingF = true;
	local plains = 0;

	for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
		local adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), direction);
		if (adjacentPlot ~= nil) then
			if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
				if (adjacentPlot:GetTerrainType() == g_TERRAIN_TYPE_PLAINS or adjacentPlot:GetTerrainType() == g_TERRAIN_TYPE_PLAINS_HILLS) then
					plains = plains + 1;
				end
			end              
		end
	end
	 
	local minProd = 8;
	local minFood = 8;
	if (plains == 3) then 
		minProd = 10;
	elseif (plains > 3) then 
		minProd = 11;
	end
	
	while ( (production < minProd and keepTryingP) or (food < minFood and keepTryingF) ) do
		print("DEBUG: production = " .. tostring(minProd));
		print("DEBUG: keepTryingP = " .. tostring(keepTryingP));
		print("DEBUG: food = " .. tostring(food));
		print("DEBUG: keepTryingF = " .. tostring(keepTryingF));

		production = 0;
		food = 0;
    
        for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
            local adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), direction);
            if (adjacentPlot ~= nil) then
                terrainType = adjacentPlot:GetTerrainType();
                if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
                    -- Gets the food and production counts
                    food = food + adjacentPlot:GetYield(g_YIELD_FOOD);
                    production = production + adjacentPlot:GetYield(g_YIELD_PRODUCTION);

					-- Horse
					if(adjacentPlot:GetResourceType() == 42) then
						production = production - 1;
						food = food - 1;
					-- Oil
					elseif(adjacentPlot:GetResourceType() == 13) then
						production = production - 3;
					-- Coal
					elseif(adjacentPlot:GetResourceType() == 41) then
						production = production - 2;
					-- Uranium
					elseif(adjacentPlot:GetResourceType() == 14) then
						production = production - 2;
					-- Niter
					elseif(adjacentPlot:GetResourceType() == 12) then
						production = production - 1
					end
                end
            end
        end 

        if(food < minFood and keepTryingF) then
			print("DEBUG: Food Run");
            keepTryingF = self:__AddFood(plot);
		else
			keepTryingF = false;
        end

        if(production < minProd and keepTryingP) then
            print("DEBUG: Production Run"); 
            keepTryingP = self:__AddProduction(plot);
		else
			keepTryingP = false;
        end
    end
	-- add hill to cap if spawned in plains area
	if (plains > 3 and plot:GetTerrainType() == g_TERRAIN_TYPE_PLAINS and plot:GetFeatureType() == -1) then
        TerrainBuilder.SetTerrainType(plot, g_TERRAIN_TYPE_PLAINS_HILLS);
    end
end


------------------------------------------------------------------------------
function AssignStartingPlots:__AddFood(plot)
	local iResourcesInDB = 0;
	eResourceType	= {};
	eResourceClassType = {};
	aBonus = {};

	for row in GameInfo.Resources() do
		eResourceType[iResourcesInDB] = row.Index;
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

	local dir = TerrainBuilder.GetRandomNumber(DirectionTypes.NUM_DIRECTION_TYPES, "Random Direction");
	for i = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
		local adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), dir);
		local canPlace = true;
		
		if (adjacentPlot == nil) then return false; end

		for row = 0, iResourcesInDB do
			if(eResourceType[row] == adjacentPlot:GetResourceType()) then
				canPlace = false;
			end
		end
		
		print("DEBUG: X: " .. tostring(plot:GetX()) .. " Y:" .. tostring(plot:GetY()));
		print("DEBUG: I = " .. tostring(i));
		print("DEBUG: DIR = " .. tostring(dir));
		print("DEBUG: resource = " .. tostring(adjacentPlot:GetResourceType()));
		print("DEBUG: feature = " .. tostring(adjacentPlot:GetFeatureType()));
		
		if (adjacentPlot ~= nil and canPlace and
			adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and
			adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS and
			adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND) then
			if(adjacentPlot:GetFeatureType() == g_FEATURE_JUNGLE) then
				--banana
				print("PLACING BANANA");
				if(ResourceBuilder.CanHaveResource(adjacentPlot, 0)) then
					ResourceBuilder.SetResourceType(adjacentPlot, 0, 1);
				end
				return true;

			elseif(adjacentPlot:GetTerrainType() == g_TERRAIN_TYPE_PLAINS and adjacentPlot:GetFeatureType() == -1) then
				--wheat
				print("PLACING WHEAT");
				if(ResourceBuilder.CanHaveResource(adjacentPlot, 9)) then
					ResourceBuilder.SetResourceType(adjacentPlot, 9, 1);
				end
				return true;
				
			elseif(adjacentPlot:GetTerrainType() == g_TERRAIN_TYPE_PLAINS_HILLS and adjacentPlot:GetFeatureType() == -1) then
				-- sheep
				print("PLACING SHEEP");
				if(ResourceBuilder.CanHaveResource(adjacentPlot, 7)) then
					ResourceBuilder.SetResourceType(adjacentPlot, 7, 1);
				end
				return true;
			end
		end

		if(dir == DirectionTypes.NUM_DIRECTION_TYPES - 1) then
			dir = 0;
		else
			dir = dir + 1;
		end
	end
	print("DEBUG: cannot add food to any tiles");
	return false;
end

------------------------------------------------------------------------------
function AssignStartingPlots:__AddProduction(plot)
	local iResourcesInDB = 0;
	eResourceType	= {};
	eResourceClassType = {};
	aBonus = {};

	for row in GameInfo.Resources() do
		eResourceType[iResourcesInDB] = row.Index;
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

	local dir = TerrainBuilder.GetRandomNumber(DirectionTypes.NUM_DIRECTION_TYPES, "Random Direction");
	for i = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
		local adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), dir);
		local canPlace = true;

		if (adjacentPlot == nil) then return false; end

		for row = 0, iResourcesInDB do
			if(eResourceType[row] == adjacentPlot:GetResourceType()) then
				canPlace = false;
			end
		end

		print("DEBUG: X: " .. tostring(plot:GetX()) .. " Y:" .. tostring(plot:GetY()));
		print("DEBUG: I = " .. tostring(i));
		print("DEBUG: DIR = " .. tostring(dir));
		print("DEBUG: resource = " .. tostring(adjacentPlot:GetResourceType()));
		print("DEBUG: feature = " .. tostring(adjacentPlot:GetFeatureType()));
		
		if (adjacentPlot ~= nil and canPlace and 
			adjacentPlot:GetFeatureType() ~= g_FEATURE_MARSH and
			adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and
			adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS and
			adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND) then					
			if (adjacentPlot:GetTerrainType() == g_TERRAIN_TYPE_PLAINS and adjacentPlot:GetFeatureType() == g_FEATURE_FOREST) then
				--plains forest, add hill
				print("adding hill to plains forest");
				TerrainBuilder.SetTerrainType(adjacentPlot,g_TERRAIN_TYPE_PLAINS_HILLS);
				return true;
			elseif (adjacentPlot:GetTerrainType() == g_TERRAIN_TYPE_PLAINS and adjacentPlot:GetFeatureType() == g_FEATURE_JUNGLE) then
				--plains jungle, add hill
				print("adding hill to plains jungle");
				TerrainBuilder.SetTerrainType(adjacentPlot,g_TERRAIN_TYPE_PLAINS_HILLS);
				return true;
			elseif (adjacentPlot:GetTerrainType() == g_TERRAIN_TYPE_PLAINS) then
				--flat plains w/ no feature, add hill
				print("adding hill to plains");
				TerrainBuilder.SetTerrainType(adjacentPlot,g_TERRAIN_TYPE_PLAINS_HILLS);
				return true;
			elseif (adjacentPlot:GetTerrainType() == g_TERRAIN_TYPE_PLAINS_HILLS and adjacentPlot:GetFeatureType() == -1) then
				--plains hill w/ no feature, add forest
				print("adding forest to plains hill");
				TerrainBuilder.SetFeatureType(adjacentPlot,g_FEATURE_FOREST);
				return true;
			elseif (adjacentPlot:GetTerrainType() == g_TERRAIN_TYPE_PLAINS_HILLS and adjacentPlot:GetFeatureType() == g_FEATURE_FOREST) then
				--plains hill forest, add deer
				print("adding deer to plains hill forest");
				if(ResourceBuilder.CanHaveResource(adjacentPlot, 4)) then
					ResourceBuilder.SetResourceType(adjacentPlot, 4, 1);
				end
				return true;
			elseif (adjacentPlot:GetTerrainType() == g_TERRAIN_TYPE_GRASS and adjacentPlot:GetFeatureType() == g_FEATURE_FOREST) then
				--flat grass with forest, add hill
				print("adding hill to grass forest");
				TerrainBuilder.SetTerrainType(adjacentPlot,g_TERRAIN_TYPE_GRASS_HILLS);
				return true;
			elseif (adjacentPlot:GetTerrainType() == g_TERRAIN_TYPE_GRASS) then
				--flat grass, add hill
				print("adding hill to grass");
				TerrainBuilder.SetTerrainType(adjacentPlot,g_TERRAIN_TYPE_GRASS_HILLS);
				return true;
			elseif(adjacentPlot:GetTerrainType() == g_TERRAIN_TYPE_GRASS_HILLS and adjacentPlot:GetFeatureType() == -1) then
				--grass hill without feature, add forest
				print("adding forest to grass hill");
				TerrainBuilder.SetFeatureType(adjacentPlot,g_FEATURE_FOREST);
				return true;
			end
		end

		if(dir == DirectionTypes.NUM_DIRECTION_TYPES - 1) then
			dir = 0;
		else
			dir = dir + 1;
		end	
	end
	print("DEBUG: cannot add any more production to tiles");
	return false;
end

------------------------------------------------------------------------------
function AssignStartingPlots:__InitStartBias(minor)
	--Create an array of each starting plot for each civ
	self.playerStarts = {};
	if (minor == true) then
		for i = 1, self.iNumMinorCivs do
			local playerStart = {}
			for j, plot in ipairs(self.minorStartPlots) do
				playerStart[j] = plot;
			end
			self.playerStarts[self.iNumMajorCivs + i] = playerStart
		end
	else
		for i = 1, self.iNumMajorCivs do
			local playerStart = {}
			for j, plot in ipairs(self.majorStartPlots) do
				playerStart[j] = plot;
			end
			self.playerStarts[i] = playerStart;
		end
	end

	--Find the Max tier
	local max = 0; 
	for row in GameInfo.StartBiasResources() do
		if( row.Tier > max) then
			max = row.Tier;
		end
	end
	for row in GameInfo.StartBiasFeatures() do
		if( row.Tier > max) then
			max = row.Tier;
		end
	end
	for row in GameInfo.StartBiasTerrains() do
		if( row.Tier > max) then
			max = row.Tier;
		end
	end
	for row in GameInfo.StartBiasRivers() do
		if(row.Tier > max) then
			max = row.Tier;
		end
	end

	
	for i = 1, max do
		players = {};
		
		--Add all the civs that are in this tier to a table
		if(minor == true) then
			for j = 1, self.iNumMinorCivs do
				local playerIndex = self.iNumMajorCivs + j;
				local civilizationType = PlayerConfigurations[self.minorList[j]]:GetCivilizationTypeName();

				for row in GameInfo.StartBiasResources() do
					if(row.CivilizationType == civilizationType) then
						if( row.Tier == i) then
							table.insert(players, playerIndex);
						end
					end
				end

				for row in GameInfo.StartBiasFeatures() do
					if(row.CivilizationType == civilizationType) then
						if( row.Tier == i) then
							table.insert(players, playerIndex);
						end
					end
				end

				for row in GameInfo.StartBiasTerrains() do
					if(row.CivilizationType == civilizationType) then
						if( row.Tier == i) then
							table.insert(players, playerIndex);
						end
					end
				end

				for row in GameInfo.StartBiasRivers() do
					if(row.CivilizationType == civilizationType) then
						if( row.Tier == i) then
							table.insert(players, playerIndex);
						end
					end
				end
			end
		else
			for j = 1, self.iNumMajorCivs do
				local playerIndex = j;
				local civilizationType = PlayerConfigurations[self.majorList[j]]:GetCivilizationTypeName();
				for row in GameInfo.StartBiasResources() do
					if(row.CivilizationType == civilizationType) then
						if( row.Tier == i) then
							table.insert(players, playerIndex);
						end
					end
				end

				for row in GameInfo.StartBiasFeatures() do
					if(row.CivilizationType == civilizationType) then
						if( row.Tier == i) then
							table.insert(players, playerIndex);
						end
					end
				end

				for row in GameInfo.StartBiasTerrains() do
					if(row.CivilizationType == civilizationType) then
						if( row.Tier == i) then
							table.insert(players, playerIndex);
						end
					end
				end

				for row in GameInfo.StartBiasRivers() do
					if(row.CivilizationType == civilizationType) then
						if( row.Tier == i) then
							table.insert(players, playerIndex);
						end
					end
				end
			end
		end


		players =  GetShuffledCopyOfTable(players); -- Shuffle the table
		-- Go through all the players in this tier
		for j, playerIndex in ipairs(players) do
			local playerId = (playerIndex > self.iNumMajorCivs) and self.minorList[playerIndex - self.iNumMajorCivs] or self.majorList[playerIndex];
			local civilizationType = PlayerConfigurations[playerId]:GetCivilizationTypeName()
			
			--Check if this player has a resource bias then it calls that method
			local resource = false;
			for row in GameInfo.StartBiasResources() do
				if(row.CivilizationType == civilizationType) then
					if( row.Tier == i) then
						resource = true;
					end
				end
			end
			if(resource == true) then
				self:__StartBiasResources(playerIndex, i, minor);
			end

			--Check if this player has a feature bias then it calls that method
			local feature = false;
			for row in GameInfo.StartBiasFeatures() do
				if(row.CivilizationType == civilizationType) then
					if( row.Tier == i) then
						feature = true;
					end
				end
			end
			if(feature == true) then
				self:__StartBiasFeatures(playerIndex, i, minor);
			end

			--Check if this player has a terrain bias then it calls that method
			local terrain = false;
			for row in GameInfo.StartBiasTerrains() do
				if(row.CivilizationType == civilizationType) then
					if( row.Tier == i) then
						terrain = true;
					end
				end
			end
			if(terrain == true) then
				self:__StartBiasTerrains(playerIndex, i, minor);
			end

			--Check if this player has a river bias then it calls that method
			local river = false;
			for row in GameInfo.StartBiasRivers() do
				if(row.CivilizationType == civilizationType) then
					if( row.Tier == i) then
						river = true;
					end
				end
			end
			if(river == true) then
				self:__StartBiasRivers(playerIndex, i, minor);
			end
		end

		local minorModifier = 0;
		if(minor == true) then
			minorModifier = self.iNumMajorCivs;
		end

		if(i == max) then
			local loop = self.iNumMajorCivs;

			if(minor == true) then
				loop = self.iNumMinorCivs;
			end

			for j = 1, loop do
				if(self:__ArraySize(self.playerStarts, j + minorModifier) > 1) then
					for k, v in pairs(self.playerStarts[j + minorModifier]) do
						if(v~= nil) then
							--Call Removal
							self:__StartBiasPlotRemoval(v, minor, j + minorModifier);
						end
					end
				end
			end
		else
			for j, playerIndex in ipairs(players) do
				local hasPlot = false;

				if(self:__ArraySize(self.playerStarts, playerIndex) > 1) then
					for k, v in pairs(self.playerStarts[playerIndex]) do
						if(v~= nil and hasPlot == false) then
							hasPlot = true;
							--Call Removal
							self:__StartBiasPlotRemoval(v, minor, playerIndex);
						end
					end
				end
			end
		end
	end
	

	-- Safety net for starting plots
	playerRestarts = {};
	local loop = 0;
	if (minor == true) then
		loop = self.iNumMinorCivs;
		
		for k, plot in ipairs(self.minorCopy) do
			table.insert(playerRestarts, plot);
		end

		for i = 1, self.iNumMinorCivs do
			local removed = false;
			for j, plot in pairs(self.playerStarts[i + self.iNumMajorCivs]) do
				for k, rePlot in ipairs(playerRestarts) do
					if(plot:GetIndex() == rePlot:GetIndex() and removed == false) then
						table.remove(playerRestarts, k);
						removed = true;
					end
				end
			end
		end
	else
		loop = self.iNumMajorCivs;
		
		for k, plot in ipairs(self.majorCopy) do
			table.insert(playerRestarts, plot);
		end

		for i = 1, self.iNumMajorCivs do
			local removed = false;
			for j, plot in pairs(self.playerStarts[i]) do
				for k, rePlot in ipairs(playerRestarts) do
					if(plot:GetIndex() == rePlot:GetIndex() and removed == false) then
						table.remove(playerRestarts, k);
						removed = true;
					end
				end
			end
		end
	end

	
	for i = 1, loop do
		local bHasStart = false;

		local offset = minor and self.iNumMajorCivs or 0;

		for j, plot in pairs(self.playerStarts[i + offset]) do
			if(plot ~= nil) then
				bHasStart = true;
			end
		end

		if(bHasStart == false) then
			local bNeedPlot = true;
			local index = -1;
			for j, plot in ipairs(playerRestarts) do
				if (plot ~= nil and bNeedPlot == true) then
					bNeedPlot = false;
					index = j;
				end
			end
			if(bNeedPlot == true) then
				--print("Start Bias Error");
			else
				table.insert(self.playerStarts[i + offset], playerRestarts[index]);
				table.remove(playerRestarts, index);
			end
		end
	end
end

------------------------------------------------------------------------------
function AssignStartingPlots:__StartBiasResources(playerIndex, tier, minor)
	local numResource = 0;
	resources = {}

	local playerId = minor and self.minorList[playerIndex - self.iNumMajorCivs] or self.majorList[playerIndex];
	local civilizationType = PlayerConfigurations[playerId]:GetCivilizationTypeName()
	local playerStart = self.playerStarts[playerIndex];

	-- Find the resouces in this tier
	for row in GameInfo.StartBiasResources() do
		if(row.CivilizationType == civilizationType) then
			if( row.Tier == tier) then
				table.insert(resources,  row.ResourceType);
			end
		end
	end

	--Change the range if it is a minor civ
	local range = 2;
	if(minor == true) then
		range = 1;
	end

	resourcePlots = {};

	Resources = {};

	for row in GameInfo.Resources() do
		table.insert(Resources, row.ResourceType);
	end

	--Loop through all the starting plots
	for k, v in pairs(playerStart) do
		--Count the starting plots with the given resource(s) in this tier and add them to an array
		if(v ~= nil) then
			local plotX = v:GetX();
			local plotY = v:GetY();

			local hasResource = false;

			for dx = -range, range, 1 do
				for dy = -range,range, 1 do
					local otherPlot = Map.GetPlotXY(plotX, plotY, dx, dy, range);
					if(otherPlot) then
						if(otherPlot:GetResourceCount() > 0) then
							for j, resource in ipairs(resources) do
								if(Resources[otherPlot:GetResourceType()+1] == resource) then
									hasResource = true;
								end
							end
						end
					end
				end
			end

			if (hasResource == true) then
				numResource = numResource + 1;
				table.insert(resourcePlots, v);
			end
		end
	end 

	--If more than 1 has this resource(s) within 3
	if(numResource  > 1) then
		-- Remove all other starting plots from this civ�s list.
		for k, v in pairs(playerStart) do
			playerStart[k] = nil;
		end
		for i, resourcePlot in ipairs(resourcePlots) do
			table.insert(playerStart, resourcePlot);
		end
	elseif (numResource  == 1) then
		local startPlot = resourcePlots[1];
		
		-- Remove all other starting plots from this civ�s list.
		for k, v in pairs(playerStart) do
			if(startPlot:GetIndex() == v:GetIndex()) then
					playerStart[k] = startPlot;
			else
					playerStart[k] = nil;
			end
		end

		-- Remove this starting plot from all other civ's list
		-- Check to to see if they have one starting spot left if so remove it from all other players
		self:__StartBiasPlotRemoval(startPlot, minor, playerIndex);

	end
end

------------------------------------------------------------------------------
function AssignStartingPlots:__StartBiasFeatures(playerIndex, tier, minor)
	local numFeature = 0;
	features = {}

	local playerId = minor and self.minorList[playerIndex - self.iNumMajorCivs] or self.majorList[playerIndex];
	local civilizationType = PlayerConfigurations[playerId]:GetCivilizationTypeName()
	local playerStart = self.playerStarts[playerIndex];

	-- Find the features in this tier
	for row in GameInfo.StartBiasFeatures() do
		if(row.CivilizationType == civilizationType) then
			if( row.Tier == tier) then
				table.insert(features,  row.FeatureType);
			end
		end
	end

	--Change the range if it is a minor civ
	local range = 3;
	if(minor == true) then
		range = 2;
	end

	featurePlots = {};

	Features = {};

	for row in GameInfo.Features() do
		table.insert(Features, row.FeatureType);
	end

	--Loop through all the starting plots
	for k, v in pairs(playerStart) do
		--Count the starting plots with the given feature(s) in this tier and add them to an array
		if(v ~= nil) then
			local plotX = v:GetX();
			local plotY = v:GetY();

			local hasFeature = false;

			for dx = -range, range - 1, 1 do
				for dy = -range,range -1, 1 do
					local otherPlot = Map.GetPlotXY(plotX, plotY, dx, dy, range);
					if(otherPlot) then
						if(otherPlot:GetFeatureType() ~= g_FEATURE_NONE) then
							for j, feature in ipairs(features) do
								if(Features[otherPlot:GetFeatureType()+1] == feature) then
									hasFeature = true;
								end
							end
						end
					end
				end
			end

			if (hasFeature == true) then
				numFeature = numFeature + 1;
				table.insert(featurePlots, v);
			end
		end
	end 

	--If more than 1 has this feature(s) within 3
	if(numFeature  > 1) then
		-- Remove all other starting plots from this civ�s list.
		local featureValue = table.fill(0, #featurePlots);

		for i, featurePlot in ipairs(featurePlots) do
			local plotX = featurePlot:GetX();
			local plotY = featurePlot:GetY();


			for dx = -range, range - 1, 1 do
				for dy = -range,range -1, 1 do
					local otherPlot = Map.GetPlotXY(plotX, plotY, dx, dy, range);
					if(otherPlot) then
						if(featurePlot:GetIndex() ~= otherPlot:GetIndex()) then
							if(otherPlot:GetFeatureType() ~= g_FEATURE_NONE) then
								for j, feature in ipairs(features) do
									if(Features[otherPlot:GetFeatureType()+1] == feature) then
										featureValue[i] = featureValue[i] + 1;
									end
								end
							end
						end
					end
				end
			end
		end

		self.sortedArray = {};
		self:__SortByArray(featurePlots, featureValue);

		for k, v in pairs(playerStart) do
			playerStart[k] = nil;
		end
		for i, featurePlot in ipairs(self.sortedArray) do
			table.insert(playerStart, featurePlot);
		end
	elseif (numFeature  == 1) then
		local startPlot = featurePlots[1];

		-- Remove all other starting plots from this civ�s list.
		for k, v in pairs(playerStart) do
			if(startPlot:GetIndex() == v:GetIndex()) then
					playerStart[k] = startPlot;
			else
					playerStart[k] = nil;
			end
		end

		-- Remove this starting plot from all other civ's list
		-- Check to to see if they have one starting spot left if so remove it from all other players
		self:__StartBiasPlotRemoval(startPlot, minor, playerIndex);

	end
end

------------------------------------------------------------------------------
function AssignStartingPlots:__StartBiasTerrains(playerIndex, tier, minor)
	local numTerrain = 0;
	terrains = {}

	local playerId = minor and self.minorList[playerIndex - self.iNumMajorCivs] or self.majorList[playerIndex];
	local civilizationType = PlayerConfigurations[playerId]:GetCivilizationTypeName()
	local playerStart = self.playerStarts[playerIndex];

	-- Find the terrains in this tier
	for row in GameInfo.StartBiasTerrains() do
		if(row.CivilizationType == civilizationType) then
			if( row.Tier == tier) then
				table.insert(terrains,  row.TerrainType);
			end
		end
	end

	--Change the range if it is a minor civ
	local range = 3;
	if(minor == true) then
		range = 2;
	end

	terrainPlots = {};

	Terrains = {};

	for row in GameInfo.Terrains() do
		table.insert(Terrains, row.TerrainType);
	end

	--Loop through all the starting plots
	for k, v in pairs(playerStart) do
		--Count the starting plots with the given terrain(s) in this tier and add them to an array
		if(v ~= nil) then
			local plotX = v:GetX();
			local plotY = v:GetY();

			local hasTerrain = false;

			for dx = -range, range - 1, 1 do
				for dy = -range,range -1, 1 do
					local otherPlot = Map.GetPlotXY(plotX, plotY, dx, dy, range);
					if(otherPlot) then
						if(v:GetIndex() ~= otherPlot:GetIndex()) then
							if(otherPlot:GetTerrainType() ~= g_TERRAIN_NONE) then
								for j, terrain in ipairs(terrains) do
									if(Terrains[otherPlot:GetTerrainType()+1] == terrain) then
										hasTerrain = true;
									end
								end
							end
						end
					end
				end
			end

			if (hasTerrain == true) then
				numTerrain = numTerrain + 1;
				table.insert(terrainPlots, v);
			end
		end
	end 

	--If more than 1 has this terrain(s) within 3
	if(numTerrain  > 1) then
		-- Remove all other starting plots from this civ�s list.
		local terrainValue = table.fill(0, #terrainPlots);

		for i, terrainPlot in ipairs(terrainPlots) do
			local plotX = terrainPlot:GetX();
			local plotY = terrainPlot:GetY();


			for dx = -range, range - 1, 1 do
				for dy = -range,range -1, 1 do
					local otherPlot = Map.GetPlotXY(plotX, plotY, dx, dy, range);
					if(otherPlot) then
						if(otherPlot:GetTerrainType() ~= g_TERRAIN_NONE) then
							for j, terrain in ipairs(terrains) do
								if(Terrains[otherPlot:GetTerrainType()+1] == terrain) then
									terrainValue[i] = terrainValue[i] + 1;
								end
							end
						end
					end
				end
			end
		end

		self.sortedArray = {};
		self:__SortByArray(terrainPlots, terrainValue);

		for k, v in pairs(playerStart) do
			playerStart[k] = nil;
		end
		for i, terrainPlot in ipairs(self.sortedArray) do
			table.insert(playerStart, terrainPlot);
		end
	elseif (numTerrain  == 1) then
		local startPlot = terrainPlots[1];

		-- Remove all other starting plots from this civ�s list.
		for k, v in pairs(playerStart) do
			if(startPlot:GetIndex() == v:GetIndex()) then
				playerStart[k] = startPlot;
			else
				playerStart[k] = nil;
			end
		end

		-- Remove this starting plot from all other civ's list
		-- Check to to see if they have one starting spot left if so remove it from all other players
		self:__StartBiasPlotRemoval(startPlot, minor, playerIndex);

	end
end

------------------------------------------------------------------------------
function AssignStartingPlots:__StartBiasRivers(playerIndex, tier, minor)
	local numRiver = 0;

	--The range is 1 in the beginning
	local range = 1;

	riverPlots = {};

	local playerId = minor and self.minorList[playerIndex - self.iNumMajorCivs] or self.majorList[playerIndex];
	local civilizationType = PlayerConfigurations[playerId]:GetCivilizationTypeName()
	local playerStart = self.playerStarts[playerIndex];

	--Loop through all the starting plots
	for k, v in pairs(playerStart) do
		--Count the starting plots with the given river(s) in this tier and add them to an array
		if(v ~= nil) then
			local plotX = v:GetX();
			local plotY = v:GetY();

			local hasRiver = false;

			for dx = -range, range - 1, 1 do
				for dy = -range,range -1, 1 do
					local otherPlot = Map.GetPlotXY(plotX, plotY, dx, dy, range);
					if(otherPlot) then
						if(otherPlot:IsRiver()) then
							hasRiver = true;
						end
					end
				end
			end

			if (hasRiver == true) then
				numRiver = numRiver + 1;
				table.insert(riverPlots, v);
			end
		end
	end 

	--If more than 1 has this river(s) within 3
	if(numRiver  > 1) then
		-- Remove all other starting plots from this civ�s list.
		for k, v in pairs(playerStart) do
			playerStart[k] = nil;
		end
		for i, riverPlot in ipairs(riverPlots) do
			table.insert(playerStart, riverPlot);
		end
	elseif (numRiver  == 1) then
		local startPlot = riverPlots[1];
		
		-- Remove all other starting plots from this civ�s list.
		for k, v in pairs(playerStart) do
			if(startPlot:GetIndex() == v:GetIndex()) then
				playerStart[k] = startPlot;
			else
				playerStart[k] = nil;
			end
		end

		-- Remove this starting plot from all other civ's list
		-- Check to to see if they have one starting spot left if so remove it from all other players
		self:__StartBiasPlotRemoval(startPlot, minor, playerIndex);

	elseif(minor == false) then
		--Change the range if no rivers within 3 and major
		local numRiver = 0;
		local range = 3;

		riverPlots = {};

		--Loop through all the starting plots
		for k, v in pairs(playerStart) do
			--Count the starting plots with the given river(s) in this tier and add them to an array
			if(v ~= nil) then
				local plotX = v:GetX();
				local plotY = v:GetY();

				local hasRiver = false;

				for dx = -range, range - 1, 1 do
					for dy = -range,range -1, 1 do
						local otherPlot = Map.GetPlotXY(plotX, plotY, dx, dy, range);
						if(otherPlot) then
							if(otherPlot:IsRiver()) then
								hasRiver = true;
							end
						end
					end
				end

				if (hasRiver == true) then
					numRiver = numRiver + 1;
					table.insert(riverPlots, v);
				end
			end
		end 

		if(numRiver  > 1) then
			-- Remove all other starting plots from this civ�s list.
			for k, v in pairs(playerStart) do
				playerStart[k] = nil;
			end
			for i, riverPlot in ipairs(riverPlots) do
				table.insert(playerStart, riverPlot);
			end
		elseif (numRiver  == 1) then
			local startPlot = riverPlots[1];
		
			-- Remove all other starting plots from this civ�s list.
			for k, v in pairs(playerStart) do
				if(startPlot:GetIndex() == v:GetIndex()) then
					playerStart[k] = startPlot;
				else
					playerStart[k] = nil;
				end
			end

			-- Remove this starting plot from all other civ's list
			-- Check to to see if they have one starting spot left if so remove it from all other players
			self:__StartBiasPlotRemoval(startPlot, minor, playerIndex);
		end
	end
end

------------------------------------------------------------------------------
function AssignStartingPlots:__StartBiasPlotRemoval(startPlot, minor, playerIndex)
	
	if(startPlot == nil) then
		print("Nil1 Starting Plot");
	end
 
	local start = 1;
	local finish = self.iNumMajorCivs; 

	if (minor == true) then
		start = self.iNumMajorCivs + 1;
		finish = self.iNumMajorCivs + self.iNumMinorCivs;
	end

	for i = start, finish do
		if(i ~= playerIndex) then
			local plotID  = -1;

			for k, v in pairs(self.playerStarts[i]) do
				if(v~= nil and v:GetIndex() == startPlot:GetIndex()) then
					plotID = k;
				end
			end

			--If only one left remove it. And remove it from others...
			if(plotID > -1) then
				if(self:__ArraySize(self.playerStarts, i) == 1) then
					--print("Deleting the last entry will have bad results. Minor is ", minor);
				end

				self.playerStarts[i][plotID] = nil;

				if(self:__ArraySize(self.playerStarts, i) == 1) then
					local hasPlot = false;
					for k, v in pairs(self.playerStarts[i]) do
						if(v~= nil and hasPlot == false) then
							hasPlot = true;
							--Call Removal
							self:__StartBiasPlotRemoval(v, minor, i)
						end
					end
				end
			end
		end
	end
end
------------------------------------------------------------------------------
function AssignStartingPlots:__SortByArray(sorted, keyArray)
	local greatestValue = -1;
	local index  = -1;

	for k, key in ipairs(keyArray) do
		if(key ~= nil and key > greatestValue) then
			index = k;
			greatestValue = key;
		end
	end

	if(index > 0 and sorted[index] ~= nil) then
		table.insert(self.sortedArray,sorted[index]);
		table.remove(sorted,index);
		table.remove(keyArray,index);
	else
		print("Nil");
	end 

	if(#keyArray > 0) then
		self:__SortByArray(sorted, keyArray);
	end
end
------------------------------------------------------------------------------
function AssignStartingPlots:__ArraySize(array, index)
	local count = 0;
	
	if( array ~= nil) then
		for v in pairs(array[index]) do 
			if(v~=nil) then
				count = count + 1;
			end
		end
	end

 	return count;
end

------------------------------------------------------------------------------
function AssignStartingPlots:__PreFertilitySort(sortedPlots)
	--Only used for balanced start
	local iFirstFertility = sortedPlots[1].Fertility;
	if(iFirstFertility < 0) then
		iFirstFertility = 0;
	end

	local score = {};

	for i, plot in ipairs(sortedPlots) do
		local value = plot.Fertility;

		if(value < 0) then
			value = 0
		end

		if(iFirstFertility - value < 0) then
			value = iFirstFertility - value;
		end

		table.insert(score, value);
	end

	return score;
end
------------------------------------------------------------------------------
function AssignStartingPlots:__SortByFertilityArray(sorted, keyArray)
	--Only used for balanced start
	local greatestValue = math.huge * -1;
	local index  = -1;

	for k, key in ipairs(keyArray) do
		if(key ~= nil and key > greatestValue) then
			index = k;
			greatestValue = key;
		end
	end

	if(index > 0 and sorted[index] ~= nil) then
		row = {};
		row.Plot = sorted[index].Plot;
		row.Fertility = sorted[index].Fertility;
		table.insert(self.sortedFertilityArray,row);
		table.remove(sorted,index);
		table.remove(keyArray,index);
	else
		--print("Nil");
	end 

	if(#keyArray > 0) then
		self:__SortByFertilityArray(sorted, keyArray);
	end
end

------------------------------------------------------------------------------
function AssignStartingPlots:__AddResourcesBalanced()
	local iStartEra = GameInfo.Eras[ GameConfiguration.GetStartEra() ];
	local iStartIndex = 1;
	if iStartEra ~= nil then
		iStartIndex = iStartEra.ChronologyIndex;
	end

	local iHighestFertility = 0;
	for i, plot in ipairs(self.majorStartPlots) do
		self:__RemoveBonus(plot);
		self:__BalancedStrategic(plot, iStartIndex);
		
		if(self:__BaseFertility(plot:GetIndex()) > iHighestFertility) then
			iHighestFertility = self:__BaseFertility(plot:GetIndex());
		end
	end

	for i, plot in ipairs(self.majorStartPlots) do
		local iFertilityLeft = self:__BaseFertility(plot:GetIndex());

		if(iFertilityLeft > 0) then
			if(self:__IsContinentalDivide(plot) == true) then
				local iContinentalWeight = GlobalParameters.START_FERTILITY_WEIGHT_CONTINENTAL_DIVIDE or 250;
				iFertilityLeft = iFertilityLeft - iContinentalWeight
			else
				local bAddLuxury = true;
				local iLuxWeight = GlobalParameters.START_FERTILITY_WEIGHT_LUXURY or 250;
				while iFertilityLeft >= iLuxWeight and bAddLuxury == true do 
					bAddLuxury = self:__AddLuxury(plot);
					if(bAddLuxury == true) then
						iFertilityLeft = iFertilityLeft - iLuxWeight;
					end
				end
			end
			local bAddBonus = true;
			local iBonusWeight = GlobalParameters.START_FERTILITY_WEIGHT_BONUS or 75;
			while iFertilityLeft >= iBonusWeight and bAddBonus == true do 
				bAddBonus = self:__AddBonus(plot);
				if(bAddBonus == true) then
					iFertilityLeft = iFertilityLeft - iBonusWeight;
				end
			end
		end
	end
end
------------------------------------------------------------------------------
function AssignStartingPlots:__AddResourcesLegendary()
	local iStartEra = GameInfo.Eras[ GameConfiguration.GetStartEra() ];
	local iStartIndex = 1;
	if iStartEra ~= nil then
		iStartIndex = iStartEra.ChronologyIndex;
	end

	local iLegendaryBonusResources = GlobalParameters.START_LEGENDARY_BONUS_QUANTITY or 2;
	local iLegendaryLuxuryResources = GlobalParameters.START_LEGENDARY_LUXURY_QUANTITY or 1;
	for i, plot in ipairs(self.majorStartPlots) do
		self:__BalancedStrategic(plot, iStartIndex);

		if(self:__IsContinentalDivide(plot) == true) then
			iLegendaryLuxuryResources = iLegendaryLuxuryResources - 1;
		else	
			local bAddLuxury = true;
			while iLegendaryLuxuryResources > 0 and bAddLuxury == true do 
				bAddLuxury = self:__AddLuxury(plot);
				if(bAddLuxury == true) then
						iLegendaryLuxuryResources = iLegendaryLuxuryResources - 1;
				end
			end
		end

		local bAddBonus = true;
		iLegendaryBonusResources = iLegendaryBonusResources + 2 * iLegendaryLuxuryResources;
		while iLegendaryBonusResources > 0 and bAddBonus == true do 
			bAddBonus = self:__AddBonus(plot);
			if(bAddBonus == true) then
					iLegendaryBonusResources = iLegendaryBonusResources - 1;
			end
		end
	end
end

------------------------------------------------------------------------------
function AssignStartingPlots:__BalancedStrategic(plot, iStartIndex)
	local iResourcesInDB = 0;
	eResourceType	= {};
	eResourceClassType = {};	
	eRevealedEra = {};	
	local iRange = STRATEGIC_RESOURCE_FERTILITY_STARTING_ERA_RANGE or 1;

	for row in GameInfo.Resources() do
		eResourceType[iResourcesInDB] = row.Hash;
		eResourceClassType[iResourcesInDB] = row.ResourceClassType;
		eRevealedEra[iResourcesInDB] = row.RevealedEra;
	    iResourcesInDB = iResourcesInDB + 1;
	end

	for row = 0, iResourcesInDB do
		if (eResourceClassType[row]== "RESOURCECLASS_STRATEGIC") then
			if(iStartIndex - iRange <= eRevealedEra[row] and iStartIndex + iRange >= eRevealedEra[row]) then
				local bHasResource = false;
				bHasResource = self:__FindSpecificStrategic(eResourceType[row], plot);	
				if(bHasResource == false) then
					self:__AddStrategic(eResourceType[row], plot)
					--print("Placed!");
				end
			end
		end
	end
end

------------------------------------------------------------------------------
function AssignStartingPlots:__FindSpecificStrategic(eResourceType, plot)
	-- Checks to see if there is a specific strategic in a given distance

	local plotX = plot:GetX();
	local plotY = plot:GetY();
	for dx = -3, 3 do
		for dy = -3,3 do
			local otherPlot = Map.GetPlotXY(plotX, plotY, dx, dy, 3);
			if(otherPlot) then
				if(otherPlot:GetResourceCount() > 0) then
					if(eResourceType == otherPlot:GetResourceType() ) then
						return true;
					end
				end
			end
		end
	end 

	return false;
end

------------------------------------------------------------------------------
function AssignStartingPlots:__AddStrategic(eResourceType, plot)
	-- Checks to see if it can place a specific strategic

	local plotX = plot:GetX();
	local plotY = plot:GetY();

	for dx = -2, 2 do
		for dy = -2,2 do
			local otherPlot = Map.GetPlotXY(plotX, plotY, dx, dy, 2);
			if(otherPlot) then
				if(ResourceBuilder.CanHaveResource(otherPlot, eResourceType) and otherPlot:GetIndex() ~= plot:GetIndex()) then
					ResourceBuilder.SetResourceType(otherPlot, eResourceType, 1);
					return;
				end
			end
		end
	end

	for dx = -3, 3 do
		for dy = -3,3 do
			local otherPlot = Map.GetPlotXY(plotX, plotY, dx, dy, 3);
			if(otherPlot) then
				if(ResourceBuilder.CanHaveResource(otherPlot, eResourceType) and otherPlot:GetIndex() ~= plot:GetIndex()) then
					ResourceBuilder.SetResourceType(otherPlot, eResourceType, 1);
					return;
				end
			end
		end
	end 

	--print("Failed");
end

------------------------------------------------------------------------------
function AssignStartingPlots:__AddLuxury(plot)
	-- Checks to see if it can place a nearby luxury

	local iResourcesInDB = 0;
	eResourceType	= {};
	eResourceClassType	= {};
	eAddLux	= {};

	for row in GameInfo.Resources() do
		eResourceType[iResourcesInDB] = row.Hash;
		eResourceClassType[iResourcesInDB] = row.ResourceClassType;
		iResourcesInDB = iResourcesInDB + 1;
	end

	local plotX = plot:GetX();
	local plotY = plot:GetY();
	for dx = -4, 4 do
		for dy = -4, 4 do
			local otherPlot = Map.GetPlotXY(plotX, plotY, dx, dy, 4);
			if(otherPlot) then
				if(otherPlot:GetResourceCount() > 0) then
					for row = 0, iResourcesInDB do
						if (eResourceClassType[row]== "RESOURCECLASS_LUXURY") then
							if(otherPlot:GetResourceType() == eResourceType[row]) then
								table.insert(eAddLux, eResourceType[row]);
							end
						end
					end
				end
			end
		end
	end 

	for dx = -2, 2 do
		for dy = -2, 2 do
			local otherPlot = Map.GetPlotXY(plotX, plotY, dx, dy, 2);
			if(otherPlot) then
				eAddLux =  GetShuffledCopyOfTable(eAddLux);
				for i, resource in ipairs(eAddLux) do
					if(ResourceBuilder.CanHaveResource(otherPlot, resource) and otherPlot:GetIndex() ~= plot:GetIndex()) then
						ResourceBuilder.SetResourceType(otherPlot, resource, 1);
						--print("Yeah Lux");
						return true;
					end
				end
			end
		end
	end 

	--print("Failed Lux");
	return false;
end

------------------------------------------------------------------------------
function AssignStartingPlots:__AddBonus(plot)
	local iResourcesInDB = 0;
	eResourceType	= {};
	eResourceClassType = {};
	aBonus = {};

	for row in GameInfo.Resources() do
		eResourceType[iResourcesInDB] = row.Hash;
		eResourceClassType[iResourcesInDB] = row.ResourceClassType;
	    iResourcesInDB = iResourcesInDB + 1;
	end

	for row = 0, iResourcesInDB do
		if (eResourceClassType[row] == "RESOURCECLASS_BONUS") then
			for row2 in GameInfo.TypeTags() do
				if(GameInfo.Resources[row2.Type] ~= nil) then
					table.insert(aBonus, eResourceType[row]);
				end
			end
		end
	end

	local plotX = plot:GetX();
	local plotY = plot:GetY();
	aBonus =  GetShuffledCopyOfTable(aBonus);
	for i, resource in ipairs(aBonus) do
		for dx = -2, 2 do
			for dy = -2, 2 do
				local otherPlot = Map.GetPlotXY(plotX, plotY, dx, dy, 2);
				if(otherPlot) then
					if(ResourceBuilder.CanHaveResource(otherPlot, resource) and otherPlot:GetIndex() ~= plot:GetIndex()) then
						ResourceBuilder.SetResourceType(otherPlot, resource, 1);
						--print("Yeah Bonus");
						return true;
					end
				end
			end
		end
	end 

	--print("Failed Bonus");
	return false
end


------------------------------------------------------------------------------
function AssignStartingPlots:__IsContinentalDivide(plot)
	local plotX = plot:GetX();
	local plotY = plot:GetY();

	eContinents	= {};

	for dx = -4, 4 do
		for dy = -4, 4 do
			local otherPlot = Map.GetPlotXY(plotX, plotY, dx, dy, 4);
			if(otherPlot) then
				if(otherPlot:GetContinentType() ~= nil) then
					if(#eContinents == 0) then
						table.insert(eContinents, otherPlot:GetContinentType());
					else
						if(eContinents[1] ~= otherPlot:GetContinentType()) then
							return true;
						end
					end
				end
			end
		end
	end 
	
	return false;
end

------------------------------------------------------------------------------
function AssignStartingPlots:__RemoveBonus(plot)
	local plotX = plot:GetX();
	local plotY = plot:GetY();
	local iResourcesInDB = 0;
	eResourceType	= {};
	eResourceClassType = {};
	aBonus = {};
		
	for row in GameInfo.Resources() do
		eResourceType[iResourcesInDB] = row.Hash;
		eResourceClassType[iResourcesInDB] = row.ResourceClassType;
	    iResourcesInDB = iResourcesInDB + 1;
	end

	for row = 0, iResourcesInDB do
		if (eResourceClassType[row] == "RESOURCECLASS_BONUS") then
			for row2 in GameInfo.TypeTags() do
				if(GameInfo.Resources[row2.Type] ~= nil) then
					table.insert(aBonus, eResourceType[row]);
				end
			end
		end
	end

	for i, resource in ipairs(eResourceType) do
		for dx = -3, 3 do
			for dy = -3,3 do
				local otherPlot = Map.GetPlotXY(plotX, plotY, dx, dy, 3);
				if(otherPlot) then
					if(resource  == otherPlot:GetResourceTypeHash()) then
						ResourceBuilder.SetResourceType(otherPlot, resource, -1);
						return;
					end
				end
			end
		end
	end
end