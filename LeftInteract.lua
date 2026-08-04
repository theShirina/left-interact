local ADDON_NAME = "LeftInteract"
local ADDON_VERSION = GetAddOnMetadata and GetAddOnMetadata(ADDON_NAME, "Version") or "dev"

LeftInteractDB = LeftInteractDB or {}

local controller = CreateFrame("Frame", "LeftInteractController")
local pendingAction = nil
local active = false
local cursorHasItem = false
local cursorCheckElapsed = 0
local optionsFrame = nil
local minimapButton = nil
local ToggleGUI = nil
local leftDownTime = nil
local leftDownX = nil
local leftDownY = nil
local deselectBlockedWarningShown = false
local appliedMode = nil
local appliedRightMove = nil
local appliedMovementMode = nil

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff62d8ffLeft Interact:|r " .. message)
end

local function InCombat()
    return InCombatLockdown and InCombatLockdown()
end

local function ConfigSummary(mode, rightMove, movementMode)
    local interaction
    if mode == "cursor" then
        interaction = "Item drag"
    else
        interaction = mode == "mouseover" and "NPC only" or "World"
    end
    local movement = movementMode == "combined" and "W-compatible" or "Seamless"
    local rightClick = rightMove and "R-click on" or "R-click off"
    return interaction .. " / " .. movement .. " / " .. rightClick
end

local function DesiredConfigSummary()
    return ConfigSummary(LeftInteractDB.mode, LeftInteractDB.rightMove, LeftInteractDB.movementMode)
end

local function EffectiveConfigSummary()
    if not active then
        return "native bindings"
    end
    local effectiveMode = cursorHasItem and "cursor" or appliedMode
    return ConfigSummary(effectiveMode, appliedRightMove, appliedMovementMode)
end

local function DesiredMatchesApplied()
    return active
        and appliedMode == LeftInteractDB.mode
        and appliedRightMove == (LeftInteractDB.rightMove and true or false)
        and appliedMovementMode == LeftInteractDB.movementMode
end

local function ApplyBindings(silent)
    if InCombat() then
        if DesiredMatchesApplied() then
            pendingAction = nil
            if not silent then
                Print("Already enabled; no binding change is pending.")
            end
            if optionsFrame and optionsFrame.Refresh then
                optionsFrame:Refresh()
            end
            return true
        end
        pendingAction = active and "refresh" or "enable"
        if not silent then
            if active then
                Print("Changes will apply after combat.")
            else
                Print("Will enable after combat.")
            end
        end
        return false
    end

    ClearOverrideBindings(controller)

    local action = "TURNORACTION"
    cursorHasItem = CursorHasItem and CursorHasItem() and true or false
    if cursorHasItem then
        -- Native left click is required to drop or delete an item carried by
        -- the cursor. Interaction mode returns as soon as the cursor is clear.
        action = "CAMERAORSELECTORMOVE"
    elseif LeftInteractDB.mode == "mouseover" then
        action = "INTERACTMOUSEOVER"
    end

    -- TURNORACTION is the client's native right-click world action. It handles
    -- NPCs, loot, gathering nodes, and quest objects. The override is temporary:
    -- it does not rewrite bindings-cache.wtf.
    SetOverrideBinding(controller, true, "BUTTON1", action)

    -- The 3.3.5 client offers two useful protected movement actions. MOVEFORWARD
    -- can be re-pressed while left stays held, while MOVEANDSTEER does not share
    -- W's movement state. The user can switch between them with /li movement.
    if LeftInteractDB.rightMove then
        local movementAction = LeftInteractDB.movementMode == "combined" and "MOVEANDSTEER" or "MOVEFORWARD"
        SetOverrideBinding(controller, true, "BUTTON2", movementAction)
        SetOverrideBinding(controller, true, "SHIFT-BUTTON2", "TURNORACTION")

    end

    -- Keep the original left-click select/camera action available as an escape
    -- hatch while the accessibility binding is enabled.
    SetOverrideBinding(controller, true, "SHIFT-BUTTON1", "CAMERAORSELECTORMOVE")

    active = true
    appliedMode = LeftInteractDB.mode
    appliedRightMove = LeftInteractDB.rightMove and true or false
    appliedMovementMode = LeftInteractDB.movementMode
    pendingAction = nil

    if not silent then
        local movement = LeftInteractDB.rightMove and " Right click controls forward movement; hold left click to steer." or ""
        if LeftInteractDB.mode == "mouseover" then
            Print("Enabled in NPC mouseover mode." .. movement .. " Shift + left click keeps normal left-click behavior.")
        else
            Print("Enabled for NPCs, loot, gathering nodes, and quest objects." .. movement .. " Shift + left click keeps normal left-click behavior.")
        end
    end

    if optionsFrame and optionsFrame.Refresh then
        optionsFrame:Refresh()
    end

    return true
