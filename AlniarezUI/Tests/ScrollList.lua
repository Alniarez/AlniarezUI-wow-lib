-- AlniarezUI/Tests/ScrollList.lua

local _, ns = ...
local T, A, Lib = ns.T, ns.A, ns.Lib

local COLUMNS = {
    { width = 150 },
    { width = 60, justify = "RIGHT" },
}

local function NewParent()
    local p = CreateFrame("Frame", nil, ns.sandbox)
    p:SetSize(300, 200)
    p:SetPoint("CENTER")
    return p
end

-- Rows are only laid out on a visible frame, so render tests use a shown
-- but fully transparent host. Tests hide it when they finish.
local function NewVisibleHost()
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(300, 200)
    f:SetPoint("CENTER")
    f:SetAlpha(0)
    f:Show()
    return f
end

-- Returns { [row] = data } for the rows currently showing data
local function Rows(list)
    local found, count = {}, 0
    list:ForEachRow(function(row, data)
        found[row] = data
        count = count + 1
    end)
    return found, count
end

T:Describe("CreateScrollList", function()

    local function New(parent, opts)
        opts = opts or {}
        opts.columns = opts.columns or COLUMNS
        return Lib:CreateScrollList(parent or NewParent(), opts)
    end

    T:It("uses a ScrollBox with a modern scroll bar", function()
        local list = New()
        A.NotNil(list.SetDataProvider, "list is a ScrollBox")
        A.Type(list.scrollBar, "Frame", "scrollBar")
        A.NotNil(list.scrollBar.SetScrollPercentage, "scrollBar:SetScrollPercentage")
    end)

    T:It("starts empty", function()
        A.Equal(New():GetNumRows(), 0, "rows")
    end)

    T:It("takes initial data", function()
        local list = New(nil, { data = { { "a", 1 }, { "b", 2 }, { "c", 3 } } })
        A.Equal(list:GetNumRows(), 3, "rows")
    end)

    T:It("replaces rows with SetData", function()
        local list = New(nil, { data = { { "a", 1 }, { "b", 2 }, { "c", 3 } } })
        list:SetData({ { "z", 26 } })
        A.Equal(list:GetNumRows(), 1, "rows")
        list:SetData({})
        A.Equal(list:GetNumRows(), 0, "rows after clearing")
    end)

    T:It("anchors TOPLEFT and BOTTOMRIGHT with offsets", function()
        local parent = NewParent()
        local list = New(parent, { x1 = 18, y1 = -62, x2 = -36, y2 = 50 })
        A.Equal(list:GetParent(), parent, "parent")

        local _, relPoint, x, y = ns.FindPoint(list, "TOPLEFT")
        A.Equal(relPoint, "TOPLEFT", "TOPLEFT relativePoint")
        A.Near(x, 18,  "x1")
        A.Near(y, -62, "y1")

        _, relPoint, x, y = ns.FindPoint(list, "BOTTOMRIGHT")
        A.Equal(relPoint, "BOTTOMRIGHT", "BOTTOMRIGHT relativePoint")
        A.Near(x, -36, "x2")
        A.Near(y, 50,  "y2")
    end)

    T:ItAsync("renders column text and reuses rows", 3, function(t)
        local host = NewVisibleHost()
        local list = New(host, { data = { { "Wolf", 12 }, { "Boar", 7 } } })
        local firstRows

        t:After(0.1, function()
            local rows, count = Rows(list)
            A.Equal(count, 2, "rows shown")
            for row, data in pairs(rows) do
                A.Equal(#row.cols, 2, "columns per row")
                A.Equal(row.cols[1]:GetText(), data[1], "column 1")
                A.Equal(row.cols[2]:GetText(), tostring(data[2]), "column 2")
            end
            firstRows = rows
            list:SetData({ { "Murloc", 3 } })
        end)

        t:After(0.2, function()
            local rows, count = Rows(list)
            A.Equal(count, 1, "rows shown after SetData")
            local row = next(rows)
            A.Equal(row.cols[1]:GetText(), "Murloc", "column 1 after SetData")
            A.NotNil(firstRows[row], "row frame was reused")
            host:Hide()
            t:Done()
        end)
    end)

    T:ItAsync("calls onRowInit with row and data", 3, function(t)
        local host = NewVisibleHost()
        local seen = {}
        local data = { { "a", 1 }, { "b", 2 } }
        New(host, {
            data      = data,
            onRowInit = function(row, d) seen[d] = row end,
        })

        t:After(0.1, function()
            A.NotNil(seen[data[1]], "onRowInit for row 1")
            A.NotNil(seen[data[2]], "onRowInit for row 2")
            A.NotNil(seen[data[1]].cols, "row.cols is set before onRowInit")
            host:Hide()
            t:Done()
        end)
    end)

    T:ItAsync("shows plain values as single-column rows", 3, function(t)
        local host = NewVisibleHost()
        local list = New(host, { data = { "only" } })

        t:After(0.1, function()
            local row = next((Rows(list)))
            A.NotNil(row, "row")
            A.Equal(row.cols[1]:GetText(), "only", "column 1")
            -- SetText("") makes GetText() return nil on some clients
            A.Equal(row.cols[2]:GetText() or "", "", "column 2")
            host:Hide()
            t:Done()
        end)
    end)
end)
