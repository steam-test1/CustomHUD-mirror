--TODO: Dynamic updates

local main_menu_id = "customHUD_menu_main"
local localization_file = ModPath .. "localization/menu.json"
local settings_file = ModPath .. "saved_settings.json"

Hooks:Add("MenuManagerPopulateCustomMenus", "MenuManagerPopulateCustomMenus_CustomHUD", function(menu_manager, nodes)
	local function change_setting(category, setting, value)
		HUDTeammateCustomMenu.setting_changed = true
		
		--printf("CHANGE SETTING %s > %s: %s", tostring(category), tostring(setting), tostring(value))
		if category then
			HUDTeammateCustomMenu.SETTINGS[setting] = value
		else
			HUDTeammateCustomMenu.SETTINGS[category][setting] = value
		end
	end
	
	local function initialize_menu(menu_id, data)
		if MenuHelper.menus[menu_id] then return end
	
		MenuHelper:NewMenu(menu_id)
		
		local category = data.category
		
		for i, item in ipairs(data) do
			local id = item[1]
			local item_type = item[2]
			local item_data = item[3] or {}
				
			if not item_data.required_category or not category or item_data.required_category == category then
				local default = category and HUDTeammateCustomMenu.SETTINGS[category][id] or HUDTeammateCustomMenu.SETTINGS[id]
				local clbk_id = "customHUD_menu_" .. id .. "_" .. tostring(category) .. "_clbk"
				local title = "customHUD_menu_" .. id .. "_title"
				local desc = "customHUD_menu_" .. id .. "_desc"
				
				if item_type == "toggle" then
					MenuHelper:AddToggle({ id = id, title = title, desc = desc, callback = clbk_id, menu_id = menu_id, priority = -i, value = default and true or false })
					
					MenuCallbackHandler[clbk_id] = function(self, item)
						change_setting(category, id, item:value() == "on")
					end
				elseif item_type == "slider" then
					MenuHelper:AddSlider({ id = id, title = title, desc = desc, callback = clbk_id, min = item_data.min, max = item_data.max, step = item_data.step, show_value = true, menu_id = menu_id, priority = -i, value = default or 0 })
					
					MenuCallbackHandler[clbk_id] = function(self, item)
						if item_data.round then item:set_value(math.round(item:value())) end
						change_setting(category, id, item:value())
					end
				elseif item_type == "multichoice" then
					MenuHelper:AddMultipleChoice({ id = id, title = title, desc = desc, callback = clbk_id, items = item_data.items, menu_id = menu_id, priority = -i, value = (default or 0) + 1 })
					
					MenuCallbackHandler[clbk_id] = function(self, item)
						change_setting(category, id, item:value() - 1)
					end
				elseif item_type == "divider" then
					MenuHelper:AddDivider({ id = id, size = item_data.size, menu_id = menu_id, priority = -i })
				end
			end
		end
		
		for sub_menu_id, sub_menu_data in pairs(data.sub_menus or {}) do
			initialize_menu(sub_menu_id, sub_menu_data)
		end
	end
	
	local function finalize_menu(menu_id, data, parent, back_clbk)
		nodes[menu_id] = MenuHelper:BuildMenu(menu_id, { back_callback = back_clbk })
		MenuHelper:AddMenuItem(nodes[parent], menu_id, menu_id .. "_title", menu_id .. "_desc")
		
		for sub_menu_id, sub_menu_data in pairs(data.sub_menus or {}) do
			finalize_menu(sub_menu_id, sub_menu_data, menu_id, back_clbk)
		end
	end
	
	--Menu structure
	local main_menu = {
		sub_menus = {
			customHUD_menu_teammatepanels = {
				--General stuff here if any
				sub_menus = {
					--teammate
					--player
				},
			},
		},
	}
	
	local options = {
		{ "scale", "slider", { min = 0.25, max = 3, step = 0.05 }},
		{ "opacity", "slider", { min = 0, max = 1, step = 0.05 }},
		{ "divider", "divider", { size = 12 } },
		{ "name", "toggle" },
		{ "rank", "toggle" },
		{ "character", "toggle" },
		{ "divider", "divider", { size = 12 } },
		{ "latency", "toggle", { required_category = "teammate" } },
		{ "build", "toggle", { required_category = "teammate" } },
		{ "build_duration", "slider", { required_category = "teammate", min = 0, max = 60, step = 1, round = true }},
		{ "status", "toggle" },
		{ "callsign", "toggle" },
		{ "carry", "toggle" },
		{ "divider", "divider", { size = 12 } },
		{ "equipment", "toggle" },
		{ "special_equipment", "toggle" },
		{ "special_equipment_rows", "slider", { min = 2, max = 4, step = 1, round = true }},
		{ "divider", "divider", { size = 12 } },
		{ "interaction", "toggle", { required_category == "teammate" } },
		{ "interaction_duration", "slider", { required_category == "teammate", min = 0, max = 60, step = 0.5 }},
		{ "divider", "divider", { size = 12 } },
		{ "weapon_icon", "multichoice", { items = { 
			"customHUD_menu_option_off", 
			"customHUD_menu_option_on",
			"customHUD_menu_option_selected", 
			"customHUD_menu_option_unselected", 
		}}},
		{ "weapon_ammo", "multichoice", { items = { 
			"customHUD_menu_option_off", 
			"customHUD_menu_option_on",
			"customHUD_menu_option_selected", 
			"customHUD_menu_option_unselected", 
		}}},
		{ "weapon_ammo_aggregate", "toggle" },
		{ "weapon_fire_mode", "multichoice", { required_category = "player", items = { 
			"customHUD_menu_option_off", 
			"customHUD_menu_option_on",
			"customHUD_menu_option_selected", 
			"customHUD_menu_option_unselected", 
		}}},
		{ "divider", "divider", { size = 12 } },
		{ "accuracy", "toggle", { required_category == "player" } },
		{ "kill_counter", "toggle" },
		{ "kill_counter_specials", "toggle" },
		{ "kill_counter_bots", "toggle", { required_category == "teammate" } },
	}
	
	for category, menu_id in pairs({ player = "customHUD_menu_player", teammate = "customHUD_menu_teammate" }) do
		--printf("%s : %s", category, menu_id)
		local new_menu = table.deep_map_copy(options)
		new_menu.category = category
		main_menu.sub_menus.customHUD_menu_teammatepanels.sub_menus[menu_id] = new_menu
	end
	
	
	local back_clbk = "customHUD_menu_back_clbk"
	MenuCallbackHandler[back_clbk] = function(self, item)
		HUDTeammateCustomMenu.save_settings()
	end
	
	initialize_menu(main_menu_id, main_menu)
	finalize_menu(main_menu_id, main_menu, "lua_mod_options_menu", back_clbk)
end)

Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_CustomHUD_localization", function(self)
	LocalizationManager:load_localization_file(localization_file)
end)


HUDTeammateCustomMenu = {
	SETTINGS = {
		MAX_WEAPONS = 2,	--Number of carried guns (fuck with this at your own risk)
		
		player = {
			scale = 1,	--Scale of all elements of the panel
			opacity = 0.9,	--Transparency/alpha of panel (1 is solid, 0 is invisible)
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
			scale = 1,	--Scale of all elements of the panel
			opacity = 0.9,	--Transparency/alpha of panel (1 is solid, 0 is invisible)
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

	save_settings = function(force)
		if force or HUDTeammateCustomMenu.setting_changed then
			local file = io.open(settings_file, "w+")
			if file then
				HUDTeammateCustomMenu.setting_changed = false
				file:write(json.encode(HUDTeammateCustomMenu.SETTINGS))
				file:close()
			end
		end
	end,
	
	load_settings = function()
		local file = io.open(settings_file, "r")
		if file then
			HUDTeammateCustomMenu.SETTINGS = json.decode(file:read("*all"))
			file:close()
		else
			HUDTeammateCustomMenu.save_settings(true)
		end
	end,
}

HUDTeammateCustomMenu.load_settings()
