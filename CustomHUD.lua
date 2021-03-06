--This file is mostly legacy stuff, things to be rewritten and ported into new version. It can still be used safely, but is optional and may not be the best choice


if RequiredScript == "lib/managers/hud/hudassaultcorner" then

	local init_original = HUDAssaultCorner.init

	function HUDAssaultCorner:init(...)
		init_original(self, ...)
		
		local assault_panel = self._hud_panel:child("assault_panel")
		assault_panel:set_right(self._hud_panel:w() / 2 + 133)
		local buffs_panel = self._hud_panel:child("buffs_panel")
		buffs_panel:set_x(assault_panel:left() + self._bg_box:left() - 3 - 200)
		
		local point_of_no_return_panel = self._hud_panel:child("point_of_no_return_panel")
		point_of_no_return_panel:set_right(self._hud_panel:w() / 2 + 133)
		
		local casing_panel = self._hud_panel:child("casing_panel")
		casing_panel:set_right(self._hud_panel:w() / 2 + 133)
		
		local hostages_panel = self._hud_panel:child("hostages_panel")
		hostages_panel:set_alpha(0)
	end

end
	
if RequiredScript == "lib/managers/hud/hudobjectives" then
	
	HUDObjectives._TEXT_MARGIN = 8

	function HUDObjectives:init(hud)
		if hud.panel:child("objectives_panel") then
			hud.panel:remove(self._panel:child("objectives_panel"))
		end

		self._panel = hud.panel:panel({
			visible = false,
			name = "objectives_panel",
			h = 100,
			w = 500,
			x = 60,
			valign = "top"
		})
			
		self._bg_box = HUDBGBox_create(self._panel, {
			w = 500,
			h = 38,
		})
		
		self._objective_text = self._bg_box:text({
			name = "objective_text",
			visible = false,
			layer = 2,
			color = Color.white,
			text = "",
			font_size = tweak_data.hud.active_objective_title_font_size,
			font = tweak_data.hud.medium_font_noshadow,
			align = "left",
			vertical = "center",
			w = self._bg_box:w(),
			x = HUDObjectives._TEXT_MARGIN
		})
		
		self._amount_text = self._bg_box:text({
			name = "amount_text",
			visible = false,
			layer = 2,
			color = Color.white,
			text = "",
			font_size = tweak_data.hud.active_objective_title_font_size,
			font = tweak_data.hud.medium_font_noshadow,
			align = "left",
			vertical = "center",
			w = self._bg_box:w(),
			x = HUDObjectives._TEXT_MARGIN
		})
	end

	function HUDObjectives:activate_objective(data)
		self._active_objective_id = data.id
		
		self._panel:set_visible(true)
		self._objective_text:set_text(utf8.to_upper(data.text))
		self._objective_text:set_visible(true)
		self._amount_text:set_visible(false)
		
		local width = self:_get_text_width(self._objective_text)
		
		if data.amount then
			self:update_amount_objective(data)
			self._amount_text:set_left(width + HUDObjectives._TEXT_MARGIN)
			width = width + self:_get_text_width(self._amount_text)
		else
			self._amount_text:set_text("")
		end

		self._bg_box:set_w(HUDObjectives._TEXT_MARGIN * 2 + width)
		self._bg_box:stop()
		--self._amount_text:animate(callback(self, self, "_animate_new_objective"))
		--self._objective_text:animate(callback(self, self, "_animate_new_objective"))
		self._bg_box:animate(callback(self, self, "_animate_update_objective"))
	end

	function HUDObjectives:update_amount_objective(data)
		if data.id ~= self._active_objective_id then
			return
		end

		self._amount_text:set_visible(true)
		self._amount_text:set_text(": " .. (data.current_amount or 0) .. "/" .. data.amount)
		self._amount_text:set_x(self:_get_text_width(self._objective_text) + HUDObjectives._TEXT_MARGIN)
		self._bg_box:set_w(HUDObjectives._TEXT_MARGIN * 2 + self:_get_text_width(self._objective_text) + self:_get_text_width(self._amount_text))
		self._bg_box:stop()
		self._bg_box:animate(callback(self, self, "_animate_update_objective"))
	end

	function HUDObjectives:remind_objective(id)
		if id ~= self._active_objective_id then
			return
		end
		
		self._bg_box:stop()
		self._bg_box:animate(callback(self, self, "_animate_update_objective"))
	end

	function HUDObjectives:complete_objective(data)
		if data.id ~= self._active_objective_id then
			return
		end

		self._amount_text:set_visible(false)
		self._objective_text:set_visible(false)
		self._panel:set_visible(false)
		self._bg_box:set_w(0)
	end

	function HUDObjectives:_animate_new_objective(object)
		local TOTAL_T = 2
		local t = TOTAL_T
		object:set_color(Color(1, 1, 1, 1))
		while t > 0 do
			local dt = coroutine.yield()
			t = t - dt
			object:set_color(Color(1, 1 - (0.5 * math.sin(t * 360) + 0.5), 1, 1 - (0.5 * math.sin(t * 360) + 0.5)))
		end
		object:set_color(Color(1, 1, 1, 1))
	end

	function HUDObjectives:_animate_update_objective(object)
		local TOTAL_T = 2
		local t = TOTAL_T
		object:set_y(0)
		while t > 0 do
			local dt = coroutine.yield()
			t = t - dt
			object:set_y(math.round((1 + math.sin((TOTAL_T - t) * 450 * 2)) * (12 * (t / TOTAL_T))))
		end
		object:set_y(0)
	end

	function HUDObjectives:_get_text_width(obj)
		local _, _, w, _ = obj:text_rect()
		return w
	end	

end	
	
if RequiredScript == "lib/managers/hud/hudheisttimer" then
	
	function HUDHeistTimer:init(hud, tweak_hud, ...)
		self._enabled = not tweak_hud.no_timer
	
		self._hud_panel = hud.panel
		if self._hud_panel:child("heist_timer_panel") then
			self._hud_panel:remove(self._hud_panel:child("heist_timer_panel"))
		end
		
		self._heist_timer_panel = self._hud_panel:panel({
			visible = self._enabled and true or false,
			name = "heist_timer_panel",
			h = 40,
			w = 50,
			valign = "top",
			layer = 0
		})
		self._timer_text = self._heist_timer_panel:text({
			name = "timer_text",
			text = "00:00",
			font_size = 28,
			font = tweak_data.hud.medium_font_noshadow,
			color = Color.white,
			align = "center",
			vertical = "center",
			layer = 1,
			wrap = false,
			word_wrap = false
		})
		self._last_time = 0
	end
	
end
