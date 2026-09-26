-- AlniarezUI/Tests/ProgressBar.lua

local _, ns = ...
local T, A, Lib = ns.T, ns.A, ns.Lib

T:Describe("CreateProgressBar", function()

    T:It("creates a StatusBar with defaults", function()
        local bar = Lib:CreateProgressBar(ns.sandbox)
        A.Type(bar, "StatusBar")
        A.Near(bar:GetWidth(),  200, "width")
        A.Near(bar:GetHeight(), 16,  "height")
        local min, max = bar:GetMinMaxValues()
        A.Near(min, 0,   "min")
        A.Near(max, 100, "max")
        A.Near(bar:GetValue(), 0, "value")
    end)

    T:It("registers a global name", function()
        local name = ns.UniqueName("ProgressBar")
        local bar = Lib:CreateProgressBar(ns.sandbox, { name = name })
        A.Equal(_G[name], bar, "_G[name]")
    end)

    T:It("applies size, min, max and value", function()
        local bar = Lib:CreateProgressBar(ns.sandbox, {
            width = 120, height = 10, min = 10, max = 50, value = 30,
        })
        A.Near(bar:GetWidth(),  120, "width")
        A.Near(bar:GetHeight(), 10,  "height")
        local min, max = bar:GetMinMaxValues()
        A.Near(min, 10, "min")
        A.Near(max, 50, "max")
        A.Near(bar:GetValue(), 30, "value")
    end)

    T:It("has a bar texture and a background", function()
        local bar = Lib:CreateProgressBar(ns.sandbox)
        A.NotNil(bar:GetStatusBarTexture(), "status bar texture")
        A.Type(bar.bg, "Texture", "bg")
        A.Equal((bar.bg:GetDrawLayer()), "BACKGROUND", "bg layer")
    end)

    T:It("uses green by default", function()
        local r, g, b = Lib:CreateProgressBar(ns.sandbox):GetStatusBarColor()
        A.Near(r, 0.2, "r")
        A.Near(g, 0.7, "g")
        A.Near(b, 0.2, "b")
    end)

    T:It("applies color", function()
        local r, g, b, a = Lib:CreateProgressBar(ns.sandbox, { color = { 0.8, 0.1, 0.1, 0.5 } }):GetStatusBarColor()
        A.Near(r, 0.8, "r")
        A.Near(g, 0.1, "g")
        A.Near(b, 0.1, "b")
        A.Near(a, 0.5, "a")
    end)

    T:It("shows labelFormat with value and max", function()
        local bar = Lib:CreateProgressBar(ns.sandbox, { labelFormat = "%d / %d", value = 25 })
        A.Equal(bar.label:GetText(), "25 / 100", "initial label")
    end)

    T:It("updates the label on SetValue", function()
        local bar = Lib:CreateProgressBar(ns.sandbox, { labelFormat = "%d / %d" })
        bar:SetValue(60)
        A.Equal(bar.label:GetText(), "60 / 100", "label")
    end)

    T:It("updates the label on SetMinMaxValues", function()
        local bar = Lib:CreateProgressBar(ns.sandbox, { labelFormat = "%d / %d", value = 5 })
        bar:SetMinMaxValues(0, 20)
        A.Equal(bar.label:GetText(), "5 / 20", "label")
    end)

    T:It("leaves the label empty without labelFormat", function()
        local bar = Lib:CreateProgressBar(ns.sandbox, { value = 50 })
        A.Equal(bar.label:GetText() or "", "", "label")
    end)
end)
