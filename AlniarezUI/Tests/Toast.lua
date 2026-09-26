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
