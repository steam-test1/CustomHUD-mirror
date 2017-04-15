if not CustomHUDMenu.settings.enable_chat then return end

if RequiredScript == "lib/managers/hudmanagerpd2" then

	local setup_endscreen_hud_original = HUDManager.setup_endscreen_hud
	
	function HUDManager:setup_endscreen_hud(...)
		self._hud_chat_ingame:disconnect_mouse()
		return setup_endscreen_hud_original(self, ...)
	end
	
	function HUDManager:change_custom_chat_settings(...)
		self._hud_chat_ingame:change_settings(...)
	end
	
end
	
if RequiredScript == "lib/managers/hud/hudchat" then
	
	function HUDChat:init(ws, hud)
		self._ws = ws
		self._hud_panel = hud.panel
		self._messages = {}
		self._msg_index = 0
		self._msg_offset = 0
		self:set_channel_id(ChatManager.GAME)
		
		self._settings = {
			x_offset = CustomHUDMenu.settings.hudchat.x_offset,
			y_offset = CustomHUDMenu.settings.hudchat.y_offset,
			height = CustomHUDMenu.settings.hudchat.height,
			width = CustomHUDMenu.settings.hudchat.width,
			line_height = CustomHUDMenu.settings.hudchat.line_height,
			fade_delay = CustomHUDMenu.settings.hudchat.fade_delay,
			use_mouse = CustomHUDMenu.settings.hudchat.use_mouse,
		}
		
		self._panel = self._hud_panel:panel({
			h = self._settings.height,
			w = self._settings.width,
			alpha = 0,
			visible = false,
		})
		
		self:_create_output_panel()
		self:_create_input_panel()
		self:_update_position()
	end
	
	function HUDChat:_create_input_panel()
		self._input_panel = self._panel:panel({ 
			w = self._settings.width, 
			h = self._settings.line_height,
		})
		self._input_panel:set_bottom(self._panel:h())
		
		local bg = self._input_panel:rect({
			alpha = 0.25,
			color = Color.black,
			layer = -10,
			halign = "grow",
			valign = "grow",
		})
		
		self._input_prompt = self._input_panel:text({
			text = string.format("%s ", managers.localization:text("debug_chat_say")),
			font = tweak_data.menu.pd2_small_font,
			font_size = self._settings.line_height * 0.95,
			h = self._settings.line_height,
		})
		local _, _, w, _ = self._input_prompt:text_rect()
		self._input_prompt:set_w(w)
		
		self._input_text = self._input_panel:text({
			font = tweak_data.menu.pd2_small_font,
			font_size = self._settings.line_height * 0.95,
			h = self._settings.line_height,
			w = self._input_panel:w() - self._input_prompt:w(),
			x = self._input_prompt:w(),
			wrap = true,
			word_wrap = false,
			align = "left",
			halign = "left",
			vertical = "center",
			hvertical = "center",
			valign = "grow",
		})
		
		self._caret = self._input_panel:rect({
			layer = 2,
			visible = false,
		})
		
		self._focus_indicator = self._input_panel:rect({
			visible = false,
			color = Color.white:with_alpha(0.2),
			layer = -1
		})	
	end
	
	function HUDChat:_create_output_panel()
		self._output_panel = ScrollablePanelCustom:new(self._hud_panel, self._panel, { 
			name = "output_panel",
			w = self._settings.width,
			h = self._settings.height - self._settings.line_height,
		})
		self._output_panel:set_content_size(self._panel:w() - ScrollablePanelNew.SCROLL_PANEL_WIDTH, 0)
		
		local bg = self._output_panel:content_panel():gradient({
			--gradient_points = { 0, Color.white:with_alpha(0), 0.2, Color.white:with_alpha(0.25), 1, Color.white:with_alpha(0) },
			--gradient_points = { 0, Color.white:with_alpha(0.4), 0.2, Color.white:with_alpha(0.3), 1, Color.white:with_alpha(0.2) },
			gradient_points = { 0, Color.white:with_alpha(0.3), 0.3, Color.white:with_alpha(0.1), 0.5, Color.white:with_alpha(0.2) , 0.7, Color.white:with_alpha(0.1), 1, Color.white:with_alpha(0.3) },
			layer = -10,
			valign = "grow",
			halign = "grow",
			blend_mode = "sub",
		})
	end
	
	function HUDChat:change_settings(settings)
		local force_line_height_update, force_position_update = false, false
		
		if self._settings.width ~= settings.width or self._settings.height ~= settings.height then
			self._settings.width = settings.width
			self._settings.height = settings.height
			self:_update_chatbox_size()
			force_line_height_update = true
			force_position_update = true
		end
		
		if force_line_height_update or self._settings.line_height ~= settings.line_height then
			self._settings.line_height = settings.line_height
			self:_update_line_height()
		end
		
		if force_position_update or self._settings.x_offset ~= settings.x_offset or self._settings.y_offset ~= settings.y_offset then
			self._settings.x_offset = settings.x_offset
			self._settings.y_offset = settings.y_offset
			self:_update_position()
		end
	end
	
	function HUDChat:set_position(x, y)
		self._panel:set_position(x, y)
	end
	
	function HUDChat:_update_position()
		local x = (self._hud_panel:w() - self._panel:w()) * self._settings.x_offset/100
		local y = (self._hud_panel:h() - self._panel:h()) * self._settings.y_offset/100
		self:set_position(x, y)
	end
	
	function HUDChat:_update_chatbox_size()
		self._panel:set_size(self._settings.width, self._settings.height)
		
		self._input_panel:set_w(self._settings.width)
		self._input_panel:set_bottom(self._panel:h())
		self._input_text:set_w(self._input_panel:w() - self._input_prompt:w())
		self:_update_output_panel_size()
	end
	
	function HUDChat:_update_line_height()
		self._input_prompt:set_h(self._settings.line_height)
		self._input_prompt:set_font_size(self._settings.line_height * 0.95)
		local _, _, w, _ = self._input_prompt:text_rect()
		self._input_prompt:set_w(w)
		self._input_text:set_left(self._input_prompt:right())
		self._input_text:set_w(self._input_panel:w() - self._input_prompt:w())
		self._input_text:set_font_size(self._settings.line_height * 0.95)
		
		self:_update_input_panel_height()
		self:_rearrange_messages()
	end
	
	function HUDChat:_update_input_panel_height()
		local no_lines = math.max(1, self._input_text:number_of_lines())
		local h = no_lines * self._settings.line_height
		
		if h ~= self._input_panel:h() then
			self._input_panel:set_h(h)
			self._input_panel:set_bottom(self._panel:h())
			self._focus_indicator:set_shape(self._input_text:shape())
			self:_update_output_panel_size()
			self._output_panel:scroll_to_bottom()
		end
	end
	
	function HUDChat:_update_output_panel_size()
		self._output_panel:set_size(self._panel:w(), self._panel:h() - self._input_panel:h())
		self._output_panel:set_content_size(self._panel:w() - ScrollablePanelNew.SCROLL_PANEL_WIDTH)
	end
	
	function HUDChat:receive_message(name, message, color, icon)
		local msg_panel_name = "msg_" .. self._msg_index
		local msg = { index = self._msg_index, panel_name = msg_panel_name, name = name, message = message, color = color, icon = icon }
		self._msg_index = self._msg_index + 1
		table.insert(self._messages, msg)
		
		self:_add_message(msg)
		
		if not self._focus then
			self:_do_fade_in()
		end
	end
	
	function HUDChat:_add_message(msg)
		local name, message, color, icon = msg.name, msg.message, msg.color, msg.icon
		local content_panel = self._output_panel:content_panel()
		
		local msg_panel = content_panel:panel({
			name = msg.panel_name,
			h = self._settings.line_height,
			w = content_panel:w(),
		})
		local bg = msg_panel:rect({
			alpha = 0.25,
			color = color,
			layer = -1,
			valign = "grow",
			halign = "grow",
		})
		
		local x_offset = 0
		local t = managers.game_play_central and managers.game_play_central:get_heist_timer() or 0
		local minutes = math.floor(t/60)
		local hours = math.floor(minutes/60)
		local time_string = hours > 0 and string.format("%d:%02d:%02d", hours, minutes%60, t%60) or string.format("%2d:%02d", minutes%60, t%60)
		
		local time_text = msg_panel:text({
			name = "time",
			text = time_string,
			font = tweak_data.menu.pd2_small_font,
			font_size = self._settings.line_height * 0.95,
			h = self._settings.line_height,
			x = x_offset,
		})
		local _, _, w, _ = time_text:text_rect()
		time_text:set_w(w)
		x_offset = x_offset + w + 2
		
		if icon then
			local texture, texture_rect = tweak_data.hud_icons:get_icon_data(icon)
			local bitmap = msg_panel:bitmap({
				texture = texture,
				texture_rect = texture_rect,
				color = color,
				h = self._settings.line_height * 0.85,
				w = self._settings.line_height * 0.85,
				x = x_offset,
			})
			bitmap:set_center_y(self._settings.line_height / 2)
			x_offset = x_offset + bitmap:w() + 1
		end
		
		local message_text = msg_panel:text({
			text = name .. ": " .. message,
			font = tweak_data.menu.pd2_small_font,
			font_size = self._settings.line_height * 0.95,
			w = msg_panel:w() - x_offset,
			x = x_offset,
			align = "left",
			halign = "left",
			valign = "grow",
			wrap = true,
			word_wrap = true,
		})
		local no_lines = message_text:number_of_lines()
		
		message_text:set_range_color(0, utf8.len(name) + 1, color)
		message_text:set_kern(message_text:kern())
		msg_panel:set_h(self._settings.line_height * no_lines)
		msg_panel:set_y(self._msg_offset)
		self._msg_offset = self._msg_offset + msg_panel:h()
		
		self._output_panel:set_content_size(nil, self._msg_offset)
		self._output_panel:scroll_to_bottom()
	end
	
	function HUDChat:_rearrange_messages()
		local content_panel = self._output_panel:content_panel()
		
		for _, msg in ipairs(self._messages) do
			content_panel:remove(content_panel:child(msg.panel_name))
		end
		
		self._msg_offset = 0
		self._msg_index = 0
		
		for _, msg in ipairs(self._messages) do
			self:_add_message(msg)
		end
	end
	
	function HUDChat:_on_focus()
		if not self._focus then
			self._focus = true
			self._skip_first = true
			
			self._focus_indicator:set_visible(true)
			self:_show_caret(true)
			self:_do_fade_in()
			
			self:_connect_keyboard()
			self:_connect_mouse()
			
			self:set_layer(1100)
		end
	end
	
	function HUDChat:_loose_focus()
		if self._focus then
			self._focus = false
			
			self._focus_indicator:set_visible(false)
			self:_show_caret(false)
			self:_do_fade_out()
			
			self:disconnect_keyboard()
			self:disconnect_mouse()
			
			self:set_layer(1)
		end
	end
	
	function HUDChat:update_key_down(o, k)
		local first_wait_done = false
		
		while self._key_pressed == k do
			local s, e = self._input_text:selection()
			local n = utf8.len(self._input_text:text())
			local d = math.abs(e - s)
			
			if k == Idstring("backspace") then
				if s == e and s > 0 then
					self._input_text:set_selection(s - 1, e)
				end
				self._input_text:replace_text("")
				self:_update_input_panel_height()
			elseif k == Idstring("delete") then
				if s == e and s < n then
					self._input_text:set_selection(s, e + 1)
				end
				self._input_text:replace_text("")
				self:_update_input_panel_height()
			elseif k == Idstring("left") then
				if s < e then
					self._input_text:set_selection(s, s)
				elseif s > 0 then
					self._input_text:set_selection(s - 1, s - 1)
				end
			elseif k == Idstring("right") then
				if s < e then
					self._input_text:set_selection(e, e)
				elseif s < n then
					self._input_text:set_selection(s + 1, s + 1)
				end
			elseif self._key_pressed == Idstring("up") then
				self._output_panel:scroll_vertical(0.5)
			elseif self._key_pressed == Idstring("down") then
				self._output_panel:scroll_vertical(-0.5)
			elseif self._key_pressed == Idstring("page up") then
				self._output_panel:scroll_vertical(2)
			elseif self._key_pressed == Idstring("page down") then
				self._output_panel:scroll_vertical(-2)
			end
			
			self:_update_caret()
			wait(first_wait_done and 0.03 or 0.6)
			first_wait_done = true
		end
	end
	
	function HUDChat:key_release(o, k)
		if self._key_pressed == k then
			self._key_pressed = false
		end
	end
	
	function HUDChat:key_press(o, k)
		if k == Idstring("esc") then
			self:_clear_input()
			managers.hud:set_chat_focus(false)
		elseif k == Idstring("end") then
			local n = utf8.len(self._input_text:text())
			self._input_text:set_selection(n, n)
		elseif k == Idstring("home") then
			self._input_text:set_selection(0, 0)
		elseif k == Idstring("enter") then
			local message = self._input_text:text()
			
			if string.len(message) > 0 then
				local u_name = managers.network.account:username()
				managers.chat:send_message(self._channel_id, u_name or "Offline", message)
			end
			
			self:_clear_input()
			managers.hud:set_chat_focus(false)
		else
			if self._skip_first then
				self:_clear_input()
				self._skip_first = false
				return
			end
			
			self._key_pressed = k
			self._input_text:stop()
			self._input_text:animate(callback(self, self, "update_key_down"), k)
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

		self._input_text:replace_text(s)
		self:_update_input_panel_height()
		self:_update_caret()
	end
	
	function HUDChat:_clear_input()
		self._input_text:set_text("")
		self._input_text:set_selection(0, 0)
		self:_update_input_panel_height()
	end
	
	function HUDChat:_update_caret()
		local s, e = self._input_text:selection()
		local x, y, w, h = self._input_text:selection_rect()
		
		if s == 0 and e == 0 then
			if self._input_text:align() == "center" then
				x = self._input_text:world_x() + self._input_text:w() / 2
			else
				x = self._input_text:world_x()
			end
			y = self._input_text:world_y()
		end
		h = self._input_text:h()
		if w < 3 then
			w = 3
		end
		if not self._focus then
			w = 0
			h = 0
		end
		self._caret:set_world_shape(x, y + 2, w, h - 4)
	end
	
	function HUDChat:_connect_mouse()
		if self._settings.use_mouse and not self._mouse_connected then
			self._mouse_connected = true
			
			managers.mouse_pointer:use_mouse({
				mouse_move = function(_, x, y) self._output_panel:mouse_event("mouse_moved", nil, x, y) end,
				mouse_press = function(_, k, x, y) self._output_panel:mouse_event("mouse_pressed", k, x, y) end,
				mouse_release = function(_, k, x, y) self._output_panel:mouse_event("mouse_released", k, x, y) end,
				--mouse_click = function(...) mouse_clicked(...) end,
				id = "ingame_chat_mouse",
			})
		end
	end
	
	function HUDChat:disconnect_mouse()
		if self._mouse_connected then
			self._mouse_connected = false
			
			managers.mouse_pointer:remove_mouse("ingame_chat_mouse")
		end
	end
	
	function HUDChat:_connect_keyboard()
		if not self._keyboard_connected then
			self._keyboard_connected = true
			
			self._ws:connect_keyboard(Input:keyboard())
			self._input_panel:key_press(callback(self, self, "key_press"))
			self._input_panel:key_release(callback(self, self, "key_release"))
			self._input_panel:enter_text(callback(self, self, "enter_text"))
		end
	end
	
	function HUDChat:disconnect_keyboard()
		if self._keyboard_connected then
			self._keyboard_connected = false
			
			self._ws:disconnect_keyboard()
			self._input_panel:key_press(nil)
			self._input_panel:key_release(nil)
			self._input_panel:enter_text(nil)
		end
	end
	
	function HUDChat:set_layer(layer)
		self._panel:set_layer(layer)
	end
	
	function HUDChat:set_channel_id(channel_id)
		managers.chat:unregister_receiver(self._channel_id, self)
		self._channel_id = channel_id
		managers.chat:register_receiver(self._channel_id, self)
	end
	
	function HUDChat:input_focus()
		return self._focus
	end
	
	function HUDChat:set_skip_first(skip_first)
		self._skip_first = skip_first
	end
	
	function HUDChat:send_message(name, message)
	end
	
	function HUDChat:remove()
		self._hud_panel:remove(self._panel)
		managers.chat:unregister_receiver(self._channel_id, self)
	end
	
	function HUDChat:_show_caret(state)
		if state then
			self:_update_caret()
			
			self._caret:animate(function(o)
				local visible = true
				
				while true do
					self._caret:set_visible(visible and true or false)
					visible = not visible
					wait(0.5)
				end
			end)
		else
			self._caret:stop()
			self._caret:set_visible(false)
		end
	end
	
	function HUDChat:_do_fade_in()
		self._panel:stop()
		self._panel:animate(function(o)
			local t = (1 - self._panel:alpha()) * 0.25
			self._panel:set_visible(true)
			over(t, function(r)
				self._panel:set_alpha(r)
			end)
		end)
	end
	
	function HUDChat:_do_fade_out()
		self._panel:stop()
		self._panel:animate(function(o)
			wait(self._settings.fade_delay)
			local t = self._panel:alpha() * 0.25
			over(t, function(r)
				self._panel:set_alpha(1-r)
			end)
			self._panel:set_visible(false)
		end)
	end
	
	
	
	ScrollablePanelNew = ScrollablePanelNew or class()
	ScrollablePanelNew.SCROLL_PANEL_WIDTH = 9
	ScrollablePanelNew.SCROLL_BAR_WIDTH = 5
	ScrollablePanelNew.SCROLL_SPEED = 28
	function ScrollablePanelNew:init(parent, params)
		self._parent = parent
		
		self._panel = parent:panel({
			name = params.name,
			x = params.x or 0,
			y = params.y or 0,
		})
		
		self._view_panel = self._panel:panel({
			w = self._panel:w(),
			h = self._panel:h(),
		})
		
		self._content_panel = self._view_panel:panel({ h = 0, w = 0 })
		
		self:_create_scroll_panels()
		
		self:set_size(params.w, params.h)
	end
	
	function ScrollablePanelNew:_create_scroll_panels()
		local arrow_texture, arrow_rect = tweak_data.hud_icons:get_icon_data("scrollbar_arrow")
		
		self._vertical_scroll_panel = self._panel:panel({ 
			w = self.SCROLL_PANEL_WIDTH, 
			visible = false
		})
		self._vertical_scroll_panel:rect({ alpha = 0.15, color = Color.black, halign = "grow", valign = "grow" })
		
		self._vertical_scroll_bar = self._vertical_scroll_panel:panel({ 
			w = self.SCROLL_BAR_WIDTH,
			h = self._view_panel:h(),
		})
		self._vertical_scroll_bar:set_center_x(self._vertical_scroll_panel:w() / 2)
		
		local vbg = self._vertical_scroll_bar:rect({ 
			alpha = 0.75, 
			color = Color.white,
			halign = "grow", 
			valign = "grow"
		})
		--BoxGuiObject:new(self._vertical_scroll_bar, { sides = { 3, 3, 0, 0 } })
		
		self._arrow_up = self._vertical_scroll_panel:bitmap({
			texture = arrow_texture,
			texture_rect = arrow_rect,
			valign = "top",
			rotation = 0,
			w = self.SCROLL_PANEL_WIDTH * 0.65,
			h = self.SCROLL_PANEL_WIDTH * 0.65,
		})
		self._arrow_up:set_center_x(self.SCROLL_PANEL_WIDTH / 2)
		
		self._arrow_down = self._vertical_scroll_panel:bitmap({
			texture = arrow_texture,
			texture_rect = arrow_rect,
			valign = "bottom",
			rotation = 180,
			w = self.SCROLL_PANEL_WIDTH * 0.65,
			h = self.SCROLL_PANEL_WIDTH * 0.65,
		})
		self._arrow_down:set_center_x(self.SCROLL_PANEL_WIDTH / 2)
		
		
		self._horizontal_scroll_panel = self._panel:panel({ 
			h = self.SCROLL_PANEL_WIDTH,
			w = self._view_panel:w(),
			visible = false
		})
		self._horizontal_scroll_panel:rect({ alpha = 0.15, color = Color.black, halign = "grow", valign = "grow" })
		
		self._horizontal_scroll_bar = self._horizontal_scroll_panel:panel({
			h = self.SCROLL_BAR_WIDTH
		})
		self._horizontal_scroll_bar:set_center_y(self._horizontal_scroll_panel:h() / 2)
		
		local hbg = self._horizontal_scroll_bar:rect({
			alpha = 0.75, 
			color = Color.white,
			halign = "grow", 
			valign = "grow"
		})
		--BoxGuiObject:new(self._horizontal_scroll_bar, { sides = { 0, 0, 4, 4 } })
		
		self._arrow_left = self._horizontal_scroll_panel:bitmap({
			texture = arrow_texture,
			texture_rect = arrow_rect,
			halign = "left",
			rotation = 270,
			w = self.SCROLL_PANEL_WIDTH * 0.65,
			h = self.SCROLL_PANEL_WIDTH * 0.65,
		})
		self._arrow_left:set_center_y(self.SCROLL_PANEL_WIDTH / 2)
		
		self._arrow_right = self._horizontal_scroll_panel:bitmap({
			texture = arrow_texture,
			texture_rect = arrow_rect,
			halign = "right",
			rotation = 90,
			w = self.SCROLL_PANEL_WIDTH * 0.65,
			h = self.SCROLL_PANEL_WIDTH * 0.65,
		})
		self._arrow_right:set_center_y(self.SCROLL_PANEL_WIDTH / 2)
	end
	
	function ScrollablePanelNew:panel()
		return self._panel
	end
	
	function ScrollablePanelNew:content_panel()
		return self._content_panel
	end
	
	function ScrollablePanelNew:view_size()
		return self._view_panel:size()
	end
	
	function ScrollablePanelNew:pack_content_panel(skip_width, skip_height)
		local max_w = 0
		local max_h = 0
		
		for _, child in ipairs(self._content_panel:children()) do
			max_w = math.max(max_w, child:right())
			max_h = math.max(max_h, child:bottom())
		end
		
		self:set_content_size(not skip_width and max_w or nil, not skip_height and max_h or nil)
	end
	
	function ScrollablePanelNew:set_size(w, h)
		local w = w or self._panel:w()
		local h = h or self._panel:h()
		
		self._panel:set_size(w, h)
		self._vertical_scroll_panel:set_right(w)
		self._horizontal_scroll_panel:set_bottom(h)
		self._arrow_up:set_top(0)
		self._arrow_down:set_bottom(self._vertical_scroll_panel:h())
		self._arrow_left:set_left(0)
		self._arrow_right:set_right(self._horizontal_scroll_panel:w())
		
		self:_update_view_panel()
	end
	
	function ScrollablePanelNew:set_content_size(w, h)
		local w = w or self._content_panel:w()
		local h = h or self._content_panel:h()
		
		self._content_panel:set_size(w, h)
		self:_update_view_panel()
		self:_update_scroll_bars()
	end
	
	function ScrollablePanelNew:_update_view_panel()
		local w = self._panel:w()
		local h = self._panel:h()
		
		self._horizontal_scroll_panel:set_visible(self._content_panel:w() > w - self._horizontal_scroll_panel:h())
		self._vertical_scroll_panel:set_visible(self._content_panel:h() > h - self._vertical_scroll_panel:w())
		
		local vw = math.max(0, w - (self._vertical_scroll_panel:visible() and self._vertical_scroll_panel:w() or 0))
		local vh = math.max(0, h - (self._horizontal_scroll_panel:visible() and self._horizontal_scroll_panel:h() or 0))
		self._view_panel:set_size(vw, vh)
		self._vertical_scroll_panel:set_h(vh)
		self._horizontal_scroll_panel:set_w(vw)
		
		self:_update_scroll_bars()
	end
	
	function ScrollablePanelNew:_update_scroll_bars()
		local bar_arrow_padding = 4

		if self._vertical_scroll_panel:visible() then
			local bar_area = self._vertical_scroll_panel:h() - self._arrow_up:h() - self._arrow_down:h() - bar_arrow_padding
			
			local r = math.min(1, self._view_panel:h() / self._content_panel:h())
			self._vertical_scroll_bar:set_h(bar_area * r)
			self._vertical_scroll_bar:set_top(bar_arrow_padding/2 + self._arrow_up:bottom() - self._content_panel:top() * bar_area / self._content_panel:h())
		end
		
		if self._horizontal_scroll_panel:visible() then
			local bar_area = self._horizontal_scroll_panel:w() - self._arrow_left:w() - self._arrow_right:w() - bar_arrow_padding
			
			local r = math.min(1, self._view_panel:w() / self._content_panel:w())
			self._horizontal_scroll_bar:set_w(bar_area * r)
			self._horizontal_scroll_bar:set_left(bar_arrow_padding/2 + self._arrow_left:right() - self._content_panel:left() * bar_area / self._content_panel:w())
		end
	end
	
	function ScrollablePanelNew:scroll_to_top()
		self._content_panel:set_top(0)
		self:_update_scroll_bars()
	end
	
	function ScrollablePanelNew:scroll_to_bottom()
		self._content_panel:set_bottom(self._view_panel:h())
		self:_update_scroll_bars()
	end
	
	function ScrollablePanelNew:scroll_to_left()
		self._content_panel:set_left(0)
		self:_update_scroll_bars()
	end
	
	function ScrollablePanelNew:scroll_to_right()
		self._content_panel:set_right(self._view_panel:w())
		self:_update_scroll_bars()
	end
	
	function ScrollablePanelNew:scroll_vertical(direction)
		self:perform_scroll_vertical(self.SCROLL_SPEED * TimerManager:main():delta_time() * 200, direction)
	end
	
	function ScrollablePanelNew:scroll_horizontal(direction)
		self:perform_scroll_horizontal(self.SCROLL_SPEED * TimerManager:main():delta_time() * 200, direction)
	end
	
	function ScrollablePanelNew:scroll_with_bar_vertical(target_y, current_y)
		local arrow_size = self._arrow_up:size()
		
		if target_y < current_y then
			if target_y < self._vertical_scroll_panel:world_bottom() - arrow_size then
				local mul = (self._vertical_scroll_panel:h() - arrow_size * 2) / self._content_panel:h()
				self:perform_scroll_vertical((current_y - target_y) / mul, 1)
			end
		elseif target_y > current_y then
			if target_y > self._vertical_scroll_panel:world_y() + arrow_size then
				local mul = (self._vertical_scroll_panel:h() - arrow_size * 2) / self._content_panel:h()
				self:perform_scroll_vertical((target_y - current_y) / mul, -1)
			end
		end
	end
	
	function ScrollablePanelNew:scroll_with_bar_horizontal(target_x, current_x)
		local arrow_size = self._arrow_left:size()
		
		if target_x < current_x then
			if target_x < self._horizontal_scroll_panel:world_right() - arrow_size then
				local mul = (self._horizontal_scroll_panel:w() - arrow_size * 2) / self._content_panel:w()
				self:perform_scroll_horizontal((current_x - target_x) / mul, 1)
			end
		elseif target_x > current_x then
			if target_x > self._horizontal_scroll_panel:world_x() + arrow_size then
				local mul = (self._horizontal_scroll_panel:w() - arrow_size * 2) / self._content_panel:w()
				self:perform_scroll_horizontal((target_x - current_x) / mul, -1)
			end
		end
	end
	
	function ScrollablePanelNew:perform_scroll_vertical(speed, direction)
		if self._content_panel:h() <= self._view_panel:h() then
			return
		end
		
		local scroll_amount = speed * direction
		local max_h = self._content_panel:h() - self._view_panel:h()
		max_h = max_h * -1
		local new_y = math.clamp(self._content_panel:y() + scroll_amount, max_h, 0)
		self._content_panel:set_y(new_y)
		self:_update_scroll_bars()
	end
	
	function ScrollablePanelNew:perform_scroll_horizontal(speed, direction)
		if self._content_panel:w() <= self._view_panel:w() then
			return
		end
		
		local scroll_amount = speed * direction
		local max_w = self._content_panel:w() - self._view_panel:w()
		max_w = max_w * -1
		local new_x = math.clamp(self._content_panel:x() + scroll_amount, max_w, 0)
		self._content_panel:set_x(new_x)
		self:_update_scroll_bars()
	end
	
	function ScrollablePanelNew:mouse_pressed(button, x, y)
		if button == Idstring("mouse wheel up") then
			self:scroll_vertical(1)
			return true
		elseif button == Idstring("mouse wheel down") then
			self:scroll_vertical(-1)
			return true
		elseif button == Idstring("0") then
			if self._vertical_scroll_bar:visible() and self._vertical_scroll_bar:inside(x, y) then
				self._grabbed_vertical_bar = true
				self._current_y = y
				return true
			elseif self._horizontal_scroll_bar:visible() and self._horizontal_scroll_bar:inside(x, y) then
				self._grabbed_horizontal_bar = true
				self._current_x = x
				return true
			elseif self._arrow_up:inside(x, y) then
				self._panel:animate(callback(self, self, "_update"), "perform_scroll_vertical", 1)
				return true
			elseif self._arrow_down:inside(x, y) then
				self._panel:animate(callback(self, self, "_update"), "perform_scroll_vertical", -1)
				return true
			elseif self._arrow_left:inside(x, y) then
				self._panel:animate(callback(self, self, "_update"), "perform_scroll_horizontal", 1)
				return true
			elseif self._arrow_right:inside(x, y) then
				self._panel:animate(callback(self, self, "_update"), "perform_scroll_horizontal", -1)
				return true
			end
		end
	end
	
	function ScrollablePanelNew:mouse_released(button, x, y)
		self._panel:stop()
		
		if self._grabbed_vertical_bar or self._grabbed_horizontal_bar then
			self._grabbed_vertical_bar = false
			self._grabbed_horizontal_bar = false
			return true
		end
	end
	
	function ScrollablePanelNew:mouse_moved(button, x, y)
		if self._grabbed_vertical_bar then
			self:scroll_with_bar_vertical(y, self._current_y)
			self._current_y = y
			return true, "grab"
		elseif self._grabbed_horizontal_bar then
			self:scroll_with_bar_horizontal(x, self._current_x)
			self._current_x = x
			return true, "grab"
		--elseif self._scroll_bar:visible() and self._scroll_bar:inside(x, y) then
		--	return true, "hand"
		--elseif self._arrow_up:inside(x, y) or self._arrow_down:inside(x, y) or self._arrow_left:inside(x, y) or self._arrow_right:inside(x, y) then
		--	return true, "link"
		end
	end
	
	function ScrollablePanelNew:_update(o, clbk, dir)
		while true do
			self[clbk](self, self.SCROLL_SPEED * coroutine.yield() * 5, dir)
		end
	end
	
	
	ScrollablePanelCustom = ScrollablePanelCustom or class(ScrollablePanelNew)
	function ScrollablePanelCustom:init(hud_panel, ...)
		ScrollablePanelCustom.super.init(self, ...)
		
		local fullscreen = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN_PD2)
		self._x_offset = (fullscreen.panel:w() - hud_panel:w()) / 2
		self._y_offset = (fullscreen.panel:h() - hud_panel:h()) / 2
	end
	
	function ScrollablePanelCustom:mouse_event(event, button, x, y)
		return self[event](self, button, x - self._x_offset, y - self._y_offset)
	end
	
end
