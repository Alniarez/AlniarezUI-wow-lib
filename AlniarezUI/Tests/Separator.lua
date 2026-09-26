-- AlniarezUI/Tests/Separator.lua

local _, ns = ...
local T, A, Lib = ns.T, ns.A, ns.Lib

local function NewParent()
    local p = CreateFrame("Frame", nil, ns.sandbox)
    p:SetSize(400, 300)
    p:SetPoint("CENTER")
    return p
end

T:Describe("CreateSeparator", function()

    T:It("creates a Texture on parent", function()
        local parent = NewParent()
        local line = Lib:CreateSeparator(parent)
        A.Type(line, "Texture")
        A.Equal(line:GetParent(), parent, "parent")
        A.Equal((line:GetDrawLayer()), "ARTWORK", "default layer")
    end)

    T:It("applies a custom layer", function()
        local line = Lib:CreateSeparator(NewParent(), { layer = "OVERLAY" })
        A.Equal((line:GetDrawLayer()), "OVERLAY", "layer")
    end)

    T:It("is 1 high by default", function()
        local line = Lib:CreateSeparator(NewParent())
        A.Near(line:GetHeight(), 1, "height")
    end)

    T:It("applies thickness", function()
        local line = Lib:CreateSeparator(NewParent(), { thickness = 3 })
        A.Near(line:GetHeight(), 3, "height")
    end)

    T:It("anchors across the top of parent with y, x1, x2", function()
        local parent = NewParent()
        local line = Lib:CreateSeparator(parent, { y = -60, x1 = 20, x2 = -20 })

        local rel, relPoint, x, y = ns.FindPoint(line, "TOPLEFT")
        A.Equal(rel, parent, "TOPLEFT relativeTo")
        A.Equal(relPoint, "TOPLEFT", "TOPLEFT relativePoint")
        A.Near(x, 20,  "x1")
        A.Near(y, -60, "y (left)")

        rel, relPoint, x, y = ns.FindPoint(line, "TOPRIGHT")
        A.Equal(rel, parent, "TOPRIGHT relativeTo")
        A.Equal(relPoint, "TOPRIGHT", "TOPRIGHT relativePoint")
        A.Near(x, -20, "x2")
        A.Near(y, -60, "y (right)")
    end)

    T:It("defaults to the full width at the top", function()
        local line = Lib:CreateSeparator(NewParent())
        local _, _, x1, y1 = ns.FindPoint(line, "TOPLEFT")
        local _, _, x2, y2 = ns.FindPoint(line, "TOPRIGHT")
        A.Near(x1, 0, "x1")
        A.Near(y1, 0, "y (left)")
        A.Near(x2, 0, "x2")
        A.Near(y2, 0, "y (right)")
    end)

    T:It("spans the parent width minus the insets", function()
        local line = Lib:CreateSeparator(NewParent(), { x1 = 10, x2 = -30 })
        A.Near(line:GetWidth(), 360, "width")
    end)

    T:It("uses the default color", function()
        local line = Lib:CreateSeparator(NewParent())
        local r, g, b, a = line:GetVertexColor()
        A.Near(r, 0.6, "r")
        A.Near(g, 0.6, "g")
        A.Near(b, 0.6, "b")
        A.Near(a, 0.6, "a")
    end)

    T:It("applies color, with alpha defaulting to 1", function()
        local line = Lib:CreateSeparator(NewParent(), { color = { 1, 0.82, 0 } })
        local r, g, b, a = line:GetVertexColor()
        A.Near(r, 1,    "r")
        A.Near(g, 0.82, "g")
        A.Near(b, 0,    "b")
        A.Near(a, 1,    "a")
    end)
end)
