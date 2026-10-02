-- AlniarezUI/Harness.lua
-- Minimal test runner. Every test runs inside pcall so one failure never
-- stops the rest of the suite.

local ADDON_NAME, ns = ...

--------------------------------------------------
-- Library snapshot
--
-- Every addon that embeds AlnUI shares one global table, and the newest
-- copy loaded wins. Snapshot it right after this folder's copy loaded, so
-- a newer copy from an addon loading later cannot change what the suite
-- tests.
--
-- If a newer copy had already loaded, this folder's copy stopped at its
-- version check, and the snapshot is that other copy. The suite then says
-- so: its results are not about this folder's Libs/AlnUI.lua.
--------------------------------------------------

local Lib = {}
for k, v in pairs(AlnUI) do Lib[k] = v end
ns.Lib = Lib

-- true when the snapshot is this folder's copy
ns.TestsOwnLibrary = AlnUI.loadedFrom == ADDON_NAME

-- "AlnUI v1", plus where it came from when it is not this folder's copy
function ns.VersionText()
    local text = "AlnUI v" .. tostring(Lib.version)
    if not ns.TestsOwnLibrary then
        text = text .. " (from " .. tostring(Lib.loadedFrom) .. ")"
    end
    return text
end

-- Shows the version in the top-left corner of window `f`: grey, or red
-- when the suite is not using this folder's copy
function ns.AddVersionLabel(f)
    local fs = Lib:CreateLabel(f, {
        text  = ns.VersionText(),
        font  = "GameFontHighlightSmall",
        color = ns.TestsOwnLibrary and { 0.6, 0.6, 0.6 } or { 1, 0.33, 0.33 },
    })
    fs:SetPoint("TOPLEFT", 20, -14)
    f.versionLabel = fs
    return fs
end
if not ns.TestsOwnLibrary then
    print("|cff33ff99" .. ADDON_NAME .. ":|r |cffff5555the tests are using AlnUI version "
        .. tostring(AlnUI.version) .. " from " .. tostring(AlnUI.loadedFrom)
        .. ", which is newer than this folder's copy.|r")
end

--------------------------------------------------
-- Sandbox
--
-- WoW frames can never be destroyed, so tests parent their frames to one
-- hidden sandbox frame to keep them off screen.
--------------------------------------------------

ns.sandbox = CreateFrame("Frame", nil, UIParent)
ns.sandbox:SetSize(1, 1)
ns.sandbox:SetPoint("CENTER")
ns.sandbox:Hide()

local nameCounter = 0

-- Returns a unique global frame name for tests that need one
function ns.UniqueName(tag)
    nameCounter = nameCounter + 1
    return ADDON_NAME .. "_Test" .. (tag or "") .. nameCounter
end

-- Returns relativeTo, relativePoint, x, y for the anchor named `point`
function ns.FindPoint(region, point)
    for i = 1, region:GetNumPoints() do
        local p, rel, relPoint, x, y = region:GetPoint(i)
        if p == point then return rel, relPoint, x, y end
    end
end

--------------------------------------------------
-- Assertions
--------------------------------------------------

local A = {}
ns.A = A

local function fail(label, msg)
    -- level 3: report the line in the test, not in the assertion helper
    error((label and (label .. ": ") or "") .. msg, 3)
end

local function show(v)
    if type(v) == "string" then return string.format("%q", v) end
    return tostring(v)
end

function A.Equal(actual, expected, label)
    if actual ~= expected then
        fail(label, "expected " .. show(expected) .. ", got " .. show(actual))
    end
end

function A.Near(actual, expected, label, eps)
    if type(actual) ~= "number" or math.abs(actual - expected) > (eps or 0.01) then
        fail(label, "expected ~" .. show(expected) .. ", got " .. show(actual))
    end
end

function A.True(v, label)
    if not v then fail(label, "expected truthy, got " .. show(v)) end
end

function A.False(v, label)
    if v then fail(label, "expected falsy, got " .. show(v)) end
end

function A.Nil(v, label)
    if v ~= nil then fail(label, "expected nil, got " .. show(v)) end
end

function A.NotNil(v, label)
    if v == nil then fail(label, "expected a value, got nil") end
end

-- Asserts `obj` is a widget of the given object type ("Frame", "Button", ...)
function A.Type(obj, objectType, label)
    if type(obj) ~= "table" or type(obj.GetObjectType) ~= "function" then
        fail(label, "expected a " .. objectType .. " widget, got " .. show(obj))
    end
    local actual = obj:GetObjectType()
    if actual ~= objectType then
        fail(label, "expected a " .. objectType .. " widget, got a " .. actual)
    end
