-- AlniarezUI/Tests/IconButton.lua

local _, ns = ...
local T, A, Lib = ns.T, ns.A, ns.Lib

T:Describe("CreateIconButton", function()

    T:It("creates a 32x32 Button with an icon", function()
        local b = Lib:CreateIconButton(ns.sandbox)
        A.Type(b, "Button")
        A.Near(b:GetWidth(),  32, "width")
        A.Near(b:GetHeight(), 32, "height")
        A.Type(b.icon, "Texture", "icon")
        A.NotNil(b.icon:GetTexture(), "default icon texture")
    end)

    T:It("registers a global name", function()
        local name = ns.UniqueName("IconButton")
        local b = Lib:CreateIconButton(ns.sandbox, { name = name })
        A.Equal(_G[name], b, "_G[name]")
    end)

    T:It("applies size", function()
        local b = Lib:CreateIconButton(ns.sandbox, { size = 48 })
        A.Near(b:GetWidth(),  48, "width")
        A.Near(b:GetHeight(), 48, "height")
    end)

    T:It("applies icon", function()
        local b = Lib:CreateIconButton(ns.sandbox, { icon = "Interface\\Icons\\INV_Sword_04" })
        A.NotNil(b.icon:GetTexture(), "icon texture")
    end)

    T:It("has a hover highlight", function()
        local b = Lib:CreateIconButton(ns.sandbox)
        A.NotNil(b:GetHighlightTexture(), "highlight texture")
    end)

    T:It("fires onClick with the button as self", function()
        local got
        local b = Lib:CreateIconButton(ns.sandbox, { onClick = function(self) got = self end })
        b:Click()
        A.Equal(got, b, "self")
    end)

    T:It("nudges the icon while pressed", function()
        local b = Lib:CreateIconButton(ns.sandbox)
        b:GetScript("OnMouseDown")(b)
        local _, _, x, y = ns.FindPoint(b.icon, "TOPLEFT")
        A.Near(x, 1,  "pressed x")
        A.Near(y, -1, "pressed y")
        b:GetScript("OnMouseUp")(b)
        _, _, x, y = ns.FindPoint(b.icon, "TOPLEFT")
        A.Near(x, 0, "released x")
        A.Near(y, 0, "released y")
    end)

    T:It("greys out while disabled", function()
        local b = Lib:CreateIconButton(ns.sandbox)
        b:Disable()
        A.True(b.icon:IsDesaturated(), "desaturated when disabled")
        b:Enable()
        A.False(b.icon:IsDesaturated(), "desaturated when enabled")
    end)

    T:It("starts disabled with disabled = true", function()
        local b = Lib:CreateIconButton(ns.sandbox, { disabled = true })
        A.False(b:IsEnabled(), "enabled")
        A.True(b.icon:IsDesaturated(), "desaturated")
    end)

    T:It("adds a tooltip", function()
        local b = Lib:CreateIconButton(ns.sandbox, { tooltip = "Sword", tooltipText = "Pointy" })
        A.NotNil(b.alnTooltip, "alnTooltip")
        A.Equal(b.alnTooltip.title, "Sword",  "tooltip title")
        A.Equal(b.alnTooltip.text,  "Pointy", "tooltip text")
    end)
end)