end

local function RemoveBindings(silent)
    if InCombat() then
        if not active then
            pendingAction = nil
            if not silent then
                Print("Already disabled; no binding change is pending.")
            end
            if optionsFrame and optionsFrame.Refresh then
                optionsFrame:Refresh()
            end
            return true
        end
        pendingAction = "disable"
        if not silent then
            Print("Will disable after combat.")
        end
        return false
    end

    ClearOverrideBindings(controller)
    active = false
    appliedMode = nil
    appliedRightMove = nil
    appliedMovementMode = nil
    pendingAction = nil

    if not silent then
        Print("Disabled; normal left-click behavior restored.")
    end

    if optionsFrame and optionsFrame.Refresh then
        optionsFrame:Refresh()
    end

    return true
end

local function SetEnabled(enabled, silent)
    LeftInteractDB.enabled = enabled and true or false
    if LeftInteractDB.enabled then
        return ApplyBindings(silent)
    end
    return RemoveBindings(silent)
end

local function ShowStatus()
    if pendingAction == "enable" then
        Print("Status: disabled; queued after combat: enable with " .. DesiredConfigSummary() .. ".")
    elseif pendingAction == "disable" then
        Print("Status: enabled; active: " .. EffectiveConfigSummary() .. "; queued after combat: disable.")
    elseif pendingAction == "refresh" then
        Print("Status: enabled; active: " .. EffectiveConfigSummary() .. "; queued after combat: " .. DesiredConfigSummary() .. ".")
    elseif active then
        Print("Status: enabled; active: " .. EffectiveConfigSummary() .. ".")
    else
        Print("Status: disabled; active: native bindings.")
    end
end

local function PrintSettingChange(applied, activeMessage, queuedMessage, savedMessage)
    if not LeftInteractDB.enabled then
        Print(savedMessage)
    elseif applied then
        Print(activeMessage)
    else
        Print(queuedMessage)
    end
end

