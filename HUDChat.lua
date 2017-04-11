if not CustomHUDMenu.settings.enable_chat then return end

if RequiredScript == "lib/managers/hudmanagerpd2" then

	local setup_endscreen_hud_original = HUDManager.setup_endscreen_hud
	
	function HUDManager:_set_custom_hud_chat_offset(offset)
		self._hud_chat_ingame:set_offset(offset)
	end
	
	function HUDManager:setup_endscreen_hud(...)
		self._hud_chat_ingame:disconnect_mouse()
		return setup_endscreen_hud_original(self, ...)
	end
	
	function HUDManager:change_custom_chat_settings(...)
		self._hud_chat_ingame:change_settings(...)
	end
	
end

if RequiredScript == "lib/managers/hud/hudchat" then
	
	local enter_key_callback_original = HUDChat.enter_key_callback
	local esc_key_callback_original = HUDChat.esc_key_callback
	local _on_focus_original = HUDChat._on_focus
	local _loose_focus_original = HUDChat._loose_focus
	
	function HUDChat:init(ws, hud)
		local fullscreen = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN_PD2)
		
		self._settings = CustomHUDMenu.settings.hudchat
		
		self._x_offset = (fullscreen.panel:w() - hud.panel:w()) / 2
		self._y_offset = (fullscreen.panel:h() - hud.panel:h()) / 2
		self._esc_callback = callback(self, self, "esc_key_callback")
		self._enter_callback = callback(self, self, "enter_key_callback")
		self._typing_callback = 0
		self._skip_first = false
		self._messages = {}
		self._current_line_offset = 0
		self._total_message_lines = 0
		self._current_input_lines = 1
		self._ws = ws
		self._parent = hud.panel
		self:set_channel_id(ChatManager.GAME)
		
		self._panel = self._parent:panel({
			name = "chat_panel",
			h = self._settings.line_height * (self._settings.max_output_lines + 1),
			w = self._settings.width,
		})
		
		self:move(self._settings.x_offset, self._settings.y_offset)
		
		self:_create_output_panel()
		self:_create_input_panel()
		self:_layout_output_panel()
	end

	function HUDChat:_create_input_panel()
		if self._panel:child("input_panel") then
			self._panel:remove(self._panel:child("input_panel"))
		end
	
		self._input_panel = self._panel:panel({
			name = "input_panel",
			alpha = 0,
			h = self._settings.line_height,
			w = self._panel:w(),
			layer = 1,
		})
		local focus_indicator = self._input_panel:rect({
			name = "focus_indicator",
			visible = false,
			color = Color.white:with_alpha(0.2),
			layer = 0
		})	
		local gradient = self._input_panel:gradient({	--TODO: Why won't this POS behave?
			name = "input_bg",
			visible = false,	--TODO: Remove
			alpha = 0,	--TODO: Remove
			gradient_points = { 0, Color.white:with_alpha(0), 0.2, Color.white:with_alpha(0.25), 1, Color.white:with_alpha(0) },
			layer = -1,
			valign = "grow",
			blend_mode = "sub",
		})
		local bg_simple = self._input_panel:rect({
			name = "input_bg_simple",
			alpha = 0.5,
			color = Color.black,
			layer = -1,
			h = self._settings.max_input_lines * self._settings.line_height,--self._input_panel:h(),
			w = self._input_panel:w(),
		})
		
		local input_prompt = self._input_panel:text({
			name = "input_prompt",
			text = utf8.to_upper(managers.localization:text("debug_chat_say")),
			font = tweak_data.menu.pd2_small_font,
			font_size = self._settings.line_height * 0.95,
			h = self._settings.line_height,
			align = "left",
			halign = "left",
			vertical = "center",
			hvertical = "center",
			blend_mode = "normal",
			color = Color.white,
			layer = 1
		})
		local _, _, w, h = input_prompt:text_rect()
		input_prompt:set_w(w)
		input_prompt:set_left(0)
		
		local input_text = self._input_panel:text({
			name = "input_text",
			text = "",
			font = tweak_data.menu.pd2_small_font,
			font_size = self._settings.line_height * 0.95,
			h = self._settings.line_height,
			w = self._input_panel:w() - input_prompt:w() - 4,
			align = "left",
			halign = "left",
			vertical = "center",
			hvertical = "center",
			blend_mode = "normal",
			color = Color.white,
			layer = 1,
			wrap = true,
			word_wrap = false
		})
		input_text:set_right(self._input_panel:w())
		
		local caret = self._input_panel:rect({
			name = "caret",
			layer = 2,
			color = Color(0.05, 1, 1, 1)
		})
		
		focus_indicator:set_shape(input_text:shape())
		self._input_panel:set_bottom(self._panel:h())
	end

	function HUDChat:_create_output_panel()
		if self._panel:child("output_panel") then
			self._panel:remove(self._panel:child("output_panel"))
		end
		
		local output_panel = self._panel:panel({
			name = "output_panel",
			h = 0,
			w = self._panel:w(),
			layer = 1,
		})
		local scroll_bar_bg = output_panel:rect({
			name = "scroll_bar_bg",
			color = Color.black,
			layer = -1,
			alpha = 0.35,
			visible = false,
			blend_mode = "normal",
			w = 8,
			h = self._settings.line_height * self._settings.max_output_lines,
		})
		scroll_bar_bg:set_right(output_panel:w())
		
		local scroll_bar_up = output_panel:bitmap({
			name = "scroll_bar_up",
			texture = "guis/textures/pd2/scrollbar_arrows",
			texture_rect = { 1, 1, 9, 10 },
			w = scroll_bar_bg:w(),
			h = scroll_bar_bg:w(),
			visible = false,
			blend_mode = "add",
			color = Color.white,
		})
		scroll_bar_up:set_right(output_panel:w())
		
		local scroll_bar_down = output_panel:bitmap({
			name = "scroll_bar_down",
			texture = "guis/textures/pd2/scrollbar_arrows",
			texture_rect = { 1, 1, 9, 10 },
			w = scroll_bar_bg:w(),
			h = scroll_bar_bg:w(),
			visible = false,
			blend_mode = "add",
			color = Color.white,
			rotation = 180,
		})
		scroll_bar_down:set_right(output_panel:w())
		scroll_bar_down:set_bottom(output_panel:h())
		
		local scroll_bar_position = output_panel:rect({
			name = "scroll_bar_position",
			color = Color.white,
			alpha = 0.8,
			visible = false,
			blend_mode = "normal",
			w = scroll_bar_bg:w() * 0.6,
			h = 3,
		})
		scroll_bar_position:set_center_x(scroll_bar_bg:center_x())
		
		output_panel:gradient({
			name = "output_bg",
			--gradient_points = { 0, Color.white:with_alpha(0), 0.2, Color.white:with_alpha(0.25), 1, Color.white:with_alpha(0) },
			--gradient_points = { 0, Color.white:with_alpha(0.4), 0.2, Color.white:with_alpha(0.3), 1, Color.white:with_alpha(0.2) },
			gradient_points = { 0, Color.white:with_alpha(0.3), 0.3, Color.white:with_alpha(0.1), 0.5, Color.white:with_alpha(0.2) , 0.7, Color.white:with_alpha(0.1), 1, Color.white:with_alpha(0.3) },
			layer = -1,
			valign = "grow",
			blend_mode = "sub",
			w = output_panel:w() - scroll_bar_bg:w() ,
		})
		
		output_panel:set_bottom(self._panel:h())
	end

	function HUDChat:_layout_output_panel()
		local output_panel = self._panel:child("output_panel")
		
		output_panel:set_h(self._settings.line_height * math.min(self._settings.max_output_lines, self._total_message_lines))
		if self._total_message_lines > self._settings.max_output_lines then
			local scroll_bar_bg = output_panel:child("scroll_bar_bg")
			local scroll_bar_up = output_panel:child("scroll_bar_up")
			local scroll_bar_down = output_panel:child("scroll_bar_down")
			local scroll_bar_position = output_panel:child("scroll_bar_position")
			
			scroll_bar_bg:show()
			scroll_bar_up:show()
			scroll_bar_down:show()
			scroll_bar_position:show()
			scroll_bar_down:set_bottom(output_panel:h())
			
			local positon_height_area = scroll_bar_bg:h() - scroll_bar_up:h() - scroll_bar_down:h() - 4
			scroll_bar_position:set_h(math.max((self._settings.max_output_lines / self._total_message_lines) * positon_height_area, 3))
			scroll_bar_position:set_center_y((1 - self._current_line_offset / self._total_message_lines) * positon_height_area + scroll_bar_up:h() + 2 - scroll_bar_position:h() / 2)
		end
		output_panel:set_bottom(self._input_panel:top())

		local y = -self._current_line_offset * self._settings.line_height
		for i = #self._messages, 1, -1 do
			local msg = self._messages[i]
			msg.panel:set_bottom(output_panel:h() - y)
			y = y + msg.panel:h()
		end
	end
	
	function HUDChat:change_settings(settings)
		self._settings = settings
		self:move(self._settings.x_offset, self._settings.y_offset)
	end
	
	function HUDChat:move(xr, yr)
		local x = (self._parent:w() - self._panel:w()) * xr/100
		local y = (self._parent:h() - self._panel:h()) * yr/100
		self._panel:set_position(x, y)
	end
	
	function HUDChat:receive_message(name, message, color, icon)
		local output_panel = self._panel:child("output_panel")
		local scroll_bar_bg = output_panel:child("scroll_bar_bg")
		local x_offset = 0
		
		local msg_panel = output_panel:panel({
			name = "msg_" .. tostring(#self._messages),
			w = output_panel:w() - scroll_bar_bg:w(),
		})
		local msg_panel_bg = msg_panel:rect({
			name = "bg",
			alpha = 0.25,
			color = color,
			w = msg_panel:w(),
		})

		local heisttime = managers.game_play_central and managers.game_play_central:get_heist_timer() or 0
		local hours = math.floor(heisttime / (60*60))
		local minutes = math.floor(heisttime / 60) % 60
		local seconds = math.floor(heisttime % 60)
		local time_format_text
		if hours > 0 then
			time_format_text = string.format("%d:%02d:%02d", hours, minutes, seconds)
		else
			time_format_text = string.format("%d:%02d", minutes, seconds)
		end
		
		local time_text = msg_panel:text({
			name = "time",
			text = time_format_text,
			font = tweak_data.menu.pd2_small_font,
			font_size = self._settings.line_height * 0.95,
			h = self._settings.line_height,
			w = msg_panel:w(),
			x = x_offset,
			align = "left",
			halign = "left",
			vertical = "top",
			hvertical = "top",
			blend_mode = "normal",
			wrap = true,
			word_wrap = true,
			color = Color.white,
			layer = 1
		})
		local _, _, w, _ = time_text:text_rect()
		x_offset = x_offset + w + 2
		
		if icon then
			local icon_texture, icon_texture_rect = tweak_data.hud_icons:get_icon_data(icon)
			local icon_bitmap = msg_panel:bitmap({
				name = "icon",
				texture = icon_texture,
				texture_rect = icon_texture_rect,
				color = color,
				h = self._settings.line_height * 0.85,
				w = self._settings.line_height * 0.85,
				x = x_offset,
				layer = 1,
			})
			icon_bitmap:set_center_y(self._settings.line_height / 2)
			x_offset = x_offset + icon_bitmap:w() + 1
		end
		
		local message_text = msg_panel:text({
			name = "msg",
			text = name .. ": " .. message,
			font = tweak_data.menu.pd2_small_font,
			font_size = self._settings.line_height * 0.95,
			w = msg_panel:w() - x_offset,
			x = x_offset,
			align = "left",
			halign = "left",
			vertical = "top",
			hvertical = "top",
			blend_mode = "normal",
			wrap = true,
			word_wrap = true,
			color = Color.white,
			layer = 1
		})
		local no_lines = message_text:number_of_lines()
		
		message_text:set_range_color(0, utf8.len(name) + 1, color)
		message_text:set_h(self._settings.line_height * no_lines)
		message_text:set_kern(message_text:kern())
		msg_panel:set_h(self._settings.line_height * no_lines)
		msg_panel_bg:set_h(self._settings.line_height * no_lines)
		
		self._total_message_lines = self._total_message_lines + no_lines
		table.insert(self._messages, { panel = msg_panel, name = name, lines = no_lines })
		
		self:_layout_output_panel()
		if not self._focus then
			local output_panel = self._panel:child("output_panel")
			output_panel:stop()
			output_panel:animate(callback(self, self, "_animate_show_component"), output_panel:alpha())
			output_panel:animate(callback(self, self, "_animate_fade_output"))
		end
	end

	function HUDChat:enter_text(o, s)
		if managers.hud and managers.hud:showing_stats_screen() then
			return
		end
		if self._skip_first then
			self._skip_first = false
			return
		end
		local text = self._input_panel:child("input_text")
		if type(self._typing_callback) ~= "number" then
			self._typing_callback()
		end
		text:replace_text(s)
		
		local lbs = text:line_breaks()
		if #lbs <= self._settings.max_input_lines then
			self:_set_input_lines(#lbs)
		else
			local s = lbs[self._settings.max_input_lines + 1]
			local e = utf8.len(text:text())
			text:set_selection(s, e)
			text:replace_text("")
		end
		self:update_caret()
	end

	function HUDChat:enter_key_callback(...)
		enter_key_callback_original(self, ...)
		self:_set_input_lines(1)
		self:_set_line_offset(0)
	end

	function HUDChat:esc_key_callback(...)
		esc_key_callback_original(self, ...)
		self:_set_input_lines(1)
		self:_set_line_offset(0)
	end

	function HUDChat:_set_input_lines(no_lines)
		if no_lines ~= self._current_input_lines then
			no_lines = math.max(no_lines, 1)
			self._current_input_lines = no_lines
			self._input_panel:set_h(no_lines * self._settings.line_height)
			self._input_panel:child("input_text"):set_h(no_lines * self._settings.line_height)
			self._input_panel:set_bottom(self._panel:h())
			self._panel:child("output_panel"):set_bottom(self._input_panel:top())
		end
	end
	
	function HUDChat:set_offset(offset)
		self._panel:set_bottom(self._parent:h() - offset)
	end
	
	function HUDChat:update_key_down(o, k)
		wait(0.6)
		local text = self._input_panel:child("input_text")
		while self._key_pressed == k do
			local s, e = text:selection()
			local n = utf8.len(text:text())
			local d = math.abs(e - s)
			if self._key_pressed == Idstring("backspace") then
				if s == e and s > 0 then
					text:set_selection(s - 1, e)
				end
				text:replace_text("")
				self:_set_input_lines(#(text:line_breaks()))
				if not (utf8.len(text:text()) < 1) or type(self._esc_callback) ~= "number" then
				end
			elseif self._key_pressed == Idstring("delete") then
				if s == e and s < n then
					text:set_selection(s, e + 1)
				end
				text:replace_text("")
				self:_set_input_lines(#(text:line_breaks()))
				if not (utf8.len(text:text()) < 1) or type(self._esc_callback) ~= "number" then
				end
			elseif self._key_pressed == Idstring("left") then
				if s < e then
					text:set_selection(s, s)
				elseif s > 0 then
					text:set_selection(s - 1, s - 1)
				end
			elseif self._key_pressed == Idstring("right") then
				if s < e then
					text:set_selection(e, e)
				elseif s < n then
					text:set_selection(s + 1, s + 1)
				end
			elseif self._key_pressed == Idstring("up") then
				self:_change_line_offset(1)
			elseif self._key_pressed == Idstring("down") then
				self:_change_line_offset(-1)
			elseif self._key_pressed == Idstring("page up") then
				self:_change_line_offset(self._settings.max_output_lines - self._current_input_lines)
			elseif self._key_pressed == Idstring("page down") then
				self:_change_line_offset(-(self._settings.max_output_lines - self._current_input_lines))
			else
				self._key_pressed = false
			end
			self:update_caret()
			wait(0.03)
		end
	end

	function HUDChat:key_press(o, k)
		if self._skip_first then
			self._skip_first = false
			return
		end
		if not self._enter_text_set then
			self._input_panel:enter_text(callback(self, self, "enter_text"))
			self._enter_text_set = true
		end
		local text = self._input_panel:child("input_text")
		local s, e = text:selection()
		local n = utf8.len(text:text())
		local d = math.abs(e - s)
		self._key_pressed = k
		text:stop()
		text:animate(callback(self, self, "update_key_down"), k)
		if k == Idstring("backspace") then
			if s == e and s > 0 then
				text:set_selection(s - 1, e)
			end
			text:replace_text("")
			if not (utf8.len(text:text()) < 1) or type(self._esc_callback) ~= "number" then
			end
			self:_set_input_lines(#(text:line_breaks()))
		elseif k == Idstring("delete") then
			if s == e and s < n then
				text:set_selection(s, e + 1)
			end
			text:replace_text("")
			if not (utf8.len(text:text()) < 1) or type(self._esc_callback) ~= "number" then
			end
			self:_set_input_lines(#(text:line_breaks()))
		elseif k == Idstring("left") then
			if s < e then
				text:set_selection(s, s)
			elseif s > 0 then
				text:set_selection(s - 1, s - 1)
			end
		elseif k == Idstring("right") then
			if s < e then
				text:set_selection(e, e)
			elseif s < n then
				text:set_selection(s + 1, s + 1)
			end
		elseif self._key_pressed == Idstring("up") then
			self:_change_line_offset(1)
		elseif self._key_pressed == Idstring("down") then
			self:_change_line_offset(-1)
		elseif self._key_pressed == Idstring("page up") then
			self:_change_line_offset(self._settings.max_output_lines - self._current_input_lines)
		elseif self._key_pressed == Idstring("page down") then
			self:_change_line_offset(-(self._settings.max_output_lines - self._current_input_lines))
		elseif self._key_pressed == Idstring("end") then
			text:set_selection(n, n)
		elseif self._key_pressed == Idstring("home") then
			text:set_selection(0, 0)
		elseif k == Idstring("enter") then
			if type(self._enter_callback) ~= "number" then
				self._enter_callback()
			end
		elseif k == Idstring("esc") and type(self._esc_callback) ~= "number" then
			text:set_text("")
			text:set_selection(0, 0)
			self._esc_callback()
		end
		self:update_caret()
	end

	function HUDChat:_change_line_offset(diff)
		if diff ~= 0 then
			self:_set_line_offset(math.clamp(self._current_line_offset + diff, 0, math.max(self._total_message_lines - self._settings.max_output_lines + self._current_input_lines - 1, 0)))
		end
	end
	
	function HUDChat:_set_line_offset(offset)
		if self._current_line_offset ~= offset then
			self._current_line_offset = offset
			self:_layout_output_panel()
		end
	end

	function HUDChat:_on_focus(...)
		if not self._mouse_connected and self._settings.mouse_support then
			self:connect_mouse()
		end
		
		return _on_focus_original(self, ...)
	end
	
	function HUDChat:_loose_focus(...)
		if self._settings.mouse_support then
			self:disconnect_mouse()
		end
		
		return _loose_focus_original(self, ...)
	end
	
	function HUDChat:connect_mouse()
		self._mouse_connected = true
		
		managers.mouse_pointer:use_mouse({
			mouse_move = callback(self, self, "_mouse_move"),
			mouse_press = callback(self, self, "_mouse_press"),
			mouse_release = callback(self, self, "_mouse_release"),
			mouse_click = callback(self, self, "_mouse_click"),
			id = "ingame_chat_mouse",
		})
	end
	
	function HUDChat:disconnect_mouse()
		if self._mouse_connected then
			managers.mouse_pointer:remove_mouse("ingame_chat_mouse")
		end
	end
	
	function HUDChat:_mouse_move(o, x, y)
		if self._mouse_state then
			x = x - self._x_offset
			y = y - self._y_offset
		
			--TODO: Move relative to initial click position, change y based on y move difference instead (or fuck it and leave it as it is, it works)
			local output_panel = self._panel:child("output_panel")
			self:_move_scroll_bar_position_center(y - self._panel:y() - output_panel:y())
			self._mouse_state = y
		end
	end
	
	function HUDChat:_mouse_press(o, button, x, y)
		x = x - self._x_offset
		y = y - self._y_offset
		
		if button == Idstring("mouse wheel up") then
			self:_change_line_offset(1)
		elseif button == Idstring("mouse wheel down") then
			self:_change_line_offset(-1)
		elseif button == Idstring("0") then
			local scroll_bar_position = self._panel:child("output_panel"):child("scroll_bar_position")
			if scroll_bar_position:inside(x, y) then
				self._mouse_state = y
			end
		end
	end
	
	function HUDChat:_mouse_release(o, button, x, y)
		x = x - self._x_offset
		y = y - self._y_offset
		
		if button == Idstring("0") then
			self._mouse_state = nil
		end
	end
	
	function HUDChat:_mouse_click(o, button, x, y)
		x = x - self._x_offset
		y = y - self._y_offset
		
		local output_panel = self._panel:child("output_panel")
		local scroll_bar_bg = output_panel:child("scroll_bar_bg")
		local scroll_bar_up = output_panel:child("scroll_bar_up")
		local scroll_bar_down = output_panel:child("scroll_bar_down")
		local scroll_bar_position = output_panel:child("scroll_bar_position")
		
		if scroll_bar_up:inside(x, y) then
			self:_change_line_offset(1)
		elseif scroll_bar_down:inside(x, y) then
			self:_change_line_offset(-1)
		elseif scroll_bar_position:inside(x, y) then

		elseif scroll_bar_bg:inside(x, y) then
			self:_move_scroll_bar_position_center(y - self._panel:y() - output_panel:y())
		end
	end
	
	function HUDChat:_move_scroll_bar_position_center(y)
		local output_panel = self._panel:child("output_panel")
		local scroll_bar_bg = output_panel:child("scroll_bar_bg")
		local scroll_bar_up = output_panel:child("scroll_bar_up")
		local scroll_bar_down = output_panel:child("scroll_bar_down")
		local scroll_bar_position = output_panel:child("scroll_bar_position")
		
		y = y + scroll_bar_position:h() / 2
		local positon_height_area = scroll_bar_bg:h() - scroll_bar_up:h() - scroll_bar_down:h() - 4
		local new_line_offset = math.round((1 - ((y - scroll_bar_up:h() - 2) / positon_height_area)) * self._total_message_lines)
		self:_change_line_offset(new_line_offset - self._current_line_offset)
	end
	
end
