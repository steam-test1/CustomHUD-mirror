PlayerInfoComponent = PlayerInfoComponent or {}

PlayerInfoComponent.Base = PlayerInfoComponent.Base or class()

function PlayerInfoComponent.Base:init(parent, name, width, height)
	self._parent = parent
	self._enabled = true
	self._visible = true
	
	self._panel = parent:panel():panel({
		name = name,
		h = height or 0,
		w = width or 0,
	})
end

function PlayerInfoComponent.Base:arrange(internal_only, w, h) 	--Override in subclasses if needed
	local shape_changed = false

	if w and w ~= self._panel:w() then
		shape_changed = true
		self._panel:set_w(w)
	end
	
	if h and h ~= self._panel:h() then
		shape_changed = true
		self._panel:set_h(h)
	end
	
	if shape_changed and not internal_only then
		self:set_visible(w > 0 and h > 0)
		self._parent:arrange()
	end
end

function PlayerInfoComponent.Base:set_enabled(status)
	self._enabled = status and true or false
	self:set_visible(self._visible)
end

function PlayerInfoComponent.Base:set_visible(status)
	self._visible = status and true or false
	self._panel:set_visible(self._visible and self._enabled)
end

function PlayerInfoComponent.Base:panel() return self._panel end
function PlayerInfoComponent.Base:w() return self._panel:w() end
function PlayerInfoComponent.Base:h() return self._panel:h() end
function PlayerInfoComponent.Base:x() return self._panel:x() end
function PlayerInfoComponent.Base:y() return self._panel:y() end
function PlayerInfoComponent.Base:left() return self._panel:left() end
function PlayerInfoComponent.Base:right() return self._panel:right() end
function PlayerInfoComponent.Base:top() return self._panel:top() end
function PlayerInfoComponent.Base:bottom() return self._panel:bottom() end
function PlayerInfoComponent.Base:center() return self._panel:center() end
function PlayerInfoComponent.Base:visible() return self._panel:visible() end
function PlayerInfoComponent.Base:layer() return self._panel:layer() end

function PlayerInfoComponent.Base:set_x(v) self._panel:set_x(v) end
function PlayerInfoComponent.Base:set_y(v) self._panel:set_y(v) end
function PlayerInfoComponent.Base:set_left(v) self._panel:set_left(v) end
function PlayerInfoComponent.Base:set_right(v) self._panel:set_right(v) end
function PlayerInfoComponent.Base:set_top(v) self._panel:set_top(v) end
function PlayerInfoComponent.Base:set_bottom(v) self._panel:set_bottom(v) end
function PlayerInfoComponent.Base:set_center(x, y) self._panel:set_center(x, y) end
function PlayerInfoComponent.Base:set_layer(v) self._panel:set_layer(v) end

function PlayerInfoComponent.Base.get_item_data(type, id)
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

function PlayerInfoComponent.HealthRadial:init(parent, size)
	PlayerInfoComponent.HealthRadial.super.init(self, parent, "health", size, size)
	
	self._bg = self._panel:bitmap({
		name = "bg",
		texture = "guis/textures/pd2/hud_radialbg",
		w = size,
		h = size,
	})
	
	self._radial = self._panel:bitmap({
		name = "health",
		texture = "guis/textures/pd2/hud_health",
		texture_rect = { 64, 0, -64, 64 },
		render_template = "VertexColorTexturedRadial",
		blend_mode = "add",
		color = Color(1, 1, 1),
		w = size,
		h = size,
		layer = 2,
	})
	
	self._stored_radial = self._panel:bitmap({
		name = "stored_health",
		texture = "guis/textures/pd2/hud_health",
		texture_rect = { 64, 0, -64, 64 },
		render_template = "VertexColorTexturedRadial",
		blend_mode = "add",
		color = Color(0, 0, 0),
		alpha = 0.5,
		w = size,
		h = size,
		layer = 3,
	})
	
	self._stored_health = 0
	self._stored_health_max = 0
end

function PlayerInfoComponent.HealthRadial:set_health(data)
	local ratio = data.current / data.total
	local prev = self._radial:color().red
	
	if ratio < prev then
		self._parent:damage_taken("health", prev - ratio)
	end
	
	self._radial:set_color(Color(ratio, 1, 1))
	self._stored_radial:set_rotation(-ratio * 360)
	self:set_stored_health_max(1-ratio)
end

function PlayerInfoComponent.HealthRadial:set_stored_health(stored_health)
	self._stored_health = stored_health
	self._stored_radial:set_color(Color(math.min(self._stored_health, self._stored_health_max), 0, 0))
end
	
function PlayerInfoComponent.HealthRadial:set_stored_health_max(stored_health_max)
	self._stored_health_max = stored_health_max
	self:set_stored_health(self._stored_health)
end


PlayerInfoComponent.ArmorRadial = PlayerInfoComponent.ArmorRadial or class(PlayerInfoComponent.Base)

function PlayerInfoComponent.ArmorRadial:init(parent, size)
	PlayerInfoComponent.ArmorRadial.super.init(self, parent, "armor", size, size)
	
	self._radial = self._panel:bitmap({
		name = "radial_shield",
		texture = "guis/textures/pd2/hud_shield",
		texture_rect = { 64, 0, -64, 64 },
		render_template = "VertexColorTexturedRadial",
		blend_mode = "add",
		color = Color(1, 0, 0),
		w = size,
		h = size,
	})
end

function PlayerInfoComponent.ArmorRadial:set_armor(data)
	local ratio = data.current / data.total
	local prev = self._radial:color().red
	
	if ratio < prev then
		self._parent:damage_taken("armor", prev - ratio)
	end
	
	self._radial:set_color(Color(1, ratio, 1, 1))
end


PlayerInfoComponent.StaminaRadial = PlayerInfoComponent.StaminaRadial or class(PlayerInfoComponent.Base)

function PlayerInfoComponent.StaminaRadial:init(parent, size)
	PlayerInfoComponent.StaminaRadial.super.init(self, parent, "stamina", size, size)
	
	self._radial = self._panel:bitmap({
		name = "radial_shield",
		texture = "guis/textures/pd2/hud_shield",
		texture_rect = { 64, 0, -64, 64 },
		render_template = "VertexColorTexturedRadial",
		blend_mode = "add",
		color = Color(1, 0, 0),
		w = size,
		h = size,
	})
end

function PlayerInfoComponent.StaminaRadial:set_stamina_max(data)
	self._max = data.total
end

function PlayerInfoComponent.StaminaRadial:set_stamina(data)
	local ratio = data.current / (data.total or self._max or 1)
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

function PlayerInfoComponent.DamageIndicatorRadial:init(parent, size)
	PlayerInfoComponent.DamageIndicatorRadial.super.init(self, parent, "armor", size, size)
	
	self._indicator = self._panel:bitmap({
		name = "damage_indicator",
		texture = "guis/textures/pd2/hud_radial_rim",
		blend_mode = "add",
		color = Color(1, 1, 1, 1),
		alpha = 0,
		w = size,
		h = size,
	})
end

function PlayerInfoComponent.DamageIndicatorRadial:damage_taken(damage_type, amount)
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

function PlayerInfoComponent.ConditionRadial:init(parent, size)
	PlayerInfoComponent.ConditionRadial.super.init(self, parent, "condition", size, size)
	
	self._icon = self._panel:bitmap({
		name = "icon",
		visible = false,
		color = Color.white,
		w = size,
		h = size,
	})
	
	self._timer = self._panel:text({
		name = "timer",
		visible = false,
		color = Color.white,
		w = size,
		h = size,
		align = "center",
		vertical = "center",
		font_size = size * 0.5,
		font = tweak_data.hud_players.timer_font,
		layer = self._icon:layer() + 1,
	})
	
	self._timer_paused = false
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
		
		self._timer_paused = false
		self._timer:set_font_size(self._panel:h() * 0.5)
		self._timer:set_visible(true)
		self._timer:animate(callback(self, self, "_animate_timer"), time)
	end
	