SLASH_LEFTINTERACT1 = "/leftinteract"
SLASH_LEFTINTERACT2 = "/li"
SlashCmdList.LEFTINTERACT = function(message)
    local command, argument = string.match(string.lower(message or ""), "^%s*(%S*)%s*(.-)%s*$")

    if command == "on" or command == "enable" then
        SetEnabled(true, false)
    elseif command == "off" or command == "disable" then
        SetEnabled(false, false)
    elseif command == "toggle" then
        SetEnabled(not LeftInteractDB.enabled, false)
    elseif command == "status" then
        ShowStatus()
    elseif command == "mode" then
        if argument == "action" or argument == "world" then
            LeftInteractDB.mode = "action"
            local applied = true
            if LeftInteractDB.enabled then
                applied = ApplyBindings(true)
            end
            PrintSettingChange(applied, "Mode set to full world interaction.", "Full world interaction queued for after combat.", "Full world interaction saved for the next enable.")
        elseif argument == "mouseover" or argument == "npc" then
            LeftInteractDB.mode = "mouseover"
            local applied = true
            if LeftInteractDB.enabled then
                applied = ApplyBindings(true)
            end
            PrintSettingChange(applied, "Mode set to NPC mouseover.", "NPC mouseover mode queued for after combat.", "NPC mouseover mode saved for the next enable.")
        else
            Print("Modes: /leftinteract mode action  or  /leftinteract mode mouseover")
        end
    elseif command == "rightmove" then
        if argument == "on" or argument == "enable" then
            LeftInteractDB.rightMove = true
            local applied = true
            if LeftInteractDB.enabled then
                applied = ApplyBindings(true)
            end
            PrintSettingChange(applied, "Right click now controls forward movement. Hold left click to steer. Shift + right click keeps the original right-click action.", "Right-click movement queued for after combat.", "Right-click movement saved for the next enable.")
        elseif argument == "off" or argument == "disable" then
            LeftInteractDB.rightMove = false
            local applied = true
            if LeftInteractDB.enabled then
                applied = ApplyBindings(true)
            end
            PrintSettingChange(applied, "Normal right-click behavior restored.", "Normal right-click behavior queued for after combat.", "Normal right-click behavior saved for the next enable.")
        else
            Print("Use /leftinteract rightmove on  or  /leftinteract rightmove off")
        end
    elseif command == "movement" then
        if argument == "independent" or argument == "forward" then
            LeftInteractDB.movementMode = "independent"
            local applied = true
            if LeftInteractDB.enabled then
                applied = ApplyBindings(true)
            end
            PrintSettingChange(applied, "Independent movement enabled. Right click can be re-pressed while left remains held; W shares the client's forward state.", "Seamless-left-hold movement queued for after combat.", "Seamless-left-hold movement saved for the next enable.")
        elseif argument == "combined" or argument == "steer" then
            LeftInteractDB.movementMode = "combined"
            local applied = true
            if LeftInteractDB.enabled then
                applied = ApplyBindings(true)
            end
            PrintSettingChange(applied, "Combined movement enabled. W will not conflict; restarting right-click movement may require releasing left click.", "W-compatible movement queued for after combat.", "W-compatible movement saved for the next enable.")
        else
            Print("Use /leftinteract movement independent or combined")
        end
    elseif command == "gui" or command == "options" then
        if ToggleGUI then
            ToggleGUI()
        end
    else
        Print("Commands: gui, on, off, toggle, status, rightmove on/off, movement independent/combined, mode action/mouseover")
    end
end

local function MakeLabel(parent, text, size)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetText(text)
    if size then
        label:SetFont("Fonts\\FRIZQT__.TTF", size)
    end
    return label
end

local function SetupEmptyClickDeselect()
    if not WorldFrame or WorldFrame.leftInteractDeselectHooked then
        return
    end
    WorldFrame.leftInteractDeselectHooked = true

    WorldFrame:HookScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" or not active or not LeftInteractDB.emptyClickDeselect then
            leftDownTime = nil
            return
        end
        leftDownTime = GetTime()
        leftDownX, leftDownY = GetCursorPosition()
    end)

    WorldFrame:HookScript("OnMouseUp", function(self, button)
        if button ~= "LeftButton" or not leftDownTime then
            return
        end

        local downTime, downX, downY = leftDownTime, leftDownX, leftDownY
        leftDownTime, leftDownX, leftDownY = nil, nil, nil

        if not active or not LeftInteractDB.emptyClickDeselect or InCombat() or cursorHasItem or (CursorHasItem and CursorHasItem()) then
            return
        end
        if UnitExists("mouseover") or not UnitExists("target") then
            return
        end

        local upX, upY = GetCursorPosition()
        local dx, dy = upX - downX, upY - downY
        if GetTime() - downTime > 0.28 or (dx * dx + dy * dy) > 64 then
            return
        end

        local ok = pcall(ClearTarget)
        if not ok and not deselectBlockedWarningShown then
            deselectBlockedWarningShown = true
            Print("This client blocked experimental empty-click deselection. Shift + left click still works.")
        end
    end)
end

