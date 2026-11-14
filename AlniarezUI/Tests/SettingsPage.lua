-- AlniarezUI/Tests/SettingsPage.lua
-- Pages are never registered here, so the game's Settings stay untouched.

local _, ns = ...
local T, A, Lib = ns.T, ns.A, ns.Lib

T:Describe("CreateSettingsPage", function()

    T:It("creates a hidden page with its name as the title", function()
        local page = Lib:CreateSettingsPage({ name = "Test page" })
        A.Type(page, "Frame")
        A.False(page:IsShown(), "IsShown")
        A.Equal(page.title:GetText(), "Test page", "title")
    end)

    T:It("adds rows in order, one under the other", function()
        local page = Lib:CreateSettingsPage({ name = "x" })
        local header = page:AddHeader("Section")
        local row = page:AddButton({ label = "Do it", text = "Go" })
        A.Equal(#page.rows, 2, "rows")
        A.Equal(page.rows[1], header, "first row")
        local _, _, _, _, y1 = header:GetPoint(1)
        local _, _, _, _, y2 = row:GetPoint(1)
        A.True(y2 < y1, "second row is lower")
    end)

    T:It("checkbox shows get() on refresh and calls set() on click", function()
        local value = true
        local page = Lib:CreateSettingsPage()
        local row = page:AddCheckbox({
            label = "Thing",
            get = function() return value end,
            set = function(v) value = v end,
        })
        page:Refresh()
        A.True(row.control:GetChecked(), "checked after refresh")
        row.control:Click()
        A.False(value, "set(false) after a click")
    end)

    T:It("button calls onClick", function()
        local clicked = false
        local page = Lib:CreateSettingsPage()
        local row = page:AddButton({ label = "Do it", text = "Go", onClick = function() clicked = true end })
        A.Equal(row.control:GetText(), "Go", "button text")
        row.control:Click()
        A.True(clicked, "onClick")
    end)

    T:It("greys out a row whose enabled() is false", function()
        local page = Lib:CreateSettingsPage()
        local row = page:AddButton({ label = "Do it", text = "Go", enabled = function() return false end })
        page:Refresh()
        A.False(row.control:IsEnabled(), "button enabled")
    end)

    T:It("slider shows get() on refresh without calling set()", function()
        local calls = 0
        local page = Lib:CreateSettingsPage()
        page:AddSlider({
            label = "Size", min = 8, max = 24, step = 1,
            get = function() return 12 end,
            set = function() calls = calls + 1 end,
        })
        page:Refresh()
        A.Equal(calls, 0, "set() calls")
    end)
end)
