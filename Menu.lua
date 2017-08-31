--TODO: Dynamic updates

local menu_prefix = "customHUD_menu_"
local localization_file = ModPath .. "localization/menu.json"
local settings_file = ModPath .. "saved_settings.json"

Hooks:Add("MenuManagerPopulateCustomMenus", "MenuManagerPopulateCustomMenus_CustomHUD", function(menu_manager, nodes)
	local function initialize_menu(menu_id, data)
		local prefixed_menu_id = menu_prefix .. menu_id
		
		MenuHelper:NewMenu(prefixed_menu_id)
		
		for i, item in ipairs(data) do
			local id = item[1]
			local item_type = item[2]
			local item_data = item[3] or {}
			
			local default = data.default_value_clbk(id)
			local clbk_id = string.format("%s_%s_clbk", prefixed_menu_id, id)
			local title = string.format("%s%s_title", menu_prefix, id)
			local desc = string.format("%s%s_desc", menu_prefix, id)
			
			if item_type == "toggle" then
				MenuHelper:AddToggle({ id = id, title = title, desc = desc, callback = clbk_id, menu_id = prefixed_menu_id, priority = -i, value = default and true or false })
				
				MenuCallbackHandler[clbk_id] = function(self, item)
					data.change_clbk(id, item:value() == "on")
				end
			elseif item_type == "slider" then
				MenuHelper:AddSlider({ id = id, title = title, desc = desc, callback = clbk_id, min = item_data.min, max = item_data.max, step = item_data.step, show_value = true, menu_id = prefixed_menu_id, priority = -i, value = default or 0 })
				
				MenuCallbackHandler[clbk_id] = function(self, item)
					if item_data.round then item:set_value(math.round(item:value())) end
					data.change_clbk(id, item:value())
				end
			elseif item_type == "multichoice" then
				local items = {}
				for _, item in ipairs(item_data.items) do
					table.insert(items, string.format("%s%s", menu_prefix, item))
				end
				
				MenuHelper:AddMultipleChoice({ id = id, title = title, desc = desc, callback = clbk_id, items = items, menu_id = prefixed_menu_id, priority = -i, value = (default or 0) + 1 })
				
				MenuCallbackHandler[clbk_id] = function(self, item)
					data.change_clbk(id, item:value() - 1)
				end
			elseif item_type == "divider" then
				MenuHelper:AddDivider({ id = id, size = item_data.size, menu_id = prefixed_menu_id, priority = -i })
			end
		end
		
		for sub_menu_id, sub_menu_data in pairs(data.sub_menus or {}) do
			initialize_menu(sub_menu_id, sub_menu_data)
		end
	end
	
	local function finalize_menu(menu_id, data, parent, back_clbk)
		local prefixed_menu_id = menu_prefix .. menu_id
		
		nodes[prefixed_menu_id] = MenuHelper:BuildMenu(prefixed_menu_id, { back_callback = back_clbk })
		MenuHelper:AddMenuItem(nodes[parent], prefixed_menu_id, prefixed_menu_id .. "_title", prefixed_menu_id .. "_desc")
		
		for sub_menu_id, sub_menu_data in pairs(data.sub_menus or {}) do
			finalize_menu(sub_menu_id, sub_menu_data, prefixed_menu_id, back_clbk)
		end
	end
	
	local function change_module_enabled_setting(id, value)
		printf("change_module_enabled_setting: %s / %s", tostring(id), tostring(value))
		CustomHUDMenu.setting_changed = true
		CustomHUDMenu.settings[id] = value
	end
	
	local function default_value_module_enabled_setting(id)
		return CustomHUDMenu.settings[id]
	end
	
	local function change_teammatepanel_settings(id, value)
		printf("change_teammatepanel_settings: %s / %s", tostring(id), tostring(value))
		CustomHUDMenu.setting_changed = true
		CustomHUDMenu.settings.teammatepanels[id] = value
	end
	
	local function default_value_teammatepanel_settings(id)
		return CustomHUDMenu.settings.teammatepanels[id]
	end
	
	local function change_teammatepanel_settings_player(id, value)
		printf("change_teammatepanel_settings_player: %s / %s", tostring(id), tostring(value))
		CustomHUDMenu.setting_changed = true
		CustomHUDMenu.settings.teammatepanels.player[id] = value
	end
	
	local function default_value_teammatepanel_settings_player(id)
		return CustomHUDMenu.settings.teammatepanels.player[id]
	end
	
	local function change_teammatepanel_settings_teammate(id, value)
		printf("change_teammatepanel_settings_teammate: %s / %s", tostring(id), tostring(value))
		CustomHUDMenu.setting_changed = true
		CustomHUDMenu.settings.teammatepanels.teammate[id] = value
	end
	
	local function default_value_teammatepanel_settings_teammate(id)
		return CustomHUDMenu.settings.teammatepanels.teammate[id]
	end
	
	local function change_hudchat_settings(id, value)
		printf("change_hudchat_settings: %s / %s", tostring(id), tostring(value))
		CustomHUDMenu.setting_changed = true
		CustomHUDMenu.settings.hudchat[id] = value
		
		if managers.hud and managers.hud.change_custom_chat_settings then
			managers.hud:change_custom_chat_settings(CustomHUDMenu.settings.hudchat)
		end
	end
	
	local function default_value_hudchat_settings(id)
		return CustomHUDMenu.settings.hudchat[id]
	end
	
	--Menu structure
	local main_menu = {
		change_clbk = change_module_enabled_setting,
		default_value_clbk = default_value_module_enabled_setting,
		{ "enable_teammatepanels", "toggle" },
		{ "enable_chat", "toggle" },

		sub_menus = {
			teammatepanels = {
				change_clbk = change_teammatepanel_settings,
				default_value_clbk = default_value_teammatepanel_settings,
				--General stuff here if any
				
				sub_menus = {
					player = {
						change_clbk = change_teammatepanel_settings_player,
						default_value_clbk = default_value_teammatepanel_settings_player,
						--Items populated dynamically below
					},
					teammate = {
						change_clbk = change_teammatepanel_settings_teammate,
						default_value_clbk = default_value_teammatepanel_settings_teammate,
						--Items populated dynamically below
					},
				},
			},
			
			hudchat = {
				change_clbk = change_hudchat_settings,
				default_value_clbk = default_value_hudchat_settings,
				{ "line_height", "slider", { min = 5, max = 25, step = 1, round = true }},
				{ "width", "slider", { min = 100, max = 800, step = 10, round = true }},
				{ "height", "slider", { min = 100, max = 800, step = 10, round = true }},
				{ "x_offset", "slider", { min = 0, max = 100, step = 1 }},
				{ "y_offset", "slider", { min = 0, max = 100, step = 1 }},
				{ "fade_delay", "slider", { min = 1, max = 25, step = 1 }},
				{ "use_mouse", "toggle" },
			}
		},
	}
	
	--Populate teammatepanels options
	local teammatepanels_items = {
		{ data = { "scale", "slider", { min = 0.25, max = 3, step = 0.05 }}},
		{ data = { "opacity", "slider", { min = 0, max = 1, step = 0.05 }}},
		{ data = { "divider", "divider", { size = 12 }}},
		{ data = { "name", "toggle" }},
		{ data = { "rank", "toggle" }},
		{ data = { "character", "toggle" }},
		{ data = { "divider", "divider", { size = 12 }}},
		{ required_category = "teammate", data = { "latency", "toggle" }},
		{ required_category = "teammate", data = { "build", "toggle" }},
		{ required_category = "teammate", data = { "build_duration", "slider", { min = 0, max = 60, step = 1, round = true }}},
		{ data = { "status", "toggle" }},
		{ data = { "callsign", "toggle" }},
		{ data = { "carry", "toggle" }},
		{ data = { "divider", "divider", { size = 12 }}},
		{ data = { "equipment", "toggle" }},
		{ data = { "special_equipment", "toggle" }},
		{ data = { "special_equipment_rows", "slider", { min = 2, max = 4, step = 1, round = true }}},
		{ data = { "divider", "divider", { size = 12 }}},
		{ required_category = "teammate", data = { "interaction", "toggle" }},
		{ required_category = "teammate", data = { "interaction_duration", "slider", { min = 0, max = 60, step = 0.5 }}},
		{ data = { "divider", "divider", { size = 12 }}},
		{ data = { "weapon_icon", "multichoice", { items = { "option_off", "option_on", "option_selected", "option_unselected" }}}},
		{ data = { "weapon_ammo", "multichoice", { items = { "option_off", "option_on", "option_selected", "option_unselected" }}}},
		{ data = { "weapon_ammo_aggregate", "toggle" }},
		{ required_category = "player", data = { "weapon_fire_mode", "multichoice", { items = { "option_off", "option_on", "option_selected", "option_unselected" }}}},
		{ data = { "divider", "divider", { size = 12 }}},
		{ required_category = "player", data = { "accuracy", "toggle" }},
		{ data = { "kill_counter", "toggle" }},
		{ data = { "kill_counter_specials", "toggle" }},
		{ required_category = "teammate", data = { "kill_counter_bots", "toggle" }},
	}
	for _, category in ipairs({ "player", "teammate" }) do
		local menu_table = main_menu.sub_menus.teammatepanels.sub_menus[category]
		
		for i, item in ipairs(teammatepanels_items) do
			if not item.required_category or item.required_category == category then
				table.insert(menu_table, item.data)
			end
		end
	end
	
	
	local back_clbk = menu_prefix .. "back_clbk"
	MenuCallbackHandler[back_clbk] = function(self, item)
		CustomHUDMenu.save_settings()
	end
	
	if nodes.blt_options then
		initialize_menu("main", main_menu)
		finalize_menu("main", main_menu, "blt_options", back_clbk)
	end
end)

Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_CustomHUD_localization", function(self)
	LocalizationManager:load_localization_file(localization_file)
