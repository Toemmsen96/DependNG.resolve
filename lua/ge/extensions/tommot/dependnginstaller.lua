-- Installer UI for DependNG.resolve
-- This script provides a user interface for installing the DependNG.resolve extension into a mod, so that it can resolve dependencies for other mods.
-- Author: Toemmsen / TommoT, GitHub repository: https://github.com/Toemmsen96/DependNG.resolve

local M = {}
M.dependencies = {"ui_imgui"}
M.showUI = false

local imgui = ui_imgui
local style = imgui.GetStyle()
local ffi = require("ffi")

local TEMPLATE = "dependng_template.lua"
local MS_TEMPLATE = "ms_template.lua"
local TEMPLATE_DIR = "/lua/ge/extensions/tommot/templates/"
local CLOSE_TEXT = " Close Installer "

-- Settings
local possibleNames = ffi.new("char[?]", 256, "")
local moddersName = ffi.new("char[?]", 256, "")
local optionsID = {"Select", "Option 2", "Option 3", "Option 4"}
local optionsMods = {"Select", "Mod 2", "Mod 3", "Mod 4"}
local selectedOptionID = optionsID[1]
local selectedOptionMod = optionsMods[1]
local cachedModIDs = {} -- Used to install dependency for a mod
local cachedModNames = {} -- Used to install dep into a mod

local function toggleUI()
    M.showUI = not M.showUI
end

local function findModIDs()

    local modIDs = {}
    
    -- Also check mod_info directory
    if FS:directoryExists("mod_info") then
        local infoDirectories = FS:directoryList("mod_info")
        for _, dir in ipairs(infoDirectories) do
            local modID = dir:match("([^/\\]+)$")
            if modID and modID ~= "." and modID ~= ".." and not tableContains(modIDs, modID) then
                table.insert(modIDs, modID)
                log('D', 'findModIDs', "Found mod in mod_info: " .. modID)
            end
        end
    end

    return modIDs
end

local function findMods()
    local mods = core_modmanager.getMods()
    if not mods then
        log('E', 'findMods', "Failed to get mods list")
        return {}
    end

    return mods
end

local function installMod(modID, possibleNames,installToModName, moddersName)
    print("Installing mod with ID: " .. modID)
    print("Possible names: " .. possibleNames)
    print("Modder's name: " .. moddersName)
    print("Installing to mod: " .. installToModName)
    -- Check if modID is valid
    if not modID or modID == "Select" then
        log('W', 'installMod', "No mod ID selected")
        modID = ""
    end

    -- Check if possibleNames is valid
    if not possibleNames or possibleNames == "" then
        log('W', 'installMod', "No possible names entered")
        possibleNames = ""
    end

    -- Check if moddersName is valid
    if not moddersName or moddersName == "" then
        log('W', 'installMod', "No modder's name entered")
        return false
    end

    -- Create the file path
    if not core_modmanager.modIsUnpacked(installToModName) then
        log('W', 'installMod', "Mod " .. installToModName .. " is packed, cannot install DependNG.resolve")
        imgui.OpenPopup("Error##packedmod")
        return true -- Return true to prevent the error popup from showing
    end
    local targetModPath = "mods/unpacked/" .. installToModName .. "/lua/ge/extensions/" .. moddersName .. "/"
    local filePath = targetModPath .. modID.."Downloader.lua"

    -- Create the directories if they don't exist
    if not FS:directoryExists(targetModPath) then
        FS:directoryCreate(targetModPath, true)
    end

    -- Read template file
    local sourceFile = TEMPLATE_DIR .. TEMPLATE
    local content = readFile(sourceFile)
    
    if not content then
        log('E', 'installMod', "Failed to read template file")
        return false
    end
    
    -- Parse possible names into proper format
    local namesList = {}
    for name in string.gmatch(possibleNames, "[^,]+") do
        table.insert(namesList, '"' .. name:match("^%s*(.-)%s*$") .. '"')
    end
    local formattedNames = table.concat(namesList, ",\n        ")
    if formattedNames == "" then
        formattedNames = '"' .. modID .. '"'
    end
    
    -- Replace the configuration section
    local modifiedContent = content:gsub(
        "-- START OF ADJUSTMENTS .-END OF ADJUSTMENTS /\\.-/\\",
        "-- START OF ADJUSTMENTS \\/ EDIT BELOW THIS LINE \\/\n" ..
        "--------------------------------------------------------------------------------\n" ..
        "-- To adjust this to be used in your own extension, you need to change the following:\n" ..
        "local reqExtensionName = \"" .. modID .. "\" -- Name of the extension to check for, if it is a lua extension\n" ..
        "-- List of possible mod names to check, will get converted to lowercase\n" ..
        "local reqModNames = {\n" ..
        "        " .. formattedNames .. "\n" ..
        "}\n" ..
        "local reqModID = \"" .. modID .. "\" -- Mod ID to check for / subscribe to\n" ..
        "local creatorName = \"" .. moddersName .. "\" -- Name of the creator of this extension, needs to match the creator name in the extensions folder\n" ..
        "local extensionName = \""..modID.."Downloader\" -- Name of this extension, preferably using the reqModID and \"Downloader\" or similar, needs to match the name in the extensions folder\n" ..
        "local failureMessage = \"This mod requires ".. modID .. " to be installed\" -- Message to display if the required mod is not found\n" ..
        "--------------------------------------------------------------------------------\n" ..
        "-- END OF ADJUSTMENTS /\\ EDIT ABOVE THIS LINE /\\"
    )

    -- ModScript.lua
    local modScriptTemplatePath = TEMPLATE_DIR .. MS_TEMPLATE
    local modScriptContent = readFile(modScriptTemplatePath)
    local modScriptOutPath = "mods/unpacked/" .. installToModName .. "/scripts/" .. modID.."Downloader/modScript.lua"
    if not modScriptContent then
        log('E', 'installMod', "Failed to read ModScript.lua")
        return false
    end
    local modifiedModScriptContent = modScriptContent:gsub(
        "tommot_gmsgDownloader",
        moddersName.."_"..modID.."Downloader"
    )
    

    
    -- Write the modified file
    if writeFile(filePath, modifiedContent) and writeFile(modScriptOutPath, modifiedModScriptContent) then
        log('I', 'installMod', "Successfully installed DependNG.resolve at " .. filePath)
    return true

    else
        log('E', 'installMod', "Failed to write file at " .. filePath)
        return false
    end
    
