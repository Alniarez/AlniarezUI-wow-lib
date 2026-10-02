-- AlniarezUI/Tests/Toast.lua
-- Toasts always parent to UIParent, so these use very short timings to keep
-- them on screen only briefly. Every test starts with ClearToasts() so the
-- queue from an earlier test never gets in the way.

local _, ns = ...
local T, A, Lib = ns.T, ns.A, ns.Lib

local GOLD_EDGE     = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border"
local STANDARD_EDGE = "Interface\\DialogFrame\\UI-DialogBox-Border"

-- fade in 0.05s, hold until 0.2s, fade out 0.05s: each toast lasts ~0.25s
local FAST = { fadeIn = 0.05, duration = 0.2, fadeOut = 0.05 }

local function Fast(opts)
    local o = {}
    for k, v in pairs(FAST) do o[k] = v end
    for k, v in pairs(opts or {}) do o[k] = v end
    return o
end

-- Clears the queue, then shows a toast
local function Fresh(opts)
    Lib:ClearToasts()
    return Lib:ShowToast(Fast(opts))
end

-- Returns the text of every FontString region on `frame`
local function Texts(frame)
    local found = {}
    for _, r in ipairs({ frame:GetRegions() }) do
        if r:GetObjectType() == "FontString" and r:GetText() then
            found[r:GetText()] = r
        end
    end
    return found
end

