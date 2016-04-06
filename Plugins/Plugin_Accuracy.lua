if RequiredScript == "lib/managers/statisticsmanager" then

	local shot_fired_original = StatisticsManager.shot_fired
	
	function StatisticsManager:shot_fired(data, ...)
		shot_fired_original(self, data, ...)
		
		--[[
			This does not work well for HE rounds. It would be almost correct if you halved number of shots, 
			but would not take into account shots that goes into the void or compensate for direct hits
		]]
		
		local name_id = data.name_id or data.weapon_unit:base():get_name_id()
		local slot = tweak_data.weapon[name_id].use_data.selection_index
		local weapon_data = self._global.session.shots_by_weapon[name_id]
		local weapon_accuracy = 0
		if weapon_data.total > 0 then
			weapon_accuracy = math.floor(100 * weapon_data.hits / weapon_data.total)
		end
		
		managers.hud:set_teammate_accuracy(HUDManager.PLAYER_PANEL, self:session_hit_accuracy())
		managers.hud:set_teammate_weapon_accuracy(HUDManager.PLAYER_PANEL, slot, weapon_accuracy)
	end

end

if RequiredScript == "lib/managers/hudmanagerpd2" then

	HUDManager.ACCURACY_PLUGIN = true

	HUDManager.set_teammate_accuracy = HUDManager.set_teammate_accuracy or function(self, i, value)
		self._teammate_panels[i]:set_accuracy(value)
	end
	
	HUDManager.set_teammate_weapon_accuracy = HUDManager.set_teammate_weapon_accuracy or function(self, i, slot, value)
		--TODO
	end

end