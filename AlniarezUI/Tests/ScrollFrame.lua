-- AlniarezUI/Tests/ScrollFrame.lua

local _, ns = ...
local T, A, Lib = ns.T, ns.A, ns.Lib

local function NewParent()
    local p = CreateFrame("Frame", nil, ns.sandbox)
    p:SetSize(400, 300)
    return p
end

T:Describe("CreateScrollFrame", function()

    T:It("returns a ScrollFrame and its content child", function()
        local scroll, content = Lib:CreateScrollFrame(NewParent())
        A.Type(scroll,  "ScrollFrame", "scroll")
        A.Type(content, "Frame",       "content")
        A.Equal(scroll:GetScrollChild(), content, "scroll child")
        A.Equal(content:GetParent(), scroll, "content parent")
    end)

    -- the old UIPanelScrollFrameTemplate bar is a Slider. The modern one is
    -- a MinimalScrollBar, which reports itself as a plain "Frame"
    T:It("uses the modern scroll bar", function()
        local bar = Lib:CreateScrollFrame(NewParent()).ScrollBar
        A.Type(bar, "Frame", "ScrollBar")
        A.NotNil(bar.SetScrollPercentage, "ScrollBar:SetScrollPercentage")
    end)

    T:It("places the scroll bar outside the right edge", function()
        local scroll = Lib:CreateScrollFrame(NewParent())
        local rel, relPoint, x = ns.FindPoint(scroll.ScrollBar, "TOPLEFT")
        A.Equal(rel, scroll, "relativeTo")
        A.Equal(relPoint, "TOPRIGHT", "relativePoint")
        A.Near(x, 6, "x")
    end)

    T:It("parents the scroll frame to parent", function()
        local parent = NewParent()
        local scroll = Lib:CreateScrollFrame(parent)
        A.Equal(scroll:GetParent(), parent, "parent")
    end)

    T:It("defaults content size to 0", function()
        local _, content = Lib:CreateScrollFrame(NewParent())
        A.Near(content:GetWidth(),  0, "width")
        A.Near(content:GetHeight(), 0, "height")
    end)

    T:It("applies content size", function()
        local _, content = Lib:CreateScrollFrame(NewParent(), {
            contentWidth = 360, contentHeight = 800,
        })
        A.Near(content:GetWidth(),  360, "width")
        A.Near(content:GetHeight(), 800, "height")
    end)

    T:It("anchors TOPLEFT and BOTTOMRIGHT with offsets", function()
        local scroll = Lib:CreateScrollFrame(NewParent(), {
            x1 = 18, y1 = -62, x2 = -36, y2 = 50,
        })
        local _, relPoint, x, y = ns.FindPoint(scroll, "TOPLEFT")
        A.Equal(relPoint, "TOPLEFT", "TOPLEFT relativePoint")
        A.Near(x, 18,  "x1")
        A.Near(y, -62, "y1")

        _, relPoint, x, y = ns.FindPoint(scroll, "BOTTOMRIGHT")
        A.Equal(relPoint, "BOTTOMRIGHT", "BOTTOMRIGHT relativePoint")
        A.Near(x, -36, "x2")
        A.Near(y, 50,  "y2")
    end)

    T:It("fills the parent with default offsets", function()
        local scroll = Lib:CreateScrollFrame(NewParent())
        local _, _, x1, y1 = ns.FindPoint(scroll, "TOPLEFT")
        local _, _, x2, y2 = ns.FindPoint(scroll, "BOTTOMRIGHT")
        A.Near(x1, 0, "x1")
        A.Near(y1, 0, "y1")
        A.Near(x2, 0, "x2")
        A.Near(y2, 0, "y2")
    end)

    T:It("creates the content child as childType", function()
        local _, content = Lib:CreateScrollFrame(NewParent(), { childType = "Button" })
        A.Type(content, "Button", "content")
    end)
end)
