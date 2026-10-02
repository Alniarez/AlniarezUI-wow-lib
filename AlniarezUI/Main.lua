-- AlniarezUI/Main.lua
-- Slash commands and the live test results window.

local ADDON_NAME, ns = ...
local T, Lib = ns.T, ns.Lib

local PREFIX = "|cff33ff99" .. ADDON_NAME .. ":|r "
local GREEN  = "|cff55ff55"
local RED    = "|cffff5555"
local GREY   = "|cffbbbbbb"
local GOLD   = "|cffffd100"
local YELLOW = "|cffffff00"

local DEFAULT_DELAY = 0.1
local MAX_DELAY     = 1

--------------------------------------------------
-- SavedVariables
--------------------------------------------------

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, name)
    if name ~= ADDON_NAME then return end
    AlniarezUIDB = AlniarezUIDB or {}
    if AlniarezUIDB.delay == nil then AlniarezUIDB.delay = DEFAULT_DELAY end
    self:UnregisterEvent("ADDON_LOADED")
end)

local function GetDelay()
    return AlniarezUIDB and AlniarezUIDB.delay or DEFAULT_DELAY
end

--------------------------------------------------
-- Results window
--
-- Built with AlnUI itself. Every update goes through SafeUI, so if the
-- library is broken badly enough that the window fails, the run carries
-- on and results still go to chat.
--------------------------------------------------

local resultsFrame, resultsScroll, resultsContent, resultsSummary
local runButton, copyButton, delaySlider
local copyFrame, copyBox
local lastResults   = nil  -- results of the last finished run, for copying
local lines         = {}
local numLines      = 0
local contentHeight = 0
local lastSuite     = nil
local runningLine   = nil
local uiBroken      = false

local function BuildResultsFrame()
    local f = Lib:CreateDialog({
        name       = "AlniarezUIResultsFrame",
        title      = "AlnUI Tests",
        width      = 560,
        height     = 460,
        strata     = "DIALOG",
    })

    ns.AddVersionLabel(f)

    resultsSummary = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    resultsSummary:SetPoint("TOPLEFT", 24, -36)

    Lib:CreateSeparator(f, { y = -54, x1 = 20, x2 = -20 })

    resultsScroll, resultsContent = Lib:CreateScrollFrame(f, {
        x1 = 18,  y1 = -58,
        x2 = -36, y2 = 64,
        contentWidth  = 500,
        contentHeight = 1,
    })

    Lib:CreateSeparator(f, { y = -400, x1 = 20, x2 = -20 })

    delaySlider = Lib:CreateSlider(f, {
        width       = 180,
        min         = 0,
        max         = MAX_DELAY,
        step        = 0.05,
        labelFormat = "Delay: %.2fs per test",
        onChange    = function(v) AlniarezUIDB.delay = v end,
        value       = GetDelay(),
    })
    delaySlider:SetPoint("BOTTOMLEFT", 30, 34)

    runButton = Lib:CreateButton(f, {
        text    = "Run",
        width   = 100,
        onClick = function()
            if T:IsRunning() then ns.StopTests() else ns.RunTests() end
        end,
    })
    runButton:SetPoint("BOTTOMRIGHT", -24, 20)

    copyButton = Lib:CreateButton(f, {
        text    = "Copy",
        width   = 90,
        onClick = function() ns.CopyResults() end,
    })
    copyButton:SetPoint("RIGHT", runButton, "LEFT", -8, 0)
    copyButton:SetEnabled(lastResults ~= nil)

    local demoButton = Lib:CreateButton(f, {
        text    = "Demo",
        width   = 90,
        onClick = function() ns.ToggleDemo() end,
    })
    demoButton:SetPoint("RIGHT", copyButton, "LEFT", -8, 0)

    return f
end

local function SafeUI(fn, ...)
    if uiBroken then return end
    local ok, err = pcall(fn, ...)
    if not ok then
        uiBroken = true
        print(PREFIX .. RED .. "results window failed: " .. tostring(err) .. "|r")
    end
end

local function AddLine(text)
    numLines = numLines + 1
    local fs = lines[numLines]
    if not fs then
        fs = resultsContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetWidth(490)
        fs:SetJustifyH("LEFT")
        lines[numLines] = fs
    end
    fs:ClearAllPoints()
    if numLines == 1 then
        fs:SetPoint("TOPLEFT", resultsContent, "TOPLEFT", 4, 0)
    else
        fs:SetPoint("TOPLEFT", lines[numLines - 1], "BOTTOMLEFT", 0, -3)
    end
    fs:SetText(text)
    fs:Show()

    contentHeight = contentHeight + fs:GetStringHeight() + 3
    resultsContent:SetHeight(math.max(contentHeight, 1))
    return fs
end

