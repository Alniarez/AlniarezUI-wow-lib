-- AlniarezUI/Tests/Checkbox.lua

local _, ns = ...
local T, A, Lib = ns.T, ns.A, ns.Lib

T:Describe("CreateCheckbox", function()

    T:It("creates a CheckButton with a label", function()
        local cb = Lib:CreateCheckbox(ns.sandbox, { label = "Enable thing" })
        A.Type(cb, "CheckButton")
        A.Type(cb.label, "FontString", "label")
        A.Equal(cb.label:GetText(), "Enable thing", "label text")
    end)

    T:It("places the label to the right of the button", function()
        local cb = Lib:CreateCheckbox(ns.sandbox, { label = "x" })
        local rel, relPoint = ns.FindPoint(cb.label, "LEFT")
        A.Equal(rel, cb, "label relativeTo")
        A.Equal(relPoint, "RIGHT", "label relativePoint")
    end)

    T:It("registers a global name", function()
        local name = ns.UniqueName("Checkbox")
        local cb = Lib:CreateCheckbox(ns.sandbox, { name = name })
        A.Equal(_G[name], cb, "_G[name]")
    end)

    T:It("starts unchecked by default", function()
        local cb = Lib:CreateCheckbox(ns.sandbox)
        A.False(cb:GetChecked(), "GetChecked")
    end)

    T:It("applies the initial checked state", function()
        local on  = Lib:CreateCheckbox(ns.sandbox, { checked = true })
        local off = Lib:CreateCheckbox(ns.sandbox, { checked = false })
        A.True(on:GetChecked(),   "checked = true")
        A.False(off:GetChecked(), "checked = false")
    end)

    T:It("toggles and fires onChange on click", function()
        local calls, last = 0, nil
        local cb = Lib:CreateCheckbox(ns.sandbox, {
            checked  = false,
            onChange = function(checked) calls = calls + 1; last = checked end,
        })
        cb:Click()
        A.Equal(calls, 1, "onChange calls")
        A.True(last, "onChange value after first click")
        A.True(cb:GetChecked(), "GetChecked after first click")

        cb:Click()
        A.Equal(calls, 2, "onChange calls")
        A.False(last, "onChange value after second click")
    end)

    T:It("does not fire onChange on creation", function()
        local calls = 0
        Lib:CreateCheckbox(ns.sandbox, { checked = true, onChange = function() calls = calls + 1 end })
        A.Equal(calls, 0, "onChange calls")
    end)

    T:It("adds a tooltip", function()
        local cb = Lib:CreateCheckbox(ns.sandbox, { tooltip = "Sound", tooltipText = "Plays a sound" })
        A.Equal(cb.alnTooltip.title, "Sound", "tooltip title")
        A.Equal(cb.alnTooltip.text,  "Plays a sound", "tooltip text")
    end)

    T:It("does not error without onChange", function()
        local cb = Lib:CreateCheckbox(ns.sandbox)
        cb:Click()
        A.True(cb:GetChecked(), "GetChecked")
    end)
end)
