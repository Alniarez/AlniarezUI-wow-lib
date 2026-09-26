-- AlniarezUI/Tests/Tooltip.lua
-- GameTooltip needs a visible owner, so these use a shown but transparent
-- host. The tooltip itself flashes on screen for a moment.

local _, ns = ...
local T, A, Lib = ns.T, ns.A, ns.Lib

-- Runs fn(host) with a visible host, cleaning up even if fn fails
local function WithHost(fn)
    local host = CreateFrame("Frame", nil, UIParent)
    host:SetSize(100, 40)
    host:SetPoint("CENTER")
    host:SetAlpha(0)
    host:Show()

    local ok, err = pcall(fn, host)
    GameTooltip:Hide()
    host:Hide()
    if not ok then error(err, 0) end
end

local function NewButton(host)
    local b = CreateFrame("Button", nil, host)
    b:SetAllPoints()
    return b
end

-- Fires a script including its hooks when the client can; otherwise calls
-- the handler directly
local function Fire(frame, script)
    if frame.ExecuteFrameScript then
        frame:ExecuteFrameScript(script)
    else
        frame:GetScript(script)(frame)
    end
end

local function Enter(frame) Fire(frame, "OnEnter") end
local function Leave(frame) Fire(frame, "OnLeave") end

T:Describe("AddTooltip", function()

    T:It("returns the frame and stores the tooltip", function()
        local b = CreateFrame("Button", nil, ns.sandbox)
        A.Equal(Lib:AddTooltip(b, "Title", "Body"), b, "return value")
        A.Equal(b.alnTooltip.title, "Title", "alnTooltip.title")
        A.Equal(b.alnTooltip.text,  "Body",  "alnTooltip.text")
    end)

    T:It("shows title and text on enter", function()
        WithHost(function(host)
            local b = Lib:AddTooltip(NewButton(host), "Title", "Body")
            Enter(b)
            A.True(GameTooltip:IsShown(), "tooltip shown")
            A.Equal(GameTooltip:GetOwner(), b, "tooltip owner")
            A.Equal(GameTooltipTextLeft1:GetText(), "Title", "line 1")
            A.Equal(GameTooltipTextLeft2:GetText(), "Body",  "line 2")
        end)
    end)

    T:It("shows a title-only tooltip", function()
        WithHost(function(host)
            local b = Lib:AddTooltip(NewButton(host), "Only title")
            Enter(b)
            A.Equal(GameTooltipTextLeft1:GetText(), "Only title", "line 1")
            A.Equal(GameTooltip:NumLines(), 1, "number of lines")
        end)
    end)

    T:It("hides on leave", function()
        WithHost(function(host)
            local b = Lib:AddTooltip(NewButton(host), "Title")
            Enter(b)
            Leave(b)
            A.False(GameTooltip:IsShown(), "tooltip shown")
        end)
    end)

    T:It("does not hide another frame's tooltip on leave", function()
        WithHost(function(host)
            local b = Lib:AddTooltip(NewButton(host), "Title")
            GameTooltip:SetOwner(host, "ANCHOR_RIGHT")
            GameTooltip:SetText("Someone else")
            GameTooltip:Show()
            Leave(b)
            A.True(GameTooltip:IsShown(), "other tooltip still shown")
        end)
    end)

    T:It("calls a title function for dynamic text", function()
        WithHost(function(host)
            local b = NewButton(host)
            local n, got = 0, nil
            Lib:AddTooltip(b, function(frame)
                n, got = n + 1, frame
                return "Count " .. n, "Body " .. n
            end)
            Enter(b)
            A.Equal(GameTooltipTextLeft1:GetText(), "Count 1", "first enter")
            A.Equal(got, b, "frame argument")
            Leave(b)
            Enter(b)
            A.Equal(GameTooltipTextLeft1:GetText(), "Count 2", "second enter")
            A.Equal(GameTooltipTextLeft2:GetText(), "Body 2",  "second body")
        end)
    end)

    T:It("shows nothing when the title function returns nil", function()
        WithHost(function(host)
            GameTooltip:Hide()
            local b = Lib:AddTooltip(NewButton(host), function() return nil end)
            Enter(b)
            A.False(GameTooltip:IsShown(), "tooltip shown")
        end)
    end)

    T:It("replaces the text when called again", function()
        WithHost(function(host)
            local b = NewButton(host)
            Lib:AddTooltip(b, "Old")
            Lib:AddTooltip(b, "New")
            Enter(b)
            A.Equal(GameTooltipTextLeft1:GetText(), "New", "line 1")
        end)
    end)

    T:It("works on disabled buttons", function()
        local b = Lib:AddTooltip(CreateFrame("Button", nil, ns.sandbox), "Title")
        A.True(b:GetMotionScriptsWhileDisabled(), "motion scripts while disabled")
    end)

    T:It("keeps existing OnEnter handlers", function()
        WithHost(function(host)
            local b = NewButton(host)
            local called = false
            b:SetScript("OnEnter", function() called = true end)
            Lib:AddTooltip(b, "Title")
            Enter(b)
            A.True(called, "original handler")
            A.True(GameTooltip:IsShown(), "tooltip shown")
        end)
    end)
end)