end

local function renderToolTip(text)
    imgui.SameLine()
    imgui.TextDisabled("(?)")
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.Text(text)
        imgui.EndTooltip()
    end
end



local function renderTopBar()
    imgui.SetCursorPosY(-style.ItemSpacing.y + imgui.GetScrollY())
    imgui.PushFont3("cairo_bold")

    imgui.Text("DependNG.resolve Installer")

    imgui.SetCursorPosX(imgui.GetWindowWidth() - imgui.CalcTextSize(CLOSE_TEXT).x - style.FramePadding.x * 2 - style.WindowPadding.x)
    if imgui.Button(CLOSE_TEXT) then
        extensions.unload("tommot_dependnginstaller")
    end
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.Text("Close and unload the installer UI.")
        imgui.EndTooltip()
    end
    imgui.SetCursorPosX(0)
    imgui.PopFont()

    imgui.Separator()
end

local function render()
    imgui.SetNextWindowSizeConstraints(imgui.ImVec2(256, 256), imgui.ImVec2(512, 512))
    imgui.Begin("Barebones UI", nil, imgui.WindowFlags_NoTitleBar + imgui.WindowFlags_MenuBar)
    
    imgui.BeginMenuBar()
    renderTopBar()
    imgui.EndMenuBar()

    -- TODO: Add Checkboxes / Settings for options

    -- Option selection
    imgui.Text("Select an ModID:")
    renderToolTip("Enter the mod's Unique ID, found on BeamNG's mod-page under \"Information\".")

    if #cachedModIDs == 0 then
        cachedModIDs = findModIDs()
        optionsID = {"Select", unpack(cachedModIDs)}
    end

    if imgui.BeginCombo("##selectOptionID", selectedOptionID) then
        for _, option in ipairs(optionsID) do
            local displayText = option
            -- Only try to get mod name if it's not the "Select" placeholder
            if option ~= "Select" then
                local modName = core_modmanager.getModNameFromID(option)
                if modName then
                    displayText = option .. " (" .. modName .. ")"
                end
            end
            
            if imgui.Selectable1(displayText, option == selectedOptionID) then
                selectedOptionID = option
            end
        end
        imgui.EndCombo()
    end
    
    imgui.Text("Select a Mod to install DependNG.resolve into:")
    renderToolTip("This is the mod that will get DependNG.resolve installed into, so that it can resolve THIS mod's dependencies.")
    
    if #cachedModNames == 0 then
        local mods = findMods()
        for _, mod in pairs(mods) do
            if mod.modname then
                table.insert(cachedModNames, mod.modname)
            end
        end
        optionsMods = {"Select", unpack(cachedModNames)}
    end
    
    if imgui.BeginCombo("##selectOptionMod", selectedOptionMod) then
        for _, option in ipairs(optionsMods) do
            local displayText = option
            -- Only try to get mod name if it's not the "Select" placeholder
            if option ~= "Select" then
                local modName = core_modmanager.getModNameFromID(option)
                if modName then
                    displayText = option .. " (" .. modName .. ")"
                end
            end
            
            if imgui.Selectable1(displayText, option == selectedOptionMod) then
                selectedOptionMod = option
            end
        end
        imgui.EndCombo()
    end
    
    -- Text input
    imgui.Text("Enter possible names for the required mod, separated by a comma (,):")
    renderToolTip("These names will be used to check if the required mod is installed, in case the ModID is not present. Example: 'DependNG.resolve, DependNG Resolve, dependng.resolve'")
    imgui.InputText("##possibleNames", possibleNames, 256)
    
    imgui.Text("Enter your name:")
    renderToolTip("This is needed to save the generated files into a unique folder inside the extensions directory of the target mod.")
    imgui.InputText("##moddersName", moddersName, 256)

    -- Display selection
    imgui.Separator()
    imgui.Text("Selected Mod ID: " .. (selectedOptionID ~= "Select" and selectedOptionID or "None"))
    imgui.Text("Target Mod: " .. (selectedOptionMod ~= "Select" and selectedOptionMod or "None"))
    imgui.Text("Possible Names to check (for if ModID isn't present):")
    local namesStr = ffi.string(possibleNames)
    if namesStr ~= "" then
        for name in string.gmatch(namesStr, "[^,]+") do
            imgui.Text("  - " .. name:match("^%s*(.-)%s*$")) -- Trim whitespace
        end
    else
        imgui.Text("  (None entered)")
    end
    imgui.Text("Modder's Name: " .. (ffi.string(moddersName) ~= "" and ffi.string(moddersName) or "Not specified"))
    
    -- Action button
    if imgui.Button(" Install ") then
        
        -- Validate inputs before installation
        if selectedOptionID == "Select" then
            imgui.OpenPopup("Error##modid")
        elseif selectedOptionMod == "Select" then
            imgui.OpenPopup("Error##targetmod")
        elseif ffi.string(moddersName) == "" then
            imgui.OpenPopup("Error##modname")
        else
            if not installMod(selectedOptionID, ffi.string(possibleNames), selectedOptionMod, ffi.string(moddersName)) then
            imgui.OpenPopup("Error##installation")
            end
        end
    end
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.Text("Starts the installation of DependNG.resolve into the selected mod.")
        imgui.EndTooltip()
    end
    
    -- Error popups
    if imgui.BeginPopupModal("Error##modid", nil, imgui.WindowFlags_AlwaysAutoResize) then
        imgui.Text("Please select a valid Mod ID first.")
        if imgui.Button("OK") then imgui.CloseCurrentPopup() end
        imgui.EndPopup()
    end
    
    if imgui.BeginPopupModal("Error##targetmod", nil, imgui.WindowFlags_AlwaysAutoResize) then
        imgui.Text("Please select a target mod to install DependNG.resolve into.")
        if imgui.Button("OK") then imgui.CloseCurrentPopup() end
        imgui.EndPopup()
    end
    
    if imgui.BeginPopupModal("Error##modname", nil, imgui.WindowFlags_AlwaysAutoResize) then
        imgui.Text("Please enter your name.")
        if imgui.Button("OK") then imgui.CloseCurrentPopup() end
        imgui.EndPopup()
    end

    if imgui.BeginPopupModal("Error##packedmod", nil, imgui.WindowFlags_AlwaysAutoResize) then
        imgui.Text("The target mod is packed, cannot install DependNG.resolve.")
        imgui.Text("Do you want to unpack the mod?")
        if imgui.Button("NO") then imgui.CloseCurrentPopup() end
        if imgui.Button("YES") then 
            imgui.CloseCurrentPopup() 
            core_modmanager.unpackMod(selectedOptionMod)
        end
        imgui.EndPopup()
    end

    if imgui.BeginPopupModal("Error##installation", nil, imgui.WindowFlags_AlwaysAutoResize) then
        imgui.Text("Got an error while trying to intall DependNG.resolve. Check the log / console for more information.")
        if imgui.Button("OK") then imgui.CloseCurrentPopup() end
        imgui.EndPopup()
    end
    
    
    imgui.End()
end

local function onUpdate(dtReal)
    if not M.showUI then return end

    local success, err = pcall(render, dtReal)
    if not success and err then
        print("Error in onUpdate: " .. err)
    end
end

local function onExtensionLoaded()
    toggleUI()
end

local function onExtensionUnloaded()
    if M.showUI then
        toggleUI()
    end
end

M.onUpdate = onUpdate
M.toggleUI = toggleUI
M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded

return M
