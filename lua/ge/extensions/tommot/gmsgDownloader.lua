-- Dependency resolver for BeamNG.drive by Toemmsen / TommoT
-- This extension is used to check for the presence of the generalModSlotGenerator / MultiSlot mods
-- If neither mod is found, the extension will subscribe to the GMSG repository and wait for the user to install the mod
-- Once the mod is installed, the extension will activate the mod and unload itself
-- If the mod is already installed, the extension will activate the mod and unload itself

local M = {}
M.dependencies = {"core_modmanager"}
local LOGLEVEL = 2


-- To adjust this to be used in your own extension, you need to change the following:
local reqExtensionName = "tommot_modslotGenerator" -- Name of the extension to check for, if it is a lua extension
-- List of possible mod names to check, will get converted to lowercase
local reqModNames = {
        "generalModSlotGenerator",
        "TommoT_GMSG"
}
local reqModID = "MFBSYCPZ9" -- Mod ID to check for / subscribe to
local extensionName = "gmsgDownloader" -- Name of this extension, preferably using the reqModID and "Downloader" or similar, needs to match the name in the extensions folder
local failureMessage = "GMSG Plugins require generalModSlotGenerator or TommoT_GMSG to be installed" -- Message to display if the required mod is not found
-- End of adjustments


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
    log(level, extensionName, func .. ": " .. message)
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
            -- if not mod.valid then
            --     logToConsole('W', 'checkForModName', "Mod " .. mod.modname .. " is not valid")
            --     return false
            -- end
            
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

local function subscribeToRequiredMod()
    core_repository.modSubscribe(reqModID) -- GMSG ID
end

-- Function to delete temporary files
local function unloadExtension()
    extensions.unload(extensionName)
end

-- Function to handle extension loading
local function onModManagerReady()
    logToConsole('D', 'onModManagerReady', extensionName .. "-dep-resolver extension loaded")

    if extensions.isExtensionLoaded(reqExtensionName) then
        logToConsole('D', 'onModManagerReady', reqExtensionName.." found and already loaded")
        unloadExtension()
        return
    end
    
    -- Check each mod name
    for _, modName in ipairs(reqModNames) do
        if checkForModName(modName) then
            logToConsole('D', 'onModManagerReady', modName .. " found")
            unloadExtension()
            return
        end
        logToConsole('W', 'onModManagerReady', modName .. " not found")
    end
    
    -- If we get here, no compatible mod was found
    guihooks.trigger('modmanagerError', failureMessage)
    subscribeToRequiredMod()
end



-- Functions to be exported
M.onModManagerReady = onModManagerReady
M.onModDeactivated = unloadExtension
M.onModActivated = onModManagerReady
--M.onExit = deleteTempFiles

return M
