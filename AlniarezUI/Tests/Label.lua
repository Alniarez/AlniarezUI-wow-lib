-- AlniarezUI/Tests/Label.lua

local _, ns = ...
local T, A, Lib = ns.T, ns.A, ns.Lib

T:Describe("CreateLabel", function()

    T:It("creates a FontString on parent", function()
        local fs = Lib:CreateLabel(ns.sandbox, { text = "Hello" })
        A.Type(fs, "FontString")
        A.Equal(fs:GetParent(), ns.sandbox, "parent")
        A.Equal(fs:GetText(), "Hello", "text")
    end)

    T:It("uses GameFontHighlight, LEFT and OVERLAY by default", function()
        local fs = Lib:CreateLabel(ns.sandbox)
        A.Equal(fs:GetFontObject(), GameFontHighlight, "font")
        A.Equal(fs:GetJustifyH(), "LEFT", "justify")
        A.Equal((fs:GetDrawLayer()), "OVERLAY", "layer")
    end)

    T:It("applies font, justify and layer", function()
        local fs = Lib:CreateLabel(ns.sandbox, {
            font = "GameFontNormalLarge", justify = "CENTER", layer = "ARTWORK",
        })
        A.Equal(fs:GetFontObject(), GameFontNormalLarge, "font")
        A.Equal(fs:GetJustifyH(), "CENTER", "justify")
        A.Equal((fs:GetDrawLayer()), "ARTWORK", "layer")
    end)

    T:It("applies width", function()
        local fs = Lib:CreateLabel(ns.sandbox, { width = 150 })
        A.Near(fs:GetWidth(), 150, "width")
    end)

    T:It("applies color, with alpha defaulting to 1", function()
        local fs = Lib:CreateLabel(ns.sandbox, { color = { 1, 0.5, 0 } })
        local r, g, b, a = fs:GetTextColor()
        A.Near(r, 1,   "r")
        A.Near(g, 0.5, "g")
        A.Near(b, 0,   "b")
        A.Near(a, 1,   "a")
    end)

    T:It("disables word wrap only when wordWrap is false", function()
        A.True(Lib:CreateLabel(ns.sandbox):CanWordWrap(), "default")
        A.False(Lib:CreateLabel(ns.sandbox, { wordWrap = false }):CanWordWrap(), "wordWrap = false")
    end)
end)
