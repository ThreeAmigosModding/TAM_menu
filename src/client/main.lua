local ArePermissionsSetup = false
local NoClipKey = "F2"

local Menu
local PlayerSubMenu
local VehicleSubmenu
local WordSubmenu

local PlayerOptionsMenu
local OnlinePlayersMenu
local BannedPlayersMenu
local SavedVehiclesMenu
local PersonalVehicleMenu
local VehicleOptionsMenu
local VehicleSpawnerMenu
local PlayerAppearanceMenu
local MpPedCustomizationMenu
local PlayerTimeWeatherOptionsMenu
local TeleportOptionsMenu
local TimeOptionsMenu
local WeatherOptionsMenu
local DensityOptions
local WeaponOptionsMenu
local WeaponLoadoutsMenu
local RecordingMenu
local EnhancedCameraMenu
local PluginSettingsMenu
local MiscSettingsMenu
local AboutMenu

local NoClipEnabled = NoClip.IsNoclipActive()
local PlayersList

local DebugMode = GetResourceMetadata(GetCurrentResourceName(), "client_debug_mode", 0) == "true"
local EnableExperimentalFeatures = (GetResourceMetadata(GetCurrentResourceName(), "experimental_features_enabled", 0) or "0") == "1"
local vMenuKey

local Version = GetResourceMetadata(GetCurrentResourceName(), "version", 0)
local DontOpenMenus = false
local DisableControls = false

local vMenuEnabled = true

local currentCleanupVersion = 2

