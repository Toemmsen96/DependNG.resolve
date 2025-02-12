local M = {}
M.dependencies = {"core_modmanager"}
local LOGLEVEL = 2
local AUTOPACK = true
local GMSG_LOCAL_NAME = ""

--helpers
local function logToConsole(level, func, message)
    if LOGLEVEL == 0 then
        return
    end
    if level == 'D' and LOGLEVEL < 2 then
        return
    end
    if level == 'I' and LOGLEVEL < 1 then
        return
    end
    if level == 'W' and LOGLEVEL < 1 then
        return
    end
    if level == 'E' then
        log('E', func, message)
        return
    end
    log(level, "gmsgDownloader", func .. ": " .. message)
end

-- end helpers


local function checkForModName(nameToCheck)
    logToConsole('D', 'checkForModName', "Checking for mod: " .. nameToCheck)
    if not nameToCheck then return false end
    
    nameToCheck = nameToCheck:lower()
    local mods = core_modmanager.getMods()
    
    if not mods then
        logToConsole('E', 'checkForModName', "Failed to get mods list")
        return false
    end
    
    -- Iterate through mods table using pairs instead of ipairs
    for modId, mod in pairs(mods) do
        if mod and mod.modname and mod.modname:lower() == nameToCheck then
            logToConsole('D', 'checkForModName', "Found mod: " .. mod.modname)
            
            -- Check if mod is valid
            if not mod.valid then
                logToConsole('W', 'checkForModName', "Mod " .. mod.modname .. " is not valid")
                return false
            end
            
            -- Handle mod activation
            if not mod.active then
                logToConsole('D', 'checkForModName', "Activating mod: " .. modId)
                core_modmanager.activateMod(modId)
                logToConsole('D', 'checkForModName', "Mod " .. mod.modname .. " activated")
            end
            
            return true
        end
    end
    
    logToConsole('D', 'checkForModName', "Mod " .. nameToCheck .. " not found")
    return false
end

local function subscribeToGMSG()
    core_repository.modSubscribe("MFBSYCPZ9") -- GMSG ID
end

-- Function to delete temporary files
local function unloadExtension()
    extensions.unload("gmsgDownloader")
end

-- Function to handle extension loading
local function onModManagerReady()
    logToConsole('D', 'onModManagerReady', "gmsgDownloader extension loaded")
    
    -- List of possible mod names to check
    local modNames = {
        "generalModSlotGenerator",
        "TommoT_GMSG"
    }
    
    -- Check each mod name
    for _, modName in ipairs(modNames) do
        if checkForModName(modName) then
            GMSG_LOCAL_NAME = modName
            logToConsole('D', 'onModManagerReady', modName .. " found")
            unloadExtension()
            return
        end
        logToConsole('W', 'onModManagerReady', modName .. " not found")
    end
    
    -- If we get here, no compatible mod was found
    guihooks.trigger('modmanagerError', "GMSG Plugins require generalModSlotGenerator or TommoT_GMSG to be installed")
    subscribeToGMSG()
end



-- Functions to be exported
M.onModManagerReady = onModManagerReady
M.onModDeactivated = unloadExtension
M.onModActivated = onModManagerReady
M.onExit = deleteTempFiles

return M
