-- AlniarezUI/Tests/Resize.lua
-- Dragging the grip needs a real mouse, so these check the setup and call
-- the grip's mouse-up handler directly. Try the drag itself in the demo.

local _, ns = ...
local T, A, Lib = ns.T, ns.A, ns.Lib

local function New(opts)
    opts = opts or {}
    opts.parent = opts.parent or ns.sandbox
    return Lib:CreateDialog(opts)
end

-- Returns minW, minH, maxW, maxH from whichever API the client has
local function Bounds(f)
    if f.GetResizeBounds then return f:GetResizeBounds() end
    local minW, minH = f:GetMinResize()
    local maxW, maxH = f:GetMaxResize()
    return minW, minH, maxW, maxH
end

T:Describe("Dialog resizing", function()

    T:It("is off by default", function()
        local f = New()
        A.False(f:IsResizeEnabled(), "IsResizeEnabled")
        A.False(f:IsResizable(), "IsResizable")
        A.Nil(f.resizeButton, "resizeButton")
    end)

    T:It("turns on with resizable = true", function()
        local f = New({ resizable = true })
        A.True(f:IsResizeEnabled(), "IsResizeEnabled")
        A.True(f:IsResizable(), "IsResizable")
    end)

    T:It("shows a grip in the bottom-right corner", function()
        local f = New({ resizable = true })
        local grip = f.resizeButton
        A.Type(grip, "Button", "resizeButton")
        A.True(grip:IsShown(), "grip shown")
        A.Near(grip:GetWidth(), 16, "grip width")
        local rel, relPoint = ns.FindPoint(grip, "BOTTOMRIGHT")
        A.Equal(rel, f, "grip relativeTo")
        A.Equal(relPoint, "BOTTOMRIGHT", "grip relativePoint")
    end)

    T:It("uses the chat window grip textures", function()
        local grip = New({ resizable = true }).resizeButton
        A.NotNil(grip:GetNormalTexture(),    "normal texture")
        A.NotNil(grip:GetPushedTexture(),    "pushed texture")
        A.NotNil(grip:GetHighlightTexture(), "highlight texture")
    end)

    T:It("draws the grip above the frame's content", function()
        local f = New({ resizable = true })
        A.True(f.resizeButton:GetFrameLevel() > f:GetFrameLevel(), "grip frame level")
    end)

    T:It("applies min and max bounds", function()
        local f = New({ resizable = true, minWidth = 300, minHeight = 200, maxWidth = 800, maxHeight = 600 })
        local minW, minH, maxW, maxH = Bounds(f)
        A.Near(minW, 300, "min width")
        A.Near(minH, 200, "min height")
        A.Near(maxW, 800, "max width")
        A.Near(maxH, 600, "max height")
    end)

    T:It("keeps the title banner inside the default min width", function()
        local minW = Bounds(New({ resizable = true, title = "Hi", titleWidth = 300 }))
        A.True(minW >= 340, "min width (" .. tostring(minW) .. ") fits the 300 wide banner")
    end)

    T:It("uses at least 200x150 as the default minimum", function()
        local minW, minH = Bounds(New({ resizable = true }))
        A.Near(minW, 200, "min width")
        A.Near(minH, 150, "min height")
    end)

    T:It("turns off and on with SetResizeEnabled", function()
        local f = New({ resizable = true })
        f:SetResizeEnabled(false)
        A.False(f:IsResizeEnabled(), "enabled after turning off")
        A.False(f.resizeButton:IsShown(), "grip shown after turning off")
        f:SetResizeEnabled(true)
        A.True(f:IsResizeEnabled(), "enabled after turning on")
        A.True(f.resizeButton:IsShown(), "grip shown after turning on")
    end)

    T:It("creates the grip when turned on later", function()
        local f = New({ minWidth = 250 })
        f:SetResizeEnabled(true)
        A.Type(f.resizeButton, "Button", "resizeButton")
        A.Near((Bounds(f)), 250, "min width")
    end)

    T:It("calls onResize with the size when the grip is released", function()
        local calls, gotW, gotH = 0, nil, nil
        local f = New({
            resizable = true,
            onResize  = function(w, h) calls = calls + 1; gotW, gotH = w, h end,
        })
        f:SetSize(420, 330)
        f.resizeButton:GetScript("OnMouseUp")(f.resizeButton, "LeftButton")
        A.Equal(calls, 1, "onResize calls")
        A.Near(gotW, 420, "width")
        A.Near(gotH, 330, "height")
    end)

    T:It("does not error on release without onResize", function()
        local f = New({ resizable = true })
        f.resizeButton:GetScript("OnMouseUp")(f.resizeButton, "LeftButton")
    end)

    T:It("keeps SetClampedSize within the bounds", function()
        local f = New({ minWidth = 300, minHeight = 200, maxWidth = 800, maxHeight = 600 })
        f:SetClampedSize(100, 50)
        A.Near(f:GetWidth(),  300, "width clamped to min")
        A.Near(f:GetHeight(), 200, "height clamped to min")
        f:SetClampedSize(5000, 5000)
        A.Near(f:GetWidth(),  800, "width clamped to max")
        A.Near(f:GetHeight(), 600, "height clamped to max")
        f:SetClampedSize(500, 400)
        A.Near(f:GetWidth(),  500, "width in range")
        A.Near(f:GetHeight(), 400, "height in range")
    end)
end)
