if RequiredScript == "lib/units/enemies/cop/copdamage" then

--This needs fixing for DoT kills as client somehow


function CopDamage:chk_killshot(attacker_unit, variant)
	--printf("chk_killshot: %s\n", tostring(attacker_unit and attacker_unit:slot()))
	
	if alive(attacker_unit) then
		local source = "direct/unknown"
		local killer = attacker_unit
		
		if attacker_unit:in_slot(14) then
			if attacker_unit:base().thrower_unit then
				source = "throwable"
				killer = attacker_unit:base():thrower_unit()
			end
		elseif attacker_unit:in_slot(25) then
			if attacker_unit:base().sentry_gun then
				local owner = attacker_unit:base()._owner_id
				if owner then
					source = "sentry"
					killer = managers.criminals:character_unit_by_peer_id(owner)
				end
			end
		end
		
		if killer then
			if killer:in_slot(3) then
				--printf("Teammate kill (%s)\n", source)
				local crim_data = managers.criminals:character_data_by_unit(killer)
				if crim_data and crim_data.panel_id then
					managers.hud:increment_teammate_kill_count(crim_data.panel_id, managers.groupai:state():is_enemy_special(self._unit))
				end
			elseif killer:in_slot(2) then
				--printf("Player kill (%s)\n", source)
				managers.hud:increment_teammate_kill_count(HUDManager.PLAYER_PANEL, managers.groupai:state():is_enemy_special(self._unit))
			elseif killer:in_slot(16) then
				printf("Bot/joker kill (%s)\n", source)
				local crim_data = managers.criminals:character_data_by_unit(killer)
				if crim_data and crim_data.panel_id then
					managers.hud:increment_teammate_kill_count(crim_data.panel_id, managers.groupai:state():is_enemy_special(self._unit))
				end
			elseif killer:in_slot(12) then
				--printf("Enemy kill (%s)\n", source)
			else
				printf("UNKNOWN KILL (%d / %s)\n", killer:slot(), source)
			end
		else
			printf("UNKNOWN KILL (no killer, attacker unit: %d)\n", attacker_unit:slot())
		end
	end
	

	
	
	
	if attacker_unit and attacker_unit == managers.player:player_unit() then
		managers.player:on_killshot(self._unit, variant)
	end
end


--[[

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
				managers.hud:increment_teammate_kill_count(HUDManager.PLAYER_PANEL, managers.groupai:state():is_enemy_special(self._unit))
				managers.hud:increment_teammate_kill_count_detailed(HUDManager.PLAYER_PANEL, self._unit, weapon_type, weapon_slot)
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
]]
	
end

if RequiredScript == "lib/managers/hudmanagerpd2" then

	HUDManager.KILL_COUNTER_PLUGIN = true
	HUDManager.SHOW_BOT_KILLS = true

	HUDManager.increment_teammate_kill_count = HUDManager.increment_teammate_kill_count or function (self, i, is_special)
		--TODO: Add call for default HUD
	end
	
	HUDManager.reset_teammate_kill_count = HUDManager.reset_teammate_kill_count or function(self, i)
		--TODO: Add call for default HUD
	end
	
	HUDManager.increment_teammate_kill_count_detailed = HUDManager.increment_teammate_kill_count_detailed or function(self, i, unit, weapon_type, weapon_slot)
		--TODO: Add call for default HUD
	end

end

if string.lower(RequiredScript) == "lib/units/equipment/sentry_gun/sentrygunbase" then
	
	local sync_setup_original = SentryGunBase.sync_setup
	
	function SentryGunBase:sync_setup(upgrade_lvl, peer_id, ...)
		sync_setup_original(self, upgrade_lvl, peer_id, ...)
		self._owner_id = self._owner_id or peer_id
	end
	
end