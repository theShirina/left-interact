-- Regression test for Left Interact movement defaults.
-- Run each scenario in a fresh Lua 5.1 process.

local scenario = arg and arg[1] or "new"

if scenario == "new" then
    LeftInteractDB = {}
elseif scenario == "existing-independent" then
    LeftInteractDB = {
        enabled = true,
        mode = "action",
        rightMove = true,
        emptyClickDeselect = true,
        movementMode = "independent",
        settingsVersion = 6,
    }
elseif scenario == "existing-independent-without-enabled" then
    LeftInteractDB = {
        mode = "action",
        rightMove = true,
        movementMode = "independent",
    }
elseif scenario == "existing-combined" then
    LeftInteractDB = {
        enabled = true,
        mode = "action",
        rightMove = true,
        emptyClickDeselect = true,
        movementMode = "combined",
        settingsVersion = 6,
    }
elseif scenario == "item-native-dispatch" then
    LeftInteractDB = {
        enabled = true,
        mode = "action",
        rightMove = true,
        emptyClickDeselect = true,
        movementMode = "combined",
        settingsVersion = 7,
    }
elseif scenario == "changelog-page" then
    LeftInteractDB = {
        enabled = true,
        mode = "action",
        rightMove = true,
        emptyClickDeselect = true,
        movementMode = "combined",
        settingsVersion = 7,
    }
else
    error("unknown scenario: " .. tostring(scenario))
end

local controller
local cursorItem = false
local overrideBindings = {}
local createdFrames = {}
local namedFrames = {}
local widgetMethods = {}

function widgetMethods:SetText(text)
    rawset(self, "text", text)
end

function widgetMethods:SetScript(name, handler)
    local scripts = rawget(self, "scripts")
    if not scripts then
        scripts = {}
        rawset(self, "scripts", scripts)
    end
    scripts[name] = handler
end

function widgetMethods:CreateFontString()
    local widget = setmetatable({ shown = true }, { __index = widgetMethods })
    table.insert(createdFrames, widget)
    return widget
end

function widgetMethods:CreateTexture()
    return setmetatable({}, { __index = widgetMethods })
end

function widgetMethods:GetCenter()
    return 0, 0
end

function widgetMethods:GetEffectiveScale()
    return 1
end

function widgetMethods:GetFrameLevel()
    return 1
end

function widgetMethods:IsShown()
    return rawget(self, "shown") and true or false
end

function widgetMethods:Show()
    rawset(self, "shown", true)
end

function widgetMethods:Hide()
    rawset(self, "shown", false)
end

function widgetMethods:GetChecked()
    return false
end

setmetatable(widgetMethods, {
    __index = function(_, key)
        local fn = function() end
        rawset(widgetMethods, key, fn)
        return fn
    end,
})

local function NewWidget()
    return setmetatable({ shown = true }, { __index = widgetMethods })
end

function CreateFrame(_, name)
    local frame = NewWidget()
    table.insert(createdFrames, frame)
    if name then namedFrames[name] = frame end
    if name == "LeftInteractController" then
        controller = frame
    end
    return frame
end

DEFAULT_CHAT_FRAME = { AddMessage = function() end }
GameTooltip = NewWidget()
UIParent = NewWidget()
Minimap = NewWidget()
WorldFrame = NewWidget()
SlashCmdList = {}
UISpecialFrames = {}

function GetAddOnMetadata(_, field)
    if field == "Version" then return "test" end
end

function InCombatLockdown() return false end
function CursorHasItem() return cursorItem end
function ClearOverrideBindings()
    for key in pairs(overrideBindings) do
        overrideBindings[key] = nil
    end
end
function SetOverrideBinding(_, _, key, action)
    overrideBindings[key] = action
end
function GetCursorPosition() return 0, 0 end
function GetTime() return 0 end
function UnitExists() return false end
function ClearTarget() end

dofile("LeftInteract.lua")
assert(controller and controller.scripts and controller.scripts.OnEvent, "controller OnEvent handler missing")
controller.scripts.OnEvent(controller, "ADDON_LOADED", "LeftInteract")

if scenario == "item-native-dispatch" then
    assert(overrideBindings.BUTTON1 == "TURNORACTION", "normal interaction binding was not installed")
    cursorItem = true
    controller.scripts.OnUpdate(controller, 0.06)
    assert(
        overrideBindings.BUTTON1 == nil,
        "item cursor must leave BUTTON1 unoverridden for native UI OnReceiveDrag dispatch"
    )
    assert(overrideBindings["SHIFT-BUTTON1"] == "CAMERAORSELECTORMOVE", "modifier fallback should remain installed")
    assert(overrideBindings.BUTTON2 == "MOVEANDSTEER", "right-click movement should remain installed")
    cursorItem = false
    controller.scripts.OnUpdate(controller, 0.06)
    assert(overrideBindings.BUTTON1 == "TURNORACTION", "interaction binding was not restored after cursor cleared")
elseif scenario == "changelog-page" then
    local whatsNew
    local correctVersion = false
    for _, frame in ipairs(createdFrames) do
        if frame.text == "WHAT'S NEW" and rawget(frame, "scripts") and rawget(frame, "scripts").OnClick then
            whatsNew = frame
        elseif frame.text == "v1.6.2" then
            correctVersion = true
        end
    end
    assert(correctVersion, "GUI version must match the source version instead of cached client metadata")
    assert(whatsNew and whatsNew.scripts and whatsNew.scripts.OnClick, "WHAT'S NEW button missing or inert")
    whatsNew.scripts.OnClick(whatsNew)
    local page = namedFrames.LeftInteractChangelogPage
    assert(page and page:IsShown(), "changelog page was not shown inside settings")
    assert(not namedFrames.LeftInteractChangelogFrame, "changelog must not open a second top-level window")
    local back
    for _, frame in ipairs(createdFrames) do
        if frame.text == "BACK TO SETTINGS" and rawget(frame, "scripts") and rawget(frame, "scripts").OnClick then
            back = frame
            break
        end
    end
    assert(back and back.scripts and back.scripts.OnClick, "BACK TO SETTINGS button missing or inert")
    back.scripts.OnClick(back)
    assert(not page:IsShown(), "BACK TO SETTINGS did not hide the changelog page")
end

local expected = (scenario == "existing-independent" or scenario == "existing-independent-without-enabled")
    and "independent" or "combined"
assert(
    LeftInteractDB.movementMode == expected,
    scenario .. ": expected movementMode " .. expected .. ", got " .. tostring(LeftInteractDB.movementMode)
)

print(scenario .. ": PASS")