T:Describe("ShowToast", function()

    T:It("returns a shown frame on UIParent", function()
        local f = Fresh()
        A.Type(f, "Frame")
        A.True(f:IsShown(), "IsShown")
        A.Equal(f.alnState, "showing", "state")
        A.Equal(f:GetParent(), UIParent, "parent")
        A.Equal(f:GetFrameStrata(), "HIGH", "strata")
    end)

    T:It("defaults to 400x100 at the top of the screen", function()
        local f = Fresh()
        A.Near(f:GetWidth(),  400, "width")
        A.Near(f:GetHeight(), 100, "height")
        local rel, relPoint, _, y = ns.FindPoint(f, "TOP")
        A.Equal(rel, UIParent, "relativeTo")
        A.Equal(relPoint, "TOP", "relativePoint")
        A.Near(y, -200, "y")
    end)

    T:It("applies width and height", function()
        local f = Fresh({ width = 300, height = 80 })
        A.Near(f:GetWidth(),  300, "width")
        A.Near(f:GetHeight(), 80,  "height")
    end)

    T:It("defaults to the gold theme", function()
        A.Equal(Fresh():GetBackdrop().edgeFile, GOLD_EDGE, "edgeFile")
    end)

    T:It("applies the standard theme", function()
        A.Equal(Fresh({ theme = "standard" }):GetBackdrop().edgeFile, STANDARD_EDGE, "edgeFile")
    end)

    T:It("uses the theme's backdrop", function()
        local b = Fresh():GetBackdrop()
        A.Equal(b.edgeSize, 32, "edgeSize")
        A.True(b.tile, "tile")
        A.Equal(b.insets.left, 11, "left inset")
        A.Equal(b.insets.top,  12, "top inset")
    end)

    T:It("uses the tooltip theme for the window-only themes", function()
        for _, name in ipairs({ "basic", "panel" }) do
            local f = Fresh({ theme = name })
            if Lib:HasTheme("tooltip") then
                A.Nil(f:GetBackdrop(), name .. ": backdrop")
                A.Equal(f.border, f.alnBorders.TooltipBackdropTemplate, name .. ": tooltip border")
            else
                A.Equal(f:GetBackdrop().edgeFile, GOLD_EDGE, name .. ": falls back to gold")
            end
        end
    end)

    T:It("lists the toast themes with GetThemes(\"toast\")", function()
        local all, toast = {}, {}
        for _, name in ipairs(Lib:GetThemes()) do all[name] = true end
        for _, name in ipairs(Lib:GetThemes("toast")) do toast[name] = true end
        A.Nil(toast.basic, "basic")
        A.Nil(toast.panel, "panel")
        for _, name in ipairs({ "gold", "standard", "modern", "tooltip" }) do
            A.Equal(toast[name], all[name], name .. " listed when available")
        end
    end)

    T:It("draws the modern theme with Blizzard's border", function()
        local f = Fresh({ theme = "modern" })
        if Lib:HasTheme("modern") then
            A.Nil(f:GetBackdrop(), "backdrop")
            A.True(f.border:IsShown(), "border shown")
        else
            A.Equal(f:GetBackdrop().edgeFile, GOLD_EDGE, "falls back to gold")
        end
    end)

    T:It("draws the tooltip theme with Blizzard's tooltip border", function()
        local f = Fresh({ theme = "tooltip" })
        if Lib:HasTheme("tooltip") then
            A.Nil(f:GetBackdrop(), "backdrop")
            A.True(f.border:IsShown(), "border shown")
        else
            A.Equal(f:GetBackdrop().edgeFile, GOLD_EDGE, "falls back to gold")
        end
    end)

    T:It("renders title and text", function()
        local texts = Texts(Fresh({ title = "Toast Title", text = "Toast body" }))
        A.NotNil(texts["Toast Title"], "title FontString")
        A.NotNil(texts["Toast body"],  "text FontString")
    end)

    T:It("shifts text right when an icon is shown", function()
        local _, _, xPlain = ns.FindPoint(Texts(Fresh({ title = "Plain" }))["Plain"], "CENTER")
        local _, _, xIcon  = ns.FindPoint(
            Texts(Fresh({ title = "Icon", icon = "Interface\\Icons\\INV_Misc_QuestionMark" }))["Icon"], "CENTER")
        A.Near(xPlain, 0, "x without icon")
        A.True(xIcon > xPlain, "x with icon (" .. tostring(xIcon) .. ") is right of x without")
    end)

    T:ItAsync("fades in, then hides itself", 3, function(t)
        local f = Fresh()
        t:After(0.15, function()
            A.True(f:IsShown(), "IsShown during hold")
            A.Near(f:GetAlpha(), 1, "alpha during hold", 0.05)
        end)
        t:After(0.6, function()
            A.False(f:IsShown(), "IsShown after fade-out")
            A.Equal(f.alnState, "done", "state")
            A.Nil(Lib:GetActiveToast(), "active toast")
            t:Done()
        end)
    end)

    -- Queue ----------------------------------------------------------------

    T:It("queues a toast while another is showing", function()
        local first  = Fresh()
        local second = Lib:ShowToast(Fast())
        A.Equal(Lib:GetActiveToast(), first, "active toast")
        A.Equal(Lib:GetNumQueuedToasts(), 1, "queued toasts")
        A.Equal(second.alnState, "queued", "second state")
        A.False(second:IsShown(), "second IsShown")
        Lib:ClearToasts()
    end)

    T:ItAsync("plays queued toasts in order, one at a time", 4, function(t)
        local a = Fresh({ title = "A" })
        local b = Lib:ShowToast(Fast({ title = "B" }))
        local c = Lib:ShowToast(Fast({ title = "C" }))

        local function Only(expected, label)
            for name, f in pairs({ A = a, B = b, C = c }) do
                A.Equal(f:IsShown(), name == expected, label .. ": " .. name .. " IsShown")
            end
        end

        t:After(0.1, function()
            Only("A", "at 0.1s")
            A.Equal(Lib:GetNumQueuedToasts(), 2, "queued at 0.1s")
        end)
        t:After(0.35, function()
            Only("B", "at 0.35s")
            A.Equal(a.alnState, "done", "A state at 0.35s")
            A.Equal(Lib:GetNumQueuedToasts(), 1, "queued at 0.35s")
        end)
        t:After(0.6, function()
            Only("C", "at 0.6s")
            A.Equal(Lib:GetNumQueuedToasts(), 0, "queued at 0.6s")
        end)
        t:After(0.95, function()
            Only(nil, "at 0.95s")
            A.Nil(Lib:GetActiveToast(), "active toast at 0.95s")
            t:Done()
        end)
    end)

    T:It("shows right away with queue = false", function()
        local first = Fresh()
        local now   = Lib:ShowToast(Fast({ queue = false }))
        A.True(now:IsShown(), "IsShown")
        A.Equal(now.alnState, "showing", "state")
        A.Equal(Lib:GetActiveToast(), first, "active toast unchanged")
        A.Equal(Lib:GetNumQueuedToasts(), 0, "queued toasts")
        Lib:ClearToasts()
    end)

    T:It("ClearToasts hides the active toast and drops the queue", function()
        local first  = Fresh()
        local second = Lib:ShowToast(Fast())
        Lib:ClearToasts()
        A.False(first:IsShown(),  "first IsShown")
        A.False(second:IsShown(), "second IsShown")
        A.Equal(first.alnState,  "done", "first state")
        A.Equal(second.alnState, "done", "second state")
        A.Nil(Lib:GetActiveToast(), "active toast")
        A.Equal(Lib:GetNumQueuedToasts(), 0, "queued toasts")
    end)

    T:ItAsync("does not start the next toast after ClearToasts", 3, function(t)
        local first = Fresh()
        Lib:ClearToasts()
        local after = Lib:ShowToast(Fast({ duration = 0.5 }))
        A.Equal(Lib:GetActiveToast(), after, "a new toast shows right away after clearing")
        -- the cleared toast's hold timer still fires at 0.2s; it must not
        -- end the new one, which holds until 0.5s
        t:After(0.35, function()
            A.Equal(first.alnState, "done", "cleared toast state")
            A.True(after:IsShown(), "new toast still showing")
        end)
        t:After(0.8, function()
            A.Equal(after.alnState, "done", "new toast state")
            t:Done()
        end)
    end)
end)