function PlayerInfoComponent.ConditionRadial:stop_timer()
	self._timer:stop()
	self._timer:set_visible(false)
end

function PlayerInfoComponent.ConditionRadial:pause_timer(pause)
	self._timer_paused = pause
end

function PlayerInfoComponent.ConditionRadial:_animate_timer(timer, initial)
	local T = initial
	local t = initial
	
	while t >= 0 do
		local dt = coroutine.yield()
		if not self._timer_paused then
			t = t - dt
			
			local r = 1 - t / T
			local red = 0.1 + 0.7 * math.min(2*r, 1)
			local green = 0.8 - 0.7 * math.max(2*(r-0.5), 0)
			timer:set_color(Color(red, green, 0.1))
			timer:set_text(string.format("%02.0f", t))
			
			if t < 10 then
				timer:animate(callback(self, self, "_animate_timer_flash"))
			end
		end
	end
end

function PlayerInfoComponent.ConditionRadial:_animate_timer_flash()
	local t = 0
	while t < 0.5 do
		t = t + coroutine.yield()
		local n = 1 - math.sin(t * 180)
		self._timer:set_font_size(math.lerp(self._panel:h() * 0.5, self._panel:h() * 0.8, n))
	end
	self._timer:set_font_size(self._panel:h() * 0.5)
end


PlayerInfoComponent.CustomRadial = PlayerInfoComponent.CustomRadial or class(PlayerInfoComponent.Base)

function PlayerInfoComponent.CustomRadial:init(parent, size)
	PlayerInfoComponent.CustomRadial.super.init(self, parent, "condition", size, size)
	
	self._icon = self._panel:bitmap({
		name = "radial_custom",
		texture = "guis/textures/pd2/hud_swansong",
		texture_rect = { 0, 0, 64, 64 },
		render_template = "VertexColorTexturedRadial",
		blend_mode = "add",
		color = Color(1, 0, 0, 0),
		visible = false,
		w = self._panel:w(),
		h = self._panel:h(),
	})
end

function PlayerInfoComponent.CustomRadial:set_progress(data)
	local ratio = data.current / data.total
	self._icon:set_color(Color(1, ratio, 1, 1))
	self._icon:set_visible(ratio > 0)
end


PlayerInfoComponent.ManiacRadial = PlayerInfoComponent.ManiacRadial or class(PlayerInfoComponent.Base)

function PlayerInfoComponent.ManiacRadial:init(parent, size)
	PlayerInfoComponent.ManiacRadial.super.init(self, parent, "maniac", size, size)

	self._radial = self._panel:bitmap({
		name = "radial_absorb_shield_active",
		texture = "guis/dlcs/coco/textures/pd2/hud_absorb_shield",
		texture_rect = { 0, 0, 64, 64 },
		render_template = "VertexColorTexturedRadial",
		blend_mode = "normal",
		alpha = 1,
		w = self:w() * 0.92,
		h = self:h() * 0.92,
		color = Color.black,
	})
	self._radial:set_center(self:w() / 2, self:h() / 2)
	
	local tweak = tweak_data.upgrades
	self._max_absorb = tweak.cocaine_stacks_dmg_absorption_value * tweak.values.player.cocaine_stack_absorption_multiplier[1] * tweak.max_total_cocaine_stacks  / tweak.cocaine_stacks_convert_levels[2]
end

function PlayerInfoComponent.ManiacRadial:set_absorb(amount)
	local r = amount / self._max_absorb
	self:set_visible(r > 0)
	self._radial:set_color(Color(r, 1, 1))
end

function PlayerInfoComponent.ManiacRadial:set_stacks(data)
	--local r = math.clamp(data.current / data.max, 0, 1)
	--self:set_visible(r > 0)
	--self._radial:set_color(Color(r, 1, 1))
end


PlayerInfoComponent.PlayerStatusRadial = PlayerInfoComponent.PlayerStatusRadial or class(PlayerInfoComponent.Base)

function PlayerInfoComponent.PlayerStatusRadial:init(parent, size, is_player)
	PlayerInfoComponent.PlayerStatusRadial.super.init(self, parent, "player_status", size, size)

	self._health = PlayerInfoComponent.HealthRadial:new(self, size)
	self._health:set_layer(0)
	self._armor = PlayerInfoComponent.ArmorRadial:new(self, size)
	self._armor:set_layer(1)
	self._stamina = PlayerInfoComponent.StaminaRadial:new(self, size * 0.45)
	self._stamina:set_center(self._health:center())
	self._stamina:set_layer(1)
	self._stamina:set_enabled(is_player)
	self._damage_indicator = PlayerInfoComponent.DamageIndicatorRadial:new(self, size)
	self._damage_indicator:set_layer(2)
	self._condition = PlayerInfoComponent.ConditionRadial:new(self, size)
	self._condition:set_layer(3)
	self._custom_radial = PlayerInfoComponent.CustomRadial:new(self, size)
	self._custom_radial:set_layer(3)
	self._maniac = PlayerInfoComponent.ManiacRadial:new(self, size)
	self._maniac:set_layer(10)
	
	self._components = {
		health = self._health,
		armor = self._armor,
		stamina = self._stamina,
		damage_indicator = self._damage_indicator,
		condition = self._condition,
		custom_radial = self._custom_radial,
		maniac = self._maniac,
	}
end

function PlayerInfoComponent.PlayerStatusRadial:get_component(id)
	return self._components[id]
end

function PlayerInfoComponent.PlayerStatusRadial:damage_taken(dmg_type, amount)
	self._damage_indicator:damage_taken(dmg_type, amount)
end


PlayerInfoComponent.Callsign = PlayerInfoComponent.Callsign or class(PlayerInfoComponent.Base)

function PlayerInfoComponent.Callsign:init(parent, size)
	PlayerInfoComponent.Callsign.super.init(self, parent, "callsign", size, size)
	
	self._icon = self._panel:bitmap({
		name = "icon",
		texture = "guis/textures/pd2/hud_tabs",
		texture_rect = { 84, 34, 19, 19 },
		color = Color.white,
		w = self:w(),
		h = self:h(),
	})
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


PlayerInfoComponent.Name = PlayerInfoComponent.Name or class(PlayerInfoComponent.Base)

function PlayerInfoComponent.Name:init(parent, height)
	PlayerInfoComponent.Name.super.init(self, parent, "name", 0, height)
	
	self._text = self._panel:text({
		name = "name",
		color = Color.white,
		align = "left",
		vertical = "center",
		h = height,
		w = 0,
		font_size = height * 0.95,
		font = tweak_data.hud_players.name_font,
	})
end

function PlayerInfoComponent.Name:set_name(name)
	self._text:set_text(name)
	local _, _, w, _ = self._text:text_rect()
	self._text:set_w(w)
	self:arrange(false, w, self:h())
end

function PlayerInfoComponent.Name:set_id(id)
	self._text:set_color((tweak_data.chat_colors[id] or Color.white):with_alpha(1))
end


PlayerInfoComponent.Weapon = PlayerInfoComponent.Weapon or class(PlayerInfoComponent.Base)

