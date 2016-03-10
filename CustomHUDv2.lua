if RequiredScript == "lib/managers/hudmanagerpd2" then
	
	HUDTeamPanelBase = HUDTeamPanelBase or class()
	HUDPlayerPanel = HUDPlayerPanel or class(HUDTeamPanelBase)
	HUDTeammatePanel = HUDTeammatePanel or class(HUDTeamPanelBase)
	
	HUDTeamPanelBase.DEBUG_SHOW_PANEL_AREA = false	--Show panel area
	HUDPlayerPanel.DEBUG_HIDE = false	--Don't show player panel
	HUDTeammatePanel.DEBUG_HIDE = false	--Don't show teammate panels
	
	--Settings for player panel
	HUDPlayerPanel.SCALE = 1	--Scale factor of panel and components
	HUDPlayerPanel.SHOW_WEAPONS_ICONS = false	--Show icons for equipped weapons
	HUDPlayerPanel.SHOW_SELECTED_WEAPON_ICONS_ONLY = false	--Only show the icon of the currently equipped weapon (requires SHOW_WEAPONS_ICONS)
	HUDPlayerPanel.SHOW_AMMO = true	--Show the mag/total ammo count of both weapons
	HUDPlayerPanel.SHOW_FIRE_MODE = true	--Show the current fire mode of both weapons
	HUDPlayerPanel.SHOW_EQUIPMENT = true	--Show deployables, cable ties and throwables
	HUDPlayerPanel.SHOW_SPECIAL_EQUIPMENT = true	--Show special equipment pickups
	HUDPlayerPanel.SHOW_CARRY_INFO = true	--Show carried bags
	
	HUDTeammatePanel.SCALE = 1	--Scale factor of panel and components
	HUDTeammatePanel.SHOW_WEAPONS_ICONS = false	--Show icons for equipped weapons
	HUDTeammatePanel.SHOW_SELECTED_WEAPON_ICONS_ONLY = false	--Only show the icon of the currently equipped weapon (requires SHOW_WEAPONS_ICONS)
	HUDTeammatePanel.SHOW_AMMO = true	--Show the mag/total ammo count of both weapons
	HUDTeammatePanel.SHOW_EQUIPMENT = true	--Show deployables, cable ties and throwables
	HUDTeammatePanel.SHOW_SPECIAL_EQUIPMENT = true	--Show special equipment pickups
	HUDTeammatePanel.SHOW_CARRY_INFO = true	--Show carried bags
	HUDTeammatePanel.SHOW_NAME = true	--Show the screen name of the peer
	HUDTeammatePanel.SHOW_INTERACTIONS = 1	--Min interaction duration to show, or false to show nothing
	
	
	function HUDTeamPanelBase:init(width, height, scale, id, parent)
		self._id = id
		self._parent = parent
		
		
		self._player_data = {
			accuracy = HUDManager.ACCURACY_PLUGIN and {
				total = 0,
				[1] = 0,
				[2] = 0,
			},
			kill_count = HUDManager.KILL_COUNT_PLUGIN and {
				total = {
					special = 0,
					normal = 0,
				},
				by_weapon = {
					melee = {
						special = 0,
						normal = 0,
					},
					throwable = {
						special = 0,
						normal = 0,
					},
					sentry = {
						special = 0,
						normal = 0,
					},
					trip_mine = {
						special = 0,
						normal = 0,
					},
					weapon = {
						slotted = true,
						[1] = {
							special = 0,
							normal = 0,
						},
						[2] = {
							special = 0,
							normal = 0,
						},
					},
				},
				by_unit = {},
			},
		}		
		
		self._show_selected_weapon_icon_only = self.SHOW_SELECTED_WEAPON_ICONS_ONLY
		self._show_equipment = self.SHOW_EQUIPMENT
		self._show_special_equipment = self.SHOW_SPECIAL_EQUIPMENT
		self._show_carry_info = self.SHOW_CARRY_INFO
		
		self._timer = 0
		self._special_equipment = {}
		self._selected_weapon = 1
		
		self._panel = self._parent:panel({
			name = "teammates_panel_" .. tostring(self._id),
			w = width * scale,
			h = height * scale,
			visible = false,
		})
		
		self:_create_health_panel(self._panel:h() * 0.75)
		self:_create_callsign_panel(self._health_panel:h())
		self:_create_weapons_panel(self._health_panel:h())
		self:_create_equipment_panel(self._health_panel:h())
		self:_create_special_equipment_panel(self._health_panel:h())
		self:_create_carry_panel()
		
		self:set_show_weapon_icons(self.SHOW_WEAPONS_ICONS)
		self:set_show_ammo(self.SHOW_AMMO)
		
		if HUDTeamPanelBase.DEBUG_SHOW_PANEL_AREA then
			local test_bg = self._panel:rect({
				name = "test_bg",
				blend_mode = "normal",
				color = Color((self._id / (math.random() * 10 + 1)) % 1, (self._id / (math.random() * 10 + 1)) % 1, (self._id / (math.random() * 10 + 1)) % 1),
				w = self._panel:w(),
				h = self._panel:h(),
				layer = -100,
				alpha = 0.35,
			})
		end
	
	end
	
	function HUDTeamPanelBase:set_show_health(status)
		self._health_panel:set_w(status and self._health_default_w or 0)
		self:_arrange_panel()
	end
	
	function HUDTeamPanelBase:set_show_weapon_icons(status)
		self._show_weapon_icons = status
	
		for i = 2, 1, -1 do
			local sub_panel = self._weapons_panel:child("weapons_panel_" .. i)
			local w = status and (not self._show_selected_weapon_icon_only or (i == self._selected_weapon)) and sub_panel:h() * 2 or 0
			sub_panel:child("icon_panel"):set_w(w)
		end
		
		self:_arrange_weapons_panel()
		self:_arrange_panel()
	end
	
	function HUDTeamPanelBase:set_show_ammo(status)
		for i = 2, 1, -1 do
			self._weapons_panel:child("weapons_panel_" .. i):child("ammo_panel"):set_w(status and self._ammo_panel_default_w or 0)
		end
		
		self:_arrange_weapons_panel()
		self:_arrange_panel()
	end
	
	function HUDTeamPanelBase:set_show_equipment(status)
		self._show_equipment = status
		self:_check_equipment_panel_visibility()
	end
	
	function HUDTeamPanelBase:set_show_special_equipment(status)
		self._show_special_equipment = status
		self:_layout_special_equipments()
	end
	
	function HUDTeamPanelBase:set_show_carry_info(status)
		self._show_carry_info = status
		self:set_carry_info(self._current_carry)
	end
	
	function HUDTeamPanelBase:_arrange_panel()
		self._callsign_panel:set_center(self._health_panel:center())
	end
	
	function HUDTeamPanelBase:panel()
		return self._panel
	end
	
	function HUDTeamPanelBase:peer_id()
		return self._peer_id
	end
	
	function HUDTeamPanelBase:_create_health_panel(size)
		self._health_default_w = size
		self._health_panel = self._panel:panel({
			name = "radial_health_panel",
			w = size,
			h = size,
		})

		local health_panel_bg = self._health_panel:bitmap({
			name = "radial_bg",
			texture = "guis/textures/pd2/hud_radialbg",
			w = self._health_panel:w(),
			h = self._health_panel:h(),
			layer = 0,
		})
		
		local radial_health = self._health_panel:bitmap({
			name = "radial_health",
			texture = "guis/textures/pd2/hud_health",
			texture_rect = { 64, 0, -64, 64 },
			render_template = "VertexColorTexturedRadial",
			blend_mode = "add",
			color = Color(1, 1, 0, 0),
			w = self._health_panel:w(),
			h = self._health_panel:h(),
			layer = 2,
		})
		
		local radial_shield = self._health_panel:bitmap({
			name = "radial_shield",
			texture = "guis/textures/pd2/hud_shield",
			texture_rect = { 64, 0, -64, 64 },
			render_template = "VertexColorTexturedRadial",
			blend_mode = "add",
			color = Color(1, 1, 0, 0),
			w = self._health_panel:w(),
			h = self._health_panel:h(),
			layer = 1
		})
		
		local damage_indicator = self._health_panel:bitmap({
			name = "damage_indicator",
			texture = "guis/textures/pd2/hud_radial_rim",
			blend_mode = "add",
			color = Color(1, 1, 1, 1),
			alpha = 0,
			w = self._health_panel:w(),
			h = self._health_panel:h(),
			layer = 1
		})
		local radial_custom = self._health_panel:bitmap({
			name = "radial_custom",
			texture = "guis/textures/pd2/hud_swansong",
			texture_rect = { 0, 0, 64, 64 },
			render_template = "VertexColorTexturedRadial",
			blend_mode = "add",
			color = Color(1, 0, 0, 0),
			visible = false,
			w = self._health_panel:w(),
			h = self._health_panel:h(),
			layer = 2
		})
		
		self._condition_icon = self._health_panel:bitmap({
			name = "condition_icon",
			layer = 4,
			visible = false,
			color = Color.white,
			w = self._health_panel:w(),
			h = self._health_panel:h(),
		})
		self._condition_timer = self._health_panel:text({
			name = "condition_timer",
			visible = false,
			layer = 5,
			color = Color.white,
			w = self._health_panel:w(),
			h = self._health_panel:h(),
			align = "center",
			vertical = "center",
			font_size = self._health_panel:h() * 0.5,
			font = tweak_data.hud_players.timer_font
		})
	end
	
	function HUDTeamPanelBase:set_health(data)
		local radial_health = self._health_panel:child("radial_health")
		local red = data.current / data.total
		if red < radial_health:color().red then
			self:_damage_taken()
		end
		radial_health:set_color(Color(1, red, 1, 1))
		self._health_ratio = red
	end
	
	function HUDTeamPanelBase:set_armor(data)
		local radial_shield = self._health_panel:child("radial_shield")
		local red = data.current / data.total
		if red < radial_shield:color().red then
			self:_damage_taken()
		end
		radial_shield:set_color(Color(1, red, 1, 1))
	end
	
	function HUDTeamPanelBase:_damage_taken()
		local damage_indicator = self._health_panel:child("damage_indicator")
		damage_indicator:stop()
		damage_indicator:animate(callback(self, self, "_animate_damage_taken"))
	end
	
	function HUDTeamPanelBase:set_condition(icon_data, text)
		if icon_data == "mugshot_normal" then
			self._condition_icon:set_visible(false)
		else
			self._condition_icon:set_visible(true)
			local icon, texture_rect = tweak_data.hud_icons:get_icon_data(icon_data)
			self._condition_icon:set_image(icon, texture_rect[1], texture_rect[2], texture_rect[3], texture_rect[4])
		end
	end
	
	function HUDTeamPanelBase:set_custom_radial(data)
		local radial_custom = self._health_panel:child("radial_custom")
		local red = data.current / data.total
		radial_custom:set_color(Color(1, red, 1, 1))
		radial_custom:set_visible(red > 0)
	end
	
	function HUDTeamPanelBase:start_timer(time)
		self._timer_paused = 0
		self._timer = time
		self._condition_timer:set_font_size(self._health_panel:h() * 0.5)
		self._condition_timer:set_color(Color.white)
		self._condition_timer:stop()
		self._condition_timer:set_visible(true)
		self._condition_timer:animate(callback(self, self, "_animate_timer"))
	end
	
	function HUDTeamPanelBase:stop_timer()
		if alive(self._panel) then
			self._condition_timer:set_visible(false)
			self._condition_timer:stop()
		end
	end
	
	function HUDTeamPanelBase:set_pause_timer(pause)
		if not alive(self._panel) then
			return
		end
		--self._condition_timer:set_visible(false)
		self._condition_timer:stop()
	end
	
	function HUDTeamPanelBase:is_timer_running()
		return self._condition_timer:visible()
	end
	
	function HUDTeamPanelBase:_create_callsign_panel(size)
		self._callsign_panel = self._panel:panel({
			name = "callsign_panel",
			w = size,
			h = size,
		})
		
		local callsign = self._callsign_panel:bitmap({
			name = "callsign",
			texture = "guis/textures/pd2/hud_tabs",
			texture_rect = { 84, 34, 19, 19 },
			layer = 1,
			color = Color.white,
			blend_mode = "normal",
			w = self._callsign_panel:w() * 0.35,
			h = self._callsign_panel:h() * 0.35,
		})
		callsign:set_center(self._callsign_panel:w() / 2, self._callsign_panel:h() / 2)
	end
	
	function HUDTeamPanelBase:_create_weapons_panel(height)
		self._weapons_panel = self._panel:panel({
			name = "weapons_panel",
			h = height,
		})
		
		self._weapons_panel:rect({
			name = "bg",
			blend_mode = "normal",
			color = Color.black,
			alpha = 0.25,
			h = self._weapons_panel:h(),
			layer = -1,
		})
		
		for i = 2, 1, -1 do
			local sub_panel = self._weapons_panel:panel({
				name = "weapons_panel_" .. i,
				h = self._weapons_panel:h(),
			})
			
			local icon_panel = sub_panel:panel({
				name = "icon_panel",
				w = sub_panel:h() * 2,
				h = sub_panel:h(),
			})
			
			local icon = icon_panel:bitmap({
				name = "icon",
				blend_mode = "normal",
				w = icon_panel:h() * 2,
				h = icon_panel:h(),
				layer = 1,
			})
			
			local silencer_icon = icon_panel:bitmap({
				name = "silencer_icon",
				texture = "guis/textures/pd2/blackmarket/inv_mod_silencer",
				blend_mode = "normal",
				visible = false,
				w = icon:h() * 0.25,
				h = icon:h() * 0.25,
				layer = icon:layer() + 1,
			})
			silencer_icon:set_bottom(icon:bottom())
			silencer_icon:set_right(icon:right())
			
			local ammo_panel = sub_panel:panel({
				name = "ammo_panel",
				h = sub_panel:h(),
			})
			
			local ammo_clip = ammo_panel:text({
				name = "ammo_clip",
				text = "000",
				color = Color.white,
				blend_mode = "normal",
				layer = 1,
				h = ammo_panel:h() * 0.55,
				vertical = "center",
				align = "right",
				font_size = ammo_panel:h() * 0.55,
				font = tweak_data.hud_players.ammo_font
			})
			ammo_clip:set_top(0)
			
			local ammo_total = ammo_panel:text({
				name = "ammo_total",
				text = "000",
				color = Color.white,
				blend_mode = "normal",
				layer = 1,
				h = ammo_panel:h() * 0.45,
				vertical = "center",
				align = "right",
				font_size = ammo_panel:h() * 0.45,
				font = tweak_data.hud_players.ammo_font
			})
			ammo_total:set_bottom(ammo_panel:h())
			
			local _, _, w, _ = ammo_clip:text_rect()
			self._ammo_panel_default_w = w
			ammo_panel:set_w(w)
			ammo_clip:set_w(w)
			ammo_total:set_w(w)
		end
	end
	
	function HUDTeamPanelBase:_arrange_weapons_panel()
		local BIG_MARGIN = 3
		local SMALL_MARGIN = 1
		local total_w = 0
		
		for i = 2, 1, -1 do
			local sub_panel = self._weapons_panel:child("weapons_panel_" .. i)
			local sub_total_w = 0
			
			for _, pid in ipairs({ "icon_panel", "ammo_panel", "firemode_panel" }) do
				local panel = sub_panel:child(pid)
				if panel then
					panel:set_x(sub_total_w)
					if panel:w() > 0 then
						sub_total_w = sub_total_w + panel:w() + SMALL_MARGIN
					end
				end
			end
			
			sub_total_w = sub_total_w - (sub_total_w > 0 and SMALL_MARGIN or 0)
			
			sub_panel:set_w(sub_total_w)
			sub_panel:set_x(total_w)
			total_w = total_w + sub_total_w + (sub_total_w > 0 and BIG_MARGIN or 0)
		end
		
		total_w = total_w - (total_w > 0 and BIG_MARGIN or 0)
		
		self._weapons_panel:set_w(total_w)
		local bg = self._weapons_panel:child("bg")
		bg:set_w(self._weapons_panel:w())
	end
	
	function HUDTeamPanelBase:set_weapon_id(slot, id, silencer, blueprint)
		local bitmap_texture = HUDManager.get_item_data("weapon", id)

		local panel = self._weapons_panel:child("weapons_panel_" .. slot):child("icon_panel")
		local icon = panel:child("icon")
		local silencer_icon = panel:child("silencer_icon")
		panel:set_visible(true)
		icon:set_image(bitmap_texture)
		silencer_icon:set_visible(silencer)
		
		self._player_data.weapon = self._player_data.weapon or {}
		self._player_data.weapon[slot] = { id, silencer, blueprint or self._weapon_blueprints[slot] }
		managers.hud:update_custom_stats("weapon", self._id, slot, id, silencer, blueprint or self._weapon_blueprints[slot] )
	end
	
	function HUDTeamPanelBase:set_weapon_selected(id)
		self._selected_weapon = id
		
		for i = 2, 1, -1 do
			self._weapons_panel:child("weapons_panel_" .. i):set_alpha((i == id) and 1 or 0.5)
		end
		
		if self._show_selected_weapon_icon_only then
			self:set_show_weapon_icons(self._show_weapon_icons)
		end
	end
	
	function HUDTeamPanelBase:set_ammo_amount_by_type(id, max_clip, current_clip, current_left, max)
		local panel = self._weapons_panel:child("weapons_panel_" .. id):child("ammo_panel")
		local low_ammo = current_left <= math.round(max_clip / 2)
		local low_ammo_clip = current_clip <= math.round(max_clip / 4)
		local out_of_ammo_clip = current_clip <= 0
		local out_of_ammo = current_left <= 0
		local color_total = out_of_ammo and Color(1, 0.9, 0.3, 0.3)
		color_total = color_total or low_ammo and Color(1, 0.9, 0.9, 0.3)
		color_total = color_total or Color.white
		local color_clip = out_of_ammo_clip and Color(1, 0.9, 0.3, 0.3)
		color_clip = color_clip or low_ammo_clip and Color(1, 0.9, 0.9, 0.3)
		color_clip = color_clip or Color.white
		
		local ammo_clip = panel:child("ammo_clip")
		local zero = current_clip < 10 and "00" or current_clip < 100 and "0" or ""
		ammo_clip:set_text(zero .. tostring(current_clip))
		ammo_clip:set_color(color_clip)
		ammo_clip:set_range_color(0, string.len(zero), color_clip:with_alpha(0.5))
		
		local ammo_total = panel:child("ammo_total")
		local zero = current_left < 10 and "00" or current_left < 100 and "0" or ""
		ammo_total:set_text(zero .. tostring(current_left))
		ammo_total:set_color(color_total)
		ammo_total:set_range_color(0, string.len(zero), color_total:with_alpha(0.5))
		
		self._player_data.ammo = self._player_data.ammo or {}
		self._player_data.ammo[id] = { max_clip, current_clip, current_left, max }
		managers.hud:update_custom_stats("ammo", self._id, id, max_clip, current_clip, current_left, max)
	end	
	
	function HUDTeamPanelBase:_create_equipment_panel(height)
		self._equipment_panel = self._panel:panel({
			name = "equipment_panel",
			h = height,
			w = 0,
		})
		
		for i, name in ipairs({ "deployable_equipment_panel", "cable_ties_panel", "throwables_panel" }) do
			local panel = self._equipment_panel:panel({
				name = name,
				h = self._equipment_panel:h() / 3,
				w = self._equipment_panel:h() * 0.6,
				visible = false,
			})
			
			local icon = panel:bitmap({
				name = "icon",
				layer = 1,
				color = Color.white,
				w = panel:h(),
				h = panel:h(),
				layer = 2,
			})
			
			local amount = panel:text({
				name = "amount",
				text = "00",
				font = "fonts/font_medium_mf",
				font_size = panel:h(),
				color = Color.white,
				align = "right",
				vertical = "center",
				layer = 2,
				w = panel:w(),
				h = panel:h()
			})
			
			local bg = panel:rect({
				name = "bg",
				blend_mode = "normal",
				color = Color.black,
				alpha = 0.5,
				h = panel:h(),
				w = panel:w(),
				layer = -1,
			})
			
			panel:set_top((i-1) * panel:h())
		end
	end
	
	function HUDTeamPanelBase:_set_amount_string(text, amount)
		local zero = amount < 10 and "0" or ""
		text:set_text(zero .. amount)
		text:set_range_color(0, string.len(zero), Color.white:with_alpha(0.5))
	end
	
	function HUDTeamPanelBase:_check_equipment_panel_visibility()
		local was_visible = self._equipment_panel:w() > 0
		local visible = false
		for _, child in ipairs(self._equipment_panel:children()) do
			visible = visible or child:visible()
		end
		
		visible = self._show_equipment and visible or false
		
		if was_visible ~= visible then
			self._equipment_panel:set_w(visible and self._equipment_panel:h() * 0.6 or 0)
			self:_arrange_panel()
		end
	end
	
	function HUDTeamPanelBase:set_deployable_equipment(data)
		local icon, texture_rect = tweak_data.hud_icons:get_icon_data(data.icon)
		local deployable_equipment_panel = self._equipment_panel:child("deployable_equipment_panel")
		local deployable_icon = deployable_equipment_panel:child("icon")
		deployable_icon:set_image(icon, unpack(texture_rect))
		self:set_deployable_equipment_amount(1, data)
		
		self._player_data.deployable_icon = { icon, unpack(texture_rect) }
		managers.hud:update_custom_stats("deployable_icon", self._id, unpack(self._player_data.deployable_icon))
	end
	
	function HUDTeamPanelBase:set_deployable_equipment_amount(index, data)
		local deployable_equipment_panel = self._equipment_panel:child("deployable_equipment_panel")
		local deployable_amount = deployable_equipment_panel:child("amount")
		self:_set_amount_string(deployable_amount, data.amount)	
		deployable_equipment_panel:set_visible(data.amount ~= 0)
		self:_check_equipment_panel_visibility()
		
		self._player_data.deployable_amount = data.amount
		managers.hud:update_custom_stats("deployable_amount", self._id, data.amount)
	end
	
	function HUDTeamPanelBase:set_cable_tie(data)
		local icon, texture_rect = tweak_data.hud_icons:get_icon_data(data.icon)
		local cable_ties_panel = self._equipment_panel:child("cable_ties_panel")
		local tie_icon = cable_ties_panel:child("icon")
		tie_icon:set_image(icon, unpack(texture_rect))
		self:set_cable_ties_amount(data.amount)
		
		self._player_data.cable_tie_icon = { icon, unpack(texture_rect) }
		managers.hud:update_custom_stats("cable_tie_icon", self._id, unpack(self._player_data.cable_tie_icon))
	end
	
	function HUDTeamPanelBase:set_cable_ties_amount(amount)
		local cable_ties_panel = self._equipment_panel:child("cable_ties_panel")
		self:_set_amount_string(cable_ties_panel:child("amount"), amount)
		cable_ties_panel:set_visible(amount ~= 0)
		self:_check_equipment_panel_visibility()
		
		self._player_data.cable_tie_amount = amount
		managers.hud:update_custom_stats("cable_tie_amount", self._id, amount)
	end
	
	function HUDTeamPanelBase:set_grenades(data)
		local icon, texture_rect = tweak_data.hud_icons:get_icon_data(data.icon)
		local throwables_panel = self._equipment_panel:child("throwables_panel")
		local grenade_icon = throwables_panel:child("icon")
		grenade_icon:set_image(icon, unpack(texture_rect))
		self:set_grenades_amount(data)
	end
	
	function HUDTeamPanelBase:set_grenades_amount(data)
		local throwables_panel = self._equipment_panel:child("throwables_panel")
		local amount = throwables_panel:child("amount")
		self:_set_amount_string(amount, data.amount)
		throwables_panel:set_visible(data.amount ~= 0)
		self:_check_equipment_panel_visibility()
		
		self._player_data.throwable_amount = data.amount
		managers.hud:update_custom_stats("throwable_amount", self._id, data.amount)
	end
	
	function HUDTeamPanelBase:_create_special_equipment_panel(height)
		self._special_equipment_panel = self._panel:panel({
			name = "special_equipment_panel",
			h = height,
			w = 0,
		})
	end
	
	function HUDTeamPanelBase:add_special_equipment(data)
		local size = self._special_equipment_panel:h() / 3
		
		local equipment_panel = self._special_equipment_panel:panel({
			name = data.id,
			h = size,
			w = size,
		})
		table.insert(self._special_equipment, equipment_panel)
		
		local icon, texture_rect = tweak_data.hud_icons:get_icon_data(data.icon)
		local bitmap = equipment_panel:bitmap({
			name = "bitmap",
			texture = icon,
			color = Color.white,
			layer = 1,
			texture_rect = texture_rect,
			w = equipment_panel:w(),
			h = equipment_panel:h()
		})
		
		local amount, amount_bg
		if data.amount then
			amount = equipment_panel:child("amount") or equipment_panel:text({
				name = "amount",
				text = tostring(data.amount),
				font = "fonts/font_small_noshadow_mf",
				font_size = 12 * equipment_panel:h() / 32,
				color = Color.black,
				align = "center",
				vertical = "center",
				layer = 4,
				w = equipment_panel:w(),
				h = equipment_panel:h()
			})
			amount:set_visible(1 < data.amount)
			amount_bg = equipment_panel:child("amount_bg") or equipment_panel:bitmap({
				name = "amount_bg",
				texture = "guis/textures/pd2/equip_count",
				color = Color.white,
				layer = 3,
			})
			amount_bg:set_size(amount_bg:w() * equipment_panel:w() / 32, amount_bg:h() * equipment_panel:h() / 32)
			amount_bg:set_center(bitmap:center())
			amount_bg:move(amount:w() * 0.2, amount:h() * 0.2)
			amount_bg:set_visible(1 < data.amount)
			amount:set_center(amount_bg:center())
		end
		
		local flash_icon = equipment_panel:bitmap({
			name = "bitmap",
			texture = icon,
			color = tweak_data.hud.prime_color,
			layer = 2,
			texture_rect = texture_rect,
			w = equipment_panel:w() + 2,
			h = equipment_panel:w() + 2
		})
		
		local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
		flash_icon:set_center(bitmap:center())
		flash_icon:animate(hud.flash_icon, nil, equipment_panel)
		self:_layout_special_equipments()
		
		self._player_data.add_special_equipment = self._player_data.add_special_equipment or {}
		self._player_data.add_special_equipment[data.id] = self._player_data.add_special_equipment[data.id] or { data.icon, data.amount }
		managers.hud:update_custom_stats("add_special_equipment", self._id, data.id, data.icon, data.amount)
	end
	
	function HUDTeamPanelBase:remove_special_equipment(equipment)
		for i, panel in ipairs(self._special_equipment) do
			if panel:name() == equipment then
				local data = table.remove(self._special_equipment, i)
				self._special_equipment_panel:remove(panel)
				self:_layout_special_equipments()
				break
			end
		end
		
		if self._player_data.add_special_equipment then
			self._player_data.add_special_equipment[equipment] = nil
		end
		managers.hud:update_custom_stats("remove_special_equipment", self._id, equipment)
	end
	
	function HUDTeamPanelBase:set_special_equipment_amount(equipment_id, amount)
		for i, panel in ipairs(self._special_equipment) do
			if panel:name() == equipment_id then
				panel:child("amount"):set_text(tostring(amount))
				panel:child("amount"):set_visible(amount > 1)
				panel:child("amount_bg"):set_visible(amount > 1)
				break
			end
		end
		
		if self._player_data.add_special_equipment then
			self._player_data.add_special_equipment[equipment_id][2] = amount
		end
		managers.hud:update_custom_stats("special_equipment_amount", self._id, equipment_id, amount)
	end
	
	function HUDTeamPanelBase:clear_special_equipment()
		while self._special_equipment[1] do
			self._special_equipment_panel:remove(table.remove(self._special_equipment, 1))
		end
		
		self._player_data.add_special_equipment = nil
		managers.hud:update_custom_stats("clear_special_equipment", self._id)
	end
	
	function HUDTeamPanelBase:_layout_special_equipments()
		local panel_w = 0
	
		if #self._special_equipment > 0 then
			local h = self._special_equipment[1]:h()
			local w = self._special_equipment[1]:w()
			local items_per_column = math.floor(self._special_equipment_panel:h() / h)
			
			for i, panel in ipairs(self._special_equipment) do
				local column = math.floor((i-1) / items_per_column)
				panel:set_left(0 + column * w)
				panel:set_top(0 + (i - 1 - column * items_per_column) * h)
			end
			
			panel_w = math.ceil(#self._special_equipment / items_per_column) * w
		end
		
		self._special_equipment_panel:set_w(self._show_special_equipment and panel_w or 0)
		self:_arrange_panel()
	end
	
	function HUDTeamPanelBase:_create_carry_panel(height)
		self._carry_panel = self._panel:panel({
			name = "carry_panel",
			visible = false,
			h = height,
			w = 0,
		})
		
		local icon = self._carry_panel:bitmap({
			name = "icon",
			visible = false,	--Shows otherwise for some reason...
			texture = "guis/textures/pd2/hud_tabs",
			texture_rect = { 32, 33, 32, 31 },
			w = self._carry_panel:h(),
			h = self._carry_panel:h(),
			layer = 1,
			color = Color.white,
		})
		
		local text = self._carry_panel:text({
			name = "text",
			layer = 1,
			color = Color.white,
			--w = self._carry_panel:w(),
			h = self._carry_panel:h(),
			vertical = "center",
			align = "center",
			font_size = self._carry_panel:h(),
			font = tweak_data.hud.medium_font_noshadow,
		})
		
		self:remove_carry_info()
	end
	
	function HUDTeamPanelBase:set_carry_info(carry_id, value)
		self._current_carry = carry_id
		
		local name_id = carry_id and tweak_data.carry[carry_id] and tweak_data.carry[carry_id].name_id
		local carry_text = utf8.to_upper(name_id and managers.localization:text(name_id) or "UNKNOWN")
		local text = self._carry_panel:child("text")
		local icon = self._carry_panel:child("icon")
		
		text:set_text(carry_text)
		local _, _, w, _ = text:text_rect()
		text:set_w(w)
		icon:set_visible(true)
		
		self._carry_panel:set_visible(true)
		self._carry_panel:animate(callback(self, self, "_animate_carry_pickup"))
	end
	
	function HUDTeamPanelBase:remove_carry_info()
		self._current_carry = nil
		self._carry_panel:stop()
		self._carry_panel:set_w(0)
		self._carry_panel:set_visible(false)
		self._carry_panel:child("icon"):set_visible(false)
		self._carry_panel:child("text"):set_text("")
	end
	
	function HUDTeamPanelBase:add_panel()
		self._panel:show()
	end
	
	function HUDTeamPanelBase:remove_panel()
		self._panel:hide()
		
		self:clear_special_equipment()
		self:set_condition("mugshot_normal")
		self:set_cheater(false)
		self:stop_timer()
		self:set_peer_id(nil)
		self:set_ai(nil)
		self:remove_carry_info()
	end
	
	function HUDTeamPanelBase:set_callsign(id)
		self._callsign_panel:child("callsign"):set_color(tweak_data.chat_colors[id]:with_alpha(1))
		
		self._player_data.callsign = id
		managers.hud:update_custom_stats("callsign", self._id, id)
	end
	
	function HUDTeamPanelBase:set_name(teammate_name)
		self._name = teammate_name
		
		self._player_data.name  = self._name
		managers.hud:update_custom_stats("name", self._id, teammate_name)
	end
	
	function HUDTeamPanelBase:set_voice_com(status)
		self._voice_com = status
		
		if status and not self._animating_voice_com then
			self._callsign_panel:child("callsign"):animate(callback(self, self, "_animate_voice_com"))
		end
	end
	
	function HUDTeamPanelBase:set_peer_id(peer_id)
		self._peer_id = peer_id
		
		local peer = managers.network:session() and managers.network:session():peer(peer_id)
		if peer then
			self:_set_rank(peer:level(), peer:rank())
		end
		
		self:recheck_outfit_string()
		
		self._player_data.peer_id = peer_id
		managers.hud:update_custom_stats("ai", self._id, peer_id)
	end
	
	function HUDTeamPanelBase:_parse_outfit_string(outfit)
		self._weapon_blueprints = {}
		for selection, data in ipairs({ outfit.secondary, outfit.primary }) do
			local weapon_id = managers.weapon_factory:get_weapon_id_by_factory_id(data.factory_id)
			local silencer = managers.weapon_factory:has_perk("silencer", data.factory_id, data.blueprint)
			self:set_weapon_id(selection, weapon_id, silencer, data.blueprint)
			self._weapon_blueprints[selection] = data.blueprint
		end
		
		self:_set_armor(outfit.armor)
		self:_set_melee(outfit.melee_weapon)
		--self:_set_deployable_id(outfit.deployable)
		self:_set_throwable(outfit.grenade)
		self:_set_skills(table.map_copy(outfit.skills.skills))
		self:_set_specialization(table.map_copy(outfit.skills.specializations))
	end
	
	function HUDTeamPanelBase:set_ai(ai)
		self._ai = ai
		
		local visible = not ai and true or false
		self._weapons_panel:set_visible(visible)
		self._equipment_panel:set_visible(visible)
		self._special_equipment_panel:set_visible(visible)
		self._callsign_panel:set_visible(visible)
		
		self._player_data.ai = ai and true or false
		managers.hud:update_custom_stats("ai", self._id, self._player_data.ai)
	end
	
	function HUDTeamPanelBase:_set_armor(id)
		self._player_data.armor = id
		managers.hud:update_custom_stats("armor", self._id, id)
	end
	
	function HUDTeamPanelBase:_set_melee(id)
		self._player_data.melee = id
		managers.hud:update_custom_stats("melee", self._id, id)
	end
	
	function HUDTeamPanelBase:_set_deployable_id(id)
		--TODO
	end
	
	function HUDTeamPanelBase:_set_throwable(id)
		self._player_data.throwable = id
		managers.hud:update_custom_stats("throwable", self._id, id)
	end
	
	function HUDTeamPanelBase:_set_skills(data)
		
	end
	
	function HUDTeamPanelBase:_set_specialization(data)
		
	end
	
	function HUDTeamPanelBase:_set_rank(level, infamy)
		self._player_data.level = { level, infamy }
		managers.hud:update_custom_stats("rank", self._id, level, infamy)
	end
	
	function HUDTeamPanelBase:_animate_damage_taken(damage_indicator)
		damage_indicator:set_alpha(1)
		local st = 3
		local t = st
		local st_red_t = 0.5
		local red_t = st_red_t
		while t > 0 do
			local dt = coroutine.yield()
			t = t - dt
			red_t = math.clamp(red_t - dt, 0, 1)
			damage_indicator:set_color(Color(1, red_t / st_red_t, red_t / st_red_t))
			damage_indicator:set_alpha(t / st)
		end
		damage_indicator:set_alpha(0)
	end
	
	function HUDTeamPanelBase:_animate_voice_com(callsign)
		self._animating_voice_com = true
		
		local w, h = callsign:size()
		local x, y = callsign:center()
		callsign:set_image("guis/textures/pd2/jukebox_playing", unpack({ 0, 0, 16, 16 }))
		
		while self._voice_com do
			local T = 2
			local t = 0
			
			while t < T do
				local r = (math.sin(t * 360)) * 0.15
				callsign:set_size(w + w * r, h + h * r)
				callsign:set_center(x, y)
				t = t + coroutine.yield()
			end
		end
		
		callsign:set_image("guis/textures/pd2/hud_tabs", unpack({ 84, 34, 19, 19 }))
		callsign:set_size(w, h)
		callsign:set_center(x, y)
		
		self._animating_voice_com = false
	end
	
	function HUDTeamPanelBase:_animate_timer()
		local rounded_timer = math.round(self._timer)
		while self._timer >= 0 do
			local dt = coroutine.yield()
			if self._timer_paused == 0 then
				self._timer = self._timer - dt
				local text = self._timer < 0 and "00" or (math.round(self._timer) < 10 and "0" or "") .. math.round(self._timer)
				self._condition_timer:set_text(text)
				if rounded_timer > math.round(self._timer) then
					rounded_timer = math.round(self._timer)
					if rounded_timer < 11 then
						self._condition_timer:animate(callback(self, self, "_animate_timer_flash"))
					end
				end
			end
		end
	end
	
	function HUDTeamPanelBase:_animate_timer_flash()
		local t = 0
		while t < 0.5 do
			t = t + coroutine.yield()
			local n = 1 - math.sin(t * 180)
			local r = math.lerp(1 or self._point_of_no_return_color.r, 1, n)
			local g = math.lerp(0 or self._point_of_no_return_color.g, 0.8, n)
			local b = math.lerp(0 or self._point_of_no_return_color.b, 0.2, n)
			self._condition_timer:set_color(Color(r, g, b))
			self._condition_timer:set_font_size(math.lerp(self._health_panel:h() * 0.5, self._health_panel:h() * 0.8, n))
		end
		self._condition_timer:set_font_size(self._health_panel:h() * 0.5)
	end
	
	function HUDTeamPanelBase:_animate_carry_pickup(carry_panel)
		local DURATION = 2
		local text = self._carry_panel:child("text")
		local icon = self._carry_panel:child("icon")
		
		local t = DURATION
		while t > 0 do
			local dt = coroutine.yield()
			t = math.max(t-dt, 0)
			
			local r = math.sin(720 * t) * 0.5 + 0.5
			text:set_color(Color(1, 1, 1, r))
			icon:set_color(Color(1, 1, 1, r))
		end
		
		text:set_color(Color(1, 1, 1, 1))
		icon:set_color(Color(1, 1, 1, 1))
	end
	
	function HUDTeamPanelBase:get_player_data()
		return self._player_data
	end
	
	
	
	HUDPlayerPanel.WIDTH = 500
	HUDPlayerPanel.HEIGHT = 75
	HUDPlayerPanel.SUB_PANEL_HORIZONTAL_MARGIN = 3
	
	function HUDPlayerPanel:init(...)
		HUDPlayerPanel.super.init(self, self.WIDTH, self.HEIGHT, self.SCALE, ...)
		
		self:_create_stamina_panel(self._health_panel:h() * 0.3, self._health_panel:h())
		
		self:set_show_fire_mode(HUDPlayerPanel.SHOW_FIRE_MODE)
		
		self:_arrange_panel()
		
		self._panel:set_bottom(self._parent:h())
		self._panel:set_center_x(self._parent:w() / 2)
		
		self:recheck_outfit_string()
		self:_set_rank(managers.experience:current_level(), managers.experience:current_rank())
	end
	
	function HUDPlayerPanel:_create_health_panel(...)
		HUDPlayerPanel.super._create_health_panel(self, ...)
		
		local radial_stored_health = self._health_panel:bitmap({
			name = "radial_stored_health",
			texture = "guis/textures/pd2/hud_health",
			texture_rect = { 64, 0, -64, 64 },
			render_template = "VertexColorTexturedRadial",
			blend_mode = "add",
			color = Color(0, 0, 0),
			alpha = 0.5,
			w = self._health_panel:w(),
			h = self._health_panel:h(),
			layer = 3,
		})
	end
	
	function HUDPlayerPanel:set_show_fire_mode(status)
		for i = 2, 1, -1 do
			self._weapons_panel:child("weapons_panel_" .. i):child("firemode_panel"):set_w(status and self._firemode_panel_default_w or 0)
		end
		
		self:_arrange_weapons_panel()
		self:_arrange_panel()
	end
	
	function HUDPlayerPanel:set_show_stamina(status)
		self._stamina_panel:set_w(status and self._stamina_default_w or 0)
		self:_arrange_panel()
	end
	
	function HUDPlayerPanel:effective_height()
		local h = 0
		
		for _, panel in ipairs({ self._health_panel, self._stamina_panel, self._weapons_panel, self._equipment_panel, self._special_equipment_panel }) do
			if panel:h() > 0 then
				h = math.max(h, panel:h())
			end
		end
		
		return h + (self._carry_panel:visible() and self._carry_panel:h() or 0)
	end
	
	function HUDPlayerPanel:effective_width()
		local w = 0
		
		for _, panel in ipairs({ self._health_panel, self._stamina_panel, self._weapons_panel, self._equipment_panel, self._special_equipment_panel }) do
			if panel:w() > 0 then
				w = w + panel:w() + self.SUB_PANEL_HORIZONTAL_MARGIN
			end
		end
		
		return math.max(self._carry_panel:w(), w)
	end
	
	function HUDPlayerPanel:_arrange_panel()
		HUDPlayerPanel.super._arrange_panel(self)
		
		local panels = { self._health_panel, self._stamina_panel, self._weapons_panel, self._equipment_panel, self._special_equipment_panel }
	
		local total_w = 0
		for _, panel in ipairs(panels) do
			if panel:w() > 0 then
				total_w = total_w + panel:w() + self.SUB_PANEL_HORIZONTAL_MARGIN
			end
		end
		
		local x = (self._panel:w() - total_w) / 2
		for _, panel in ipairs(panels) do
			panel:set_bottom(self._panel:h())
			panel:set_x(x)
			if panel:w() > 0 then
				x = x + panel:w() + self.SUB_PANEL_HORIZONTAL_MARGIN
			end
		end
		
		self._callsign_panel:set_center(self._health_panel:center())
		self._carry_panel:set_left(self._health_panel:left())
		self._carry_panel:set_bottom(self._health_panel:top())
	end
	
	function HUDPlayerPanel:_create_stamina_panel(width, height)
		self._stamina_default_w = width
		self._stamina_panel = self._panel:panel({
			name = "stamina_panel",
			w = width,
			h = height,
		})
		
		local stamina_bar_outline = self._stamina_panel:bitmap({
			name = "stamina_bar_outline",
			texture = "guis/textures/hud_icons",
			texture_rect = { 252, 240, 12, 48 },
			color = Color.white,
			w = width,
			h = height,
			layer = 10,
		})
		self._stamina_bar_max_h = stamina_bar_outline:h() * 0.96
		self._default_stamina_color = Color(0.7, 0.8, 1.0)
		
		local stamina_bar = self._stamina_panel:rect({
			name = "stamina_bar",
			blend_mode = "normal",
			color = self._default_stamina_color,
			alpha = 0.75,
			h = self._stamina_bar_max_h,
			w = stamina_bar_outline:w() * 0.9,
			layer = 5,
		})
		stamina_bar:set_center(stamina_bar_outline:center())
		
		local bar_bg = self._stamina_panel:gradient({
			layer = 1,
			gradient_points = { 0, Color.white:with_alpha(0.10), 1, Color.white:with_alpha(0.40) },
			h = stamina_bar:h(),
			w = stamina_bar:w(),
			blend_mode = "sub",
			orientation = "vertical",
			layer = 10,
		})
		bar_bg:set_center(stamina_bar:center())
		
		local stamina_threshold = self._stamina_panel:rect({
			name = "stamina_threshold",
			color = Color.red,
			w = stamina_bar:w(),
			h = 2,
			layer = 8,
		})
		stamina_threshold:set_center(stamina_bar:center())
	end
	
	function HUDPlayerPanel:set_max_stamina(value)
		if value ~= self._max_stamina then
			self._max_stamina = value
			local stamina_bar = self._stamina_panel:child("stamina_bar")
			
			local offset = stamina_bar:h() * (tweak_data.player.movement_state.stamina.MIN_STAMINA_THRESHOLD / self._max_stamina)
			self._stamina_panel:child("stamina_threshold"):set_bottom(stamina_bar:bottom() - offset + 1)
		end
	end
	
	function HUDPlayerPanel:set_current_stamina(value)
		local stamina_bar = self._stamina_panel:child("stamina_bar")
		local stamina_bar_outline = self._stamina_panel:child("stamina_bar_outline")
		
		stamina_bar:set_h(self._stamina_bar_max_h * (value / self._max_stamina))
		stamina_bar:set_bottom(0.5 * (stamina_bar_outline:h() + self._stamina_bar_max_h))
		if value <= tweak_data.player.movement_state.stamina.MIN_STAMINA_THRESHOLD and not self._animating_low_stamina then
			self._animating_low_stamina = true
			stamina_bar:animate(callback(self, self, "_animate_low_stamina"), stamina_bar_outline)
		elseif value > tweak_data.player.movement_state.stamina.MIN_STAMINA_THRESHOLD and self._animating_low_stamina then
			self._animating_low_stamina = nil
		end
	end
	
	function HUDPlayerPanel:_create_weapons_panel(...)
		HUDPlayerPanel.super._create_weapons_panel(self, ...)
		
		for i = 2, 1, -1 do
			local sub_panel = self._weapons_panel:child("weapons_panel_" .. i)
			
			self._firemode_panel_default_w = sub_panel:h() * 0.4
			local firemode_panel = sub_panel:panel({
				name = "firemode_panel",
				layer = 1,
				w = self._firemode_panel_default_w,
				h = sub_panel:h(),
			})
				
			local fire_modes = {
				{ name = "auto_fire", abbrev = "A" },
				{ name = "single_fire", abbrev = "S" },
			}
			if HUDManager._USE_BURST_MODE then
				table.insert(fire_modes, 2, { name = "burst_fire", abbrev = "B" })
			end
				
			local bg = firemode_panel:rect({
				name = "bg",
				blend_mode = "normal",
				color = Color.white,
				h = firemode_panel:h() * math.clamp(#fire_modes * 0.25, 0.25, 1),
				w = firemode_panel:w() * 0.65,
				layer = 1,
			})
			bg:set_center(firemode_panel:w() / 2, firemode_panel:h() / 2)

			for i, data in ipairs(fire_modes) do
				local text = firemode_panel:text({
					name = data.name,
					text = data.abbrev,
					color = Color.black,
					blend_mode = "normal",
					layer = 10,
					alpha = 0.75,
					w = bg:w(),
					h = bg:h() / #fire_modes,
					vertical = "center",
					align = "center",
					font_size = bg:h() / #fire_modes,
					font = tweak_data.hud_players.ammo_font
				})
				text:set_center(bg:center())
				text:set_bottom(bg:bottom() - text:h() * (i-1))
			end
		end
		
		self:recreate_weapon_firemode()
		self:_arrange_weapons_panel()
	end
	
	function HUDPlayerPanel:recreate_weapon_firemode()
		for i = 2, 1, -1 do
			local weapon = (i == 2) and managers.blackmarket:equipped_primary() or managers.blackmarket:equipped_secondary()
			local panel = self._weapons_panel:child("weapons_panel_" .. i)
			local weapon_tweak_data = tweak_data.weapon[weapon.weapon_id]
			local fire_mode = weapon_tweak_data.FIRE_MODE
			local can_toggle_firemode = weapon_tweak_data.CAN_TOGGLE_FIREMODE
			local locked_to_auto = managers.weapon_factory:has_perk("fire_mode_auto", weapon.factory_id, weapon.blueprint)
			local locked_to_single = managers.weapon_factory:has_perk("fire_mode_single", weapon.factory_id, weapon.blueprint)

			local firemode_panel = panel:child("firemode_panel")
			local has_single = (fire_mode == "single" or can_toggle_firemode) and not locked_to_auto and true or false
			firemode_panel:child("single_fire"):set_color(has_single and Color.black or Color(0.6, 0.1, 0.1))
			local has_auto = (fire_mode == "auto" or can_toggle_firemode) and not locked_to_single and true or false
			firemode_panel:child("auto_fire"):set_color(has_auto and Color.black or Color(0.6, 0.1, 0.1))
			
			local burst_fire = firemode_panel:child("burst_fire")
			if burst_fire then
				local has_burst = (weapon_tweak_data.BURST_FIRE or can_toggle_firemode) and not (locked_to_single or locked_to_auto) and (weapon_tweak_data.BURST_FIRE ~= false)
				burst_fire:set_color(has_burst and Color.black or Color(0.6, 0.1, 0.1))
			end
			
			local default = locked_to_auto and "auto" or locked_to_single and "single" or fire_mode
			self:set_weapon_firemode(i, default)
		end
	end
	
	function HUDPlayerPanel:set_weapon_id(slot, ...)
		HUDPlayerPanel.super.set_weapon_id(self, slot, ...)
		
		if alive(managers.player:player_unit()) then
			local burst_fire = self._weapons_panel:child("weapons_panel_" .. slot):child("firemode_panel"):child("burst_fire")
			local weapon = managers.player:player_unit():inventory():unit_by_selection(slot)
			
			if burst_fire and alive(weapon) then
				local has_burst = weapon:base().can_use_burst_mode and weapon:base():can_use_burst_mode() or false
				burst_fire:set_color(has_burst and Color.black or Color(0.6, 0.1, 0.1))
			end
		end
	end
	
	function HUDPlayerPanel:set_weapon_firemode(id, firemode)
		local panel = self._weapons_panel:child("weapons_panel_" .. id)
		local firemode_panel = panel:child("firemode_panel")
		local single_fire = firemode_panel:child("single_fire")
		local auto_fire = firemode_panel:child("auto_fire")
		local burst_fire = firemode_panel:child("burst_fire")
		
		local active_alpha = 1
		local inactive_alpha = 0.65
		
		if firemode == "single" then
			single_fire:set_alpha(active_alpha)
			single_fire:set_text("[S]")
			auto_fire:set_alpha(inactive_alpha)
			auto_fire:set_text("A")
			if burst_fire then
				burst_fire:set_text("B")
				burst_fire:set_alpha(inactive_alpha)
			end
		elseif firemode == "auto" then
			auto_fire:set_alpha(active_alpha)
			auto_fire:set_text("[A]")
			single_fire:set_alpha(inactive_alpha)
			single_fire:set_text("S")
			if burst_fire then
				burst_fire:set_text("B")
				burst_fire:set_alpha(inactive_alpha)
			end
		elseif firemode == "burst" then
			burst_fire:set_alpha(active_alpha)
			burst_fire:set_text("[B]")
			auto_fire:set_alpha(inactive_alpha)
			auto_fire:set_text("A")
			single_fire:set_alpha(inactive_alpha)
			single_fire:set_text("S")
		end
	end
	
	function HUDPlayerPanel:set_weapon_firemode_burst(id)
		self:set_weapon_firemode(id, "burst")
	end
	
	function HUDPlayerPanel:_create_carry_panel()
		HUDPlayerPanel.super._create_carry_panel(self, self._panel:h() - self._health_panel:h())
	end
	
	function HUDPlayerPanel:set_carry_info(...)
		HUDPlayerPanel.super.set_carry_info(self, ...)
		
		local text = self._carry_panel:child("text")
		local icon = self._carry_panel:child("icon")
		icon:set_left(0)
		text:set_left(icon:right() + 2)
		self._carry_panel:set_w(self._show_carry_info and (text:w() + icon:w() + 2) or 0)
		self._carry_panel:set_center_x(self._panel:w() / 2)
		
		--self:_arrange_panel()
	end
	
	function HUDPlayerPanel:teammate_progress(...)
		--Why does this happen?
	end
	
	function HUDPlayerPanel:set_cheater(state)
	
	end
	
	function HUDPlayerPanel:add_panel(...)
		if not HUDPlayerPanel.DEBUG_HIDE then
			HUDPlayerPanel.super.add_panel(self, ...)
		end
	end
	
	function HUDPlayerPanel:remove_panel()
		HUDPlayerPanel.super.remove_panel(self)
		
		self._stamina_panel:child("stamina_bar"):stop()
	end
	
	function HUDPlayerPanel:recheck_outfit_string()
		self:_parse_outfit_string(managers.blackmarket:unpack_outfit_from_string(managers.blackmarket:outfit_string()))
	end
	
	function HUDPlayerPanel:_animate_low_stamina(stamina_bar, stamina_bar_outline)
		local target = Color(1.0, 0.1, 0.1)
		local bar = self._default_stamina_color
		local border = Color.white
	
		while self._animating_low_stamina do
			local t = 0
			while t <= 0.5 do
				t = t + coroutine.yield()
				local ratio = 0.5 + 0.5 * math.sin(t * 720)
				stamina_bar:set_color(Color(
					bar.r + (target.r - bar.r) * ratio, 
					bar.g + (target.g - bar.g) * ratio, 
					bar.b + (target.b - bar.b) * ratio))
				stamina_bar_outline:set_color(Color(
					border.r + (target.r - border.r) * ratio, 
					border.g + (target.g - border.g) * ratio, 
					border.b + (target.b - border.b) * ratio))
			end
		end
		
		stamina_bar:set_color(bar)
		stamina_bar_outline:set_color(border)
	end
	
	function HUDPlayerPanel:increment_kill_count(unit, weapon_type, weapon_slot)
		local unit_id = unit:base()._tweak_table
		local unit_type = managers.groupai:state():is_enemy_special(unit) and "special" or "normal"
		
		local weapon_table = self._player_data.kill_count.by_weapon[weapon_type]
		weapon_table = weapon_slot and weapon_table[weapon_slot] or weapon_table
		weapon_table[unit_type] = (weapon_table[unit_type] or 0) + 1
		self._player_data.kill_count.total[unit_type] = (self._player_data.kill_count.total[unit_type] or 0) + 1
		self._player_data.kill_count.by_unit[unit_id] = (self._player_data.kill_count.by_unit[unit_id] or 0) + 1
		
		managers.hud:update_custom_stats("kill_count_by_weapon", self._id, weapon_table.normal, weapon_table.special, weapon_type, weapon_slot)
		managers.hud:update_custom_stats("kill_count_by_unit", self._id, unit_id, self._player_data.kill_count.by_unit[unit_id])
		managers.hud:update_custom_stats("kill_count_total", self._id, self._player_data.kill_count.total.normal, self._player_data.kill_count.total.special)
	end
	
	function HUDPlayerPanel:set_accuracy(slot, weapon_value, total_value)
		self._player_data.accuracy[slot] = weapon_value
		self._player_data.accuracy.total = total_value
		managers.hud:update_custom_stats("accuracy", self._id, slot, weapon_value, total_value)
	end
	
	function HUDPlayerPanel:set_stored_health(stored_health)
		local radial = self._health_panel:child("radial_stored_health")
		local ratio = stored_health or self._stored_health or 0
		self._stored_health = ratio
		radial:set_color(Color(math.min(ratio, self._stored_health_max), 0, 0))
	end
	
	function HUDPlayerPanel:set_stored_health_max(stored_health_max)
		self._stored_health_max = stored_health_max
		self:set_stored_health()
	end
	
	function HUDPlayerPanel:set_health(data)
		HUDPlayerPanel.super.set_health(self, data)		
		local ratio = data.current / data.total
		local stored_health = self._health_panel:child("radial_stored_health")
		stored_health:set_rotation(-ratio * 360)
		self:set_stored_health_max(1-ratio)
	end
	
	HUDTeammatePanel.WIDTH = 400
	HUDTeammatePanel.HEIGHT = 65
	HUDTeammatePanel.SUB_PANEL_HORIZONTAL_MARGIN = 2
	
	HUDTeammatePanel._INTERACTION_TEXTS = {
		big_computer_server = "USING COMPUTER",
	--[[
		ammo_bag = "Using ammo bag",
		c4_bag = "Taking C4",
		c4_mission_door = "Planting C4 (equipment)",
		c4_x1_bag = "Taking C4",
		connect_hose = "Connecting hose",
		crate_loot = "Opening crate",
		crate_loot_close = "Closing crate",
		crate_loot_crowbar = "Opening crate",
		cut_fence = "Cutting fence",
		doctor_bag = "Using doctor bag",
		drill = "Placing drill",
		drill_jammed = "Repairing drill",
		drill_upgrade = "Upgrading drill",
		ecm_jammer = "Placing ECM jammer",
		first_aid_kit = "Using first aid kit",
		free = "Uncuffing",
		grenade_briefcase = "Taking grenade",
		grenade_crate = "Opening grenade case",
		hack_suburbia_jammed = "Resuming hack",
		hold_approve_req = "Approving request",
		hold_close = "Closing door",
		hold_close_keycard = "Closing door (keycard)",
		hold_download_keys = "Starting hack",
		hold_hack_comp = "Starting hack",
		hold_open = "Opening door",
		hold_open_bomb_case = "Opening bomb case",
		hold_pku_disassemble_cro_loot = "Disassembling bomb",
		hold_remove_armor_plating = "Removing plating",
		hold_remove_ladder = "Taking ladder",
		hold_take_server_axis = "Taking server",
		hostage_convert = "Converting enemy",
		hostage_move = "Moving hostage",
		hostage_stay = "Moving hostage",
		hostage_trade = "Trading hostage",
		intimidate = "Cable tying civilian",
		open_train_cargo_door = "Opening door",
		pick_lock_easy_no_skill = "Picking lock",
		requires_cable_ties = "Cable tying civilian",
		revive = "Reviving",
		sentry_gun_refill = "Refilling sentry gun",
		shaped_charge_single = "Planting C4 (deployable)",
		shaped_sharge = "Planting C4 (deployable)",
		shape_charge_plantable = "Planting C4 (equipment)",
		shape_charge_plantable_c4_1 = "Planting C4 (equipment)",
		shape_charge_plantable_c4_x1 = "Planting C4 (equipment)",
		trip_mine = "Placing trip mine",
		uload_database_jammed = "Resuming hack",
		use_ticket = "Using ticket",
		votingmachine2 = "Starting hack",
		votingmachine2_jammed = "Resuming hack",
		methlab_caustic_cooler = "Cooking meth (caustic soda)",
		methlab_gas_to_salt = "Cooking meth (hydrogen chloride)",
		methlab_bubbling = "Cooking meth (muriatic acid)",
		money_briefcase = "Opening briefcase",
		pku_barcode_downtown = "Taking barcode (downtown)",
		pku_barcode_edgewater = "Taking barcode (?)",	--TODO: Location
		gage_assignment = "Taking courier package",
		stash_planks = "Boarding window",
		stash_planks_pickup = "Taking planks",
		taking_meth = "Bagging loot",
		hlm_connect_equip = "Connecting cable",
	]]
	}
	
	function HUDTeammatePanel:init(...)
		HUDTeammatePanel.super.init(self, self.WIDTH, self.HEIGHT, self.SCALE, ...)
		
		local name_height = self._panel:h() - self._health_panel:h()
		self:_create_name_panel(math.max(self:effective_width(), name_height * 4), name_height)
		self:_create_interact_panel(self._health_panel:h())
		
		self:set_show_name(self.SHOW_NAME)
		
		self:_arrange_panel()

		--self._panel:set_bottom(self._parent:h() - (self._id - (self._id > 4 and 2 or 1)) * self._panel:h())
		--self._panel:set_x(0)
	end
	
	function HUDTeammatePanel:set_show_name(status)
		self._show_name = status
		self._name_panel:set_h(status and self._default_name_height or 0)
		managers.hud:restack_team_panels()
	end
	
	function HUDTeammatePanel:effective_height()
		local h = 0
		for _, panel in ipairs({ self._health_panel, self._weapons_panel, self._equipment_panel, self._special_equipment_panel, self._carry_panel }) do
			if panel then
				h = math.max(panel:h(), h)
			end
		end
		
		return h + (self._name_panel and self._name_panel:h() or 0)
	end
	
	function HUDTeammatePanel:effective_width()
		local w = 0
		for _, panel in ipairs({ self._health_panel, self._weapons_panel, self._equipment_panel, self._special_equipment_panel, self._carry_panel }) do
			if panel then
				w = w + panel:w()
			end
		end
		
		return math.max(w, self._name_panel and self._name_panel:w() or 0)
	end
	
	function HUDTeammatePanel:_arrange_panel()
		HUDTeammatePanel.super._arrange_panel(self)
	
		local x = 0
		local panels = { self._health_panel, self._weapons_panel, self._equipment_panel, self._special_equipment_panel, self._carry_panel }
		for _, panel in ipairs(panels) do
			if panel then
				panel:set_bottom(self._panel:h())
				panel:set_x(x)
				if panel:w() > 0 then
					x = x + panel:w() + self.SUB_PANEL_HORIZONTAL_MARGIN
				end
			end
		end
		
		if self._name_panel then
			self._name_panel:set_bottom(self._health_panel:top())
			self._name_panel:set_x(0)
		end
		if self._carry_panel then
			self._carry_panel:set_center_y(self._panel:h() / 2)
		end
		if self._interact_panel then
			self._interact_panel:set_left(self._health_panel:right())
		end
	end
	
	function HUDTeammatePanel:_create_name_panel(width, height)
		self._default_name_height = height
		self._name_panel = self._panel:panel({
			name = "name_panel",
			w = width,
			h = height,
		})		
		
		local text = self._name_panel:text({
			name = "name",
			text = tostring(self._id),
			layer = 1,
			color = Color.white,
			--align = "left",
			align = "center",
			vertical = "center",
			w = self._name_panel:w(),
			h = self._name_panel:h(),
			font_size = self._name_panel:h(),
			font = tweak_data.hud_players.name_font
		})
	end
	
	function HUDTeammatePanel:_create_weapons_panel(...)
		HUDTeammatePanel.super._create_weapons_panel(self, ...)
		self:_arrange_weapons_panel()
	end
	
	function HUDTeammatePanel:_create_carry_panel()
		HUDTeammatePanel.super._create_carry_panel(self, self._panel:h() / 2)
		
		local text = self._carry_panel:child("text")
		local icon = self._carry_panel:child("icon")
		
		icon:set_w(self._carry_panel:h() / 2)
		icon:set_h(icon:w())
		text:set_h(self._carry_panel:h() / 2)
		text:set_font_size(text:h())
	end
	
	function HUDTeammatePanel:set_carry_info(...)
		HUDTeammatePanel.super.set_carry_info(self, ...)
		
		local text = self._carry_panel:child("text")
		local icon = self._carry_panel:child("icon")
		
		self._carry_panel:set_w(self._show_carry_info and math.max(text:w(), icon:w()) or 0)
		self._carry_panel:set_center_y(self._panel:h() / 2)
		icon:set_bottom((icon:h() + text:h()) / 2)
		icon:set_center_x(self._carry_panel:w() / 2)
		text:set_top(self._carry_panel:h() - (icon:h() + text:h()) / 2)
		text:set_center_x(self._carry_panel:w() / 2)
		
		self:_arrange_panel()
	end
	
	function HUDTeammatePanel:_create_interact_panel(height)
		self._interact_panel = self._panel:panel({
			name = "interact_panel",
			layer = 0,
			visible = false,
			alpha = 0,
			w = 0,
			h = height,
		})
		self._interact_panel:set_bottom(self._panel:h())
		
		self._interact_panel:rect({
			name = "bg",
			blend_mode = "normal",
			color = Color.black,
			alpha = 0.25,
			h = self._interact_panel:h(),
			w = self._interact_panel:w(),
			layer = -1,
		})

		local interact_text = self._interact_panel:text({
			name = "interact_text",
			layer = 10,
			color = Color.white,
			w = self._interact_panel:w(),
			h = self._interact_panel:h() * 0.5,
			vertical = "center",
			align = "center",
			blend_mode = "normal",
			font_size = self._interact_panel:h() * 0.3,
			font = tweak_data.hud_players.name_font
		})
		interact_text:set_top(0)
		
		local interact_bar_outline = self._interact_panel:bitmap({
			name = "outline",
			texture = "guis/textures/hud_icons",
			texture_rect = { 252, 240, 12, 48 },
			w = self._interact_panel:h() * 0.5,
			h = self._interact_panel:w() * 0.75,
			layer = 10,
			rotation = 90
		})
		
		self._interact_bar_max_width = interact_bar_outline:h() * 0.97

		local interact_bar = self._interact_panel:gradient({
			name = "interact_bar",
			blend_mode = "normal",
			alpha = 0.75,
			layer = 5,
			h = interact_bar_outline:w() * 0.8,
			w = self._interact_bar_max_width,
		})
		
		local interact_bar_bg = self._interact_panel:rect({
			name = "interact_bar_bg",
			blend_mode = "normal",
			color = Color.black,
			alpha = 1.0,
			h = interact_bar_outline:w(),
			w = interact_bar_outline:h(),
			layer = 0,
		})
		
		local interact_timer = self._interact_panel:text({
			name = "interact_timer",
			layer = 10,
			color = Color.white,
			w = interact_bar:w(),
			h = interact_bar:h(),
			vertical = "center",
			align = "center",
			blend_mode = "normal",
			font_size = interact_bar:h(),
			font = tweak_data.hud_players.name_font
		})
	end
	
	function HUDTeammatePanel:_adjust_interact_panel_size()
		local w = math.max(self:effective_width() - self._health_panel:w(), self._interact_panel:h() * 4)
		
		if w ~= self._interact_panel:w() then
			self._interact_panel:set_w(w)
			self._interact_panel:child("bg"):set_w(w)
			self._interact_panel:child("interact_text"):set_w(w)
			
			local interact_bar_outline = self._interact_panel:child("outline")
			interact_bar_outline:set_h(w * 0.75)
			interact_bar_outline:set_center_x(w / 2)
			interact_bar_outline:set_bottom(self._interact_panel:h() + interact_bar_outline:h() / 2 - interact_bar_outline:w() / 2)
			self._interact_bar_max_width = interact_bar_outline:h() * 0.97
			
			local interact_bar = self._interact_panel:child("interact_bar")
			interact_bar:set_w(self._interact_bar_max_width)
			interact_bar:set_center(interact_bar_outline:center())
			
			local interact_bar_bg = self._interact_panel:child("interact_bar_bg")
			interact_bar_bg:set_w(interact_bar_outline:h())
			interact_bar_bg:set_center(interact_bar:center())
			
			local interact_timer = self._interact_panel:child("interact_timer")
			interact_timer:set_w(interact_bar:w())
			interact_timer:set_center(interact_bar:center())
		end
	end
	
	function HUDTeammatePanel:teammate_progress(enabled, tweak_data_id, timer, success)
		self._interact_panel:stop()
		
		if not enabled and self._interact_panel:visible() then
			self._interact_panel:animate(callback(self, self, "_animate_interact_timer_complete"), success)
		end
		
		if enabled and HUDTeammatePanel.SHOW_INTERACTIONS and (timer > HUDTeammatePanel.SHOW_INTERACTIONS) then
			local text = ""
			if tweak_data_id then
				local action_text_id = tweak_data.interaction[tweak_data_id] and tweak_data.interaction[tweak_data_id].action_text_id or "hud_action_generic"
				text = HUDTeammatePanel._INTERACTION_TEXTS[tweak_data_id] or action_text_id and managers.localization:text(action_text_id)
			end
			
			self._interact_panel:child("interact_text"):set_text(string.format("%s (%.1fs)", utf8.to_upper(text), timer))
			self._interact_panel:animate(callback(self, self, "_animate_interact_timer"), timer)
		end
	end
	
	function HUDTeammatePanel:set_cheater(state)
		self._name_panel:child("name"):set_color(state and tweak_data.screen_colors.pro_color or Color.white)
	end
	
	function HUDTeammatePanel:add_panel(...)
		if not HUDTeammatePanel.DEBUG_HIDE then
			HUDTeammatePanel.super.add_panel(self, ...)
		end
	end
	
	function HUDTeammatePanel:remove_panel()
		HUDTeammatePanel.super.remove_panel(self)
		
		--TODO
		--self:teammate_progress(false)
	end
	
	function HUDTeammatePanel:set_callsign(id)
		HUDTeammatePanel.super.set_callsign(self, id)
		self._name_panel:child("name"):set_color((tweak_data.chat_colors[id] or Color.white):with_alpha(1))
		self._callsign_panel:child("callsign"):set_color(tweak_data.chat_colors[id]:with_alpha(1))
	end
	
	function HUDTeammatePanel:set_ai(ai)
		HUDTeammatePanel.super.set_ai(self, ai)
		
		self._interact_panel:stop()
		self._interact_panel:set_visible(false)
		self._name_panel:child("name"):set_color((not ai and tweak_data.chat_colors[self._id] or Color.white):with_alpha(1))
	end
	
	function HUDTeammatePanel:set_name(teammate_name)
		if self._name ~= teammate_name then
			HUDTeammatePanel.super.set_name(self, teammate_name)
			self._name_panel:stop()
			
			local text = self._name_panel:child("name")
			text:set_left(0)
			text:set_text(teammate_name)
			local _, _, w, _ = text:text_rect()
			w = w + 5
			text:set_w(w)
			if w > self._name_panel:w() then
				self._name_panel:animate(callback(self, self, "_animate_name_label"), w - self._name_panel:w())
			end
		end
	end
	
	function HUDTeammatePanel:recheck_outfit_string()
		local peer = self._peer_id and managers.network:session():peer(self._peer_id)
		if peer then
			local outfit = peer:blackmarket_outfit()
			self:_parse_outfit_string(outfit)
		end
	end
	
	function HUDTeammatePanel:_animate_name_label(panel, width)
		local t = 0
		local text = self._name_panel:child("name")
		
		while true do
			t = t + coroutine.yield()
			text:set_left(width * (math.sin(90 + t * HUDTeammate._NAME_ANIMATE_SPEED) * 0.5 - 0.5))
		end
	end
	
	function HUDTeammatePanel:_animate_interact_timer(panel, timer)
		self:_adjust_interact_panel_size()
		
		local bar = panel:child("interact_bar")
		local text = panel:child("interact_timer")
		local outline = panel:child("outline")
		text:set_size(self._interact_bar_max_width, bar:h())
		text:set_font_size(text:h())
		text:set_color(Color.white)
		text:set_alpha(1)
		text:set_center(outline:center())
		
		self._interact_panel:set_visible(true)
		self._interact_panel:set_alpha(0)
		
		for _, panel in ipairs({ self._weapons_panel, self._equipment_panel, self._special_equipment_panel, self._carry_panel }) do
			if panel then
				panel:set_alpha(1)
			end
		end
		
		local b = 0
		local g_max = 0.9
		local g_min = 0.1
		local r_max = 0.9
		local r_min = 0.1		
		
		local T = 0.5
		local t = 0
		while timer > t do
			if t < T then
				for _, panel in ipairs({ self._weapons_panel, self._equipment_panel, self._special_equipment_panel, self._carry_panel }) do
					if panel then
						panel:set_alpha(1-t/T)
					end
				end
				self._interact_panel:set_alpha(t/T)
			end
		
			local time_left = timer - t
			local r = t / timer
			bar:set_w(self._interact_bar_max_width * r)
			if r < 0.5 then
				local green = math.clamp(r * 2, 0, 1) * (g_max - g_min) + g_min
				bar:set_gradient_points({ 0, Color(r_max, g_min, b), 1, Color(r_max, green, b) })
			else
				local red = math.clamp(1 - (r - 0.5) * 2, 0, 1) * (r_max - r_min) + r_min
				bar:set_gradient_points({ 0, Color(r_max, g_min, b), 0.5/r, Color(r_max, g_max, b), 1, Color(red, g_max, b) })
			end
			--bar:set_gradient_points({0, Color(0.9, 0.1, 0.1), 1, Color((1-r) * 0.8 + 0.1, r * 0.8 + 0.1, 0.1)})
			text:set_text(string.format("%.1fs", time_left))
			t = t + coroutine.yield()
		end
		
		bar:set_w(self._interact_bar_max_width)
		bar:set_gradient_points({ 0, Color(r_max, g_min, b), 0.5, Color(r_max, g_max, b), 1, Color(r_min, g_max, b) })
		--bar:set_gradient_points({ 0, Color(0.9, 0.1, 0.1), 1, Color(0.1, 0.9, 0.1) })
	end
	
	function HUDTeammatePanel:_animate_interact_timer_complete(panel, success)
		local text = panel:child("interact_timer")
		local h = text:h()
		local w = text:w()
		local x = text:center_x()
		local y = text:center_y()
		text:set_color(success and Color.green or Color.red)
		
		for _, panel in ipairs({ self._weapons_panel, self._equipment_panel, self._special_equipment_panel, self._carry_panel }) do
			if panel then
				panel:set_alpha(0)
			end
		end
		self._interact_panel:set_alpha(1)
		
		if success then 
			text:set_text("DONE") 
		end
		
		local T = 1
		local t = 0
		while t < T do
			local r = math.sin(t/T*90)
			text:set_size(w * (1 + r * 2), h * (1 + r * 2))
			text:set_font_size(text:h())
			text:set_center(x, y)

			for _, panel in ipairs({ self._weapons_panel, self._equipment_panel, self._special_equipment_panel, self._carry_panel }) do
				if panel then
					panel:set_alpha(t/T)
				end
			end
			self._interact_panel:set_alpha(1-t/T)
			t = t + coroutine.yield()
		end
		
		self._interact_panel:set_visible(false)
		coroutine.yield()	--Prevents text flashing
		text:set_text("")
		text:set_color(Color.white)
		text:set_size(self._interact_bar_max_width, h)
		text:set_font_size(text:h())
		text:set_center(x, y)
	end

	function HUDTeammatePanel:increment_kill_count(unit)
		
	end
	
	
	HUDManager.CUSTOM_TEAMMATE_PANEL = true	--External flag
	HUDManager.TEAM_PANEL_SPACING = 1	--Spacing between team mate panels
	
	--Store away all of them, easier than having a fuckton of separate pointers
	local ORIGINAL_FUNCTIONS = {}
	for id, ptr in pairs(HUDManager) do
		ORIGINAL_FUNCTIONS[id] = (type(ptr) == "function") and ptr or nil
	end
	
	function HUDManager:resolution_changed(...)
		ORIGINAL_FUNCTIONS["update"](self, ...)
		
		self:restack_team_panels()
	end
	
	function HUDManager:update(t, dt, ...)
		self._next_latency_update = self._next_latency_update or 0
		
		local session = managers.network:session()
		if self._showing_stats_screen and session and self._next_latency_update <= t then
			self._next_latency_update = t + 1
			
			local latencies = {}
			for _, peer in pairs(session:peers()) do
				if peer:id() ~= session:local_peer():id() then
					latencies[peer:id()] = Network:qos(peer:rpc()).ping
				end
			end
			
			for i, panel in ipairs(self._teammate_panels_custom) do
				local latency = latencies[panel:peer_id()]
				if latency then
					self:update_custom_stats("latency", i, latency)
				end
			end
		end
	
		return ORIGINAL_FUNCTIONS["update"](self, t, dt, ...)
	end
	
	function HUDManager:_create_teammates_panel(hud, ...)
		self:_setup_stats_screen()
		
		ORIGINAL_FUNCTIONS["_create_teammates_panel"](self, hud, ...)
		
		local teammates_panel = hud.panel:child("teammates_panel")
		teammates_panel:hide()
		
		local hud = hud or managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
		self._hud.teammate_panels_data_custom = self._hud.teammate_panels_data_custom or {}
		self._teammate_panels_custom = {}
		
		if hud.panel:child("teammates_panel_custom") then
			hud.panel:remove(hud.panel:child("teammates_panel_custom"))
		end
		
		local teammates_panel_custom = hud.panel:panel({ 
			name = "teammates_panel_custom", 
			h = hud.panel:h(), 
			w = hud.panel:w(),
		})

		--local num_panels = CriminalsManager and CriminalsManager.MAX_NR_CRIMINALS or 4
		--for i = 1, math.max(num_panels, HUDManager.PLAYER_PANEL) do
		for i = 1, 4, 1 do
			local is_player = i == HUDManager.PLAYER_PANEL
			self._hud.teammate_panels_data_custom[i] = {
				taken = false,--is_player,--false and is_player, 	--TODO: The fuck is up with this value?
				special_equipments = {},
			}
			
			local teammate = is_player and HUDPlayerPanel:new(i, teammates_panel_custom) or HUDTeammatePanel:new(i, teammates_panel_custom)
			table.insert(self._teammate_panels_custom, teammate)
			
			if is_player then
				teammate:add_panel()
			end
		end
	end
	
	function HUDManager:add_teammate_panel(character_name, player_name, ai, peer_id, ...)
		for i, data in ipairs(self._hud.teammate_panels_data_custom) do
			if not data.taken then
				self._teammate_panels_custom[i]:add_panel()
				self._teammate_panels_custom[i]:set_peer_id(peer_id)
				self._teammate_panels_custom[i]:set_ai(ai)
				data.taken = true
				break
			end
		end
		
		self:restack_team_panels()
		
		 return ORIGINAL_FUNCTIONS["add_teammate_panel"](self, character_name, player_name, ai, peer_id, ...)
	end
	
	function HUDManager:remove_teammate_panel(id, ...)
		self._teammate_panels_custom[id]:remove_panel()
		self._hud.teammate_panels_data_custom[id].taken = false
		
		--TODO: WTF is this stuff about?
		--[[
		local is_ai = self._teammate_panels_custom[HUDManager.PLAYER_PANEL]._ai
		if self._teammate_panels_custom[HUDManager.PLAYER_PANEL]._peer_id and self._teammate_panels_custom[HUDManager.PLAYER_PANEL]._peer_id ~= managers.network:session():local_peer():id() or is_ai then
			local peer_id = self._teammate_panels_custom[HUDManager.PLAYER_PANEL]._peer_id
			self:remove_teammate_panel(HUDManager.PLAYER_PANEL)
			if is_ai then
				local character_name = managers.criminals:character_name_by_panel_id(HUDManager.PLAYER_PANEL)
				local name = managers.localization:text("menu_" .. character_name)
				local panel_id = self:add_teammate_panel(character_name, name, true, nil)
				managers.criminals:character_data_by_name(character_name).panel_id = panel_id
			else
				local character_name = managers.criminals:character_name_by_peer_id(peer_id)
				local panel_id = self:add_teammate_panel(character_name, managers.network:session():peer(peer_id):name(), false, peer_id)
				managers.criminals:character_data_by_name(character_name).panel_id = panel_id
			end
		end
		]]
		managers.hud._teammate_panels_custom[HUDManager.PLAYER_PANEL]:add_panel()
		self:restack_team_panels()
		
		 return ORIGINAL_FUNCTIONS["remove_teammate_panel"](self, id, ...)
	end
	
	function HUDManager:set_mugshot_voice(id, active, ...)
		local panel_id
		for _, data in pairs(managers.criminals:characters()) do
			if data.data.mugshot_id == id then
				panel_id = data.data.panel_id
				break
			end
		end

		if panel_id and panel_id ~= HUDManager.PLAYER_PANEL then
			self._teammate_panels_custom[panel_id]:set_voice_com(active)
		end
		
		 return ORIGINAL_FUNCTIONS["set_mugshot_voice"](self, id, active, ...)
	end
	
	function HUDManager:set_teammate_callsign(i, ...)
		self._teammate_panels_custom[i]:set_callsign(...)
		 return ORIGINAL_FUNCTIONS["set_teammate_callsign"](self, i, ...)
	end
	
	function HUDManager:set_teammate_name(i, ...)
		self._teammate_panels_custom[i]:set_name(...)
		 return ORIGINAL_FUNCTIONS["set_teammate_name"](self, i, ...)
	end
	
	function HUDManager:mark_cheater(peer_id, ...)
		for i, data in ipairs(self._hud.teammate_panels_data) do
			if self._teammate_panels_custom[i]:peer_id() == peer_id then
				self._teammate_panels_custom[i]:set_cheater(true)
				break
			end
		end
		
		 return ORIGINAL_FUNCTIONS["mark_cheater"](self, peer_id, ...)
	end
	
	function HUDManager:set_stamina_value(...)
		self._teammate_panels_custom[HUDManager.PLAYER_PANEL]:set_current_stamina(...)
		 return ORIGINAL_FUNCTIONS["set_stamina_value"](self, ...)
	end
	
	function HUDManager:set_max_stamina(...)
		self._teammate_panels_custom[HUDManager.PLAYER_PANEL]:set_max_stamina(...)
		 return ORIGINAL_FUNCTIONS["set_max_stamina"](self, ...)
	end
	
	function HUDManager:set_teammate_health(i, ...)
		self._teammate_panels_custom[i]:set_health(...)
		 return ORIGINAL_FUNCTIONS["set_teammate_health"](self, i, ...)
	end
	
	function HUDManager:set_teammate_armor(i, ...)
		self._teammate_panels_custom[i]:set_armor(...)
		 return ORIGINAL_FUNCTIONS["set_teammate_armor"](self, i, ...)
	end
	
	function HUDManager:set_teammate_custom_radial(i, ...)
		self._teammate_panels_custom[i]:set_custom_radial(...)
		 return ORIGINAL_FUNCTIONS["set_teammate_custom_radial"](self, i, ...)
	end
	
	function HUDManager:set_teammate_condition(i, ...)
		self._teammate_panels_custom[i]:set_condition(...)
		 return ORIGINAL_FUNCTIONS["set_teammate_condition"](self, i, ...)
	end
	
	function HUDManager:start_teammate_timer(i, ...)
		self._teammate_panels_custom[i]:start_timer(...)
		 return ORIGINAL_FUNCTIONS["start_teammate_timer"](self, i, ...)
	end
	
	function HUDManager:pause_teammate_timer(i, ...)
		self._teammate_panels_custom[i]:set_pause_timer(...)
		 return ORIGINAL_FUNCTIONS["pause_teammate_timer"](self, i, ...)
	end
	
	function HUDManager:stop_teammate_timer(i, ...)
		self._teammate_panels_custom[i]:stop_timer(...)
		return ORIGINAL_FUNCTIONS["stop_teammate_timer"](self, i, ...)
	end
	
	function HUDManager:add_weapon(data, ...)
		local selection_index = data.inventory_index
		local weapon_id = data.unit:base().name_id
		local silencer = data.unit:base():got_silencer()
		self:set_teammate_weapon_id(HUDManager.PLAYER_PANEL, selection_index, weapon_id, silencer)

		 return ORIGINAL_FUNCTIONS["add_weapon"](self, data, ...)
	end
	
	function HUDManager:set_teammate_weapon_firemode(i, ...)
		self._teammate_panels_custom[i]:set_weapon_firemode(...)
		 return ORIGINAL_FUNCTIONS["set_teammate_weapon_firemode"](self, i, ...)
	end
	
	function HUDManager:_set_teammate_weapon_selected(i, ...)
		self._teammate_panels_custom[i]:set_weapon_selected(...)
		return ORIGINAL_FUNCTIONS["_set_teammate_weapon_selected"](self, i, ...)
	end
	
	function HUDManager:set_teammate_ammo_amount(i, ...)
		self._teammate_panels_custom[i]:set_ammo_amount_by_type(...)
		return ORIGINAL_FUNCTIONS["set_teammate_ammo_amount"](self, i, ...)
	end
	
	function HUDManager:set_deployable_equipment(i, ...)
		self._teammate_panels_custom[i]:set_deployable_equipment(...)
		return ORIGINAL_FUNCTIONS["set_deployable_equipment"](self, i, ...)
	end
	
	function HUDManager:set_teammate_deployable_equipment_amount(i, ...)
		self._teammate_panels_custom[i]:set_deployable_equipment_amount(...)
		return ORIGINAL_FUNCTIONS["set_teammate_deployable_equipment_amount"](self, i, ...)
	end
	
	function HUDManager:set_teammate_grenades(i, ...)
		self._teammate_panels_custom[i]:set_grenades(...)
		return ORIGINAL_FUNCTIONS["set_teammate_grenades"](self, i, ...)
	end
	
	function HUDManager:set_teammate_grenades_amount(i, ...)
		self._teammate_panels_custom[i]:set_grenades_amount(...)
		return ORIGINAL_FUNCTIONS["set_teammate_grenades_amount"](self, i, ...)
	end	
	
	function HUDManager:set_cable_tie(i, ...)
		self._teammate_panels_custom[i]:set_cable_tie(...)
		return ORIGINAL_FUNCTIONS["set_cable_tie"](self, i, ...)
	end
	
	function HUDManager:set_cable_ties_amount(i, ...)
		self._teammate_panels_custom[i]:set_cable_ties_amount(...)
		return ORIGINAL_FUNCTIONS["set_cable_ties_amount"](self, i, ...)
	end
	
	function HUDManager:add_teammate_special_equipment(i, ...)
		self._teammate_panels_custom[i]:add_special_equipment(...)
		return ORIGINAL_FUNCTIONS["add_teammate_special_equipment"](self, i, ...)
	end
	
	function HUDManager:remove_teammate_special_equipment(i, ...)
		self._teammate_panels_custom[i]:remove_special_equipment(...)
		return ORIGINAL_FUNCTIONS["remove_teammate_special_equipment"](self, i, ...)
	end
	
	function HUDManager:set_teammate_special_equipment_amount(i, ...)
		self._teammate_panels_custom[i]:set_special_equipment_amount(...)
		return ORIGINAL_FUNCTIONS["set_teammate_special_equipment_amount"](self, i, ...)
	end
	
	function HUDManager:clear_player_special_equipments(...)
		self._teammate_panels_custom[HUDManager.PLAYER_PANEL]:clear_special_equipment(...)
		return ORIGINAL_FUNCTIONS["clear_player_special_equipments"](self,  ...)
	end
	
	function HUDManager:set_teammate_carry_info(i, ...)
		self._teammate_panels_custom[i]:set_carry_info(...)
		return ORIGINAL_FUNCTIONS["set_teammate_carry_info"](self, i, ...)
	end
	
	function HUDManager:remove_teammate_carry_info(i, ...)
		self._teammate_panels_custom[i]:remove_carry_info()
		return ORIGINAL_FUNCTIONS["remove_teammate_carry_info"](self, i, ...)
	end
	
	function HUDManager:teammate_progress(peer_id, type_index, ...)
		local character_data = managers.criminals:character_data_by_peer_id(peer_id)
		if character_data then
			self._teammate_panels_custom[character_data.panel_id]:teammate_progress(...)
		end
		
		return ORIGINAL_FUNCTIONS["teammate_progress"](self, peer_id, type_index, ...)
	end

	function HUDManager:set_stored_health(...)
		self._teammate_panels_custom[HUDManager.PLAYER_PANEL]:set_stored_health(...)
		return ORIGINAL_FUNCTIONS["set_stored_health"](self, ...)
	end
	
	function HUDManager:set_stored_health_max(...)
		self._teammate_panels_custom[HUDManager.PLAYER_PANEL]:set_stored_health_max(...)
		return ORIGINAL_FUNCTIONS["set_stored_health_max"](self, ...)
	end
	
	--New functions
	function HUDManager:set_custom_hud_enabled(status)
		local hud_panel = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2).panel
		if hud_panel then
			local default = hud_panel:child("teammates_panel")
			local custom = hud_panel:child("teammates_panel_custom")
			
			if default and custom then
				default:set_visible(not status)
				custom:set_visible(status)
			end
		end
	end
	
	function HUDManager:set_teammate_weapon_id(i, ...)
		self._teammate_panels_custom[i]:set_weapon_id(...)
	end
	
	function HUDManager:set_teammate_weapon_firemode_burst(id)
		self._teammate_panels_custom[HUDManager.PLAYER_PANEL]:set_weapon_firemode_burst(id)
	end
	
	function HUDManager:restack_team_panels()
		local offset = 0
		for i, data in ipairs(self._hud.teammate_panels_data_custom) do
			if data.taken then
				local panel = self._teammate_panels_custom[i]:panel()
				
				if i ~= HUDManager.PLAYER_PANEL then
					local h = self._teammate_panels_custom[i]:effective_height()
					panel:set_bottom(panel:parent():h() - offset)
					offset = offset + h + HUDManager.TEAM_PANEL_SPACING
				else
					panel:set_bottom(panel:parent():h())
					panel:set_center_x(panel:parent():w() / 2)
				end
			end
		end
	end
	
	function HUDManager:update_custom_stats(target, panel_id, ...)
		if self._hud_statsscreen then
			self._hud_statsscreen:set_custom_stat(panel_id, target, ...)
		end
	end
	
	function HUDManager:query_player_data(i)
		return self._teammate_panels_custom[i]:get_player_data()
	end
	
	function HUDManager.get_item_data(type, id)
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
	
end

if RequiredScript == "lib/managers/hud/hudstatsscreen" then
	
	CustomStatsBase = CustomStatsBase or class()
	CustomStatsPlayer = CustomStatsPlayer or class(CustomStatsBase)
	CustomStatsTeam = CustomStatsTeam or class(CustomStatsBase)
	
	
	function CustomStatsBase:init(height_ratio, parent, i)
		self._id = i
		self._parent = parent
		
		local x_margin = 10
		local y_margin = 10
		local x, y, w, h = self._parent:child("blur_bg"):shape()
		
		self._panel = self._parent:panel({
			name = "custom_stat_panel_" .. self._id,
			x = x + x_margin,
			y = y + y_margin,
			w = w - x_margin * 2,
			h = (h - y_margin * 2) * height_ratio,
		})
		
		local bg = self._panel:rect({
			name = "bg",
			blend_mode = "normal",
			color = Color(math.random(), math.random(), math.random()),
			w = self._panel:w(),
			h = self._panel:h(),
			layer = -1,
			alpha = 0.25,
		})
	end
	
	function CustomStatsBase:post_init()
		local player_data = managers.hud:query_player_data(self._id)
		
		if player_data then
			for stat, data in pairs(player_data) do
				local clbk = self["set_" .. stat]
				
				if clbk then
					--io.write("CustomStatsBase:post_init: " .. "set_" .. stat .. " (" .. tostring(self._id) .. ")\n")
					
					if stat == "weapon" or stat == "ammo" or stat == "add_special_equipment" then
						for id, stat_data in pairs(data) do
							clbk(self, id, unpack(stat_data))
						end
					elseif stat == "kill_count" then
						clbk(self, data)
					elseif stat == "accuracy" then
						for slot, value in ipairs(data) do
							clbk(self, slot, data[slot], data.total)
						end
					else
						local args = type(data) == "table" and data or { data }
						clbk(self, unpack(args))
					end
				else
					io.write("CustomStatsBase:post_init: " .. "set_" .. stat .. " (" .. tostring(self._id) .. "): Does not exist\n")
				end
			end
		end
	end
	
	function CustomStatsBase:set_alpha(alpha)
		self._panel:set_alpha(alpha)
	end
	
	function CustomStatsBase:_create_weapons_panel(height, sub_panel_ratio)
		self._weapons_panel = self._panel:panel({
			name = "weapons_panel",
			w = 0,
			h = height,
		})
		
		for i = 2, 1, -1 do
			local sub_panel = self._weapons_panel:panel({
				name = "weapons_panel_" .. i,
				h = self._weapons_panel:h() * sub_panel_ratio,
			})
			
			local icon_panel = sub_panel:panel({
				name = "icon_panel",
				w = sub_panel:h() * 2,
				h = sub_panel:h(),
			})
			
			local icon = icon_panel:bitmap({
				name = "icon",
				blend_mode = "normal",
				w = icon_panel:w(),
				h = icon_panel:h(),
			})
			
			local name = icon_panel:text({
				name = "name",
				text = "NAME",
				color = Color.white,
				align = "center",
				vertical = "center",
				h = icon_panel:h() * 0.25,
				font_size = icon_panel:h() * 0.25,
				font = tweak_data.hud_players.name_font,
				layer = icon:layer() + 1,
			})
			
			local silencer_icon = icon_panel:bitmap({
				name = "silencer_icon",
				texture = "guis/textures/pd2/blackmarket/inv_mod_silencer",
				blend_mode = "normal",
				visible = false,
				w = icon:h() * 0.25,
				h = icon:h() * 0.25,
				layer = icon:layer() + 1,
			})
			
			local ammo_panel = sub_panel:panel({
				name = "ammo_panel",
				h = sub_panel:h(),
			})
			
			local ammo_clip = ammo_panel:text({
				name = "ammo_clip",
				text = "000",
				color = Color.white,
				blend_mode = "normal",
				h = ammo_panel:h() * 0.55,
				vertical = "center",
				align = "right",
				font_size = ammo_panel:h() * 0.55,
				font = tweak_data.hud_players.ammo_font
			})
			
			local ammo_total = ammo_panel:text({
				name = "ammo_total",
				text = "000",
				color = Color.white,
				blend_mode = "normal",
				h = ammo_panel:h() * 0.45,
				vertical = "center",
				align = "right",
				font_size = ammo_panel:h() * 0.45,
				font = tweak_data.hud_players.ammo_font
			})
			
			local statistics_panel = sub_panel:panel({
				name = "statistics_panel",
				h = sub_panel:h(),
				w = 0,
			})
			
			local _, _, w, _ = ammo_clip:text_rect()
			ammo_panel:set_w(w)
			ammo_clip:set_w(w)
			ammo_total:set_w(w)
			ammo_total:set_bottom(ammo_panel:h())
			silencer_icon:set_bottom(icon:bottom())
			silencer_icon:set_right(icon:right())
			
			ammo_panel:set_left(icon_panel:right())
			statistics_panel:set_left(ammo_panel:right())
			sub_panel:set_w(ammo_panel:w() + icon_panel:w() + statistics_panel:w())
		end
	end
	
	function CustomStatsBase:_add_kill_count_panel(parent)
		if HUDManager.KILL_COUNT_PLUGIN then
			local kill_count_panel = parent:panel({
				name = "kill_count_panel",
				h = parent:h(),
			})
			
			local div = kill_count_panel:rect({
				name = "div",
				blend_mode = "normal",
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
				blend_mode = "normal",
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
				blend_mode = "normal",
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
	end
	
	function CustomStatsBase:_add_accuracy_panel(parent)
		if HUDManager.ACCURACY_PLUGIN then
			local accuracy_panel = parent:panel({
				name = "accuracy_panel",
				h = parent:h(),
				w = parent:h() * 0.75,
			})
			
			local div = accuracy_panel:rect({
				name = "div",
				blend_mode = "normal",
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
				blend_mode = "normal",
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
				blend_mode = "normal",
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
	end
	
	function CustomStatsBase:_add_weapon_info_panel(parent)
			local weapon_info_panel = parent:panel({
				name = "weapon_info_panel",
				h = parent:h(),
			})
			
			local div = weapon_info_panel:rect({
				name = "div",
				blend_mode = "normal",
				color = Color.white,
				x = 1,
				w = 1,
				h = weapon_info_panel:h(),
				alpha = 1,
			})
			
			local damage_accuracy = weapon_info_panel:text({
				name = "damage_accuracy",
				text = "D: 10000, A: 999",
				color = Color.white,
				blend_mode = "normal",
				layer = 1,
				x = 1 + div:x(),
				h = weapon_info_panel:h() * 0.5,
				vertical = "center",
				align = "center",
				font_size = weapon_info_panel:h() * 0.5 * 0.75,
				font = tweak_data.hud_players.ammo_font
			})
			
			local stability_concealment = weapon_info_panel:text({
				name = "stability_concealment",
				text = "S: 999, C: 999",
				color = Color.white,
				blend_mode = "normal",
				layer = 1,
				x = 1 + div:x(),
				y = weapon_info_panel:h() * 0.5,
				h = weapon_info_panel:h() * 0.5,
				vertical = "center",
				align = "center",
				font_size = weapon_info_panel:h() * 0.5 * 0.75,
				font = tweak_data.hud_players.ammo_font
			})
			
			local _, _, w, _ = damage_accuracy:text_rect()
			w = w + div:w() + 2
			
			damage_accuracy:set_w(w)
			stability_concealment:set_w(w)
			weapon_info_panel:set_w(w)
			weapon_info_panel:set_x(parent:w())
			parent:set_w(parent:w() + weapon_info_panel:w())
	end
	
	function CustomStatsBase:_create_throwable_panel(height)		
		self._throwable_panel = self._panel:panel({
			name = "throwable_panel",
			w = 0,
			h = height,
		})
		
		local icon_panel = self._throwable_panel:panel({
			name = "icon_panel",
			w = self._throwable_panel:h() * 2,
			h = self._throwable_panel:h(),
		})
		
		local icon = icon_panel:bitmap({
			name = "icon",
			blend_mode = "normal",
			w = icon_panel:w(),
			h = icon_panel:h(),
			layer = 1,
		})
		
		local name = icon_panel:text({
			name = "name",
			text = "NAME",
			layer = 1,
			color = Color.white,
			align = "center",
			vertical = "center",
			h = icon_panel:h() * 0.25,
			font_size = icon_panel:h() * 0.25,
			font = tweak_data.hud_players.name_font
		})
		
		local amount = icon_panel:text({
			name = "amount",
			text = "0",
			color = Color.white,
			blend_mode = "normal",
			layer = 1,
			w = icon_panel:w(),
			h = icon_panel:h() * 0.35,
			vertical = "center",
			align = "right",
			font_size = icon_panel:h() * 0.35,
			font = tweak_data.hud_players.ammo_font
		})
		amount:set_bottom(icon_panel:h())
		
		local statistics_panel = self._throwable_panel:panel({
			name = "statistics_panel",
			h = self._throwable_panel:h(),
			w = 0,
		})
		
		statistics_panel:set_left(icon_panel:right())
		self._throwable_panel:set_w(icon_panel:w() + statistics_panel:w())
	end
	
	function CustomStatsBase:_create_melee_panel(height)
		self._melee_panel = self._panel:panel({
			name = "melee_panel",
			w = 0,
			h = height,
		})
		
		local icon_panel = self._melee_panel:panel({
			name = "icon_panel",
			w = self._melee_panel:h() * 2,
			h = self._melee_panel:h(),
		})
		
		local icon = icon_panel:bitmap({
			name = "icon",
			blend_mode = "normal",
			w = icon_panel:w(),
			h = icon_panel:h(),
			layer = 1,
		})
		
		local name = icon_panel:text({
			name = "name",
			text = "NAME",
			layer = 1,
			color = Color.white,
			align = "center",
			vertical = "center",
			h = icon_panel:h() * 0.25,
			font_size = icon_panel:h() * 0.25,
			font = tweak_data.hud_players.name_font
		})
		
		local statistics_panel = self._melee_panel:panel({
			name = "statistics_panel",
			h = self._melee_panel:h(),
			w = 0,
		})
		
		statistics_panel:set_left(icon_panel:right())
		self._melee_panel:set_w(icon_panel:w() + statistics_panel:w())
	end
	
	function CustomStatsBase:_create_player_panel(height)
		self._player_panel = self._panel:panel({
			name = "player_panel",
			w = self._panel:w(),
			h = height,
		})
		
		local name_panel = self._player_panel:panel({
			name = "name_panel",
			w = self._player_panel:w() * 0.75,
			h = self._player_panel:h(),
		})
		
		local name = name_panel:text({
			name = "name",
			text = "(NAME)",
			layer = 1,
			color = Color.white,
			align = "center",
			vertical = "center",
			w = name_panel:w(),
			h = name_panel:h(),
			font_size = name_panel:h() * 0.9,
			font = tweak_data.hud_players.name_font
		})
		
		local rank = self._player_panel:text({
			name = "rank",
			text = "(RANK)",
			layer = 1,
			color = Color.white,
			align = "center",
			vertical = "center",
			w = (self._player_panel:w() - name_panel:w()) / 2,
			h = self._player_panel:h(),
			font_size = name_panel:h() * 0.9,
			font = tweak_data.hud_players.name_font
		})
		
		local latency = self._player_panel:text({
			name = "latency",
			text = "(LATENCY)",
			visible = not self._is_player,
			layer = 1,
			color = Color.white,
			align = "center",
			vertical = "center",
			w = (self._player_panel:w() - name_panel:w()) / 2,
			h = self._player_panel:h(),
			font_size = name_panel:h() * 0.9,
			font = tweak_data.hud_players.name_font
		})
		
		rank:set_left(0)
		name_panel:set_left(rank:right())
		latency:set_left(name_panel:right())
	end
	
	function CustomStatsBase:_create_health_panel(height)
		self._health_panel = self._panel:panel({
			name = "radial_health_panel",
			w = height,
			h = height,
		})
		
		local health_panel_bg = self._health_panel:bitmap({
			name = "radial_bg",
			texture = "guis/textures/pd2/hud_radialbg",
			w = self._health_panel:w(),
			h = self._health_panel:h(),
			layer = 0,
		})
		
		local radial_health = self._health_panel:bitmap({
			name = "radial_health",
			texture = "guis/textures/pd2/hud_health",
			texture_rect = { 64, 0, -64, 64 },
			render_template = "VertexColorTexturedRadial",
			blend_mode = "add",
			color = Color(1, 1, 0, 0),
			w = self._health_panel:w(),
			h = self._health_panel:h(),
			layer = 2,
		})
		
		local radial_shield = self._health_panel:bitmap({
			name = "radial_shield",
			texture = "guis/textures/pd2/hud_shield",
			texture_rect = { 64, 0, -64, 64 },
			render_template = "VertexColorTexturedRadial",
			blend_mode = "add",
			color = Color(1, 1, 0, 0),
			w = self._health_panel:w(),
			h = self._health_panel:h(),
			layer = 1
		})
		
		local damage_indicator = self._health_panel:bitmap({
			name = "damage_indicator",
			texture = "guis/textures/pd2/hud_radial_rim",
			blend_mode = "add",
			color = Color(1, 1, 1, 1),
			alpha = 0,
			w = self._health_panel:w(),
			h = self._health_panel:h(),
			layer = 1
		})
		local radial_custom = self._health_panel:bitmap({
			name = "radial_custom",
			texture = "guis/textures/pd2/hud_swansong",
			texture_rect = { 0, 0, 64, 64 },
			render_template = "VertexColorTexturedRadial",
			blend_mode = "add",
			color = Color(1, 0, 0, 0),
			visible = false,
			w = self._health_panel:w(),
			h = self._health_panel:h(),
			layer = 2
		})
		
		self._condition_icon = self._health_panel:bitmap({
			name = "condition_icon",
			layer = 4,
			visible = false,
			color = Color.white,
			w = self._health_panel:w(),
			h = self._health_panel:h(),
		})
		self._condition_timer = self._health_panel:text({
			name = "condition_timer",
			visible = false,
			layer = 5,
			color = Color.white,
			w = self._health_panel:w(),
			h = self._health_panel:h(),
			align = "center",
			vertical = "center",
			font_size = self._health_panel:h() * 0.5,
			font = tweak_data.hud_players.timer_font
		})
	end
	
	function CustomStatsBase:_create_armor_panel(height)
		self._armor_panel = self._panel:panel({
			name = "armor_panel",
			w = 0,
			h = height,
		})
		
		local icon_panel = self._armor_panel:panel({
			name = "icon_panel",
			w = self._armor_panel:h(),
			h = self._armor_panel:h(),
		})
		
		local icon = icon_panel:bitmap({
			name = "icon",
			blend_mode = "normal",
			w = icon_panel:w(),
			h = icon_panel:h(),
			layer = 1,
		})
		
		local name = icon_panel:text({
			name = "name",
			text = "NAME",
			layer = 1,
			color = Color.white,
			align = "center",
			vertical = "center",
			h = icon_panel:h() * 0.25 * 0.5,
			font_size = icon_panel:h() * 0.25 * 0.5,
			font = tweak_data.hud_players.name_font
		})
		
		local statistics_panel = self._armor_panel:panel({
			name = "statistics_panel",
			h = self._armor_panel:h() * 0.5,
			w = 0,
		})
		
		statistics_panel:set_left(icon_panel:right())
		self._armor_panel:set_w(icon_panel:w() + statistics_panel:w())
	end
	
	function CustomStatsBase:_create_equipment_panel(height)
		local sub_panels = { "deployable_equipment_panel", "cable_ties_panel" }
		
		self._equipment_panel = self._panel:panel({
			name = "equipment_panel",
			h = height,
			w = height * (height / #sub_panels) * 3,
		})
		
		for i, name in ipairs(sub_panels) do
			local panel = self._equipment_panel:panel({
				name = name,
				h = self._equipment_panel:h() / #sub_panels,
				w = self._equipment_panel:w(),
			})
			
			local icon = panel:bitmap({
				name = "icon",
				layer = 1,
				color = Color.white,
				w = panel:h(),
				h = panel:h(),
				layer = 2,
			})
			
			local amount = panel:text({
				name = "amount",
				text = "00",
				font = "fonts/font_medium_mf",
				font_size = panel:h(),
				color = Color.white,
				align = "right",
				vertical = "center",
				layer = 2,
				w = panel:h() * 2,
				h = panel:h()
			})
			
			panel:set_top((i-1) * panel:h())
		end
	end
	
	function CustomStatsBase:_create_special_equipment_panel(height)
		self._special_equipment_panel = self._panel:panel({
			name = "special_equipment_panel",
			h = height,
			w = 0,
		})
	end
	
	
	function CustomStatsBase:_layout_special_equipments()
		local w = 0
		
		for i, child in ipairs(self._special_equipment_panel:children()) do
			child:set_x((i-1) * child:w())
			w = w + child:w()
		end
		
		self._special_equipment_panel:set_w(w)
	end
	
	function CustomStatsBase:_set_scrolling_text(parent, component, text)
		component:set_text(text)
		local _, _, w, _ = component:text_rect()
		component:set_w(w)

		if component:w() > parent:w() then
			parent:animate(callback(self, self, "_animate_scroll_name_label"), component)
		else
			parent:stop()
			component:set_center_x(parent:w() / 2)
		end
	end
	
	function CustomStatsBase:_animate_scroll_name_label(parent, component)
		local ANIMATE_SPEED = 90
		local width = component:w() - parent:w()
		local t = 0
		
		while true do
			t = t + coroutine.yield()
			component:set_left(width * (math.sin(90 + t * ANIMATE_SPEED) * 0.5 - 0.5))
		end
	end
	
	
	function CustomStatsBase:set_weapon(slot, id, silencer, blueprint)
		local panel = self._weapons_panel:child("weapons_panel_" .. slot)
		local icon_panel = panel:child("icon_panel")
		local icon = icon_panel:child("icon")
		local silencer_icon = icon_panel:child("silencer_icon")
		local name = icon_panel:child("name")
		
		local texture, text = HUDManager.get_item_data("weapon", id)
		
		icon:set_image(texture)
		silencer_icon:set_visible(silencer)
		
		if name then
			self:_set_scrolling_text(icon_panel, name, text)
		end
		--[[
		local weapon_info = panel:child("statistics_panel"):child("weapon_info_panel")
		if weapon_info and blueprint and BlackMarketGui then
			local used_stats = {
				--{name = "magazine", stat_name = "extra_ammo"},
				--{name = "totalammo", stat_name = "total_ammo_mod"},
				--{name = "fire_rate"},
				{name = "damage"},
				{name = "spread", offset = true, revert = true},
				{name = "recoil", offset = true, revert = true},
				{name = "concealment", index = true},
				--{name = "suppression", offset = true},
			}
			
			--TODO: _get_X_stats() no longer exists
			local factory_id = managers.weapon_factory:get_factory_id_by_weapon_id(id)
			local base_stats = BlackMarketGui._get_base_stats({ _stats_shown = used_stats }, id)
			local mods_stats = BlackMarketGui._get_mods_stats({ _stats_shown = used_stats }, id, base_stats, blueprint)
			local stats = {}
			for _, stat in ipairs(used_stats) do
				stats[stat.name] = math.max(base_stats[stat.name].value + mods_stats[stat.name].value, 0)
			end
			
			weapon_info:child("damage_accuracy"):set_text(string.format("D: %.0f, A: %.0f", stats.damage, stats.spread))
			weapon_info:child("stability_concealment"):set_text(string.format("S: %.0f, C: %.0f", stats.recoil, stats.concealment))
		end
		]]
	end
	
	function CustomStatsBase:set_ammo(slot, max_clip, current_clip, current_left, max)
		local panel = self._panel:child("weapons_panel"):child("weapons_panel_" .. slot):child("ammo_panel")
		local low_ammo = current_left <= math.round(max_clip / 2)
		local low_ammo_clip = current_clip <= math.round(max_clip / 4)
		local out_of_ammo_clip = current_clip <= 0
		local out_of_ammo = current_left <= 0
		local color_total = out_of_ammo and Color(1, 0.9, 0.3, 0.3)
		color_total = color_total or low_ammo and Color(1, 0.9, 0.9, 0.3)
		color_total = color_total or Color.white
		local color_clip = out_of_ammo_clip and Color(1, 0.9, 0.3, 0.3)
		color_clip = color_clip or low_ammo_clip and Color(1, 0.9, 0.9, 0.3)
		color_clip = color_clip or Color.white
		
		local ammo_clip = panel:child("ammo_clip")
		local zero = current_clip < 10 and "00" or current_clip < 100 and "0" or ""
		ammo_clip:set_text(zero .. tostring(current_clip))
		ammo_clip:set_color(color_clip)
		ammo_clip:set_range_color(0, string.len(zero), color_clip:with_alpha(0.5))
		
		local ammo_total = panel:child("ammo_total")
		local zero = current_left < 10 and "00" or current_left < 100 and "0" or ""
		ammo_total:set_text(zero .. tostring(current_left))
		ammo_total:set_color(color_total)
		ammo_total:set_range_color(0, string.len(zero), color_total:with_alpha(0.5))
	end
	
	function CustomStatsBase:set_throwable(id)
		local panel = self._throwable_panel:child("icon_panel")
		local icon = panel:child("icon")
		local name = panel:child("name")
		
		local texture, text = HUDManager.get_item_data("throwable", id)
		
		icon:set_image(texture)
		self:_set_scrolling_text(panel, name, text)
	end
	
	function CustomStatsBase:set_throwable_amount(value)
		local amount = self._throwable_panel:child("icon_panel"):child("amount")
		amount:set_text(tostring(value or 0))
	end
	
	function CustomStatsBase:set_melee(id)
		local panel = self._melee_panel:child("icon_panel")
		local icon = panel:child("icon")
		local name = panel:child("name")
		
		if id ~= "weapon" then
			local texture, text = HUDManager.get_item_data("melee", id)
		
			icon:set_image(texture)
			self:_set_scrolling_text(panel, name, text)
		else
			--TODO
			--Need special case for the default melee
		end
	end
	
	function CustomStatsBase:set_armor(id)
		local icon_panel = self._armor_panel:child("icon_panel")
		local icon = icon_panel:child("icon")
		local name = icon_panel:child("name")
		
		local texture, text = HUDManager.get_item_data("armor", id)
		
		icon:set_image(texture)
		
		if name then
			self:_set_scrolling_text(icon_panel, name, text)
		end
	end
	
	function CustomStatsBase:set_deployable_icon(...)
		local deployable_equipment_panel = self._equipment_panel:child("deployable_equipment_panel")
		local deployable_icon = deployable_equipment_panel:child("icon")
		deployable_icon:set_image(...)
	end
	
	function CustomStatsBase:set_deployable_amount(value)
		local deployable_equipment_panel = self._equipment_panel:child("deployable_equipment_panel")
		local deployable_amount = deployable_equipment_panel:child("amount")
		deployable_amount:set_text(string.format("%02d", value))
	end
	
	function CustomStatsBase:set_cable_tie_icon(...)
		local cable_ties_panel = self._equipment_panel:child("cable_ties_panel")
		local tie_icon = cable_ties_panel:child("icon")
		tie_icon:set_image(...)
	end
	
	function CustomStatsBase:set_cable_tie_amount(value)
		local cable_ties_panel = self._equipment_panel:child("cable_ties_panel")
		local cable_ties_amount = cable_ties_panel:child("amount")
		cable_ties_amount:set_text(string.format("%02d", value))
	end
	
	function CustomStatsBase:set_add_special_equipment(id, icon_data, count)
		local size = self._special_equipment_panel:h()
		count = count or 0
		
		local equipment_panel = self._special_equipment_panel:panel({
			name = id,
			h = size,
			w = size,
		})
		
		local icon, texture_rect = tweak_data.hud_icons:get_icon_data(icon_data)
		local bitmap = equipment_panel:bitmap({
			name = "bitmap",
			texture = icon,
			color = Color.white,
			layer = 1,
			texture_rect = texture_rect,
			w = equipment_panel:w(),
			h = equipment_panel:h()
		})
		
		if count then
			local amount = equipment_panel:child("amount") or equipment_panel:text({
				name = "amount",
				text = tostring(count),
				font = "fonts/font_small_noshadow_mf",
				font_size = 12 * equipment_panel:h() / 32,
				color = Color.black,
				align = "center",
				vertical = "center",
				layer = 4,
				w = equipment_panel:w(),
				h = equipment_panel:h()
			})
			amount:set_visible(1 < count)
			
			local amount_bg = equipment_panel:child("amount_bg") or equipment_panel:bitmap({
				name = "amount_bg",
				texture = "guis/textures/pd2/equip_count",
				color = Color.white,
				layer = 3,
			})
			amount_bg:set_visible(1 < count)

			amount_bg:set_size(amount_bg:w() * equipment_panel:w() / 32, amount_bg:h() * equipment_panel:h() / 32)
			amount_bg:set_center(bitmap:center())
			amount_bg:move(amount:w() * 0.2, amount:h() * 0.2)
			amount:set_center(amount_bg:center())
		end
		
		self:_layout_special_equipments()
	end
	
	function CustomStatsBase:set_remove_special_equipment(id)
		for i, child in ipairs(self._special_equipment_panel:children()) do
			if child:name() == id then
				self._special_equipment_panel:remove(child)
				break
			end
		end
		
		self:_layout_special_equipments()
	end
	
	function CustomStatsBase:set_special_equipment_amount(id, value)
		for i, child in ipairs(self._special_equipment_panel:children()) do
			if child:name() == id then
				child:child("amount"):set_text(tostring(value))
				child:child("amount"):set_visible(value > 1)
				child:child("amount_bg"):set_visible(value > 1)
				break
			end
		end
	end
	
	function CustomStatsBase:set_clear_special_equipment()
		self._special_equipment_panel:clear()
	end
	
	function CustomStatsBase:set_callsign(callsign)
		local name = self._player_panel:child("name_panel"):child("name")
		local bg = self._panel:child("bg")
		local color = tweak_data.chat_colors[callsign]:with_alpha(1)
		bg:set_color(color)
		name:set_color(color)
	end
	
	function CustomStatsBase:set_peer_id(peer_id)
		self._peer_id = peer_id
		self:set_name(self._name)
	end
	
	function CustomStatsBase:set_ai(status)
		self:set_peer_id(nil)
		
		--TODO: Add stuff as they are created
		--self._player_panel:child("rank"):set_visible(not status)
		--self._player_panel:child("latency"):set_visible(not status)
		--self._melee_panel:set_visible(not status)
		--self._throwable_panel:set_visible(not status)
		--self._weapons_panel:set_visible(not status)
	end
	
	function CustomStatsBase:set_name(name)
		--TODO: Clean this BS up somehow
		self._name = name
		
		if name then
			local panel = self._player_panel:child("name_panel")
			local character_name
			if self._id == HUDManager.PLAYER_PANEL then
				character_name = managers.criminals:character_name_by_peer_id(managers.network:session():local_peer():id())
			else
				character_name = self._peer_id and managers.criminals:character_name_by_peer_id(self._peer_id) or managers.criminals:character_name_by_panel_id(self._id)
			end
			
			if character_name then
				local localized_character_name = managers.localization:text("menu_" .. character_name)
				self:_set_scrolling_text(panel, panel:child("name"), string.format("%s (%s)", name, localized_character_name))
			else
				self:_set_scrolling_text(panel, panel:child("name"), string.format("%s", name))
			end
		end
	end
	
	function CustomStatsBase:set_level(level, infamy)
		local rank = self._player_panel:child("rank")
		local infamy_string = managers.experience:rank_string(infamy)
		infamy_string = infamy_string .. ((infamy_string ~= "") and "-" or "")
		rank:set_text(string.format("%s%s", infamy_string, tostring(level)))
	end
	
	function CustomStatsBase:set_latency(value)
		local latency = self._player_panel:child("latency")
		latency:set_text(string.format("%dms", value))
	end
	
	function CustomStatsBase:set_kill_count(data)
		if not HUDManager.KILL_COUNT_PLUGIN then return end
		
		for weapon_type, wdata in pairs(data.by_weapon) do
			if wdata.slotted then
				for slot, slotdata in ipairs(wdata) do
					self:set_kill_count_by_weapon(slotdata.normal, slotdata.special, weapon_type, slot)
				end
			else
				self:set_kill_count_by_weapon(wdata.normal, wdata.special, weapon_type)
			end
		end
		
		for unit_type, count in pairs(data.by_unit) do
			self:set_kill_count_by_unit(unit_type, count)
		end
		
		self:set_kill_count_total(data.total.normal, data.total.special)
	end
	
	function CustomStatsBase:set_kill_count_by_weapon(normal, special, weapon_type, weapon_slot)
		if not HUDManager.KILL_COUNT_PLUGIN then return end
	
		local function update_kill_count(parent, normals, specials)
			local statistics_panel = parent:child("statistics_panel")
			if statistics_panel then
				local kill_count_panel = statistics_panel:child("kill_count_panel")
				if kill_count_panel then
					local count = kill_count_panel:child("count")
					count:set_text(string.format("%d/%d", normals, specials))
				end
			end
		end
	
		local panel
		if weapon_type == "melee" then
			panel = self._melee_panel
		elseif weapon_type == "throwable" then
			panel = self._throwable_panel
		elseif weapon_type == "weapon" then
			panel = self._weapons_panel:child("weapons_panel_" .. weapon_slot)
		--elseif weapon_type == "sentry" then
		--elseif weapon_type == "trip_mine" then
		end
		
		if panel then
			update_kill_count(panel, normal, special)
		end
	end
	
	function CustomStatsBase:set_kill_count_total(normal, special)
		if not HUDManager.KILL_COUNT_PLUGIN then return end
		
		--TODO
	end
	
	function CustomStatsBase:set_kill_count_by_unit(unit_type, count)
		if not HUDManager.KILL_COUNT_PLUGIN then return end
			
		--TODO
	end
	
	function CustomStatsBase:set_accuracy(weapon_slot, weapon_value, total_value)
		if HUDManager.ACCURACY_PLUGIN then
			local statistics_panel = self._weapons_panel:child("weapons_panel_" .. weapon_slot):child("statistics_panel")
			if statistics_panel then
				local accuracy_panel = statistics_panel:child("accuracy_panel")
				if accuracy_panel then
					local count = accuracy_panel:child("count")
					count:set_text(string.format("%d%%", weapon_value))
				end
			end
			
			--TODO: Total accuracy when component exists
		end
	end
	
	
	
	function CustomStatsPlayer:init(...)
		self._is_player = true
	
		CustomStatsPlayer.super.init(self, 1, ...)
		
		self:_create_weapons_panel(self._panel:h() * 0.4 * 1/3)
		self:_create_throwable_panel(self._panel:h() * 0.2 * 1/3)
		self:_create_melee_panel(self._panel:h() * 0.2 * 1/3)
		self:_create_player_panel(self._panel:h() * 0.1 * 1/3)
		self:_create_armor_panel(self._panel:h() * 0.5 * 1/3)
		self:_create_health_panel(self._panel:h() * 0.25 * 1/3)
		self:_create_special_equipment_panel(self._panel:h() * 0.25 * 1/3 * 1/3)
		self:_create_equipment_panel(self._panel:h() * 0.25 * 2/3 * 1/3)
		
		self._player_panel:set_top(0)
		self._throwable_panel:set_bottom(self._panel:h())
		self._melee_panel:set_bottom(self._throwable_panel:top())
		self._weapons_panel:set_bottom(self._melee_panel:top())
		self._armor_panel:set_top(self._player_panel:bottom())
		self._armor_panel:set_right(self._panel:w())
		self._health_panel:set_top(self._player_panel:bottom())
		self._special_equipment_panel:set_bottom(self._weapons_panel:top())
		self._equipment_panel:set_bottom(self._special_equipment_panel:top())
	end
	
	function CustomStatsPlayer:_create_weapons_panel(height)
		CustomStatsPlayer.super._create_weapons_panel(self, height, 0.5)
		
		local w = 0
		for i = 2, 1, -1 do
			local sub_panel = self._weapons_panel:child("weapons_panel_" .. i)
			local statistics_panel = sub_panel:child("statistics_panel")
			
			local old_w = statistics_panel:w()
			self:_add_kill_count_panel(statistics_panel)
			self:_add_accuracy_panel(statistics_panel)
			self:_add_weapon_info_panel(statistics_panel)
			sub_panel:set_w(sub_panel:w() + (statistics_panel:w() - old_w))
			
			sub_panel:set_y((2-i) * sub_panel:h())
			w = w + sub_panel:w()
		end
		
		self._weapons_panel:set_w(w)
	end
	
	function CustomStatsPlayer:_create_throwable_panel(height)
		CustomStatsPlayer.super._create_throwable_panel(self, height)
		
		local statistics_panel = self._throwable_panel:child("statistics_panel")
		local old_w = statistics_panel:w()
		self:_add_kill_count_panel(statistics_panel)
		--self:_add_weapon_info_panel(statistics_panel)		--TODO
		self._throwable_panel:set_w(self._throwable_panel:w() + (statistics_panel:w() - old_w))
	end
	
	function CustomStatsPlayer:_create_melee_panel(height)
		CustomStatsPlayer.super._create_melee_panel(self, height)
		
		local statistics_panel = self._melee_panel:child("statistics_panel")
		local old_w = statistics_panel:w()
		self:_add_kill_count_panel(statistics_panel)
		--self:_add_weapon_info_panel(statistics_panel)		--TODO
		self._melee_panel:set_w(self._melee_panel:w() + (statistics_panel:w() - old_w))
	end


	function CustomStatsTeam:init(...)
		CustomStatsTeam.super.init(self, 1/3, ...)
		
		self:_create_weapons_panel(self._panel:h() * 0.4)
		self:_create_throwable_panel(self._panel:h() * 0.2)
		self:_create_melee_panel(self._panel:h() * 0.2)
		self:_create_player_panel(self._panel:h() * 0.1)
		self:_create_armor_panel(self._panel:h() * 0.5)
		self:_create_health_panel(self._panel:h() * 0.25)
		self:_create_special_equipment_panel(self._panel:h() * 0.25 * 1/3)
		self:_create_equipment_panel(self._panel:h() * 0.25 * 2/3)
		
		self._player_panel:set_top(0)
		self._weapons_panel:set_bottom(self._panel:h())
		self._melee_panel:set_bottom(self._panel:h())
		self._melee_panel:set_right(self._panel:w())
		self._throwable_panel:set_bottom(self._melee_panel:top())
		self._throwable_panel:set_right(self._panel:w())
		self._armor_panel:set_top(self._player_panel:bottom())
		self._armor_panel:set_right(self._panel:w())
		self._health_panel:set_top(self._player_panel:bottom())
		self._special_equipment_panel:set_bottom(self._weapons_panel:top())
		self._equipment_panel:set_bottom(self._special_equipment_panel:top())
		
		self._panel:set_y(self._panel:y() + (self._id - 1) * self._panel:h())
	end
	
	function CustomStatsTeam:_create_weapons_panel(height)
		CustomStatsTeam.super._create_weapons_panel(self, height, 0.5)
		
		local w = 0
		for i = 2, 1, -1 do
			local sub_panel = self._weapons_panel:child("weapons_panel_" .. i)
			local statistics_panel = sub_panel:child("statistics_panel")
			
			local old_w = statistics_panel:w()
			self:_add_weapon_info_panel(statistics_panel)
			sub_panel:set_w(sub_panel:w() + (statistics_panel:w() - old_w))
			
			sub_panel:set_y((2-i) * sub_panel:h())
			w = w + sub_panel:w()
		end
		
		self._weapons_panel:set_w(w)
	end
	

	
	
	local init_original = HUDStatsScreen.init
	local show_original = HUDStatsScreen.show
	
	HUDStatsScreen.SHOW_CUSTOM_PANEL_INITIALLY = true
	HUDStatsScreen.OSCILLATION_TIME = 5
	HUDStatsScreen.FADE_TIME = 0.5
	
	function HUDStatsScreen:init(...)
		init_original(self, ...)
		
		local left_panel = self._full_hud_panel:child("left_panel")
		local right_panel = self._full_hud_panel:child("right_panel")
		
		self._custom_stats_team_panels = {}
		
		for i = 1, 4, 1 do
			local is_player = i == HUDManager.PLAYER_PANEL
			local parent = is_player and left_panel or right_panel
			local class = is_player and CustomStatsPlayer or CustomStatsTeam
			
			self._custom_stats_team_panels[i] = class:new(parent, i)
			self._custom_stats_team_panels[i]:post_init()
		end
	end
	
	function HUDStatsScreen:show(...)
		self:_adjust_custom_panel_alpha(HUDStatsScreen.SHOW_CUSTOM_PANEL_INITIALLY and 1 or 0)
		
		show_original(self, ...)
		
		local left_panel = self._full_hud_panel:child("left_panel")
		left_panel:animate(callback(self, self, "_animate_oscillate_custom_panel"))
	end
	
	function HUDStatsScreen:set_custom_stat(i, stat, ...)
		local stat_panel = self._custom_stats_team_panels[i]
		local cbk = stat_panel and stat_panel["set_" .. stat]
		
		if cbk then
			cbk(stat_panel, ...)
		end
	end
	
	function HUDStatsScreen:_adjust_custom_panel_alpha(alpha)
		local left_panel = self._full_hud_panel:child("left_panel")
		local right_panel = self._full_hud_panel:child("right_panel")
	
		for _, parent in ipairs({ left_panel, right_panel }) do
			for _, child in ipairs(parent:children()) do
				local name = child:name()
				if name ~= "" and name ~= "blur_bg" then
					child:set_alpha(1-alpha)
				end
			end
		end
		
		for _, panel in ipairs(self._custom_stats_team_panels) do
			panel:set_alpha(alpha)
		end
	end
	
	function HUDStatsScreen:_animate_oscillate_custom_panel()
		local custom_visible = HUDStatsScreen.SHOW_CUSTOM_PANEL_INITIALLY
		
		while true do
			custom_visible = not custom_visible
			
			local t = 0
			while t < HUDStatsScreen.OSCILLATION_TIME do
				t = t + coroutine.yield()
			end
			
			t = 0
			while t < HUDStatsScreen.FADE_TIME do
				local r = t/HUDStatsScreen.FADE_TIME
				self:_adjust_custom_panel_alpha(custom_visible and r or (1-r))
				t = t + coroutine.yield()
			end
			
			self:_adjust_custom_panel_alpha(custom_visible and 1 or 0)
		end
	end
	
	
	
	
	
	
end