T:Describe("ShowToast bars", function()

    T:It("has no bars by default", function()
        local f = Fresh({ title = "Plain" })
        A.Nil(f.bar, "bar")
        A.Nil(f.timerBar, "timerBar")
        Lib:ClearToasts()
    end)

    T:It("shows a progress bar with its value and label", function()
        local f = Fresh({ title = "Kill 10 Defias", progress = { value = 3, max = 10 } })
        A.Type(f.bar, "StatusBar", "bar")
        A.Equal(f.bar:GetParent(), f, "bar parent")
        local min, max = f.bar:GetMinMaxValues()
        A.Near(min, 0, "min")
        A.Near(max, 10, "max")
        A.Near(f.bar:GetValue(), 3, "value")
        A.Equal(f.bar.label:GetText(), "3 / 10", "label")
        Lib:ClearToasts()
    end)

    T:It("updates the progress bar while the toast shows", function()
        local f = Fresh({ title = "Kill 10 Defias", progress = { value = 3, max = 10 } })
        f.bar:SetValue(4)
        A.Equal(f.bar.label:GetText(), "4 / 10", "label after SetValue")
        Lib:ClearToasts()
    end)

    T:It("applies the progress color and label format", function()
        local f = Fresh({ progress = { value = 50, color = { 0.2, 0.5, 1 }, labelFormat = "%d%%" } })
        local r, g, b = f.bar:GetStatusBarColor()
        A.Near(r, 0.2, "red")
        A.Near(g, 0.5, "green")
        A.Near(b, 1,   "blue")
        A.Equal(f.bar.label:GetText(), "50%", "label")
        Lib:ClearToasts()
    end)

    T:It("leaves the progress label empty with labelFormat = false", function()
        local f = Fresh({ progress = { value = 5, labelFormat = false } })
        A.True((f.bar.label:GetText() or "") == "", "label is empty")
        Lib:ClearToasts()
    end)

    T:It("keeps the bars clear of the icon", function()
        local f = Fresh({ icon = "Interface\\Icons\\INV_Misc_Coin_01", progress = { value = 1 }, timer = true })
        local _, _, x = ns.FindPoint(f.bar, "BOTTOMLEFT")
        A.True(x >= 16 + 64, "progress bar starts right of the icon (x = " .. tostring(x) .. ")")
        _, _, x = ns.FindPoint(f.timerBar, "BOTTOMLEFT")
        A.True(x >= 16 + 64, "countdown bar starts right of the icon (x = " .. tostring(x) .. ")")
        Lib:ClearToasts()
    end)

    T:It("moves the text up to make room for the bars", function()
        local plain = Fresh({ title = "Hello" })
        local _, _, _, plainY = ns.FindPoint(plain.titleText, "CENTER")
        local barred = Fresh({ title = "Hello", progress = { value = 1 }, timer = true })
        local _, _, _, barredY = ns.FindPoint(barred.titleText, "CENTER")
        A.True(barredY > plainY, "title higher with bars")
        Lib:ClearToasts()
    end)

    T:It("starts the countdown full and runs it down", function()
        local f = Fresh({ title = "Timed", timer = true, duration = 2 })
        A.Type(f.timerBar, "StatusBar", "timerBar")
        local _, max = f.timerBar:GetMinMaxValues()
        A.Near(max, 2, "max is the duration")
        A.Near(f.timerBar:GetValue(), 2, "starts full")

        local tick = f:GetScript("OnUpdate")
        A.NotNil(tick, "OnUpdate runs the countdown")
        tick(f, 0.5)
        A.Near(f.timerBar:GetValue(), 1.5, "after 0.5s")
        tick(f, 5)
        A.Near(f.timerBar:GetValue(), 0, "never below 0")
        A.Nil(f:GetScript("OnUpdate"), "stops at 0")
        Lib:ClearToasts()
    end)

    T:It("stops the countdown when the toast is cleared", function()
        local f = Fresh({ title = "Timed", timer = true, duration = 2 })
        Lib:ClearToasts()
        A.Nil(f:GetScript("OnUpdate"), "OnUpdate after ClearToasts")
    end)

    T:It("starts a queued toast's countdown only when it shows", function()
        Lib:ClearToasts()
        local first  = Lib:ShowToast(Fast({ title = "First" }))
        local second = Lib:ShowToast(Fast({ title = "Second", timer = true }))
        A.Equal(second.alnState, "queued", "second waits")
        A.Nil(second:GetScript("OnUpdate"), "no countdown while queued")
        Lib:ClearToasts()
    end)
end)

