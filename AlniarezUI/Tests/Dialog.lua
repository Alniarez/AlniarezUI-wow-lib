-- AlniarezUI/Tests/Dialog.lua

local _, ns = ...
local T, A, Lib = ns.T, ns.A, ns.Lib

local STANDARD_EDGE = "Interface\\DialogFrame\\UI-DialogBox-Border"
local GOLD_EDGE     = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border"

-- the highest frame level used by `frame` or anything inside it
local function TopLevelIn(frame)
    local top = frame:GetFrameLevel()
    for i = 1, select("#", frame:GetChildren()) do
        top = math.max(top, TopLevelIn((select(i, frame:GetChildren()))))
    end
    return top
end

-- Describes everything a theme sets on a titled, resizable dialog, one
-- string per part, so two dialogs can be compared part by part
local function ThemeState(f)
    local function Name(region)
        if region == f then return "frame" end
        if region == f.titleHeader then return "header" end
        if f.titleBanner and region == f.titleBanner.left  then return "bannerLeft" end
        if f.titleBanner and region == f.titleBanner.right then return "bannerRight" end
        if region == nil then return "nil" end
        return "other"
    end
    local function Points(region)
        local out = {}
        for i = 1, region:GetNumPoints() do
            local p, rel, relPoint, x, y = region:GetPoint(i)
            table.insert(out, string.format("%s>%s.%s(%.1f,%.1f)", p, Name(rel), relPoint, x, y))
        end
        return table.concat(out, " ")
    end
    local function Shown(region)
        return tostring(region ~= nil and region:IsShown())
    end

    local backdrop = f:GetBackdrop()
    local borders = 0
    for _, b in pairs(f.alnBorders or {}) do
        if b:IsShown() then borders = borders + 1 end
    end
    local drag = f.dragHandle

    return {
        theme        = f:GetTheme(),
        backdrop     = backdrop and backdrop.edgeFile or "none",
        border       = Shown(f.border),
        bordersShown = tostring(borders),
        -- a hidden banner keeps its last texture, which does not matter
        banner       = f.titleBanner:IsShown() and tostring(f.titleBanner:GetTexture()) or "hidden",
        bannerCaps   = Shown(f.titleBanner.left) .. " " .. Shown(f.titleBanner.right),
        bannerWidth  = f.titleBanner:IsShown() and string.format("%.1f", f.titleBanner:GetWidth()) or "hidden",
        header       = Shown(f.titleHeader),
        titleParent  = Name(f.titleText:GetParent()),
        titlePoints  = Points(f.titleText),
        close        = Points(f.closeButton),
        grip         = Points(f.resizeButton),
        drag         = Points(drag),
        dragSize     = string.format("%.1fx%.1f", drag:GetWidth(), drag:GetHeight()),
    }