end)


CustomHUDMenu = {
	--Default settings, will be written to initial settings file and then ignored
	settings = {
		enable_teammatepanels = false,
		enable_chat = false,
		
		teammatepanels = {
			MAX_WEAPONS = 2,	--Number of carried guns (fuck with this at your own risk)
			
			player = {
				scale = 1,	--Scale of all elements of the panel
				opacity = 1.0,	--Transparency/alpha of panel (1 is solid, 0 is invisible)
				name = false,	--Show name
				rank = false,	--Show infamy/level
				character = false,	--Show character name
				latency = false,	--Show latency (not used by local player)
				build = false,	--Show build; skill/perk breakdown (not used by local player)
				build_duration = 0,	--Show build for duration; 0 is permanent (not used by local player)
				status = true,	--Show health/armor/condition etc.
				callsign = true,	--Show the callsign and voice chat icon
				carry = true,	--Show currently carried bag
				equipment = true,	--Show throwables, cable ties and deployables
				special_equipment = true,	--Show special equipment/tools (keycards etc.)
				special_equipment_rows = 3,	--Number of special equipment items in each column
				interaction = false,	--Show interaction timer and type (not used by local player)
				interaction_duration = 0, --Minimum interaction timer to show it (not used by local player)
				weapon_icon = 0,	--Show/hide weapon icon. 0: off, 1: on, 2: selected only, 3: unselected only
				weapon_ammo = 1,	--Show/hide weapon ammo. 0: off, 1: on, 2: selected only, 3: unselected only
				weapon_ammo_aggregate = false,	--Aggregate weapon ammo or show magazine/total separately
				weapon_fire_mode = 1,	--Show/hide weapon fire mode. 0: off, 1: on, 2: selected only, 3: unselected only (not used by teammates)
				accuracy = true,	--Show weapon accuracy (not used by teammates)
				kill_counter = true,	--Show kill counter
				kill_counter_specials = true,	--Separate special kills from other units
				kill_counter_bots = true,	--Show kill counts for team AI (not used by local player)
			},
			
			teammate = {
				scale = 0.8,	--Scale of all elements of the panel
				opacity = 1.0,	--Transparency/alpha of panel (1 is solid, 0 is invisible)
				name = true,	--Show name
				rank = true,	--Show infamy/level
				character = false,	--Show character name
				latency = true,	--Show latency (not used by player panel)
				build = true,	--Show build; skill/perk breakdown (not used by local player)
				build_duration = 30,	--Show build for duration; 0 is permanent (not used by local player)
				status = true,	--Show health/armor/condition etc.
				callsign = true,	--Show the callsign and voice chat icon
				carry = true,	--Show currently carried bag
				equipment = true,	--Show throwables, cable ties and deployables
				special_equipment = true,	--Show special equipment/tools (keycards etc.)
				special_equipment_rows = 3,	--Number of special equipment items in each column
				interaction = true,	--Show interaction timer and type (not used by local player)
				interaction_duration = 1, --Minimum interaction timer to show it (not used by local player)
				weapon_icon = 2,	--Show/hide weapon icon. 0: off, 1: on, 2: selected only, 3: unselected only
				weapon_ammo = 1,	--Show/hide weapon ammo. 0: off, 1: on, 2: selected only, 3: unselected only
				weapon_ammo_aggregate = true,	--Aggregate weapon ammo or show magazine/total separately
				weapon_fire_mode = 1,	--Show/hide weapon fire mode. 0: off, 1: on, 2: selected only, 3: unselected only (not used by teammates)
				accuracy = true,	--Show weapon accuracy (not used by teammates)
				kill_counter = true,	--Show kill counter
				kill_counter_specials = true,	--Separate special kills from other units
				kill_counter_bots = true,	--Show kill counts for team AI (not used by local player)
			},
		},
		
		hudchat = {
			line_height = 12,			--Size of each line in chat (and hence the text size)
			width = 350,				--Width of the chat window
			height = 100,				--Height of the chat window
			use_mouse = false,		--For scolling and stuff. Experimental, you have been warned
			x_offset = 100,			--% offset from left of HUD panel
			y_offset = 50,				--% offset from top of HUD panel
			fade_delay = 6,			--Fade delay for chat window after inactivity
		},
	},
	
	save_settings = function(force)
		if force or CustomHUDMenu.setting_changed then
			local file = io.open(settings_file, "w+")
			if file then
				CustomHUDMenu.setting_changed = false
				file:write(json.encode(CustomHUDMenu.settings))
				file:close()
			end
		end
	end,
	
	load_settings = function()
		local file = io.open(settings_file, "r")
		if file then
			CustomHUDMenu.settings = json.decode(file:read("*all"))
			file:close()
		else
			CustomHUDMenu.save_settings(true)
		end
	end,
}

CustomHUDMenu.load_settings()
