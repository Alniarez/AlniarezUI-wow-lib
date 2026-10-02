-- AlniarezUI/Learn.lua
-- The "Learn AlnUI" window, the addon's main window (/alnui): one button
-- per topic, grouped by what you want to do (see GROUPS), plus topics
-- about this addon (the Demo, the tests). Each button opens a window
-- with three tabs:
--   About    what it is, everything it can do, and where the Demo shows it
--   Example  a working example to try
--   Code     the code for it, ready to copy
--
-- Adding a topic: add an entry to TOPICS and its key to a group in
-- GROUPS. Tests/Learn.lua checks that
-- every public AlnUI function is explained by at least one topic.

local _, ns = ...
local Lib = ns.Lib

local GOLD = { 1, 0.82, 0 }
local GREY = { 0.7, 0.7, 0.7 }

local TOPIC_WIDTH  = 560
local TOPIC_HEIGHT = 460
local PANEL_X      = 20                          -- tab panels' inset
local PANEL_W      = TOPIC_WIDTH - 2 * PANEL_X

--------------------------------------------------
-- Helpers
--------------------------------------------------

-- Gold heading at (x, y) inside `parent`
local function Heading(parent, text, x, y)
    local fs = Lib:CreateLabel(parent, { text = text, font = "GameFontNormal" })
    fs:SetPoint("TOPLEFT", x, y)
    return fs
end

-- Small grey text at (x, y) inside `parent`
local function Hint(parent, text, x, y, width)
    local fs = Lib:CreateLabel(parent, {
        text = text, font = "GameFontHighlightSmall", color = GREY, width = width,
    })
    fs:SetPoint("TOPLEFT", x, y)
    return fs
end

-- Small dialogs the examples open, made on first use and kept by `key`.
-- They show their size, which updates when the grip is let go.
local samples = {}
local function ShowSample(key, opts)
    local f = samples[key]
    if not f then
        local size
        f = Lib:CreateDialog({
            title     = opts.title or ("A " .. (opts.theme or "standard") .. " dialog"),
            width     = opts.width or 320,
            height    = opts.height or 180,
            theme     = opts.theme,
            strata    = "DIALOG",
            resizable = true,
            onResize  = function(w, h) size:SetText(string.format("Size: %d x %d", w, h)) end,
        })
        -- anchored on both sides, so it rewraps as the window resizes,
        -- with the size line hanging under it
        local hint = Hint(f, opts.hint or "Drag the title to move me, the corner to resize me.", 24, -44)
        hint:SetPoint("TOPRIGHT", -24, -44)
        size = Hint(f, string.format("Size: %d x %d", f:GetWidth(), f:GetHeight()), 0, 0)
        size:ClearAllPoints()
        size:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -12)
        samples[key] = f
    end
    if opts.theme and f:GetTheme() ~= opts.theme then f:SetTheme(opts.theme) end
    if opts.point then
        f:ClearAllPoints()
        f:SetPoint("CENTER", UIParent, "CENTER", opts.point[1], opts.point[2])
    end
    f:Show()
    f:BringToFront()
    return f
end

-- "Theme" and a dropdown of every theme, to the right of `anchor`, for
-- examples that open windows or show toasts. opts:
--   selected     the theme picked at first
--   onChange     onChange(theme) on a pick
--   first        an extra option listed before the themes
--   kind         "toast": only the themes toasts can use
--   tooltipText  replaces the dropdown's tooltip text
-- Returns the dropdown, or nil on clients without one; read it with
-- PickedTheme.
local function ThemePicker(p, anchor, opts)
    if not Lib:HasDropdown() then return nil end
    local options = { opts.first }
    for _, theme in ipairs(Lib:GetThemes(opts.kind)) do
        table.insert(options, { value = theme, label = theme:sub(1, 1):upper() .. theme:sub(2) })
    end

    local label = Lib:CreateLabel(p, { text = "Theme:", font = "GameFontNormal" })
    label:SetPoint("LEFT", anchor, "RIGHT", 16, 0)

    local dropdown = Lib:CreateDropdown(p, {
        width       = 120,
        options     = options,
        selected    = opts.selected,
        onChange    = opts.onChange,
        tooltip     = opts.kind == "toast" and "Toast theme" or "Window theme",
        tooltipText = opts.tooltipText or "Switches the window with frame:SetTheme().",
    })
    dropdown:SetPoint("LEFT", label, "RIGHT", 8, 0)
    return dropdown
end

-- The theme picked in `picker`, or `default` when there is no picker
local function PickedTheme(picker, default)
    return picker and picker:GetValue() or default
end

--------------------------------------------------
-- A real addon's window
--
-- The "Recreating a window" topic's code. Its example runs this same
-- code, so the window you try is exactly the one the Code tab shows.
--------------------------------------------------

local SHOPPING_LIST_CODE = [==[
-- Profession Shopping List's order settings, rebuilt with AlnUI.
-- Each row hangs off the one above it, so when the window gets
-- narrower the text rewraps and everything below moves down.
local settings = {
    knowledge = 85, artisan = 3, bag = 50,
    scope = "Professions", afterReset = false, concentration = false,
}

local f = AlnUI:CreateDialog({
    name      = "AlnUIShoppingList",
    title     = "Profession Shopping List",
    width     = 480,
    height    = 320,
    theme     = "basic",   -- the original is a BasicFrameTemplate frame
    strata    = "DIALOG",
    resizable = true,
    minWidth  = 400,
    minHeight = 320,
    maxWidth  = 800,
    maxHeight = 500,
})

-- anchored on both sides, so it wraps to the window's width
local intro = AlnUI:CreateLabel(f, {
    text = "Set the criteria to track orders. Cost settings only work with: "
        .. "Auctionator, Oribos Exchange, or TradeSkillMaster.",
    font = "GameFontNormal",
})
intro:SetPoint("TOPLEFT", 16, -32)
intro:SetPoint("TOPRIGHT", -16, -32)

-- A gold label under `above` (dx to its left edge), then a numeric
-- box with a gold coin after it. Typing saves settings[key].
local function CostRow(above, dx, text, key)
    local label = AlnUI:CreateLabel(f, { text = text, font = "GameFontNormal" })
    label:SetPoint("TOPLEFT", above, "BOTTOMLEFT", dx, -8)

    local box = AlnUI:CreateEditBox(f, {
        width         = 56,
        numeric       = true,
        maxLetters    = 7,
        text          = tostring(settings[key]),
        onTextChanged = function(v) settings[key] = tonumber(v) or 0 end,
    })
    box:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 8, -4)
    box:SetJustifyH("RIGHT")

    local coin = f:CreateTexture(nil, "ARTWORK")
    coin:SetSize(14, 14)
    coin:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon")
    coin:SetPoint("LEFT", box, "RIGHT", 4, 0)
    box.coin = coin
    return box
end

-- boxes sit 8 right of their label, so the next label is 8 left of the box
local knowledge = CostRow(intro, 0, "Maximum cost per knowledge point:", "knowledge")
local artisan   = CostRow(knowledge, -8, "Maximum cost per artisan currency:", "artisan")
local bag       = CostRow(artisan, -8, "Maximum cost per reward bag:", "bag")

if AlnUI:HasDropdown() then
    AlnUI:CreateDropdown(f, {
        width    = 124,
        options  = { "Professions", "All Items" },
        selected = settings.scope,
        onChange = function(v) settings.scope = v end,
    }):SetPoint("LEFT", knowledge.coin, "RIGHT", 10, 0)
end

local reset = AlnUI:CreateCheckbox(f, {
    label    = "Track orders available after weekly reset",
    checked  = settings.afterReset,
    onChange = function(checked) settings.afterReset = checked end,
})
reset:SetPoint("TOPLEFT", bag, "BOTTOMLEFT", -12, -6)
reset.label:SetFontObject("GameFontNormal")

local heading = AlnUI:CreateLabel(f, {
    text = "Track orders costing concentration:", font = "GameFontNormal",
})
heading:SetPoint("TOPLEFT", reset, "BOTTOMLEFT", 4, -6)

-- you, as Name-Realm in your class color
local name = UnitName("player") .. "-" .. GetNormalizedRealmName()
local c = RAID_CLASS_COLORS[select(2, UnitClass("player"))]
if c then
    name = string.format("|cff%02x%02x%02x%s|r", c.r * 255, c.g * 255, c.b * 255, name)
end

AlnUI:CreateCheckbox(f, {
    label    = name,
    checked  = settings.concentration,
    onChange = function(checked) settings.concentration = checked end,
}):SetPoint("TOPLEFT", heading, "BOTTOMLEFT", -4, -2)


SLASH_SHOPLIST1 = "/shoplist"
SlashCmdList.SHOPLIST = function() f:SetShown(not f:IsShown()) end]==]

--------------------------------------------------
-- Topics
--
-- Each topic:
--   key       string  unique id, also used in the window's global name
--   name      string  button text and window title
--   text      string  what it is, in a few sentences
--   features  table   everything it can do, one line each
--   demo      string  where the Demo window (or this addon) shows it
--   example   func    example(panel) builds the live example
--   code      string  example code. Lua examples are complete: each one
--                     runs on its own in a file loaded after AlnUI
--   lang      string  "text" when the code is not Lua (slash commands,
--                     .toc lines); the tests compile everything else
--------------------------------------------------