-- The scroll range only updates on the next frame, so scroll after it
local function ScrollToBottom()
    C_Timer.After(0, function()
        resultsScroll:SetVerticalScroll(resultsScroll:GetVerticalScrollRange())
    end)
end

local function CountsText(passed, failed)
    return GREEN .. passed .. " passed|r, " .. (failed > 0 and RED or GREY) .. failed .. " failed|r"
end

local function BeginRun(total)
    resultsFrame = resultsFrame or BuildResultsFrame()

    -- clear every pooled line, not just the ones the last run used
    for _, fs in ipairs(lines) do
        fs:SetText("")
        fs:Hide()
    end
    numLines, contentHeight, lastSuite, runningLine = 0, 0, nil, nil
    resultsContent:SetHeight(1)
    resultsScroll:SetVerticalScroll(0)

    resultsSummary:SetText(YELLOW .. "Running 0/" .. total .. "|r")
    runButton:SetText("Stop")
    copyButton:Disable()
    if copyFrame then copyFrame:Hide() end
    resultsFrame:Show()
end

local function ShowTestStart(suite, name, index, total, passed, failed)
    if suite ~= lastSuite then
        if lastSuite then AddLine(" ") end
        AddLine(GOLD .. suite .. "|r")
        lastSuite = suite
    end
    runningLine = AddLine("   " .. YELLOW .. "RUN|r   " .. name)
    resultsSummary:SetText(YELLOW .. "Running " .. index .. "/" .. total .. "|r   " .. CountsText(passed, failed))
    ScrollToBottom()
end

local function ShowTestDone(entry, index, total, passed, failed)
    if runningLine then
        if entry.ok then
            runningLine:SetText("   " .. GREEN .. "PASS|r  " .. entry.name)
        else
            runningLine:SetText("   " .. RED .. "FAIL|r  " .. entry.name)
            AddLine("          " .. GREY .. entry.err .. "|r")
            ScrollToBottom()
        end
        runningLine = nil
    end
    resultsSummary:SetText(YELLOW .. "Running " .. index .. "/" .. total .. "|r   " .. CountsText(passed, failed))
end

local function FinishRun(results)
    local status
    if results.stopped then
        status = YELLOW .. "Stopped|r   "
    elseif results.failed == 0 then
        status = GREEN .. "All passed|r   "
    else
        status = RED .. "Failed|r   "
    end
    resultsSummary:SetText(status .. CountsText(results.passed, results.failed)
        .. string.format("   %s(%.2fs)|r", GREY, results.elapsed))
    runButton:SetText("Run")
    copyButton:Enable()
end

-- Opens or closes the panel without running anything
function ns.TogglePanel()
    local firstOpen = not resultsFrame
    resultsFrame = resultsFrame or BuildResultsFrame()
    if firstOpen then
        resultsSummary:SetText(GREY .. T:Count() .. " tests ready. Press Run to start.|r")
    end
    -- dialogs come to the front on their own when shown
    resultsFrame:SetShown(not resultsFrame:IsShown())
end

--------------------------------------------------
-- Running
--------------------------------------------------

-- delay: seconds per test; defaults to the saved delay
function ns.RunTests(delay)
    if T:IsRunning() then
        print(PREFIX .. "tests are already running.")
        return
    end

    local total = T:Count()
    local passed, failed = 0, 0
    uiBroken    = false
    lastResults = nil

    print(PREFIX .. "running " .. total .. " tests...")
    SafeUI(BeginRun, total)

    T:Run({
        delay = delay or GetDelay(),

        onTestStart = function(suite, name, index)
            SafeUI(ShowTestStart, suite, name, index, total, passed, failed)
        end,

        onTestDone = function(entry, index)
            if entry.ok then passed = passed + 1 else failed = failed + 1 end
            SafeUI(ShowTestDone, entry, index, total, passed, failed)
        end,

        onComplete = function(results)
            for _, e in ipairs(results.entries) do
                if not e.ok then
                    print(PREFIX .. RED .. "FAIL|r " .. e.suite .. " > " .. e.name .. GREY .. " - " .. e.err .. "|r")
                end
            end
            local summary = CountsText(results.passed, results.failed)
                .. string.format(" %s(%.2fs)|r", GREY, results.elapsed)
            if results.stopped then summary = summary .. YELLOW .. " - stopped|r" end
            print(PREFIX .. summary)

            lastResults = results
            SafeUI(FinishRun, results)
        end,
    })
end

--------------------------------------------------
-- Copy window
--
-- Addons can't write to the clipboard, so this shows the results as plain
-- text in a selected EditBox for the player to copy with Ctrl+C.
--------------------------------------------------

local copyText = ""

