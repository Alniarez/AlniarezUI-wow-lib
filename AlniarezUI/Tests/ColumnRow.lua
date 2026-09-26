-- AlniarezUI/Tests/ColumnRow.lua

local _, ns = ...
local T, A, Lib = ns.T, ns.A, ns.Lib

local function NewParent()
    local p = CreateFrame("Frame", nil, ns.sandbox)
    p:SetSize(400, 100)
    return p
end

T:Describe("CreateColumnRow", function()

    T:It("returns one FontString per column", function()
        local cols = Lib:CreateColumnRow(NewParent(), nil, {
            { width = 100 }, { width = 50 }, { width = 25 },
        })
        A.Equal(#cols, 3, "count")
        for i, fs in ipairs(cols) do
            A.Type(fs, "FontString", "column " .. i)
        end
    end)

    T:It("returns an empty table for no columns", function()
        local cols = Lib:CreateColumnRow(NewParent(), nil, {})
        A.Equal(#cols, 0, "count")
    end)

    T:It("applies width and justify", function()
        local cols = Lib:CreateColumnRow(NewParent(), nil, {
            { width = 120 },
            { width = 60, justify = "RIGHT" },
        })
        A.Near(cols[1]:GetWidth(), 120, "width 1")
        A.Near(cols[2]:GetWidth(), 60,  "width 2")
        A.Equal(cols[1]:GetJustifyH(), "LEFT",  "default justify")
        A.Equal(cols[2]:GetJustifyH(), "RIGHT", "justify")
    end)

    T:It("sets initial text", function()
        local cols = Lib:CreateColumnRow(NewParent(), nil, {
            { width = 100, text = "Mob" },
            { width = 100, text = "Kills" },
        })
        A.Equal(cols[1]:GetText(), "Mob",   "text 1")
        A.Equal(cols[2]:GetText(), "Kills", "text 2")
    end)

    T:It("uses GameFontHighlight by default", function()
        local cols = Lib:CreateColumnRow(NewParent(), nil, { { width = 100 } })
        A.Equal(cols[1]:GetFontObject(), GameFontHighlight, "font object")
    end)

    T:It("applies a custom font to every column", function()
        local cols = Lib:CreateColumnRow(NewParent(), { font = "GameFontNormal" }, {
            { width = 100 }, { width = 100 },
        })
        A.Equal(cols[1]:GetFontObject(), GameFontNormal, "font 1")
        A.Equal(cols[2]:GetFontObject(), GameFontNormal, "font 2")
    end)

    T:It("disables word wrap only when wordWrap is false", function()
        local cols = Lib:CreateColumnRow(NewParent(), nil, {
            { width = 100 },
            { width = 100, wordWrap = false },
        })
        A.True(cols[1]:CanWordWrap(),  "default word wrap")
        A.False(cols[2]:CanWordWrap(), "wordWrap = false")
    end)

    T:It("anchors the first column TOPLEFT to the parent with x/y", function()
        local parent = NewParent()
        local cols = Lib:CreateColumnRow(parent, { x = 24, y = -44 }, { { width = 100 } })
        local rel, relPoint, x, y = ns.FindPoint(cols[1], "TOPLEFT")
        A.Equal(rel, parent, "relativeTo")
        A.Equal(relPoint, "TOPLEFT", "relativePoint")
        A.Near(x, 24,  "x")
        A.Near(y, -44, "y")
    end)

    T:It("anchors the first column to anchorTo", function()
        local parent = NewParent()
        local other  = CreateFrame("Frame", nil, parent)
        local cols = Lib:CreateColumnRow(parent, { anchorTo = other }, { { width = 100 } })
        A.Equal((ns.FindPoint(cols[1], "TOPLEFT")), other, "relativeTo")
        A.Equal(cols[1]:GetParent(), parent, "still parented to parent")
    end)

    T:It("chains later columns LEFT to the previous RIGHT with gap", function()
        local cols = Lib:CreateColumnRow(NewParent(), nil, {
            { width = 100 },
            { width = 100 },
            { width = 100, gap = 6 },
        })
        local rel, relPoint, x = ns.FindPoint(cols[2], "LEFT")
        A.Equal(rel, cols[1], "col 2 relativeTo")
        A.Equal(relPoint, "RIGHT", "col 2 relativePoint")
        A.Near(x, 0, "col 2 default gap")

        rel, relPoint, x = ns.FindPoint(cols[3], "LEFT")
        A.Equal(rel, cols[2], "col 3 relativeTo")
        A.Near(x, 6, "col 3 gap")
    end)
end)