function PlayerInfoComponent.Weapon:init(parent, slot, height, settings)
	PlayerInfoComponent.Weapon.super.init(self, parent, "weapon_" .. tostring(slot), 0, height)
	
	self._components = {}
	self._fire_modes = {}
	self._has_multiple_fire_modes = false
	
	self._bg = self._panel:rect({
		name = "bg",
		blend_mode = "normal",
		color = Color.black,
		alpha = 0.25,
		h = height,
		layer = -1,
	})
	
	self._icon_panel = self._panel:panel({
		name = "icon_panel",
		w = height * 2,
		h = height,
	})
	
	local weapon_icon = self._icon_panel:bitmap({
		name = "icon",
		blend_mode = "normal",
		w = self._icon_panel:w(),
		h = self._icon_panel:h(),
	})
	
	local silencer_icon = self._icon_panel:bitmap({
		name = "silencer_icon",
		texture = "guis/textures/pd2/blackmarket/inv_mod_silencer",
		blend_mode = "normal",
		visible = false,
		w = self._icon_panel:h() * 0.25,
		h = self._icon_panel:h() * 0.25,
		layer = weapon_icon:layer() + 1,
	})
	silencer_icon:set_bottom(weapon_icon:bottom())
	silencer_icon:set_right(weapon_icon:right())
	
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
	
	table.insert(self._components, self._icon_panel)
	
	self._ammo_panel = self._panel:panel({
		name = "ammo_panel",
		h = height,
	})
		
	local ammo_mag = self._ammo_panel:text({
		name = "mag",
		text = "000",
		color = Color.white,
		blend_mode = "normal",
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
		blend_mode = "normal",
		vertical = "center",
		align = "right",
		h = self._ammo_panel:h() * 0.4,
		font_size = self._ammo_panel:h() * 0.4,
		font = tweak_data.hud_players.ammo_font
	})
	ammo_total:set_center_y((self._ammo_panel:h() - ammo_mag:h()) / 2 + ammo_mag:h())
	
	local _, _, w, _ = ammo_mag:text_rect()
	self._ammo_panel:set_w(w)
	ammo_mag:set_w(w)
	ammo_total:set_w(w)

	table.insert(self._components, self._ammo_panel)
	
	self._fire_mode_panel = self._panel:panel({
		name = "fire_mode_panel",
		h = ammo_total:h(),
		w = height * 0.15,
		visible = false,
	})
	self._fire_mode_panel:set_center_y(ammo_total:center_y())
	
	local active_mode = self._fire_mode_panel:text({
		name = "active_mode",
		text = "O",
		color = Color.black,
		blend_mode = "normal",
		vertical = "center",
		align = "center",
		w = self._fire_mode_panel:w(),
		h = self._fire_mode_panel:h(),
		font_size = ammo_total:h() * 0.75,
		font = tweak_data.hud_players.ammo_font,
		layer = 1,
	})
	
	local _, _, w, h = active_mode:text_rect()
	local bg = self._fire_mode_panel:rect({
		name = "bg",
		blend_mode = "normal",
		color = Color.white,
		w = w * 1.1,
		h = h,
		layer = 0,
	})
	bg:set_center(active_mode:center())
	
	self:arrange(true)
end

function PlayerInfoComponent.Weapon:add_statistics_panel()
	self._statistics_panel = self._panel:panel({
		name = "statistics_panel",
		h = self._panel:h(),
		w = 0,
	})
	
	table.insert(self._components, self._statistics_panel)
	
	--TODO: Check killcount and accuracy plugins, add stuff if so
--[[
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
]]

--TODO: Update statisticspanel width
	self:arrange()
end

function PlayerInfoComponent.Weapon:arrange(internal_only)
	local MARGIN_SIZE = self._panel:h() * 0.05
	local margins = 1
	local offset = 0
	
	self._icon_panel:set_x(offset + margins * MARGIN_SIZE)
	if self._icon_panel:visible() then
		margins = margins + 1
		offset = offset + self._icon_panel:w()
	end
	
	self._ammo_panel:set_x(offset + margins * MARGIN_SIZE)
	self._fire_mode_panel:set_x(offset + margins * MARGIN_SIZE)
	if self._ammo_panel:visible() or self._fire_mode_panel:visible() then
		margins = margins + 1
		offset = offset + math.max(
			self._ammo_panel:w() * (self._ammo_panel:visible() and 1 or 0), 
			self._fire_mode_panel:w() * (self._fire_mode_panel:visible() and 1 or 0)
		)
	end
	
	if self._statistics_panel then
		self._statistics_panel:set_x(offset + margins * MARGIN_SIZE)
		if self._statistics_panel:visible() then
			margins = margins + 1
			offset = offset + self._statistics_panel:w()
		end
	end
	
	local w = offset + ((offset > 0) and (margins * MARGIN_SIZE) or 0)
	local h = self:h()
	
	PlayerInfoComponent.Weapon.super.arrange(self, internal_only, w, h)
	self._bg:set_w(self._panel:w())
end