local function CreateOptionsGUI()
    if optionsFrame then
        return
    end

    local frame = CreateFrame("Frame", "LeftInteractOptionsFrame", UIParent)
    frame:SetWidth(480)
    frame:SetHeight(450)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:Hide()
    optionsFrame = frame
    table.insert(UISpecialFrames, "LeftInteractOptionsFrame")

    local header = frame:CreateTexture(nil, "BACKGROUND")
    header:SetTexture("Interface\\Buttons\\WHITE8X8")
    header:SetVertexColor(0.025, 0.11, 0.17, 0.96)
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -12)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -12)
    header:SetHeight(55)

    local accent = frame:CreateTexture(nil, "ARTWORK")
    accent:SetTexture("Interface\\Buttons\\WHITE8X8")
    accent:SetVertexColor(0.2, 0.75, 1, 1)
    accent:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
    accent:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
    accent:SetHeight(2)

    local titleIcon = frame:CreateTexture(nil, "ARTWORK")
    titleIcon:SetTexture("Interface\\Icons\\Ability_Rogue_Sprint")
    titleIcon:SetWidth(36); titleIcon:SetHeight(36)
    titleIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -21)
    titleIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local title = MakeLabel(frame, "Left Interact", 20)
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 70, -20)
    local subtitle = MakeLabel(frame, "Accessibility controls for WotLK 3.3.5a", 12)
    subtitle:SetTextColor(0.55, 0.8, 1)
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)

    local version = MakeLabel(frame, "v" .. ADDON_VERSION, 11)
    version:SetTextColor(0.55, 0.65, 0.7)
    version:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -48, -31)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

    local enabled = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    enabled:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -76)
    local enabledText = MakeLabel(frame, "Enable Left Interact", 14)
    enabledText:SetPoint("LEFT", enabled, "RIGHT", 4, 1)
    enabled:SetScript("OnClick", function(self)
        SetEnabled(self:GetChecked() and true or false, false)
        frame:Refresh()
    end)
    frame.enabledCheck = enabled

    local movementCard = frame:CreateTexture(nil, "BACKGROUND")
    movementCard:SetTexture("Interface\\Buttons\\WHITE8X8")
    movementCard:SetVertexColor(0.06, 0.075, 0.09, 0.88)
    movementCard:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -112)
    movementCard:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -18, -244)

    local moveTitle = MakeLabel(frame, "MOVEMENT", 13)
    moveTitle:SetTextColor(0.3, 0.8, 1)
    moveTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 30, -124)

    local combined = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    combined:SetWidth(198); combined:SetHeight(28)
    combined:SetPoint("TOPLEFT", moveTitle, "BOTTOMLEFT", 0, -10)
    combined:SetScript("OnClick", function()
        LeftInteractDB.movementMode = "combined"
        LeftInteractDB.rightMove = true
        if LeftInteractDB.enabled then ApplyBindings(true) end
        frame:Refresh()
    end)
    frame.combinedButton = combined

    local independent = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    independent:SetWidth(198); independent:SetHeight(28)
    independent:SetPoint("LEFT", combined, "RIGHT", 12, 0)
    independent:SetScript("OnClick", function()
        LeftInteractDB.movementMode = "independent"
        LeftInteractDB.rightMove = true
        if LeftInteractDB.enabled then ApplyBindings(true) end
        frame:Refresh()
    end)
    frame.independentButton = independent

    local rightMove = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    rightMove:SetPoint("TOPLEFT", combined, "BOTTOMLEFT", 0, -8)
    local rightMoveText = MakeLabel(frame, "Use right click for movement", 13)
    rightMoveText:SetPoint("LEFT", rightMove, "RIGHT", 4, 1)
    rightMove:SetScript("OnClick", function(self)
        LeftInteractDB.rightMove = self:GetChecked() and true or false
        if LeftInteractDB.enabled then ApplyBindings(true) end
        frame:Refresh()
    end)
    frame.rightMoveCheck = rightMove

    local movementHelp = MakeLabel(frame, "", 11)
    movementHelp:SetTextColor(0.65, 0.7, 0.74)
    movementHelp:SetWidth(400)
    movementHelp:SetJustifyH("LEFT")
    movementHelp:SetPoint("TOPLEFT", rightMove, "BOTTOMLEFT", 3, -3)
    frame.movementHelp = movementHelp

    local interactionCard = frame:CreateTexture(nil, "BACKGROUND")
    interactionCard:SetTexture("Interface\\Buttons\\WHITE8X8")
    interactionCard:SetVertexColor(0.06, 0.075, 0.09, 0.88)
    interactionCard:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -252)
    interactionCard:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -18, -374)

    local interactTitle = MakeLabel(frame, "INTERACTION", 13)
    interactTitle:SetTextColor(0.3, 0.8, 1)
    interactTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 30, -264)

    local world = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    world:SetWidth(198); world:SetHeight(28)
    world:SetPoint("TOPLEFT", interactTitle, "BOTTOMLEFT", 0, -10)
    world:SetScript("OnClick", function()
        LeftInteractDB.mode = "action"
        if LeftInteractDB.enabled then ApplyBindings(true) end
        frame:Refresh()
    end)
    frame.worldButton = world

    local mouseover = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    mouseover:SetWidth(198); mouseover:SetHeight(28)
    mouseover:SetPoint("LEFT", world, "RIGHT", 12, 0)
    mouseover:SetScript("OnClick", function()
        LeftInteractDB.mode = "mouseover"
        if LeftInteractDB.enabled then ApplyBindings(true) end
        frame:Refresh()
    end)
    frame.mouseoverButton = mouseover

    local deselect = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    deselect:SetPoint("TOPLEFT", world, "BOTTOMLEFT", 0, -8)
    local deselectText = MakeLabel(frame, "Short empty click clears target outside combat (experimental)", 11)
    deselectText:SetPoint("LEFT", deselect, "RIGHT", 4, 1)
    deselect:SetScript("OnClick", function(self)
        LeftInteractDB.emptyClickDeselect = self:GetChecked() and true or false
        frame:Refresh()
    end)
    frame.deselectCheck = deselect

    local hint = MakeLabel(frame, "Item dragging uses native click.  |  Shift + left is always native.", 11)
    hint:SetTextColor(0.7, 0.7, 0.7)
    hint:SetPoint("BOTTOM", frame, "BOTTOM", 0, 54)

    local status = MakeLabel(frame, "", 11)
    status:SetWidth(440)
    status:SetJustifyH("CENTER")
    status:SetPoint("BOTTOM", frame, "BOTTOM", 0, 20)
    frame.statusText = status

    function frame:Refresh()
        self.enabledCheck:SetChecked(LeftInteractDB.enabled and true or false)
        self.rightMoveCheck:SetChecked(LeftInteractDB.rightMove and true or false)
        self.deselectCheck:SetChecked(LeftInteractDB.emptyClickDeselect and true or false)
        local combinedSelected = LeftInteractDB.movementMode == "combined"
        local independentSelected = LeftInteractDB.movementMode == "independent"
        self.combinedButton:SetText(combinedSelected and ">  W-compatible" or "W-compatible")
        self.independentButton:SetText(independentSelected and ">  Seamless left hold" or "Seamless left hold")
        if combinedSelected then self.combinedButton:LockHighlight() else self.combinedButton:UnlockHighlight() end
        if independentSelected then self.independentButton:LockHighlight() else self.independentButton:UnlockHighlight() end
        if independentSelected then
            self.movementHelp:SetText("Keeps left steering active when right click is released. Forward keys share the old client state.")
        else
            self.movementHelp:SetText("Keeps W independent from mouse movement. Releasing right click may reset a held left click.")
        end

        local worldSelected = LeftInteractDB.mode == "action"
        local mouseoverSelected = LeftInteractDB.mode == "mouseover"
        self.worldButton:SetText(worldSelected and ">  NPCs + world objects" or "NPCs + world objects")
        self.mouseoverButton:SetText(mouseoverSelected and ">  NPC mouseover only" or "NPC mouseover only")
        if worldSelected then self.worldButton:LockHighlight() else self.worldButton:UnlockHighlight() end
        if mouseoverSelected then self.mouseoverButton:LockHighlight() else self.mouseoverButton:UnlockHighlight() end
        local state
        if pendingAction == "enable" then
            state = "Disabled\nQueued: enable - " .. DesiredConfigSummary()
        elseif pendingAction == "disable" then
            state = "Active: " .. EffectiveConfigSummary() .. "\nQueued: disable"
        elseif pendingAction == "refresh" then
            state = "Active: " .. EffectiveConfigSummary() .. "\nQueued: " .. DesiredConfigSummary()
        elseif active then
            state = "Enabled - " .. EffectiveConfigSummary()
        else
            state = "Disabled - native bindings"
        end
        self.statusText:SetText(state)
        if pendingAction then
            self.statusText:SetTextColor(1, 0.75, 0.2)
        elseif active then
            self.statusText:SetTextColor(0.35, 1, 0.35)
        else
            self.statusText:SetTextColor(1, 0.35, 0.35)
        end
    end

    frame:SetScript("OnShow", function(self) self:Refresh() end)
