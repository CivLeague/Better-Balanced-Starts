------------------------------------------------------------------------------
--	FILE:	BBS_AssignStartingPlot.lua    -- 1.16
--	AUTHOR:  D. / Jack The Narrator, Kilua
--	PURPOSE: Custom Spawn Placement Script
------------------------------------------------------------------------------
--	Copyright (c) 2014 Firaxis Games, Inc. All rights reserved.
------------------------------------------------------------------------------
include( "MapEnums" );
include( "MapUtilities" );
include( "FeatureGenerator" );
include( "TerrainGenerator" );
include( "NaturalWonderGenerator" );
include( "ResourceGenerator" );
include ( "AssignStartingPlots" );

local bError_major = false;
local bError_minor = false;
local bError_proximity = false;
local b_debug_region = false
local b_north_biased = false
local Teamers_Config = 0
local Teamers_Ref_team = nil

------------------------------------------------------------------------------
BBS_AssignStartingPlots = {};
------------------------------------------------------------------------------
function BBS_AssignStartingPlots.Create(args)
	if (GameConfiguration.GetValue("SpawnRecalculation") == nil) then
		print("BBS_AssignStartingPlots: Map Type Not Supported!")
		Game:SetProperty("BBS_RESPAWN",false)
		return AssignStartingPlots.Create(args)
	end
	print("BBS_AssignStartingPlots: BBS Settings:", GameConfiguration.GetValue("SpawnRecalculation"));
	if (GameConfiguration.GetValue("SpawnRecalculation") == false) then 
		print("BBS_AssignStartingPlots: BBS Spawn Placement has been Desactivated.")
		Game:SetProperty("BBS_RESPAWN",false)
		return AssignStartingPlots.Create(args)
	end
	
	if MapConfiguration.GetValue("BBS_Team_Spawn") ~= nil then
		Teamers_Config = MapConfiguration.GetValue("BBS_Team_Spawn")
	end
	

	local Major_Distance_Target = 19
	local instance = {}
	--if MapConfiguration.GetValue("MAP_SCRIPT") == "Pangaea.lua" then
	--	Major_Distance_Target = 20
	--end	
	if MapConfiguration.GetValue("MAP_SCRIPT") == "Terra.lua" then
		Major_Distance_Target = 16
	end
	if Teamers_Config == 0 then
		Major_Distance_Target = Major_Distance_Target - 3 
	end
	
	if Map.GetMapSize() == 5 and  PlayerManager.GetAliveMajorsCount() > 10 then
		Major_Distance_Target = Major_Distance_Target - 2
	end
	if Map.GetMapSize() == 5 and  PlayerManager.GetAliveMajorsCount() < 8 then
		Major_Distance_Target = Major_Distance_Target + 2
	end	
	
	if Map.GetMapSize() == 4 and  PlayerManager.GetAliveMajorsCount() > 10 then
		Major_Distance_Target = Major_Distance_Target - 2
	end
	if Map.GetMapSize() == 4 and  PlayerManager.GetAliveMajorsCount() < 8 then
		Major_Distance_Target = Major_Distance_Target + 2
	end	
	
	if Map.GetMapSize() == 3 and  PlayerManager.GetAliveMajorsCount() > 7 then
		Major_Distance_Target = Major_Distance_Target - 3
	end
	if Map.GetMapSize() == 3 and  PlayerManager.GetAliveMajorsCount() < 8 then
		Major_Distance_Target = Major_Distance_Target 
	end	
	
	if Map.GetMapSize() == 2 and  PlayerManager.GetAliveMajorsCount() > 5 then
		Major_Distance_Target = Major_Distance_Target - 4
	end
	if Map.GetMapSize() == 2 and  PlayerManager.GetAliveMajorsCount() < 6 then
		Major_Distance_Target = Major_Distance_Target - 2
	end	
	
	if Map.GetMapSize() == 1 and  PlayerManager.GetAliveMajorsCount() > 5 then
		Major_Distance_Target = Major_Distance_Target - 5
	end
	if Map.GetMapSize() == 1 and  PlayerManager.GetAliveMajorsCount() < 6 then
		Major_Distance_Target = Major_Distance_Target - 3
	end	
	
	if Map.GetMapSize() == 0 and  PlayerManager.GetAliveMajorsCount() > 2  then
		Major_Distance_Target = 15
	end	
	
	if Map.GetMapSize() == 0 and  PlayerManager.GetAliveMajorsCount() == 2  then
		Major_Distance_Target = 18
	end	
	
	
	for i = 1,10 do
		instance = {}
		bError_major = false;
		bError_proximity = false;
		bError_minor = false;
		print("Attempt #",i,"Distance",Major_Distance_Target)
	instance  = {
        -- Core Process member methods
        __Debug								= BBS_AssignStartingPlots.__Debug,
        __InitStartingData					= BBS_AssignStartingPlots.__InitStartingData,
        __FilterStart                       = BBS_AssignStartingPlots.__FilterStart,
        __SetStartBias                      = BBS_AssignStartingPlots.__SetStartBias,
        __BiasRoutine                       = BBS_AssignStartingPlots.__BiasRoutine,
        __FindBias                          = BBS_AssignStartingPlots.__FindBias,
        __RateBiasPlots                     = BBS_AssignStartingPlots.__RateBiasPlots,
        __SettlePlot                   = BBS_AssignStartingPlots.__SettlePlot,
        __CountAdjacentTerrainsInRange      = BBS_AssignStartingPlots.__CountAdjacentTerrainsInRange,
        __ScoreAdjacent    = BBS_AssignStartingPlots.__ScoreAdjacent,
        __CountAdjacentFeaturesInRange      = BBS_AssignStartingPlots.__CountAdjacentFeaturesInRange,
        __CountAdjacentResourcesInRange     = BBS_AssignStartingPlots.__CountAdjacentResourcesInRange,
        __CountAdjacentYieldsInRange        = BBS_AssignStartingPlots.__CountAdjacentYieldsInRange,
        __GetTerrainIndex                   = BBS_AssignStartingPlots.__GetTerrainIndex,
        __GetFeatureIndex                   = BBS_AssignStartingPlots.__GetFeatureIndex,
        __GetResourceIndex                  = BBS_AssignStartingPlots.__GetResourceIndex,
        __NaturalWonderBuffer				= BBS_AssignStartingPlots.__NaturalWonderBuffer,
        __LuxuryBuffer				        = BBS_AssignStartingPlots.__LuxuryBuffer,
        __TryToRemoveBonusResource			= BBS_AssignStartingPlots.__TryToRemoveBonusResource,
        __MajorCivBuffer					= BBS_AssignStartingPlots.__MajorCivBuffer,
        __MinorMajorCivBuffer				= BBS_AssignStartingPlots.__MinorMajorCivBuffer,
        __MinorMinorCivBuffer				= BBS_AssignStartingPlots.__MinorMinorCivBuffer,
        __BaseFertility						= BBS_AssignStartingPlots.__BaseFertility,
        __AddBonusFoodProduction			= BBS_AssignStartingPlots.__AddBonusFoodProduction,
        __AddFood							= BBS_AssignStartingPlots.__AddFood,
        __AddProduction						= BBS_AssignStartingPlots.__AddProduction,
        __AddResourcesBalanced				= BBS_AssignStartingPlots.__AddResourcesBalanced,
        __AddResourcesLegendary				= BBS_AssignStartingPlots.__AddResourcesLegendary,
        __BalancedStrategic					= BBS_AssignStartingPlots.__BalancedStrategic,
        __FindSpecificStrategic				= BBS_AssignStartingPlots.__FindSpecificStrategic,
        __AddStrategic						= BBS_AssignStartingPlots.__AddStrategic,
        __AddLuxury							= BBS_AssignStartingPlots.__AddLuxury,
        __AddBonus							= BBS_AssignStartingPlots.__AddBonus,
        __IsContinentalDivide				= BBS_AssignStartingPlots.__IsContinentalDivide,
        __RemoveBonus						= BBS_AssignStartingPlots.__RemoveBonus,
        __TableSize						    = BBS_AssignStartingPlots.__TableSize,
        __GetValidAdjacent					= BBS_AssignStartingPlots.__GetValidAdjacent,
		__CountAdjacentContinentsInRange	= BBS_AssignStartingPlots.__CountAdjacentContinentsInRange,

        iNumMajorCivs = 0,
		iNumSpecMajorCivs = 0,
        iNumWaterMajorCivs = 0,
        iNumMinorCivs = 0,
        iNumRegions		= 0,
        iDefaultNumberMajor = 0,
        iDefaultNumberMinor = 0,
		iTeamPlacement = Teamers_Config,
        uiMinMajorCivFertility = args.MIN_MAJOR_CIV_FERTILITY or 0,
        uiMinMinorCivFertility = args.MIN_MINOR_CIV_FERTILITY or 0,
        uiStartMinY = args.START_MIN_Y or 0,
        uiStartMaxY = args.START_MAX_Y or 0,
        uiStartConfig = args.START_CONFIG or 2,
        waterMap  = args.WATER or false,
        landMap  = args.LAND or false,
        noStartBiases = args.IGNORESTARTBIAS or false,
        startAllOnLand = args.STARTALLONLAND or false,
        startLargestLandmassOnly = args.START_LARGEST_LANDMASS_ONLY or false,
        majorStartPlots = {},
		majorStartPlotsTeam = {},
        minorStartPlots = {},
        majorList = {},
        minorList = {},
        playerStarts = {},
		regionTracker = {},
        aBonusFood = {},
        aBonusProd = {},
        rBonus = {},
        rLuxury = {},
        rStrategic = {},
        aMajorStartPlotIndices = {},
        fallbackPlots = {},
        tierMax = 0,
		iHard_Major = Major_Distance_Target,
		iDistance = 0,
		iDistance_minor = 0,
		iDistance_minor_minor = 5,
        -- Team info variables (not used in the core process, but necessary to many Multiplayer map scripts)
    }

		instance:__InitStartingData()
	
		if bError_major == false and bError_proximity == false then
			print("BBS_AssignStartingPlots: Successfully ran!")
			if  (bError_minor == true) then
				print("BBS_AssignStartingPlots: An error has occured: A city-state is missing.")
			end
			Game:SetProperty("BBS_RESPAWN",true)
			return instance
			else
			Major_Distance_Target = Major_Distance_Target - 1
		end
	end
	
	
	print("BBS_AssignStartingPlots: To Many Attempts Failed - Go to Firaxis Placement")
	Game:SetProperty("BBS_RESPAWN",false)
	return AssignStartingPlots.Create(args)

