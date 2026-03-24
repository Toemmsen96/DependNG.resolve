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
local moddersName = ffi.new("char[?]", 256, "")
local optionsID = {"Select", "Option 2", "Option 3", "Option 4"}
local optionsMods = {"Select", "Mod 2", "Mod 3", "Mod 4"}
local selectedOptionMod = optionsMods[1]
local cachedModIDs = {} -- Used to install dependency for a mod
local cachedModNames = {} -- Used to install dep into a mod
local dependencyEntries = {
    {
        selectedModID = "Select",
        possibleNames = ffi.new("char[?]", 256, "")
    }
}
local installationWasSuccessful = false
local installationResultMessage = ""
local openRetryInstallPopup = false
local openExitInstallerPopup = false

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
    local escapedTargetModName = (installToModName or "This mod"):gsub("\\", "\\\\"):gsub('"', '\\"')
    
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
        "local failureMessage = \"" .. escapedTargetModName .. " requires ".. modID .. " to be installed\" -- Message to display if the required mod is not found\n" ..
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

local function addDependencyEntry()
    table.insert(dependencyEntries, {
        selectedModID = "Select",
        possibleNames = ffi.new("char[?]", 256, "")
    })
end

local function removeDependencyEntry(index)
    if #dependencyEntries > 1 then
        table.remove(dependencyEntries, index)
    end
end

local function pushRedButtonStyle()
    imgui.PushStyleColor2(imgui.Col_Button, imgui.ImVec4(0.75, 0.2, 0.2, 1.0))
    imgui.PushStyleColor2(imgui.Col_ButtonHovered, imgui.ImVec4(0.9, 0.25, 0.25, 1.0))
    imgui.PushStyleColor2(imgui.Col_ButtonActive, imgui.ImVec4(0.65, 0.15, 0.15, 1.0))
end

local function pushGreenButtonStyle()
    imgui.PushStyleColor2(imgui.Col_Button, imgui.ImVec4(0.2, 0.65, 0.25, 1.0))
    imgui.PushStyleColor2(imgui.Col_ButtonHovered, imgui.ImVec4(0.25, 0.8, 0.3, 1.0))
    imgui.PushStyleColor2(imgui.Col_ButtonActive, imgui.ImVec4(0.15, 0.55, 0.2, 1.0))
end

local function renderPopupNoYesButtons(noLabel, yesLabel)
    local yesWidth = imgui.CalcTextSize(yesLabel).x + style.FramePadding.x * 2
    local rightButtonX = imgui.GetWindowWidth() - style.WindowPadding.x - yesWidth
    local buttonRowY = imgui.GetCursorPosY()

    local noClicked = false
    local yesClicked = false

    pushRedButtonStyle()
    if imgui.Button(noLabel) then noClicked = true end
    imgui.PopStyleColor(3)

    imgui.SetCursorPosY(buttonRowY)
    imgui.SetCursorPosX(rightButtonX)
    pushGreenButtonStyle()
    if imgui.Button(yesLabel) then yesClicked = true end
    imgui.PopStyleColor(3)

    return noClicked, yesClicked
end

local function renderPopupGreenButton(label)
    local clicked = false
    pushGreenButtonStyle()
    if imgui.Button(label) then clicked = true end
    imgui.PopStyleColor(3)
    return clicked
end

local function validateInstallInputs()
    local hasSelectedDependency = false
    for _, dependency in ipairs(dependencyEntries) do
        if dependency.selectedModID ~= "Select" then
            hasSelectedDependency = true
            break
        end
    end

    if not hasSelectedDependency then
        imgui.OpenPopup("Error##modid")
        return false
    end
    if selectedOptionMod == "Select" then
        imgui.OpenPopup("Error##targetmod")
        return false
    end
    if ffi.string(moddersName) == "" then
        imgui.OpenPopup("Error##modname")
        return false
    end
    if not core_modmanager.modIsUnpacked(selectedOptionMod) then
        imgui.OpenPopup("Error##packedmod")
        return false
    end

    return true
end