T:Describe("Toast gallery", function()

    T:It("clears toasts shown with queue = false", function()
        Lib:ClearToasts()
        local a = Lib:ShowToast(Fast({ title = "A", queue = false }))
        local b = Lib:ShowToast(Fast({ title = "B", queue = false }))
        Lib:ClearToasts()
        A.False(a:IsShown(), "A shown")
        A.False(b:IsShown(), "B shown")
        A.Equal(a.alnState, "done", "A state")
        A.Equal(b.alnState, "done", "B state")
    end)

    T:It("shows every kind of toast in every theme at once", function()
        local toasts = ns.ShowToastGallery()
        local themes = Lib:GetThemes("toast")
        A.Equal(#toasts, #themes * 5, "one toast per kind per theme")

        local seen, bars, timers = {}, 0, 0
        for _, f in ipairs(toasts) do
            A.Equal(f.alnState, "showing", "all showing at once")
            seen[f.titleText:GetText()] = true
            if f.bar then bars = bars + 1 end
            if f.timerBar then timers = timers + 1 end
        end
        for _, theme in ipairs(themes) do
            local label = theme:sub(1, 1):upper() .. theme:sub(2)
            A.True(seen[label], "a column for " .. theme)
        end
        A.Equal(bars, #themes * 2, "progress bars (Progress bar and Everything rows)")
        A.Equal(timers, #themes * 2, "countdown bars (Countdown bar and Everything rows)")

        Lib:ClearToasts()
        for _, f in ipairs(toasts) do
            A.False(f:IsShown(), "cleared")
        end
    end)
end)