end

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

    T:It("comes to the front when shown", function()
        local f = Lib:CreateDialog({ parent = ns.sandbox, title = "Hello" })
        A.Equal(type(f.BringToFront), "function", "BringToFront")
        A.NotNil(f:GetScript("OnShow"), "OnShow brings it to the front")
    end)

    T:It("catches clicks on its background", function()
        A.True(Lib:CreateDialog({ parent = ns.sandbox, title = "Hello" }):IsMouseEnabled(), "titled")
        A.True(Lib:CreateDialog({ parent = ns.sandbox }):IsMouseEnabled(), "untitled")
    end)

    T:It("draws above everything on another dialog after BringToFront", function()
        local a = Lib:CreateDialog({ parent = ns.sandbox, strata = "DIALOG", title = "A", resizable = true })
        local b = Lib:CreateDialog({ parent = ns.sandbox, strata = "DIALOG", title = "B", resizable = true })
        a:Show()
        b:Show()

        a:BringToFront()
        A.True(a:GetFrameLevel() > TopLevelIn(b), "A above all of B")
        b:BringToFront()
        A.True(b:GetFrameLevel() > TopLevelIn(a), "B above all of A")

        -- widgets keep their place on their own dialog
        A.True(b.closeButton:GetFrameLevel() > b:GetFrameLevel(), "B's close button above B")
        A.True(b.resizeButton:GetFrameLevel() >= b:GetFrameLevel() + 10, "B's grip keeps its +10")
        a:Hide()
        b:Hide()
    end)

    T:It("keeps the close button above everything on its dialog", function()
        -- the highest level used on `f` by anything but the close button
        local function TopWithoutClose(f)
            local top = f:GetFrameLevel()
            for i = 1, select("#", f:GetChildren()) do
                local child = select(i, f:GetChildren())
                if child ~= f.closeButton then top = math.max(top, TopLevelIn(child)) end
            end
            return top
        end

        local other = Lib:CreateDialog({ parent = ns.sandbox, strata = "DIALOG", title = "Other" })
        other:Show()
        for _, name in ipairs(Lib:GetThemes()) do
            local f = Lib:CreateDialog({ parent = ns.sandbox, strata = "DIALOG", title = "Hello",
                resizable = true, theme = name })
            A.True(f.closeButton:GetFrameLevel() > TopWithoutClose(f), name .. ": on creation")

            f:Show()
            other:BringToFront()
            f:BringToFront()
            A.True(f.closeButton:GetFrameLevel() > TopWithoutClose(f), name .. ": after restacking")
            f:Hide()
        end
        other:Hide()
    end)

    T:It("brings a dialog to the front when shown", function()
        -- OnShow only fires for frames that become visible, which nothing
        -- in the hidden sandbox does; this host is visible but see-through
        local host = CreateFrame("Frame", nil, UIParent)
        host:SetAllPoints()
        host:SetAlpha(0)
        local a = Lib:CreateDialog({ parent = host, strata = "DIALOG", title = "A" })
        local b = Lib:CreateDialog({ parent = host, strata = "DIALOG", title = "B" })
        b:Show()
        a:Show()
        local ok = a:GetFrameLevel() > TopLevelIn(b)
        a:Hide()
        b:Hide()
        host:Hide()
        A.True(ok, "A shown last, on top")
    end)

    T:It("keeps frame levels low however often dialogs swap", function()
        local a = Lib:CreateDialog({ parent = ns.sandbox, strata = "DIALOG", title = "A" })
        local b = Lib:CreateDialog({ parent = ns.sandbox, strata = "DIALOG", title = "B" })
        a:Show()
        b:Show()
        a:BringToFront()
        b:BringToFront()
        local after2 = math.max(TopLevelIn(a), TopLevelIn(b))
        for _ = 1, 50 do
            a:BringToFront()
            b:BringToFront()
        end
        A.Equal(math.max(TopLevelIn(a), TopLevelIn(b)), after2, "highest level after 100 more swaps")
        a:Hide()
        b:Hide()
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
        -- the template themes only show on clients that have the templates
        local expected = {}
        for _, name in ipairs({ "basic", "gold", "modern", "panel", "standard", "tooltip" }) do
            if Lib:HasTheme(name) then table.insert(expected, name) end
        end
        local names = Lib:GetThemes()
        A.Equal(#names, #expected, "number of themes")
        for i, name in ipairs(expected) do
            A.Equal(names[i], name, "theme " .. i)
        end
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

    T:It("uses Blizzard's dialog backdrop in the backdrop themes", function()
        for _, name in ipairs({ "gold", "standard" }) do
            local b = Lib:CreateDialog({ parent = ns.sandbox, theme = name }):GetBackdrop()
            A.Equal(b.edgeSize, 32, name .. " edgeSize")
            A.True(b.tile, name .. " tile")
            A.Equal(b.tileSize, 32, name .. " tileSize")
            A.Equal(b.insets.left,   11, name .. " left inset")
            A.Equal(b.insets.right,  12, name .. " right inset")
            A.Equal(b.insets.top,    12, name .. " top inset")
            A.Equal(b.insets.bottom, 11, name .. " bottom inset")
        end
    end)

    T:It("knows its themes with HasTheme", function()
        A.True(Lib:HasTheme("gold"),     "gold")
        A.True(Lib:HasTheme("standard"), "standard")
        A.False(Lib:HasTheme("nope"),    "unknown")
    end)

    T:It("falls back to standard without the modern templates", function()
        if Lib:HasTheme("modern") then return end
        local f = Lib:CreateDialog({ parent = ns.sandbox, theme = "modern" })
        A.Equal(f:GetTheme(), "standard", "theme")
        A.Equal(f:GetBackdrop().edgeFile, STANDARD_EDGE, "edgeFile")
    end)

    T:It("draws the modern theme with Blizzard's dialog templates", function()
        if not Lib:HasTheme("modern") then return end
        local f = Lib:CreateDialog({ parent = ns.sandbox, theme = "modern", title = "Hello" })
        A.Equal(f:GetTheme(), "modern", "theme")
        A.Nil(f:GetBackdrop(), "backdrop")
        A.Type(f.border, "Frame", "border")
        A.True(f.border:IsShown(), "border shown")
        A.Type(f.titleHeader, "Frame", "titleHeader")
        A.True(f.titleHeader:IsShown(), "header shown")
        A.False(f.titleBanner:IsShown(), "banner shown")
        A.Equal(f.titleText:GetParent(), f.titleHeader, "title parent")
        A.Equal(f.titleText:GetText(), "Hello", "title text")
        A.True(f.titleHeader:GetWidth() > f.titleText:GetStringWidth(), "header fits the title")
    end)

    T:It("switches between modern and backdrop themes", function()
        if not Lib:HasTheme("modern") then return end
        local f = Lib:CreateDialog({ parent = ns.sandbox, theme = "gold", title = "Hello" })
        f:SetTheme("modern")
        local border, header = f.border, f.titleHeader

        f:SetTheme("standard")
        A.Equal(f:GetBackdrop().edgeFile, STANDARD_EDGE, "edgeFile")
        A.False(border:IsShown(), "border shown")
        A.False(header:IsShown(), "header shown")
        A.True(f.titleBanner:IsShown(), "banner shown")
        A.Equal(f.titleText:GetParent(), f, "title parent")

        f:SetTheme("modern")
        A.Equal(f.border, border, "border reused")
        A.Equal(f.titleHeader, header, "header reused")
        A.True(border:IsShown(), "border shown again")
    end)

    T:It("drags from the header in the modern theme", function()
        if not Lib:HasTheme("modern") then return end
        local f = Lib:CreateDialog({ parent = ns.sandbox, theme = "modern", title = "Hello" })
        local rel, relPoint = ns.FindPoint(f.dragHandle, "TOPLEFT")
        A.Equal(rel, f.titleHeader, "drag handle relativeTo")
        A.Equal(relPoint, "TOPLEFT", "drag handle relativePoint")
        A.Equal(f.dragHandle:GetNumPoints(), 2, "drag handle anchors")
    end)

    T:It("places the close button per theme", function()
        local f = Lib:CreateDialog({ parent = ns.sandbox })
        local _, _, x, y = ns.FindPoint(f.closeButton, "TOPRIGHT")
        A.Near(x, -10, "standard x")
        A.Near(y, -10, "standard y")
        if not Lib:HasTheme("modern") then return end
        f:SetTheme("modern")
        A.Equal(f.closeButton:GetNumPoints(), 1, "number of anchors")
        _, _, x, y = ns.FindPoint(f.closeButton, "TOPRIGHT")
        A.Near(x, -2, "modern x")
        A.Near(y, -2, "modern y")
    end)

    T:It("switches to modern without a title", function()
        if not Lib:HasTheme("modern") then return end
        local f = Lib:CreateDialog({ parent = ns.sandbox })
        f:SetTheme("modern")
        A.True(f.border:IsShown(), "border shown")
        A.Nil(f.titleHeader, "titleHeader")
    end)

    T:It("draws the tooltip theme with Blizzard's tooltip border", function()
        if not Lib:HasTheme("tooltip") then return end
        local f = Lib:CreateDialog({ parent = ns.sandbox, theme = "tooltip", title = "Hello" })
        A.Equal(f:GetTheme(), "tooltip", "theme")
        A.Nil(f:GetBackdrop(), "backdrop")
        A.Type(f.border, "Frame", "border")
        A.True(f.border:IsShown(), "border shown")
        A.Equal(f.border:GetFrameLevel(), f:GetFrameLevel(), "border level (so it stays behind the title)")
        A.False(f.titleBanner:IsShown(), "banner shown")
        A.Nil(f.titleHeader, "titleHeader")
        A.Equal(f.titleText:GetParent(), f, "title parent")
        local _, _, _, y = ns.FindPoint(f.titleText, "TOP")
        A.True(y < 0, "title inside the frame")
        local rel, _, x
        rel, _, x, y = ns.FindPoint(f.dragHandle, "TOPLEFT")
        A.Equal(rel, f, "drag strip relativeTo")
        A.Near(x, 0, "drag strip left")
        A.Near(y, 0, "drag strip top")
        _, _, x = ns.FindPoint(f.dragHandle, "TOPRIGHT")
        A.Near(x, -24, "drag strip stops short of the close button")
        A.Near(f.dragHandle:GetHeight(), 28, "drag strip height")
    end)

    T:It("draws the basic theme with BasicFrameTemplate", function()
        if not Lib:HasTheme("basic") then return end
        local f = Lib:CreateDialog({ parent = ns.sandbox, theme = "basic", title = "Hello" })
        A.Equal(f:GetTheme(), "basic", "theme")
        A.Nil(f:GetBackdrop(), "backdrop")
        A.Type(f.border, "Frame", "border")
        A.True(f.border:IsShown(), "border shown")
        A.Equal(f.border:GetFrameLevel(), f:GetFrameLevel(), "border level (so it stays behind the title)")
        A.False(f.border.CloseButton:IsShown(), "the template's own close button hidden")
        A.True(f.closeButton:IsShown(), "the dialog's close button shown")
        A.False(f.titleBanner:IsShown(), "banner shown")
        A.Equal(f.titleText:GetParent(), f, "title parent")
        A.Equal(f.titleText:GetFontObject(), GameFontNormal, "title font")
        local rel, _, x, y = ns.FindPoint(f.titleText, "TOP")
        local ownRel, _, ownX, ownY = ns.FindPoint(f.border.TitleText, "TOP")
        A.Equal(rel, ownRel or f.border, "title relativeTo, as the template's TitleText")
        A.Near(x, ownX, "title x, as the template's TitleText")
        A.Near(y, ownY, "title y, as the template's TitleText")
        _, _, x, y = ns.FindPoint(f.closeButton, "TOPRIGHT")
        A.Near(x, 1, "close x, as UIPanelCloseButtonDefaultAnchors")
        A.Near(y, 0, "close y, as UIPanelCloseButtonDefaultAnchors")
    end)

    T:It("draws the panel theme with DefaultPanelTemplate", function()
        if not Lib:HasTheme("panel") then return end
        local f = Lib:CreateDialog({ parent = ns.sandbox, theme = "panel", title = "Hello" })
        A.Equal(f:GetTheme(), "panel", "theme")
        A.Nil(f:GetBackdrop(), "backdrop")
        A.Type(f.border, "Frame", "border")
        A.True(f.border:IsShown(), "border shown")
        A.Equal(f.border:GetFrameLevel(), f:GetFrameLevel(), "border level")
        -- at the frame's level, so they stay behind the title and keep
        -- TitleContainer's level 510 out of the stacking
        A.Equal(f.border.NineSlice:GetFrameLevel(), f:GetFrameLevel(), "NineSlice level")
        A.Equal(f.border.TitleContainer:GetFrameLevel(), f:GetFrameLevel(), "TitleContainer level")
        local own = f.border.TitleContainer.TitleText
        A.False(own:IsShown(), "the template's own title hidden")
        A.True(f.closeButton:GetFrameLevel() < f:GetFrameLevel() + 100, "close button level stays small")
        A.Equal(f.titleText:GetParent(), f, "title parent")
        A.Equal(f.titleText:GetFontObject(), own:GetFontObject(), "title font")
        local rel, _, x, y = ns.FindPoint(f.titleText, "TOP")
        local ownRel, _, ownX, ownY = ns.FindPoint(own, "TOP")
        A.Equal(rel, ownRel or f.border.TitleContainer, "title placed in the template's title bar")
        A.Near(x, ownX, "title x, as the template's TitleText")
        A.Near(y, ownY, "title y, as the template's TitleText")
        _, _, x, y = ns.FindPoint(f.closeButton, "TOPRIGHT")
        A.Near(x, 1, "close x")
        A.Near(y, 0, "close y")
    end)

    T:It("sets the title font only when the theme changes", function()
        if not Lib:HasTheme("basic") then return end
        local f = Lib:CreateDialog({ parent = ns.sandbox, theme = "basic", title = "Hello" })
        f.titleText:SetFontObject(GameFontHighlight)
        f:SetTheme("basic")
        A.Equal(f.titleText:GetFontObject(), GameFontHighlight, "a hand-set font survives the same theme")
        f:SetTheme("gold")
        A.Equal(f.titleText:GetFontObject(), GameFontNormalLarge, "gold's font")
    end)

    T:It("overhangs the close button in the tooltip theme", function()
        if not Lib:HasTheme("tooltip") then return end
        local f = Lib:CreateDialog({ parent = ns.sandbox, theme = "tooltip" })
        local _, _, x, y = ns.FindPoint(f.closeButton, "TOPRIGHT")
        A.Near(x, 2, "x")
        A.Near(y, 2, "y")
    end)

    T:It("keeps one border per template when switching", function()
        if not (Lib:HasTheme("tooltip") and Lib:HasTheme("modern")) then return end
        local f = Lib:CreateDialog({ parent = ns.sandbox, theme = "tooltip", title = "Hello" })
        local tooltipBorder = f.border
        f:SetTheme("modern")
        A.True(f.border ~= tooltipBorder, "modern has its own border")
        A.False(tooltipBorder:IsShown(), "tooltip border hidden")
        A.True(f.titleHeader:IsShown(), "header shown")

        f:SetTheme("tooltip")
        A.Equal(f.border, tooltipBorder, "tooltip border reused")
        A.False(f.titleHeader:IsShown(), "header hidden")
        A.Equal(f.titleText:GetParent(), f, "title parent")

        f:SetTheme("gold")
        A.Nil(f.border, "border in a backdrop theme")
        A.False(tooltipBorder:IsShown(), "tooltip border hidden in gold")
        A.Equal((ns.FindPoint(f.dragHandle, "TOPLEFT")), f.titleBanner.left, "drag handle back on the banner")
        A.Equal(f.dragHandle:GetNumPoints(), 2, "drag handle anchors")
    end)

    T:It("matches a fresh dialog after every theme switch", function()
        local themes = Lib:GetThemes()
        local opts = { parent = ns.sandbox, title = "Hello", resizable = true }
        local function New(theme)
            local o = {}
            for k, v in pairs(opts) do o[k] = v end
            o.theme = theme
            return Lib:CreateDialog(o)
        end

        local fresh = {}
        for _, name in ipairs(themes) do fresh[name] = ThemeState(New(name)) end

        for _, from in ipairs(themes) do
            for _, to in ipairs(themes) do
                if from ~= to then
                    local f = New(from)
                    f:SetTheme(to)
                    for part, want in pairs(fresh[to]) do
                        A.Equal(ThemeState(f)[part], want, from .. " -> " .. to .. ": " .. part)
                    end
                end
            end
        end
    end)

    T:It("matches a fresh dialog after a round trip through every theme", function()
        local themes = Lib:GetThemes()
        local start = themes[1]
        local f = Lib:CreateDialog({ parent = ns.sandbox, title = "Hello", resizable = true, theme = start })
        local want = ThemeState(f)
        for _, name in ipairs(themes) do f:SetTheme(name) end
        f:SetTheme(start)
        for part, value in pairs(want) do
            A.Equal(ThemeState(f)[part], value, "back to " .. start .. ": " .. part)
        end
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
        A.Type(f.titleBanner.left,  "Texture", "banner left cap")
        A.Type(f.titleBanner.right, "Texture", "banner right cap")
        A.Equal(f.titleText:GetText(), "Hello", "title text")
    end)

    T:It("fits the banner to the title", function()
        local short = Lib:CreateDialog({ parent = ns.sandbox, title = "Hi" })
        local long  = Lib:CreateDialog({ parent = ns.sandbox, title = "A much longer dialog title" })
        A.Near(short.titleBanner:GetWidth(), short.titleText:GetStringWidth() + 10, "short middle")
        A.Near(long.titleBanner:GetWidth(),  long.titleText:GetStringWidth() + 10,  "long middle")
        A.True(long.titleBanner:GetWidth() > short.titleBanner:GetWidth(), "longer title, wider banner")
        A.Near(long.titleBanner.left:GetWidth(), 30, "caps keep their size")
    end)

    T:It("applies titleWidth to the whole banner", function()
        local f = Lib:CreateDialog({ parent = ns.sandbox, title = "Hello", titleWidth = 300 })
        -- two 30 wide caps around the middle
        A.Near(f.titleBanner:GetWidth(), 240, "middle width")
    end)

    T:It("drags from the whole banner, caps included", function()
        local f = Lib:CreateDialog({ parent = ns.sandbox, title = "Hello" })
        local rel, relPoint = ns.FindPoint(f.dragHandle, "TOPLEFT")
        A.Equal(rel, f.titleBanner.left, "TOPLEFT relativeTo")
        A.Equal(relPoint, "TOPLEFT", "TOPLEFT relativePoint")
        rel, relPoint = ns.FindPoint(f.dragHandle, "BOTTOMRIGHT")
        A.Equal(rel, f.titleBanner.right, "BOTTOMRIGHT relativeTo")
        A.Equal(relPoint, "BOTTOMRIGHT", "BOTTOMRIGHT relativePoint")
    end)

    T:It("hides the banner caps with the banner", function()
        if not Lib:HasTheme("tooltip") then return end
        local f = Lib:CreateDialog({ parent = ns.sandbox, title = "Hello", theme = "tooltip" })
        A.False(f.titleBanner:IsShown(),       "middle")
        A.False(f.titleBanner.left:IsShown(),  "left cap")
        A.False(f.titleBanner.right:IsShown(), "right cap")
    end)

    T:It("fits the modern header to titleWidth when given", function()
        if not Lib:HasTheme("modern") then return end
        local f = Lib:CreateDialog({ parent = ns.sandbox, title = "Hello", titleWidth = 300, theme = "modern" })
        A.Near(f.titleHeader:GetWidth(), 300, "header width")
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

--------------------------------------------------
-- Long titles
--------------------------------------------------

local LONG_TITLE = string.rep("A really very long dialog title ", 8)

-- Width of what the theme draws for the title: the banner with its caps,
-- the header, or the text itself
local function TitleArtWidth(f)
    if f.titleBanner:IsShown() then
        return f.titleBanner:GetWidth() + f.titleBanner.left:GetWidth() + f.titleBanner.right:GetWidth()
    end
    if f.titleHeader and f.titleHeader:IsShown() then return f.titleHeader:GetWidth() end
    local w = f.titleText:GetWidth()
    if w == 0 then w = f.titleText:GetStringWidth() end
    return w
end

-- The x where the close button starts, measured from the frame's left edge
local function CloseButtonLeft(f)
    local _, _, x = ns.FindPoint(f.closeButton, "TOPRIGHT")
    return f:GetWidth() + x - f.closeButton:GetWidth()
end

-- Calls the frame's OnSizeChanged the way the client does after a resize
local function Resize(f, w)
    f:SetWidth(w)
    f:GetScript("OnSizeChanged")(f, w, f:GetHeight())
end

T:Describe("CreateDialog long titles", function()

    T:It("leaves a short title whole", function()
        local f = Lib:CreateDialog({ parent = ns.sandbox, title = "Hello" })
        A.False(f:IsTitleTruncated(), "IsTitleTruncated")
        A.Nil(f.dragHandle.alnTooltip.title(f.dragHandle), "no hover tooltip")
    end)

    T:It("keeps a long title clear of the close button in every theme", function()
        for _, name in ipairs(Lib:GetThemes()) do
            local f = Lib:CreateDialog({ parent = ns.sandbox, title = LONG_TITLE, width = 400, theme = name })
            A.True(f:IsTitleTruncated(), name .. ": IsTitleTruncated")
            local art = TitleArtWidth(f)
            -- the art is centered, so its right edge is half of it past the middle
            local right = f:GetWidth() / 2 + art / 2
            A.True(right <= CloseButtonLeft(f),
                name .. ": title ends at " .. right .. ", close button starts at " .. CloseButtonLeft(f))
            A.True(art > 0, name .. ": title still shows")
        end
    end)

    T:It("keeps a too large titleWidth clear of the close button", function()
        for _, name in ipairs(Lib:GetThemes()) do
            local f = Lib:CreateDialog({ parent = ns.sandbox, title = "Hello", titleWidth = 2000, width = 400, theme = name })
            local right = f:GetWidth() / 2 + TitleArtWidth(f) / 2
            A.True(right <= CloseButtonLeft(f), name .. ": title art ends before the close button")
        end
    end)

    T:It("cuts the text, not the title", function()
        local f = Lib:CreateDialog({ parent = ns.sandbox, title = LONG_TITLE, width = 400 })
        A.Equal(f.titleText:GetText(), LONG_TITLE, "GetText keeps the full title")
        A.True(f.titleText:GetWidth() > 0, "text has a width to cut at")
        A.True(f.titleText:GetWidth() <= f.titleBanner:GetWidth(), "text fits in the banner middle")
    end)

    T:It("shows the full title on hover when cut off", function()
        local f = Lib:CreateDialog({ parent = ns.sandbox, title = LONG_TITLE, width = 400 })
        A.Equal(f.dragHandle.alnTooltip.title(f.dragHandle), LONG_TITLE, "hover tooltip")
    end)

    T:It("refits the title when the frame resizes", function()
        local title = string.rep("Medium title ", 4)
        local f = Lib:CreateDialog({ parent = ns.sandbox, title = title, width = 250 })
        A.True(f:IsTitleTruncated(), "cut off at 250")
        local narrow = TitleArtWidth(f)

        Resize(f, 1200)
        A.False(f:IsTitleTruncated(), "whole at 1200")
        A.True(TitleArtWidth(f) > narrow, "banner grew")
        A.Nil(f.dragHandle.alnTooltip.title(f.dragHandle), "no hover tooltip when whole")

        Resize(f, 250)
        A.True(f:IsTitleTruncated(), "cut off again at 250")
        A.Near(TitleArtWidth(f), narrow, "banner back to its narrow width")
    end)

    T:It("keeps the title fit through theme switches", function()
        local f = Lib:CreateDialog({ parent = ns.sandbox, title = LONG_TITLE, width = 400 })
        for _, name in ipairs(Lib:GetThemes()) do
            f:SetTheme(name)
            A.True(f:IsTitleTruncated(), name .. ": IsTitleTruncated")
            local right = f:GetWidth() / 2 + TitleArtWidth(f) / 2
            A.True(right <= CloseButtonLeft(f), name .. ": title ends before the close button")
        end
    end)

    T:It("keeps a long title inside a frame without a close button", function()
        local f = Lib:CreateDialog({ parent = ns.sandbox, title = LONG_TITLE, width = 400, noCloseButton = true })
        A.True(f:IsTitleTruncated(), "IsTitleTruncated")
        A.True(TitleArtWidth(f) <= f:GetWidth(), "title art inside the frame")
    end)
end)