local function runInstallForSelections()
    local dependencyCount = 0
    local hadInstallError = false

    for _, dependency in ipairs(dependencyEntries) do
        if dependency.selectedModID ~= "Select" then
            dependencyCount = dependencyCount + 1
            local installOk = installMod(
                dependency.selectedModID,
                ffi.string(dependency.possibleNames),
                selectedOptionMod,
                ffi.string(moddersName)
            )
            if not installOk then
                hadInstallError = true
                break
            end
        end
    end

    if hadInstallError then
        installationWasSuccessful = false
        installationResultMessage = "Installation failed while generating one or more dependency files."
    else
        installationWasSuccessful = true
        if dependencyCount == 1 then
            installationResultMessage = "Installation succeeded. Generated 2 files for 1 dependency."
        else
            installationResultMessage = "Installation succeeded. Generated " .. (dependencyCount * 2) .. " files for " .. dependencyCount .. " dependencies."
        end
    end

    imgui.OpenPopup("Install Result##summary")
end

local function render()
    imgui.SetNextWindowSizeConstraints(imgui.ImVec2(256, 256), imgui.ImVec2(512, 512))
    imgui.Begin("Barebones UI", nil, imgui.WindowFlags_NoTitleBar + imgui.WindowFlags_MenuBar)

    if openRetryInstallPopup then
        imgui.OpenPopup("Retry Install##afterunpack")
        openRetryInstallPopup = false
    end
    if openExitInstallerPopup then
        imgui.OpenPopup("Exit Installer##afterflow")
        openExitInstallerPopup = false
    end
    
    imgui.BeginMenuBar()
    renderTopBar()
    imgui.EndMenuBar()

    -- TODO: Add Checkboxes / Settings for options

    -- Dependency selection
    imgui.Text("Select dependencies:")
    renderToolTip("Pick one or more required Mod IDs. One downloader extension and one modScript file will be generated per selected dependency.")

    if #cachedModIDs == 0 then
        cachedModIDs = findModIDs()
        optionsID = {"Select", unpack(cachedModIDs)}
    end

    for i, dependency in ipairs(dependencyEntries) do
        imgui.Separator()
        imgui.Text("Dependency " .. i)

        if imgui.BeginCombo("##selectOptionID" .. i, dependency.selectedModID) then
            for _, option in ipairs(optionsID) do
                local displayText = option
                -- Only try to get mod name if it's not the "Select" placeholder
                if option ~= "Select" then
                    local modName = core_modmanager.getModNameFromID(option)
                    if modName then
                        displayText = option .. " (" .. modName .. ")"
                    end
                end

                if imgui.Selectable1(displayText, option == dependency.selectedModID) then
                    dependency.selectedModID = option
                end
            end
            imgui.EndCombo()
        end

        imgui.Text("Possible names for dependency " .. i .. " (comma-separated):")
        imgui.InputText("##possibleNames" .. i, dependency.possibleNames, 256)

        if #dependencyEntries > 1 and i > 1 then
            imgui.SameLine()
            imgui.PushStyleColor2(imgui.Col_Button, imgui.ImVec4(0.75, 0.2, 0.2, 1.0))
            imgui.PushStyleColor2(imgui.Col_ButtonHovered, imgui.ImVec4(0.9, 0.25, 0.25, 1.0))
            imgui.PushStyleColor2(imgui.Col_ButtonActive, imgui.ImVec4(0.65, 0.15, 0.15, 1.0))
            if imgui.Button(" X ##removeDependency" .. i) then
                removeDependencyEntry(i)
                imgui.PopStyleColor(3)
                break
            end
            imgui.PopStyleColor(3)
        end
    end

    if imgui.Button(" Add Dependency ") then
        addDependencyEntry()
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
    
    imgui.Text("Enter your name:")
    renderToolTip("This is needed to save the generated files into a unique folder inside the extensions directory of the target mod.")
    imgui.InputText("##moddersName", moddersName, 256)

    -- Display selection
    imgui.Separator()
    imgui.Text("Selected Dependencies:")
    local selectedDependencyCount = 0
    for _, dependency in ipairs(dependencyEntries) do
        if dependency.selectedModID ~= "Select" then
            selectedDependencyCount = selectedDependencyCount + 1
            imgui.Text("  - " .. dependency.selectedModID)
        end
    end
    if selectedDependencyCount == 0 then
        imgui.Text("  (None selected)")
    end

    imgui.Text("Target Mod: " .. (selectedOptionMod ~= "Select" and selectedOptionMod or "None"))

    imgui.Text("Modder's Name: " .. (ffi.string(moddersName) ~= "" and ffi.string(moddersName) or "Not specified"))
    
    -- Action button
    if imgui.Button(" Install ") then
        if validateInstallInputs() then
            runInstallForSelections()
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
        if renderPopupGreenButton("OK") then imgui.CloseCurrentPopup() end
        imgui.EndPopup()
    end
    
    if imgui.BeginPopupModal("Error##targetmod", nil, imgui.WindowFlags_AlwaysAutoResize) then
        imgui.Text("Please select a target mod to install DependNG.resolve into.")
        if renderPopupGreenButton("OK") then imgui.CloseCurrentPopup() end
        imgui.EndPopup()
    end
    
    if imgui.BeginPopupModal("Error##modname", nil, imgui.WindowFlags_AlwaysAutoResize) then
        imgui.Text("Please enter your name.")
        if renderPopupGreenButton("OK") then imgui.CloseCurrentPopup() end
        imgui.EndPopup()
    end

    imgui.SetNextWindowSize(imgui.ImVec2(420, 0), imgui.Cond_Appearing)
    if imgui.BeginPopupModal("Error##packedmod", nil, 0) then
        imgui.Text("The target mod is packed, cannot install DependNG.resolve.")
        imgui.Text("Do you want to unpack the mod?")

        local noClicked, yesClicked = renderPopupNoYesButtons("NO", "YES")
        if noClicked then
            imgui.CloseCurrentPopup()
        end
        if yesClicked then
            imgui.CloseCurrentPopup() 
            core_modmanager.unpackMod(selectedOptionMod)
            openRetryInstallPopup = true
        end
        imgui.EndPopup()
    end

    if imgui.BeginPopupModal("Retry Install##afterunpack", nil, imgui.WindowFlags_AlwaysAutoResize) then
        imgui.Text("Mod unpacked. Try installing again now?")

        local noClicked, yesClicked = renderPopupNoYesButtons("NO##retryinstall", "YES##retryinstall")
        if noClicked then
            imgui.CloseCurrentPopup()
        end
        if yesClicked then
            imgui.CloseCurrentPopup()
            if validateInstallInputs() then
                runInstallForSelections()
            end
        end
        imgui.EndPopup()
    end

    if imgui.BeginPopupModal("Error##installation", nil, imgui.WindowFlags_AlwaysAutoResize) then
        imgui.Text("Got an error while trying to intall DependNG.resolve. Check the log / console for more information.")
        if renderPopupGreenButton("OK") then imgui.CloseCurrentPopup() end
        imgui.EndPopup()
    end

    if imgui.BeginPopupModal("Install Result##summary", nil, imgui.WindowFlags_AlwaysAutoResize) then
        imgui.Text(installationResultMessage)

        if installationWasSuccessful then
            imgui.Separator()
            imgui.Text("Do you want to pack the target mod again now?")

            local noClicked, yesClicked = renderPopupNoYesButtons("NO##packmod", "YES##packmod")
            if noClicked then
                imgui.CloseCurrentPopup()
                openExitInstallerPopup = true
            end
            if yesClicked then
                local packSucceeded = false
                local targetModFolderPath = "mods/unpacked/" .. selectedOptionMod
                if core_modmanager.packMod then
                    local ok = pcall(core_modmanager.packMod, targetModFolderPath)
                    packSucceeded = ok
                end

                if not packSucceeded then
                    log('E', 'installResult', "Failed to pack mod at " .. targetModFolderPath .. " after successful installation")
                end
                imgui.CloseCurrentPopup()
                openExitInstallerPopup = true
            end
        else
            if renderPopupGreenButton("OK##installresult") then
                imgui.CloseCurrentPopup()
                openExitInstallerPopup = true
            end
        end
        imgui.EndPopup()
    end

    if imgui.BeginPopupModal("Exit Installer##afterflow", nil, imgui.WindowFlags_AlwaysAutoResize) then
        imgui.Text("All done. Do you want to exit the installer?")

        local noClicked, yesClicked = renderPopupNoYesButtons("NO##exitinstaller", "YES##exitinstaller")
        if noClicked then
            imgui.CloseCurrentPopup()
        end
        if yesClicked then
            imgui.CloseCurrentPopup()
            extensions.unload("tommot_dependnginstaller")
        end
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