local TOPICS = {

    {
        key = "themes", name = "Themes",
        text = "A theme decides how a dialog or toast looks: its border, background and title art. "
            .. "There are six: two classic dialog backdrops that AlnUI draws itself, and four "
            .. "borrowed from Blizzard's own frame templates. Pick one when you create a window "
            .. "and switch whenever you like; toasts take one too.",
        features = {
            "\"gold\" and \"standard\": the classic dialog border with a title banner, the same border size, tiling and insets as Blizzard's dialogs",
            "\"basic\": BasicFrameTemplate's metal frame and title bar, as many addons' settings windows use",
            "\"panel\": DefaultPanelTemplate, the modern version of basic: the Character window's frame without the portrait",
            "\"modern\": the Game Menu's border and header (DialogBorderTemplate, DialogHeaderTemplate)",
            "\"tooltip\": GameTooltip's border, with the title as plain text inside the frame",
            "In basic and panel the title and close button sit exactly where the template puts its own",
            "opts.theme on CreateDialog and ShowToast; frame:SetTheme(name) switches a dialog later, frame:GetTheme() reads it",
            "Switching refits the title and moves the close button and resize grip to suit the theme",
            "AlnUI:GetThemes() lists the themes this client can draw; AlnUI:HasTheme(name) checks one",
            "Toasts: AlnUI:GetThemes(\"toast\") lists their themes; basic and panel are whole windows, so toasts given them use tooltip",
            "Unknown names, and template themes this client lacks, fall back to \"standard\" (dialogs) or \"gold\" (toasts)",
        },
        demo = "The theme dropdown at the bottom of the Demo window switches it live. "
            .. "/alnui demos opens one Demo window per theme, overlapping; /alnui toasts shows "
            .. "every kind of toast in every toast theme.",
        example = function(p)
            local function Label(theme) return theme:sub(1, 1):upper() .. theme:sub(2) end

            -- windows: one small dialog per theme
            Heading(p, "Windows", 0, 0)
            Hint(p, "Open a small dialog in each theme.", 70, -2)
            local themes = Lib:GetThemes()
            local mid = (#themes + 1) / 2
            local function OpenTheme(i, theme)
                ShowSample("theme-" .. theme, {
                    theme = theme,
                    title = Label(theme),
                    point = { (i - mid) * 50, (mid - i) * 36 },
                })
            end
            for i, theme in ipairs(themes) do
                Lib:CreateButton(p, {
                    text    = Label(theme),
                    width   = 80,
                    onClick = function() OpenTheme(i, theme) end,
                }):SetPoint("TOPLEFT", (i - 1) * 86, -20)
            end

            local all = Lib:CreateButton(p, {
                text        = "All at once",
                width       = 120,
                onClick     = function() for i, theme in ipairs(themes) do OpenTheme(i, theme) end end,
                tooltip     = "All at once",
                tooltipText = "One dialog per theme, overlapping, to compare them side by side.",
            })
            all:SetPoint("TOPLEFT", 0, -50)

            -- one dialog switched in place with SetTheme
            local current = 0
            Lib:CreateButton(p, {
                text        = "Switch one window",
                width       = 160,
                onClick     = function()
                    current = current % #themes + 1
                    local f = ShowSample("switch", {
                        hint = "frame:SetTheme() redraws me in place: border, title and close button.",
                    })
                    f.titleText:SetText("Now: " .. Label(themes[current]))
                    f:SetTheme(themes[current])
                end,
                tooltip     = "Switch one window",
                tooltipText = "Each click moves one dialog on to the next theme with frame:SetTheme().",
            }):SetPoint("LEFT", all, "RIGHT", 8, 0)

            Lib:CreateSeparator(p, { y = -86 })

            -- toasts: one per toast theme, and the window-only fallback
            Heading(p, "Toasts", 0, -98)
            Hint(p, "Basic and Panel are whole windows: toasts given them use Tooltip.", 70, -100, PANEL_W - 70)
            local function Toast(theme, text)
                Lib:ShowToast({ title = Label(theme), text = text, theme = theme, duration = 2 })
            end
            local prev
            for i, theme in ipairs(Lib:GetThemes("toast")) do
                local b = Lib:CreateButton(p, {
                    text    = Label(theme),
                    width   = 80,
                    onClick = function() Toast(theme, "A " .. theme .. " toast.") end,
                })
                b:SetPoint("TOPLEFT", (i - 1) * 86, -118)
                prev = b
            end
            if Lib:HasTheme("basic") then
                Lib:CreateButton(p, {
                    text        = "Basic toast",
                    width       = 100,
                    onClick     = function() Toast("basic", "Asked for basic, drawn as tooltip.") end,
                    tooltip     = "Basic toast",
                    tooltipText = "ShowToast({ theme = \"basic\" }) uses the tooltip theme.",
                }):SetPoint("LEFT", prev, "RIGHT", 14, 0)
            end
        end,
        code = [==[
-- One small window per theme this client can draw, overlapping.
local themes = AlnUI:GetThemes()
local mid = (#themes + 1) / 2
for i, theme in ipairs(themes) do
    local f = AlnUI:CreateDialog({
        title  = "Theme: " .. theme,
        theme  = theme,
        width  = 260,
        height = 120,
    })
    -- step each window down and to the right so they do not hide each other
    f:SetPoint("CENTER", (i - mid) * 50, (mid - i) * 36)
    f:Show()
end

-- A theme can also be switched later. Unknown names, and themes this
-- client cannot draw, fall back to "standard".
local w = AlnUI:CreateDialog({ title = "Switching", theme = "gold" })
w:SetTheme(AlnUI:HasTheme("panel") and "panel" or "standard")
print("now drawn with", w:GetTheme())

-- Toasts take a theme too: any from GetThemes("toast"). The window-only
-- "basic" and "panel" draw toasts with "tooltip" instead.
for _, theme in ipairs(AlnUI:GetThemes("toast")) do
    AlnUI:ShowToast({ title = theme, text = "A " .. theme .. " toast.", theme = theme, duration = 2 })
end
AlnUI:ShowToast({ title = "Basic?", text = "Drawn as tooltip.", theme = "basic" })]==],
    },
    {
        key = "dialog", name = "Dialog",
        text = "A movable window to put the other components in. It can have a title you drag it "
            .. "by, has a close button, and can have a resize grip. It starts hidden: call Show().",
        features = {
            "opts: name (global name), title, width, height, parent, strata, level, theme",
            "Opens in the middle of its parent (the screen by default) and cannot be dragged off screen",
            "Drag it by its title; without a title, by anywhere on the frame",
            "A close button in the top-right corner; opts.noCloseButton = true leaves it out",
            "Catches clicks, so they do not fall through to whatever is behind it",
            "Comes to the front when shown or clicked (see Stacking windows)",
            "Fields: titleText, titleBanner (.left, .right), titleHeader, border, closeButton, dragHandle",
        },
        demo = "The Demo window itself is a dialog, as are the Test window (/alnui tests), Copy Results "
            .. "(/alnui copy) and this window.",
        example = function(p)
            local picker
            local open = Lib:CreateButton(p, {
                text    = "Open a dialog",
                width   = 140,
                onClick = function() ShowSample("dialog", { theme = PickedTheme(picker, "gold") }) end,
            })
            open:SetPoint("TOPLEFT", 0, 0)
            picker = ThemePicker(p, open, {
                selected = "gold",
                onChange = function(theme) ShowSample("dialog", { theme = theme }) end,
            })
        end,
        code = [==[
local f = AlnUI:CreateDialog({
    name   = "MyAddonFrame",   -- optional: also makes the global MyAddonFrame
    title  = "My Window",
    width  = 360,
    height = 200,
    theme  = "gold",
    strata = "DIALOG",         -- above most of the game's UI
})

-- everything you add goes on f; leave room for the title at the top
local hello = AlnUI:CreateLabel(f, { text = "Hello! Drag my title to move me." })
hello:SetPoint("TOPLEFT", 24, -44)

f:Show()   -- dialogs start hidden

-- the close button hides it again; this toggles it from code:
-- f:SetShown(not f:IsShown())]==],
    },
    {
        key = "resizing", name = "Resizing",
        text = "A dialog can get a grip in its bottom-right corner that the player drags to "
            .. "resize it, within limits you choose. Save the size when they let go and restore "
            .. "it next session.",
        features = {
            "opts.resizable = true adds the grip (the chat window's size grabber)",
            "opts.minWidth / minHeight / maxWidth / maxHeight set the limits (default: 200 x 150 up to the screen size)",
            "The default minimum width fits the title banner, but never more than 400",
            "opts.onResize(width, height) runs when the player lets go of the grip",
            "frame:SetResizeEnabled(bool) turns resizing on or off later; frame:IsResizeEnabled() checks it",
            "frame:SetClampedSize(w, h) sets a size kept within the limits: use it to restore a saved size",
            "frame.resizeButton is the grip (made the first time resizing is turned on)",
            "Fill columns in column rows and scroll lists follow the new width",
        },
        demo = "Drag the Demo window's bottom-right corner: the List tab's Mob column grows "
            .. "and shrinks with it.",
        example = function(p)
            local picker
            local open = Lib:CreateButton(p, {
                text    = "Open a resizable dialog",
                width   = 200,
                onClick = function() ShowSample("dialog", { theme = PickedTheme(picker, "gold") }) end,
            })
            open:SetPoint("TOPLEFT", 0, 0)
            picker = ThemePicker(p, open, {
                selected = "gold",
                onChange = function(theme) ShowSample("dialog", { theme = theme }) end,
            })
            Hint(p, "Drag its bottom-right corner; it shows its size when you let go.", 0, -30, PANEL_W)
        end,
        code = [==[
local saved = { w = 400, h = 260 }   -- in a real addon: your SavedVariables

local size   -- the label below; onResize updates it
local f = AlnUI:CreateDialog({
    title     = "Resize me",
    resizable = true,                -- adds the grip in the bottom-right corner
    minWidth  = 300, minHeight = 160,
    maxWidth  = 800, maxHeight = 600,
    -- runs when the player lets go of the grip
    onResize  = function(w, h)
        saved.w, saved.h = w, h
        size:SetText(string.format("Size: %d x %d", w, h))
    end,
})

size = AlnUI:CreateLabel(f, { text = "Drag the bottom-right corner." })
size:SetPoint("TOPLEFT", 24, -44)

-- restore the saved size, kept within the limits above
f:SetClampedSize(saved.w, saved.h)
f:Show()

-- the grip can be turned off and on again later:
-- f:SetResizeEnabled(false)
-- print(f:IsResizeEnabled())   -- false]==],
    },
    {
        key = "stacking", name = "Stacking windows",
        text = "Overlapping AlnUI dialogs never draw through each other. The one shown last, or "
            .. "clicked last, is fully in front, buttons and text included.",
        features = {
            "A dialog comes to the front when it is shown or the player presses the mouse on it or anything on it",
            "frame:BringToFront() does it from code",
            "Each dialog sits above everything inside the one below it, so nothing shows through",
            "Widgets keep their place on their own dialog (the close button stays above the border)",
            "Frame levels stay low however often windows swap places",
            "Applies to AlnUI dialogs in the same strata",
        },
        demo = "/alnui demos opens one overlapping Demo window per theme: click between them. "
            .. "Open the Test window and the Demo together, then click each.",
        example = function(p)
            -- "mixed": a different theme each, the others: all three in one
            local MIXED = { "standard", "gold", "modern" }
            local function Open(picked)
                for i, theme in ipairs(MIXED) do
                    if picked ~= "mixed" then theme = picked end
                    ShowSample("stack-" .. i, {
                        theme = Lib:HasTheme(theme) and theme or "standard",
                        title = "Window " .. i,
                        hint  = "Click me to bring me to the front.",
                        point = { (i - 2) * 60, (2 - i) * 40 },
                    })
                end
            end

            local picker
            local open = Lib:CreateButton(p, {
                text    = "Open three overlapping dialogs",
                width   = 240,
                onClick = function() Open(PickedTheme(picker, "mixed")) end,
            })
            open:SetPoint("TOPLEFT", 0, 0)
            picker = ThemePicker(p, open, {
                selected = "mixed",
                onChange = Open,
                first    = { value = "mixed", label = "Mixed" },
            })
        end,
        code = [==[
-- Three overlapping windows: click any of them to bring it to the front.
local windows = {}
for i = 1, 3 do
    local f = AlnUI:CreateDialog({ title = "Window " .. i, width = 260, height = 150 })
    f:SetPoint("CENTER", (i - 2) * 60, (2 - i) * 40)
    f:Show()   -- each window comes to the front as it is shown
    windows[i] = f
end

-- bring one forward from code, for example when it needs attention
windows[1]:BringToFront()]==],
    },
    {
        key = "titles", name = "Long titles",
        text = "The title banner grows with its text, but never so wide that it reaches the close "
            .. "button. A title too long for the window is cut off with \"...\"; hovering it "
            .. "shows the whole title.",
        features = {
            "The banner is three pieces: two end caps and a middle that fits the title",
            "opts.titleWidth fixes the banner (or modern header) width instead",
            "Titles too long for the window are cut off with \"...\"; frame:IsTitleTruncated() tells you when",
            "Hovering a cut-off title shows the full title in a tooltip",
            "Resizing the window wider shows more of the title, narrower cuts more",
            "titleText:GetText() always returns the full title",
        },
        demo = "Each window from /alnui demos fits its own title: \"AlnUI Demo: Standard\" has a "
            .. "wider banner than \"AlnUI Demo: Gold\".",
        example = function(p)
            local function Open(theme)
                ShowSample("long", {
                    theme = theme,
                    title = "A dialog whose title is much too long to fit on its banner",
                    hint  = "Hover the title to read it all; resize me wider to see more of it.",
                })
            end

            local picker
            local open = Lib:CreateButton(p, {
                text    = "Open a dialog with a very long title",
                width   = 260,
                onClick = function() Open(PickedTheme(picker, "gold")) end,
            })
            open:SetPoint("TOPLEFT", 0, 0)
            picker = ThemePicker(p, open, { selected = "gold", onChange = Open })
        end,
        code = [==[
local f = AlnUI:CreateDialog({
    title     = "Kills of every mob in Elwynn Forest this week",
    width     = 300,
    resizable = true,
})
f:Show()

-- Too long for 300 wide: it shows as "Kills of every mob in...".
-- Hover the title to read it all, or resize the window wider.
print(f:IsTitleTruncated())    -- true
print(f.titleText:GetText())   -- still the full title

-- a fixed banner width instead of one that fits the title
local g = AlnUI:CreateDialog({ title = "Short", titleWidth = 250 })
g:Show()]==],
    },

    {
        key = "table", name = "Table",
        text = "A table is made of pieces that share one list of columns: CreateSortHeader for the "
            .. "headings, and rows below them, either CreateColumnRow for a few fixed rows or a "
            .. "scroll list for many. Because the pieces share the same column specs, the headings "
            .. "line up with the rows.",
        features = {
            "Each column: width, justify (\"LEFT\" or \"RIGHT\"), gap before it, text, wordWrap, and key to make its heading sort",
            "One column may have fill = true: it takes the width left over and follows the window as it resizes; the columns after it line up from the right edge",
            "AlnUI:CreateColumnRow(parent, opts, cols) makes one row and returns its FontStrings to SetText on; opts: x, y, right (inset of the last column), font, anchorTo",
            "AlnUI:CreateSortHeader(parent, opts, cols) makes the headings: clicking one cycles ascending, descending, then unsorted (your own order), with Blizzard's sort arrow",
            "opts.onSort(key, ascending) runs on every click: sort your rows there; both are nil when the sort is cleared",
            "opts.sortKey and opts.ascending set the starting sort; header:SetSort(key, ascending) changes it without calling onSort, header:GetSort() reads it",
            "Columns without a key are plain headings; header.labels and header.buttons (each with .key and .arrow)",
            "To line up, give the header the same left and right insets as the rows. A scroll list's rows sit inside the list, so count the list's own insets too (its x2 makes room for the scroll bar)",
            "Many rows: use a scroll list (only the rows on screen exist). A few fixed rows, or a totals line: column rows are simpler",
        },
        demo = "The Demo's List tab is a table: sortable Mob, Character and Total headings over a "
            .. "200-row scroll list whose Mob column fills the width.",
        example = function(p)
            -- 60 mobs: { name, kills, total }
            local MOBS = { "Defias Pillager", "Murloc Tidehunter", "Kobold Tunneler", "Harvest Golem",
                "Riverpaw Gnoll", "Young Wolf", "Stonetusk Boar", "Mangy Wolf", "Rockjaw Trogg", "Vile Familiar" }
            local rows = {}
            local kills, total = 0, 0
            for i = 1, 60 do
                local k = (i * 37) % 60 + 1
                rows[i] = { MOBS[(i - 1) % #MOBS + 1] .. " #" .. i, k, k + (i * 13) % 90 }
                kills, total = kills + rows[i][2], total + rows[i][3]
            end

            -- the same columns for the header, the list and the totals line;
            -- each key is the index into a row
            local cols = {
                { text = "Mob",   key = 1, fill = true },
                { text = "Kills", key = 2, width = 70, justify = "RIGHT" },
                { text = "Total", key = 3, width = 70, justify = "RIGHT", gap = 6 },
            }

            local list
            Hint(p, "Click a heading: ascending, again: descending, again: the original order.", 0, 0, PANEL_W)
            -- right = 24: the list's 20 inset for its scroll bar + the rows' 4
            Lib:CreateSortHeader(p, {
                y      = -20,
                right  = 24,
                onSort = function(key, ascending)
                    local sorted = {}
                    for i, row in ipairs(rows) do sorted[i] = row end
                    if key then
                        table.sort(sorted, function(a, b)
                            if a[key] == b[key] then return a[1] < b[1] end
                            if ascending then return a[key] < b[key] end
                            return a[key] > b[key]
                        end)
                    end
                    list:SetData(sorted)
                end,
            }, cols)
            Lib:CreateSeparator(p, { y = -40, x2 = -20 })
            list = Lib:CreateScrollList(p, { y1 = -44, x2 = -20, y2 = 28, columns = cols, right = 4, data = rows })

            -- a column row as a totals line, pinned to the bottom with anchorTo
            local foot = CreateFrame("Frame", nil, p)
            foot:SetPoint("BOTTOMLEFT")
            foot:SetPoint("BOTTOMRIGHT")
            foot:SetHeight(20)
            Lib:CreateSeparator(foot, { y = 2, x2 = -20 })
            local totals = Lib:CreateColumnRow(p, { anchorTo = foot, y = -4, right = 24, font = "GameFontNormal" }, cols)
            totals[1]:SetText("All 60 mobs")
            totals[2]:SetText(kills)
            totals[3]:SetText(total)
        end,
        code = [==[
local f = AlnUI:CreateDialog({ title = "Mob kills", width = 380, height = 340, resizable = true })

-- the rows: { name, kills, total }
local mobs = {
    { "Defias Pillager",   21, 113 }, { "Murloc Tidehunter", 6,  88 },
    { "Kobold Tunneler",   45, 118 }, { "Harvest Golem",     19, 137 },
    { "Riverpaw Gnoll",    18,  35 }, { "Young Wolf",        52,  53 },
    { "Stonetusk Boar",    54, 173 }, { "Mangy Wolf",        20, 121 },
}

-- One list of columns for the header, the list and the totals line, so
-- they all line up. Each key is what onSort gets back: the index into a row.
local cols = {
    { text = "Mob",   key = 1, fill = true },                  -- takes the leftover width
    { text = "Kills", key = 2, width = 70, justify = "RIGHT" },
    { text = "Total", key = 3, width = 70, justify = "RIGHT", gap = 6 },
}

local list   -- made below; onSort fills it

-- Click a heading: ascending, again: descending, again: unsorted.
-- right = 40: the list's 36 inset for its scroll bar + the rows' 4.
local header = AlnUI:CreateSortHeader(f, {
    x = 24, y = -44, right = 40,
    onSort = function(key, ascending)
        local sorted = {}
        for i, mob in ipairs(mobs) do sorted[i] = mob end
        if key then   -- nil: unsorted, keep the list's own order
            table.sort(sorted, function(a, b)
                if a[key] == b[key] then return a[1] < b[1] end   -- ties by name
                if ascending then return a[key] < b[key] end
                return a[key] > b[key]
            end)
        end
        list:SetData(sorted)   -- keeps the scroll position
    end,
}, cols)

AlnUI:CreateSeparator(f, { y = -64, x1 = 24, x2 = -36 })

list = AlnUI:CreateScrollList(f, {
    x1 = 24,  y1 = -68,
    x2 = -36, y2 = 48,         -- leaves room at the bottom for the totals
    columns = cols,
    right   = 4,
    data    = mobs,
})

-- A column row on its own: a totals line pinned to the bottom of the
-- window, through anchorTo, so it stays there when the window resizes.
local foot = CreateFrame("Frame", nil, f)
foot:SetPoint("BOTTOMLEFT", 0, 20)
foot:SetPoint("BOTTOMRIGHT", 0, 20)
foot:SetHeight(20)

local kills, total = 0, 0
for _, mob in ipairs(mobs) do kills, total = kills + mob[2], total + mob[3] end

local totals = AlnUI:CreateColumnRow(f, {
    anchorTo = foot, x = 24, y = -4, right = 40, font = "GameFontNormal",
}, cols)
totals[1]:SetText("All mobs")
totals[2]:SetText(kills)
totals[3]:SetText(total)

f:Show()

-- header:SetSort(2, false) shows a sort without calling onSort;
-- header:GetSort() returns the key and the direction]==],
    },
    {
        key = "separator", name = "Separator",
        text = "A horizontal line across its parent, like <hr> in HTML.",
        features = {
            "opts: y (from the top), x1 and x2 (insets from the edges), thickness, color, layer",
            "Pixel snapping is turned off, so 1px lines stay visible at odd UI scales",
            "Returns the Texture, so you can move or recolor it later",
        },
        demo = "The Feedback tab's Separators section shows thicknesses, colors and insets; "
            .. "lines divide every tab's sections.",
        example = function(p)
            Lib:CreateSeparator(p, { y = -4 })
            Lib:CreateSeparator(p, { y = -20, thickness = 2, color = GOLD })
            Lib:CreateSeparator(p, { y = -38, thickness = 4, x1 = 60, x2 = -60,
                color = { 0.8, 0.1, 0.1, 0.8 } })
        end,
        code = [==[
local f = AlnUI:CreateDialog({ title = "Separators", width = 320, height = 160 })

-- a thin grey line across the window, 50px below its top
AlnUI:CreateSeparator(f, { y = -50, x1 = 20, x2 = -20 })

-- thicker, and gold
AlnUI:CreateSeparator(f, { y = -80, x1 = 20, x2 = -20, thickness = 2, color = { 1, 0.82, 0 } })

-- 60px in from each side, red and a little see-through
local red = AlnUI:CreateSeparator(f, {
    y = -110, x1 = 60, x2 = -60, thickness = 4, color = { 0.8, 0.1, 0.1, 0.8 },
})
-- it is a Texture: recolor or move it like any other
red:SetVertexColor(0.1, 0.6, 0.1, 0.8)

f:Show()]==],
    },
    {
        key = "scrollframe", name = "Scroll frame",
        text = "A scrolling area with Blizzard's modern slim scroll bar. Put anything in the "
            .. "content frame it returns. For lists of rows, a scroll list is better.",
        features = {
            "opts: x1, y1 (offset of the top-left corner) and x2, y2 (of the bottom-right corner) from the parent's; the scroll bar sits outside the right edge",
            "opts.contentWidth and opts.contentHeight size the content; grow the height as you add to it",
            "opts.childType makes the content another kind of frame: an EditBox gives scrolling, copyable text",
            "Returns scroll, content; scroll.ScrollBar is the bar",
        },
        demo = "The Test window's results and the Copy Results window scroll this way; so does "
            .. "this window's About and Code tabs.",
        example = function(p)
            local LINES = 200
            Hint(p, LINES .. " lines, every one a real FontString inside the content frame.", 0, 0, PANEL_W)
            local _, content = Lib:CreateScrollFrame(p, {
                y1 = -20, x2 = -20, contentWidth = PANEL_W - 20, contentHeight = 20 * LINES,
            })
            for i = 1, LINES do
                Lib:CreateLabel(content, {
                    text  = "Line " .. i .. " of " .. LINES,
                    color = i % 10 == 0 and GOLD or nil,
                }):SetPoint("TOPLEFT", 4, -(i - 1) * 20)
            end
        end,
        code = [==[
local f = AlnUI:CreateDialog({ title = "Scroll frame", width = 320, height = 260 })

local LINES = 200
local scroll, content = AlnUI:CreateScrollFrame(f, {
    x1 = 20,  y1 = -40,
    x2 = -36, y2 = 20,            -- room on the right for the scroll bar
    contentWidth  = 260,
    contentHeight = LINES * 20,   -- tall enough for every line
})

-- every line is a real FontString inside the content frame
for i = 1, LINES do
    local line = AlnUI:CreateLabel(content, { text = "Line " .. i .. " of " .. LINES })
    line:SetPoint("TOPLEFT", 4, -(i - 1) * 20)
end

f:Show()

-- An EditBox as the content gives scrolling text the player can copy:
-- local _, box = AlnUI:CreateScrollFrame(f, { childType = "EditBox", contentWidth = 260 })
-- box:SetMultiLine(true)
-- box:SetFontObject(GameFontHighlightSmall)
-- box:SetText("Lots of text...")]==],
    },
    {
        key = "scrolllist", name = "Scroll list",
        text = "A scrolling list of rows built on Blizzard's ScrollBox. Only the visible rows "
            .. "exist and they are reused while scrolling, so it stays fast with thousands of rows.",
        features = {
            "opts.columns: the same column specs as a table's (see Table); one may fill the width",
            "opts.data: the rows, each an array with one value per column (a plain value is a one-column row)",
            "list:SetData(rows, resetScroll) replaces the rows, keeping the scroll position unless resetScroll",
            "opts.onRowInit(row, data) runs as each row is shown: color or decorate it there (rows are reused, so reset what you change)",
            "list:GetNumRows(), list:ForEachRow(fn), list.scrollBar, and row.cols (the row's FontStrings)",
            "opts: x1, y1, x2, y2 (corner offsets, as for a scroll frame), rowHeight (default 20), font, x and right (column insets)",
        },
        demo = "The List tab: 200 rows, Shuffle keeps your scroll position, Shuffle + Top resets it, "
            .. "Empty List clears it, and high totals turn orange in onRowInit.",
        example = function(p)
            local ROWS = 5000
            local mobs = { "Defias Pillager", "Murloc Tidehunter", "Kobold Tunneler",
                "Harvest Golem", "Riverpaw Gnoll", "Young Wolf", "Stonetusk Boar", "Mangy Wolf" }
            local rows = {}
            for i = 1, ROWS do
                rows[i] = { mobs[(i - 1) % #mobs + 1] .. " #" .. i, (i * 37) % 50 }
            end
            Hint(p, ROWS .. " rows, but only the ones on screen exist: they are reused as you "
                .. "scroll. Kills of 40 or more turn orange in onRowInit.", 0, 0, PANEL_W)
            Lib:CreateScrollList(p, {
                y1        = -32,
                x2        = -20,
                columns   = { { fill = true }, { width = 60, justify = "RIGHT" } },
                right     = 4,
                data      = rows,
                onRowInit = function(row, data)
                    local high = data[2] >= 40
                    row.cols[2]:SetTextColor(1, high and 0.5 or 1, high and 0.2 or 1)
                end,
            })
        end,
        code = [==[
local f = AlnUI:CreateDialog({ title = "Scroll list", width = 360, height = 300, resizable = true })

-- 5000 rows, one array per row: { mob, kills }
local rows = {}
for i = 1, 5000 do
    rows[i] = { "Defias Pillager #" .. i, (i * 37) % 50 }
end

local list = AlnUI:CreateScrollList(f, {
    x1 = 20,  y1 = -40,
    x2 = -36, y2 = 20,                        -- room on the right for the scroll bar
    columns = {
        { fill = true },                      -- Mob: follows the window's width
        { width = 60, justify = "RIGHT" },    -- Kills
    },
    right = 4,
    data  = rows,
    -- runs each time a row is shown; rows are reused while scrolling,
    -- so set the color every time, not only for high values
    onRowInit = function(row, data)
        local high = data[2] >= 40
        row.cols[2]:SetTextColor(1, high and 0.5 or 1, high and 0.2 or 1)
    end,
})

f:Show()
print(list:GetNumRows())   -- 5000

-- New rows later keep the scroll position; true goes back to the top:
-- list:SetData(newRows, true)]==],
    },

    {
        key = "label", name = "Label",
        text = "A piece of text (a FontString) with its font, color, alignment and width set in "
            .. "one call.",
        features = {
            "opts: text, font (default GameFontHighlight), color, justify, layer",
            "opts.width makes long text wrap; wordWrap = false keeps it on one line",
            "Returns the FontString: call SetText on it to change the text",
            "Color part of the text with WoW's color codes: \"||cffRRGGBB\" starts a color, \"||r\" ends it (in Lua files, write the || as \\124)",
            "SetSpacing(2) adds space between wrapped lines; label:GetStringHeight() is how tall the text is",
            "Bullet lists: one label per item with a small square beside it, each anchored under the one before",
        },
        demo = "Every heading and grey hint in the Demo is a label. So is every line of this window's "
            .. "About tab, bullets included.",
        example = function(p)
            Lib:CreateLabel(p, { text = "A plain label" }):SetPoint("TOPLEFT", 0, 0)
            Lib:CreateLabel(p, { text = "A gold heading", font = "GameFontNormalLarge" })
                :SetPoint("TOPLEFT", 0, -18)
            Lib:CreateLabel(p, { text = "Grey and small", font = "GameFontHighlightSmall", color = GREY })
                :SetPoint("TOPLEFT", 0, -42)
            Lib:CreateLabel(p, {
                text  = "A label with a width wraps its text onto as many lines as it needs.",
                width = 220,
            }):SetPoint("TOPLEFT", 0, -62)

            -- a heading with a line under it, then a bullet list
            local heading = Lib:CreateLabel(p, { text = "Before the raid", font = "GameFontNormalLarge" })
            heading:SetPoint("TOPLEFT", 0, -110)
            local line = p:CreateTexture(nil, "ARTWORK")
            line:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.35)
            line:SetHeight(1)
            line:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -3)
            line:SetPoint("RIGHT", p, "RIGHT", -20, 0)

            local items = {
                "Repair your gear",
                "Bring |cff9fd8ff20 flasks|r and food for everyone",
                "Long items wrap, and their next lines stay indented under the text, not under the bullet",
                "|cffff6060Do not|r pull before the tank is ready",
            }
            local previous = line
            for _, item in ipairs(items) do
                local text = Lib:CreateLabel(p, { text = item, width = 300 })
                text:SetSpacing(2)
                text:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", previous == line and 16 or 0, -6)
                local dot = p:CreateTexture(nil, "ARTWORK")
                dot:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 1)
                dot:SetSize(4, 4)
                dot:SetPoint("TOPLEFT", text, "TOPLEFT", -12, -5)
                previous = text
            end
        end,
        code = [==[
local f = AlnUI:CreateDialog({ title = "Labels", width = 360, height = 300 })

local heading = AlnUI:CreateLabel(f, { text = "Kills today", font = "GameFontNormalLarge" })
heading:SetPoint("TOPLEFT", 24, -44)

local count = AlnUI:CreateLabel(f, { text = "0 kills", justify = "RIGHT", width = 100 })
count:SetPoint("TOPRIGHT", -24, -48)

-- with a width, long text wraps onto as many lines as it needs
local note = AlnUI:CreateLabel(f, {
    text  = "Grey, small, and long enough to wrap onto a second line.",
    font  = "GameFontHighlightSmall",
    color = { 0.7, 0.7, 0.7 },
    width = 300,
})
note:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -10)

-- A heading with a gold line under it...
local GOLD = { 1, 0.82, 0 }
local listTitle = AlnUI:CreateLabel(f, { text = "Before the raid", font = "GameFontNormalLarge" })
listTitle:SetPoint("TOPLEFT", note, "BOTTOMLEFT", 0, -20)

local line = f:CreateTexture(nil, "ARTWORK")
line:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.35)
line:SetHeight(1)
line:SetPoint("TOPLEFT", listTitle, "BOTTOMLEFT", 0, -3)
line:SetPoint("RIGHT", f, "RIGHT", -24, 0)

-- ...then a bullet list: one label per item, each anchored under the one
-- before it, so they never overlap however many lines an item wraps to.
-- Color codes: \124cffRRGGBB starts a color and \124r ends it. \124 is the
-- pipe character; writing it this way keeps it from being read as a color
-- code before it reaches the label.
local items = {
    "Repair your gear",
    "Bring \124cff9fd8ff20 flasks\124r and food for everyone",
    "Long items wrap, and their next lines stay indented under the text",
    "\124cffff6060Do not\124r pull before the tank is ready",
}
local previous = line
for _, item in ipairs(items) do
    local text = AlnUI:CreateLabel(f, { text = item, width = 280 })
    text:SetSpacing(2)   -- a little room between wrapped lines
    -- the first item is indented 16 from the line; the rest line up under it
    text:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", previous == line and 16 or 0, -6)

    -- the bullet: a small gold square left of the item's first line
    local dot = f:CreateTexture(nil, "ARTWORK")
    dot:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 1)
    dot:SetSize(4, 4)
    dot:SetPoint("TOPLEFT", text, "TOPLEFT", -12, -5)

    previous = text
end

f:Show()
count:SetText("12 kills")   -- labels are FontStrings: change them any time]==],
    },
    {
        key = "editbox", name = "Edit box",
        text = "A one-line text box with an optional label above it.",
        features = {
            "opts: text, label, width, height, maxLetters, numeric (digits only), name",
            "onEnterPressed(text) when the player presses Enter",
            "onTextChanged(text) for the player's typing only, not when you call SetText",
            "Enter and Escape take the focus away from the box",
            "editbox.label is the label FontString",
        },
        demo = "The Inputs tab: the Name box greets you on Enter, the second box counts letters as "
            .. "you type, and the numeric Opacity box sets the slider when you press Enter.",
        example = function(p)
            local echo = Hint(p, "Type and press Enter.", 220, -22)
            Lib:CreateEditBox(p, {
                label          = "Your name",
                width          = 180,
                onEnterPressed = function(text) echo:SetText("Hello, " .. text .. "!") end,
            }):SetPoint("TOPLEFT", 6, -18)
            local count = Hint(p, "Typed: 0 letters", 220, -74)
            Lib:CreateEditBox(p, {
                label         = "Counts as you type",
                width         = 180,
                onTextChanged = function(text) count:SetText("Typed: " .. #text .. " letters") end,
            }):SetPoint("TOPLEFT", 6, -70)
        end,
        code = [==[
local f = AlnUI:CreateDialog({ title = "Edit boxes", width = 340, height = 170 })

local greeting = AlnUI:CreateLabel(f, { text = "Type your name and press Enter." })
greeting:SetPoint("TOPLEFT", 24, -100)

local name = AlnUI:CreateEditBox(f, {
    label          = "Name",           -- shown above the box
    width          = 180,
    maxLetters     = 24,
    onEnterPressed = function(text) greeting:SetText("Hello, " .. text .. "!") end,
})
name:SetPoint("TOPLEFT", 30, -60)   -- the box's border sticks out ~5px to the left

local level = AlnUI:CreateEditBox(f, {
    label         = "Level",
    width         = 50,
    numeric       = true,              -- digits only
    -- only for the player's typing, not when you call SetText
    onTextChanged = function(text) print("level is now", text) end,
})
level:SetPoint("LEFT", name, "RIGHT", 24, 0)

f:Show()]==],
    },

    {
        key = "button", name = "Button",
        text = "The standard red Blizzard button.",
        features = {
            "opts: text, width (default 120), height (default 24), onClick, name",
            "opts.disabled starts it disabled; Enable() and Disable() change it later",
            "opts.tooltip and opts.tooltipText add a tooltip, which also shows while disabled",
        },
        demo = "The Buttons tab: a click counter, a disabled button with a tooltip, Enable It to "
            .. "toggle it, and small, wide and tall sizes.",
        example = function(p)
            local clicks = 0
            local btn
            btn = Lib:CreateButton(p, {
                text    = "Click me",
                onClick = function()
                    clicks = clicks + 1
                    btn:SetText("Clicked " .. clicks .. "x")
                end,
            })
            btn:SetPoint("TOPLEFT", 0, 0)
            local off = Lib:CreateButton(p, {
                text = "Disabled", disabled = true,
                tooltip = "Disabled button", tooltipText = "Tooltips still show.",
            })
            off:SetPoint("LEFT", btn, "RIGHT", 8, 0)
            Lib:CreateButton(p, {
                text = "Toggle it", width = 100,
                onClick = function() off:SetEnabled(not off:IsEnabled()) end,
            }):SetPoint("LEFT", off, "RIGHT", 8, 0)
        end,
        code = [==[
local f = AlnUI:CreateDialog({ title = "Buttons", width = 340, height = 140 })

local clicks = 0
local reset   -- made below; the first button enables it

local count = AlnUI:CreateButton(f, {
    text    = "Click me",
    onClick = function(self)
        clicks = clicks + 1
        self:SetText("Clicked " .. clicks .. "x")
        reset:Enable()
    end,
})
count:SetPoint("TOPLEFT", 24, -50)

reset = AlnUI:CreateButton(f, {
    text        = "Reset",
    width       = 90,
    disabled    = true,                  -- starts greyed out
    tooltip     = "Reset",               -- tooltips show even while disabled
    tooltipText = "Click the other button first.",
    onClick     = function(self)
        clicks = 0
        count:SetText("Click me")
        self:Disable()
    end,
})
reset:SetPoint("LEFT", count, "RIGHT", 8, 0)

f:Show()]==],
    },
    {
        key = "iconbutton", name = "Icon button",
        text = "A square button showing an icon, with the usual hover highlight.",
        features = {
            "opts: icon (texture path or file ID), size (default 32), onClick, name",
            "The icon nudges down while pressed and turns grey while disabled",
            "opts.disabled, opts.tooltip and opts.tooltipText, like a button",
            "button.icon is the icon Texture: change it with SetTexture",
        },
        demo = "The Buttons tab: a row of icons to pick from (the line under them shows your pick), "
            .. "four sizes, a disabled icon and Toggle Key to enable it.",
        example = function(p)
            local first = Lib:CreateIconButton(p, {
                icon = "Interface\\Icons\\INV_Misc_Coin_01",
                tooltip = "Gold", onClick = function() print("Coin clicked") end,
            })
            first:SetPoint("TOPLEFT", 0, 0)
            Lib:CreateIconButton(p, {
                icon = "Interface\\Icons\\INV_Misc_Note_01", size = 24, tooltip = "Smaller",
            }):SetPoint("LEFT", first, "RIGHT", 8, 0)
            Lib:CreateIconButton(p, {
                icon = "Interface\\Icons\\INV_Misc_Key_03", disabled = true,
                tooltip = "Disabled", tooltipText = "Greyed out.",
            }):SetPoint("LEFT", first, "RIGHT", 40, 0)
        end,
        code = [==[
local f = AlnUI:CreateDialog({ title = "Icon buttons", width = 300, height = 140 })

local picked = AlnUI:CreateLabel(f, { text = "Pick an icon." })
picked:SetPoint("TOPLEFT", 24, -100)

local icons = {
    { "Gold",  "Interface\\Icons\\INV_Misc_Coin_01" },
    { "Notes", "Interface\\Icons\\INV_Misc_Note_01" },
    { "Key",   "Interface\\Icons\\INV_Misc_Key_03" },
}
for i, info in ipairs(icons) do
    local btn = AlnUI:CreateIconButton(f, {
        icon    = info[2],
        size    = 36,
        tooltip = info[1],
        onClick = function() picked:SetText("Picked: " .. info[1]) end,
    })
    btn:SetPoint("TOPLEFT", 24 + (i - 1) * 44, -48)
end

f:Show()

-- btn.icon is the Texture: btn.icon:SetTexture(...) swaps the picture,
-- and btn:Disable() turns the icon grey]==],
    },
    {
        key = "checkbox", name = "Checkbox",
        text = "An on/off box with a label to its right. Each checkbox is its own choice, so a "
            .. "list of options is simply several checkboxes.",
        features = {
            "opts: label, checked (starting state), name",
            "onChange(checked) each time the player clicks it, not when it is made",
            "opts.tooltip and opts.tooltipText add a tooltip",
            "checkbox.label is the label FontString; GetChecked/SetChecked read and set it",
            "SetChecked from code does not call onChange, so update anything that depends on it yourself",
            "There is no checkbox group: for several on/off options, make one checkbox per option",
        },
        demo = "The Inputs tab: three checkboxes, one starting checked and one with a tooltip; the "
            .. "line under them lists which are on.",
        example = function(p)
            -- one checkbox per setting
            local OPTIONS = {
                { key = "sound",    label = "Play a sound" },
                { key = "minimap",  label = "Show a minimap button" },
                { key = "lock",     label = "Lock the window" },
                { key = "announce", label = "Announce in party chat",
                  tooltip = "Announce", tooltipText = "Tells your party when a rare spawns." },
                { key = "combat",   label = "Hide in combat" },
            }
            local settings = { sound = true, lock = true }
            local boxes = {}

            local summary = Hint(p, "", 0, -(#OPTIONS * 26 + 8), PANEL_W)
            local function UpdateSummary()
                local on = {}
                for _, option in ipairs(OPTIONS) do
                    if settings[option.key] then table.insert(on, option.label) end
                end
                summary:SetText("On: " .. (#on > 0 and table.concat(on, ", ") or "nothing"))
            end

            for i, option in ipairs(OPTIONS) do
                boxes[i] = Lib:CreateCheckbox(p, {
                    label       = option.label,
                    checked     = settings[option.key],
                    tooltip     = option.tooltip,
                    tooltipText = option.tooltipText,
                    onChange    = function(checked)
                        settings[option.key] = checked
                        UpdateSummary()
                    end,
                })
                boxes[i]:SetPoint("TOPLEFT", 0, -(i - 1) * 26)
            end

            -- SetChecked does not call onChange, so these update the summary themselves
            local function SetAll(checked)
                for i, option in ipairs(OPTIONS) do
                    boxes[i]:SetChecked(checked)
                    settings[option.key] = checked
                end
                UpdateSummary()
            end
            local all = Lib:CreateButton(p, { text = "All", width = 70, onClick = function() SetAll(true) end })
            all:SetPoint("TOPLEFT", 280, 0)
            Lib:CreateButton(p, { text = "None", width = 70, onClick = function() SetAll(false) end })
                :SetPoint("TOPLEFT", all, "BOTTOMLEFT", 0, -6)

            UpdateSummary()
        end,
        code = [==[
-- in a real addon: your SavedVariables
local settings = { sound = true, lock = true }

-- one checkbox per setting
local OPTIONS = {
    { key = "sound",    label = "Play a sound" },
    { key = "minimap",  label = "Show a minimap button" },
    { key = "lock",     label = "Lock the window" },
    { key = "announce", label = "Announce in party chat",
      tooltip = "Announce", tooltipText = "Tells your party when a rare spawns." },
    { key = "combat",   label = "Hide in combat" },
}

local f = AlnUI:CreateDialog({ title = "Settings", width = 360, height = 260 })

local summary = AlnUI:CreateLabel(f, { width = 300 })
summary:SetPoint("TOPLEFT", 24, -44 - #OPTIONS * 26 - 8)

local function UpdateSummary()
    local on = {}
    for _, option in ipairs(OPTIONS) do
        if settings[option.key] then table.insert(on, option.label) end
    end
    summary:SetText("On: " .. (#on > 0 and table.concat(on, ", ") or "nothing"))
end

local boxes = {}
for i, option in ipairs(OPTIONS) do
    boxes[i] = AlnUI:CreateCheckbox(f, {
        label       = option.label,
        checked     = settings[option.key],   -- the starting state
        tooltip     = option.tooltip,         -- nil: no tooltip
        tooltipText = option.tooltipText,
        -- only for the player's clicks, not when the box is made
        onChange    = function(checked)
            settings[option.key] = checked
            UpdateSummary()
        end,
    })
    boxes[i]:SetPoint("TOPLEFT", 20, -44 - (i - 1) * 26)
end

-- Check or clear them all from code. SetChecked does not call onChange,
-- so update the settings and the summary here too.
local function SetAll(checked)
    for i, option in ipairs(OPTIONS) do
        boxes[i]:SetChecked(checked)
        settings[option.key] = checked
    end
    UpdateSummary()
end
local all = AlnUI:CreateButton(f, { text = "All", width = 70, onClick = function() SetAll(true) end })
all:SetPoint("TOPRIGHT", -24, -44)
local none = AlnUI:CreateButton(f, { text = "None", width = 70, onClick = function() SetAll(false) end })
none:SetPoint("TOP", all, "BOTTOM", 0, -6)

UpdateSummary()
f:Show()]==],
    },
    {
        key = "radiogroup", name = "Radio group",
        text = "A column of round buttons where only one can be picked.",
        features = {
            "opts.options: values, or { value = v, label = \"text\" } for a label that differs from the value",
            "opts.selected: the starting pick (default none)",
            "onChange(value) only when the pick changes",
            "group:GetValue() reads the pick; group:SetValue(value) picks without calling onChange",
            "The labels are clickable too; opts.spacing and opts.width set the layout",
            "group.buttons are the radio buttons, each with .value and .label",
        },
        demo = "The Inputs tab's class picker: Warrior, Mage, Priest or Rogue.",
        example = function(p)
            local picked = Hint(p, "Picked: Small", 200, 0)
            Lib:CreateRadioGroup(p, {
                options  = { "Small", "Medium", "Large" },
                selected = "Small",
                onChange = function(v) picked:SetText("Picked: " .. v) end,
            }):SetPoint("TOPLEFT", 0, 0)
        end,
        code = [==[
local settings = { size = 2 }   -- in a real addon: your SavedVariables

local f = AlnUI:CreateDialog({ title = "Radio group", width = 300, height = 170 })

local group = AlnUI:CreateRadioGroup(f, {
    options = {
        { value = 1, label = "Small" },   -- the value can differ from the label
        { value = 2, label = "Medium" },
        { value = 3, label = "Large" },
    },
    selected = settings.size,
    -- only when the pick changes
    onChange = function(v)
        settings.size = v
        print("size is now", v)
    end,
})
group:SetPoint("TOPLEFT", 24, -48)

f:Show()

-- group:GetValue() reads the pick; group:SetValue(1) picks without onChange]==],
    },
    {
        key = "slider", name = "Slider",
        text = "A slider with a label under it.",
        features = {
            "opts: min, max, step, value, width, name",
            "opts.labelFormat keeps the label showing the value, e.g. \"Volume: %d%%\"",
            "onChange(value) on every move, and once at the start when you give a value",
            "slider.label is the label FontString",
        },
        demo = "The Inputs tab's slider sets the Demo window's opacity; the numeric box next to it "
            .. "sets the slider.",
        example = function(p)
            Lib:CreateSlider(p, {
                width = 220, min = 0, max = 100, step = 5, value = 50,
                labelFormat = "Volume: %d%%",
            }):SetPoint("TOPLEFT", 4, -6)
        end,
        code = [==[
local settings = { volume = 50 }   -- in a real addon: your SavedVariables

local f = AlnUI:CreateDialog({ title = "Slider", width = 300, height = 140 })

local slider = AlnUI:CreateSlider(f, {
    width       = 220,
    min         = 0,
    max         = 100,
    step        = 5,
    value       = settings.volume,
    labelFormat = "Volume: %d%%",     -- %% shows a percent sign
    -- on every move, and once right away because a value was given
    onChange    = function(v) settings.volume = v end,
})
slider:SetPoint("TOP", 0, -56)

f:Show()]==],
    },
    {
        key = "tabs", name = "Tabs",
        text = "A row of native Blizzard tabs. Give each tab a panel and only the selected tab's "
            .. "panel shows.",
        features = {
            "opts.style \"top\": tabs standing on the content; \"bottom\": tabs hanging below a window, like the Character window's",
            "opts: tabs (the labels), panels, selected (default 1), tabWidth, gap",
            "onSelect(index) when the player picks a different tab",
            "tabs:Select(index), tabs:GetSelected(), tabs:SetPanel(index, frame)",
            "tabs.buttons and tabs.panels",
            "AlnUI:HasTabs(style) checks the client has that style's template",
        },
        demo = "The Demo's List, Inputs, Buttons and Feedback tabs are top tabs; the Feedback tab "
            .. "shows bottom tabs under a small box. This window's tabs are made the same way.",
        example = function(p)
            if not Lib:HasTabs("top") then
                Hint(p, "This client has no top tabs (PanelTopTabButtonTemplate).", 0, 0, PANEL_W)
                return
            end
            local panels = {}
            for i, text in ipairs({ "First tab's panel", "Second tab's panel" }) do
                local panel = CreateFrame("Frame", nil, p)
                panel:SetPoint("TOPLEFT", 0, -40)
                panel:SetSize(PANEL_W, 40)
                Lib:CreateLabel(panel, { text = text }):SetPoint("TOPLEFT", 8, -4)
                panels[i] = panel
            end
            Lib:CreateTabs(p, { tabs = { "First", "Second" }, panels = panels })
                :SetPoint("TOPLEFT", 0, 0)
        end,
        code = [==[
local f = AlnUI:CreateDialog({ title = "Tabs", width = 360, height = 220 })

-- one panel per tab, each filling the area under the tabs
local function NewPanel(text)
    local p = CreateFrame("Frame", nil, f)
    p:SetPoint("TOPLEFT", 20, -70)
    p:SetPoint("BOTTOMRIGHT", -20, 20)
    AlnUI:CreateLabel(p, { text = text }):SetPoint("TOPLEFT", 4, -4)
    return p
end
local general = NewPanel("General settings go here.")
local sounds  = NewPanel("Sound settings go here.")

-- some clients lack the tab templates; check before using them
if AlnUI:HasTabs("top") then
    local tabs = AlnUI:CreateTabs(f, {
        tabs     = { "General", "Sounds" },
        panels   = { general, sounds },   -- only the selected one shows
        onSelect = function(i) print("tab", i) end,
    })
    -- top tabs stand on a line just under the title
    tabs:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 20, -64)
    AlnUI:CreateSeparator(f, { y = -64, x1 = 16, x2 = -16 })

    -- tabs:Select(2) switches from code; tabs:GetSelected() reads it
end

f:Show()

-- style = "bottom" hangs the tabs below the window instead:
-- tabs:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 12, 2)]==],
    },
    {
        key = "dropdown", name = "Dropdown",
        text = "A pick-one menu built on the modern Blizzard dropdown.",
        features = {
            "opts: options (values or { value, label }), selected, label (above it), width, name",
            "opts.placeholder: the text shown while nothing is picked (default \"Select...\")",
            "onChange(value) when the player picks a different option",
            "dd:GetValue(), dd:SetValue(value) without onChange, dd:Choose(value) as if the player picked it",
            "dd:SetOptions(list) replaces the options",
            "opts.tooltip and opts.tooltipText add a tooltip",
            "AlnUI:HasDropdown() checks the client has the modern dropdown",
        },
        demo = "The Inputs tab: a Zone dropdown, and one that starts on its placeholder with a Swap "
            .. "button calling SetOptions. The theme switcher is a dropdown too.",
        example = function(p)
            if not Lib:HasDropdown() then
                Hint(p, "This client has no modern dropdown (WowStyle1DropdownTemplate).", 0, 0, PANEL_W)
                return
            end
            local picked = Hint(p, "", 200, -24)
            Lib:CreateDropdown(p, {
                label    = "Zone",
                width    = 180,
                options  = { "Elwynn Forest", "Westfall", "Duskwood" },
                onChange = function(v) picked:SetText("Picked: " .. v) end,
            }):SetPoint("TOPLEFT", 0, -18)
        end,
        code = [==[
local settings = { zone = "Westfall" }   -- in a real addon: your SavedVariables

local f = AlnUI:CreateDialog({ title = "Dropdown", width = 320, height = 160 })

-- some clients lack the modern dropdown; check before using it
if AlnUI:HasDropdown() then
    local zone = AlnUI:CreateDropdown(f, {
        label       = "Zone",            -- shown above it
        width       = 200,
        options     = { "Elwynn Forest", "Westfall", "Duskwood" },
        selected    = settings.zone,
        placeholder = "Pick a zone",     -- shown while nothing is picked
        onChange    = function(v) settings.zone = v end,
    })
    zone:SetPoint("TOPLEFT", 24, -64)

    -- swap the options later; Choose picks one as if the player did:
    -- zone:SetOptions({ "Stormwind", "Ironforge" })
    -- zone:Choose("Ironforge")
end

f:Show()]==],
    },

    {
        key = "progressbar", name = "Progress bar",
        text = "A bar that fills from min to max, with optional text on it.",
        features = {
            "opts: min, max, value, width, height, color, name",
            "opts.labelFormat gets the value and the max: \"%d / %d\" shows \"30 / 100\"",
            "The label updates on SetValue and SetMinMaxValues",
            "bar.label is the text, bar.bg the dark background",
        },
        demo = "The Feedback tab: an XP bar with -100 and +100, a red health bar, a thin bar with no "
            .. "label and a Cast button that fills a bar over time.",
        example = function(p)
            local bar = Lib:CreateProgressBar(p, {
                width = 220, value = 30, labelFormat = "%d / %d",
            })
            bar:SetPoint("TOPLEFT", 0, -4)
            Lib:CreateButton(p, {
                text = "+10", width = 60,
                onClick = function()
                    local _, max = bar:GetMinMaxValues()
                    bar:SetValue((bar:GetValue() + 10) % (max + 10))
                end,
            }):SetPoint("LEFT", bar, "RIGHT", 12, 0)
        end,
        code = [==[
local f = AlnUI:CreateDialog({ title = "Progress bar", width = 320, height = 150 })

local bar = AlnUI:CreateProgressBar(f, {
    width       = 220,
    max         = 100,
    value       = 30,
    color       = { 0.2, 0.5, 1 },
    labelFormat = "%d / %d",   -- gets the value and the max: "30 / 100"
})
bar:SetPoint("TOP", 0, -50)

local plus = AlnUI:CreateButton(f, {
    text    = "+10",
    width   = 60,
    onClick = function()
        local _, max = bar:GetMinMaxValues()
        bar:SetValue(math.min(max, bar:GetValue() + 10))   -- the label follows
    end,
})
plus:SetPoint("TOP", bar, "BOTTOM", 0, -12)

f:Show()]==],
    },
    {
        key = "tooltip", name = "Tooltip",
        text = "Shows a GameTooltip while the mouse is over any frame.",
        features = {
            "AlnUI:AddTooltip(frame, title, text, anchor): text is wrapped, anchor defaults to ANCHOR_RIGHT",
            "Pass a function as the title for a tooltip that changes: it returns title, text (nil shows nothing)",
            "Calling it again replaces the tooltip",
            "Works on disabled buttons too",
            "Hooks the frame's OnEnter and OnLeave, so the frame's own handlers keep working",
            "Buttons, icon buttons, checkboxes and dropdowns take opts.tooltip and opts.tooltipText directly",
        },
        demo = "The Buttons tab: Hover Me shows a tooltip that changes each time; the disabled "
            .. "button and the icons have tooltips. Cut-off dialog titles use one too.",
        example = function(p)
            local plain = Lib:CreateButton(p, { text = "Hover me" })
            plain:SetPoint("TOPLEFT", 0, 0)
            Lib:AddTooltip(plain, "A tooltip", "With a line of text under the title.")

            local live = Lib:CreateButton(p, { text = "What time is it?", width = 140 })
            live:SetPoint("LEFT", plain, "RIGHT", 8, 0)
            Lib:AddTooltip(live, function() return "The time", date("%H:%M:%S") end)
        end,
        code = [==[
local f = AlnUI:CreateDialog({ title = "Tooltips", width = 340, height = 130 })

local plain = AlnUI:CreateButton(f, { text = "Hover me" })
plain:SetPoint("TOPLEFT", 24, -50)
AlnUI:AddTooltip(plain, "A tooltip", "With a line of text under the title.")

-- a function makes a tooltip that changes each time it shows;
-- return nil from it to show nothing
local clock = AlnUI:CreateButton(f, { text = "What time is it?", width = 150 })
clock:SetPoint("LEFT", plain, "RIGHT", 8, 0)
AlnUI:AddTooltip(clock, function(self)
    return "The time", date("%H:%M:%S")
end, nil, "ANCHOR_TOP")

f:Show()]==],
    },
    {
        key = "toast", name = "Toast",
        text = "A short notification at the top of the screen that fades in, stays a few seconds "
            .. "and fades out on its own.",
        features = {
            "opts: title, text, icon (shown on the left), sound, theme (default gold), width, height",
            "Themes: any from AlnUI:GetThemes(\"toast\"); the window-only \"basic\" and \"panel\" use \"tooltip\"",
            "opts.fadeIn, opts.duration and opts.fadeOut set the timing in seconds (defaults 0.3, 5 and 1)",
            "Toasts queue up and play one at a time; opts.queue = false shows one right away",
            "AlnUI:GetActiveToast() and AlnUI:GetNumQueuedToasts() report the queue",
            "AlnUI:ClearToasts() hides every toast showing, queued or not, and drops the queue",
            "opts.progress adds a progress bar along the bottom: { value, min, max, color, labelFormat }, \"3 / 10\" by default",
            "Update it while the toast shows through toast.bar, for example toast.bar:SetValue(4) on the next kill",
            "opts.timer = true adds a thin bar along the bottom that runs down until the toast starts to fade",
            "The bars start right of the icon and push the text up a little to make room",
            "Returns the toast frame; toast.alnState is \"queued\", \"showing\" or \"done\"",
        },
        demo = "The Feedback tab: Gold, Standard and No Icon toasts, a Long toast with a countdown bar, "
            .. "a Progress toast that fills as it shows, Queue 3 to queue three, Clear, and a live "
            .. "line showing the queue. /alnui toasts shows every kind of toast in every theme at once.",
        example = function(p)
            local picker
            local function Theme() return PickedTheme(picker, "gold") end

            local show = Lib:CreateButton(p, {
                text    = "Show a toast",
                onClick = function()
                    Lib:ShowToast({
                        title = "Achievement!",
                        text  = "You opened the toast example.",
                        icon  = "Interface\\Icons\\INV_Misc_Coin_01",
                        duration = 3,
                        theme = Theme(),
                    })
                end,
            })
            show:SetPoint("TOPLEFT", 0, 0)
            local queue = Lib:CreateButton(p, {
                text = "Queue 3", width = 90,
                onClick = function()
                    for i = 1, 3 do
                        Lib:ShowToast({ title = "Toast " .. i, text = i .. " of 3", duration = 1.5, theme = Theme() })
                    end
                end,
            })
            queue:SetPoint("LEFT", show, "RIGHT", 8, 0)
            local clear = Lib:CreateButton(p, {
                text = "Clear", width = 80, onClick = function() Lib:ClearToasts() end,
            })
            clear:SetPoint("LEFT", queue, "RIGHT", 8, 0)

            -- the style every toast below uses; picking one shows it
            picker = ThemePicker(p, clear, {
                selected    = "gold",
                kind        = "toast",
                tooltipText = "The theme of the toasts this example shows (opts.theme).",
                onChange    = function(theme)
                    Lib:ShowToast({
                        title    = theme:sub(1, 1):upper() .. theme:sub(2),
                        text     = "Toasts here now use this style.",
                        duration = 2,
                        theme    = theme,
                    })
                end,
            })

            -- a progress bar that fills while the toast shows
            local progress = Lib:CreateButton(p, {
                text    = "Progress toast",
                width   = 140,
                onClick = function()
                    local toast = Lib:ShowToast({
                        title    = "Defias Pillagers slain",
                        icon     = "Interface\\Icons\\INV_Sword_04",
                        duration = 6,
                        progress = { value = 0, max = 10 },
                        theme    = Theme(),
                    })
                    local ticker
                    ticker = C_Timer.NewTicker(0.4, function()
                        if toast.alnState == "done" then ticker:Cancel() return end
                        if toast.alnState ~= "showing" then return end
                        local value = toast.bar:GetValue() + 1
                        toast.bar:SetValue(value)
                        if value >= 10 then ticker:Cancel() end
                    end)
                end,
            })
            progress:SetPoint("TOPLEFT", show, "BOTTOMLEFT", 0, -10)

            -- a countdown bar showing how long the toast has left
            Lib:CreateButton(p, {
                text    = "Countdown toast",
                width   = 140,
                onClick = function()
                    Lib:ShowToast({
                        title    = "Ready check",
                        text     = "Answer before the bar runs out.",
                        duration = 8,
                        timer    = true,
                        theme    = Theme(),
                    })
                end,
            }):SetPoint("LEFT", progress, "RIGHT", 8, 0)

            -- every kind of toast in every theme at once
            local gallery = Lib:CreateButton(p, {
                text        = "Every style",
                width       = 140,
                onClick     = function() ns.ShowToastGallery() end,
                tooltip     = "Toast gallery",
                tooltipText = "Every kind of toast in every theme, side by side (/alnui toasts).",
            })
            gallery:SetPoint("TOPLEFT", progress, "BOTTOMLEFT", 0, -10)
            Lib:CreateButton(p, {
                text = "Clear them", width = 140, onClick = function() Lib:ClearToasts() end,
            }):SetPoint("LEFT", gallery, "RIGHT", 8, 0)
        end,
        code = [==[
-- one toast...
AlnUI:ShowToast({
    title    = "Rare spawned!",
    text     = "Time-Lost Proto-Drake",
    icon     = "Interface\\Icons\\Ability_Mount_Drake_Proto",
    sound    = SOUNDKIT.RAID_WARNING,
    theme    = "gold",
    duration = 5,              -- seconds before it fades out
})

-- ...then three more: they wait their turn and play one at a time
for i = 1, 3 do
    AlnUI:ShowToast({ title = "Queued " .. i, text = i .. " of 3", duration = 1.5 })
end
print(AlnUI:GetNumQueuedToasts())   -- 3 waiting
print(AlnUI:GetActiveToast() ~= nil)  -- true: one is showing

-- AlnUI:ClearToasts() hides the one showing and drops the rest

-- A progress toast: the bar shows "3 / 10"; keep the toast to update it
-- while it shows, for example on the next kill
local quest = AlnUI:ShowToast({
    title    = "Defias Pillagers slain",
    duration = 6,
    progress = { value = 3, max = 10 },   -- also: min, color, labelFormat
})
quest.bar:SetValue(4)                     -- the label follows: "4 / 10"

-- A countdown bar: runs down along the bottom until the toast fades
AlnUI:ShowToast({
    title    = "Ready check",
    text     = "Answer before the bar runs out.",
    duration = 8,
    timer    = true,
})]==],
    },

    {
        key = "replica", name = "Recreating a window",
        text = "A real addon's window rebuilt from AlnUI parts: the order settings of "
            .. "Profession Shopping List. It shows how the components fit together in a "
            .. "window that stays tidy at any size.",
        features = {
            "A resizable dialog in the basic theme: BasicFrameTemplate's art, as the original uses",
            "A label anchored on both sides, so it rewraps as the window gets wider or narrower",
            "Every row anchored to the one above it, so everything moves down when the text needs another line",
            "Numeric edit boxes with a gold coin texture after each, saving as you type",
            "A dropdown beside the first box, checkboxes with gold labels, and your character in its class color",
            "One settings table that every control reads from and writes to",
            "The Example tab's theme dropdown, not in the original, switches it with frame:SetTheme()",
            "A /shoplist slash command to toggle it, as an addon would have",
        },
        demo = "",
        example = function(p)
            Hint(p, "This runs the Code tab exactly as it is, then opens the window it made. "
                .. "Drag the bottom-right corner to resize it.", 0, 0, PANEL_W)

            -- the window, made by running the Code tab the first time
            local function Window()
                if not _G.AlnUIShoppingList then
                    local fn = assert((loadstring or load)(SHOPPING_LIST_CODE, "=replica"))
                    -- AlnUI is this folder's copy, like the rest of this window:
                    -- the global may be an older copy another addon loaded later.
                    -- Everything else reads and writes the real globals.
                    setfenv(fn, setmetatable({ AlnUI = Lib }, { __index = _G, __newindex = _G }))
                    fn()
                end
                return _G.AlnUIShoppingList
            end

            local open = Lib:CreateButton(p, {
                text    = "Open the window",
                width   = 160,
                onClick = function()
                    local f = Window()
                    f:SetShown(not f:IsShown())
                end,
            })
            open:SetPoint("TOPLEFT", 0, -34)

            -- not in the original: try the window in every theme
            ThemePicker(p, open, {
                selected = "basic",
                onChange = function(theme)
                    local f = Window()
                    f:SetTheme(theme)
                    f:Show()
                    f:BringToFront()
                end,
            })
        end,
        code = SHOPPING_LIST_CODE,
    },

    {
        key = "demo", name = "The Demo",
        text = "The Demo window (/alnui demo) shows the AlnUI components working together, for "
            .. "checking by eye what the tests cannot: textures, fonts, spacing and dragging. "
            .. "(Scroll frames are in the Test window instead.)",
        features = {
            "List tab: a sortable 200-row scroll list with Shuffle, Shuffle + Top and Empty List",
            "Inputs tab: edit boxes, the opacity slider with a numeric box, a radio group, checkboxes and dropdowns",
            "Buttons tab: text buttons in several sizes, enabling and disabling, icon buttons and a changing tooltip",
            "Feedback tab: progress bars (one animated), separators, toasts in each style and bottom tabs",
            "The theme dropdown at the bottom switches the window's theme",
            "The bottom-right grip resizes it; Run Tests runs the tests and Test Window opens the Test window",
            "/alnui demos opens one Demo per theme, overlapping, to compare themes and stacking",
        },
        demo = "",
        example = function(p)
            Lib:CreateButton(p, {
                text = "Open the Demo", width = 140, onClick = function() ns.ToggleDemo() end,
            }):SetPoint("TOPLEFT", 0, 0)
            Lib:CreateButton(p, {
                text = "One per theme", width = 140, onClick = function() ns.ToggleThemeDemos() end,
            }):SetPoint("TOPLEFT", 148, 0)
        end,
        lang = "text",
        code = [==[
/alnui demo     -- toggle the Demo window
/alnui demos    -- toggle one Demo window per theme]==],
    },
    {
        key = "tests", name = "Tests and commands",
        text = "AlniarezUI is the test suite for AlnUI: over 250 automated tests that build every "
            .. "component and check how it behaves, plus the Demo and this Learn window.",
        features = {
            "/alnui opens this window; its bottom row opens the Test window, runs the tests, opens the Demo and shows the toast gallery",
            "/alnui tests opens the Test window; Run shows each result as it happens",
            "/alnui run runs the tests with the saved delay; /alnui fast with none; /alnui stop stops",
            "/alnui delay <seconds> sets the delay between tests (0 to 1)",
            "/alnui copy opens the last results as text you can copy",
            "/alnui demo and /alnui demos open the Demo; /alnui toasts shows every toast style; /alnui learn opens this window too",
            "Tests run against this folder's copy of AlnUI, even when another addon loads a different one",
        },
        demo = "",
        example = function(p)
            Lib:CreateButton(p, {
                text = "Open the Test window", width = 180, onClick = function() ns.TogglePanel() end,
            }):SetPoint("TOPLEFT", 0, 0)
            local run = Lib:CreateButton(p, {
                text = "Run the tests", width = 140, onClick = function() ns.RunTests() end,
            })
            run:SetPoint("TOPLEFT", 188, 0)
            -- the Test window is a dialog too: try it in each theme
            ThemePicker(p, run, {
                selected = "standard",
                onChange = function(theme)
                    if not (AlniarezUIResultsFrame and AlniarezUIResultsFrame:IsShown()) then ns.TogglePanel() end
                    AlniarezUIResultsFrame:SetTheme(theme)
                end,
            })
        end,
        lang = "text",
        code = [==[
/alnui              -- the Learn window (this one)
/alnui tests        -- toggle the Test window
/alnui run          -- run every test
/alnui fast         -- run with no delay
/alnui stop         -- stop after the current test
/alnui delay 0.25   -- seconds between tests
/alnui copy         -- copy the last results
/alnui demo         -- the Demo window
/alnui demos        -- one Demo per theme
/alnui toasts       -- every kind of toast in every theme
/alnui help         -- list the commands]==],
    },
    {
        key = "embedding", name = "Embedding AlnUI",
        text = "AlnUI is one file: copy Libs/AlnUI.lua into your addon and load it before your own "
            .. "files. It is made for Retail and WoW Forever. Parts that need templates some "
            .. "clients lack (tabs, the modern dropdown, the modern and tooltip themes) check for "
            .. "them first.",
        features = {
            "List Libs/AlnUI.lua in your .toc before the files that use AlnUI",
            "Every addon that embeds it shares the global AlnUI table; the newest copy loaded is the one used, whatever the load order",
            "AlnUI.version is the version in use and AlnUI.loadedFrom the addon whose copy it is",
            "So a new version must keep everything older ones offered: add options and functions, never remove or rename them",
            "Constructors take an opts table whose fields are all optional",
            "They return the Blizzard widget itself, with AlnUI's methods added to it",
            "Fields starting with aln are AlnUI's own bookkeeping: read them, do not set them",
            "Libs/AlnUI.lua is organized in numbered sections with a table of contents at the top",
        },
        demo = "",
        example = function(p)
            Hint(p, "Nothing to try here: see the Code tab for the .toc lines.", 0, 0, PANEL_W)
        end,
        lang = "text",
        code = [==[
-- MyAddon.toc ------------------------------------------------
## Interface: 120100, 16001
## Title: My Addon

Libs/AlnUI.lua
MyAddon.lua

-- MyAddon.lua ------------------------------------------------
local f = AlnUI:CreateDialog({ title = "My Addon", width = 360, height = 200 })

AlnUI:CreateLabel(f, { text = "Hello from my addon!" })
    :SetPoint("TOPLEFT", 24, -44)

SLASH_MYADDON1 = "/myaddon"
SlashCmdList.MYADDON = function() f:SetShown(not f:IsShown()) end]==],
    },
}

--------------------------------------------------
-- Groups
--
-- How the Learn window lists the topics: by what you want to do, most
-- useful first. Every topic belongs to exactly one group (the tests check).
--------------------------------------------------

local GROUPS = {
    { name = "Getting started",    topics = { "embedding", "dialog", "themes" } },
    { name = "Windows",            topics = { "resizing", "stacking", "titles", "tabs", "scrollframe" } },
    { name = "Lists and tables",   topics = { "table", "scrolllist" } },
    { name = "Text",               topics = { "label", "tooltip", "separator" } },
    { name = "Buttons and inputs", topics = { "button", "iconbutton", "checkbox", "radiogroup",
                                              "slider", "editbox", "dropdown" } },
    { name = "Status and alerts",  topics = { "progressbar", "toast" } },
    { name = "Examples",           topics = { "replica" } },
    { name = "This addon",         topics = { "demo", "tests" } },
}

-- topics by key, for the groups to look up
local TOPIC_BY_KEY = {}
for _, topic in ipairs(TOPICS) do TOPIC_BY_KEY[topic.key] = topic end

ns.LearnTopics = TOPICS
ns.LearnGroups = GROUPS

--------------------------------------------------
-- Topic windows
--------------------------------------------------

local topicWindows = {}   -- by topic key, made on first open
local learn               -- the Learn window

local function NewPanel(f)
    local p = CreateFrame("Frame", nil, f)
    p:SetPoint("TOPLEFT", PANEL_X, -70)
    p:SetPoint("BOTTOMRIGHT", -PANEL_X, 20)
    return p
end

-- Colors for the About tab: code names and quoted values stand out from
-- the prose around them
local CODE_COLOR   = "|cff9fd8ff"
local STRING_COLOR = "|cffb5e48c"

-- Tints what looks like code in `text`: quoted values ("LEFT"), and names
-- with a dot or colon in them, with their (arguments) if any
-- (opts.onSort(key, ascending), header:GetSort()).
local function Highlight(text)
    text = text:gsub('"[^"]*"', function(q) return STRING_COLOR .. q .. "|r" end)

    local out, pos = {}, 1
    while true do
        local s, e = text:find("[%a_][%w_]+[%.:][%a_][%w_%.:]*", pos)
        if not s then break end
        -- a dot or colon at the end is punctuation, not code
        while text:sub(e, e):match("[%.:]") do e = e - 1 end
        local args = text:match("^%b()", e + 1)
        if args then e = e + #args end
        table.insert(out, text:sub(pos, s - 1))
        table.insert(out, CODE_COLOR .. text:sub(s, e) .. "|r")
        pos = e + 1
    end
    table.insert(out, text:sub(pos))
    return table.concat(out)
end

local ABOUT_GAP    = 6    -- between bullets
local ABOUT_INDENT = 16   -- bullet text, right of its bullet

-- About tab: the explanation, what it can do and where the Demo shows it,
-- on a dark panel and in a scroll frame in case it is long. Returns a
-- function that lays it all out again for a new width.
local function BuildAboutPanel(p, topic)
    local scroll, content = Lib:CreateScrollFrame(p, { x2 = -16 })
    local bg = scroll:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", -6, 6)
    bg:SetPoint("BOTTOMRIGHT", 4, -6)
    bg:SetColorTexture(0, 0, 0, 0.45)

    -- what to lay out, top to bottom
    local items = {}
    local function Text(text, font, gap)
        local fs = Lib:CreateLabel(content, { text = Highlight(text), font = font })
        fs:SetSpacing(2)
        table.insert(items, { fs = fs, gap = gap })
    end
    local function Heading(text)
        local fs = Lib:CreateLabel(content, { text = text, font = "GameFontNormalLarge" })
        local line = content:CreateTexture(nil, "ARTWORK")
        line:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.35)
        line:SetHeight(1)
        table.insert(items, { fs = fs, line = line, gap = 8 })
    end
    local function Bullet(text)
        local fs = Lib:CreateLabel(content, { text = Highlight(text) })
        fs:SetSpacing(2)
        local dot = content:CreateTexture(nil, "ARTWORK")
        dot:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 1)
        dot:SetSize(4, 4)
        table.insert(items, { fs = fs, dot = dot, gap = ABOUT_GAP })
    end

    Text(topic.text, "GameFontHighlight", 16)
    Heading("What it can do")
    for _, feature in ipairs(topic.features) do Bullet(feature) end
    if topic.demo ~= "" then
        items[#items].gap = 16
        Heading("In the Demo")
        Text(topic.demo, "GameFontHighlight", 0)
    end

    return function(width)
        content:SetWidth(width)
        local y = -4
        for _, item in ipairs(items) do
            local fs = item.fs
            fs:ClearAllPoints()
            if item.dot then
                fs:SetWidth(width - ABOUT_INDENT - 4)
                fs:SetPoint("TOPLEFT", ABOUT_INDENT, y)
                item.dot:SetPoint("TOPLEFT", 4, y - 5)
            else
                fs:SetWidth(width - 8)
                fs:SetPoint("TOPLEFT", 4, y)
            end
            y = y - fs:GetStringHeight()
            if item.line then
                item.line:SetPoint("TOPLEFT", 4, y - 3)
                item.line:SetPoint("TOPRIGHT", -4, y - 3)
                y = y - 4
            end
            y = y - item.gap
        end
        content:SetHeight(-y + 4)
    end
end

-- Code tab: read-only, copyable code. Returns the box and a function that
-- fits it to a new width.
local function BuildCodePanel(p, topic)
    Hint(p, topic.lang == "text"
        and "Click the text, then Ctrl+A and Ctrl+C to copy it."
        or "Runs as it is in a file loaded after Libs/AlnUI.lua. Click it, then Ctrl+A and Ctrl+C to copy.",
        0, 0, PANEL_W)
    local scroll, box = Lib:CreateScrollFrame(p, {
        y1 = -20, x2 = -16, contentWidth = PANEL_W - 24, childType = "EditBox",
    })
    local bg = scroll:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", -4, 4)
    bg:SetPoint("BOTTOMRIGHT", 4, -4)
    bg:SetColorTexture(0, 0, 0, 0.45)

    box:SetMultiLine(true)
    box:SetAutoFocus(false)
    box:SetFontObject(GameFontHighlightSmall)
    box:SetText(topic.code)
    box:SetCursorPosition(0)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    -- undo any typing, so the code stays as it is
    box:SetScript("OnTextChanged", function(self, userInput)
        if userInput then self:SetText(topic.code) end
    end)
    return box, function(width) box:SetWidth(width) end
end

-- the width of a topic window's scrolling content, for a window `w` wide:
-- the panel's insets, and room on the right for the scroll bar
local function ContentWidth(w)
    return w - 2 * PANEL_X - 24
end

-- Builds the window for `topic`: About, Example and Code tabs. The window
-- can be resized; the About text and the code reflow to fit.
local function BuildTopicWindow(topic)
    local f = Lib:CreateDialog({
        name      = "AlniarezUILearn_" .. topic.key,
        title     = topic.name,
        width     = TOPIC_WIDTH,
        height    = TOPIC_HEIGHT,
        strata    = "DIALOG",
        resizable = true,
        minWidth  = 460,
        minHeight = 360,
        maxWidth  = 1100,
        maxHeight = 900,
    })

    local about, example, code = NewPanel(f), NewPanel(f), NewPanel(f)
    local layoutAbout = BuildAboutPanel(about, topic)
    Hint(example, "Try it:", 0, 0)
    local area = CreateFrame("Frame", nil, example)
    area:SetPoint("TOPLEFT", 0, -22)
    area:SetPoint("BOTTOMRIGHT")
    topic.example(area)
    local fitCode
    f.codeBox, fitCode = BuildCodePanel(code, topic)

    local function Reflow()
        local width = ContentWidth(f:GetWidth())
        layoutAbout(width)
        fitCode(width)
    end
    Reflow()
    f:HookScript("OnSizeChanged", Reflow)

    -- top tabs on the line under the title, or bottom tabs below the
    -- window on clients without top tabs
    local style = Lib:HasTabs("top") and "top" or "bottom"
    if Lib:HasTabs(style) then
        local tabs = Lib:CreateTabs(f, {
            tabs   = { "About", "Example", "Code" },
            panels = { about, example, code },
            style  = style,
        })
        if style == "top" then
            tabs:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 20, -64)
        else
            tabs:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 12, 6)
        end
        Lib:CreateSeparator(f, { y = -64, x1 = 16, x2 = -16, color = GOLD })
        f.tabs = tabs
    else
        -- no tabs at all: show the About panel only
        example:Hide()
        code:Hide()
    end

    return f
end

-- The window for `topic`, made on first use
function ns.GetLearnWindow(topic)
    local f = topicWindows[topic.key]
    if not f then
        f = BuildTopicWindow(topic)
        topicWindows[topic.key] = f
    end
    return f
end

-- Opens a topic window beside the Learn window. Each new one opens a
-- little further down, so they do not cover each other exactly.
local opened = 0
local function OpenTopic(topic)
    local f = ns.GetLearnWindow(topic)
    if not f.alnLearnPlaced and learn and learn:GetRight() then
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT",
            learn:GetRight() + 12 + (opened % 6) * 24,
            learn:GetTop() - (opened % 6) * 24)
        f.alnLearnPlaced = true
        opened = opened + 1
    end
    f:Show()
    f:BringToFront()
end

--------------------------------------------------
-- Learn window
--
-- One row per group: its name on the left, its topics' buttons to the
-- right, wrapping onto more rows when there are many.
--------------------------------------------------

local MARGIN      = 24          -- the same on both sides
local GROUP_W     = 130         -- room for the group names
local BUTTON_W    = 150
local BUTTON_GAP  = 8
local PER_ROW     = 3
-- wide enough for the group names and a full row of buttons
local LEARN_WIDTH = 2 * MARGIN + GROUP_W + PER_ROW * BUTTON_W + (PER_ROW - 1) * BUTTON_GAP

local function BuildLearnWindow()
    local f = Lib:CreateDialog({
        name   = "AlniarezUILearnFrame",
        title  = "Learn AlnUI",
        width  = LEARN_WIDTH,
        height = 200,   -- resized below to fit the buttons
        theme  = "gold",
        strata = "DIALOG",
    })

    ns.AddVersionLabel(f)

    Hint(f, "Pick a topic to open a window explaining it: what it can do, where the Demo "
        .. "shows it, an example to try and the code to copy.", MARGIN, -40, LEARN_WIDTH - 2 * MARGIN)

    local y = -80
    f.topicButtons = {}
    for i, group in ipairs(GROUPS) do
        if i > 1 then
            Lib:CreateSeparator(f, { y = y + 6, x1 = MARGIN, x2 = -MARGIN })
        end
        local heading = Heading(f, group.name, MARGIN, y - 5)
        heading:SetWidth(GROUP_W - 8)

        for n, key in ipairs(group.topics) do
            local topic = TOPIC_BY_KEY[key]
            local col = (n - 1) % PER_ROW
            if n > 1 and col == 0 then y = y - 28 end
            local btn = Lib:CreateButton(f, {
                text    = topic.name,
                width   = BUTTON_W,
                onClick = function() OpenTopic(topic) end,
            })
            btn:SetPoint("TOPLEFT", MARGIN + GROUP_W + col * (BUTTON_W + BUTTON_GAP), y)
            f.topicButtons[topic.key] = btn
        end
        y = y - 28 - 12
    end

    -- the rest of the addon: tests and demos, one row along the bottom
    Lib:CreateSeparator(f, { y = y + 6, x1 = MARGIN, x2 = -MARGIN, color = GOLD })
    y = y - 6
    local actions = {
        { "Test Window",    function() ns.TogglePanel() end },
        { "Run Tests",      function() ns.RunTests() end },
        { "Demo",           function() ns.ToggleDemo() end },
        { "Demo per theme", function() ns.ToggleThemeDemos() end },
        { "Toast gallery",  function() ns.ShowToastGallery() end },
    }
    local width = (LEARN_WIDTH - 2 * MARGIN - (#actions - 1) * BUTTON_GAP) / #actions
    f.actionButtons = {}
    for i, action in ipairs(actions) do
        local btn = Lib:CreateButton(f, { text = action[1], width = width, onClick = action[2] })
        btn:SetPoint("TOPLEFT", MARGIN + (i - 1) * (width + BUTTON_GAP), y)
        f.actionButtons[i] = btn
    end
    y = y - 28 - 12

    f:SetHeight(-y + 12)
    return f
end

function ns.ToggleLearn()
    learn = learn or BuildLearnWindow()
    learn:SetShown(not learn:IsShown())
end

-- the Learn window, made on first use (for the tests)
function ns.GetLearnFrame()
    learn = learn or BuildLearnWindow()
    return learn
end
