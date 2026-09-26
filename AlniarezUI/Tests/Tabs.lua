-- AlniarezUI/Tests/Tabs.lua
-- The first two tests say whether this client has the native tab
-- templates; if "top" is missing, most other tests fail with that reason.

local _, ns = ...
local T, A, Lib = ns.T, ns.A, ns.Lib

local function Panels(n)
    local panels = {}
    for i = 1, n do panels[i] = CreateFrame("Frame", nil, ns.sandbox) end
    return panels
end

-- Returns which panels are shown as a string like ".x." for readable
-- failure messages
local function Shown(panels)
    local s = ""
    for _, p in ipairs(panels) do s = s .. (p:IsShown() and "x" or ".") end
    return s
end

T:Describe("CreateTabs", function()

    T:It("client has native top tabs", function()
        A.True(Lib:HasTabs("top"), "HasTabs(\"top\")")
        A.True(Lib:HasTabs(), "HasTabs() defaults to top")
    end)

    T:It("client has native bottom tabs", function()
        A.True(Lib:HasTabs("bottom"), "HasTabs(\"bottom\")")
    end)

    T:It("creates one tab button per label", function()
        local tabs = Lib:CreateTabs(ns.sandbox, { tabs = { "One", "Two", "Three" } })
        A.Type(tabs, "Frame")
        A.Equal(#tabs.buttons, 3, "buttons")
        A.Type(tabs.buttons[1], "Button", "button 1")
        A.Equal(tabs.buttons[2]:GetText(), "Two", "button 2 text")
        A.Equal(tabs.buttons[3]:GetID(), 3, "button 3 ID")
    end)

    T:It("creates bottom style tabs", function()
        local tabs = Lib:CreateTabs(ns.sandbox, { tabs = { "One", "Two" }, style = "bottom" })
        A.Equal(#tabs.buttons, 2, "buttons")
        A.Equal(tabs:GetSelected(), 1, "selected")
    end)

    T:It("errors for an unknown style", function()
        local ok = pcall(Lib.CreateTabs, Lib, ns.sandbox, { tabs = { "A" }, style = "sideways" })
        A.False(ok, "created tabs with style = \"sideways\"")
    end)

    T:It("chains tabs left to right with gap", function()
        local tabs = Lib:CreateTabs(ns.sandbox, { tabs = { "One", "Two" }, gap = -8 })
        local rel, relPoint, x = ns.FindPoint(tabs.buttons[2], "LEFT")
        A.Equal(rel, tabs.buttons[1], "tab 2 relativeTo")
        A.Equal(relPoint, "RIGHT", "tab 2 relativePoint")
        A.Near(x, -8, "gap")
    end)

    T:It("applies tabWidth to every tab", function()
        local tabs = Lib:CreateTabs(ns.sandbox, { tabs = { "A", "A much longer label" }, tabWidth = 90 })
        A.Near(tabs.buttons[1]:GetWidth(), 90, "tab 1 width")
        A.Near(tabs.buttons[2]:GetWidth(), 90, "tab 2 width")
    end)

    T:It("sizes tabs to fit their text by default", function()
        local tabs = Lib:CreateTabs(ns.sandbox, { tabs = { "A", "A much longer label" } })
        local short, long = tabs.buttons[1]:GetWidth(), tabs.buttons[2]:GetWidth()
        A.True(long > short, "long tab (" .. long .. ") is wider than short tab (" .. short .. ")")
    end)

    T:It("sizes the row to fit its tabs", function()
        local tabs = Lib:CreateTabs(ns.sandbox, { tabs = { "One", "Two", "Three" }, tabWidth = 80, gap = 4 })
        A.Near(tabs:GetWidth(), 248, "row width")
        A.Near(tabs:GetHeight(), tabs.buttons[1]:GetHeight(), "row height")
    end)

    T:It("selects the first tab by default", function()
        local tabs = Lib:CreateTabs(ns.sandbox, { tabs = { "One", "Two" } })
        A.Equal(tabs:GetSelected(), 1, "selected")
        A.Equal(PanelTemplates_GetSelectedTab(tabs), 1, "PanelTemplates selected tab")
    end)

    T:It("applies the initial selection", function()
        local tabs = Lib:CreateTabs(ns.sandbox, { tabs = { "One", "Two" }, selected = 2 })
        A.Equal(tabs:GetSelected(), 2, "selected")
        A.Equal(PanelTemplates_GetSelectedTab(tabs), 2, "PanelTemplates selected tab")
    end)

    T:It("shows only the selected tab's panel", function()
        local panels = Panels(3)
        Lib:CreateTabs(ns.sandbox, { tabs = { "A", "B", "C" }, panels = panels, selected = 2 })
        A.Equal(Shown(panels), ".x.", "shown panels")
    end)

    T:It("switches panels on click and fires onSelect", function()
        local panels = Panels(3)
        local calls, got = 0, nil
        local tabs = Lib:CreateTabs(ns.sandbox, {
            tabs     = { "A", "B", "C" },
            panels   = panels,
            onSelect = function(i) calls = calls + 1; got = i end,
        })
        tabs.buttons[3]:Click()
        A.Equal(tabs:GetSelected(), 3, "selected")
        A.Equal(PanelTemplates_GetSelectedTab(tabs), 3, "PanelTemplates selected tab")
        A.Equal(Shown(panels), "..x", "shown panels")
        A.Equal(calls, 1, "onSelect calls")
        A.Equal(got, 3, "onSelect index")
    end)

    T:It("does not fire onSelect for the selected tab or on creation", function()
        local calls = 0
        local tabs = Lib:CreateTabs(ns.sandbox, {
            tabs = { "A", "B" }, onSelect = function() calls = calls + 1 end,
        })
        tabs:Select(1)
        A.Equal(calls, 0, "onSelect calls")
    end)

    T:It("ignores out of range indexes", function()
        local tabs = Lib:CreateTabs(ns.sandbox, { tabs = { "A", "B" } })
        tabs:Select(5)
        A.Equal(tabs:GetSelected(), 1, "selected")
    end)

    T:It("attaches panels later with SetPanel", function()
        local tabs = Lib:CreateTabs(ns.sandbox, { tabs = { "A", "B" } })
        local p1, p2 = CreateFrame("Frame", nil, ns.sandbox), CreateFrame("Frame", nil, ns.sandbox)
        tabs:SetPanel(1, p1)
        tabs:SetPanel(2, p2)
        A.True(p1:IsShown(),  "panel 1 shown")
        A.False(p2:IsShown(), "panel 2 shown")
        tabs:Select(2)
        A.False(p1:IsShown(), "panel 1 shown after select")
        A.True(p2:IsShown(),  "panel 2 shown after select")
    end)
end)