end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__Debug(...)
    --print (...);
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__InitStartingData()
   	print("BBS_AssignStartingPlots: Start:", os.date("%c"));
    if(self.uiMinMajorCivFertility <= 0) then
        self.uiMinMajorCivFertility = 110;
    end
    if(self.uiMinMinorCivFertility <= 0) then
        self.uiMinMinorCivFertility = 25;
    end
	local rng = 0
	rng = TerrainBuilder.GetRandomNumber(100,"North Test")/100;
	if rng > 0.5 then
		b_north_biased = true
	end
    --Find Default Number
    local MapSizeTypes = {};
    for row in GameInfo.Maps() do
        MapSizeTypes[row.RowId] = row.DefaultPlayers;
    end
    local sizekey = Map.GetMapSize() + 1;
    local iDefaultNumberPlayers = MapSizeTypes[sizekey] or 8;
    self.iDefaultNumberMajor = iDefaultNumberPlayers ;
    self.iDefaultNumberMinor = math.floor(iDefaultNumberPlayers * 1.5);

    --Init Resources List
    for row in GameInfo.Resources() do
        if (row.ResourceClassType  == "RESOURCECLASS_BONUS") then
            table.insert(self.rBonus, row);
            for row2 in GameInfo.TypeTags() do
                if(GameInfo.Resources[row2.Type] ~= nil and GameInfo.Resources[row2.Type].Hash == row.Hash) then
                    if(row2.Tag=="CLASS_FOOD" and row.Name ~= "LOC_RESOURCE_CRABS_NAME") then
                        table.insert(self.aBonusFood, row);
                    elseif(row2.Tag=="CLASS_PRODUCTION" and row.Name ~= "LOC_RESOURCE_COPPER_NAME") then
                        table.insert(self.aBonusProd, row);
                    end
                end
            end
        elseif (row.ResourceClassType == "RESOURCECLASS_LUXURY") then
            table.insert(self.rLuxury, row);
        elseif (row.ResourceClassType  == "RESOURCECLASS_STRATEGIC") then
            table.insert(self.rStrategic, row);
        end
    end

    for row in GameInfo.StartBiasResources() do
        if(row.Tier > self.tierMax) then
            self.tierMax = row.Tier;
        end
    end
    for row in GameInfo.StartBiasFeatures() do
        if(row.Tier > self.tierMax) then
            self.tierMax = row.Tier;
        end
    end
    for row in GameInfo.StartBiasTerrains() do
        if(row.Tier > self.tierMax) then
            self.tierMax = row.Tier;
        end
    end
    for row in GameInfo.StartBiasRivers() do
        if(row.Tier > self.tierMax) then
            self.tierMax = row.Tier;
        end
    end
	
	if b_debug_region == true then
		for iPlotIndex = 0, Map.GetPlotCount()-1, 1 do
			local pPlot = Map.GetPlotByIndex(iPlotIndex)
			if (pPlot ~= nil) then
				TerrainBuilder.SetFeatureType(pPlot,-1);
			end
		end		
	end

    -- See if there are any civs starting out in the water
    local tempMajorList = {};
    self.majorList = {};
    self.waterMajorList = {};
    self.specMajorList = {};
    self.iNumMajorCivs = 0;
    self.iNumSpecMajorCivs = 0;
    self.iNumWaterMajorCivs = 0;

    tempMajorList = PlayerManager.GetAliveMajorIDs();
	
    
    for i = 1, PlayerManager.GetAliveMajorsCount() do
        local leaderType = PlayerConfigurations[tempMajorList[i]]:GetLeaderTypeName();
        if (not self.startAllOnLand and GameInfo.Leaders_XP2[leaderType] ~= nil and GameInfo.Leaders_XP2[leaderType].OceanStart) then
            table.insert(self.waterMajorList, tempMajorList[i]);
            self.iNumWaterMajorCivs = self.iNumWaterMajorCivs + 1;
            self:__Debug ("Found the Maori");
        elseif ( PlayerConfigurations[tempMajorList[i]]:GetLeaderTypeName() == "LEADER_SPECTATOR" or PlayerConfigurations[tempMajorList[i]]:GetHandicapTypeID() == 2021024770) then
		table.insert(self.specMajorList, tempMajorList[i]);
		self.iNumSpecMajorCivs = self.iNumSpecMajorCivs + 1;
		self:__Debug ("Found a Spectator");
	else
            table.insert(self.majorList, tempMajorList[i]);
            self.iNumMajorCivs = self.iNumMajorCivs + 1;
        end
    end

    -- Do we have enough water on this map for the number of water civs specified?
    local TILES_NEEDED_FOR_WATER_START = 8;
    if (self.waterMap) then
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
    self.minorList = PlayerManager.GetAliveMinorIDs();
    self.iNumRegions = self.iNumMajorCivs + self.iNumMinorCivs;

    StartPositioner.DivideMapIntoMajorRegions(self.iNumMajorCivs, self.uiMinMajorCivFertility, self.uiMinMinorCivFertility, self.startLargestLandmassOnly);
    local majorStartPlots = {};
    for i = self.iNumMajorCivs - 1, 0, - 1 do
        local plots = StartPositioner.GetMajorCivStartPlots(i);
		table.insert(majorStartPlots, self:__FilterStart(plots, i, true));
    end

    self.playerStarts = {};
    self.aMajorStartPlotIndices = {};
    self:__SetStartBias(majorStartPlots, self.iNumMajorCivs, self.majorList,true);

    if(self.uiStartConfig == 1 ) then
        self:__AddResourcesBalanced();
    elseif(self.uiStartConfig == 3 ) then
        self:__AddResourcesLegendary();
    end


    StartPositioner.DivideMapIntoMinorRegions(self.iNumMinorCivs);
    local minorStartPlots = {};
    for i = self.iNumMinorCivs - 1, 0, - 1 do
        local plots = StartPositioner.GetMinorCivStartPlots(i);
        table.insert(minorStartPlots, self:__FilterStart(plots, i, false));
    end

    self:__SetStartBias(minorStartPlots, self.iNumMinorCivs, self.minorList,false);

    -- Finally place the ocean civs
    if (self.iNumWaterMajorCivs > 0) then
        local iWaterCivs = StartPositioner.PlaceOceanStartCivs(self.waterMap, self.iNumWaterMajorCivs, self.aMajorStartPlotIndices);
        for i = 1, iWaterCivs do
            local waterPlayer = Players[self.waterMajorList[i]]
            local iStartIndex = StartPositioner.GetOceanStartTile(i - 1);  -- Indices start at 0 here
            local pStartPlot = Map.GetPlotByIndex(iStartIndex);
            waterPlayer:SetStartingPlot(pStartPlot);
            self:__Debug("Water Start X: ", pStartPlot:GetX(), "Water Start Y: ", pStartPlot:GetY());
        end
        if (iWaterCivs < self.iNumWaterMajorCivs) then
            self:__Debug("FAILURE PLACING WATER CIVS - Missing civs: " .. tostring(self.iNumWaterMajorCivs - iWaterCivs));
        end
    end

	-- Place the spectator
    if (self.iNumSpecMajorCivs > 0) then
        for i = 1, self.iNumSpecMajorCivs do
            local specPlayer = Players[self.specMajorList[i]]
            local pStartPlot = Map.GetPlotByIndex(0+self.iNumSpecMajorCivs);
            specPlayer:SetStartingPlot(pStartPlot);
            self:__Debug("Spec Start X: ", pStartPlot:GetX(), "Spec Start Y: ", pStartPlot:GetY());
        end
    end

	-- Sanity check

	for i = 1, PlayerManager.GetAliveMajorsCount() do
		local startPlot = Players[tempMajorList[i]]:GetStartingPlot();
		if (startPlot == nil) then
			bError_major = true
			--self:__Debug("Error Major Player is missing:", tempMajorList[i]);
			print("Error Major Player is missing:", tempMajorList[i]);
			else
			self:__Debug("Major Start X: ", startPlot:GetX(), "Major Start Y: ", startPlot:GetY(), "ID:",tempMajorList[i]);
		end
	end

	if (Game:GetProperty("BBS_MINOR_FAILING_TOTAL") == nil) then
		local count = 0
		for i = 1, PlayerManager.GetAliveMinorsCount() do
		
			local startPlot = Players[self.minorList[i]]:GetStartingPlot();
			print(i, count)
			if (startPlot == nil) then
				self:__Debug("Error Minor Player is missing:", self.minorList[i]);
				count = count + 1
				Game:SetProperty("BBS_MINOR_FAILING_ID_"..count,self.minorList[i])
				startPlot = Map.GetPlotByIndex(PlayerManager.GetAliveMajorsCount()+PlayerManager.GetAliveMinorsCount()+count);
				local minPlayer = Players[self.minorList[i]]
				minPlayer:SetStartingPlot(startPlot);
				self:__Debug("Minor Temp Start X: ", startPlot:GetX(), "Y: ", startPlot:GetY());
				else
				self:__Debug("Minor", PlayerConfigurations[self.minorList[i]]:GetCivilizationTypeName(), "Start X: ", startPlot:GetX(), "Y: ", startPlot:GetY());
			end
		end

		Game:SetProperty("BBS_MINOR_FAILING_TOTAL",count)
	end

	self:__Debug(Game:GetProperty("BBS_MINOR_FAILING_TOTAL"),"Minor Players are missing");

	if (Game:GetProperty("BBS_MINOR_FAILING_TOTAL") > 0) then
		bError_minor = true
		else
		bError_minor = false
	end

	if (bError_major ~= true) then
		for i = 1, PlayerManager.GetAliveMajorsCount() do
			if (PlayerConfigurations[tempMajorList[i]]:GetLeaderTypeName() ~= "LEADER_SPECTATOR" and PlayerConfigurations[tempMajorList[i]]:GetHandicapTypeID() ~= 2021024770 and PlayerConfigurations[tempMajorList[i]]:GetLeaderTypeName() ~= "LEADER_KUPE") then
				local pStartPlot_i = Players[tempMajorList[i]]:GetStartingPlot()
				for j = 1, PlayerManager.GetAliveMajorsCount() do
					if (PlayerConfigurations[tempMajorList[j]]:GetLeaderTypeName() ~= "LEADER_SPECTATOR" and PlayerConfigurations[tempMajorList[j]]:GetHandicapTypeID() ~= 2021024770 and PlayerConfigurations[tempMajorList[j]]:GetLeaderTypeName() ~= "LEADER_KUPE" and tempMajorList[j] ~= tempMajorList[i]) then
						local pStartPlot_j = Players[tempMajorList[j]]:GetStartingPlot()
						if (pStartPlot_j ~= nil) then
							local distance = Map.GetPlotDistance(pStartPlot_i:GetIndex(),pStartPlot_j:GetIndex())
							self:__Debug("I:", tempMajorList[i],"J:", tempMajorList[j],"Distance:",distance)
							print("I:", tempMajorList[i],"J:", tempMajorList[j],"Distance:",distance)
							if (distance < 9 ) then
								bError_proximity = true;
								print("Proximity Error:",distance)
							end
						end
					end
				end
			end
		end
	end


    print("BBS_AssignStartingPlots: Completed", os.date("%c"));
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__FilterStart(plots, index, major)
    local sortedPlots = {};
    local atLeastOneValidPlot = false;
    for i, row in ipairs(plots) do
        local plot = Map.GetPlotByIndex(row);
        if (plot:IsImpassable() == false and plot:IsWater() == false and self:__GetValidAdjacent(plot, major)) or b_debug_region == true then
            atLeastOneValidPlot = true;
            table.insert(sortedPlots, plot);
        end
    end
    if (atLeastOneValidPlot == true) then
        if (major == true) then
            StartPositioner.MarkMajorRegionUsed(index);
        end
    end
    return sortedPlots;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__SetStartBias(startPlots, iNumberCiv, playersList, major)
    local civs = {};
	self.regionTracker = {};
	local count = 0;
	for i, region in ipairs(startPlots) do
		count = count + 1;
		self.regionTracker[i] = i;
	end
	self:__Debug("Set Start Bias: Total Region", count);
    for i = 1, iNumberCiv do
        local civ = {};
        civ.Type = PlayerConfigurations[playersList[i]]:GetCivilizationTypeName();

        civ.Index = i;
        local biases = self:__FindBias(civ.Type);
        if (self:__TableSize(biases) > 0) then
            civ.Tier = biases[1].Tier;
        else
            civ.Tier = self.tierMax + 1;
        end
        table.insert(civs, civ);
    end
    for i = 1, self.tierMax + 1 do
        local tierOrder = {};
        for j, civ in ipairs(civs) do
            if (civ.Tier == i) then
                table.insert(tierOrder, civ);
            end
        end
        local shuffledCiv = GetShuffledCopyOfTable(tierOrder);
        for k, civ in ipairs(shuffledCiv) do
            self:__Debug("SetStartBias for", civ.Type);
            self:__BiasRoutine(civ.Type, startPlots, civ.Index, playersList, major, false);
        end
    end
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__BiasRoutine(civilizationType, startPlots, index, playersList, major)
    	local biases = self:__FindBias(civilizationType);
    	local ratedBiases = nil;
    	local regionIndex = 0;
    	local settled = false;

    	for i, region in ipairs(startPlots) do
			self:__Debug("Bias Routine: Analysing Region index", i, "Tracker",self.regionTracker[i]);
			if (self.regionTracker[i] ~= -1) then
       			if (region ~= nil and self:__TableSize(region) > 0) then
            		local tempBiases = self:__RateBiasPlots(biases, region, major, i,civilizationType,playersList[index]);

            		if ((ratedBiases == nil or ratedBiases[1].Score < tempBiases[1].Score) and (tempBiases[1].Score > 0 or major == false) ) then
                		ratedBiases = tempBiases;
                		regionIndex = i;
            		end
					else
					regionIndex = i;
					self.regionTracker[regionIndex] = -1;
					self:__Debug("Bias Routine: Remove Region index: Empty Region", regionIndex);
        		end

			end

		end

    	if (ratedBiases ~= nil and regionIndex > 0) then
        	settled = self:__SettlePlot(ratedBiases, index, Players[playersList[index]], major, regionIndex, civilizationType);


    		if (settled == false) then

        		self:__Debug("Failed to settled in assigned region, reduce the distance by one and retry.");

			if (major == true) then
				if (self.iDistance == 0) then
					self.iDistance = -1;
					self:__Debug("BBS_AssignStartingPlots: Reducing Major Distance by 1");
				end
				else

				if (self.iDistance_minor == 0) then
					self.iDistance_minor = -1;
					self:__Debug("BBS_AssignStartingPlots: Reducing Minor Distance by 1");
				end
				self:__Debug("BBS_AssignStartingPlots: Minor-Minor Distance Buffer is ",self.iDistance_minor_minor);
				if (self.iDistance_minor_minor > -1) then
					self.iDistance_minor_minor = self.iDistance_minor_minor -1;
					self:__Debug("BBS_AssignStartingPlots: Reducing Minor-Minor Distance Buffer to ", self.iDistance_minor_minor);
				end
			end

			settled = self:__SettlePlot(ratedBiases, index, Players[playersList[index]], major, regionIndex,civilizationType);

    			if (settled == false) then
        			self:__Debug("Failed to settled in assigned region, use fallbacks.");
				if (self:__TableSize(self.fallbackPlots) > 0) then
        				ratedBiases = self:__RateBiasPlots(biases, self.fallbackPlots, major);
        				self:__SettlePlot(ratedBiases, index, Players[playersList[index]], major, -1,civilizationType);
					else
					self:__Debug("We are fucked!");
					return
				end

				else

				self.regionTracker[regionIndex] = -1;
				self:__Debug("Bias Routine: Remove Region index: Successful Placement post distance reduction", regionIndex);
			end

			else

			self.regionTracker[regionIndex] = -1;
			self:__Debug("Bias Routine: Remove Region index: Successful Placement", regionIndex);

    		end

	end
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__FindBias(civilizationType)
    local biases = {};
    for row in GameInfo.StartBiasResources() do
        if(row.CivilizationType == civilizationType) then
            local bias = {};
            bias.Tier = row.Tier;
            bias.Type = "RESOURCES";
            bias.Value = self:__GetResourceIndex(row.ResourceType);
            self:__Debug("BBS_AssignStartingPlots: Add Bias : Civilization",civilizationType,"Bias Type:", bias.Type, "Tier :", bias.Tier, "Type :", bias.Value);
            table.insert(biases, bias);
        end
    end
    for row in GameInfo.StartBiasFeatures() do
        if(row.CivilizationType == civilizationType) then
            local bias = {};
            bias.Tier = row.Tier;
            bias.Type = "FEATURES";
            bias.Value = self:__GetFeatureIndex(row.FeatureType);
            self:__Debug("BBS_AssignStartingPlots: Add Bias : Civilization",civilizationType,"Bias Type:", bias.Type, "Tier :", bias.Tier, "Type :", bias.Value);
            table.insert(biases, bias);
        end
    end
    for row in GameInfo.StartBiasTerrains() do
        if(row.CivilizationType == civilizationType) then
            local bias = {};
            bias.Tier = row.Tier;
            bias.Type = "TERRAINS";
            bias.Value = self:__GetTerrainIndex(row.TerrainType);
            self:__Debug("BBS_AssignStartingPlots: Add Bias : Civilization",civilizationType,"Bias Type:", bias.Type, "Tier :", bias.Tier, "Type :", bias.Value);
            table.insert(biases, bias);
        end
    end
    for row in GameInfo.StartBiasRivers() do
        if(row.CivilizationType == civilizationType) then
            local bias = {};
            bias.Tier = row.Tier;
            bias.Type = "RIVERS";
            bias.Value = nil;
            self:__Debug("BBS_AssignStartingPlots: Add Bias : Civilization",civilizationType,"Bias Type:", bias.Type, "Tier :", bias.Tier, "Type :", bias.Value);
            table.insert(biases, bias);
        end
    end
    table.sort(biases, function(a, b) return a.Tier < b.Tier; end);
    return biases;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__RateBiasPlots(biases, startPlots, major, region_index, civilizationType,iPlayer)
    local ratedPlots = {};
	local region_bonus = 0



	if civilizationType == "CIVILIZATION_SPAIN" or civilizationType == "CIVILIZATION_AUSTRALIA" or civilizationType == "CIVILIZATION_INCA" or civilizationType == "CIVILIZATION_MAPUCHE" or civilizationType == "CIVILIZATION_EGYPT" or civilizationType == "CIVILIZATION_CANADA" or civilizationType == "CIVILIZATION_RUSSIA" then
		local count = 0
		for i, plot in ipairs(startPlots) do
			if civilizationType == "CIVILIZATION_SPAIN" then
				local continent = nil
				local multi_continent = false
				if continent == nil then
					continent = plot:GetContinentType()
					else
					if plot:GetContinentType() ~= continent then
						multi_continent = true
						region_bonus = 50
						break
					end
				end
			end
			if civilizationType == "CIVILIZATION_AUSTRALIA" or civilizationType == "CIVILIZATION_MAPUCHE" then
				if  plot:GetFeatureType() == "FEATURE_JUNGLE" or plot:GetFeatureType() == "FEATURE_FLOODPLAINS" or plot:GetFeatureType() == "FEATURE_FLOODPLAINS_PLAINS" or plot:GetFeatureType() == "FEATURE_FLOODPLAINS_GRASSLAND" then
					count = count + 1
				end
			end
			if civilizationType == "CIVILIZATION_EGYPT" then
				if  plot:GetFeatureType() == "FEATURE_FLOODPLAINS" or plot:GetFeatureType() == "FEATURE_FLOODPLAINS_PLAINS" or plot:GetFeatureType() == "FEATURE_FLOODPLAINS_GRASSLAND" then
					count = count + 1
				end
			end
			if civilizationType == "CIVILIZATION_INCA" then
				if  plot:GetTerrainType() == 2 or plot:GetTerrainType() == 5 then
					count = count + 1
				end
			end
			if civilizationType == "CIVILIZATION_RUSSIA" or civilizationType == "CIVILIZATION_CANADA" then
				if  plot:GetTerrainType() > 8 and plot:GetTerrainType() < 15 then
					count = count + 1
				end
			end
		end
		
		if (civilizationType == "CIVILIZATION_AUSTRALIA" or civilizationType == "CIVILIZATION_MAPUCHE") and count > 20 then 
			region_bonus = -200
		end
		if civilizationType == "CIVILIZATION_EGYPT" and count > 20 then 
			region_bonus = 150
		end
		if civilizationType == "CIVILIZATION_INCA" and count > 15 then 
			if  count > 15 then
				region_bonus = 100
				else
				region_bonus = -300				
			end
		end
		if civilizationType == "CIVILIZATION_RUSSIA" or civilizationType == "CIVILIZATION_CANADA" then
			if  count > 15 then
				region_bonus = 100
				else
				region_bonus = -300				
			end
		end
	end
	
    for i, plot in ipairs(startPlots) do
        local ratedPlot = {};
        local foundBiasDesert = false;
        local foundBiasToundra = false;
		local foundBiasFloodPlains = false;
        ratedPlot.Plot = plot;
		if b_debug_region == true and major == true then
			if region_index == 0  then -- Region 0: Snow
				TerrainBuilder.SetTerrainType(ratedPlot.Plot,12);
			end
			if region_index == 1 then -- Region 1: Grass Jungle
				TerrainBuilder.SetFeatureType(ratedPlot.Plot,2);
				TerrainBuilder.SetTerrainType(ratedPlot.Plot,0);
			end
			if region_index == 2  then -- Region 2: Forest Grass
				TerrainBuilder.SetFeatureType(ratedPlot.Plot,3);
				TerrainBuilder.SetTerrainType(ratedPlot.Plot,0);
			end
			if region_index == 3  then -- Region 3: Oasis
				TerrainBuilder.SetFeatureType(ratedPlot.Plot,4);
				TerrainBuilder.SetTerrainType(ratedPlot.Plot,0);
			end
			if region_index == 4  then -- Region 4: Flat Marsh
				TerrainBuilder.SetFeatureType(ratedPlot.Plot,5);
				TerrainBuilder.SetTerrainType(ratedPlot.Plot,0);
			end
			if  region_index == 5 then -- Region 5: Plains
				TerrainBuilder.SetFeatureType(ratedPlot.Plot,0);
				TerrainBuilder.SetTerrainType(ratedPlot.Plot,3);
			end
			if  region_index == 6 then -- Region 6: Jungle Plains
				TerrainBuilder.SetFeatureType(ratedPlot.Plot,2);
				TerrainBuilder.SetTerrainType(ratedPlot.Plot,3);
			end
			if  region_index == 7 then
				TerrainBuilder.SetFeatureType(ratedPlot.Plot,3);
				TerrainBuilder.SetTerrainType(ratedPlot.Plot,3);
			end
			if  region_index == 8 then
				TerrainBuilder.SetFeatureType(ratedPlot.Plot,4);
				TerrainBuilder.SetTerrainType(ratedPlot.Plot,3);
			end
			if  region_index == 9 then
				TerrainBuilder.SetFeatureType(ratedPlot.Plot,5);
				TerrainBuilder.SetTerrainType(ratedPlot.Plot,3);
			end
			if region_index == 10  then
				TerrainBuilder.SetTerrainType(ratedPlot.Plot,10);
			end
			if region_index == 11 then
				TerrainBuilder.SetFeatureType(ratedPlot.Plot,2);
				TerrainBuilder.SetTerrainType(ratedPlot.Plot,7);
			end
			if region_index == 12  then
				TerrainBuilder.SetFeatureType(ratedPlot.Plot,3);
				TerrainBuilder.SetTerrainType(ratedPlot.Plot,7);
			end
			if region_index == 13  then
				TerrainBuilder.SetFeatureType(ratedPlot.Plot,4);
				TerrainBuilder.SetTerrainType(ratedPlot.Plot,7);
			end
			if region_index == 14  then
				TerrainBuilder.SetFeatureType(ratedPlot.Plot,5);
				TerrainBuilder.SetTerrainType(ratedPlot.Plot,7);
			end
				
		end
        ratedPlot.Score = 0 + region_bonus;
        ratedPlot.Index = i;
        if (biases ~= nil) then
            for j, bias in ipairs(biases) do
                --self:__Debug("Rate Plot:", plot:GetX(), ":", plot:GetY(), "For Bias :", bias.Type, "value :", bias.Value);
                if (bias.Type == "TERRAINS") then
					if bias.Value == g_TERRAIN_TYPE_COAST then
						if self:__CountAdjacentTerrainsInRange(ratedPlot.Plot, bias.Value, major) > 0 then
							ratedPlot.Score = ratedPlot.Score + 150
						end
						else
						ratedPlot.Score = ratedPlot.Score + self:__ScoreAdjacent(self:__CountAdjacentTerrainsInRange(ratedPlot.Plot, bias.Value, major), bias.Tier);
					end
                    if (bias.Value == g_TERRAIN_TYPE_DESERT) then
                        foundBiasDesert = true;
                    end
                    if (bias.Value == g_TERRAIN_TYPE_TUNDRA or bias.Value == g_TERRAIN_TYPE_SNOW) then
                        foundBiasToundra = true;
                    end
                elseif (bias.Type == "FEATURES") then
                    ratedPlot.Score = ratedPlot.Score + 25 + self:__ScoreAdjacent(self:__CountAdjacentFeaturesInRange(ratedPlot.Plot, bias.Value, major), bias.Tier);
					if (bias.Value == g_FEATURE_FLOODPLAINS or bias.Value == g_FEATURE_FLOODPLAINS_PLAINS or bias.Value == g_FEATURE_FLOODPLAINS_GRASSLAND) then
                        foundBiasFloodPlains = true;
                    end
                elseif (bias.Type == "RIVERS" and ratedPlot.Plot:IsRiver()) then
                    ratedPlot.Score = ratedPlot.Score + 25 + self:__ScoreAdjacent(1, bias.Tier);
                elseif (bias.Type == "RESOURCES") then
                    ratedPlot.Score = ratedPlot.Score + 25 + self:__ScoreAdjacent(self:__CountAdjacentResourcesInRange(ratedPlot.Plot, bias.Value, major), bias.Tier);
                end
            end
        end
        if (major) then
            if (not foundBiasDesert) then
                local tempDesert = self:__CountAdjacentTerrainsInRange(ratedPlot.Plot, g_TERRAIN_TYPE_DESERT, false);
                local tempDesertHill = self:__CountAdjacentTerrainsInRange(ratedPlot.Plot, g_TERRAIN_TYPE_DESERT_HILLS, false);
                if (tempDesert > 0 or tempDesertHill > 0) then
                    --self:__Debug("No Desert Bias found, reduce adjacent Desert Terrain for Plot :", ratedPlot.Plot:GetX(), ratedPlot.Plot:GetY());
                    ratedPlot.Score = ratedPlot.Score - (tempDesert + tempDesertHill) * 200;
                end
            end
			if (not foundBiasFloodPlains) then
                local tempFlood = self:__CountAdjacentFeaturesInRange(ratedPlot.Plot, g_FEATURE_FLOODPLAINS, false) 
								+ self:__CountAdjacentFeaturesInRange(ratedPlot.Plot, g_FEATURE_FLOODPLAINS_PLAINS, false)
								+ self:__CountAdjacentFeaturesInRange(ratedPlot.Plot, g_FEATURE_FLOODPLAINS_GRASSLAND, false);
                if (tempFlood > 0 ) then
                    --self:__Debug("No Floodplains Bias found, reduce adjacent floodplains for Plot :", ratedPlot.Plot:GetX(), ratedPlot.Plot:GetY());
                    ratedPlot.Score = ratedPlot.Score - (tempFlood) * 15;
                end
            end
            if (not foundBiasToundra) then
                local tempTundra = self:__CountAdjacentTerrainsInRange(ratedPlot.Plot, g_TERRAIN_TYPE_TUNDRA, false);
                local tempTundraHill = self:__CountAdjacentTerrainsInRange(ratedPlot.Plot, g_TERRAIN_TYPE_TUNDRA_HILLS, false);
                if (tempTundra > 0 or tempTundraHill > 0) then
                    --self:__Debug("No Toundra Bias found, reduce adjacent Toundra and Snow Terrain for Plot :", ratedPlot.Plot:GetX(), ratedPlot.Plot:GetY());
                    ratedPlot.Score = ratedPlot.Score - (tempTundra + tempTundraHill) * 200;
                end
				else
				if ratedPlot.Plot:GetIndex() > Map.GetPlotCount() / 2 then
							--self:__Debug("Rate Plot:", plot:GetX(), ":", plot:GetY(), "Polarity Bias b_north_biased",b_north_biased,"We are North");
					if b_north_biased == true then
						ratedPlot.Score = ratedPlot.Score + 500
						else
						ratedPlot.Score = ratedPlot.Score - 500
					end
					else
							--self:__Debug("Rate Plot:", plot:GetX(), ":", plot:GetY(), "Polarity Bias b_north_biased",b_north_biased,"We are South");
					if b_north_biased == false then
						ratedPlot.Score = ratedPlot.Score + 500
						else
						ratedPlot.Score = ratedPlot.Score - 500
					end
				end
            end
			if civilizationType == "CIVILIZATION_SPAIN" then
				local continent = self:__CountAdjacentContinentsInRange(ratedPlot.Plot, major)
				if continent ~= nil then
					ratedPlot.Score = ratedPlot.Score + continent * 250
				end
			end
			if self.iTeamPlacement == 1 then
				-- East vs. West
				if Players[iPlayer] ~= nil then
					local gridWidth, gridHeight = Map.GetGridSize();
					if Teamers_Ref_team == nil then
						Teamers_Ref_team = Players[iPlayer]:GetTeam()
					end
					if Players[iPlayer]:GetTeam() == Teamers_Ref_team  then
						if plot:GetX() > 2*(gridWidth / 3) then
							ratedPlot.Score = ratedPlot.Score + 500
							elseif plot:GetX() > (gridWidth / 2) then
							ratedPlot.Score = ratedPlot.Score + 250
							elseif plot:GetX() > ((gridWidth / 2) - 3) then
							ratedPlot.Score = ratedPlot.Score + 50
							elseif plot:GetX() > ( (gridWidth / 2) - 5) then
							ratedPlot.Score = ratedPlot.Score + 25
							elseif plot:GetX() > (gridWidth / 3) then
							ratedPlot.Score = ratedPlot.Score
							else
							ratedPlot.Score = ratedPlot.Score - 2000
						end
						else
						if plot:GetX() < gridWidth / 3 then
							ratedPlot.Score = ratedPlot.Score + 500
							elseif plot:GetX() < (gridWidth / 2) then
							ratedPlot.Score = ratedPlot.Score + 250
							elseif plot:GetX() < ((gridWidth / 2) + 3) then
							ratedPlot.Score = ratedPlot.Score + 50
							elseif plot:GetX() < ((gridWidth / 2) + 5) then
							ratedPlot.Score = ratedPlot.Score + 25
							elseif plot:GetX() < (2*(gridWidth / 3) ) then
							ratedPlot.Score = ratedPlot.Score
							else
							ratedPlot.Score = ratedPlot.Score - 2000
						end						
					end
				end	
				
				-- North vs. South
				elseif self.iTeamPlacement == 2 then
				if Players[iPlayer] ~= nil then
					local gridWidth, gridHeight = Map.GetGridSize();
					if Teamers_Ref_team == nil then
						Teamers_Ref_team = Players[iPlayer]:GetTeam()
					end
					if Players[iPlayer]:GetTeam() == Teamers_Ref_team then
						if plot:GetY() > 2*gridHeight / 3 then
							ratedPlot.Score = ratedPlot.Score + 500
							elseif plot:GetY() > (gridHeight / 2) then
							ratedPlot.Score = ratedPlot.Score + 250
							elseif plot:GetY() > ((gridHeight / 2) - 3) then
							ratedPlot.Score = ratedPlot.Score + 50
							elseif plot:GetY() > ((gridHeight / 2) - 5) then
							ratedPlot.Score = ratedPlot.Score + 25
							elseif plot:GetY() > (gridHeight / 3) then
							ratedPlot.Score = ratedPlot.Score
							else
							ratedPlot.Score = ratedPlot.Score - 2000
						end
						else
						if plot:GetY() < gridHeight / 3 then
							ratedPlot.Score = ratedPlot.Score + 500
							elseif plot:GetY() < ((gridHeight / 2)) then
							ratedPlot.Score = ratedPlot.Score + 250
							elseif plot:GetY() < ((gridHeight / 2) + 3) then
							ratedPlot.Score = ratedPlot.Score + 50
							elseif plot:GetY() < ((gridHeight / 2) + 5) then
							ratedPlot.Score = ratedPlot.Score + 25
							elseif plot:GetY() < (2*(gridHeight / 3) ) then
							ratedPlot.Score = ratedPlot.Score
							else
							ratedPlot.Score = ratedPlot.Score - 2000
						end						
					end
				end	
				
			end
		end

		if (plot:GetFeatureType() == g_FEATURE_OASIS) then
			ratedPlot.Score = ratedPlot.Score -100;
		end
        ratedPlot.Score = ratedPlot.Score + self:__CountAdjacentYieldsInRange(plot, major);
		if (plot:IsCoastalLand() == true) then
			ratedPlot.Score = ratedPlot.Score + 25;
		end
		if (plot:IsFreshWater() == true) then
			ratedPlot.Score = ratedPlot.Score + 75;
		end
		if Players[iPlayer] ~= nil then
			if self:__MajorCivBuffer(plot,Players[iPlayer]:GetTeam()) == false then
				ratedPlot.Score = ratedPlot.Score - 2000;
			end
		end
		ratedPlot.Score = math.floor(ratedPlot.Score);
        self:__Debug("Plot :", plot:GetX(), ":", plot:GetY(), "Score :", ratedPlot.Score, "North Biased:",b_north_biased, "Type:",plot:GetTerrainType());
		if Players[iPlayer] ~= nil and major then
			self:__Debug("Plot :", plot:GetX(), ":", plot:GetY(), "Region:",region_index,"Score :", ratedPlot.Score, "Civilization:",civilizationType, "Team",Players[iPlayer]:GetTeam(),"Type:",plot:GetTerrainType());
		end
		table.insert(ratedPlots, ratedPlot);

    end
    table.sort(ratedPlots, function(a, b) return a.Score > b.Score; end);
    return ratedPlots;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__SettlePlot(ratedBiases, index, player, major, regionIndex, civilizationType)
    local settled = false;
	if (regionIndex == -1) then
		self:__Debug("BBS_AssignStartingPlots: Attempt to place a Player using the Fallback plots.");
		else
		self:__Debug("BBS_AssignStartingPlots: Attempt to place a Player using region ", regionIndex)
	end

    for j, ratedBias in ipairs(ratedBiases) do
        if (not settled) then
            --self:__Debug("Rated Bias Plot:", ratedBias.Plot:GetX(), ":", ratedBias.Plot:GetY(), "Score :", ratedBias.Score);
            if (major) then
                self.playerStarts[index] = {};
                if (self:__MajorCivBuffer(ratedBias.Plot,player:GetTeam())) then
                    self:__Debug("Settled plot :", ratedBias.Plot:GetX(), ":", ratedBias.Plot:GetY(), "Score :", ratedBias.Score, "Player:",player:GetID(),"Region:",regionIndex);
                    settled = true;
                    table.insert(self.playerStarts[index], ratedBias.Plot);
                    table.insert(self.majorStartPlots, ratedBias.Plot);
					table.insert(self.majorStartPlotsTeam, player:GetTeam());
                    table.insert(self.aMajorStartPlotIndices, ratedBias.Plot:GetIndex());
                    self:__TryToRemoveBonusResource(ratedBias.Plot);
                    player:SetStartingPlot(ratedBias.Plot);
					-- Tundra Sharing
					if ratedBias.Plot:GetTerrainType() > 8 and major == true then
						self:__Debug("BBS Placement: Flip the North Switch",b_north_biased,"to",not b_north_biased);
						b_north_biased = not b_north_biased
					end
                else
                    self:__Debug("Bias plot :", ratedBias.Plot:GetX(), ":", ratedBias.Plot:GetY(), "score :", ratedBias.Score, "Region :", regionIndex, "too near other Civ");
                end
            else
                self.playerStarts[index + self.iNumMajorCivs] = {};
                if (self:__MinorMajorCivBuffer(ratedBias.Plot) and self:__MinorMinorCivBuffer(ratedBias.Plot)) then
                    self:__Debug("Settled plot :", ratedBias.Plot:GetX(), ":", ratedBias.Plot:GetY(), "Score :", ratedBias.Score, "Player:",player:GetID(),"Region:",regionIndex);
                    settled = true;
                    table.insert(self.playerStarts[index + self.iNumMajorCivs], ratedBias.Plot);
                    table.insert(self.minorStartPlots, ratedBias.Plot)
                    player:SetStartingPlot(ratedBias.Plot);

                else
                    self:__Debug("Bias plot :", ratedBias.Plot:GetX(), ":", ratedBias.Plot:GetY(), "score :", ratedBias.Score, "Region :", regionIndex, "too near other Civ");
                end
            end
            if (regionIndex == -1 and settled) then
                table.remove(self.fallbackPlots, ratedBias.Index)
            end
        elseif (regionIndex ~= -1) then
            table.insert(self.fallbackPlots, ratedBias.Plot);
        end
    end

    return settled;

