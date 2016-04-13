printf = printf or function(...) end

if RequiredScript == "lib/managers/hud/hudteammate" then

	HUDTeammateCustom = HUDTeammateCustom or class()

	--TODO: Switch to setting hierarchy with overloading for player/team instead of separate table?
	HUDTeammateCustom.SETTINGS = {
		--SHOW_DEBUG_BACKGROUND = true,	--Show the extent of each panel as a colored background
		MAX_WEAPONS = 2,	--Number of carried guns (...just don't...)
		
		PLAYER = {
			SCALE = 1,			--Scale of all elements of the panel
			OPACITY = 0.75,	--Transparency/alpha of panel (1 is solid, 0 is invisible)
			
			--NAME = true,	--Show name
			--RANK = true,	--Show infamy/level
			--CHARACTER = true,	--Show character name
			--LATENCY = true,	--Show latency (not used by player panel)
			STATUS = true,	--Show health/armor/condition etc.
			EQUIPMENT = true,	--Show throwables, cable ties and deployables
			SPECIAL_EQUIPMENT = true,	--Show special equipment/tools (keycards etc.)
			CALLSIGN = true,	--Show the callsign and voice chat icon
			CARRY = true,	--Show currently carried bag
			BUILD = {	--Show perk deck and number of skills acquired in each tree (not used by player)
				--Pick max one
				--HIDE = true,	--Don't show build at all
				DURATION = 30,	--Time in seconds to show the build from when player joins. Information is hidden when duration has expired, or never removed if value is nil/undefined
			},
			WEAPON = {
				--Show/hide various elements of the weapons panels.
				--HIDE option hides the element. SELECTED_ONLY shows only if the weapon is currently selected, UNSELECTED_ONLY the reverse
				--Pick max *one* setting for each element or results are undefined
				ICON = {
					HIDE = true,
					--SELECTED_ONLY = true,
					--UNSELECTED_ONLY = true,
				},
				AMMO = {
					--HIDE = true,
					--SELECTED_ONLY = true,
					--UNSELECTED_ONLY = true,
					--TOTAL_AMMO_ONLY = true,	--Shows only total ammo for all weapons
				},
				FIRE_MODE = {
					--HIDE = true,
					--SELECTED_ONLY = true,
					--UNSELECTED_ONLY = true,
				},
			},
			INTERACTION = {	--(Interaction display only used by teammates, included for reference)
				--HIDE = true,	--Hides the interaction activity/time/progress
				MIN_DURATION = 1,	--Shows the interaction display only if interaction duration in seconds exceeds this threshold
			},
			KILL_COUNTER = {
				--Requires external plugin to be loaded, else will be disabled no matter what
				--HIDE = true,	--Hides the kill counter
				SHOW_BOT_KILLS = true,	--Show the kill counter for criminal bots
				SHOW_SPECIAL_KILLS = true,	--Separate counter for specials
			},
			ACCURACY = true,	--Show accuracy information
		},
		
		TEAMMATE = {
			--For descriptions, see player panel settings
			SCALE = 0.8,
			OPACITY = 0.75,
			
			NAME = true,
			RANK = true,
			--CHARACTER = true,
			LATENCY = true,
			STATUS = true,
			EQUIPMENT = true,
			SPECIAL_EQUIPMENT = true,
			CALLSIGN = true,
			CARRY = true,
			BUILD = {
				--HIDE = true,
				DURATION = 30,
			},
			WEAPON = {
				ICON = {
					--HIDE = true,
					SELECTED_ONLY = true,
					--UNSELECTED_ONLY = true,
				},
				AMMO = {
					--HIDE = true,
					--SELECTED_ONLY = true,
					--UNSELECTED_ONLY = true,
					TOTAL_AMMO_ONLY = true,
				},
			},
			INTERACTION = {
				--HIDE = true,
				MIN_DURATION = 1
			},
			KILL_COUNTER = {
				--HIDE = true,
				SHOW_BOT_KILLS = true,
				SHOW_SPECIAL_KILLS = true,
			},
			--ACCURACY = true,	--Unused by non-players for now
		},
	}
	function HUDTeammateCustom:init(id, panel, is_player, alignment)
		self._panel = panel:panel({
			name = "teammate_panel_" .. tostring(id),
		})

		self._debug_bg = self._panel:rect({
			name = "debug_bg",
			halign = "grow",
			valign = "grow",
			alpha = 0.2,
			visible = HUDTeammateCustom.SETTINGS.SHOW_DEBUG_BACKGROUND and true or false,
		})
		
		self._left_align = alignment == "left"
		self._listeners = {}
		self._settings = HUDTeammateCustom.SETTINGS[is_player and "PLAYER" or "TEAMMATE"]
		self._id = id
		self._is_player = is_player
		self._next_latency_update_t = 0
		
		local size = 50 * self._settings.SCALE
		local name_size = 20 * self._settings.SCALE
		
		self._name = PlayerInfoComponent.Name:new(self._panel, self, name_size)
		self._rank = PlayerInfoComponent.Rank:new(self._panel, self, name_size)
		self._character = PlayerInfoComponent.Character:new(self._panel, self, name_size)
		self._latency = PlayerInfoComponent.Latency:new(self._panel, self, name_size)
		self._callsign = PlayerInfoComponent.Callsign:new(self._panel, self, name_size)
		self._build = PlayerInfoComponent.Build:new(self._panel, self, name_size, self._settings.BUILD and self._settings.BUILD.DURATION)	--TODO: setting
		self._player_status = PlayerInfoComponent.PlayerStatusRadial:new(self._panel, self, size, is_player)
		self._weapons = PlayerInfoComponent.AllWeapons:new(self._panel, self, size, HUDTeammateCustom.SETTINGS.MAX_WEAPONS, self._settings.WEAPON)
		self._equipment = PlayerInfoComponent.Equipment:new(self._panel, self, size * 0.6, size, false)
		self._special_equipment = PlayerInfoComponent.SpecialEquipment:new(self._panel, self, size)
		self._carry = PlayerInfoComponent.Carry:new(self._panel, self, is_player and (20 * self._settings.SCALE) or size, is_player)
		self._interaction = PlayerInfoComponent.Interaction:new(self._panel, self, size, self._settings.INTERACTION and self._settings.INTERACTION.MIN_DURATION or 0)
		self._interaction:set_layer(10)
		self._accuracy = PlayerInfoComponent.AccuracyCounter:new(self._panel, self, name_size * 0.8)
		self._kills = PlayerInfoComponent.KillCounter:new(self._panel, self, name_size * 0.8, self._settings.KILL_COUNTER.SHOW_SPECIAL_KILLS)
		
		self._all_components = {
			self._accuracy,
			self._build,
			self._callsign,
			self._carry,
			self._character,
			self._equipment,
			self._interaction,
			self._kills,
			self._latency,
			self._name,
			self._player_status,
			self._rank,
			self._special_equipment,
			self._weapons,
		}
		
		self._name:set_enabled("setting", self._settings.NAME)
		self._rank:set_enabled("setting", self._settings.RANK)
		self._character:set_enabled("setting", self._settings.CHARACTER)
		self._latency:set_enabled("setting", self._settings.LATENCY)
		self._latency:set_enabled("player", not self._is_player)
		self._callsign:set_enabled("setting", self._settings.CALLSIGN)
		self._build:set_enabled("setting", not (self._settings.BUILD and self._settings.BUILD.HIDE))
		self._build:set_enabled("player", not self._is_player)
		self._player_status:set_enabled("setting", self._settings.STATUS)
		self._equipment:set_enabled("setting", self._settings.EQUIPMENT)
		self._special_equipment:set_enabled("setting", self._settings.SPECIAL_EQUIPMENT)
		self._carry:set_enabled("setting", self._settings.CARRY)
		self._interaction:set_enabled("setting", not (self._settings.INTERACTION and self._settings.INTERACTION.HIDE))
		self._accuracy:set_enabled("setting", HUDManager.ACCURACY_PLUGIN and self._settings.ACCURACY)
		self._accuracy:set_enabled("player", self._is_player)
		self._kills:set_enabled("setting", HUDManager.KILL_COUNTER_PLUGIN and not self._settings.KILL_COUNTER.HIDE)
		
		local interaction_panel_overlap = { self._weapons, self._equipment, self._special_equipment }
		if not self._is_player then
			table.insert(interaction_panel_overlap, self._carry)
		end
		self._interaction:set_overlapping_panels(interaction_panel_overlap)
		
		self._panel:set_alpha(self._settings.OPACITY)
		self._panel:hide()
		self:_update_layout(true)
	end

	function HUDTeammateCustom:update(t, dt)
		if not self._is_player and self._peer_id and t > self._next_latency_update_t then
			local peer = managers.network:session():peer(self._peer_id)
			local latency = Network:qos(peer:rpc()).ping
			
			self:set_latency(latency)
			self._next_latency_update_t = t + 1
		end
	end

	function HUDTeammateCustom:arrange()
		if not self._component_layout then return end
	
		local MARGIN = 3
		local w = 0
		local h = 0
		
		for i, vertical_order in ipairs(self._component_layout) do
			local start = 1
			local stop = #vertical_order
			local step = 1
			
			local w_row = 0
			local h_row = 0
			
			for j = start, stop, step do
				local component = vertical_order[j]
				
				if component:visible() then
					component:set_y(h)
					component:set_x(w_row)
					w_row = w_row + MARGIN + component:w()
					h_row = math.max(h_row, component:h())
				end
			end
			
			
			h = h + h_row
			w = math.max(w, w_row)
		end
		
		if self._interaction:visible() then
			self._interaction:set_y(self._player_status:y())
			
			if h < self._player_status:bottom() then
				h = h + self._interaction:h()
			end
			w = math.max(w, self._interaction:w())
			
			local offset = self._player_status:visible() and (self._player_status:w() + MARGIN) or 0 
			if self._left_align then
				self._interaction:set_x(offset)
			else
				self._interaction:set_right(w - offset)
			end
		end
		
		if self._is_player then
			self._carry:set_center_x(w / 2)
		end
		
		self._latency:set_right(w)
		
		if not (self._latency:visible() or self._name:visible() or self._rank:visible() or self._character:visible()) and self._player_status:visible() then
			self._callsign:set_center(self._player_status:center())
		end
				
		if self._panel:w() ~= w or self._panel:h() ~= h then
			self._panel:set_size(w, h)
			managers.hud:arrange_teammate_panels()
		end
		
		if not self._left_align then
			for _, component in ipairs(self._all_components) do
				component:set_right(self._panel:w() - component:left())
			end
		end
	end

	function HUDTeammateCustom:_update_layout(human_layout)
		if self._human_layout ~= human_layout then
			
			self._human_layout = human_layout
			
			self._weapons:set_enabled("ai", self._human_layout)
			self._player_status:set_enabled("ai", self._human_layout)
			self._equipment:set_enabled("ai", self._human_layout)
			self._special_equipment:set_enabled("ai", self._human_layout)
			self._carry:set_enabled("ai", self._human_layout)
			self._character:set_enabled("ai", self._human_layout)
			self._latency:set_enabled("ai", self._human_layout)
			self._rank:set_enabled("ai", self._human_layout)
			self._build:set_enabled("ai", self._human_layout)
			self._kills:set_enabled("ai", self._human_layout or self._settings.KILL_COUNTER.SHOW_BOT_KILLS)
			self._accuracy:set_enabled("ai", self._human_layout)
			--self._callsign:set_enabled("ai", self._human_layout)
			self:teammate_progress(false, "", 0, false)
			
			
			
			self._component_layout = {}
			
			if self._is_player then
				table.insert(self._component_layout, { self._carry })
			end
			
			local top_components = { }
			if self._latency:visible() or self._name:visible() or self._rank:visible() or self._character:visible() or not self._player_status:visible() then
				table.insert(top_components, self._callsign)
			end
			table.insert(top_components, self._name)
			table.insert(top_components, self._rank)
			table.insert(top_components, self._character)
			table.insert(top_components, self._latency)
			table.insert(self._component_layout, top_components)
			
			table.insert(self._component_layout, { self._build })
			
			local center_components = { self._player_status, self._weapons, self._equipment, self._special_equipment }
			if not self._is_player then
				table.insert(center_components, self._carry)
			end
			table.insert(self._component_layout, center_components)
			
			table.insert(self._component_layout, { self._kills, self._accuracy })
			
			
			
			self:arrange()
		end
	end
	
	function HUDTeammateCustom:reset()
		self:set_condition("mugshot_normal")
		self:stop_timer()
		self:set_cheater(false)
		self:set_ai(nil)
		self:set_peer_id(nil)
		self:clear_special_equipment(true)
		self:teammate_progress(false, false, false, false)
		self:remove_carry_info()
		self:set_info_meter({ current = 0, total = 0, max = 1 })
		self:set_absorb_active(0)
		--self:set_cable_ties_amount(0)	--Necessary/dangerous?
		--self:set_deployable_equipment_amount(1, { amount = 0 })	--Necessary/dangerous?
		--self:set_grenades_amount({ amount = 0 })	--Necessary/dangerous?
		
		self:arrange()
	end
	
	function HUDTeammateCustom:add_panel()
		self._panel:show()
		managers.hud:arrange_teammate_panels()
	end

	function HUDTeammateCustom:remove_panel()
		self._panel:hide()
		self:reset()
	end

	function HUDTeammateCustom:peer_id()
		return self._peer_id
	end
	
	function HUDTeammateCustom:left_aligned()
		return self._left_align
	end
	
	function HUDTeammateCustom:panel()
		return self._panel
	end
	
	function HUDTeammateCustom:register_listener(id, events, clbk, prefix_event)
		for _, event in pairs(events) do
			self._listeners[event] = self._listeners[event] or {}
			self._listeners[event][id] = { clbk = clbk, prefix_event = prefix_event }
		end
	end

	function HUDTeammateCustom:unregister_listener(id, events)
		for _, event in pairs(events) do
			if self._listeners[event] then
				self._listeners[event][id] = nil
			end
		end
	end

	function HUDTeammateCustom:call_listeners(event, ...)
		for listener, data in pairs(self._listeners[event] or {}) do
			if data.prefix_event then
				data.clbk(event, ...)
			else
				data.clbk(...)
			end
		end
	end
	

	function HUDTeammateCustom:set_health(data)
		self:call_listeners("health", data.current, data.total)
	end
	
	function HUDTeammateCustom:set_stored_health(amount)
		self:call_listeners("stored_health", amount)
	end
	
	function HUDTeammateCustom:set_stored_health_max(amount)
		self:call_listeners("stored_health_max", amount)
	end
	
	function HUDTeammateCustom:set_downs(value)
		self:call_listeners("set_downs", value)
	end
	
	function HUDTeammateCustom:decrement_downs()
		self:call_listeners("decrement_downs")
	end
	
	function HUDTeammateCustom:reset_downs()
		self:call_listeners("reset_downs")
	end
	
	function HUDTeammateCustom:set_armor(data)
		self:call_listeners("armor", data.current, data.total)
	end
	
	function HUDTeammateCustom:set_stamina(amount)
		self:call_listeners("stamina", amount)
	end
	
	function HUDTeammateCustom:set_stamina_max(amount)
		self:call_listeners("stamina_max", amount)
	end
	
	function HUDTeammateCustom:set_info_meter(data)
		--printf("(DEBUG) set_info_meter: c: %s, t: %s, m: %s\n", tostring(data.current), tostring(data.total), tostring(data.max))
		--Used to set hysteria stacks. Unused in this HUD at the moment
	end
	
	function HUDTeammateCustom:set_absorb_active(amount)
		self:call_listeners("absorb_active", amount)
	end
	
	function HUDTeammateCustom:set_condition(icon_data, text)
		self:call_listeners("condition", icon_data)
	end
	
	function HUDTeammateCustom:start_timer(t)
		self:call_listeners("start_condition_timer", t)
	end
	
	function HUDTeammateCustom:stop_timer()
		self:call_listeners("stop_condition_timer")
	end
	
	function HUDTeammateCustom:set_pause_timer(pause)
		self:call_listeners("pause_condition_timer", pause)
	end
	
	function HUDTeammateCustom:set_custom_radial(data)
		self:call_listeners("custom_radial", data.current, data.total)
	end
	
	function HUDTeammateCustom:set_weapon_firemode(index, fire_mode)
		self:call_listeners("weapon_fire_mode", index, fire_mode)
	end
	
	function HUDTeammateCustom:set_weapon_selected(index, hud_icon)
		self:call_listeners("weapon_selected", index)
	end
	
	function HUDTeammateCustom:set_ammo_amount_by_type(slot, mag_max, mag_current, total_current, total_max)
		local slot_index = { primary = 2, secondary = 1, }
		self:call_listeners("ammo_amount", slot_index[slot], mag_current, mag_max, total_current, total_max)
	end
	
	function HUDTeammateCustom:set_grenades(data)
		self:call_listeners("throwable", data.icon)
		self:set_grenades_amount(data)
	end
	
	function HUDTeammateCustom:set_grenades_amount(data)
		if data.amount then
			self:call_listeners("throwable_amount", data.amount)
		end
	end
	
	function HUDTeammateCustom:set_cable_tie(data)
		self:call_listeners("cable_tie", data.icon)
		self:set_cable_ties_amount(data.amount)
	end
	
	function HUDTeammateCustom:set_cable_ties_amount(amount)
		if amount then
			self:call_listeners("cable_tie_amount", amount)
		end
	end
	
	function HUDTeammateCustom:set_deployable_equipment(data)
		self:call_listeners("deployable", data.icon)
		self:set_deployable_equipment_amount(1, data)
	end
	
	function HUDTeammateCustom:set_deployable_equipment_amount(index, data)
		if data.amount then
			self:call_listeners("deployable_amount", data.amount)
		end
	end
	
	function HUDTeammateCustom:add_special_equipment(data)
		self:call_listeners("add_special_equipment", data.id, data.icon)
		self:set_special_equipment_amount(data.id, data.amount)
	end
	
	function HUDTeammateCustom:remove_special_equipment(id)
		self:call_listeners("remove_special_equipment", id)
	end
	
	function HUDTeammateCustom:set_special_equipment_amount(id, amount)
		if amount then
			self:call_listeners("special_equipment_amount", id, amount)
		end
	end
	
	function HUDTeammateCustom:clear_special_equipment(override)
		self:call_listeners("clear_special_equipment")
		
		--TODO: WTF Overkill? This a generic reset function with a fucking awful name?
		--self:remove_panel()
		--self:add_panel()
		
		if not override then
			self:reset()
		end
	
	end
	
	function HUDTeammateCustom:set_name(name)
		if self._last_name ~= name then	--TODO: Got to be a better place for this...
			self._last_name = name
			self:reset_kill_count()
			self:reset_accuracy()
			self:reset_downs()
		end
		self:call_listeners("name", name)
	end
	
	function HUDTeammateCustom:set_callsign(id)
		self._debug_bg:set_color((tweak_data.chat_colors[id] or Color.white):with_alpha(1))
		
		if self._is_player then
			local local_peer = managers.network:session():local_peer()
			self:set_character(managers.criminals:character_name_by_peer_id(local_peer:id()))
			self:set_rank(managers.experience:current_rank(), managers.experience:current_level())
		end
	
		self:call_listeners("callsign", id)
	end
	
	function HUDTeammateCustom:set_rank(infamy, level)
		self:call_listeners("rank", infamy, level)
	end
	
	function HUDTeammateCustom:set_character(character)
		self:call_listeners("character", character)
	end
	
	function HUDTeammateCustom:set_latency(value)
		self:call_listeners("latency", value)
	end
	
	function HUDTeammateCustom:set_specialization(index, level)
		self:call_listeners("specialization", index, level)
	end
	
	function HUDTeammateCustom:set_skills(data)
		self:call_listeners("skills", data)
	end
	
	function HUDTeammateCustom:set_cheater(...)
		--TODO?
	end

	function HUDTeammateCustom:set_peer_id(peer_id)
		self._peer_id = peer_id
		
		if peer_id then
			local peer = managers.network:session():peer(peer_id)
			managers.hud:_parse_outfit_string(self._id, peer_id)
			self:set_character(managers.criminals:character_name_by_peer_id(peer_id))
			self:set_rank(peer:rank(), peer:level())
		end
	end

	function HUDTeammateCustom:set_ai(status)
		self._ai = status
	end

	function HUDTeammateCustom:set_state(state)
		self:_update_layout(state == "player" and true or false)
	end
	
	function HUDTeammateCustom:teammate_progress(enabled, tweak_data_id, timer, success)
		if enabled then
			self:call_listeners("interaction_start", tweak_data_id, timer)
		else
			self:call_listeners("interaction_stop", success)
		end
	end
	
	function HUDTeammateCustom:set_carry_info(id, value)
		self:call_listeners("set_carry", id, value)
	end
	
	function HUDTeammateCustom:remove_carry_info()
		self:call_listeners("clear_carry")
	end
	
	function HUDTeammateCustom:recreate_weapon_firemode()
		--Obsolete, ignore
	end
	
	function HUDTeammateCustom:set_accuracy(value)
		self:call_listeners("accuracy", value)
	end
	
	function HUDTeammateCustom:reset_accuracy()
		self:set_accuracy(0)
	end
	
	function HUDTeammateCustom:increment_kill_count(is_special)
		self:call_listeners("increment_kill_count", is_special)
	end
	
	function HUDTeammateCustom:reset_kill_count()
		self:call_listeners("reset_kill_count")
	end
	
	function HUDTeammateCustom:set_weapon(index, id, silencer)
		self:call_listeners("weapon", index, id, silencer)
	end

	function HUDTeammateCustom:set_available_fire_modes(index, modes)
		self:call_listeners("available_fire_modes", index, modes)
	end
	
	function HUDTeammateCustom:set_voice_com_active(active)
		self:call_listeners("voice_com", active)
	end

	function HUDTeammateCustom:damage_taken(damage_type, ratio, depleted)
		self:call_listeners("damage_taken", damage_type, ratio, depleted)
	end
	
	--Failsafe for unhandled functions
	for id, ptr in pairs(HUDTeammate) do
		if type(ptr) == "function" then
			HUDTeammateCustom[id] = HUDTeammateCustom[id] or function(self, ...)
				printf("(WARNING) HUDTeammateCustom: Unoverridden function call: %s\n", id)
			end
		end
	end
	
	
	

	PlayerInfoComponent = PlayerInfoComponent or {}

	PlayerInfoComponent.Base = PlayerInfoComponent.Base or class()

	function PlayerInfoComponent.Base:init(base_panel, owner, name, width, height)
		self._name = name
		self._owner_panel = base_panel
		self._owner = owner
		self._disable_reason = {}
		
		self._panel = self._owner_panel:panel({
			name = name,
			h = height or 0,
			w = width or 0,
		})
	end
	
	function PlayerInfoComponent.Base:destroy()
		self._panel:stop()
		self._owner_panel:remove(self._panel)
	end

	function PlayerInfoComponent.Base:set_size(w, h)
		w = w or self._panel:w()
		h = h or self._panel:h()
		
		if self._panel:w() ~= w or self._panel:h() ~= h then
			self._panel:set_size(w, h)
			return true
		end
	end
	
	function PlayerInfoComponent.Base:set_enabled(reason, status)
		self._disable_reason[reason] = (not status) and true or nil
		
		local visible = next(self._disable_reason) == nil
		if self._panel:visible() ~= visible then
			self._panel:set_visible(visible)
			return true
		end
	end

	function PlayerInfoComponent.Base:enabled()
		return next(self._disable_reason) == nil
	end
	
	function PlayerInfoComponent.Base:panel() return self._panel end
	function PlayerInfoComponent.Base:alpha() return self._panel:alpha() end
	function PlayerInfoComponent.Base:w() return self._panel:w() end
	function PlayerInfoComponent.Base:h() return self._panel:h() end
	function PlayerInfoComponent.Base:x() return self._panel:x() end
	function PlayerInfoComponent.Base:y() return self._panel:y() end
	function PlayerInfoComponent.Base:left() return self._panel:left() end
	function PlayerInfoComponent.Base:right() return self._panel:right() end
	function PlayerInfoComponent.Base:top() return self._panel:top() end
	function PlayerInfoComponent.Base:bottom() return self._panel:bottom() end
	function PlayerInfoComponent.Base:center() return self._panel:center() end
	function PlayerInfoComponent.Base:center_x() return self._panel:center_x() end
	function PlayerInfoComponent.Base:center_y() return self._panel:center_y() end
	function PlayerInfoComponent.Base:visible() return self._panel:visible() end
	function PlayerInfoComponent.Base:layer() return self._panel:layer() end

	function PlayerInfoComponent.Base:set_alpha(v) self._panel:set_alpha(v) end
	function PlayerInfoComponent.Base:set_x(v) self._panel:set_x(v) end
	function PlayerInfoComponent.Base:set_y(v) self._panel:set_y(v) end
	function PlayerInfoComponent.Base:set_left(v) self._panel:set_left(v) end
	function PlayerInfoComponent.Base:set_right(v) self._panel:set_right(v) end
	function PlayerInfoComponent.Base:set_top(v) self._panel:set_top(v) end
	function PlayerInfoComponent.Base:set_bottom(v) self._panel:set_bottom(v) end
	function PlayerInfoComponent.Base:set_center(x, y) self._panel:set_center(x, y) end
	function PlayerInfoComponent.Base:set_center_x(v) self._panel:set_center_x(v) end
	function PlayerInfoComponent.Base:set_center_y(v) self._panel:set_center_y(v) end
	function PlayerInfoComponent.Base:set_layer(v) self._panel:set_layer(v) end

	function PlayerInfoComponent.Base.get_item_icon_data(type, id)
		local tweak_entry = {
			weapon = tweak_data.weapon,
			melee = tweak_data.blackmarket.melee_weapons,
			armor = tweak_data.blackmarket.armors,
			throwable = tweak_data.blackmarket.projectiles,
			deployables = tweak_data.blackmarket.deployables,
		}
		local texture_path = {
			weapon = "textures/pd2/blackmarket/icons/weapons/",
			melee = "textures/pd2/blackmarket/icons/melee_weapons/",
			armor = "textures/pd2/blackmarket/icons/armors/",
			throwable = "textures/pd2/blackmarket/icons/grenades/",
			deployables = "textures/pd2/blackmarket/icons/deployables/",
		}

		local name_id = tweak_entry[type][id] and tweak_entry[type][id].name_id or tostring(id)
		local name_text = managers.localization:text(name_id)

		local bundle_folder = tweak_entry[type][id] and tweak_entry[type][id].texture_bundle_folder
		local guis_catalog = string.format("guis/%s", bundle_folder and string.format("dlcs/%s/", tostring(bundle_folder)) or "")
		local texture_name = tweak_entry[type][id] and tweak_entry[type][id].texture_name or tostring(id)
		local texture = string.format("%s%s%s", guis_catalog, texture_path[type], texture_name)
		
		return texture, name_text
	end

	
	PlayerInfoComponent.HealthRadial = PlayerInfoComponent.HealthRadial or class(PlayerInfoComponent.Base)

	function PlayerInfoComponent.HealthRadial:init(panel, owner, teammate_panel, size, is_player)
		PlayerInfoComponent.HealthRadial.super.init(self, panel, owner, "health", size, size)
		
		self._teammate_panel = teammate_panel
		
		self._bg = self._panel:bitmap({
			name = "bg",
			texture = "guis/textures/pd2/hud_radialbg",
			h = size,
			w = size,
		})
		
		self._radial = self._panel:bitmap({
			name = "health",
			texture = "guis/textures/pd2/hud_health",
			texture_rect = { 64, 0, -64, 64 },
			render_template = "VertexColorTexturedRadial",
			blend_mode = "add",
			color = Color(1, 1, 1),
			h = size,
			w = size,
			layer = self._bg:layer() + 1,
		})
		
		self._stored_radial = self._panel:bitmap({
			name = "stored_health",
			texture = "guis/textures/pd2/hud_health",
			texture_rect = { 64, 0, -64, 64 },
			render_template = "VertexColorTexturedRadial",
			blend_mode = "add",
			color = Color(0, 0, 0),
			alpha = 0.5,
			h = size,
			w = size,
			layer = self._radial:layer() + 1,
		})
		
		self._downs_counter = self._panel:text({
			name = "downs",
			color = Color.white,
			align = "right",
			vertical = "bottom",
			h = size * 0.5,
			w = size * 0.5,
			font_size = size * 0.35,
			font = "fonts/font_small_shadow_mf",
			layer = self._radial:layer() + 2,
			visible = HUDManager.DOWNS_COUNTER_PLUGIN or false,
		})
		self._downs_counter:set_bottom(size)
		self._downs_counter:set_right(size)
		
		self._stored_health = 0
		self._stored_health_max = 0
		self._max_downs = tweak_data.player.damage.LIVES_INIT + (is_player and managers.player:upgrade_value("player", "additional_lives", 0) or 0)
		self._downs = self._max_downs
		
		self._teammate_panel:register_listener("HealthRadial", { "health" }, callback(self, self, "set_health"), false)
		self._teammate_panel:register_listener("HealthRadial", { "stored_health" }, callback(self, self, "set_stored_health"), false)
		self._teammate_panel:register_listener("HealthRadial", { "stored_health_max" }, callback(self, self, "set_stored_health_max"), false)
		self._teammate_panel:register_listener("HealthRadial", { "set_downs" }, callback(self, self, "set_downs"), false)
		self._teammate_panel:register_listener("HealthRadial", { "decrement_downs" }, callback(self, self, "decrement_downs"), false)
		self._teammate_panel:register_listener("HealthRadial", { "reset_downs" }, callback(self, self, "reset_downs"), false)
	end
	
	function PlayerInfoComponent.HealthRadial:destroy()
		self._teammate_panel:unregister_listener("HealthRadial", { "health", "stored_health", "stored_health_max", "set_downs", "decrement_downs", "reset_downs" })
		
		PlayerInfoComponent.HealthRadial.super.destroy(self)
	end

	function PlayerInfoComponent.HealthRadial:set_health(current, total)
		local ratio = current / total
		local prev = self._radial:color().red
		
		if ratio < prev then
			self._teammate_panel:damage_taken("health", prev - ratio, ratio <= 0)
		end
		
		self._radial:set_color(Color(ratio, 1, 1))
		self._stored_radial:set_rotation(-ratio * 360)
		self:set_stored_health_max(1-ratio)
	end

	function PlayerInfoComponent.HealthRadial:set_stored_health(amount)
		self._stored_health = amount
		self._stored_radial:set_color(Color(math.min(self._stored_health, self._stored_health_max), 0, 0))
	end
	
	function PlayerInfoComponent.HealthRadial:set_stored_health_max(amount)
		self._stored_health_max = amount
		self:set_stored_health(self._stored_health)
	end
	
	function PlayerInfoComponent.HealthRadial:set_downs(amount)
		if self._downs ~= amount then
			self._downs = amount
			self._downs_counter:set_text(tostring(amount))
			self._downs_counter:set_visible(self._downs < self._max_downs)
			self._downs_counter:set_color(self._downs > 1 and Color.white or Color.red)
		end
	end
	
	function PlayerInfoComponent.HealthRadial:decrement_downs()
		self:set_downs(self._downs - 1)
	end
	
	function PlayerInfoComponent.HealthRadial:reset_downs()
		self:set_downs(self._max_downs)
	end
	

	PlayerInfoComponent.ArmorRadial = PlayerInfoComponent.ArmorRadial or class(PlayerInfoComponent.Base)

	function PlayerInfoComponent.ArmorRadial:init(panel, owner, teammate_panel, size)
		PlayerInfoComponent.ArmorRadial.super.init(self, panel, owner, "armor", size, size)
		
		self._teammate_panel = teammate_panel
		
		self._radial = self._panel:bitmap({
			name = "radial_shield",
			texture = "guis/textures/pd2/hud_shield",
			texture_rect = { 64, 0, -64, 64 },
			render_template = "VertexColorTexturedRadial",
			blend_mode = "add",
			color = Color(1, 1, 1),
			h = size,
			w = size,
		})
		
		self._teammate_panel:register_listener("ArmorRadial", { "armor" }, callback(self, self, "set_armor"), false)
	end
	
	function PlayerInfoComponent.ArmorRadial:destroy()
		self._teammate_panel:unregister_listener("ArmorRadial", { "armor" })
		
		PlayerInfoComponent.ArmorRadial.super.destroy(self)
	end
	
	function PlayerInfoComponent.ArmorRadial:set_armor(current, total)
		local ratio = current / total
		local prev = self._radial:color().red
		
		if ratio < prev then
			self._teammate_panel:damage_taken("armor", prev - ratio, ratio <= 0)
		end
		
		self._radial:set_color(Color(1, ratio, 1, 1))
	end


	PlayerInfoComponent.StaminaRadial = PlayerInfoComponent.StaminaRadial or class(PlayerInfoComponent.Base)

	function PlayerInfoComponent.StaminaRadial:init(panel, owner, teammate_panel, size)
		PlayerInfoComponent.StaminaRadial.super.init(self, panel, owner, "stamina", size, size)
		
		self._teammate_panel = teammate_panel
		
		self._radial = self._panel:bitmap({
			name = "radial_shield",
			texture = "guis/textures/pd2/hud_shield",
			texture_rect = { 64, 0, -64, 64 },
			render_template = "VertexColorTexturedRadial",
			blend_mode = "add",
			color = Color(1, 0, 0),
			halign = "scale",
			valign = "scale",
			align = "center",
			vertical = "center",
			w = size * 0.45,
			h = size * 0.45,
		})
		self._radial:set_center(size / 2, size / 2)
		
		self._teammate_panel:register_listener("StaminaRadial", { "stamina" }, callback(self, self, "set_stamina"), false)
		self._teammate_panel:register_listener("StaminaRadial", { "stamina_max" }, callback(self, self, "set_stamina_max"), false)
	end
	
	function PlayerInfoComponent.StaminaRadial:destroy()
		self._teammate_panel:unregister_listener("StaminaRadial", { "stamina", "stamina_max" })
		
		PlayerInfoComponent.StaminaRadial.super.destroy(self)
	end

	function PlayerInfoComponent.StaminaRadial:set_stamina_max(amount)
		self._max = amount
	end

	function PlayerInfoComponent.StaminaRadial:set_stamina(amount)
		local ratio = amount / (self._max or 1)
		self._radial:set_color(Color(ratio, 1, 1))
		
	--[[
		if value <= tweak_data.player.movement_state.stamina.MIN_STAMINA_THRESHOLD and not self._animating_low_stamina then
			self._animating_low_stamina = true
			stamina_bar:animate(callback(self, self, "_animate_low_stamina"), stamina_bar_outline)
		elseif value > tweak_data.player.movement_state.stamina.MIN_STAMINA_THRESHOLD and self._animating_low_stamina then
			self._animating_low_stamina = nil
		end
	]]
	end
	

	PlayerInfoComponent.DamageIndicatorRadial = PlayerInfoComponent.DamageIndicatorRadial or class(PlayerInfoComponent.Base)

	function PlayerInfoComponent.DamageIndicatorRadial:init(panel, owner, teammate_panel, size)
		PlayerInfoComponent.DamageIndicatorRadial.super.init(self, panel, owner, "armor", size, size)
		
		self._teammate_panel = teammate_panel
		
		self._indicator = self._panel:bitmap({
			name = "damage_indicator",
			texture = "guis/textures/pd2/hud_radial_rim",
			blend_mode = "add",
			color = Color(1, 1, 1, 1),
			alpha = 0,
			h = size,
			w = size,
		})
		
		self._teammate_panel:register_listener("DamageIndicatorRadial", { "damage_taken" }, callback(self, self, "damage_taken"), false)
	end
	
	function PlayerInfoComponent.DamageIndicatorRadial:destroy()
		self._teammate_panel:unregister_listener("DamageIndicatorRadial", { "damage_taken" })
		
		PlayerInfoComponent.DamageIndicatorRadial.super.destroy(self)
	end

	function PlayerInfoComponent.DamageIndicatorRadial:damage_taken(damage_type, amount, depleted)
		self._indicator:stop()
		self._indicator:animate(callback(self, self, "_animate_damage_taken"))
	end

	function PlayerInfoComponent.DamageIndicatorRadial:_animate_damage_taken(indicator)
		local st = 3
		local t = st
		local st_red_t = 0.5
		local red_t = st_red_t
		
		indicator:set_alpha(1)
		while t > 0 do
			local dt = coroutine.yield()
			t = t - dt
			red_t = math.clamp(red_t - dt, 0, 1)
			indicator:set_color(Color(1, red_t / st_red_t, red_t / st_red_t))
			indicator:set_alpha(t / st)
		end
		indicator:set_alpha(0)
	end


	PlayerInfoComponent.ConditionRadial = PlayerInfoComponent.ConditionRadial or class(PlayerInfoComponent.Base)

	function PlayerInfoComponent.ConditionRadial:init(panel, owner, teammate_panel, size)
		PlayerInfoComponent.ConditionRadial.super.init(self, panel, owner, "condition", size, size)
		
		self._teammate_panel = teammate_panel
		
		self._icon = self._panel:bitmap({
			name = "icon",
			visible = false,
			color = Color.white,
			h = size,
			w = size,
		})
		
		self._timer = self._panel:text({
			name = "timer",
			visible = false,
			color = Color.white,
			w = size,
			h = size,
			halign = "scale",
			valign = "scale",
			align = "center",
			vertical = "center",
			h = size,
			w = size,
			font_size = size * 0.5,
			font = tweak_data.hud_players.timer_font,
			layer = self._icon:layer() + 1,
		})
		
		self._reviver_count = 0
		
		self._teammate_panel:register_listener("ConditionRadial", { "condition" }, callback(self, self, "set_condition"), false)
		self._teammate_panel:register_listener("ConditionRadial", { "start_condition_timer" }, callback(self, self, "start_timer"), false)
		self._teammate_panel:register_listener("ConditionRadial", { "stop_condition_timer" }, callback(self, self, "stop_timer"), false)
		self._teammate_panel:register_listener("ConditionRadial", { "pause_condition_timer" }, callback(self, self, "pause_timer"), false)
	end
	
	function PlayerInfoComponent.ConditionRadial:destroy()
		self._teammate_panel:unregister_listener("ConditionRadial", { "set_condition", "start_condition_timer", "stop_condition_timer", "pause_condition_timer" })
		
		PlayerInfoComponent.ConditionRadial.super.destroy(self)
	end

	function PlayerInfoComponent.ConditionRadial:set_condition(icon_data)
		local visible = icon_data ~= "mugshot_normal"
		
		if visible then
			local icon, texture_rect = tweak_data.hud_icons:get_icon_data(icon_data)
			self._icon:set_image(icon, unpack(texture_rect))
		end
		
		self._icon:set_visible(visible)
	end

	function PlayerInfoComponent.ConditionRadial:start_timer(time)
		self._timer:stop()
		
		self._reviver_count = 0
		self._timer:set_font_size(self._panel:h() * 0.5)
		self._timer:show()
		self._timer:animate(callback(self, self, "_animate_timer"), time)
	end
	
	function PlayerInfoComponent.ConditionRadial:stop_timer()
		self._timer:stop()
		
		self._reviver_count = 0
		self._timer:hide()
	end

	function PlayerInfoComponent.ConditionRadial:pause_timer(pause)
		self._reviver_count = self._reviver_count + (pause and 1 or -1)
	end

	function PlayerInfoComponent.ConditionRadial:_animate_timer(timer, initial)
		local T = initial
		local LOW = 10
		local t = initial
		
		timer:set_font_size(self._panel:h() * 0.5)
		
		while t >= 0 do
			local dt = coroutine.yield()
			if self._reviver_count <= 0 then
				t = t - dt
				
				local r = 1 - t / T
				--local red = 0.2 + 0.6 * math.min(2*r, 1)
				--local green = 0.8 - 0.6 * math.max(2*(r-0.5), 0)
				--local blue = 0.2
				local red = 0.0 + 0.6 * math.min(2*r, 1)
				local green = 0.6 - 0.6 * math.max(2*(r-0.5), 0)
				local blue = 0.0
				timer:set_color(Color(red, green, blue))
				timer:set_text(string.format("%02.0f", t))
				
				if t <= LOW then
					local r = -(t - LOW)
					local rate = 180 + 180 * (r/LOW)
					local n = (1 + math.sin(r * rate)) / 2
					timer:set_font_size(math.lerp(self._panel:h() * 0.5, self._panel:h() * 0.7, n))
				end
			end
		end
		
		timer:set_text("0")
	end

	
	PlayerInfoComponent.CustomRadial = PlayerInfoComponent.CustomRadial or class(PlayerInfoComponent.Base)

	function PlayerInfoComponent.CustomRadial:init(panel, owner, teammate_panel, size)
		PlayerInfoComponent.CustomRadial.super.init(self, panel, owner, "condition", size, size)
		
		self._teammate_panel = teammate_panel
		
		self._icon = self._panel:bitmap({
			name = "radial_custom",
			texture = "guis/textures/pd2/hud_swansong",
			texture_rect = { 0, 0, 64, 64 },
			render_template = "VertexColorTexturedRadial",
			blend_mode = "add",
			color = Color(1, 0, 0, 0),
			visible = false,
			h = size,
			w = size,
		})
		
		self._teammate_panel:register_listener("CustomRadial", { "custom_radial" }, callback(self, self, "set_progress"), false)
	end
	
	function PlayerInfoComponent.CustomRadial:destroy()
		self._teammate_panel:unregister_listener("CustomRadial", { "custom_radial" })
		
		PlayerInfoComponent.CustomRadial.super.destroy(self)
	end

	function PlayerInfoComponent.CustomRadial:set_progress(current, total)
		local ratio = current / total
		self._icon:set_color(Color(1, ratio, 1, 1))
		self._icon:set_visible(ratio > 0)
	end


	PlayerInfoComponent.ManiacRadial = PlayerInfoComponent.ManiacRadial or class(PlayerInfoComponent.Base)

	function PlayerInfoComponent.ManiacRadial:init(panel, owner, teammate_panel, size)
		PlayerInfoComponent.ManiacRadial.super.init(self, panel, owner, "maniac", size, size)
		
		self._teammate_panel = teammate_panel

		self._radial = self._panel:bitmap({
			name = "radial_absorb_shield_active",
			texture = "guis/dlcs/coco/textures/pd2/hud_absorb_shield",
			texture_rect = { 0, 0, 64, 64 },
			render_template = "VertexColorTexturedRadial",
			alpha = 1,
			halign = "scale",
			valign = "scale",
			align = "center",
			vertical = "center",
			w = size * 0.92,
			h = size * 0.92,
			color = Color.black,
		})
		self._radial:set_center(size / 2, size / 2)
		
		local tweak = tweak_data.upgrades
		self._max_absorb = tweak.cocaine_stacks_dmg_absorption_value * tweak.values.player.cocaine_stack_absorption_multiplier[1] * tweak.max_total_cocaine_stacks  / tweak.cocaine_stacks_convert_levels[2]
		
		self._teammate_panel:register_listener("ManiacRadial", { "absorb_active" }, callback(self, self, "set_absorb"), false)
	end

	function PlayerInfoComponent.ManiacRadial:destroy()
		self._teammate_panel:unregister_listener("ManiacRadial", { "absorb_active" })
		
		PlayerInfoComponent.ManiacRadial.super.destroy(self)
	end
	
	function PlayerInfoComponent.ManiacRadial:set_absorb(amount)
		local r = amount / self._max_absorb
		self._radial:set_visible(r > 0)
		self._radial:set_color(Color(r, 1, 1))
	end

	function PlayerInfoComponent.ManiacRadial:set_stacks(data)
		--local r = math.clamp(data.current / data.max, 0, 1)
		--self._radial:set_visible(r > 0)
		--self._radial:set_color(Color(r, 1, 1))
	end

	
	--Composite class for the Radial player information for organizational purposes
	PlayerInfoComponent.PlayerStatusRadial = PlayerInfoComponent.PlayerStatusRadial or class(PlayerInfoComponent.Base)

	function PlayerInfoComponent.PlayerStatusRadial:init(panel, owner, size, is_player)
		PlayerInfoComponent.PlayerStatusRadial.super.init(self, panel, owner, "player_status", size, size)
		
		self._health = PlayerInfoComponent.HealthRadial:new(self._panel, self, owner, size, is_player)
		self._health:set_layer(0)
		self._armor = PlayerInfoComponent.ArmorRadial:new(self._panel, self, owner, size)
		self._armor:set_layer(1)
		self._stamina = PlayerInfoComponent.StaminaRadial:new(self._panel, self, owner, size)
		self._stamina:set_layer(1)
		self._stamina:set_enabled("not_player", is_player)
		self._damage_indicator = PlayerInfoComponent.DamageIndicatorRadial:new(self._panel, self, owner, size)
		self._damage_indicator:set_layer(2)
		self._condition = PlayerInfoComponent.ConditionRadial:new(self._panel, self, owner, size)
		self._condition:set_layer(20)
		self._custom_radial = PlayerInfoComponent.CustomRadial:new(self._panel, self, owner, size)
		self._custom_radial:set_layer(20)
		self._maniac = PlayerInfoComponent.ManiacRadial:new(self._panel, self, owner, size)
		self._maniac:set_layer(10)
	end
	
	function PlayerInfoComponent.PlayerStatusRadial:destroy()
		self._health:destroy()
		self._armor:destroy()
		self._stamina:destroy()
		self._damage_indicator:destroy()
		self._condition:destroy()
		self._custom_radial:destroy()
		self._maniac:destroy()
		
		PlayerInfoComponent.PlayerStatusRadial.super.destroy(self)
	end

	
	PlayerInfoComponent.Callsign = PlayerInfoComponent.Callsign or class(PlayerInfoComponent.Base)

	function PlayerInfoComponent.Callsign:init(panel, owner, size)
		PlayerInfoComponent.Callsign.super.init(self, panel, owner, "callsign", size, size)
		
		self._icon = self._panel:bitmap({
			name = "icon",
			texture = "guis/textures/pd2/hud_tabs",
			texture_rect = { 84, 34, 19, 19 },
			color = Color.white,
			h = size * 0.75,
			w = size * 0.75,
		})
		self._icon:set_center(self._panel:w() / 2, self._panel:h() / 2)
		
		self._owner:register_listener("Callsign", { "callsign" }, callback(self, self, "set_id"), false)
		self._owner:register_listener("Callsign", { "voice_com" }, callback(self, self, "set_voice_com_active"), false)
	end
	
	function PlayerInfoComponent.Callsign:destroy()
		self._owner:unregister_listener("Callsign", { "callsign", "voice_com" })
		
		PlayerInfoComponent.Callsign.super.destroy(self)
	end

	function PlayerInfoComponent.Callsign:set_id(id)
		self._icon:set_color((tweak_data.chat_colors[id] or Color.white):with_alpha(1))
	end

	function PlayerInfoComponent.Callsign:set_voice_com_active(status)
		self._voice_com_active = status
		
		if status and not self._animating_voice_com then
			self._icon:animate(callback(self, self, "_animate_voice_com"))
		end
	end

	function PlayerInfoComponent.Callsign:_animate_voice_com(icon)
		self._animating_voice_com = true
		local x = self._panel:w() / 2
		local y = self._panel:h() / 2
		icon:set_image("guis/textures/pd2/jukebox_playing", 0, 0, 16, 16 )
		
		while self._voice_com_active do
			local T = 2
			local t = 0
			
			while t < T do
				local r = (math.sin(t * 360)) * 0.15
				icon:set_size(self:w() * (1+r), self:h() * (1+r))
				icon:set_center(x, y)
				
				t = t + coroutine.yield()
			end
		end
		
		icon:set_image("guis/textures/pd2/hud_tabs", 84, 34, 19, 19)
		icon:set_center(x, y)
		icon:set_size(self:w(), self:h())
		self._animating_voice_com = false
	end

	
	--TODO: Possibly unify name, rank and character into wrapper or single element for organizational purposes

	
	PlayerInfoComponent.Name = PlayerInfoComponent.Name or class(PlayerInfoComponent.Base)

	function PlayerInfoComponent.Name:init(panel, owner, height)
		PlayerInfoComponent.Name.super.init(self, panel, owner, "name", 0, height)
		
		self._text = self._panel:text({
			name = "name",
			color = Color.white,
			halign = "grow",
			align = "left",
			vertical = "center",
			h = height,
			w = 0,
			font_size = height * 0.95,
			font = tweak_data.hud_players.name_font,
		})
		
		self._owner:register_listener("Name", { "callsign" }, callback(self, self, "set_id"), false)
		self._owner:register_listener("Name", { "name" }, callback(self, self, "set_name"), false)
	end

	function PlayerInfoComponent.Name:destroy()
		self._owner:unregister_listener("Name", { "callsign", "name" })
		
		PlayerInfoComponent.Name.super.destroy(self)
	end
	
	function PlayerInfoComponent.Name:set_name(name)
		self._text:set_text(name)
		local _, _, w, _ = self._text:text_rect()
		
		if self:set_size(w, self._panel:h()) then
			self._owner:arrange()
		end
	end

	function PlayerInfoComponent.Name:set_id(id)
		self._text:set_color((tweak_data.chat_colors[id] or Color.white):with_alpha(1))
	end

	
	PlayerInfoComponent.Character = PlayerInfoComponent.Character or class(PlayerInfoComponent.Base)

	function PlayerInfoComponent.Character:init(panel, owner, height)
		PlayerInfoComponent.Character.super.init(self, panel, owner, "character", 0, height)
		
		self._text = self._panel:text({
			name = "character",
			color = Color.white,
			halign = "grow",
			align = "left",
			vertical = "center",
			h = height,
			w = 0,
			font_size = height * 0.95,
			font = tweak_data.hud_players.name_font,
		})
		
		self._owner:register_listener("Character", { "callsign" }, callback(self, self, "set_id"), false)
		self._owner:register_listener("Character", { "character" }, callback(self, self, "set_character"), false)
	end

	function PlayerInfoComponent.Character:destroy()
		self._owner:unregister_listener("Character", { "character", "callsign" })
		
		PlayerInfoComponent.Character.super.destroy(self)
	end
	
	function PlayerInfoComponent.Character:set_character(character)
		local name = character and ("(" .. managers.localization:text("menu_" .. character) .. ")") or ""
		
		self._text:set_text(name)
		local _, _, w, _ = self._text:text_rect()
		
		if self:set_size(w, self._panel:h()) then
			self._owner:arrange()
		end
	end
	
	function PlayerInfoComponent.Character:set_id(id)
		self._text:set_color((tweak_data.chat_colors[id] or Color.white):with_alpha(1))
	end
	
	
	PlayerInfoComponent.Rank = PlayerInfoComponent.Rank or class(PlayerInfoComponent.Base)

	function PlayerInfoComponent.Rank:init(panel, owner, height)
		PlayerInfoComponent.Rank.super.init(self, panel, owner, "rank", 0, height)
		
		self._text = self._panel:text({
			name = "rank",
			color = Color.white,
			halign = "grow",
			align = "left",
			vertical = "center",
			h = height,
			w = 0,
			font_size = height * 0.95,
			font = tweak_data.hud_players.name_font,
		})
		
		self._owner:register_listener("Rank", { "callsign" }, callback(self, self, "set_id"), false)
		self._owner:register_listener("Rank", { "rank" }, callback(self, self, "set_rank"), false)
	end

	function PlayerInfoComponent.Rank:destroy()
		self._owner:unregister_listener("Rank", { "rank", "callsign" })
		
		PlayerInfoComponent.Rank.super.destroy(self)
	end
	
	function PlayerInfoComponent.Rank:set_rank(infamy, level)
		local text = level and tostring(level) or ""
		
		if infamy and infamy > 0 then
			text = managers.experience:rank_string(infamy) .. "-" .. text
		end
	
		self._text:set_text("[" .. text .. "]")
		local _, _, w, _ = self._text:text_rect()
		
		if self:set_size(w, self._panel:h()) then
			self._owner:arrange()
		end
	end
	
	function PlayerInfoComponent.Rank:set_id(id)
		self._text:set_color((tweak_data.chat_colors[id] or Color.white):with_alpha(1))
	end

	
	PlayerInfoComponent.Latency = PlayerInfoComponent.Latency or class(PlayerInfoComponent.Base)

	function PlayerInfoComponent.Latency:init(panel, owner, height)
		PlayerInfoComponent.Latency.super.init(self, panel, owner, "latency", height*2, height)
		
		self._text = self._panel:text({
			name = "latency",
			text = "n/a",
			color = Color.white,
			halign = "grow",
			align = "center",
			vertical = "center",
			h = height,
			font_size = height * 0.95,
			font = tweak_data.hud_players.name_font,
		})
		
		self._owner:register_listener("Latency", { "latency" }, callback(self, self, "set_latency"), false)
	end

	function PlayerInfoComponent.Latency:destroy()
		self._owner:unregister_listener("Latency", { "latency" })
		
		PlayerInfoComponent.Latency.super.destroy(self)
	end
	
	function PlayerInfoComponent.Latency:set_latency(value)
		self._text:set_text(string.format("%.0fms", value))
	end
	
	
	PlayerInfoComponent.Build = PlayerInfoComponent.Build or class(PlayerInfoComponent.Base)
	
	function PlayerInfoComponent.Build:init(panel, owner, height, duration)
		PlayerInfoComponent.Build.super.init(self, panel, owner, "build", 0, height)
		
		self._duration = duration
		
		self._specialization = self._panel:text({
			name = "specialization",
			color = Color.white,
			align = "center",
			vertical = "center",
			h = height,
			font_size = height * 0.95,
			font = tweak_data.hud_players.name_font,
		})
		
		self._skills = self._panel:text({
			name = "skills",
			color = Color.white,
			align = "center",
			vertical = "center",
			h = height,
			font_size = height * 0.95,
			font = tweak_data.hud_players.name_font,
		})
		
		self._owner:register_listener("Build", { "specialization" }, callback(self, self, "set_specialization"), false)
		self._owner:register_listener("Build", { "skills" }, callback(self, self, "set_skills"), false)
	end

	function PlayerInfoComponent.Build:destroy()
		self._owner:unregister_listener("Build", { "specialization", "skills" })
		
		PlayerInfoComponent.Build.super.destroy(self)
	end
	
	function PlayerInfoComponent.Build:arrange()
		if self._duration then
			self._panel:stop()
			self._panel:animate(callback(self, self, "_expire"), self._duration)
		end
		
		local w = self._specialization:w() + self._panel:h() * 0.2
		self._skills:set_x(w)
		w = w + self._skills:w()
		
		if self:set_size(w, self._panel:h()) then
			self._owner:arrange()
		end
	end
	
	function PlayerInfoComponent.Build:set_specialization(index, level)
		local data = tweak_data.skilltree.specializations[index]
		local name_id = data and data.name_id
			
		if name_id then
			local text = managers.localization:text(name_id)
			self._specialization:set_text(string.format("%s: %d", text, level))
			local _, _, w, _ = self._specialization:text_rect()
			self._specialization:set_w(w)
			self:arrange()
		end
	end
	
	function PlayerInfoComponent.Build:set_skills(data)
		local trees = { "M", "E", "T", "G", "F" }
		local text = ""
		
		for tree, skills in ipairs(data) do
			text = string.format("%s%s:%d ", text, trees[tree] or tostring(tree), skills)
		end
		
		self._skills:set_text(text)
		local _, _, w, _ = self._skills:text_rect()
		self._skills:set_w(w)
		self:arrange()
	end
	
	function PlayerInfoComponent.Build:_expire(panel, duration)
		if self:set_enabled("expiration", true) then
			self._owner:arrange()
		end
		self._panel:set_alpha(1)
		
		local t = duration
		while t > 0 do
			t = t - coroutine.yield()
		end
		
		t = 3
		while t > 0 do
			t = t - coroutine.yield()
			self._panel:set_alpha(t/3)
		end
		
		if self:set_enabled("expiration", false) then
			self._owner:arrange()
		end
	end
	
	
	
	PlayerInfoComponent.Weapon = PlayerInfoComponent.Weapon or class(PlayerInfoComponent.Base)

	function PlayerInfoComponent.Weapon:init(panel, owner, slot, height, settings)
		PlayerInfoComponent.Weapon.super.init(self, panel, owner, "weapon_" .. tostring(slot), 0, height)
		
		self._slot = slot
		self._settings = settings
		self._fire_modes = {}
		self._fire_mode_count = 0
		self._individual_ammo_enabled = not self._settings.AMMO.TOTAL_AMMO_ONLY
		
		self._icon_panel = self._panel:panel({
			name = "icon_panel",
			w = height * 2,
			h = height,
		})
		
		local weapon_icon = self._icon_panel:bitmap({
			name = "icon",
			halign = "grow",
			valign = "grow",
		})
		
		local silencer_icon = self._icon_panel:bitmap({
			name = "silencer_icon",
			texture = "guis/textures/pd2/blackmarket/inv_mod_silencer",
			visible = false,
			halign = "scale",
			valign = "scale",
			align = "right",
			vertical = "bottom",
			w = weapon_icon:h() * 0.25,
			h = weapon_icon:h() * 0.25,
			layer = weapon_icon:layer() + 1,
		})
		silencer_icon:set_bottom(weapon_icon:bottom())
		silencer_icon:set_right(weapon_icon:right())
		
		local label = self._icon_panel:text({
			name = "label",
			text = "N/A",
			color = Color.white,
			halign = "grow",
			valign = "scale",
			align = "center",
			vertical = "top",
			h = weapon_icon:h(),
			font_size = weapon_icon:h() * 0.2,
			font = tweak_data.hud_players.name_font,
			layer = weapon_icon:layer() + 1,
			wrap = true,
			word_wrap = true,
		})
		
		self._ammo_panel = self._panel:panel({
			name = "ammo_panel",
			h = height,
		})
			
		local ammo_mag = self._ammo_panel:text({
			name = "mag",
			text = "000",
			color = Color.white,
			halign = "grow",
			valign = "scale",
			vertical = "center",
			align = "right",
			h = self._ammo_panel:h() * 0.55,
			font_size = self._ammo_panel:h() * 0.55,
			font = tweak_data.hud_players.ammo_font
		})
		
		local ammo_total = self._ammo_panel:text({
			name = "total",
			text = "000",
			color = Color.white,
			halign = "grow",
			valign = "scale",
			vertical = "center",
			align = "right",
			h = self._ammo_panel:h() * 0.45,
			font_size = self._ammo_panel:h() * 0.45,
			font = tweak_data.hud_players.ammo_font
		})
		ammo_total:set_center_y((self._ammo_panel:h() + ammo_mag:h()) / 2)
		
		local _, _, w, _ = ammo_mag:text_rect()
		self._ammo_panel:set_w(w)
		
		self._fire_mode_panel = self._panel:panel({
			name = "fire_mode_panel",
			w = height * 0.25,
			h = height,
			visible = false,
		})
		
		local fire_mode_bg = self._fire_mode_panel:rect({
			name = "bg",
			halign = "grow",
			color = Color.white,
		})
		
		local active_mode = self._fire_mode_panel:text({
			name = "active_mode",
			text = "O",
			color = Color.black,
			vertical = "center",
			align = "center",
			w = self._fire_mode_panel:h(),
			h = self._fire_mode_panel:w(),
			font_size = self._fire_mode_panel:w() * 0.9,	
			font = "fonts/font_small_noshadow_mf",
			layer = fire_mode_bg:layer() + 1,
			rotation = -90,
		})
		active_mode:set_center(self._fire_mode_panel:center())
		
		self:arrange()
	end
	
	function PlayerInfoComponent.Weapon:add_statistics_panel()
		self._statistics_panel = self._panel:panel({
			name = "statistics_panel",
			h = self._panel:h(),
			w = 0,
		})
		
		--TODO: Check killcount and accuracy plugins, add stuff if so
	--[[
			if HUDManager.KILL_COUNT_PLUGIN then
				local kill_count_panel = parent:panel({
					name = "kill_count_panel",
					h = parent:h(),
				})
				
				local div = kill_count_panel:rect({
					name = "div",
					color = Color.white,
					w = 1,
					x = 1,
					h = kill_count_panel:h(),
					alpha = 1,
				})
				
				local header = kill_count_panel:text({
					name = "header",
					text = "Kills",
					color = Color.white,
					layer = 1,
					x = 1 + div:x(),
					h = kill_count_panel:h() * 0.5,
					vertical = "center",
					align = "center",
					font_size = kill_count_panel:h() * 0.5 * 0.75,
					font = tweak_data.hud_players.ammo_font
				})
				
				local count = kill_count_panel:text({
					name = "count",
					text = "1234/1234",
					color = Color.white,
					layer = 1,
					x = 1 + div:x(),
					y = kill_count_panel:h() * 0.5,
					h = kill_count_panel:h() * 0.5,
					vertical = "center",
					align = "center",
					font_size = kill_count_panel:h() * 0.5 * 0.75,
					font = tweak_data.hud_players.ammo_font
				})
			
				local _, _, w, _ = count:text_rect()
				w = w + div:w() + 2
				
				header:set_w(w)
				count:set_w(w)
				kill_count_panel:set_w(w)
				kill_count_panel:set_x(parent:w())
				parent:set_w(parent:w() + kill_count_panel:w())
			end
	]]

	--[[
			if HUDManager.ACCURACY_PLUGIN then
				local accuracy_panel = parent:panel({
					name = "accuracy_panel",
					h = parent:h(),
					w = parent:h() * 0.75,
				})
				
				local div = accuracy_panel:rect({
					name = "div",
					color = Color.white,
					x = 1,
					w = 1,
					h = accuracy_panel:h(),
					alpha = 1,
				})
				
				local header = accuracy_panel:text({
					name = "header",
					text = "Acc",
					color = Color.white,
					layer = 1,
					x = 1 + div:x(),
					h = accuracy_panel:h() * 0.5,
					w = accuracy_panel:w(),
					vertical = "center",
					align = "center",
					font_size = accuracy_panel:h() * 0.5 * 0.75,
					font = tweak_data.hud_players.ammo_font
				})
				
				local count = accuracy_panel:text({
					name = "count",
					text = "00000%",
					color = Color.white,
					layer = 1,
					x = 1 + div:x(),
					y = accuracy_panel:h() * 0.5,
					h = accuracy_panel:h() * 0.5,
					w = accuracy_panel:w(),
					vertical = "center",
					align = "center",
					font_size = accuracy_panel:h() * 0.5 * 0.75,
					font = tweak_data.hud_players.ammo_font
				})
				
				local _, _, w, _ = count:text_rect()
				w = w + div:w() + 2
				
				header:set_w(w)
				count:set_w(w)
				accuracy_panel:set_w(w)
				accuracy_panel:set_x(parent:w())
				parent:set_w(parent:w() + accuracy_panel:w())
			end
	]]

	--TODO: Update statisticspanel width
		self:arrange()
	end

	function PlayerInfoComponent.Weapon:arrange()
		local MARGIN = self._panel:h() * 0.05
		local w = MARGIN
		local h = self._panel:h()
		local visible = false
		
		local component_order = { self._icon_panel, self._fire_mode_panel, self._ammo_panel }
		if self._statistics_panel then
			table.insert(component_order, self._statistics_panel)
		end
		
		for _, component in ipairs(component_order) do
			if component:visible() then
				--component:set_y(0)
				component:set_x(w)
				w = w + component:w() + MARGIN
				visible = true
			end
		end
		
		local changed_enabled = self:set_enabled("panel_size", visible)
		local changed_size = self:set_size(w, h)
		
		return changed_enabled or changed_size
	end

	function PlayerInfoComponent.Weapon:set_available_fire_modes(modes, reset)
		if reset then
			self._fire_mode_count = 0
			self._fire_modes = {}
		end
		
		for _, mode in ipairs(modes) do
			local name = mode[1]
			local text = mode[2]
			self._fire_modes[name] = text
			self._fire_mode_count = self._fire_mode_count + 1
		end
	end

	function PlayerInfoComponent.Weapon:set_fire_mode(active_mode)
		if self._fire_modes[active_mode] then
			local bg = self._fire_mode_panel:child("bg")
			local text = self._fire_mode_panel:child("active_mode")
			text:set_text(utf8.to_upper(active_mode))
			local _, _, w, _ = text:text_rect()
			bg:set_h(w * 1.3)
			bg:set_center_y(self._fire_mode_panel:h() / 2)
			
			--self._fire_mode_panel:child("active_mode"):set_text(self._fire_modes[active_mode])
		end
	end

	function PlayerInfoComponent.Weapon:set_weapon(id, silencer)
		local bitmap_texture, text = PlayerInfoComponent.Base.get_item_icon_data("weapon", id)
		
		self._icon_panel:child("icon"):set_image(bitmap_texture)
		self._icon_panel:child("silencer_icon"):set_visible(silencer)
		self._icon_panel:child("label"):set_text(text)
	end

	function PlayerInfoComponent.Weapon:set_selected(status)
		self:set_alpha(status and 1 or 0.5)
		
		local items = {
			ICON = { item = self._icon_panel, prerequisite = true },
			AMMO = { item = self._ammo_panel, prerequisite = self._individual_ammo_enabled },
			FIRE_MODE = { item = self._fire_mode_panel, prerequisite = self._fire_mode_count > 1 },
		}
		
		for component, settings in pairs(self._settings) do
			local item = items[component].item
			local prereq = items[component].prerequisite
			local visible = prereq
			
			if prereq then
				if settings.HIDE then
					visible = false
				elseif settings.SELECTED_ONLY then
					visible = status
				elseif settings.UNSELECTED_ONLY then 
					visible = not status
				end
			end
			
			if item:visible() ~= visible then
				item:set_visible(visible)
			end
		end
		
		--self._fire_mode_panel:set_visible(not (self._settings.FIRE_MODE and self._settings.FIRE_MODE.HIDE) and self._fire_mode_count > 1)
		
		return self:arrange()
	end

	function PlayerInfoComponent.Weapon:set_ammo_amount(mag_current, mag_max, total_current, total_max)
		PlayerInfoComponent.AllWeapons._update_ammo_text(self._ammo_panel:child("mag"), mag_current, mag_max)
		PlayerInfoComponent.AllWeapons._update_ammo_text(self._ammo_panel:child("total"), total_current, total_max)
	end


	PlayerInfoComponent.AllWeapons = PlayerInfoComponent.AllWeapons or class(PlayerInfoComponent.Base)
	
	function PlayerInfoComponent.AllWeapons:init(panel, owner, height, weapon_count, settings)
		PlayerInfoComponent.AllWeapons.super.init(self, panel, owner, "all_weapons", 0, height)
		
		self._weapon_count = weapon_count
		self._settings = settings
		
		self._panel:rect({
			name = "bg",
			color = Color.black,
			alpha = 0.25,
			halign = "grow",
			valign = "grow",
		})
		
		self._weapons = {}
		for i = 1, weapon_count, 1 do
			local weapon = PlayerInfoComponent.Weapon:new(self._panel, self, i, height, settings)
			table.insert(self._weapons, weapon)
		end
		
		self._aggregate_ammo_panel = self._panel:panel({
			name = "aggregate_ammo_panel",
			h = height,
			visible = self._settings.AMMO.TOTAL_AMMO_ONLY and true or false,
		})
		
		self._aggregate_ammo = {}
		for i = 1, weapon_count do
			self._aggregate_ammo[i] = self._aggregate_ammo_panel:text({
				name = "aggregate_ammo_" .. tostring(i),
				text = "000",
				color = Color.white,
				halign = "grow",
				valign = "scale",
				vertical = "center",
				align = "right",
				y = (i-1) * self._aggregate_ammo_panel:h() * (1/weapon_count),
				h = self._aggregate_ammo_panel:h() * (1/weapon_count),
				font_size = self._aggregate_ammo_panel:h() * (1/weapon_count) * 0.95,
				font = tweak_data.hud_players.ammo_font
			})
			local _, _, w, _ = self._aggregate_ammo[i]:text_rect()
			self._aggregate_ammo_panel:set_w(math.max(w, self._aggregate_ammo_panel:w()))
		end
		
		self._event_callbacks = {
			weapon_fire_mode = "set_fire_mode",
			weapon = "set_weapon",
			available_fire_modes = "set_available_fire_modes",
		}
		
		self:arrange()
		
		self._owner:register_listener("Weapons", { "weapon_fire_mode" }, callback(self, self, "_event_handler"), true)
		self._owner:register_listener("Weapons", { "weapon_selected" }, callback(self, self, "_weapon_selected"), false)
		self._owner:register_listener("Weapons", { "ammo_amount" }, callback(self, self, "_ammo_amount"), false)
		self._owner:register_listener("Weapons", { "weapon" }, callback(self, self, "_event_handler"), true)
		self._owner:register_listener("Weapons", { "available_fire_modes" }, callback(self, self, "_event_handler"), true)
	end
	
	function PlayerInfoComponent.AllWeapons:destroy()
		self._owner:unregister_listener("Weapons", { "weapon_fire_mode", "weapon_selected", "ammo_amount", "weapon", "available_fire_modes" })
		
		for i, weapon in ipairs(self._weapons) do
			weapon:destroy()
		end
		
		PlayerInfoComponent.AllWeapons.super.destroy(self)
	end
	
	function PlayerInfoComponent.AllWeapons:arrange()
		local h = self._panel:h()
		local w = 0
		
		for i, weapon in ipairs(self._weapons) do
			if weapon:visible() then
				weapon:set_x(w)
				w = w + weapon:w()
			end
		end
		
		if self._aggregate_ammo_panel:visible() then
			if w > 0 then
				w = w + h * 0.2	--Margin
			end
			self._aggregate_ammo_panel:set_x(w)
			w = w + self._aggregate_ammo_panel:w()
		end
		
		if self:set_size(w, h) then
			self:set_enabled("panel_size", w > 0)
			self._owner:arrange()
		end
	end
	
	function PlayerInfoComponent.AllWeapons:_weapon_selected(slot)
		for i = 1, self._weapon_count, 1 do
			local selected = i == slot
			self._weapons[i]:set_selected(selected)
			self._aggregate_ammo[i]:set_alpha(selected and 1 or 0.5)
		end
		
		self:arrange()
	end
	
	function PlayerInfoComponent.AllWeapons:_ammo_amount(slot, mag_current, mag_max, total_current, total_max)
		self._weapons[slot]:set_ammo_amount(mag_current, mag_max, total_current, total_max)
		PlayerInfoComponent.AllWeapons._update_ammo_text(self._aggregate_ammo[slot], total_current, total_max)
	end
	
	function PlayerInfoComponent.AllWeapons:_event_handler(event, slot, ...)
		local weapon = self._weapons[slot]
		local clbk = self._event_callbacks[event]
		
		weapon[clbk](weapon, ...)
	end
	
	function PlayerInfoComponent.AllWeapons._update_ammo_text(component, current, max)
		local ratio = current / max
		
		local green = 0.7 * math.clamp((ratio - 0.25) / 0.25, 0, 1) + 0.3
		local blue = 0.7 * math.clamp(ratio/0.25, 0, 1) + 0.3
		local color = Color(1, 1, blue, green)
		component:set_text(string.format("%03.0f", current))
		component:set_color(color)
		
		local range = current < 10 and 2 or current < 100 and 1 or 0
		if range > 0 then
			component:set_range_color(0, range, color:with_alpha(0.5))
		end
		
		return ratio, component
	end
	
	
	PlayerInfoComponent.Equipment = PlayerInfoComponent.Equipment or class(PlayerInfoComponent.Base)

	function PlayerInfoComponent.Equipment:init(panel, owner, width, height, horizontal)
		PlayerInfoComponent.Equipment.super.init(self, panel, owner, "equipment", width, height)
		
		self._horizontal = horizontal
		self._equipment_types = { "deployables", "cable_ties", "throwables" }
		
		local bg = self._panel:rect({
			name = "bg",
			color = Color.black,
			alpha = 0.25,
			halign = "grow",
			valign = "grow",
			layer = -1,
		})
		
		for i, name in ipairs(self._equipment_types) do
			local panel = self._panel:panel({
				name = name,
				w = width / (self._horizontal and #self._equipment_types or 1),
				h = height / (self._horizontal and 1 or #self._equipment_types),
				visible = false,
			})
			
			local icon = panel:bitmap({
				name = "icon",
				color = Color.white,
				w = panel:h(),
				h = panel:h(),
			})
			
			local amount = panel:text({
				name = "amount",
				text = "00",
				font = "fonts/font_medium_mf",
				font_size = panel:h(),
				color = Color.white,
				align = "right",
				vertical = "center",
				w = panel:w(),
				h = panel:h()
			})
		end
		
		self:set_enabled("active", false)
		
		self._owner:register_listener("Equipment", { "throwable" }, callback(self, self, "set_throwable"), false)
		self._owner:register_listener("Equipment", { "throwable_amount" }, callback(self, self, "set_throwable_amount"), false)
		self._owner:register_listener("Equipment", { "cable_tie" }, callback(self, self, "set_cable_tie"), false)
		self._owner:register_listener("Equipment", { "cable_tie_amount" }, callback(self, self, "set_cable_tie_amount"), false)
		self._owner:register_listener("Equipment", { "deployable" }, callback(self, self, "set_deployable"), false)
		self._owner:register_listener("Equipment", { "deployable_amount" }, callback(self, self, "set_deployable_amount"), false)
	end
	
	function PlayerInfoComponent.Equipment:destroy()
		self._owner:unregister_listener("Equipment", { "deployable_amount", "deployable", "cable_tie_amount", "cable_tie", "throwable_amount", "throwable" })
		
		PlayerInfoComponent.Equipment.super.destroy(self)
	end

	function PlayerInfoComponent.Equipment:arrange()
		local i = 0
		local w = self._horizontal and 0 or self._panel:w()
		local h = self._horizontal and self._panel:h() or 0
		
		for _, name in ipairs(self._equipment_types) do
			local panel = self._panel:child(name)
		
			if panel:visible() then
				i = i + 1
			
				if self._horizontal then
					w = w + panel:w()
					panel:set_x((i-1) * panel:w())
				else
					h = h + panel:h()
					panel:set_y((i-1) * panel:h())
				end
			end
		end
		
		local changed = self:set_enabled("active", i > 0)
		changed = changed or self:set_size(w, h)
		
		if changed then
			self._owner:arrange()
		end
	end

	function PlayerInfoComponent.Equipment:set_cable_tie(icon)
		local texture, texture_rect = tweak_data.hud_icons:get_icon_data(icon)
		self._panel:child("cable_ties"):child("icon"):set_image(texture, unpack(texture_rect))
	end

	function PlayerInfoComponent.Equipment:set_cable_tie_amount(amount)	
		local panel = self._panel:child("cable_ties")
		local text = panel:child("amount")
		text:set_text(string.format("%02.0f", amount))
		text:set_range_color(0, amount < 10 and 1 or 0, Color.white:with_alpha(0.5))
		panel:set_visible(amount > 0)
		self:arrange()
	end

	function PlayerInfoComponent.Equipment:set_throwable(icon)
		local texture, texture_rect = tweak_data.hud_icons:get_icon_data(icon)
		self._panel:child("throwables"):child("icon"):set_image(texture, unpack(texture_rect))
	end

	function PlayerInfoComponent.Equipment:set_throwable_amount(amount)
		local panel = self._panel:child("throwables")
		local text = panel:child("amount")
		text:set_text(string.format("%02.0f", amount))
		text:set_range_color(0, amount < 10 and 1 or 0, Color.white:with_alpha(0.5))
		panel:set_visible(amount > 0)
		self:arrange()
	end

	function PlayerInfoComponent.Equipment:set_deployable(icon)
		local texture, texture_rect = tweak_data.hud_icons:get_icon_data(icon)
		self._panel:child("deployables"):child("icon"):set_image(texture, unpack(texture_rect))
	end

	function PlayerInfoComponent.Equipment:set_deployable_amount(amount)
		local panel = self._panel:child("deployables")
		local text = panel:child("amount")
		text:set_text(string.format("%02.0f", amount))
		text:set_range_color(0, amount < 10 and 1 or 0, Color.white:with_alpha(0.5))
		panel:set_visible(amount > 0)
		self:arrange()
	end


	PlayerInfoComponent.SpecialEquipment = PlayerInfoComponent.SpecialEquipment or class(PlayerInfoComponent.Base)

	function PlayerInfoComponent.SpecialEquipment:init(panel, owner, height)
		PlayerInfoComponent.SpecialEquipment.super.init(self, panel, owner, "special_equipment", 0, height)
		
		self._item_size = height / 3
		self._special_equipment = {}
		
		self:set_enabled("has_items", false)
		
		self._owner:register_listener("SpecialEquipment", { "add_special_equipment" }, callback(self, self, "add"), false)
		self._owner:register_listener("SpecialEquipment", { "remove_special_equipment" }, callback(self, self, "remove"), false)
		self._owner:register_listener("SpecialEquipment", { "special_equipment_amount" }, callback(self, self, "set_amount"), false)
		self._owner:register_listener("SpecialEquipment", { "clear_special_equipment" }, callback(self, self, "clear"), false)
	end
	
	function PlayerInfoComponent.SpecialEquipment:destroy()
		self._owner:unregister_listener("SpecialEquipment", { "clear_special_equipment", "special_equipment_amount", "remove_special_equipment", "add_special_equipment" })
		
		PlayerInfoComponent.Equipment.super.destroy(self)
	end

	function PlayerInfoComponent.SpecialEquipment:arrange()
		local w = 0
		local h = self._panel:h()
		local items_per_column = math.floor(self._panel:h() / self._item_size)
		
		for i, panel in ipairs(self._special_equipment) do
			local column = math.floor((i-1) / items_per_column)
			local row = (i-1) % items_per_column
			panel:set_left(column * panel:w())
			panel:set_top(row * panel:h())
			w = (column+1) * panel:w()
		end
		
		if self:set_size(w, h) then
			self:set_enabled("has_items", w > 0)
			self._owner:arrange()
		end
		
	end
	
	function PlayerInfoComponent.SpecialEquipment:add(id, icon)
		if self._panel:child(id) then
			self._panel:remove(self._panel:child(id))
		end
		
		local panel = self._panel:panel({
			name = id,
			h = self._item_size,
			w = self._item_size,
		})
		
		local texture, texture_rect = tweak_data.hud_icons:get_icon_data(icon)
		local icon = panel:bitmap({
			name = "icon",
			texture = texture,
			texture_rect = texture_rect,
			color = Color.white,
			w = panel:w(),
			h = panel:h()
		})
		
		local flash_icon = panel:bitmap({
			name = "flash_icon",
			texture = texture,
			texture_rect = texture_rect,
			color = tweak_data.hud.prime_color,
			layer = icon:layer() + 1,
			w = panel:w() + 2,
			h = panel:w() + 2
		})
		flash_icon:set_center(icon:center())
		
		local amount_bg = panel:bitmap({
			name = "amount_bg",
			texture = "guis/textures/pd2/equip_count",
			color = Color.white,
			layer = flash_icon:layer() + 1,
			visible = false,
			w = panel:w(),
			h = panel:h(),
			x = panel:w()/4,
			y = panel:h()/4,
		})
		
		local amount_text = panel:text({
			name = "amount",
			font = "fonts/font_small_noshadow_mf",
			font_size = amount_bg:h() * 0.5,
			color = Color.black,
			align = "center",
			vertical = "center",
			layer = amount_bg:layer() + 1,
			w = amount_bg:w(),
			h = amount_bg:h(),
			visible = false,
		})
		amount_text:set_center(amount_bg:center())
		
		table.insert(self._special_equipment, panel)
		self:arrange()
		
		local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
		flash_icon:animate(hud.flash_icon, nil, panel)
	end

	function PlayerInfoComponent.SpecialEquipment:set_amount(id, amount)
		local amount = amount or 0
		
		for i, panel in ipairs(self._special_equipment) do
			if panel:name() == id then
				panel:child("amount"):set_text(tostring(amount))
				panel:child("amount"):set_visible(amount > 1)
				panel:child("amount_bg"):set_visible(amount > 1)
				break
			end
		end
	end

	function PlayerInfoComponent.SpecialEquipment:remove(id)
		for i, panel in ipairs(self._special_equipment) do
			if panel:name() == id then
				self._panel:remove(table.remove(self._special_equipment, i))
				self:arrange()
				break
			end
		end
	end

	function PlayerInfoComponent.SpecialEquipment:clear()
		while #self._special_equipment > 0 do
			self._panel:remove(table.remove(self._special_equipment, 1))
		end
		self:arrange()
	end

	
	PlayerInfoComponent.Carry = PlayerInfoComponent.Carry or class(PlayerInfoComponent.Base)
	
	function PlayerInfoComponent.Carry:init(panel, owner, height, is_player)
		PlayerInfoComponent.SpecialEquipment.super.init(self, panel, owner, "carry", 0, height)
	
		self._is_player = is_player
		
		self._icon = self._panel:bitmap({
			name = "icon",
			texture = "guis/textures/pd2/hud_tabs",
			texture_rect = { 32, 33, 32, 31 },
			color = Color.white,
			h = is_player and height or (height / 2),
			w = is_player and height or (height / 2),
		})
		
		self._text = self._panel:text({
			name = "text",
			layer = 1,
			color = Color.white,
			vertical = "center",
			align = "center",
			h = is_player and height or (height / 2),
			font_size = (is_player and height or (height / 2)) * 0.8,
			font = tweak_data.hud.medium_font_noshadow,
		})
	
		self:set_enabled("active", false)
	
		self._owner:register_listener("Carry", { "set_carry" }, callback(self, self, "set"), false)
		self._owner:register_listener("Carry", { "clear_carry" }, callback(self, self, "clear"), false)
	end
	
	function PlayerInfoComponent.Carry:destroy()
		self._owner:unregister_listener("Carry", { "set_carry", "clear_carry" })
		
		PlayerInfoComponent.Carry.super.destroy(self)
	end
	
	function PlayerInfoComponent.Carry:arrange()
		local w = self._panel:w()
		local h = self._panel:h()
		
		if self._is_player then
			self._icon:set_left(0)
			self._text:set_left(self._icon:w() + self._icon:w() * 0.25)
			
			h = self._panel:h()
			w = self._text:right()
		else
			h = self._panel:h()
			w = self._text:w()
			
			self._icon:set_top(0)
			self._icon:set_center_x(w / 2)
			self._text:set_bottom(h)
			self._text:set_x(0)
		end
		
		self:set_size(w, h)
		self._owner:arrange()
	end
	
	function PlayerInfoComponent.Carry:set(id, value)
		self:_update_carry(id)
	end
	
	function PlayerInfoComponent.Carry:clear()
		self:_update_carry(nil)
	end
	
	function PlayerInfoComponent.Carry:_update_carry(id)
		if self._current_carry ~= id then
			self._current_carry = id
			
			if id then
				local name_id = tweak_data.carry[id] and tweak_data.carry[id].name_id
				local carry_text = utf8.to_upper(name_id and managers.localization:text(name_id) or "UNKNOWN")
				
				self._text:set_text(carry_text)
				local _, _, w, _ = self._text:text_rect()
				self._text:set_w(w)
			else
				self._text:set_text("")
				self._text:set_w(0)
			end
		
			if self:set_enabled("active", id) then
				self:arrange()
			end
		end
	end
	
	
	PlayerInfoComponent.Interaction = PlayerInfoComponent.Interaction or class(PlayerInfoComponent.Base)
	
	function PlayerInfoComponent.Interaction:init(panel, owner, height, min_duration)
		PlayerInfoComponent.Interaction.super.init(self, panel, owner, "interaction", 100, height)
		
		self._min_duration = min_duration or 0
		self._overlapping_panels = {}
		
		self._bg = self._panel:rect({
			name = "bg",
			color = Color.black,
			alpha = 0.25,
			valign = "grow",
			halign = "grow",
			layer = -1,
		})
		
		self._text = self._panel:text({
			name = "text",
			color = Color.white,
			h = self._panel:h() * 0.5,
			halign = "grow",
			vertical = "center",
			align = "center",
			font_size = self._panel:h() * 0.3,
			font = tweak_data.hud_players.name_font
		})
		
		self._progress_bar_outline = self._panel:bitmap({
			name = "progress_bar_outline",
			texture = "guis/textures/hud_icons",
			texture_rect = { 252, 240, 12, 48 },
			w = self._panel:h() * 0.35 * 1.2,
			layer = 10,
			rotation = 90
		})
		
		self._progress_bar_bg = self._panel:rect({
			name = "progress_bar_bg",
			color = Color.black,
			halign = "scale",
			valign = "scale",
			align = "center",
			h = self._panel:h() * 0.35,
			w = 80,
		})
		self._progress_bar_bg:set_top(self._text:bottom())
		self._progress_bar_bg:set_center_x(50)
		
		self._progress_bar = self._panel:gradient({
			name = "progress_bar",
			alpha = 0.75,
			layer = self._progress_bar_bg:layer() + 1,
			h = self._progress_bar_bg:h(),
		})
		self._progress_bar:set_center_y(self._progress_bar_bg:center_y())
		
		self._progress_timer = self._panel:text({
			name = "progress_timer",
			layer = self._progress_bar:layer() + 1,
			color = Color.white,
			halign = "scale",
			vertical = "center",
			align = "center",
			h = self._progress_bar_bg:h(),
			w = self._progress_bar_bg:w(),
			font_size = self._progress_bar_bg:h() * 0.95,
			font = tweak_data.hud_players.name_font
		})
		self._progress_timer:set_center(self._progress_bar:center())
		
		self:set_enabled("active", false)

		self._owner:register_listener("Interaction", { "interaction_start" }, callback(self, self, "start"), false)
		self._owner:register_listener("Interaction", { "interaction_stop" }, callback(self, self, "stop"), false)
	end
	
	function PlayerInfoComponent.Interaction:destroy()
		self._owner:unregister_listener("Interaction", { "interaction_start", "interaction_stop" })
		
		PlayerInfoComponent.Interaction.super.destroy(self)
	end
	
	function PlayerInfoComponent.Interaction:arrange()
		local h = self._panel:h()
		local _, _, text_w, _ = self._text:text_rect()
		
		local overlap_w = 0
		for _, panel in ipairs(self._overlapping_panels) do
			if panel:visible() then
				overlap_w = overlap_w + panel:w()
			end
		end
		
		local w = math.max(text_w * 1.5, overlap_w)
		
		if self:set_size(w, h) then
			self._owner:arrange()
		end
	end
	
	function PlayerInfoComponent.Interaction:set_overlapping_panels(panels)
		self._overlapping_panels = panels
	end
	
	function PlayerInfoComponent.Interaction:start(id, timer)
		self._panel:stop()
		
		if timer > self._min_duration then
			local action_text_id = tweak_data.interaction[id] and tweak_data.interaction[id].action_text_id or "hud_action_generic"
			local text = action_text_id and managers.localization:text(action_text_id) or ""
			
			self._text:set_color(Color.white)
			self._text:set_text(string.format("%s (%.1fs)", utf8.to_upper(text), timer))
			self:set_enabled("active", true)
			for _, panel in ipairs(self._overlapping_panels) do
				panel:set_alpha(0)
			end
			self:arrange()
			
			self._panel:animate(callback(self, self, "_animate"), timer)
		end
	end
	
	function PlayerInfoComponent.Interaction:stop(success)
		if self:visible() then
			self._panel:stop()
			self._panel:animate(callback(self, self, "_animate_complete"), success)
		end
	end
	
	function PlayerInfoComponent.Interaction:_animate(panel, timer)
		local progress_bar_goal_width = self._progress_bar_bg:w()
		self._progress_bar:set_x(self._progress_bar_bg:x())
		self._progress_bar_outline:set_h(self._progress_bar_bg:w() * 1.05)
		self._progress_bar_outline:set_center(self._progress_bar_bg:center())
		self:set_alpha(1)
		
		local b = 0
		local g_max = 0.9
		local g_min = 0.1
		local r_max = 0.9
		local r_min = 0.1		
		
		local T = 0.5
		local t = 0
		while timer > t do		
			local time_left = timer - t
			local r = t / timer
			
			self._progress_timer:set_text(string.format("%.1fs", time_left))
			self._progress_bar:set_w(progress_bar_goal_width * r)
			
			if r < 0.5 then
				local green = math.clamp(r * 2, 0, 1) * (g_max - g_min) + g_min
				self._progress_bar:set_gradient_points({ 0, Color(r_max, g_min, b), 1, Color(r_max, green, b) })
			else
				local red = math.clamp(1 - (r - 0.5) * 2, 0, 1) * (r_max - r_min) + r_min
				self._progress_bar:set_gradient_points({ 0, Color(r_max, g_min, b), 0.5/r, Color(r_max, g_max, b), 1, Color(red, g_max, b) })
			end
			
			t = t + coroutine.yield()
		end
		
		self._progress_bar:set_w(progress_bar_goal_width)
		self._progress_bar:set_gradient_points({ 0, Color(r_max, g_min, b), 0.5, Color(r_max, g_max, b), 1, Color(r_min, g_max, b) })
	end
	
	function PlayerInfoComponent.Interaction:_animate_complete(panel, success)
		self._text:set_color(success and Color.green or Color.red)
		self._text:set_text(success and "DONE" or "ABORTED")
		
		local T1 = 0.25
		local T2 = 0.5
		local t = 0
		
		while t < T1 do
			t = t + coroutine.yield()
		end
		
		t = 0
		
		while t < T2 do
			for _, panel in ipairs(self._overlapping_panels) do
				panel:set_alpha(t/T2)
			end
			self:set_alpha(1-t/T2)
			
			t = t + coroutine.yield()
		end
		
		self:set_alpha(0)
			for _, panel in ipairs(self._overlapping_panels) do
				panel:set_alpha(1)
			end
		self._text:set_text("n/a")
		self:set_enabled("active", false)
		
		self:arrange()
	end
	

	PlayerInfoComponent.KillCounter = PlayerInfoComponent.KillCounter or class(PlayerInfoComponent.Base)
	
	function PlayerInfoComponent.KillCounter:init(panel, owner, height, show_special_kills)
		PlayerInfoComponent.KillCounter.super.init(self, panel, owner, "kill_counter", 0, height)
		
		self._show_special_kills = show_special_kills
		
		self._icon = self._panel:bitmap({
			name = "icon",
			texture = "guis/textures/pd2/cn_miniskull",
			color = Color.white,
			h = height,
			w = height,
		})
		
		self._text = self._panel:text({
			name = "text",
			layer = 1,
			color = Color.white,
			vertical = "center",
			align = "center",
			h = height,
			font_size = height * 0.95,
			font = tweak_data.hud.medium_font_noshadow,
		})
		self._text:set_left(self._icon:right() + 1)
		
		self:reset()
		
		self._owner:register_listener("KillCounter", { "increment_kill_count" }, callback(self, self, "increment"), false)
		self._owner:register_listener("KillCounter", { "reset_kill_count" }, callback(self, self, "reset"), false)
	end
	
	function PlayerInfoComponent.KillCounter:destroy()
		self._owner:unregister_listener("KillCounter", { "increment_kill_count", "reset_kill_count" })
		
		PlayerInfoComponent.KillCounter.super.destroy(self)
	end
	
	function PlayerInfoComponent.KillCounter:increment(is_special)
		self._kills = self._kills + 1
		self._special_kills = self._special_kills + (is_special and 1 or 0)
		self:_update_text()
	end
	
	function PlayerInfoComponent.KillCounter:reset()
		self._kills = 0
		self._special_kills = 0
		self:_update_text()
	end
	
	function PlayerInfoComponent.KillCounter:_update_text()
		if self._show_special_kills then
			self._text:set_text(string.format("%d/%d", self._kills, self._special_kills))
		else
			self._text:set_text(string.format("%d", self._kills))
		end
		
		local _, _, w, _ = self._text:text_rect()
		self._text:set_w(w)
		
		if self:set_size(self._text:right(), self._panel:h()) then
			self._owner:arrange()
		end
	end
	
	
	PlayerInfoComponent.AccuracyCounter = PlayerInfoComponent.AccuracyCounter or class(PlayerInfoComponent.Base)
	
	function PlayerInfoComponent.AccuracyCounter:init(panel, owner, height)
		PlayerInfoComponent.AccuracyCounter.super.init(self, panel, owner, "accuracy_counter", 0, height)
	
		self._icon = self._panel:bitmap({
			name = "icon",
			texture = "guis/textures/pd2/pd2_waypoints",
			texture_rect = { 96, 0, 32, 32 },
			color = Color.white,
			h = height,
			w = height,
		})
		
		self._text = self._panel:text({
			name = "text",
			layer = 1,
			color = Color.white,
			vertical = "center",
			align = "center",
			h = height,
			font_size = height * 0.95,
			font = tweak_data.hud.medium_font_noshadow,
		})
		self._text:set_left(self._icon:right() + 1)
	
		self:set_accuracy(0)
	
		self._owner:register_listener("AccuracyCounter", { "accuracy" }, callback(self, self, "set_accuracy"), false)
	end
	
	function PlayerInfoComponent.AccuracyCounter:destroy()
		self._owner:unregister_listener("AccuracyCounter", { "accuracy" })
		
		PlayerInfoComponent.AccuracyCounter.super.destroy(self)
	end
	
	function PlayerInfoComponent.AccuracyCounter:set_accuracy(value)
		self._text:set_text(string.format("%.0f%%", value))
		
		local _, _, w, _ = self._text:text_rect()
		self._text:set_w(w)
		
		if self:set_size(self._text:right(), self._panel:h()) then
			self._owner:arrange()
		end
	end
	
	
	--Unused, remember to update arrange handling
	PlayerInfoComponent.Throwable = PlayerInfoComponent.Throwable or class(PlayerInfoComponent.Base)

	function PlayerInfoComponent.Throwable:init(panel, owner, height)
		PlayerInfoComponent.Throwable.super.init(self, panel, owner, "throwable", 0, height)
			
		self._icon_panel = self._panel:panel({
			name = "icon_panel",
			w = self._panel:h() * 2,
			h = self._panel:h(),
		})
		
		local icon = self._icon_panel:bitmap({
			name = "icon",
			w = self._icon_panel:w(),
			h = self._icon_panel:h(),
		})
			
		local label = self._icon_panel:text({
			name = "label",
			text = "N/A",
			color = Color.white,
			align = "center",
			vertical = "top",
			h = self._icon_panel:h(),
			w = self._icon_panel:w(),
			font_size = self._icon_panel:h() * 0.2,
			font = tweak_data.hud_players.name_font,
			layer = weapon_icon:layer() + 1,
			wrap = true,
			word_wrap = true,
		})
			
		local amount = self._icon_panel:text({
			name = "amount",
			text = "0",
			color = Color.white,
			layer = weapon_icon:layer() + 1,
			w = self._icon_panel:w(),
			h = self._icon_panel:h() * 0.35,
			vertical = "center",
			align = "right",
			font_size = self._icon_panel:h() * 0.35,
			font = tweak_data.hud_players.ammo_font
		})
		amount:set_bottom(self._icon_panel:h())
	end

	function PlayerInfoComponent.Throwable:add_statistics_panel()
		self._statistics_panel = self._panel:panel({
			name = "statistics_panel",
			h = self._panel:h(),
			w = 0,
		})
		
		--TODO: Check killcount plugin, add stuff if so
	--[[
			if HUDManager.KILL_COUNT_PLUGIN then
				local kill_count_panel = parent:panel({
					name = "kill_count_panel",
					h = parent:h(),
				})
				
				local div = kill_count_panel:rect({
					name = "div",
					color = Color.white,
					w = 1,
					x = 1,
					h = kill_count_panel:h(),
					alpha = 1,
				})
				
				local header = kill_count_panel:text({
					name = "header",
					text = "Kills",
					color = Color.white,
					layer = 1,
					x = 1 + div:x(),
					h = kill_count_panel:h() * 0.5,
					vertical = "center",
					align = "center",
					font_size = kill_count_panel:h() * 0.5 * 0.75,
					font = tweak_data.hud_players.ammo_font
				})
				
				local count = kill_count_panel:text({
					name = "count",
					text = "1234/1234",
					color = Color.white,
					layer = 1,
					x = 1 + div:x(),
					y = kill_count_panel:h() * 0.5,
					h = kill_count_panel:h() * 0.5,
					vertical = "center",
					align = "center",
					font_size = kill_count_panel:h() * 0.5 * 0.75,
					font = tweak_data.hud_players.ammo_font
				})
			
				local _, _, w, _ = count:text_rect()
				w = w + div:w() + 2
				
				header:set_w(w)
				count:set_w(w)
				kill_count_panel:set_w(w)
				kill_count_panel:set_x(parent:w())
				parent:set_w(parent:w() + kill_count_panel:w())
			end
	]]

	--TODO: Update statisticspanel width
		self:arrange()
	end

	function PlayerInfoComponent.Throwable:arrange()
		local MARGIN = self._panel:h() * 0.1
		
		local w = 0
		local h = self:h()
		
		if self._icon_panel:visible() then
			self._icon_panel:set_left(w)
			w = w + MARGIN + self._icon_panel:w()
		end
		
		if self._statistics_panel and self._statistics_panel:visible() then
			self._statistics_panel:set_left(w)
			w = w + MARGIN + self._statistics_panel:w()
		end
		
		if w > 0 then
			w = w - MARGIN
		end
		
		PlayerInfoComponent.Throwable.super.arrange(self, w, h)
		if self._owner then
			self._owner:arrange()
		end
	end

	function PlayerInfoComponent.Throwable:set_icon(id)
		local texture, text = PlayerInfoComponent.Base.get_item_icon_data("throwable", id)
		
		self._icon_panel:child("icon"):set_image(texture)
		self._icon_panel:child("label"):set_text(text)
	end

	function PlayerInfoComponent.Throwable:set_amount(count)
		self._icon_panel:child("amount"):set_text(tostring(count))
	end


	PlayerInfoComponent.Melee = PlayerInfoComponent.Melee or class(PlayerInfoComponent.Base)


	PlayerInfoComponent.Armor = PlayerInfoComponent.Armor or class(PlayerInfoComponent.Base)


	PlayerInfoComponent.Deployable = PlayerInfoComponent.Deployable or class(PlayerInfoComponent.Base)
	
end


if RequiredScript == "lib/managers/hudmanagerpd2" then

	HUDManager.CUSTOM_TEAMMATE_PANELS = true	--External flag

	local update_original = HUDManager.update
	local add_weapon_original = HUDManager.add_weapon
	local set_stamina_value_original = HUDManager.set_stamina_value
	local set_max_stamina_original = HUDManager.set_max_stamina
	local set_mugshot_voice_original = HUDManager.set_mugshot_voice
	local set_teammate_carry_info_original = HUDManager.set_teammate_carry_info
	local remove_teammate_carry_info_original = HUDManager.remove_teammate_carry_info

	function HUDManager:_create_teammates_panel(hud, ...)
		hud = hud or managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
		
		self._hud.teammate_panels_data = self._hud.teammate_panels_data or {}
		self._teammate_panels = {}
		
		if hud.panel:child("teammates_panel") then	
			hud.panel:remove(hud.panel:child("teammates_panel"))
		end
		
		if hud.panel:child("bag_presenter") then
			hud.panel:remove(hud.panel:child("bag_presenter"))
		end
		
		self._bag_presenter = BagPresenter:new(hud.panel)
		
		local teammates_panel = hud.panel:panel({
			name = "teammates_panel",
			w = hud.panel:w(),
			h = hud.panel:h(),
		})
		
		local j = 1
		local num_panels = math.max(CriminalsManager.MAX_NR_CRIMINALS, HUDManager.PLAYER_PANEL) --4
		
		for i = 1, num_panels do
			local is_player = i == HUDManager.PLAYER_PANEL
			local align
			
			if is_player or j <= math.ceil(num_panels / 2) then
				align = "left"
			else
				align = "right"
			end
			
			local teammate = HUDTeammateCustom:new(i, teammates_panel, is_player, align)
			
			self._hud.teammate_panels_data[i] = {
				taken = is_player, 
				special_equipments = {},
			}
			
			table.insert(self._teammate_panels, teammate)
			
			if is_player then
				teammate:add_panel()
			else
				j = j + 1
			end
		end	
		
		self:arrange_teammate_panels()
	end

	function HUDManager:update(...)
		for i, panel in ipairs(self._teammate_panels) do
			panel:update(...)
		end
		
		return update_original(self, ...)
	end

	function HUDManager:add_weapon(data, ...)
		local wbase = data.unit:base()
		
		self:set_teammate_weapon(HUDManager.PLAYER_PANEL, data.inventory_index, wbase.name_id, wbase:got_silencer())
		
		--TODO: Fix. Does not recognize locked modes
		local active_mode = wbase:fire_mode()
		local fire_modes = {}
		if wbase:fire_mode() == "single" or (wbase:can_toggle_firemode() and not wbase._locked_fire_mode) then
			table.insert(fire_modes, { "single", "S" })
		end
		if wbase.can_use_burst_mode and wbase:can_use_burst_mode() then
			active_mode = wbase:in_burst_mode() and "burst" or active_mode
			table.insert(fire_modes, { "burst", "B" })
		end
		if wbase:fire_mode() == "auto" or (wbase:can_toggle_firemode() and not wbase._locked_fire_mode) then
			table.insert(fire_modes, { "auto", "A" })
		end
		
		self:set_teammate_available_fire_modes(HUDManager.PLAYER_PANEL, data.inventory_index, fire_modes)
		self:set_teammate_weapon_firemode(HUDManager.PLAYER_PANEL, data.inventory_index, active_mode)
		
		return add_weapon_original(self, data, ...)
	end

	function HUDManager:set_stamina_value(...)
		self._teammate_panels[HUDManager.PLAYER_PANEL]:set_stamina(...)
		return set_stamina_value_original(self, ...)
	end
	
	function HUDManager:set_max_stamina(...)
		self._teammate_panels[HUDManager.PLAYER_PANEL]:set_stamina_max(...)
		return set_max_stamina_original(self, ...)
	end
	
	function HUDManager:set_mugshot_voice(id, active, ...)
		for i, data in pairs(managers.criminals:characters()) do
			if data.data.mugshot_id == id then
				local panel_id = data.data and data.data.panel_id
				if panel_id and panel_id ~= HUDManager.PLAYER_PANEL then
					self._teammate_panels[panel_id]:set_voice_com_active(active)
				end
				break
			end
		end
		
		return set_mugshot_voice_original(self, id, active, ...)
	end
	
	function HUDManager:set_teammate_carry_info(i, ...)
		if i == HUDManager.PLAYER_PANEL then
			self._bag_presenter:set_carry(...)
		end
		
		return set_teammate_carry_info_original(self, i, ...)
	end
	
	function HUDManager:remove_teammate_carry_info(i, ...)
		if i == HUDManager.PLAYER_PANEL then
			self._bag_presenter:clear_carry()
			self._teammate_panels[i]:remove_carry_info(...)
		end
		
		return set_teammate_carry_info_original(self, i, ...)
	end

	--NEW FUNCTIONS
	function HUDManager:arrange_teammate_panels()
		local MARGIN = 5
		local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
		local hud_panel = hud.panel
		local teammate_height = 0
		local left_height_offset = 0
		local right_height_offset = 0
		
		for i, teammate in ipairs(self._teammate_panels) do
			local panel = teammate:panel()
			
			if panel:visible() then
				if i == HUDManager.PLAYER_PANEL then
					panel:set_center(hud_panel:w() / 2, 0)
					panel:set_bottom(hud_panel:h())
				else
					if teammate:left_aligned() then
						panel:set_left(0)
						panel:set_bottom(hud_panel:h() - left_height_offset)
						left_height_offset = left_height_offset + MARGIN + panel:h()
					else
						panel:set_right(hud_panel:w())
						panel:set_bottom(hud_panel:h() - right_height_offset)
						right_height_offset = right_height_offset + MARGIN + panel:h()
					end
				end
			end
		end
		
		if managers.hudlist then
			local list_panel = managers.hudlist:list("buff_list"):panel()
			list_panel:set_bottom(hud_panel:h() - self._teammate_panels[HUDManager.PLAYER_PANEL]:panel():h() - 10)
		end
	end
	
	function HUDManager:teammate_panel(i)
		return self._teammate_panels[i]
	end
	
	function HUDManager:set_player_carry_info(carry_id, value)
		self._teammate_panels[HUDManager.PLAYER_PANEL]:set_carry_info(carry_id, value)
	end
	
	function HUDManager:set_teammate_weapon(i, index, id, silencer)
		self._teammate_panels[i]:set_weapon(index, id, silencer)
	end

	function HUDManager:set_teammate_available_fire_modes(i, index, modes)
		self._teammate_panels[i]:set_available_fire_modes(index, modes)
	end

	function HUDManager:set_teammate_weapon_firemode_burst(selection_index)
		self:set_teammate_weapon_firemode(HUDManager.PLAYER_PANEL, selection_index, "burst")
	end
	
	function HUDManager:_parse_outfit_string(panel_id, peer_id)
		local outfit
		
		if peer_id == managers.network:session():local_peer():id() then
			--local outfit = managers.blackmarket:unpack_outfit_from_string(managers.blackmarket:outfit_string())
			--Weapons handled by HUDManager:add_weapon()
		else
			local peer = managers.network:session():peer(peer_id)
			outfit = peer and peer:blackmarket_outfit()
			
			if outfit then
				--Weapon
				for selection, data in ipairs({ outfit.secondary, outfit.primary }) do
					local weapon_id = managers.weapon_factory:get_weapon_id_by_factory_id(data.factory_id)
					local silencer = managers.weapon_factory:has_perk("silencer", data.factory_id, data.blueprint)
					self:set_teammate_weapon(panel_id, selection, weapon_id, silencer)
				end
				
				--Perk deck
				local deck_index, deck_level = unpack(outfit.skills.specializations)
				local skills = outfit.skills.skills
				self:set_teammate_specialization(panel_id, tonumber(deck_index), tonumber(deck_level))
				self:set_teammate_skills(panel_id, skills)
			end
		end
	

		
		

		
		--self:_set_armor(outfit.armor)
		--self:_set_melee(outfit.melee_weapon)
		--self:_set_deployable_id(outfit.deployable)
		--self:_set_throwable(outfit.grenade)
		--self:_set_skills(table.map_copy(outfit.skills.skills))
		--self:_set_specialization(table.map_copy(outfit.skills.specializations))
	end
	
	function HUDManager:set_teammate_accuracy(i, value)
		self._teammate_panels[i]:set_accuracy(value)
	end
	
	function HUDManager:set_teammate_weapon_accuracy(i, slot, value)
		--TODO
	end
	
	function HUDManager:increment_teammate_kill_count(i, is_special)
		self._teammate_panels[i]:increment_kill_count(is_special)
	end
	
	function HUDManager:reset_teammate_kill_count(i)
		self._teammate_panels[i]:reset_kill_count()
	end
	
	function HUDManager:increment_teammate_kill_count_detailed(i, unit, weapon_type, weapon_slot)
		--TODO
	end
	
	function HUDManager:set_teammate_downs(i, value)
		self._teammate_panels[i]:set_downs(value or 0)
	end
	
	function HUDManager:decrement_teammate_downs(i)
		self._teammate_panels[i]:decrement_downs()
	end
	
	function HUDManager:reset_teammate_downs(i)
		self._teammate_panels[i]:reset_downs()
	end
	
	function HUDManager:set_teammate_specialization(i, index, level)
		if index and level then
			self._teammate_panels[i]:set_specialization(index, level)
		end
	end
	
	function HUDManager:set_teammate_skills(i, data)
		self._teammate_panels[i]:set_skills(data)
	end
	
	
	BagPresenter = BagPresenter or class()
	
	function BagPresenter:init(parent_panel)
		self._parent_panel = parent_panel
		
		self._panel = parent_panel:panel({
			name = "bag_presenter",
			visible = false,
		})
		
		self._bg_box = HUDBGBox_create(self._panel, {
			name = "bg_box",
			halign = "grow",
			valign = "grow",
		})
		
		self._carry_text = self._panel:text({
			name = "carry_text",
			align = "center",
			vertical = "center",
			valign = "grow",
			halign = "grow",
			color = Color.white,
			font = "fonts/font_medium_mf",
		})
		self._carry_text:set_x(0)
		self._carry_text:set_y(0)
	end
	
	function BagPresenter:clear_carry()
		self:set_carry()
	end
	
	function BagPresenter:set_carry(carry_id, value)
		self._carry_id = carry_id
		self._carry_value = value
		
		self._panel:stop()
		
		if carry_id then
			local tweak = tweak_data.carry[self._carry_id]
			local name_id = tweak and tweak.name_id
			local carry_text = name_id and managers.localization:text(name_id) or "N/A"
			self._carry_text:set_font_size(30)
			self._carry_text:set_text(carry_text)
			local _, _, w, h = self._carry_text:text_rect()
			self._panel:animate(callback(self, self, "_animate_present"), w * 1.5, h * 1.5)
		else
			managers.hud:set_player_carry_info()
			self._panel:hide()
		end
	end
	
	function BagPresenter:_animate_present(panel, panel_w, panel_h)
		local player_panel = managers.hud:teammate_panel(HUDManager.PLAYER_PANEL)
		local x1 = self._parent_panel:w() * 0.5
		local y1 = self._parent_panel:h() * 0.25
		local x2 = player_panel:panel():center_x()
		local y2 = player_panel:panel():top()
		local w1 = panel_w
		local w2 = panel_w
		local w3 = w2 * 0.5
		local h1 = 0
		local h2 = panel_h
		local h3 = h2 * 0.5
		local f1 = self._carry_text:font_size()
		local f2 = f1 * 0.5
		local a1 = 1
		local a2 = 0.5
		
		self._panel:set_alpha(a1)
		self._panel:show()
		
		local T = 0.15
		local t = 0
		while t < T do
			local r = t/T
			self._panel:set_size(math.lerp(w1, w2, r), math.lerp(h1, h2, r))
			self._panel:set_center(x1, y1)
			t = t + coroutine.yield()
		end
		
		wait(0.1)
		
		local i = 8
		while i > 0 do
			self._panel:set_visible(not self._panel:visible())
			i = i - 1
			wait(0.1)
		end
		
		wait(0.25)
		
		T = 0.5
		t = 0
		while t < T do
			local r = t/T
			self._panel:set_size(math.lerp(w2, w3, r), math.lerp(h2, h3, r))
			self._carry_text:set_font_size(math.lerp(f1, f2, r))
			self._panel:set_center(math.lerp(x1, x2, r), math.lerp(y1, y2, r))
			self._panel:set_alpha(math.lerp(a1, a2, r))
			t = t + coroutine.yield()
		end
		
		self._panel:hide()
		managers.hud:set_player_carry_info(self._carry_id, self._carry_value)
	end
	
end

if RequiredScript == "lib/managers/hud/hudtemp" then

	local init_original = HUDTemp.init

	function HUDTemp:init(...)
		init_original(self, ...)
		self._temp_panel:set_alpha(0)
	end
	
end
