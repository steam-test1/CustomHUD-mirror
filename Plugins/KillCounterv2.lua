if RequiredScript == "lib/units/enemies/cop/copdamage" then

	local _on_damage_received_original = CopDamage._on_damage_received

	function CopDamage:_process_kill(data)
		local killer
		local weapon_type
		local weapon_slot
		
		if alive(data.attacker_unit) then
			if data.attacker_unit:base().sentry_gun then
				killer = managers.criminals:character_unit_by_peer_id(data.attacker_unit:base()._owner_id)
				weapon_type = "sentry"
			elseif data.attacker_unit:base().thrower_unit then
				killer = data.attacker_unit:base():thrower_unit()
				
				if alive(data.attacker_unit:base():weapon_unit()) then
					weapon_type = "weapon"
					weapon_slot = tweak_data.weapon[data.attacker_unit:base():weapon_unit():base():get_name_id()].use_data.selection_index
				else
					weapon_type = "throwable"
				end
			elseif data.name_id and tweak_data.blackmarket.melee_weapons[data.name_id] then
				killer = data.attacker_unit
				weapon_type = "melee"
			elseif alive(data.weapon_unit) then
				killer = data.attacker_unit
				local name_id = data.weapon_unit:base():get_name_id()
				
				if tweak_data.blackmarket.projectiles[name_id] then
					weapon_type = "throwable"
				elseif tweak_data.weapon[name_id] then
					weapon_type = "weapon"
					weapon_slot = tweak_data.weapon[name_id].use_data.selection_index
				elseif name_id == "trip_mine" then
					weapon_type = "trip_mine"
				end
			end
		end
		
		if killer and weapon_type then
			if killer == managers.player:player_unit() then
				managers.hud:increment_kill_count(HUDManager.PLAYER_PANEL, self._unit, weapon_type, weapon_slot)
			elseif not managers.criminals:character_peer_id_by_unit(killer) then
				--io.write("DEBUG: Kill by bot " .. tostring(managers.criminals:character_name_by_unit(killer)) .. ": " .. tostring(weapon_type) .. " (" .. tostring(weapon_slot) .. ")\n")
			end
		end
	end
	
	function CopDamage:_on_damage_received(data, ...)
		if self._dead then
			self:_process_kill(data)
		end
		
		return _on_damage_received_original(self, data, ...)
	end

	--TODO: Add sync damage checks for non-local bots and players
	
end

if RequiredScript == "lib/managers/hudmanagerpd2" then

	HUDManager.KILL_COUNT_PLUGIN = true

	function HUDManager:increment_kill_count(i, unit, weapon_type, weapon_slot)
		--TODO: Standard panels call
	
		if self._teammate_panels_custom then
			self._teammate_panels_custom[i]:increment_kill_count(unit, weapon_type, weapon_slot)
		end
	end

end

if string.lower(RequiredScript) == "lib/units/equipment/sentry_gun/sentrygunbase" then
	
	local sync_setup_original = SentryGunBase.sync_setup
	
	function SentryGunBase:sync_setup(upgrade_lvl, peer_id, ...)
		sync_setup_original(self, upgrade_lvl, peer_id, ...)
		self._owner_id = self._owner_id or peer_id
	end
	
end