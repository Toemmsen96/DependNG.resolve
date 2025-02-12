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

-- Function to delete exisiting engine swaps
local function deleteExisting()
    core_modmanager.deleteMod(GENERATED_PATH:gsub("/mods/unpacked/",''):lower())
end

local function checkForModName(nameToCheck)
    logToConsole('D', 'checkForModName', "Checking for mod: " .. nameToCheck)
    if not nameToCheck then return false end
    
    -- local modValid = core_modmanager.checkMod(nameToCheck)
    -- 
    -- 
    -- -- Check if mod exists and is valid
    -- if modValid then
    --     logToConsole('D', 'checkForModName', "Mod " .. nameToCheck .. " found and valid")
    --     return true
    -- end
    -- nameToCheck = nameToCheck:lower()
    -- modValid = core_modmanager.checkMod(nameToCheck)
    -- -- Check if mod exists and is valid
    -- if modValid then
    --     logToConsole('D', 'checkForModName', "Mod " .. nameToCheck .. " found and valid")
    --     return true
    -- end
    
    for _, mod in ipairs(core_modmanager.getMods()) do
        if mod.modname == nameToCheck then
            logToConsole('D', 'checkForModName', "Mod " .. nameToCheck .. " found and valid")
            if mod.active then
                logToConsole('D', 'checkForModName', "Mod " .. nameToCheck .. " is active")
                return true
            else 
                logToConsole('D', 'checkForModName', "Mod " .. nameToCheck .. " is not active, activating")
                core_modmanager.activateMod(mod.modname)
                return true
            end
        end
    end
    
    logToConsole('D', 'checkForModName', "Mod " .. nameToCheck .. " not found")
    return false
end

local function subscribeToGMSG()
    core_repository.modSubscribe("MFBSYCPZ9") -- GMSG ID
end

-- Function to handle extension loading
local function onModManagerReady()
    logToConsole('D', 'onExtensionLoaded', "gmsgDownloader extension loaded")
    if checkForModName("generalModSlotGenerator") then
        logToConsole('D', 'onExtensionLoaded', "generalModSlotGenerator found")
        GMSG_LOCAL_NAME = "generalModSlotGenerator"
        return
    else
        logToConsole('E', 'onExtensionLoaded', "generalModSlotGenerator not found")
    end
    if checkForModName("TommoT_GMSG") then
        logToConsole('D', 'onExtensionLoaded', "TommoT_GMSG found")
        GMSG_LOCAL_NAME = "TommoT_GMSG"
        return
    else
        logToConsole('E', 'onExtensionLoaded', "TommoT_GMSG not found")
    end
    if checkForModName("tommot_gmsg") then
        logToConsole('D', 'onExtensionLoaded', "gmsgDownloader found")
        GMSG_LOCAL_NAME = "tommot_gmsg"
        return
    else
        logToConsole('E', 'onExtensionLoaded', "gmsgDownloader not found")
    end
    guihooks.trigger('modmanagerError', "GMSG Downloader requires generalModSlotGenerator or TommoT_GMSG to be installed")

    subscribeToGMSG()

    --core_modmanager.initDB()
    -- deleteExisting()
    -- Create job with 1/60 second max time per frame
    --core_jobsystem.create(generateAllJob, 1/600)
end

-- Function to delete temporary files
local function unloadExtension()
    extensions.unloadExtension("gmsgDownloader")
end

-- Functions to be exported
M.onModManagerReady = onModManagerReady
M.onModDeactivated = unloadExtension
M.onModActivated = onModManagerReady
M.onExit = deleteTempFiles

return M
