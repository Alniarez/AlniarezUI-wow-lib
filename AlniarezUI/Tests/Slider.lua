-- AlniarezUI/Tests/Slider.lua

local _, ns = ...
local T, A, Lib = ns.T, ns.A, ns.Lib

T:Describe("CreateSlider", function()

    T:It("creates a Slider with defaults", function()
        local s = Lib:CreateSlider(ns.sandbox)
        A.Type(s, "Slider")
        A.Near(s:GetWidth(), 200, "width")
        local min, max = s:GetMinMaxValues()
        A.Near(min, 0,   "min")
        A.Near(max, 100, "max")
        A.Near(s:GetValueStep(), 1, "step")
        A.True(s:GetObeyStepOnDrag(), "obey step on drag")
    end)

    T:It("registers a global name", function()
        local name = ns.UniqueName("Slider")
        local s = Lib:CreateSlider(ns.sandbox, { name = name })
        A.Equal(_G[name], s, "_G[name]")
    end)

    T:It("applies width, min, max and step", function()
        local s = Lib:CreateSlider(ns.sandbox, { width = 150, min = 5, max = 50, step = 5 })
        A.Near(s:GetWidth(), 150, "width")
        local min, max = s:GetMinMaxValues()
        A.Near(min, 5,  "min")
        A.Near(max, 50, "max")
        A.Near(s:GetValueStep(), 5, "step")
    end)

    T:It("has a label below the slider", function()
        local s = Lib:CreateSlider(ns.sandbox)
        A.Type(s.label, "FontString", "label")
        local rel, relPoint = ns.FindPoint(s.label, "TOP")
        A.Equal(rel, s, "label relativeTo")
        A.Equal(relPoint, "BOTTOM", "label relativePoint")
    end)

    T:It("sets the initial value and fires onChange once", function()
        local calls, last = 0, nil
        local s = Lib:CreateSlider(ns.sandbox, {
            value    = 40,
            onChange = function(v) calls = calls + 1; last = v end,
        })
        A.Near(s:GetValue(), 40, "value")
        A.Equal(calls, 1, "onChange calls")
        A.Near(last, 40, "onChange value")
    end)

    T:It("fires onChange with the new value", function()
        local last
        local s = Lib:CreateSlider(ns.sandbox, { onChange = function(v) last = v end })
        s:SetValue(73)
        A.Near(last, 73, "onChange value")
    end)

    T:It("updates the label from labelFormat", function()
        local s = Lib:CreateSlider(ns.sandbox, { labelFormat = "Scale: %d%%", value = 80 })
        A.Equal(s.label:GetText(), "Scale: 80%", "initial label")
        s:SetValue(25)
        A.Equal(s.label:GetText(), "Scale: 25%", "label after SetValue")
    end)

    T:It("leaves the label empty without labelFormat", function()
        local s = Lib:CreateSlider(ns.sandbox, { value = 50 })
        A.Equal(s.label:GetText() or "", "", "label")
    end)

    T:It("does not error without onChange", function()
        local s = Lib:CreateSlider(ns.sandbox)
        s:SetValue(10)
        A.Near(s:GetValue(), 10, "value")
    end)
end)