end

local function UpdateMinimapButtonPosition()
    if not minimapButton then return end
    local angle = math.rad(LeftInteractDB.minimapAngle or 220)
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * 80, math.sin(angle) * 80)
end

local function CreateMinimapButton()
    if minimapButton or not Minimap then return end
    local button = CreateFrame("Button", "LeftInteractMinimapButton", Minimap)
    button:SetWidth(32); button:SetHeight(32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\Icons\\Ability_Rogue_Sprint")
    icon:SetWidth(22); icon:SetHeight(22)
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetWidth(54); border:SetHeight(54)
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)

    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "RightButton" then
            SetEnabled(not LeftInteractDB.enabled, false)
            if optionsFrame and optionsFrame:IsShown() then optionsFrame:Refresh() end
        else
            ToggleGUI()
        end
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Left Interact", 0.4, 0.85, 1)
        GameTooltip:AddLine("Left click: Open settings", 1, 1, 1)
        GameTooltip:AddLine("Right click: Enable or disable", 1, 1, 1)
        GameTooltip:AddLine("Drag: Move this button", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            px, py = px / scale, py / scale
            LeftInteractDB.minimapAngle = math.deg(math.atan2(py - my, px - mx))
            UpdateMinimapButtonPosition()
        end)
    end)
    button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

    minimapButton = button
    UpdateMinimapButtonPosition()