end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__CountAdjacentTerrainsInRange(plot, terrainType, major)
    local count = 0;
    local plotX = plot:GetX();
    local plotY = plot:GetY();
    if(not major) then
        for dir = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
            local adjacentPlot = Map.GetAdjacentPlot(plotX, plotY, dir);
            if(adjacentPlot ~= nil and adjacentPlot:GetTerrainType() == terrainType) then
                count = count + 1;
            end
        end
    elseif (terrainType == g_TERRAIN_TYPE_COAST) then
        -- At least one adjacent coast but that is not a lake and not more than one
        for dir = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
            local adjacentPlot = Map.GetAdjacentPlot(plotX, plotY, dir);
            if(adjacentPlot ~= nil and adjacentPlot:GetTerrainType() == terrainType) then
                if (not adjacentPlot:IsLake() and count < 1) then
                    count = count + 1;
                end
            end
        end
    else
        for dx = -2, 2, 1 do
            for dy = -2, 2, 1 do
                local adjacentPlot = Map.GetPlotXYWithRangeCheck(plotX, plotY, dx, dy, 2);
                if(adjacentPlot ~= nil and adjacentPlot:GetTerrainType() == terrainType) then
                    count = count + 1;
                end
            end
        end
    end
    return count;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__ScoreAdjacent(count, tier)
    local score = 0;
    local adjust = self.tierMax + 2 - tier;
    score = count * adjust ^ 3;
    return score;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__CountAdjacentFeaturesInRange(plot, featureType, major)
    local count = 0;
    local plotX = plot:GetX();
    local plotY = plot:GetY();
    if(not major) then
        for dir = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
            local adjacentPlot = Map.GetAdjacentPlot(plotX, plotY, dir);
            if(adjacentPlot ~= nil and adjacentPlot:GetFeatureType() == featureType) then
                count = count + 1;
            end
        end
    else
        for dx = -2, 2, 1 do
            for dy = -2, 2, 1 do
                local adjacentPlot = Map.GetPlotXYWithRangeCheck(plotX, plotY, dx, dy, 2);
                if(adjacentPlot ~= nil and adjacentPlot:GetFeatureType() == featureType) then
                    count = count + 1;
                end
            end
        end
    end
    return count;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__CountAdjacentContinentsInRange(plot, major)
    local count = 0;
    local plotX = plot:GetX();
    local plotY = plot:GetY();
	local continent = plot:GetContinentType()
    if(not major) then
        for dir = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
            local adjacentPlot = Map.GetAdjacentPlot(plotX, plotY, dir);
            if(adjacentPlot ~= nil and adjacentPlot:GetContinentType() ~= continent) then
                count = count + 1;
            end
        end
    else
        for dx = -2, 2, 1 do
            for dy = -2, 2, 1 do
                local adjacentPlot = Map.GetPlotXYWithRangeCheck(plotX, plotY, dx, dy, 2);
                if(adjacentPlot ~= nil and adjacentPlot:GetContinentType() ~= continent) then
                    count = count + 1;
                end
            end
        end
    end
    return count;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__CountAdjacentResourcesInRange(plot, resourceType, major)
    local count = 0;
    local plotX = plot:GetX();
    local plotY = plot:GetY();
    if(not major) then
        for dir = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
            local adjacentPlot = Map.GetAdjacentPlot(plotX, plotY, dir);
            if(adjacentPlot ~= nil and adjacentPlot:GetResourceType() == resourceType) then
                count = count + 1;
            end
        end
    else
        for dx = -2, 2, 1 do
            for dy = -2, 2, 1 do
                local adjacentPlot = Map.GetPlotXYWithRangeCheck(plotX, plotY, dx, dy, 2);
                if(adjacentPlot ~= nil and adjacentPlot:GetResourceType() == resourceType) then
                    count = count + 1;
                end
            end
        end
    end
    return count;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__CountAdjacentYieldsInRange(plot)
    local score = 0;
    local food = 0;
    local prod = 0;
    local plotX = plot:GetX();
    local plotY = plot:GetY();
    for dir = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
        local adjacentPlot = Map.GetAdjacentPlot(plotX, plotY, dir);
        if(adjacentPlot ~= nil) then
            local foodTemp = 0;
            local prodTemp = 0;
            if (adjacentPlot:GetResourceType() ~= nil) then
                -- Coal or Uranium
                if (adjacentPlot:GetResourceType() == 41 or adjacentPlot:GetResourceType() == 46) then
                    prod = prod - 2;
                -- Horses or Niter
                elseif (adjacentPlot:GetResourceType() == 42 or adjacentPlot:GetResourceType() == 44) then
                    food = food - 1;
                    prod = prod - 1;
                -- Oil
                elseif (adjacentPlot:GetResourceType() == 45) then
                    prod = prod - 3;
                end
            end
            foodTemp = adjacentPlot:GetYield(g_YIELD_FOOD);
            prodTemp = adjacentPlot:GetYield(g_YIELD_PRODUCTION);
            if (foodTemp >= 2 and prodTemp >= 2) then
                score = score + 5;
            end
            food = food + foodTemp;
            prod = prod + prodTemp;
        end
    end
    score = score + food + prod;
    --if (prod == 0) then
    --    score = score - 5;
    --end
    return score;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__GetTerrainIndex(terrainType)
    if (terrainType == "TERRAIN_COAST") then
        return g_TERRAIN_TYPE_COAST;
    elseif (terrainType == "TERRAIN_DESERT") then
        return g_TERRAIN_TYPE_DESERT;
    elseif (terrainType == "TERRAIN_TUNDRA") then
        return g_TERRAIN_TYPE_TUNDRA;
    elseif (terrainType == "TERRAIN_SNOW") then
        return g_TERRAIN_TYPE_SNOW;
    elseif (terrainType == "TERRAIN_PLAINS") then
        return g_TERRAIN_TYPE_PLAINS;
    elseif (terrainType == "TERRAIN_GRASS") then
        return g_TERRAIN_TYPE_GRASS;
    elseif (terrainType == "TERRAIN_DESERT_HILLS") then
        return g_TERRAIN_TYPE_DESERT_HILLS;
    elseif (terrainType == "TERRAIN_TUNDRA_HILLS") then
        return g_TERRAIN_TYPE_TUNDRA_HILLS;
    elseif (terrainType == "TERRAIN_SNOW_HILLS") then
        return g_TERRAIN_TYPE_SNOW_HILLS;
    elseif (terrainType == "TERRAIN_PLAINS_HILLS") then
        return g_TERRAIN_TYPE_PLAINS_HILLS;
    elseif (terrainType == "TERRAIN_GRASS_HILLS") then
        return g_TERRAIN_TYPE_GRASS_HILLS;
    elseif (terrainType == "TERRAIN_GRASS_MOUNTAIN") then
        return g_TERRAIN_TYPE_GRASS_MOUNTAIN;
    elseif (terrainType == "TERRAIN_PLAINS_MOUNTAIN") then
        return g_TERRAIN_TYPE_PLAINS_MOUNTAIN;
    elseif (terrainType == "TERRAIN_DESERT_MOUNTAIN") then
        return g_TERRAIN_TYPE_DESERT_MOUNTAIN;
    end
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__GetFeatureIndex(featureType)
    if (featureType == "FEATURE_VOLCANO") then
        return g_FEATURE_VOLCANO;
    elseif (featureType == "FEATURE_JUNGLE") then
        return g_FEATURE_JUNGLE;
    elseif (featureType == "FEATURE_FOREST") then
        return g_FEATURE_FOREST;
    elseif (featureType == "FEATURE_FLOODPLAINS") then
        return g_FEATURE_FLOODPLAINS;
    elseif (featureType == "FEATURE_FLOODPLAINS_PLAINS") then
        return g_FEATURE_FLOODPLAINS_PLAINS;
    elseif (featureType == "FEATURE_FLOODPLAINS_GRASSLAND") then
        return g_FEATURE_FLOODPLAINS_GRASSLAND;
    elseif (featureType == "FEATURE_GEOTHERMAL_FISSURE") then
        return g_FEATURE_GEOTHERMAL_FISSURE;
    end
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__GetResourceIndex(resourceType)
    local resourceTypeName = "LOC_" .. resourceType .. "_NAME";
    for row in GameInfo.Resources() do
        if (row.Name == resourceTypeName) then
            return row.Index;
        end
    end
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__BaseFertility(plot)
    -- Calculate the fertility of the starting plot
    local pPlot = Map.GetPlotByIndex(plot);
    local iFertility = StartPositioner.GetPlotFertility(pPlot:GetIndex(), -1);
    return iFertility;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__NaturalWonderBuffer(plot, major)
    -- Returns false if the player can start because there is a natural wonder too close.
    -- If Start position config equals legendary you can start near Natural wonders
    if(self.uiStartConfig == 3) then
        return true;
    end

    local iMaxNW = 4;

    if(major == false) then
        iMaxNW = GlobalParameters.START_DISTANCE_MINOR_NATURAL_WONDER or 3;
    else
        iMaxNW = GlobalParameters.START_DISTANCE_MAJOR_NATURAL_WONDER or 4;
    end

    local plotX = plot:GetX();
    local plotY = plot:GetY();
    for dx = -iMaxNW, iMaxNW do
        for dy = -iMaxNW, iMaxNW do
            local otherPlot = Map.GetPlotXYWithRangeCheck(plotX, plotY, dx, dy, iMaxNW);
            if(otherPlot and otherPlot:IsNaturalWonder()) then
                return false;
            end
        end
    end
    return true;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__LuxuryBuffer(plot, major)
    -- Checks to see if there are luxuries in the given distance
    if (major and math.ceil(self.iDefaultNumberMajor * 1.25) + self.iDefaultNumberMinor > self.iNumMinorCivs + self.iNumMajorCivs) then
        local plotX = plot:GetX();
        local plotY = plot:GetY();
        for dx = -2, 2 do
            for dy = -2, 2 do
                local otherPlot = Map.GetPlotXYWithRangeCheck(plotX, plotY, dx, dy, 2);
                if(otherPlot) then
                    if(otherPlot:GetResourceCount() > 0) then
                        for _, row in ipairs(self.rLuxury) do
                            if(row.Index == otherPlot:GetResourceType()) then
                                return true;
                            end
                        end
                    end
                end
            end
        end
        return false;
    end
    return true;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__TryToRemoveBonusResource(plot)
    --Removes Bonus Resources underneath starting players
    for row in GameInfo.Resources() do
        if (row.ResourceClassType == "RESOURCECLASS_BONUS") then
            if(row.Index == plot:GetResourceType()) then
                ResourceBuilder.SetResourceType(plot, -1);
            end
        end
    end
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__MajorCivBuffer(plot,team)
    -- Checks to see if there are major civs in the given distance for this major civ
    local iMaxStart = GlobalParameters.START_DISTANCE_MAJOR_CIVILIZATION or 12;
    if(self.waterMap) then
        iMaxStart = iMaxStart - 3;
    end
    iMaxStart = iMaxStart - GlobalParameters.START_DISTANCE_RANGE_MAJOR or 2;
    --local iMaxStart = 10;
    local iSourceIndex = plot:GetIndex();
    for i, majorPlot in ipairs(self.majorStartPlots) do
		if majorPlot == plot then
			return false;
		end
		if team ~= nil and self.majorStartPlotsTeam[i] ~= nil then
			if self.majorStartPlotsTeam[i] == team  then

				if ( Map.GetPlotDistance(iSourceIndex, majorPlot:GetIndex()) <= iMaxStart + self.iDistance ) then
					return false;
				end			
				else
				if(Map.GetPlotDistance(iSourceIndex, majorPlot:GetIndex()) <= iMaxStart + self.iDistance or Map.GetPlotDistance(iSourceIndex, majorPlot:GetIndex()) < self.iHard_Major + self.iDistance) then
					return false;
				end	
			end
			
			else
		    if(Map.GetPlotDistance(iSourceIndex, majorPlot:GetIndex()) <= iMaxStart + self.iDistance or Map.GetPlotDistance(iSourceIndex, majorPlot:GetIndex()) < self.iHard_Major + self.iDistance) then
				return false;
			end
		end
    end
    return true;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__MinorMajorCivBuffer(plot)
    -- Checks to see if there are majors in the given distance for this minor civ
    local iMaxStart = GlobalParameters.START_DISTANCE_MINOR_MAJOR_CIVILIZATION or 8;
    --local iMaxStart = 8;
    local iSourceIndex = plot:GetIndex();
    if(self.waterMap) then
        iMaxStart = iMaxStart - 1;
    end
    for i, majorPlot in ipairs(self.majorStartPlots) do
		if majorPlot == plot then
			return false;
		end
        if(Map.GetPlotDistance(iSourceIndex, majorPlot:GetIndex()) <= iMaxStart + self.iDistance_minor or Map.GetPlotDistance(iSourceIndex, majorPlot:GetIndex()) < 11 + self.iDistance_minor or Map.GetPlotDistance(iSourceIndex, majorPlot:GetIndex()) < 5) then
            return false;
        end
    end
    return true;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__MinorMinorCivBuffer(plot)
    -- Checks to see if there are minors in the given distance for this minor civ
    local iMaxStart = GlobalParameters.START_DISTANCE_MINOR_CIVILIZATION_START or 7;
    --iMaxStart = iMaxStart - GlobalParameters.START_DISTANCE_RANGE_MINOR or 2;
	--local iMaxStart = 7;
    local iSourceIndex = plot:GetIndex();
    for i, minorPlot in ipairs(self.minorStartPlots) do
		if minorPlot == plot then
			return false;
		end
        if(Map.GetPlotDistance(iSourceIndex, minorPlot:GetIndex()) <= iMaxStart or Map.GetPlotDistance(iSourceIndex, minorPlot:GetIndex()) < 7) then
            return false;
        end
    end
    return true;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__AddBonusFoodProduction(plot)
    local food = 0;
    local production = 0;
    local maxFood = 0;
    local maxProduction = 0;
    local gridHeight = Map.GetGridSize();
    local terrainType = plot:GetTerrainType();

    for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
        local adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), direction);
        if (adjacentPlot ~= nil) then
            terrainType = adjacentPlot:GetTerrainType();
            if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
                -- Gets the food and productions
                food = food + adjacentPlot:GetYield(g_YIELD_FOOD);
                production = production + adjacentPlot:GetYield(g_YIELD_PRODUCTION);

                --Checks the maxFood
                if(maxFood <=  adjacentPlot:GetYield(g_YIELD_FOOD)) then
                    maxFood = adjacentPlot:GetYield(g_YIELD_FOOD);
                end

                --Checks the maxProduction
                if(maxProduction <=  adjacentPlot:GetYield(g_YIELD_PRODUCTION)) then
                    maxProduction = adjacentPlot:GetYield(g_YIELD_PRODUCTION);
                end
            end
        end
    end

    if(food < 7 or maxFood < 3) then
        local retry = 0;
        while (food < 7 and retry < 2) do
            food = food + self:__AddFood(plot);
            retry = retry + 1;
        end
    end

    if(production < 5 or maxProduction < 2) then
        local retry = 0;
        while (production < 5 and retry < 2) do
            production = production + self:__AddProduction(plot);
            retry = retry + 1;
        end
    end
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__AddFood(plot)
    local foodAdded = 0;
    local dir = TerrainBuilder.GetRandomNumber(DirectionTypes.NUM_DIRECTION_TYPES, "Random Direction");
    for i = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
        local adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), dir);
        if (adjacentPlot ~= nil) then
            local foodBefore = adjacentPlot:GetYield(g_YIELD_FOOD);
            local aShuffledBonus =  GetShuffledCopyOfTable(self.aBonusFood);
            for _, bonus in ipairs(aShuffledBonus) do
                if(ResourceBuilder.CanHaveResource(adjacentPlot, bonus.Index)) then
                    ResourceBuilder.SetResourceType(adjacentPlot, bonus.Index, 1);
                    foodAdded = adjacentPlot:GetYield(g_YIELD_FOOD) - foodBefore;
                    return foodAdded;
                end
            end
        end

        if(dir == DirectionTypes.NUM_DIRECTION_TYPES - 1) then
            dir = 0;
        else
            dir = dir + 1;
        end
    end
    return foodAdded;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__AddProduction(plot)
    local prodAdded = 0;
    local dir = TerrainBuilder.GetRandomNumber(DirectionTypes.NUM_DIRECTION_TYPES, "Random Direction");
    for i = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
        local adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), dir);
        if (adjacentPlot ~= nil) then
            local prodBefore = adjacentPlot:GetYield(g_YIELD_PRODUCTION);
            local aShuffledBonus = GetShuffledCopyOfTable(self.aBonusProd);
            for _, bonus in ipairs(aShuffledBonus) do
                if(ResourceBuilder.CanHaveResource(adjacentPlot, bonus.Index)) then
                    ResourceBuilder.SetResourceType(adjacentPlot, bonus.Index, 1);
                    prodAdded = adjacentPlot:GetYield(g_YIELD_PRODUCTION) - prodBefore;
                    return prodAdded;
                end
            end
        end

        if(dir == DirectionTypes.NUM_DIRECTION_TYPES - 1) then
            dir = 0;
        else
            dir = dir + 1;
        end
    end
    return prodAdded;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__AddResourcesBalanced()
    local iStartEra = GameInfo.Eras[ GameConfiguration.GetStartEra() ];
    local iStartIndex = 1;
    if iStartEra ~= nil then
        iStartIndex = iStartEra.ChronologyIndex;
    end

    local iHighestFertility = 0;
    for _, plot in ipairs(self.majorStartPlots) do
        self:__RemoveBonus(plot);
        self:__BalancedStrategic(plot, iStartIndex);

        if(self:__BaseFertility(plot:GetIndex()) > iHighestFertility) then
            iHighestFertility = self:__BaseFertility(plot:GetIndex());
        end
    end

    for _, plot in ipairs(self.majorStartPlots) do
        local iFertilityLeft = iHighestFertility - self:__BaseFertility(plot:GetIndex());

        if(iFertilityLeft > 0) then
            if(self:__IsContinentalDivide(plot)) then
                --self:__Debug("START_FERTILITY_WEIGHT_CONTINENTAL_DIVIDE", GlobalParameters.START_FERTILITY_WEIGHT_CONTINENTAL_DIVIDE);
                local iContinentalWeight = math.floor((GlobalParameters.START_FERTILITY_WEIGHT_CONTINENTAL_DIVIDE or 250) / 10);
                iFertilityLeft = iFertilityLeft - iContinentalWeight
            else
                local bAddLuxury = true;
                --self:__Debug("START_FERTILITY_WEIGHT_LUXURY", GlobalParameters.START_FERTILITY_WEIGHT_LUXURY);
                local iLuxWeight = math.floor((GlobalParameters.START_FERTILITY_WEIGHT_LUXURY or 250) / 10);
                while iFertilityLeft >= iLuxWeight and bAddLuxury do
                    bAddLuxury = self:__AddLuxury(plot);
                    if(bAddLuxury) then
                        iFertilityLeft = iFertilityLeft - iLuxWeight;
                    end
                end
            end
            local bAddBonus = true;
            --self:__Debug("START_FERTILITY_WEIGHT_BONUS", GlobalParameters.START_FERTILITY_WEIGHT_BONUS);
            local iBonusWeight = math.floor((GlobalParameters.START_FERTILITY_WEIGHT_BONUS or 75) / 10);
            while iFertilityLeft >= iBonusWeight and bAddBonus do
                bAddBonus = self:__AddBonus(plot);
                if(bAddBonus) then
                    iFertilityLeft = iFertilityLeft - iBonusWeight;
                end
            end
        end
    end
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__AddResourcesLegendary()
    local iStartEra = GameInfo.Eras[ GameConfiguration.GetStartEra() ];
    local iStartIndex = 1;
    if iStartEra ~= nil then
        iStartIndex = iStartEra.ChronologyIndex;
    end

    local iLegendaryBonusResources = GlobalParameters.START_LEGENDARY_BONUS_QUANTITY or 2;
    local iLegendaryLuxuryResources = GlobalParameters.START_LEGENDARY_LUXURY_QUANTITY or 1;
    for i, plot in ipairs(self.majorStartPlots) do
        self:__BalancedStrategic(plot, iStartIndex);

        if(self:__IsContinentalDivide(plot)) then
            iLegendaryLuxuryResources = iLegendaryLuxuryResources - 1;
        else
            local bAddLuxury = true;
            while iLegendaryLuxuryResources > 0 and bAddLuxury do
                bAddLuxury = self:__AddLuxury(plot);
                if(bAddLuxury) then
                    iLegendaryLuxuryResources = iLegendaryLuxuryResources - 1;
                end
            end
        end

        local bAddBonus = true;
        iLegendaryBonusResources = iLegendaryBonusResources + 2 * iLegendaryLuxuryResources;
        while iLegendaryBonusResources > 0 and bAddBonus do
            bAddBonus = self:__AddBonus(plot);
            if(bAddBonus) then
                iLegendaryBonusResources = iLegendaryBonusResources - 1;
            end
        end
    end
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__BalancedStrategic(plot, iStartIndex)
    local iRange = STRATEGIC_RESOURCE_FERTILITY_STARTING_ERA_RANGE or 1;
    for _, row in ipairs(self.rStrategic) do
        if(iStartIndex - iRange <= row.RevealedEra and iStartIndex + iRange >= row.RevealedEra) then
            local bHasResource = false;
            bHasResource = self:__FindSpecificStrategic(row.Index, plot);
            if(not bHasResource) then
                self:__AddStrategic(row.Index, plot)
                self:__Debug("Strategic Resource Placed :", row.Name);
            end
        end
    end
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__FindSpecificStrategic(eResourceType, plot)
    -- Checks to see if there is a specific strategic in a given distance
    local plotX = plot:GetX();
    local plotY = plot:GetY();
    for dx = -3, 3 do
        for dy = -3,3 do
            local otherPlot = Map.GetPlotXYWithRangeCheck(plotX, plotY, dx, dy, 3);
            if(otherPlot) then
                if(otherPlot:GetResourceCount() > 0) then
                    if(eResourceType == otherPlot:GetResourceType()) then
                        return true;
                    end
                end
            end
        end
    end
    return false;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__AddStrategic(eResourceType, plot)
    -- Checks to see if it can place a specific strategic
    local plotX = plot:GetX();
    local plotY = plot:GetY();
    for dx = -2, 2 do
        for dy = -2, 2 do
            local otherPlot = Map.GetPlotXYWithRangeCheck(plotX, plotY, dx, dy, 2);
            if(otherPlot) then
                if(ResourceBuilder.CanHaveResource(otherPlot, eResourceType) and otherPlot:GetIndex() ~= plot:GetIndex()) then
                    ResourceBuilder.SetResourceType(otherPlot, eResourceType, 1);
                    return;
                end
            end
        end
    end
    for dx = -3, 3 do
        for dy = -3, 3 do
            local otherPlot = Map.GetPlotXYWithRangeCheck(plotX, plotY, dx, dy, 3);
            if(otherPlot) then
                if(ResourceBuilder.CanHaveResource(otherPlot, eResourceType) and otherPlot:GetIndex() ~= plot:GetIndex()) then
                    ResourceBuilder.SetResourceType(otherPlot, eResourceType, 1);
                    return;
                end
            end
        end
    end
    self:__Debug("Failed to add Strategic.");
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__AddLuxury(plot)
    local plotX = plot:GetX();
    local plotY = plot:GetY();
    local eAddLux = {};
    for dx = -4, 4 do
        for dy = -4, 4 do
            local otherPlot = Map.GetPlotXYWithRangeCheck(plotX, plotY, dx, dy, 4);
            if(otherPlot) then
                if(otherPlot:GetResourceCount() > 0) then
                    for _, row in ipairs(self.rLuxury) do
                        if(otherPlot:GetResourceType() == row.Index) then
                            table.insert(eAddLux, row);
                        end
                    end
                end
            end
        end
    end

    for dx = -2, 2 do
        for dy = -2, 2 do
            local otherPlot = Map.GetPlotXYWithRangeCheck(plotX, plotY, dx, dy, 2);
            if(otherPlot) then
                eAddLux = GetShuffledCopyOfTable(eAddLux);
                for _, resource in ipairs(eAddLux) do
                    if(ResourceBuilder.CanHaveResource(otherPlot, resource.Index) and otherPlot:GetIndex() ~= plot:GetIndex()) then
                        ResourceBuilder.SetResourceType(otherPlot, resource.Index, 1);
                        self:__Debug("Yeah Lux");
                        return true;
                    end
                end
            end
        end
    end

    self:__Debug("Failed Lux");
    return false;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__AddBonus(plot)
    local plotX = plot:GetX();
    local plotY = plot:GetY();
    local aBonus =  GetShuffledCopyOfTable(self.rBonus);
    for _, resource in ipairs(aBonus) do
        for dx = -2, 2 do
            for dy = -2, 2 do
                local otherPlot = Map.GetPlotXYWithRangeCheck(plotX, plotY, dx, dy, 2);
                if(otherPlot) then
                    --self:__Debug(otherPlot:GetX(), otherPlot:GetY(), "Resource Index :", resource.Index);
                    if(ResourceBuilder.CanHaveResource(otherPlot, resource.Index) and otherPlot:GetIndex() ~= plot:GetIndex()) then
                        ResourceBuilder.SetResourceType(otherPlot, resource.Index, 1);
                        self:__Debug("Yeah Bonus");
                        return true;
                    end
                end
            end
        end
    end

    self:__Debug("Failed Bonus");
    return false
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__IsContinentalDivide(plot)
    local plotX = plot:GetX();
    local plotY = plot:GetY();

    local eContinents = {};

    for dx = -4, 4 do
        for dy = -4, 4 do
            local otherPlot = Map.GetPlotXYWithRangeCheck(plotX, plotY, dx, dy, 4);
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
function BBS_AssignStartingPlots:__RemoveBonus(plot)
    local plotX = plot:GetX();
    local plotY = plot:GetY();
    for _, resource in ipairs(self.rBonus) do
        for dx = -3, 3 do
            for dy = -3,3 do
                local otherPlot = Map.GetPlotXYWithRangeCheck(plotX, plotY, dx, dy, 3);
                if(otherPlot) then
                    if(resource.Index == otherPlot:GetResourceType()) then
                        ResourceBuilder.SetResourceType(otherPlot, resource.Index, -1);
                        return;
                    end
                end
            end
        end
    end
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__TableSize(table)
    local count = 0;
    for _ in pairs(table) do
        count = count + 1;
    end
    return count;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__GetValidAdjacent(plot, major)
    local impassable = 0;
    local water = 0;
    local desert = 0;
    local snow = 0;
    local toundra = 0;
    local gridWidth, gridHeight = Map.GetGridSize();
    local terrainType = plot:GetTerrainType();

	if (self:__NaturalWonderBuffer(plot, major) == false) then
		return false;
	end

	if(plot:IsFreshWater() == false and plot:IsCoastalLand() == false and major == true) then
		return false;
	end


    	local max = 0;
    	local min = 0;
    	if(major == true) then
			if Map.GetMapSize() == 4 then
				max = 6 -- math.ceil(0.5*gridHeight * self.uiStartMaxY / 100);
				min = 6 -- math.ceil(0.5*gridHeight * self.uiStartMinY / 100);
				elseif Map.GetMapSize() == 5 then
				max = 7
				min = 7
				elseif Map.GetMapSize() == 3 then
				max = 5
				min = 5	
				else
				max = 4
				min = 4
			end	
    	end

    	if(plot:GetY() <= min or plot:GetY() > gridHeight - max) then
        	return false;
    	end
		
		if(plot:GetX() <= min or plot:GetX() > gridWidth - max) then
        	return false;
    	end

	if (major == true and plot:IsFreshWater() == false and plot:IsCoastalLand() == false) then
		return false;
	end


    for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
        local adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), direction);
        if (adjacentPlot ~= nil) then
            terrainType = adjacentPlot:GetTerrainType();
            if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
                -- Checks to see if the plot is impassable
                if(adjacentPlot:IsImpassable()) then
                    impassable = impassable + 1;
                end
                -- Checks to see if the plot is water
                if(adjacentPlot:IsWater()) then
                    water = water + 1;
                end
		if(adjacentPlot:GetFeatureType() == g_FEATURE_VOLCANO and major == true) then
			return false
		end 


            else
                impassable = impassable + 1;
            end
        end
    end

    if(impassable >= 2 and not self.waterMap and major == true) then
        return false;
    elseif(impassable >= 3 and not self.waterMap) then
        return false;
    elseif(water + impassable  >= 4 and not self.waterMap and major == true) then
        return false;
    elseif(water >= 3 and major == true) then
        return false;
    elseif(water >= 4 and self.waterMap and major == true) then
        return false;
    else
        return true;
    end
end