CreateThread(function()
    PlayersList = NativePlayerList(Players)

    local tmp_kvp_handle = StartFindKvp("")
    local cleanupVersionChecked = false
    local tmp_kvp_names = {}
    while true do
        local k = FindKvp(tmp_kvp_handle)
        if k == "" or k == nil then
            break
        end
        if k == "vmenu_cleanup_version" then
            if GetResourceKvpInt("vmenu_cleanup_version") >= currentCleanupVersion then
                cleanupVersionChecked = true
            end
        end
        table.insert(tmp_kvp_names, k)
    end

    EndFindKvp(tmp_kvp_handle)

    if not cleanupVersionChecked then
        SetResourceKvpInt("vmenu_cleanup_version", currentCleanupVersion)
        for i, kvp in pairs(tmp_kvp_names) do
            if (currentCleanupVersion == 1 or currentCleanupVersion == 2) then
                if not string.find(kvp, "settings_") and not string.find(kvp, "vmenu") and not string.find(kvp, "veh_") and not string.find(kvp, "ped_") and not string.find(kvp, "mp_ped_") then
                    DeleteResourceKvp(kvp)
                    print("[vMenu] [cleanup id: 1] Removed unused (old) KVP: " .. kvp .. ".")
                end
            end
            if currentCleanupVersion == 2 then
                if string.find(kvp, "mp_char") then
                    DeleteResourceKvp(kvp)
                    print("[vMenu] [cleanup id: 2] Removed unused (old) KVP: " .. kvp .. ".")
                end
            end
        end
        print("[vMenu] Cleanup of old unused KVP items completed.")
    end

    RegisterCommand(GetSettingsString(Setting.vmenu_individual_server_id) .. "vMenu:NoClip", function(source, args, rawCommand)
        if IsAllowed(Permission.NoClip) then
            if IsPedInAnyVehicle(PlayerPedId()) then
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if DoesEntityExist(veh) and GetPedInVehicleSeat(veh, -1) == PlayerPedId() then
                    NoClipEnabled = not NoClipEnabled
                else
                    NoClipEnabled = false
                    -- Notify.Error("This vehicle does not exist (somehow) or you need to be the driver of this vehicle to enable noclip!")
                    -- You'll need to implement Notify.Error() in your script
                end
            else
                NoClipEnabled = not NoClipEnabled
            end
        end
    end, false)

    -- Enable Experimental Features
    if EnableExperimentalFeatures then
        RegisterCommand("testped", function(source, args, rawCommand)
            local data = GetPedHeadBlendData(PlayerPedId())
            print(json.encode(data, {indent = true}))
        end, false)

        RegisterCommand("tattoo", function(source, args, rawCommand)
            if args[1] ~= nil and args[2] ~= nil then
                print(args[1] .. " " .. args[2])
                local d = GetTattooCollectionData(tonumber(args[1]), tonumber(args[2]))
                print("check")
                print(json.encode(d, {indent = true}))
            end
        end, false)

        RegisterCommand("clearfocus", function(source, args, rawCommand)
            SetNuiFocus(false, false)
        end, false)
    end
    
    RegisterCommand("vmenuclient", function(source, args, rawCommand)
        if args ~= nil and #args > 0 then
            if args[1]:lower() == "debug" then
                DebugMode = not DebugMode
                Notify.Custom("Debug mode is now set to: " .. tostring(DebugMode))
                if DebugMode then
                    SetRichPresence("Debugging vMenu " .. Version .. "!")
                else
                    SetRichPresence("Enjoying FiveM!")
                end
            elseif args[1]:lower() == "gc" then
                collectgarbage()
                print("Cleared memory.")
            elseif args[1]:lower() == "dump" then
                Notify.Info("A full config dump will be made to the console. Check the log file. This can cause lag!")
                print("\n\n\n########################### vMenu ###########################")
                print("Running vMenu Version: " .. Version .. ", Experimental features: " .. tostring(EnableExperimentalFeatures) .. ", Debug mode: " .. tostring(DebugMode))
                print("\nDumping a list of all KVPs:")
                local handle = StartFindKvp("")
                local names = {}
                while true do
                    local k = FindKvp(handle)
                    if k == "" or k == nil then
                        break
                    end
                    names[#names + 1] = k
                end
                EndFindKvp(handle)
    
                local kvps = {}
                for _, kvp in ipairs(names) do
                    local type = 0 -- 0 = string, 1 = float, 2 = int
                    if kvp:match("settings_") then
                        if kvp == "settings_clothingAnimationType" or kvp == "settings_miscLastTimeCycleModifierIndex" or kvp == "settings_miscLastTimeCycleModifierStrength" then
                            type = 2
                        end
                    elseif kvp == "vmenu_cleanup_version" then
                        type = 2
                    end
    
                    if type == 0 then
                        local s = GetResourceKvpString(kvp)
                        if s:sub(1, 1) == "{" or s:sub(1, 1) == "[" then
                            kvps[kvp] = json.decode(s)
                        else
                            kvps[kvp] = s
                        end
                    elseif type == 1 then
                        kvps[kvp] = GetResourceKvpFloat(kvp)
                    elseif type == 2 then
                        kvps[kvp] = GetResourceKvpInt(kvp)
                    end
                end
                print(json.encode(kvps, { indent = true }) .. "\n")
    
                print("\n\nDumping a list of allowed permissions:")
                print(json.encode(Permissions, { indent = true }))
    
                print("\n\nDumping vmenu server configuration settings:")
                local settings = {}
                for _, setting in pairs(Setting) do
                    settings[setting] = GetSettingsString(setting)
                end
                print(json.encode(settings, { indent = true }))
                print("\nEnd of vMenu dump!")
                print("\n########################### vMenu ###########################")
            elseif args[1]:lower() == "dumplang" then
                if IsAllowed(Permission.DumpLang) then
                    TriggerEvent("vMenu:DumpLanguageTamplate:Client")
                else
                    Notify.Error("This is only for admins!")
                end
            end
        else
            Notify.Custom("vMenu is currently running version: " .. Version)
        end
    end, false)

    if GetCurrentResourceName() ~= "vMenu" then
        MenuController.MainMenu = nil
        MenuController.DontOpenAnyMenu = true
        MenuController.DisableMenuButtons = true
        error("\n[vMenu] INSTALLATION ERROR!\nThe name of the resource is not valid. Please change the folder name from '" .. GetCurrentResourceName() .. "' to 'vMenu' (case-sensitive)!\n")
    else
        CreateThread(function()
            while true do
                Wait(0)
                OnTick()
            end
        end)
    end
    
    -- Clear all previous pause menu info/brief messages on resource start.
    ClearBrief()

    -- Request the permissions data from the server.
    TriggerServerEvent("vMenu:RequestPermissions")

    -- Request server state from the server.
    TriggerServerEvent("vMenu:RequestServerState")

    -- Disables the menu toggle key
    MenuController.MenuToggleKey = -1
end)

RegisterNetEvent('vMenu:SetServerState', function(data)
    if data.IsInfity then
        PlayersList = InfinityPlayerList(Players)
    end
end)

RegisterNetEvent('vMenu:ReceivePlayerList', function(players)
    if PlayersList then
        PlayersList.ReceivedPlayerList(players)
    end
end)

function RequestPlayerCoordinates(serverId)
    local coords = vector3(0.0, 0.0, 0.0)
    local completed = false

    local CallbackFunction = function(data)
        coords = data
        completed = true
    end

    TriggerServerEvent("vMenu:GetPlayerCoords", serverId, CallbackFunction)

    while not completed do
        Wait(0)
    end

    return coords
end

function SetPermissions(permissionsList)
    vMenuShared.PermissionsManager.SetPermissions(permissionsList)

    VehicleSpawner.allowedCategories = {
        IsAllowed(Permission.VSCompacts, true),
        IsAllowed(Permission.VSSedans, true),
        IsAllowed(Permission.VSSUVs, true),
        IsAllowed(Permission.VSCoupes, true),
        IsAllowed(Permission.VSMuscle, true),
        IsAllowed(Permission.VSSportsClassic, true),
        IsAllowed(Permission.VSSports, true),
        IsAllowed(Permission.VSSuper, true),
        IsAllowed(Permission.VSMotorcycles, true),
        IsAllowed(Permission.VSOffRoad, true),
        IsAllowed(Permission.VSIndustrial, true),
        IsAllowed(Permission.VSUtility, true),
        IsAllowed(Permission.VSVans, true),
        IsAllowed(Permission.VSCycles, true),
        IsAllowed(Permission.VSBoats, true),
        IsAllowed(Permission.VSHelicopters, true),
        IsAllowed(Permission.VSPlanes, true),
        IsAllowed(Permission.VSService, true),
        IsAllowed(Permission.VSEmergency, true),
        IsAllowed(Permission.VSMilitary, true),
        IsAllowed(Permission.VSCommercial, true),
        IsAllowed(Permission.VSTrains, true),
        IsAllowed(Permission.VSOpenWheel, true)
    }
    ArePermissionsSetup = true

    while not ConfigOptionsSetupComplete do
        Wait(100)
    end

    PostPermissionsSetup()
end

function PostPermissionsSetup()
    local pvpMode = GetSettingsInt(Setting.vmenu_pvp_mode)

    if pvpMode == 1 then
        NetworkSetFriendlyFireOption(true)
        SetCanAttackFriendly(PlayerId(), true, false)
    elseif pvpMode == 2 then
        NetworkSetFriendlyFireOption(false)
        SetCanAttackFriendly(PlayerId(), false, false)
    end

    local function canUseMenu()
        if not GetSettingsBool(Setting.vmenu_menu_staff_only) then
            return true
        elseif IsAllowed(Permission.Staff) then
            return true
        end
        return false
    end

    if not canUseMenu() then
        MenuController.MainMenu = nil
        MenuController.DisableMenuButtons = true
        MenuController.DontOpenAnyMenu = true
        vMenuEnabled = false
        return
    end

    NoClipKey = GetSettingsString(Setting.vmenu_noclip_toggle_key) or "F2"

    -- Create the main menu and submenus.
    Menu = Lm.GetMenu(PlayerId(), "Main Menu")
    PlayerSubmenu = Lm.GetMenu(PlayerId(), "Player Related Options")
    VehicleSubmenu = Lm.GetMenu(PlayerId(), "Vehicle Related Options")
    WorldSubmenu = Lm.GetMenu(PlayerId(), "World Options")

    -- Add the main menu to the menu pool.
    MenuController.AddMenu(Menu)
    MenuController.MainMenu = Menu

    MenuController.AddSubmenu(Menu, PlayerSubmenu)
    MenuController.AddSubmenu(Menu, VehicleSubmenu)
    MenuController.AddSubmenu(Menu, WorldSubmenu)

    -- Create all (sub)menus.
    CreateSubmenus()

    -- Update the original language.
    LanguageManager.UpdateOriginalLanguage()

    if not GetSettingsBool(Setting.vmenu_disable_player_stats_setup) then
        -- Manage Stamina
        if PlayerOptionsMenu and PlayerOptionsMenu.PlayerStamina and IsAllowed(Permission.POUnlimitedStamina) then
            StatSetInt(GetHashKey("MP0_STAMINA"), 100, true)
        else
            StatSetInt(GetHashKey("MP0_STAMINA"), 0, true)
        end

        -- Manage other stats, in order of appearance in the pause menu (stats) page.
        StatSetInt(GetHashKey("MP0_SHOOTING_ABILITY"), 100, true)        -- Shooting
        StatSetInt(GetHashKey("MP0_STRENGTH"), 100, true)                -- Strength
        StatSetInt(GetHashKey("MP0_STEALTH_ABILITY"), 100, true)         -- Stealth
        StatSetInt(GetHashKey("MP0_FLYING_ABILITY"), 100, true)          -- Flying
        StatSetInt(GetHashKey("MP0_WHEELIE_ABILITY"), 100, true)         -- Driving
        StatSetInt(GetHashKey("MP0_LUNG_CAPACITY"), 100, true)           -- Lung Capacity
        StatSetFloat(GetHashKey("MP0_PLAYER_MENTAL_STATE"), 0.0, true)    -- Mental State
    end

    TriggerEvent("vMenu:SetupTickFunctions")
end

CreateThread(function()
    while true do
        Wait(0)

        -- If the setup (permissions) is done and it's not the first tick, then do this:
        if ConfigOptionsSetupComplete then
            local tmpMenu = GetOpenMenu()

            if MpPedCustomizationMenu then
                local function IsOpen()
                    return MpPedCustomizationMenu.appearanceMenu.Visible or
                        MpPedCustomizationMenu.faceShapeMenu.Visible or
                        MpPedCustomizationMenu.createCharacterMenu.Visible or
                        MpPedCustomizationMenu.inheritanceMenu.Visible or
                        MpPedCustomizationMenu.propsMenu.Visible or
                        MpPedCustomizationMenu.clothesMenu.Visible or
                        MpPedCustomizationMenu.tattoosMenu.Visible
                end

                if IsOpen() then
                    if tmpMenu == MpPedCustomizationMenu.createCharacterMenu then
                        MpPedCustomization.DisableBackButton = true
                    else
                        MpPedCustomization.DisableBackButton = false
                    end
                    MpPedCustomization.DontCloseMenus = true
                else
                    MpPedCustomization.DisableBackButton = false
                    MpPedCustomization.DontCloseMenus = false
                end
            end

            if IsDisabledControlJustReleased(0, Control.PhoneCancel) and MpPedCustomization.DisableBackButton then
                Wait(0)
                Notify.Alert("You must save your ped first before exiting, or click the ~r~Exit Without Saving~s~ button.")
            end
        end
    end
end)

function AddMenu(parentMenu, submenu, menuButton, grabForTranslation)
    parentMenu:AddMenuItem(menuButton)
    MenuController.AddSubmenu(parentMenu, submenu)
    MenuController.BindMenuItem(parentMenu, submenu, menuButton)
    submenu:RefreshIndex()

    -- Less code = better
    Lm.GetMenu(parentMenu)
    if grabForTranslation then
        Lm.GetMenu(submenu)
    end
end


function RecreateMenus()
    Menu:ClearMenuItems(true)
    Menu:RefreshIndex()

    if IsAllowed(Permission.PVMenu) then
        local menu = PersonalVehicleMenu.GetMenu()
        local button = MenuItem("~g~Personal Vehicle Options~s~", "Opens the personal vehicle submenu")
        button.Label = "→→→"
        AddMenu(Menu, menu, button)
    end

    if IsAllowed(Permission.OPMenu) then
        local menu = OnlinePlayersMenu.GetMenu()
        local button = MenuItem("Online Players", "All currently connected players")
        button.Label = "→→→"
        AddMenu(Menu, menu, button)
        
        Menu.OnItemSelect = function(sender, item, index)
            if item == button then
                PlayersList.RequestPlayerList()
                Citizen.Wait(0)
                OnlinePlayersMenu.UpdatePlayerlist()
                menu:RefreshIndex()
            end
        end
    end

    if IsAllowed(Permission.OPUnban) or IsAllowed(Permission.OPViewBannedPlayers) then
        local menu = BannedPlayersMenu.GetMenu()
        local button = MenuItem("Banned Players", "View and manage all banned players in this menu")
        button.Label = "→→→"
        AddMenu(Menu, menu, button)
        
        Menu.OnItemSelect = function(sender, item, index)
            if item == button then
                TriggerServerEvent("vMenu:RequestBanList", PlayerId())
                menu:RefreshIndex()
            end
        end
    end

    local playerSubmenuBtn = MenuItem("Player Related Options", "Open this submenu for player related subcategories")
    playerSubmenuBtn.Label = "→→→"
    Menu:AddMenuItem(playerSubmenuBtn)

    local vehicleSubmenuBtn = MenuItem("Vehicle Related Options", "Open this submenu for vehicle related subcategories")
    vehicleSubmenuBtn.Label = "→→→"
    Menu:AddMenuItem(vehicleSubmenuBtn)

    local worldSubmenuBtn = MenuItem("World Related Options", "Open this submenu for world related subcategories")
    if IsAllowed(Permission.CTWMenu) then
        Menu:AddMenuItem(worldSubmenuBtn)
        
        local menu2 = PlayerTimeWeatherOptionsMenu.GetMenu()
        local button2 = MenuItem("Time & Weather Options", "Change all time & weather related options here")
        button2.Label = "→→→"
        AddMenu(Menu, menu2, button2)
    end

    if IsAllowed(Permission.TPMenu) then
        local menu = TeleportOptionsMenu.GetMenu()
        local button = MenuItem("Teleport Related Options", "Open this submenu for teleport options")
        button.Label = "→→→"
        AddMenu(Menu, menu, button)
    end

    local menu = RecordingMenu.GetMenu()
    local button = MenuItem("Recording Options", "In-game recording options")
    button.Label = "→→→"
    AddMenu(Menu, menu, button)

    local spacer = GetSpacerMenuItem("~y~↓ Miscellaneous ↓")
    Menu:AddMenuItem(spacer)

    if IsAllowed(Permission.ECMenu) then
        local menu = EnhancedCameraMenu.GetMenu()
        local button = MenuItem("Enhanced Camera", "Opens the enhanced camera menu")
        button.Label = "→→→"
        AddMenu(Menu, menu, button)
    end

    if IsAllowed(Permission.PNMenu) then
        local menu = PluginSettingsMenu.GetMenu()
        local button = MenuItem("Plugins Menu", "Plugins settings/status")
        button.Label = "→→→"
        AddMenu(Menu, menu, button)
    end

    local menu = MiscSettingsMenu.GetMenu()
    local button = MenuItem("Misc Settings", "Miscellaneous vMenu options/settings can be configured here. You can also save your settings in this menu")
    button.Label = "→→→"
    AddMenu(Menu, menu, button)

    Menu.OnIndexChange = function(_, _, _newItem, _oldIndex, _newIndex)
        if spacer == _newItem then
            if _oldIndex < _newIndex then
                Menu:GoDown()
            else
                Menu:GoUp()
            end
        end
    end

    Menu.OnMenuClose = function()
        if MainMenu.MiscSettingsMenu.ResetIndex.Checked then
            Menu:RefreshIndex()
            for _, m in pairs(MenuController.Menus) do
                m:RefreshIndex()
            end
        end
    end

    local sub = AboutMenu.GetMenu()
    local btn = MenuItem("About vMenu", "Information about vMenu")
    btn.Label = "→→→"
    AddMenu(Menu, sub, btn)

    if not GetSettingsBool(Setting.vmenu_use_permissions) then
        Notify.Alert("vMenu is set up to ignore permissions, default permissions will be used")
    end

    if PlayerSubmenu.Size > 0 then
        MenuController.BindMenuItem(Menu, PlayerSubmenu, playerSubmenuBtn)
    else
        Menu:RemoveMenuItem(playerSubmenuBtn)
    end

    if VehicleSubmenu.Size > 0 then
        MenuController.BindMenuItem(Menu, VehicleSubmenu, vehicleSubmenuBtn)
    else
        Menu:RemoveMenuItem(vehicleSubmenuBtn)
    end

    if WorldSubmenu.Size > 0 then
        MenuController.BindMenuItem(Menu, WorldSubmenu, worldSubmenuBtn)
    else
        Menu:RemoveMenuItem(worldSubmenuBtn)
    end

    if MiscSettingsMenu ~= nil then
        MenuController.EnableMenuToggleKeyOnController = not MiscSettingsMenu.MiscDisableControllerSupport
    end
end

function CreateSubmenus()
    local OnlinePlayersMenu = nil

    if IsAllowed(Permission.OPMenu) then
        OnlinePlayersMenu = OnlinePlayers() -- Assuming OnlinePlayers() is a function to create your menu
        local menu = OnlinePlayersMenu:GetMenu()
        local button = NativeUI.CreateItem("Online Players", "All currently connected players.")
        button:RightLabel("→→→")
        Menu:AddItem(button)

        Menu.OnItemSelect = function(sender, item, index)
            if item == button then
                PlayersList.RequestPlayerList()
                OnlinePlayersMenu:UpdatePlayerlist()
                menu:RefreshIndex()
            end
        end
    end

    local BannedPlayersMenu = nil

    if IsAllowed(Permission.OPUnban) or IsAllowed(Permission.OPViewBannedPlayers) then
        BannedPlayersMenu = BannedPlayers() -- Assuming BannedPlayers() is a function to create your menu
        local menu = BannedPlayersMenu:GetMenu()
        local button = NativeUI.CreateItem("Banned Players", "View and manage all banned players in this menu.")
        button:RightLabel("→→→")
        Menu:AddItem(button)

        Menu.OnItemSelect = function(sender, item, index)
            if item == button then
                TriggerServerEvent("vMenu:RequestBanList", PlayerId()) -- Assuming PlayerId() gets the player's server ID
                menu:RefreshIndex()
            end
        end
    end


    local playerSubmenuBtn = NativeUI.CreateItem("Player Related Options", "Open this submenu for player related subcategories")
    playerSubmenuBtn:RightLabel("→→→")
    Menu:AddItem(playerSubmenuBtn)

    -- Add the player options menu.
    if IsAllowed(Permission.POMenu) then
        PlayerOptionsMenu = PlayerOptions() -- Assuming PlayerOptions() is a function to create your menu
        local menu = PlayerOptionsMenu:GetMenu()
        local button = NativeUI.CreateItem("Player Options", "Common player options can be accessed here")
        button:RightLabel("→→→")
        AddMenu(PlayerSubmenu, menu, button)
    end

end