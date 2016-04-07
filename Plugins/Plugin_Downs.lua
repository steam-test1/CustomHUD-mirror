--TODO: Add bots? Add player support for standalone version?

if RequiredScript == "lib/units/beings/player/huskplayermovement" then

	local _start_bleedout_original = HuskPlayerMovement._start_bleedout
	local _start_dead_original = HuskPlayerMovement._start_dead

	function HuskPlayerMovement:_start_bleedout(...)
		local crim_data = managers.criminals:character_data_by_unit(self._unit)
		if crim_data and crim_data.panel_id then
			managers.hud:decrement_teammate_downs(crim_data.panel_id)
		end
	
		return _start_bleedout_original(self, ...)
	end
	
	--[[
	--Apparently does not work
	function HuskPlayerMovement:_start_dead(...)
		local crim_data = managers.criminals:character_data_by_unit(self._unit)
		if crim_data and crim_data.panel_id then
			managers.hud:reset_teammate_downs(crim_data.panel_id)
		end
	
		return _start_dead_original(self, ...)
	end
	]]

end

if RequiredScript == "lib/network/handlers/unitnetworkhandler" then

	local sync_doctor_bag_taken_original = UnitNetworkHandler.sync_doctor_bag_taken

	function UnitNetworkHandler:sync_doctor_bag_taken(unit, amount, sender, ...)
		local peer = self._verify_sender(sender)
		if peer then
			local crim_data = managers.criminals:character_data_by_peer_id(peer:id())
			if crim_data and crim_data.panel_id then
				managers.hud:reset_teammate_downs(crim_data.panel_id)
			end
		end
		
		return sync_doctor_bag_taken_original(self, unit, amount, sender, ...)
	end

end

if RequiredScript == "lib/managers/hudmanagerpd2" then
	
	HUDManager.DOWNS_COUNTER_PLUGIN = true
	
	local set_player_health_original = HUDManager.set_player_health
	local set_mugshot_custody_original = HUDManager.set_mugshot_custody
	
	function HUDManager:set_player_health(data, ...)
		self:set_teammate_downs(HUDManager.PLAYER_PANEL, data.revives)
		return set_player_health_original(self, data, ...)
	end
	
	function HUDManager:set_mugshot_custody(id, ...)
		local data = self:_get_mugshot_data(id)
		if data then
			local i = managers.criminals:character_data_by_name(data.character_name_id).panel_id
			managers.hud:reset_teammate_downs(i)
		end
	
		return set_mugshot_custody_original(self, id, ...)
	end
	
	HUDManager.set_teammate_downs = HUDManager.decrement_teammate_downs or function(self, i, value)
		--TODO
	end
	
	HUDManager.decrement_teammate_downs = HUDManager.decrement_teammate_downs or function(self, i)
		--TODO
	end
	
	HUDManager.reset_teammate_downs = HUDManager.reset_teammate_downs or function(self, i)
		--TODO
	end
	
end