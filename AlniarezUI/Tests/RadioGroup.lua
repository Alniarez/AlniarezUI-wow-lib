-- AlniarezUI/Tests/RadioGroup.lua

local _, ns = ...
local T, A, Lib = ns.T, ns.A, ns.Lib

local OPTIONS = {
    { value = "gold",     label = "Gold" },
    { value = "standard", label = "Standard" },
    { value = "none",     label = "None" },
}

-- Returns the checked state of every button as a string like "x.." for
-- readable failure messages
local function States(group)
    local s = ""
    for _, b in ipairs(group.buttons) do
        s = s .. (b:GetChecked() and "x" or ".")
    end
    return s
end

T:Describe("CreateRadioGroup", function()

    T:It("creates one CheckButton per option", function()
        local group = Lib:CreateRadioGroup(ns.sandbox, { options = OPTIONS })
        A.Type(group, "Frame")
        A.Equal(#group.buttons, 3, "buttons")
        for i, b in ipairs(group.buttons) do
            A.Type(b, "CheckButton", "button " .. i)
        end
    end)

    T:It("labels each button and stores its value", function()
        local group = Lib:CreateRadioGroup(ns.sandbox, { options = OPTIONS })
        for i, b in ipairs(group.buttons) do
            A.Equal(b.value, OPTIONS[i].value, "value " .. i)
            A.Equal(b.label:GetText(), OPTIONS[i].label, "label " .. i)
        end
    end)

    T:It("accepts plain values as options", function()
        local group = Lib:CreateRadioGroup(ns.sandbox, { options = { "A", "B" } })
        A.Equal(group.buttons[2].value, "B", "value")
        A.Equal(group.buttons[2].label:GetText(), "B", "label")
    end)

    T:It("stacks buttons with spacing and sizes the group to fit", function()
        local group = Lib:CreateRadioGroup(ns.sandbox, { options = OPTIONS, spacing = 30 })
        local _, _, _, y = ns.FindPoint(group.buttons[3], "TOPLEFT")
        A.Near(y, -60, "third button y")
        A.Near(group:GetHeight(), 90, "group height")
        A.Near(group:GetWidth(),  200, "default width")
    end)

    T:It("starts with nothing selected by default", function()
        local group = Lib:CreateRadioGroup(ns.sandbox, { options = OPTIONS })
        A.Nil(group:GetValue(), "value")
        A.Equal(States(group), "...", "checked states")
    end)

    T:It("applies the initial selection", function()
        local group = Lib:CreateRadioGroup(ns.sandbox, { options = OPTIONS, selected = "standard" })
        A.Equal(group:GetValue(), "standard", "value")
        A.Equal(States(group), ".x.", "checked states")
    end)

    T:It("selects on click, clears the others and fires onChange", function()
        local calls, got = 0, nil
        local group = Lib:CreateRadioGroup(ns.sandbox, {
            options  = OPTIONS,
            selected = "gold",
            onChange = function(v) calls = calls + 1; got = v end,
        })
        group.buttons[3]:Click()
        A.Equal(group:GetValue(), "none", "value")
        A.Equal(States(group), "..x", "checked states")
        A.Equal(calls, 1, "onChange calls")
        A.Equal(got, "none", "onChange value")
    end)

    T:It("keeps the selection when clicking the selected button", function()
        local calls = 0
        local group = Lib:CreateRadioGroup(ns.sandbox, {
            options  = OPTIONS,
            selected = "gold",
            onChange = function() calls = calls + 1 end,
        })
        group.buttons[1]:Click()
        A.Equal(States(group), "x..", "checked states")
        A.Equal(calls, 0, "onChange calls")
    end)

    T:It("changes selection silently with SetValue", function()
        local calls = 0
        local group = Lib:CreateRadioGroup(ns.sandbox, {
            options  = OPTIONS,
            onChange = function() calls = calls + 1 end,
        })
        group:SetValue("standard")
        A.Equal(group:GetValue(), "standard", "value")
        A.Equal(States(group), ".x.", "checked states")
        A.Equal(calls, 0, "onChange calls")
    end)

    T:It("makes the label clickable", function()
        local group = Lib:CreateRadioGroup(ns.sandbox, { options = OPTIONS })
        local _, right = group.buttons[1]:GetHitRectInsets()
        A.True(right < 0, "right hit inset (" .. tostring(right) .. ") extends over the label")
    end)
end)