end

--------------------------------------------------
-- Registration
--
--   T:Describe(name, fn)          group tests under a suite name
--   T:It(name, fn)                synchronous test
--   T:ItAsync(name, timeout, fn)  fn(t) with t:After(sec, fn) and t:Done()
--------------------------------------------------

local T = {}
ns.T = T

local suites        = {}
local current       = nil
local running       = false
local stopRequested = false

function T:Describe(name, fn)
    current = { name = name, tests = {} }
    table.insert(suites, current)
    fn()
    current = nil
end

function T:It(name, fn)
    assert(current, "T:It must be called inside T:Describe")
    table.insert(current.tests, { name = name, fn = fn })
end

function T:ItAsync(name, timeout, fn)
    assert(current, "T:ItAsync must be called inside T:Describe")
    table.insert(current.tests, { name = name, fn = fn, async = true, timeout = timeout })
end

function T:Count()
    local n = 0
    for _, s in ipairs(suites) do n = n + #s.tests end
    return n
end


function T:IsRunning()
    return running
end

-- Asks the current run to stop after the test in progress. Returns true
-- if a run was in progress.
function T:Stop()
    if not running then return false end
    stopRequested = true
    return true
end

--------------------------------------------------
-- T:Run(opts)
--
-- Runs every test in registration order. Async tests hold the queue until
-- they finish or time out.
--
-- opts (all optional):
--   delay        number  seconds to wait after a test starts, before it
--                        runs, so progress can be watched (default 0)
--   onTestStart  func    onTestStart(suite, name, index, total)
--   onTestDone   func    onTestDone(entry, index, total)
--   onComplete   func    onComplete(results)
--
-- entry:   { suite, name, ok, err }
-- results: { passed, failed, elapsed, stopped, entries = { entry, ... } }
--------------------------------------------------

local function CleanError(err)
    err = tostring(err)
    -- strip the long Interface\AddOns\... prefix from error locations
    return (err:gsub("^.-AddOns[/\\]" .. ADDON_NAME .. "[/\\]", ""))
end

function T:Run(opts)
    if running then return false end
    running       = true
    stopRequested = false

    opts = opts or {}
    local delay = opts.delay or 0

    local queue = {}
    for _, s in ipairs(suites) do
        for _, t in ipairs(s.tests) do
            table.insert(queue, { suite = s.name, test = t })
        end
    end

    local results = { passed = 0, failed = 0, entries = {} }
    local started = GetTime()
    local total   = #queue
    local index   = 0
    local nextTest

    local function record(item, ok, err)
        if ok then
            results.passed = results.passed + 1
        else
            results.failed = results.failed + 1
        end
        local entry = {
            suite = item.suite,
            name  = item.test.name,
            ok    = ok,
            err   = (not ok) and CleanError(err) or nil,
        }
        table.insert(results.entries, entry)
        if opts.onTestDone then opts.onTestDone(entry, index, total) end
    end

    local function runAsync(item)
        local finished = false

        local function finish(ok, err)
            if finished then return end
            finished = true
            record(item, ok, err)
            nextTest()
        end

        local t = {}
        function t:After(sec, fn)
            C_Timer.After(sec, function()
                if finished then return end
                local ok, err = pcall(fn)
                if not ok then finish(false, err) end
            end)
        end
        function t:Done() finish(true) end

        local timeout = item.test.timeout or 5
        C_Timer.After(timeout, function()
            finish(false, "timed out after " .. timeout .. "s")
        end)

        local ok, err = pcall(item.test.fn, t)
        if not ok then finish(false, err) end
    end

    local function runItem(item)
        if item.test.async then
            runAsync(item)
        else
            local ok, err = pcall(item.test.fn)
            record(item, ok, err)
            nextTest()
        end
    end

    nextTest = function()
        index = index + 1
        local item = queue[index]
        if not item or stopRequested then
            running = false
            results.stopped = item ~= nil
            results.elapsed = GetTime() - started
            if opts.onComplete then opts.onComplete(results) end
            return
        end

        if opts.onTestStart then opts.onTestStart(item.suite, item.test.name, index, total) end

        if delay > 0 then
            C_Timer.After(delay, function() runItem(item) end)
        else
            runItem(item)
        end
    end

    nextTest()
    return true
end