function PlayerInfoComponent.Weapon:set_available_fire_modes(modes, reset)
	if reset then
		self._fire_modes = {}
		self._has_multiple_fire_modes = false
	end
	
	self._has_multiple_fire_modes = self._has_multiple_fire_modes or (#modes > 1)
	self._fire_mode_panel:set_visible(self._show_fire_mode and self._has_multiple_fire_modes)
	
	for _, mode in ipairs(modes) do
		local name = mode[1]
		local text = mode[2]
		self._fire_modes[name] = text
	end
end

function PlayerInfoComponent.Weapon:set_fire_mode(active_mode)
	if self._fire_modes[active_mode] then
		self._fire_mode_panel:child("active_mode"):set_text(self._fire_modes[active_mode])
	end
end

function PlayerInfoComponent.Weapon:set_weapon(data)
	local bitmap_texture, text = PlayerInfoComponent.Base.get_item_data("weapon", data.id)
	
	self._icon_panel:child("icon"):set_image(bitmap_texture)
	self._icon_panel:child("silencer_icon"):set_visible(data.silencer)
	self._icon_panel:child("label"):set_text(text)
end

function PlayerInfoComponent.Weapon:set_selected(status)
	for _, component in ipairs({ self._icon_panel, self._ammo_panel, self._fire_mode_panel, self._statistics_panel }) do
		if component then
			component:set_alpha(status and 1 or 0.5)
		end
	end
end

function PlayerInfoComponent.Weapon:show_icon(status)
	if self._icon_panel:visible() ~= status then
		self._icon_panel:set_visible(status)
		self:arrange()
	end
end

function PlayerInfoComponent.Weapon:show_ammo(status)
	if self._ammo_panel:visible() ~= status then
		self._ammo_panel:set_visible(status)
		self:arrange()
	end
end

function PlayerInfoComponent.Weapon:show_fire_mode(status)
	self._show_fire_mode = status
	
	if self._fire_mode_panel:visible() ~= (status and self._has_multiple_fire_modes) then
		self._fire_mode_panel:set_visible(status)
		self:arrange()
	end
end

function PlayerInfoComponent.Weapon:set_ammo_amount(data)
	local function update_component(component, current, max)
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

	update_component(self._ammo_panel:child("mag"), data.mag_current, data.mag_max)
	update_component(self._ammo_panel:child("total"), data.total_current, data.total_max)
end


PlayerInfoComponent.Equipment = PlayerInfoComponent.Equipment or class(PlayerInfoComponent.Base)

function PlayerInfoComponent.Equipment:init(parent, width, height, horizontal)
	PlayerInfoComponent.Equipment.super.init(self, parent, "equipment", width, height)
	
	self._horizontal = horizontal
	self._equipment_types = { "deployables", "cable_ties", "throwables" }
	
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
		
		local bg = panel:rect({
			name = "bg",
			blend_mode = "normal",
			color = Color.black,
			alpha = 0.25,
			h = panel:h(),
			w = panel:w(),
			layer = -1,
		})
	end
	
	self:set_visible(false)
end

function PlayerInfoComponent.Equipment:arrange(internal_only)
	local i = 0
	local w = self._horizontal and 0 or self:w()
	local h = self._horizontal and self:h() or 0
	
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
	
	PlayerInfoComponent.Equipment.super.arrange(self, internal_only, w, h)
end

function PlayerInfoComponent.Equipment:set_cable_tie(data)
	local texture, texture_rect = tweak_data.hud_icons:get_icon_data(data.icon)
	self._panel:child("cable_ties"):child("icon"):set_image(texture, unpack(texture_rect))
	self:set_cable_tie_amount(data.amount)
end

function PlayerInfoComponent.Equipment:set_cable_tie_amount(amount)	
	local panel = self._panel:child("cable_ties")
	local text = panel:child("amount")
	text:set_text(string.format("%02.0f", amount))
	text:set_range_color(0, amount < 10 and 1 or 0, Color.white:with_alpha(0.5))
	panel:set_visible(amount > 0)
	self:arrange()
end

function PlayerInfoComponent.Equipment:set_throwable(data)
	local texture, texture_rect = tweak_data.hud_icons:get_icon_data(data.icon)
	self._panel:child("throwables"):child("icon"):set_image(texture, unpack(texture_rect))
	self:set_throwable_amount(data.amount)
end

function PlayerInfoComponent.Equipment:set_throwable_amount(amount)
	local panel = self._panel:child("throwables")
	local text = panel:child("amount")
	text:set_text(string.format("%02.0f", amount))
	text:set_range_color(0, amount < 10 and 1 or 0, Color.white:with_alpha(0.5))
	panel:set_visible(amount > 0)
	self:arrange()
end

function PlayerInfoComponent.Equipment:set_deployable(data)
	local texture, texture_rect = tweak_data.hud_icons:get_icon_data(data.icon)
	self._panel:child("deployables"):child("icon"):set_image(texture, unpack(texture_rect))
	self:set_deployable_amount(data.amount)
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

function PlayerInfoComponent.SpecialEquipment:init(parent, height)
	PlayerInfoComponent.SpecialEquipment.super.init(self, parent, "special_equipment", 0, height)
	
	self._item_size = height / 3
	self._special_equipment = {}
	
	self:set_visible(false)
end

function PlayerInfoComponent.SpecialEquipment:add(id, data)
	if self._panel:child(id) then
		self._panel:remove(self._panel:child(id))
	end
	
	local panel = self._panel:panel({
		name = id,
		h = self._item_size,
		w = self._item_size,
	})
	
	local texture, texture_rect = tweak_data.hud_icons:get_icon_data(data.icon)
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
	self:set_amount(id, data.amount)
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

function PlayerInfoComponent.SpecialEquipment:arrange(internal_only)
	local w = 0
	local h = self:h()
	local items_per_column = math.floor(self._panel:h() / self._item_size)
	
	for i, panel in ipairs(self._special_equipment) do
		local column = math.floor((i-1) / items_per_column)
		local row = (i-1) % items_per_column
		panel:set_left(column * panel:w())
		panel:set_top(row * panel:h())
		w = (column+1) * panel:w()
	end
	
	self:set_visible(w > 0)
	PlayerInfoComponent.SpecialEquipment.super.arrange(self, internal_only, w, h)
end



PlayerInfoComponent.Throwable = PlayerInfoComponent.Throwable or class(PlayerInfoComponent.Base)

function PlayerInfoComponent.Throwable:init(parent, height)
	PlayerInfoComponent.Throwable.super.init(self, parent, "throwable", 0, height)
		
	self._icon_panel = self._panel:panel({
		name = "icon_panel",
		w = self._panel:h() * 2,
		h = self._panel:h(),
	})
	
	local icon = self._icon_panel:bitmap({
		name = "icon",
		blend_mode = "normal",
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
		blend_mode = "normal",
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
]]

--TODO: Update statisticspanel width
	self:arrange()
end

function PlayerInfoComponent.Throwable:arrange(internal_only)
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
	
	PlayerInfoComponent.Throwable.super.arrange(self, internal_only, w, h)
end

function PlayerInfoComponent.Throwable:set_icon(id)
	local texture, text = PlayerInfoComponent.Base.get_item_data("throwable", id)
	
	self._icon_panel:child("icon"):set_image(texture)
	self._icon_panel:child("label"):set_text(text)
end

function PlayerInfoComponent.Throwable:set_amount(count)
	self._icon_panel:child("amount"):set_text(tostring(count))
end


PlayerInfoComponent.Melee = PlayerInfoComponent.Melee or class(PlayerInfoComponent.Base)


PlayerInfoComponent.Armor = PlayerInfoComponent.Armor or class(PlayerInfoComponent.Base)


PlayerInfoComponent.Deployable = PlayerInfoComponent.Deployable or class(PlayerInfoComponent.Base)












HUDTeammateCustom = HUDTeammateCustom or class(PlayerInfoComponent.Base)

HUDTeammateCustom.SETTINGS = {
	MAX_WEAPONS = 2,	--Number of carried guns
	
	PLAYER = {
		SCALE = 1,
		--NAME = true,
		STATUS = true,
		EQUIPMENT = true,
		SPECIAL_EQUIPMENT = true,
		CALLSIGN = true,
		WEAPON = {
			--Pick *one* setting of each or results are undefined
			ICON = {
				--HIDE = true,
				--SELECTED_ONLY = true,
				--UNSELECTED_ONLY = true,
			},
			AMMO = {
				--HIDE = true,
				--SELECTED_ONLY = true,
				--UNSELECTED_ONLY = true,
			},
			FIRE_MODE = {
				--HIDE = true,
				--SELECTED_ONLY = true,
				--UNSELECTED_ONLY = true,
			},
		},
	},
	
	
	TEAMMATE = {
		SCALE = 0.85,
		NAME = true,
		STATUS = true,
		EQUIPMENT = true,
		SPECIAL_EQUIPMENT = true,
		CALLSIGN = true,
		WEAPON = {
			--Pick *one* setting of each or results are undefined
			ICON = {
				--HIDE = true,
				SELECTED_ONLY = true,
				--UNSELECTED_ONLY = true,
			},
			AMMO = {
				--HIDE = true,
				--SELECTED_ONLY = true,
				--UNSELECTED_ONLY = true,
			},
		},
	},
}

function HUDTeammateCustom:init(id, parent, is_player, alignment)
	managers.hud:register_teammate_info_listener(id, callback(self, self, "_update_event"))

	self._left_align = alignment == "left"
	self._settings = HUDTeammateCustom.SETTINGS[is_player and "PLAYER" or "TEAMMATE"]
	self._id = id
	self._is_player = is_player
	self._weapons = {}
	
	local size = 50 * (self._settings.SCALE)
	HUDTeammateCustom.super.init(self, parent, "teammate_panel_" .. tostring(id), 0, size)
	
	self._name = PlayerInfoComponent.Name:new(self, 20 * self._settings.SCALE)
	self._player_status = PlayerInfoComponent.PlayerStatusRadial:new(self, size, is_player)
	self._equipment = PlayerInfoComponent.Equipment:new(self, size * 0.6, size, false)
	self._special_equipment = PlayerInfoComponent.SpecialEquipment:new(self, size)
	self._callsign = PlayerInfoComponent.Callsign:new(self, size * 0.325)
	
	for i = 1, HUDTeammateCustom.SETTINGS.MAX_WEAPONS, 1 do
		table.insert(self._weapons, PlayerInfoComponent.Weapon:new(self, i, size))
	end
	
	self._name:set_enabled(self._settings.NAME)
	self._player_status:set_enabled(self._settings.STATUS)
	self._equipment:set_enabled(self._settings.EQUIPMENT)
	self._special_equipment:set_enabled(self._settings.SPECIAL_EQUIPMENT)
	self._callsign:set_enabled(self._settings.CALLSIGN)
	
	for i, weapon in ipairs(self._weapons) do
		weapon:show_icon(not self._settings.WEAPON.ICON.HIDE)
		weapon:show_ammo(not self._settings.WEAPON.AMMO.HIDE)
		if self._settings.WEAPON.FIRE_MODE then
			weapon:show_fire_mode(not self._settings.WEAPON.FIRE_MODE.HIDE)
		end
	end
	
	self:set_visible(false)
	self:arrange()
end

function HUDTeammateCustom:update(t, dt)
	
end

function HUDTeammateCustom:taken()
	return self._taken
end

function HUDTeammateCustom:peer_id()
	return self._peer_id
end

function HUDTeammateCustom:ai()
	return self._ai
end

function HUDTeammateCustom:arrange()
	local MARGIN = 3
	local w = 0
	local h = 0
	
	local left_align = self._align
	local component_order = {}
	
	table.insert(component_order, self._player_status)
	for _, weapon in ipairs(self._weapons) do
		table.insert(component_order, weapon)
	end
	table.insert(component_order, self._equipment)
	table.insert(component_order, self._special_equipment)
	
	local start = self._left_align and 1 or #component_order
	local stop = self._left_align and #component_order or 1
	local step = self._left_align and 1 or -1
	for i = start, stop, step do
		local component = component_order[i]
		
		component:set_x(w)
		if component:visible() then
			w = w + component:w() + MARGIN
			h = math.max(h, component:h())
			
			if self._name:visible() then
				component:set_y(self._name:h())
			end
		end
	end
	
	if self._name:visible() then
		h = h + self._name:h()
		w = math.max(w, self._name:w())
		self._name:set_y(0)
		if self._left_align then
			self._name:set_left(0)
		else
			self._name:set_right(w)
		end
	end
	
	self._callsign:set_center(self._player_status:center())
	
	if not self._player_status:visible() and self._callsign:visible() then
		h = math.max(h, self._callsign:h())
		w = w + self._callsign:w() + MARGIN
		self._callsign:set_y(0)
		if self._left_align then
			self._callsign:set_left(0)
			self._name:set_left(self._callsign:right())
		else
			self._callsign:set_right(self._name:left())
		end
	end
	
	self._panel:set_w(w)
	self._panel:set_h(h)
	managers.hud:arrange_teammate_panels()

	
	do return end
	




	self._player_status:set_x(w)
	
	if self._player_status:visible() then
		w = w + self._player_status:w() + MARGIN
		h = math.max(h, self._player_status:h())
	elseif self._callsign:visible() then
		w = w + self._callsign:w() + MARGIN
		h = math.max(h, self._callsign:h())
	end
	
	local add_weapon_margin = false
	for _, weapon in ipairs(self._weapons) do
		weapon:set_x(w)
		if weapon:visible() then
			add_weapon_margin = true
			h = math.max(h, weapon:h())
			w = w + weapon:w()
		end
	end
	if add_weapon_margin then
		w = w + MARGIN
	end
	
	self._equipment:set_x(w)
	if self._equipment:visible() then
		w = w + self._equipment:w() + MARGIN
		h = math.max(h, self._equipment:h())
	end
	
	self._special_equipment:set_x(w)
	if self._special_equipment:visible() then
		w = w + self._special_equipment:w() + MARGIN
		h = math.max(h, self._special_equipment:h())
	end
	
	if self._name:visible() then
		self._name:set_x(0)
		self._player_status:set_y(self._name:h())
		self._equipment:set_y(self._name:h())
		self._special_equipment:set_y(self._name:h())
		for _, weapon in ipairs(self._weapons) do
			weapon:set_y(self._name:h())
		end
		
		h = h + self._name:h()
	end
	
	self._callsign:set_center(self._player_status:center())
	
	self._panel:set_w(w)
	self._panel:set_h(h)
	managers.hud:arrange_teammate_panels()
end

function HUDTeammateCustom:add_panel()
	self._panel:show()
	self._taken = true
	managers.hud:arrange_teammate_panels()
end

function HUDTeammateCustom:remove_panel()
	self._panel:hide()
	self._taken = false
	
	self:set_cheater(false)
	self:set_peer_id(nil)
	self:set_ai(nil)
	managers.hud:set_teammate_condition(self._id, "mugshot_normal")
	managers.hud:stop_teammate_timer(self._id)
	managers.hud:clear_teammate_special_equipments(self._id)
	
	--self:remove_carry_info()
	
	managers.hud:arrange_teammate_panels()
end


function HUDTeammateCustom:_update_event(event, ...)
	local EVENT_TABLE = {
		weapon = "_weapon_event",
		ammo_amount = "_weapon_event",
		fire_mode = "_weapon_event",
		available_fire_modes = "_weapon_event",
		weapon_selected = "_weapon_selected_event",
		deployable = "_equipment_event",
		deployable_amount = "_equipment_event",
		throwable = "_equipment_event",
		throwable_amount = "_equipment_event",
		cable_tie = "_equipment_event",
		cable_tie_amount = "_equipment_event",
		add_special_equipment = "_special_equipment_event",
		remove_special_equipment = "_special_equipment_event",
		set_special_equipment_amount = "_special_equipment_event",
		clear_special_equipment = "_special_equipment_event",
		condition = "_player_status_event",
		start_timer = "_player_status_event",
		pause_timer = "_player_status_event",
		stop_timer = "_player_status_event",
		health = "_player_status_event",
		stored_health = "_player_status_event",
		stored_health_max = "_player_status_event",
		armor = "_player_status_event",
		stamina = "_player_status_event",
		max_stamina = "_player_status_event",
		custom_radial_progress = "_player_status_event",
		maniac_stacks = "_player_status_event",
		maniac_absorb = "_player_status_event",
		voice_com = "_voice_com_event",
		callsign = "_callsign_event",
		name = "_name_event",
	}
	
	local clbk = EVENT_TABLE[event]
	
	if self[clbk] then
		self[clbk](self, event, ...)
	elseif clbk then
		printf("ERROR (_update_event): Missing callback for event: %s\n", event)
	end
end

function HUDTeammateCustom:_weapon_event(event, index, ...)
	local CLBK_TABLE = {
		weapon = "set_weapon",
		ammo_amount = "set_ammo_amount",
		fire_mode = "set_fire_mode",
		available_fire_modes = "set_available_fire_modes",
	}
	
	local wpn = self._weapons[index]
	local clbk = CLBK_TABLE[event]
	
	if wpn[clbk] then
		wpn[clbk](wpn, ...)
	elseif clbk then
		printf("ERROR (_weapon_event): Missing callback for event: %s\n", event)
	end
end

function HUDTeammateCustom:_weapon_selected_event(event, index)
	local clbks = {
		ICON = "show_icon",
		AMMO = "show_ammo",
		FIRE_MODE = "show_fire_mode",
	}
	
	for i, weapon in ipairs(self._weapons) do
		weapon:set_selected(i == index)
		
		for component, settings in pairs(self._settings.WEAPON) do
			if not settings.HIDE then
				local clbk = clbks[component]
				local visible = true
				
				if settings.SELECTED_ONLY then visible = (i == index) end
				if settings.UNSELECTED_ONLY then visible = (i ~= index) end
				
				weapon[clbk](weapon, visible)
			end
		end
	end
end

function HUDTeammateCustom:_equipment_event(event, ...)
	local CLBK_TABLE = {
		deployable = "set_deployable",
		deployable_amount = "set_deployable_amount",
		throwable = "set_throwable",
		throwable_amount = "set_throwable_amount",
		cable_tie = "set_cable_tie",
		cable_tie_amount = "set_cable_tie_amount",
	}
	
	local clbk = CLBK_TABLE[event]
	
	if self._equipment[clbk] then
		self._equipment[clbk](self._equipment, ...)
	elseif clbk then
		printf("ERROR (_equipment_event): Missing callback for event: %s\n", event)
	end
end

function HUDTeammateCustom:_special_equipment_event(event, ...)
	local CLBK_TABLE = {
		add_special_equipment = "add",
		remove_special_equipment = "remove",
		set_special_equipment_amount = "set_amount",
		clear_special_equipment = "clear",
	}
	
	local clbk = CLBK_TABLE[event]
	
	if self._special_equipment[clbk] then
		self._special_equipment[clbk](self._special_equipment, ...)
	elseif clbk then
		printf("ERROR (_special_equipment_event): Missing callback for event: %s\n", event)
	end
end

function HUDTeammateCustom:_player_status_event(event, ...)
	local CLBK_TABLE = {
		condition = { obj = "condition", clbk = "set_condition" },
		start_timer = { obj = "condition", clbk = "start_timer" },
		pause_timer = { obj = "condition", clbk = "pause_timer" },
		stop_timer = { obj = "condition", clbk = "stop_timer" },
		health = { obj = "health", clbk = "set_health" },
		stored_health = { obj = "health", clbk = "set_stored_health" },
		stored_health_max = { obj = "health", clbk = "set_stored_health_max" },
		armor = { obj = "armor", clbk = "set_armor" },
		stamina = { obj = "stamina", clbk = "set_stamina" },
		max_stamina = { obj = "stamina", clbk = "set_stamina_max" },
		custom_radial_progress = { obj = "custom_radial", clbk = "set_progress" },
		maniac_stacks = { obj = "maniac", clbk = "set_stacks" },
		maniac_absorb = { obj = "maniac", clbk = "set_absorb" },
	}
	
	local data = CLBK_TABLE[event]
	local obj = self._player_status:get_component(data.obj)
	
	if obj and obj[data.clbk] then
		obj[data.clbk](obj, ...)
	elseif data then
		printf("ERROR (_player_status_event): Missing callback for event: %s\n", event)
	end
end

function HUDTeammateCustom:_voice_com_event(event, status)
	self._callsign:set_voice_com_active(status)
end

function HUDTeammateCustom:_callsign_event(event, id)
	id = self._is_player and managers.network:session():local_peer():id() or id
	self._callsign:set_id(id)
	self._name:set_id(id)
end

function HUDTeammateCustom:_name_event(event, name)
	self._name:set_name(name)
end


function HUDTeammateCustom:set_cheater(status)
	
end

function HUDTeammateCustom:set_peer_id(peer_id)
	self._peer_id = peer_id
	
	--local peer = managers.network:session() and managers.network:session():peer(peer_id)
	--if peer then
	--	self:_set_rank(peer:level(), peer:rank())
	--end
	
	--self:recheck_outfit_string()
end

function HUDTeammateCustom:set_ai(status)
	--printf("HUDTeammateCustom:set_ai: %s, %s\n", tostring(self._id), tostring(status))
	self._ai = status and true or false
		
	for i, panel in ipairs(self._weapons) do
		panel:set_enabled(not self._ai)
		panel:arrange(true)
	end
	
	--self._player_status:set_enabled(not self._ai and self._settings.STATUS)
	self._equipment:set_enabled(not self._ai and self._settings.EQUIPMENT)
	self._special_equipment:set_enabled(not self._ai and self._settings.SPECIAL_EQUIPMENT)
	--self._callsign:set_enabled(not self._ai and self._settings.CALLSIGN)
	self._callsign:set_id(5)
	self._name:set_id(5)
	--self._interact_panel:stop()
	--self._interact_panel:set_visible(false)
	
	--self._equipment:arrange(true)
	--self._special_equipment:arrange(true)
	self:arrange()
end








local ORIGINAL_FUNCTIONS = {}
for id, ptr in pairs(HUDManager) do
	ORIGINAL_FUNCTIONS[id] = (type(ptr) == "function") and ptr or nil
end

function HUDManager:init(...)
	ORIGINAL_FUNCTIONS["init"](self, ...)
	
	self._teammate_info_listeners = {}
	self._teammate_panel_data = {}
end

function HUDManager:_create_teammates_panel(hud, ...)
	--self:_setup_stats_screen()
	
	ORIGINAL_FUNCTIONS["_create_teammates_panel"](self, hud, ...)
	
	local teammates_panel = hud.panel:child("teammates_panel")
	teammates_panel:hide()
	
	--local hud = hud or managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
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
	
	local num_panels = CriminalsManager.MAX_NR_CRIMINALS
	for i = 1, math.max(num_panels, HUDManager.PLAYER_PANEL) do
		self._teammate_panel_data[i] = {}
		local is_player = i == HUDManager.PLAYER_PANEL
		local panel = HUDTeammateCustom:new(i, teammates_panel_custom, is_player, "left")
		
		table.insert(self._teammate_panels_custom, panel)
		if is_player then
			printf("HUDManager: ADD PLAYER PANEL\n")
			panel:add_panel()
			panel:set_peer_id(managers.network:session():local_peer():id())
			panel:set_ai(false)
		end
	end
	
	self:arrange_teammate_panels()
end

function HUDManager:update(...)
	for i, panel in ipairs(self._teammate_panels_custom) do
		if panel:taken() then
			panel:update(...)
		end
	end
	
	return ORIGINAL_FUNCTIONS["update"](self, ...)
end

function HUDManager:add_teammate_panel(character_name, player_name, ai, peer_id, ...)
	printf("HUDManager: ADD PANEL %s, %s\n", tostring(ai), tostring(peer_id))
	
	for i, panel in ipairs(self._teammate_panels_custom) do
		if not panel:taken() then
			printf("\tUSING ID %d\n", i)
			panel:add_panel()
			panel:set_peer_id(peer_id)
			panel:set_ai(ai)
			self:set_teammate_name(i, player_name)
			self:set_teammate_callsign(i, ai and 5 or peer_id)
			
			if not ai and peer_id then
				self:_parse_outfit_string(i, peer_id)
			end
			
			if peer_id then
				local peer_equipment = managers.player:get_synced_equipment_possession(peer_id) or {}
				for equipment, amount in pairs(peer_equipment) do
					self:add_teammate_special_equipment(i, { 
						id = equipment, 
						icon = tweak_data.equipments.specials[equipment].icon,
						amount = amount
					})
				end
				
				local peer_deployable_equipment = managers.player:get_synced_deployable_equipment(peer_id)
				if peer_deployable_equipment then
					local icon = tweak_data.equipments[peer_deployable_equipment.deployable].icon
					self:set_deployable_equipment(i, {
						icon = icon,
						amount = peer_deployable_equipment.amount
					})
				end
				local peer_cable_ties = managers.player:get_synced_cable_ties(peer_id)
				if peer_cable_ties then
					local icon = tweak_data.equipments.specials.cable_tie.icon
					self:set_cable_tie(i, {
						icon = icon,
						amount = peer_cable_ties.amount
					})
				end
				local peer_grenades = managers.player:get_synced_grenades(peer_id)
				if peer_grenades then
					local icon = tweak_data.blackmarket.projectiles[peer_grenades.grenade].icon
					self:set_teammate_grenades(i, {
						icon = icon,
						amount = Application:digest_value(peer_grenades.amount, false)
					})
				end
			end
			
			local peer_ammo_info = managers.player:get_synced_ammo_info(peer_id)
			if peer_ammo_info then
				for selection_index, ammo_info in pairs(peer_ammo_info) do
					self:set_teammate_ammo_amount(i, selection_index, unpack(ammo_info))
				end
			end
			local peer_carry_data = managers.player:get_synced_carry(peer_id)
			if peer_carry_data then
				self:set_teammate_carry_info(i, peer_carry_data.carry_id, managers.loot:get_real_value(peer_carry_data.carry_id, peer_carry_data.multiplier))
			end
			
			break
		end
	end
	
	self:arrange_teammate_panels()
	
	return ORIGINAL_FUNCTIONS["add_teammate_panel"](self, character_name, player_name, ai, peer_id, ...)
end

function HUDManager:remove_teammate_panel(id, ...)
	if id == HUDManager.PLAYER_PANEL then
		printf("REMOVE PLAYER PANEL\n")
		self:clear_teammate_special_equipments(id)	--Check if this is leftover from previous player on join
	else
		self._teammate_panels_custom[id]:remove_panel()
		printf("HUDManager: REMOVE PANEL %s\n", tostring(id))
		self:arrange_teammate_panels()
	end
	
	return ORIGINAL_FUNCTIONS["remove_teammate_panel"](self, id, ...)
end

function HUDManager:add_weapon(data, ...)
	local wbase = data.unit:base()
	
	self:set_teammate_weapon(HUDManager.PLAYER_PANEL, data.inventory_index, wbase.name_id, wbase:got_silencer())
	
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
	
	return ORIGINAL_FUNCTIONS["add_weapon"](self, data, ...)
end


function HUDManager:set_teammate_ammo_amount(i, index, mag_max, mag_current, total_current, total_max, ...)
	self._teammate_panel_data[i]["ammo_amount"] = self._teammate_panel_data[i]["ammo_amount"] or {}
	self._teammate_panel_data[i]["ammo_amount"][index] = {
		mag_max = mag_max, 
		mag_current = mag_current, 
		total_current = total_current, 
		total_max = total_max,
	}
	self:teammate_info_callback(i, "ammo_amount", index, self._teammate_panel_data[i]["ammo_amount"][index])
	
	return self:call_original_function("set_teammate_ammo_amount", i, index, mag_max, mag_current, total_current, total_max, ...)
end

function HUDManager:set_teammate_weapon_firemode(i, index, firemode, ...)
	self._teammate_panel_data[i]["fire_mode"] = self._teammate_panel_data[i]["fire_mode"] or {}
	self._teammate_panel_data[i]["fire_mode"][index] = firemode
	self:teammate_info_callback(i, "fire_mode", index, firemode)
	
	return self:call_original_function("set_teammate_weapon_firemode", i, ...)
end

function HUDManager:_set_teammate_weapon_selected(i, index, ...)
	self._teammate_panel_data[i]["weapon_selected"] = index
	self:teammate_info_callback(i, "weapon_selected", index)
	
	return self:call_original_function("_set_teammate_weapon_selected", i, ...)
end

function HUDManager:set_deployable_equipment(i, data, ...)
	self._teammate_panel_data[i]["deployable"] = data
	self:teammate_info_callback(i, "deployable", data)
	
	return self:call_original_function("set_deployable_equipment", i, data, ...)
end

function HUDManager:set_teammate_deployable_equipment_amount(i, index, data, ...)
	self._teammate_panel_data[i]["deployable"].amount = data.amount
	self:teammate_info_callback(i, "deployable_amount", data.amount)
	
	return self:call_original_function("set_teammate_deployable_equipment_amount", i, index, data, ...)
end

function HUDManager:set_teammate_grenades(i, data, ...)
	self._teammate_panel_data[i]["throwable"] = data
	self:teammate_info_callback(i, "throwable", data)
	
	return self:call_original_function("set_teammate_grenades", i, data, ...)
end

function HUDManager:set_teammate_grenades_amount(i, data, ...)
	self._teammate_panel_data[i]["throwable"].amount = data.amount
	self:teammate_info_callback(i, "throwable_amount", data.amount)
	
	return self:call_original_function("set_teammate_grenades_amount", i, data, ...)
end	

function HUDManager:set_cable_tie(i, data, ...)
	self._teammate_panel_data[i]["cable_tie"] = data
	self:teammate_info_callback(i, "cable_tie", data)

	return self:call_original_function("set_cable_tie", i, data, ...)
end

function HUDManager:set_cable_ties_amount(i, amount, ...)
	self._teammate_panel_data[i]["cable_tie"].amount = amount
	self:teammate_info_callback(i, "cable_tie_amount", amount)

	return self:call_original_function("set_cable_ties_amount", i, amount, ...)
end
	
function HUDManager:set_teammate_condition(i, icon_data, text, ...)
	self._teammate_panel_data[i]["condition"] = icon_data
	self:teammate_info_callback(i, "condition", icon_data)

	return self:call_original_function("set_teammate_condition", i, icon_data, text, ...)
end

function HUDManager:start_teammate_timer(i, time, ...)
	self:teammate_info_callback(i, "start_timer", time)
	
	return self:call_original_function("start_teammate_timer", i, time, ...)
end

function HUDManager:pause_teammate_timer(i, pause, ...)
	self:teammate_info_callback(i, "pause_timer", pause)
	
	return self:call_original_function("pause_teammate_timer", i, pause, ...)
end

function HUDManager:stop_teammate_timer(i, ...)
	self:teammate_info_callback(i, "stop_timer")
	
	return self:call_original_function("stop_teammate_timer", i, ...)
end
	
function HUDManager:add_teammate_special_equipment(i, data, ...)
	self._teammate_panel_data[i]["special_equipment"] = self._teammate_panel_data[i]["special_equipment"] or {}
	self._teammate_panel_data[i]["special_equipment"][data.id] = { icon = data.icon, amount = data.amount }
	self:teammate_info_callback(i, "add_special_equipment", data.id, self._teammate_panel_data[i]["special_equipment"][data.id])
	
	return self:call_original_function("add_teammate_special_equipment", i, data, ...)
end

function HUDManager:remove_teammate_special_equipment(i, id, ...)
	self._teammate_panel_data[i]["special_equipment"][id] = nil
	self:teammate_info_callback(i, "remove_special_equipment", id)
	
	return self:call_original_function("remove_teammate_special_equipment", i, id, ...)
end

function HUDManager:set_teammate_special_equipment_amount(i, id, amount, ...)
	self._teammate_panel_data[i]["special_equipment"][id] = nil
	self:teammate_info_callback(i, "set_special_equipment_amount", id, amount)
	
	return self:call_original_function("set_teammate_special_equipment_amount", i, id, amount, ...)
end

function HUDManager:clear_player_special_equipments(...)
	self:clear_teammate_special_equipments(HUDManager.PLAYER_PANEL)
	return self:call_original_function("clear_player_special_equipments",  ...)
end
	
function HUDManager:set_teammate_health(i, data, ...)
	self._teammate_panel_data[i]["health"] = self._teammate_panel_data[i]["health"] or {}
	self._teammate_panel_data[i]["health"].current = data.current
	self._teammate_panel_data[i]["health"].total = data.total
	self:teammate_info_callback(i, "health", self._teammate_panel_data[i]["health"])
	
	return self:call_original_function("set_teammate_health", i, data, ...)
end

function HUDManager:set_stored_health(stored_health_ratio, ...)
	local i = HUDManager.PLAYER_PANEL
	self._teammate_panel_data[i]["health"] = self._teammate_panel_data[i]["health"] or {}
	self._teammate_panel_data[i]["health"].stored_health = stored_health_ratio
	self:teammate_info_callback(i, "stored_health", stored_health_ratio)
	
	return self:call_original_function("set_stored_health", stored_health_ratio, ...)
end

function HUDManager:set_stored_health_max(stored_health_ratio, ...)
	local i = HUDManager.PLAYER_PANEL
	self._teammate_panel_data[i]["health"] = self._teammate_panel_data[i]["health"] or {}
	self._teammate_panel_data[i]["health"].stored_health_max = stored_health_ratio
	self:teammate_info_callback(i, "stored_health_max", stored_health_ratio)
	
	return self:call_original_function("set_stored_health_max", stored_health_ratio, ...)
end
	
function HUDManager:set_teammate_armor(i, data, ...)
	self._teammate_panel_data[i]["armor"] = data
	self:teammate_info_callback(i, "armor", data)
	
	return self:call_original_function("set_teammate_armor", i, data, ...)
end
	
function HUDManager:set_stamina_value(value, ...)
	local i = HUDManager.PLAYER_PANEL
	self._teammate_panel_data[i]["stamina"] = self._teammate_panel_data[i]["stamina"] or {}
	self._teammate_panel_data[i]["stamina"].current = value
	self:teammate_info_callback(i, "stamina", self._teammate_panel_data[i]["stamina"])

	return self:call_original_function("set_stamina_value", value, ...)
end

function HUDManager:set_max_stamina(value, ...)
	local i = HUDManager.PLAYER_PANEL
	self._teammate_panel_data[i]["stamina"] = self._teammate_panel_data[i]["stamina"] or {}
	self._teammate_panel_data[i]["stamina"].total = value
	self:teammate_info_callback(i, "max_stamina", self._teammate_panel_data[i]["stamina"])
	
	return self:call_original_function("set_max_stamina", value, ...)
end

function HUDManager:set_teammate_custom_radial(i, data, ...)
	self._teammate_panel_data[i]["custom_radial"] = data
	self:teammate_info_callback(i, "custom_radial_progress", data)
	
	return self:call_original_function("set_teammate_custom_radial", i, data, ...)
end

function HUDManager:set_teammate_callsign(i, id, ...)
	self._teammate_panel_data[i]["callsign"] = id
	self:teammate_info_callback(i, "callsign", id)
	
	return self:call_original_function("set_teammate_callsign", i, id, ...)
end

function HUDManager:set_mugshot_voice(id, active, ...)
	local panel_id
	for _, data in pairs(managers.criminals:characters()) do
		if data.data.mugshot_id == id then
			panel_id = data.data.panel_id
			break
		end
	end

	if panel_id then
		self:teammate_info_callback(panel_id, "voice_com", active)
	end
	
	return self:call_original_function("set_mugshot_voice", id, active, ...)
end

function HUDManager:set_teammate_name(i, name, ...)
	self._teammate_panel_data[i]["name"] = name
	self:teammate_info_callback(i, "name", name)
	
	return self:call_original_function("set_teammate_name", i, name, ...)
end

function HUDManager:set_info_meter(i, data, ...)
	i = i or HUDManager.PLAYER_PANEL
	self._teammate_panel_data[i]["maniac_stacks"] = data
	self:teammate_info_callback(i, "maniac_stacks", data)
	
	return self:call_original_function("set_info_meter", i, data, ...)
end

function HUDManager:set_absorb_active(i, absorb_amount, ...)
	i = i or HUDManager.PLAYER_PANEL
	self._teammate_panel_data[i]["maniac_absorb"] = absorb_amount
	self:teammate_info_callback(i, "maniac_absorb", absorb_amount)
	
	return self:call_original_function("set_absorb_active", i, absorb_amount, ...)
end



--NEW FUNCTIONS
function HUDManager:arrange_teammate_panels()
	local MARGIN = 5
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
	local hud_panel = hud.panel
	local teammate_height = 0
	
	for i, panel in ipairs(self._teammate_panels_custom) do
		if self._teammate_panels_custom[i]:visible() then
			if i == HUDManager.PLAYER_PANEL then
				self._teammate_panels_custom[i]:set_center(hud_panel:w() / 2, 0)
				self._teammate_panels_custom[i]:set_bottom(hud_panel:h())
			else
				self._teammate_panels_custom[i]:set_left(0)
				self._teammate_panels_custom[i]:set_bottom(hud_panel:h() - teammate_height)
				teammate_height = teammate_height + self._teammate_panels_custom[i]:h() + MARGIN
			end
		end
	end
end
	
function HUDManager:set_teammate_weapon(i, index, id, silencer)
	self._teammate_panel_data[i]["weapon"] = self._teammate_panel_data[i]["weapon"] or {}
	self._teammate_panel_data[i]["weapon"][index] = { id = id, silencer = silencer }
	self:teammate_info_callback(i, "weapon", index, self._teammate_panel_data[i]["weapon"][index])
end

function HUDManager:set_teammate_available_fire_modes(i, index, modes)
	self._teammate_panel_data[i]["available_fire_modes"] = self._teammate_panel_data[i]["available_fire_modes"] or {}
	self._teammate_panel_data[i]["available_fire_modes"][index] = modes
	self:teammate_info_callback(i, "available_fire_modes", index, modes)
end

function HUDManager:set_teammate_weapon_firemode_burst(selection_index)
	self:set_teammate_weapon_firemode(HUDManager.PLAYER_PANEL, selection_index, "burst")
end

function HUDManager:clear_teammate_special_equipments(i)
	self._teammate_panel_data[i]["special_equipment"] = {}
	self:teammate_info_callback(i, "clear_special_equipment")
end

function HUDManager:_parse_outfit_string(panel_id, peer_id)
	--local outfit = managers.blackmarket:unpack_outfit_from_string(managers.blackmarket:outfit_string())) --LOCAL PLAYER
	local peer = managers.network:session():peer(peer_id)
	local outfit = peer and peer:blackmarket_outfit()
	
	if not outfit then
		printf("ERROR (_parse_outfit_string): NO OUTFIT STRING FOR ID %s\n", tostring(peer_id))
		return
	end
	
	self._weapon_blueprints = {}
	for selection, data in ipairs({ outfit.secondary, outfit.primary }) do
		local weapon_id = managers.weapon_factory:get_weapon_id_by_factory_id(data.factory_id)
		local silencer = managers.weapon_factory:has_perk("silencer", data.factory_id, data.blueprint)
		self:set_teammate_weapon(panel_id, selection, weapon_id, silencer)
	end
	
	--self:_set_armor(outfit.armor)
	--self:_set_melee(outfit.melee_weapon)
	--self:_set_deployable_id(outfit.deployable)
	--self:_set_throwable(outfit.grenade)
	--self:_set_skills(table.map_copy(outfit.skills.skills))
	--self:_set_specialization(table.map_copy(outfit.skills.specializations))