end

ToggleGUI = function()
    CreateOptionsGUI()
    if optionsFrame:IsShown() then optionsFrame:Hide() else optionsFrame:Show() end
end

controller:RegisterEvent("ADDON_LOADED")
controller:RegisterEvent("PLAYER_REGEN_ENABLED")
controller:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon ~= ADDON_NAME then
            return
        end

        if LeftInteractDB.enabled == nil then
            LeftInteractDB.enabled = true
        end
        if LeftInteractDB.mode ~= "mouseover" then
            LeftInteractDB.mode = "action"
        end
        if LeftInteractDB.rightMove == nil then
            LeftInteractDB.rightMove = true
        end
        if LeftInteractDB.emptyClickDeselect == nil then
            LeftInteractDB.emptyClickDeselect = true
        end
        -- Version 1.4.1 removes W Priority and returns to seamless left hold.
        -- Future GUI choices remain unchanged.
        if not LeftInteractDB.settingsVersion or LeftInteractDB.settingsVersion < 6 then
            LeftInteractDB.movementMode = "independent"
            LeftInteractDB.settingsVersion = 6
        elseif LeftInteractDB.movementMode ~= "independent" then
            LeftInteractDB.movementMode = "combined"
        end

        CreateOptionsGUI()
        CreateMinimapButton()
        SetupEmptyClickDeselect()

        if LeftInteractDB.enabled then
            ApplyBindings(false)
        end

        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_REGEN_ENABLED" and pendingAction then
        if (pendingAction == "enable" or pendingAction == "refresh") and LeftInteractDB.enabled then
            ApplyBindings(false)
        elseif pendingAction == "disable" and not LeftInteractDB.enabled then
            RemoveBindings(false)
        else
            pendingAction = nil
        end
    end
end)

controller:SetScript("OnUpdate", function(self, elapsed)
    if not active or InCombat() then
        return
    end

    cursorCheckElapsed = cursorCheckElapsed + elapsed
    if cursorCheckElapsed < 0.05 then
        return
    end
    cursorCheckElapsed = 0

    local hasItem = CursorHasItem and CursorHasItem() and true or false
    if hasItem ~= cursorHasItem then
        ApplyBindings(true)
    end
end)
