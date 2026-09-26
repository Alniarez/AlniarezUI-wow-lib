-- AlniarezUI/Tests/Dialog.lua

local _, ns = ...
local T, A, Lib = ns.T, ns.A, ns.Lib

local STANDARD_EDGE = "Interface\\DialogFrame\\UI-DialogBox-Border"
local GOLD_EDGE     = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border"

T:Describe("CreateDialog", function()

    T:It("works with no opts", function()
        local f = Lib:CreateDialog()
        A.Type(f, "Frame")
        A.Near(f:GetWidth(),  400, "width")
        A.Near(f:GetHeight(), 300, "height")
        A.Equal(f:GetParent(), UIParent, "parent")
    end)

    T:It("starts hidden", function()
        local f = Lib:CreateDialog({ parent = ns.sandbox })
        A.False(f:IsShown(), "IsShown")
    end)

    T:It("applies width, height and parent", function()
        local f = Lib:CreateDialog({ parent = ns.sandbox, width = 321, height = 123 })
        A.Near(f:GetWidth(),  321, "width")
        A.Near(f:GetHeight(), 123, "height")
        A.Equal(f:GetParent(), ns.sandbox, "parent")
    end)

    T:It("registers a global name", function()
        local name = ns.UniqueName("Dialog")
        local f = Lib:CreateDialog({ parent = ns.sandbox, name = name })
        A.Equal(_G[name], f, "_G[name]")
        A.Equal(f:GetName(), name, "GetName")
    end)

    T:It("is anchored to CENTER", function()
        local f = Lib:CreateDialog({ parent = ns.sandbox })
        A.Equal(f:GetNumPoints(), 1, "number of anchors")
        A.Equal((f:GetPoint(1)), "CENTER", "anchor point")
    end)

    T:It("is movable and clamped to screen", function()
        local f = Lib:CreateDialog({ parent = ns.sandbox })
        A.True(f:IsMovable(), "IsMovable")
        A.True(f:IsClampedToScreen(), "IsClampedToScreen")
    end)

    T:It("applies strata and level", function()
        local f = Lib:CreateDialog({ parent = ns.sandbox, strata = "DIALOG", level = 42 })
        A.Equal(f:GetFrameStrata(), "DIALOG", "strata")
        A.Equal(f:GetFrameLevel(), 42, "level")
    end)

    T:It("defaults to the standard theme", function()
        local f = Lib:CreateDialog({ parent = ns.sandbox })
        A.Equal(f:GetBackdrop().edgeFile, STANDARD_EDGE, "edgeFile")
    end)

    T:It("applies the standard theme", function()
        local f = Lib:CreateDialog({ parent = ns.sandbox, theme = "standard" })
        A.Equal(f:GetBackdrop().edgeFile, STANDARD_EDGE, "edgeFile")
    end)

    T:It("applies the gold theme", function()
        local f = Lib:CreateDialog({ parent = ns.sandbox, theme = "gold" })
        A.Equal(f:GetBackdrop().edgeFile, GOLD_EDGE, "edgeFile")
    end)

    T:It("falls back to the standard theme for unknown names", function()
        local f = Lib:CreateDialog({ parent = ns.sandbox, theme = "nope" })
        A.Equal(f:GetBackdrop().edgeFile, STANDARD_EDGE, "edgeFile")
    end)

    T:It("lists its themes with GetThemes", function()
        local names = Lib:GetThemes()
        A.Equal(#names, 2, "number of themes")
        A.Equal(names[1], "gold",     "theme 1")
        A.Equal(names[2], "standard", "theme 2")
    end)

    T:It("reports its theme with GetTheme", function()
        A.Equal(Lib:CreateDialog({ parent = ns.sandbox }):GetTheme(), "standard", "default")
        A.Equal(Lib:CreateDialog({ parent = ns.sandbox, theme = "gold" }):GetTheme(), "gold", "gold")
        A.Equal(Lib:CreateDialog({ parent = ns.sandbox, theme = "nope" }):GetTheme(), "standard", "unknown")
    end)

    T:It("switches theme with SetTheme", function()
        local f = Lib:CreateDialog({ parent = ns.sandbox, title = "Hello" })
        local banner = f.titleBanner:GetTexture()

        f:SetTheme("gold")
        A.Equal(f:GetTheme(), "gold", "theme")
        A.Equal(f:GetBackdrop().edgeFile, GOLD_EDGE, "edgeFile")
        A.True(f.titleBanner:GetTexture() ~= banner, "banner texture changed")

        f:SetTheme("standard")
        A.Equal(f:GetBackdrop().edgeFile, STANDARD_EDGE, "edgeFile after switching back")
        A.Equal(f.titleBanner:GetTexture(), banner, "banner texture after switching back")
    end)

    T:It("falls back to standard in SetTheme for unknown names", function()
        local f = Lib:CreateDialog({ parent = ns.sandbox, theme = "gold" })
        f:SetTheme("nope")
        A.Equal(f:GetTheme(), "standard", "theme")
        A.Equal(f:GetBackdrop().edgeFile, STANDARD_EDGE, "edgeFile")
    end)

    T:It("switches theme without a title", function()
        local f = Lib:CreateDialog({ parent = ns.sandbox })
        f:SetTheme("gold")
        A.Equal(f:GetBackdrop().edgeFile, GOLD_EDGE, "edgeFile")
    end)

    T:It("has no title fields without a title", function()
        local f = Lib:CreateDialog({ parent = ns.sandbox })
        A.Nil(f.titleText,   "titleText")
        A.Nil(f.titleBanner, "titleBanner")
        A.Nil(f.dragHandle,  "dragHandle")
    end)

    T:It("is draggable from the whole frame without a title", function()
        local f = Lib:CreateDialog({ parent = ns.sandbox })
        A.True(f:IsMouseEnabled(), "IsMouseEnabled")
        A.NotNil(f:GetScript("OnDragStart"), "OnDragStart")
        A.NotNil(f:GetScript("OnDragStop"),  "OnDragStop")
    end)

    T:It("creates title text and banner", function()
        local f = Lib:CreateDialog({ parent = ns.sandbox, title = "Hello" })
        A.Type(f.titleText,   "FontString", "titleText")
        A.Type(f.titleBanner, "Texture",    "titleBanner")
        A.Equal(f.titleText:GetText(), "Hello", "title text")
        A.Near(f.titleBanner:GetWidth(), 256, "default banner width")
    end)

    T:It("applies titleWidth to banner and drag handle", function()
        local f = Lib:CreateDialog({ parent = ns.sandbox, title = "Hello", titleWidth = 300 })
        A.Near(f.titleBanner:GetWidth(), 300, "banner width")
        A.Near(f.dragHandle:GetWidth(),  300, "drag handle width")
    end)

    T:It("drags from the banner when titled", function()
        local f = Lib:CreateDialog({ parent = ns.sandbox, title = "Hello" })
        A.Type(f.dragHandle, "Frame", "dragHandle")
        A.True(f.dragHandle:IsMouseEnabled(), "handle IsMouseEnabled")
        A.NotNil(f.dragHandle:GetScript("OnDragStart"), "handle OnDragStart")
        A.NotNil(f.dragHandle:GetScript("OnDragStop"),  "handle OnDragStop")
    end)

    T:It("has a close button that hides the frame", function()
        local f = Lib:CreateDialog({ parent = ns.sandbox })
        A.Type(f.closeButton, "Button", "closeButton")
        A.Equal(f.closeButton:GetParent(), f, "closeButton parent")
        f:Show()
        f.closeButton:Click()
        A.False(f:IsShown(), "IsShown after close")
    end)

    T:It("omits the close button with noCloseButton", function()
        local f = Lib:CreateDialog({ parent = ns.sandbox, noCloseButton = true })
        A.Nil(f.closeButton, "closeButton")
    end)
end)