end


function HUDManager:call_original_function(id, ...)
	if CriminalsManager.MAX_NR_CRIMINALS <= 4 then
		return ORIGINAL_FUNCTIONS[id](self, ...)
	end
end

function HUDManager:teammate_info_callback(id, ...)
	if self._teammate_info_listeners[id] then
		self._teammate_info_listeners[id](...)
	end
end

function HUDManager:register_teammate_info_listener(id, clbk)
	self._teammate_info_listeners[id] = clbk
end

function HUDManager:unregister_teammate_info_listener(id)
	self._teammate_info_listeners[id] = nil
end






function HUDManager:mark_cheater(peer_id, ...)
	for _, panel in ipairs(self._teammate_panels_custom) do
		if panel:peer_id() == peer_id then
			panel:set_cheater(true)
			break
		end
	end
	
	return self:call_original_function("mark_cheater", peer_id, ...)
end
























if false then
	
	HUDPlayerPanel.SHOW_AMMO = true	--Show the mag/total ammo count of both weapons
	HUDPlayerPanel.SHOW_FIRE_MODE = true	--Show the current fire mode of both weapons
	HUDPlayerPanel.SHOW_EQUIPMENT = true	--Show deployables, cable ties and throwables
	HUDPlayerPanel.SHOW_SPECIAL_EQUIPMENT = true	--Show special equipment pickups
	HUDPlayerPanel.SHOW_CARRY_INFO = true	--Show carried bags
	
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
		
	function HUDTeamPanelBase:_set_rank(level, infamy)
		self._player_data.level = { level, infamy }
		managers.hud:update_custom_stats("rank", self._id, level, infamy)
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
	

	
	HUDManager.CUSTOM_TEAMMATE_PANEL = true	--External flag
	HUDManager.TEAM_PANEL_SPACING = 1	--Spacing between team mate panels

	function HUDManager:set_teammate_carry_info(i, ...)
		self._teammate_panels_custom[i]:set_carry_info(...)
		return self:call_original_function("set_teammate_carry_info", i, ...)
	end
	
	function HUDManager:remove_teammate_carry_info(i, ...)
		self._teammate_panels_custom[i]:remove_carry_info()
		return self:call_original_function("remove_teammate_carry_info", i, ...)
	end
	
	function HUDManager:teammate_progress(peer_id, type_index, ...)
		local character_data = managers.criminals:character_data_by_peer_id(peer_id)
		if character_data then
			self._teammate_panels_custom[character_data.panel_id]:teammate_progress(...)
		end
		
		return self:call_original_function("teammate_progress", peer_id, type_index, ...)
	end

end
