-- AlniarezUI/Tests/SortHeader.lua

local _, ns = ...
local T, A, Lib = ns.T, ns.A, ns.Lib

local COLS = {
    { text = "Name",  key = "name",  width = 150 },
    { text = "Kills", key = "kills", width = 60,  justify = "RIGHT" },
    { text = "Note",  width = 80 },   -- no key: not sortable
}

local function NewParent()
    local p = CreateFrame("Frame", nil, ns.sandbox)
    p:SetSize(400, 100)
    p:SetPoint("CENTER")
    return p
end

local function New(opts)
    return Lib:CreateSortHeader(NewParent(), opts, COLS)
end

local function Click(header, i)
    header.buttons[i]:Click()
end

-- Which columns show an arrow, as a string like "x.." for readable failures
local function Arrows(header)
    local s = ""
    for i = 1, #COLS do
        local b = header.buttons[i]
        s = s .. ((b and b.arrow:IsShown()) and "x" or ".")
    end
    return s
end

-- true when the arrow is flipped to point up
local function PointsUp(header, i)
    local _, ulY = header.buttons[i].arrow:GetTexCoord()
    return ulY > 0.5
end

T:Describe("CreateSortHeader", function()

    T:It("creates one label per column with its text", function()
        local h = New()
        A.Equal(#h.labels, 3, "labels")
        A.Type(h.labels[1], "FontString", "label 1")
        A.Equal(h.labels[2]:GetText(), "Kills", "label 2 text")
    end)

    T:It("uses GameFontNormal by default", function()
        A.Equal(New().labels[1]:GetFontObject(), GameFontNormal, "font")
    end)

    T:It("lays out like CreateColumnRow", function()
        local parent = NewParent()
        local h    = Lib:CreateSortHeader(parent, { x = 24, y = -44 }, COLS)
        local plain = Lib:CreateColumnRow(parent, { x = 24, y = -44 }, COLS)
        for i = 1, #COLS do
            A.Near(h.labels[i]:GetWidth(), plain[i]:GetWidth(), "width " .. i)
            A.Equal(h.labels[i]:GetJustifyH(), plain[i]:GetJustifyH(), "justify " .. i)
        end
        local _, _, x, y = ns.FindPoint(h.labels[1], "TOPLEFT")
        A.Near(x, 24,  "x")
        A.Near(y, -44, "y")
    end)

    T:It("supports fill columns", function()
        local h = Lib:CreateSortHeader(NewParent(), { right = 10 }, {
            { text = "Name", key = "name", fill = true },
            { text = "Kills", key = "kills", width = 60 },
        })
        -- 400 - 60 - 10
        A.Near(h.labels[1]:GetWidth(), 330, "fill width")
    end)

    T:It("makes only columns with a key clickable", function()
        local h = New()
        A.Type(h.buttons[1], "Button", "button 1")
        A.Type(h.buttons[2], "Button", "button 2")
        A.Nil(h.buttons[3], "button for the column without a key")
        A.Equal(h.buttons[2].key, "kills", "button 2 key")
    end)

    T:It("covers each label with its button", function()
        local h = New()
        local rel = ns.FindPoint(h.buttons[1], "TOPLEFT")
        A.Equal(rel, h.labels[1], "button relativeTo")
        A.NotNil(h.buttons[1]:GetHighlightTexture(), "hover highlight")
    end)

    T:It("shows no arrow without an initial sort", function()
        local h = New()
        A.Equal(Arrows(h), "...", "arrows")
        A.Nil((h:GetSort()), "sort key")
    end)

    T:It("applies the initial sort, ascending by default", function()
        local h = New({ sortKey = "kills" })
        local key, asc = h:GetSort()
        A.Equal(key, "kills", "sort key")
        A.True(asc, "ascending")
        A.Equal(Arrows(h), ".x.", "arrows")
        A.True(PointsUp(h, 2), "arrow points up")
    end)

    T:It("applies an explicit initial direction", function()
        local h = New({ sortKey = "kills", ascending = false })
        A.False(select(2, h:GetSort()), "ascending")
        A.False(PointsUp(h, 2), "arrow points down")
    end)

    T:It("cycles a column through ascending, descending, unsorted", function()
        local got = {}
        local h = New({ onSort = function(k, a) table.insert(got, { k, a }) end })

        Click(h, 1)
        A.Equal(got[1][1], "name", "click 1 key")
        A.True(got[1][2], "click 1 ascending")
        A.Equal(Arrows(h), "x..", "arrows after click 1")
        A.True(PointsUp(h, 1), "arrow points up after click 1")

        Click(h, 1)
        A.Equal(got[2][1], "name", "click 2 key")
        A.False(got[2][2], "click 2 ascending")
        A.False(PointsUp(h, 1), "arrow points down after click 2")

        Click(h, 1)
        A.Equal(#got, 3, "onSort calls")
        A.Nil(got[3][1], "click 3 key (unsorted)")
        A.Nil(got[3][2], "click 3 ascending (unsorted)")
        A.Equal(Arrows(h), "...", "arrows after click 3")
        A.Nil((h:GetSort()), "GetSort after click 3")

        Click(h, 1)
        A.Equal(got[4][1], "name", "click 4 starts over: key")
        A.True(got[4][2], "click 4 starts over: ascending")
    end)

    T:It("starts a different column at ascending", function()
        local got
        local h = New({ sortKey = "name", ascending = false, onSort = function(k, a) got = { k, a } end })
        Click(h, 2)
        A.Equal(got[1], "kills", "key")
        A.True(got[2], "ascending")
        A.Equal(Arrows(h), ".x.", "arrows")
    end)

    T:It("changes the sort silently with SetSort", function()
        local calls = 0
        local h = New({ onSort = function() calls = calls + 1 end })
        h:SetSort("kills", true)
        local key, asc = h:GetSort()
        A.Equal(key, "kills", "sort key")
        A.True(asc, "ascending")
        A.Equal(Arrows(h), ".x.", "arrows")
        A.Equal(calls, 0, "onSort calls")
    end)

    T:It("clears the sort with SetSort(nil)", function()
        local h = New({ sortKey = "name" })
        h:SetSort(nil)
        A.Nil((h:GetSort()), "sort key")
        A.Nil(select(2, h:GetSort()), "ascending")
        A.Equal(Arrows(h), "...", "arrows")
    end)

    T:It("defaults SetSort to ascending", function()
        local h = New()
        h:SetSort("kills")
        A.True(select(2, h:GetSort()), "ascending")
    end)

    T:It("hides every arrow for a key no column has", function()
        local h = New({ sortKey = "name" })
        h:SetSort("nope", false)
        A.Equal(Arrows(h), "...", "arrows")
    end)

    T:It("puts the arrow after left-aligned text and before right-aligned text", function()
        local h = New({ sortKey = "name" })
        local rel, relPoint, x = ns.FindPoint(h.buttons[1].arrow, "LEFT")
        A.Equal(rel, h.labels[1], "left column arrow relativeTo")
        A.Equal(relPoint, "LEFT", "left column arrow relativePoint")
        A.True(x > 0, "left column arrow x (" .. tostring(x) .. ") is after the text")

        h:SetSort("kills")
        rel, relPoint, x = ns.FindPoint(h.buttons[2].arrow, "RIGHT")
        A.Equal(rel, h.labels[2], "right column arrow relativeTo")
        A.Equal(relPoint, "RIGHT", "right column arrow relativePoint")
        A.True(x < 0, "right column arrow x (" .. tostring(x) .. ") is before the text")
    end)
end)
