--Don't use this if you're using the custom HUD since it has native support already.

if RequiredScript == "lib/managers/hudmanagerpd2" then

	local set_stamina_value_original = HUDManager.set_stamina_value
	local set_max_stamina_original = HUDManager.set_max_stamina
	
	function HUDManager:set_stamina_value(value, ...)
		self._teammate_panels[HUDManager.PLAYER_PANEL]:set_current_stamina(value)
		return set_stamina_value_original(self, value, ...)
	end

	function HUDManager:set_max_stamina(value, ...)
		self._teammate_panels[HUDManager.PLAYER_PANEL]:set_max_stamina(value)
		return set_max_stamina_original(self, value, ...)
	end

elseif RequiredScript == "lib/managers/hud/hudteammate" then

	local init_original = HUDTeammate.init

	function HUDTeammate:init(i, ...)
		init_original(self, i, ...)
		
		if i == HUDManager.PLAYER_PANEL and not HUDManager.CUSTOM_TEAMMATE_PANEL then
			self:_create_stamina_circle()
		end
	end
	
	function HUDTeammate:_create_stamina_circle()
		local radial_health_panel = self._panel:child("player"):child("radial_health_panel")
		
		self._stamina_bar = radial_health_panel:bitmap({
			name = "radial_stamina",
			texture = "guis/textures/pd2/hud_shield",
			texture_rect = { 64, 0, -64, 64 },
			render_template = "VertexColorTexturedRadial",
			blend_mode = "add",
			alpha = 1,
			w = radial_health_panel:w() * 0.5,
			h = radial_health_panel:h() * 0.5,
			layer = 5
		})
		self._stamina_bar:set_color(Color(1, 1, 0, 0))
		self._stamina_bar:set_center(radial_health_panel:child("radial_health"):center())
		
		self._stamina_line = radial_health_panel:rect({
			color = Color.red,
			w = radial_health_panel:w() * 0.10,
			h = 1,
			layer = 10,
		})
		self._stamina_line:set_center(radial_health_panel:child("radial_health"):center())
	end

	function HUDTeammate:set_max_stamina(value)
		self._max_stamina = value
		local w = self._stamina_bar:w()
		local threshold = tweak_data.player.movement_state.stamina.MIN_STAMINA_THRESHOLD
		local angle = 360 * (1 - threshold/self._max_stamina) - 90
		local x = 0.5 * w * math.cos(angle) + w * 0.5 + self._stamina_bar:x()
		local y = 0.5 * w * math.sin(angle) + w * 0.5 + self._stamina_bar:y()
		self._stamina_line:set_x(x)
		self._stamina_line:set_y(y)
		self._stamina_line:set_rotation(angle)
	end

	function HUDTeammate:set_current_stamina(value)
		self._stamina_bar:set_color(Color(1, value/self._max_stamina, 0, 0))
	end
	
end