-------------------------------------------------------------------------------
print("-------------- BBS UI v.0.99 o -D- Init --------------")
-------------------------------------------------------------------------------
--include( "CityBannerManager" );
--include( "WorldViewIconsManager" );
--include( "SupportFunctions" );
--include( "Civ6Common" );
--include( "Colors" );
--include( "CitySupport" );
------------------------------------------------------------------


--LuaEvents = ExposedMembers.LuaEvents;

function OnLoadScreenClose()
	if (Game:GetProperty("BBS_INIT_COUNT") ~= nil) then
		print(Game:GetProperty("BBS_INIT_COUNT"))
		if Game:GetProperty("BBS_INIT_COUNT") > 1 then
			StatusMessage( "BBS reloaded succesfully!", 3, ReportingStatusTypes.DEFAULT )
			--NotificationManager.SendNotification(Players[Game.GetLocalPlayer()], NotificationTypes.USER_DEFINED_3, "BBS reloaded succesfully!")
			else
			if (Game:GetProperty("BBS_SAFE_MODE") ~= nil) then
				print(Game:GetProperty("BBS_SAFE_MODE"))
				if (Game:GetProperty("BBS_SAFE_MODE") == true) then
				StatusMessage( "BBS Loaded succesfully! (Firaxis Placement)", 10, ReportingStatusTypes.DEFAULT )
				--NotificationManager.SendNotification(Players[Game.GetLocalPlayer()], NotificationTypes.USER_DEFINED_1, "BBS Loaded succesfully! (Firaxis Placement)")
				else
				StatusMessage( "BBS Loaded succesfully! (BBS Placement)", 10, ReportingStatusTypes.DEFAULT )
				--NotificationManager.SendNotification(Players[Game.GetLocalPlayer()], NotificationTypes.USER_DEFINED_1, "BBS Loaded succesfully! (BBS Placement)")
				end
			end
			if (Game:GetProperty("BBS_DISTANCE_ERROR") ~= nil) then
				StatusMessage( Game:GetProperty("BBS_DISTANCE_ERROR"), 30, ReportingStatusTypes.DEFAULT )
				--NotificationManager.SendNotification(Players[Game.GetLocalPlayer()], NotificationTypes.USER_DEFINED_2, Game:GetProperty("BBS_DISTANCE_ERROR"))
			end
		end
	end
	
	
end


Events.LoadScreenClose.Add( OnLoadScreenClose );

-- =========================================================================== 
--	Send Status message
-- =========================================================================== 
function StatusMessage( str:string, fDisplayTime:number, type:number )
		LuaEvents.StatusMessage(str, fDisplayTime, type)
end
