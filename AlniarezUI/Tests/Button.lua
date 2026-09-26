-- AlniarezUI/Tests/Button.lua

local _, ns = ...
local T, A, Lib = ns.T, ns.A, ns.Lib

T:Describe("CreateButton", function()

    T:It("creates a Button with defaults", function()
        local b = Lib:CreateButton(ns.sandbox)
        A.Type(b, "Button")
        A.Near(b:GetWidth(),  120, "width")
        A.Near(b:GetHeight(), 24,  "height")
    end)

    T:It("applies size and text", function()
        local b = Lib:CreateButton(ns.sandbox, { width = 80, height = 30, text = "Reset" })
        A.Near(b:GetWidth(),  80, "width")
        A.Near(b:GetHeight(), 30, "height")
        A.Equal(b:GetText(), "Reset", "text")
    end)

    T:It("registers a global name", function()
        local name = ns.UniqueName("Button")
        local b = Lib:CreateButton(ns.sandbox, { name = name })
        A.Equal(_G[name], b, "_G[name]")
    end)

    T:It("fires onClick with the button as self", function()
        local calls, got = 0, nil
        local b = Lib:CreateButton(ns.sandbox, {
            onClick = function(self) calls = calls + 1; got = self end,
        })
        b:Click()
        A.Equal(calls, 1, "onClick calls")
        A.Equal(got, b, "self")
    end)

    T:It("does not error without onClick", function()
        local b = Lib:CreateButton(ns.sandbox)
        b:Click()
    end)

    T:It("starts enabled by default", function()
        A.True(Lib:CreateButton(ns.sandbox):IsEnabled(), "enabled")
    end)

    T:It("starts disabled with disabled = true", function()
        local calls = 0
        local b = Lib:CreateButton(ns.sandbox, {
            disabled = true,
            onClick  = function() calls = calls + 1 end,
        })
        A.False(b:IsEnabled(), "enabled")
        b:Click()
        A.Equal(calls, 0, "onClick calls while disabled")
    end)

    T:It("has no tooltip by default", function()
        A.Nil(Lib:CreateButton(ns.sandbox).alnTooltip, "alnTooltip")
    end)

    T:It("adds a tooltip", function()
        local b = Lib:CreateButton(ns.sandbox, { tooltip = "Reset", tooltipText = "Clears everything" })
        A.Equal(b.alnTooltip.title, "Reset", "tooltip title")
        A.Equal(b.alnTooltip.text,  "Clears everything", "tooltip text")
    end)
end)