local function ResultsAsText(results)
    local version, build = GetBuildInfo()
    local out = {
        string.format("%s test results - %s - client %s (%s)",
            ns.VersionText(), date("%Y-%m-%d %H:%M"), version, build),
        string.format("%d passed, %d failed (%.2fs)%s",
            results.passed, results.failed, results.elapsed,
            results.stopped and " - stopped" or ""),
    }

    local lastSuiteName
    for _, e in ipairs(results.entries) do
        if e.suite ~= lastSuiteName then
            table.insert(out, "")
            table.insert(out, e.suite)
            lastSuiteName = e.suite
        end
        table.insert(out, "  " .. (e.ok and "PASS" or "FAIL") .. "  " .. e.name)
        if not e.ok then
            table.insert(out, "        " .. e.err)
        end
    end

    return table.concat(out, "\n")
end

local function BuildCopyFrame()
    local f = Lib:CreateDialog({
        name       = "AlniarezUICopyFrame",
        title      = "Copy Results",
        width      = 560,
        height     = 420,
        strata     = "FULLSCREEN_DIALOG",
    })

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 24, -36)
    hint:SetText("Press Ctrl+C to copy, Esc to close.")

    local _, box = Lib:CreateScrollFrame(f, {
        x1 = 20,  y1 = -56,
        x2 = -36, y2 = 20,
        contentWidth = 490,
        childType    = "EditBox",
    })
    box:SetMultiLine(true)
    box:SetAutoFocus(false)
    box:SetFontObject(GameFontHighlightSmall)
    box:SetScript("OnEscapePressed", function() f:Hide() end)
    -- read-only: undo any typing and keep everything selected
    box:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            self:SetText(copyText)
            self:HighlightText()
        end
    end)
    copyBox = box

    return f
end

function ns.CopyResults()
    if not lastResults then
        print(PREFIX .. "no results to copy yet. Run the tests first.")
        return
    end

    SafeUI(function()
        copyFrame = copyFrame or BuildCopyFrame()
        copyText  = ResultsAsText(lastResults)
        copyBox:SetText(copyText)
        copyFrame:Show()
        copyBox:SetFocus()
        copyBox:HighlightText()
    end)
end

function ns.StopTests()
    if T:Stop() then
        print(PREFIX .. "stopping after the current test...")
    end
end

--------------------------------------------------
-- Slash commands
--------------------------------------------------

local function PrintHelp()
    print("|cff33ff99AlniarezUI commands:|r")
    print("|cffffff00/alnui|r " .. GREY .. "- open the Learn AlnUI window (also /alnui learn)|r")
    print("|cffffff00/alnui tests|r " .. GREY .. "- toggle the Test window|r")
    print("|cffffff00/alnui run|r " .. GREY .. "- run all tests (with the saved delay)|r")
    print("|cffffff00/alnui fast|r " .. GREY .. "- run all tests with no delay|r")
    print("|cffffff00/alnui stop|r " .. GREY .. "- stop the current run|r")
    print("|cffffff00/alnui delay <seconds>|r " .. GREY .. "- set the delay per test (0-" .. MAX_DELAY .. ")|r")
    print("|cffffff00/alnui copy|r " .. GREY .. "- open the last results as copyable text|r")
    print("|cffffff00/alnui demo|r " .. GREY .. "- toggle the Demo window|r")
    print("|cffffff00/alnui demos|r " .. GREY .. "- toggle one Demo window per theme|r")
    print("|cffffff00/alnui toasts|r " .. GREY .. "- show every kind of toast in every theme|r")
    print("|cffffff00/alnui help|r " .. GREY .. "- show this help|r")
end

SLASH_ALNUITEST1 = "/alnui"
SLASH_ALNUITEST2 = "/alnuitest"
SlashCmdList["ALNUITEST"] = function(msg)
    local cmd, arg = strtrim((msg or ""):lower()):match("^(%S*)%s*(.-)$")

    if cmd == "" or cmd == "learn" then
        ns.ToggleLearn()
    elseif cmd == "tests" then
        SafeUI(ns.TogglePanel)
    elseif cmd == "run" then
        ns.RunTests()
    elseif cmd == "fast" then
        ns.RunTests(0)
    elseif cmd == "stop" then
        ns.StopTests()
    elseif cmd == "delay" then
        local v = tonumber(arg)
        if not v or v < 0 or v > MAX_DELAY then
            print(PREFIX .. "usage: /alnui delay <0-" .. MAX_DELAY .. ">")
            return
        end
        AlniarezUIDB.delay = v
        if delaySlider then delaySlider:SetValue(v) end
        print(PREFIX .. string.format("delay set to %.2fs per test.", v))
    elseif cmd == "copy" then
        ns.CopyResults()
    elseif cmd == "demo" then
        ns.ToggleDemo()
    elseif cmd == "demos" then
        ns.ToggleThemeDemos()
    elseif cmd == "toasts" then
        ns.ShowToastGallery()
    else
        PrintHelp()
    end
end
