-- AlniarezUI/Demo.lua
-- A gallery window that uses every AlnUI widget, for checking by eye
-- what the automated tests can't: textures, fonts, spacing, dragging.
-- Four tabs: List, Inputs, Buttons, Feedback.

local _, ns = ...
local Lib = ns.Lib

local demo

local GOLD = { 1, 0.82, 0 }
local GREY = { 0.7, 0.7, 0.7 }

--------------------------------------------------
-- Helpers
--------------------------------------------------

-- Gold section heading at (x, y) inside `panel`
local function Heading(panel, text, x, y)
    local fs = Lib:CreateLabel(panel, { text = text, font = "GameFontNormal" })
    fs:SetPoint("TOPLEFT", x, y)
    return fs
end

-- Small grey hint text at (x, y) inside `panel`
local function Hint(panel, text, x, y, width)
    local fs = Lib:CreateLabel(panel, {
        text = text, font = "GameFontHighlightSmall", color = GREY, width = width,
    })
    fs:SetPoint("TOPLEFT", x, y)
    return fs
end

local function NewPanel(parent)
    local p = CreateFrame("Frame", nil, parent)
    p:SetPoint("TOPLEFT", 16, -66)
    p:SetPoint("BOTTOMRIGHT", -16, 50)
    return p
end

--------------------------------------------------
-- List tab: column row, separator, scroll list
--------------------------------------------------

local MOB_NAMES = {
    "Defias Pillager", "Murloc Tidehunter", "Kobold Tunneler", "Harvest Golem",
    "Riverpaw Gnoll", "Young Wolf", "Stonetusk Boar", "Mangy Wolf",
    "Rockjaw Trogg", "Frostmane Troll Whelp", "Vile Familiar", "Mottled Boar",
    "Scorpid Worker", "Plainstrider", "Kobold Vermin", "Defias Thug",
    "A mob with a very long name that should be cut off",
}

-- 200 rows, so the list has plenty to scroll and recycle
local function SampleRows()
    local rows = {}
    for i = 1, 200 do
        local char  = math.random(1, 60)
        local total = char + math.random(0, 120)
        -- [4] is not a column: it keeps the default (generated) order
        rows[i] = { MOB_NAMES[(i - 1) % #MOB_NAMES + 1] .. " #" .. i, char, total, i }
    end
    return rows
end

-- Sort keys are column indexes: 1 = Mob, 2 = Character, 3 = Total.
-- nil means unsorted: the default order the rows were generated in.
local sortKey, sortAscending = nil, nil

local function SortRows(rows)
    table.sort(rows, function(a, b)
        if sortKey == nil then return a[4] < b[4] end
        local x, y = a[sortKey], b[sortKey]
        if sortKey == 1 then x, y = x:lower(), y:lower() end
        if x == y then return a[1] < b[1] end   -- names are unique: a stable order
        if sortAscending then return x < y end
        return x > y
    end)
    return rows
end

local function BuildListTab(p)
    local list
    local rows = SampleRows()

    -- Click a column: ascending, again: descending, again: default order.
    -- Mob fills the width left over, so the list follows the window size.
    -- right = 26: the list's 22 inset for the scroll bar + the rows' 4
    Lib:CreateSortHeader(p, {
        x = 8, y = -4, right = 26,
        sortKey   = sortKey,
        ascending = sortAscending,
        onSort    = function(key, ascending)
            sortKey, sortAscending = key, ascending
            list:SetData(SortRows(rows), true)
        end,
    }, {
        { text = "Mob",       key = 1, fill = true },
        { text = "Character", key = 2, width = 90, justify = "RIGHT" },
        { text = "Total",     key = 3, width = 90, justify = "RIGHT", gap = 6 },
    })

    Lib:CreateSeparator(p, { y = -22, x1 = 2, x2 = -2 })

    list = Lib:CreateScrollList(p, {
        x1 = 2,   y1 = -26,
        x2 = -22, y2 = 36,
        rowHeight = 18,
        x         = 6,
        right     = 4,
        columns   = {
            { fill = true, wordWrap = false },
            { width = 90, justify = "RIGHT" },
            { width = 90, justify = "RIGHT", gap = 6 },
        },
        data      = SortRows(rows),
        -- highlight rows with a high total; rows are recycled, so always set it
        onRowInit = function(row, data)
            local hot = data[3] >= 150
            row.cols[3]:SetTextColor(1, hot and 0.5 or 1, hot and 0.2 or 1)
        end,
    })

    local shuffle = Lib:CreateButton(p, {
        text        = "Shuffle",
        onClick     = function()
            rows = SampleRows()
            list:SetData(SortRows(rows))
        end,
        tooltip     = "Shuffle",
        tooltipText = "Replace all 200 rows. Keeps the scroll position.",
    })
    shuffle:SetPoint("BOTTOMLEFT", 0, 4)

    local top = Lib:CreateButton(p, {
        text    = "Shuffle + Top",
        onClick = function()
            rows = SampleRows()
            list:SetData(SortRows(rows), true)
        end,
        tooltip = "Shuffle and scroll back to the top",
    })
    top:SetPoint("LEFT", shuffle, "RIGHT", 8, 0)

    local clear = Lib:CreateButton(p, {
        text    = "Empty List",
        onClick = function()
            rows = {}
            list:SetData(rows)
        end,
    })
    clear:SetPoint("LEFT", top, "RIGHT", 8, 0)
end

--------------------------------------------------
-- Inputs tab: edit boxes, slider, checkboxes, radio group
--------------------------------------------------

local function BuildInputsTab(p, frame)
    Heading(p, "Edit boxes", 8, -4)

    local greeting = Hint(p, "Type a name and press Enter.", 12, -52, 220)

    local name = Lib:CreateEditBox(p, {
        label          = "Name",
        width          = 200,
        maxLetters     = 24,
        onEnterPressed = function(text)
            greeting:SetText(text ~= "" and ("Hello, " .. text .. "!") or "Type a name and press Enter.")
        end,
    })
    name:SetPoint("TOPLEFT", 14, -32)

    local live = Hint(p, "Typed: 0 letters", 262, -52, 220)
    local lettersBox = Lib:CreateEditBox(p, {
        label         = "Counts as you type",
        width         = 200,
        onTextChanged = function(text) live:SetText("Typed: " .. #text .. " letters") end,
    })
    lettersBox:SetPoint("TOPLEFT", 268, -32)

    Lib:CreateSeparator(p, { y = -74, x1 = 2, x2 = -2 })

    -- Slider + numeric box that drive the demo window's opacity
    Heading(p, "Slider and numeric box", 8, -84)

    local opacityBox
    local slider = Lib:CreateSlider(p, {
        width       = 200,
        min         = 30,
        max         = 100,
        step        = 5,
        labelFormat = "Opacity: %d%%",
        onChange    = function(v)
            frame:SetAlpha(v / 100)
            if opacityBox and not opacityBox:HasFocus() then opacityBox:SetText(tostring(v)) end
        end,
        value       = 100,
    })
    slider:SetPoint("TOPLEFT", 14, -110)

    opacityBox = Lib:CreateEditBox(p, {
        label          = "Opacity % (30-100, Enter)",
        width          = 60,
        numeric        = true,
        maxLetters     = 3,
        text           = "100",
        onEnterPressed = function(text)
            local v = tonumber(text)
            if v then slider:SetValue(math.max(30, math.min(100, v))) end
        end,
    })
    opacityBox:SetPoint("TOPLEFT", 268, -110)

    Lib:CreateSeparator(p, { y = -152, x1 = 2, x2 = -2 })

    -- Radio group + checkboxes
    Heading(p, "Radio group", 8, -162)

    local picked = Hint(p, "Picked: Warrior", 12, -276)
    local classes = Lib:CreateRadioGroup(p, {
        options  = {
            { value = "WARRIOR", label = "Warrior" },
            { value = "MAGE",    label = "Mage" },
            { value = "PRIEST",  label = "Priest" },
            { value = "ROGUE",   label = "Rogue" },
        },
        selected = "WARRIOR",
        onChange = function(v) picked:SetText("Picked: " .. v:sub(1, 1) .. v:sub(2):lower()) end,
    })
    classes:SetPoint("TOPLEFT", 12, -180)

    Heading(p, "Checkboxes", 262, -162)

    local state = Hint(p, "", 266, -276, 220)
    local boxes = {}
    local function UpdateState()
        local on = {}
        for _, cb in ipairs(boxes) do
            if cb:GetChecked() then table.insert(on, cb.label:GetText()) end
        end
        state:SetText("On: " .. (#on > 0 and table.concat(on, ", ") or "none"))
    end

    local labels = { "Plain", "Starts checked", "With tooltip" }
    for i, text in ipairs(labels) do
        local cb = Lib:CreateCheckbox(p, {
            label       = text,
            checked     = i == 2,
            onChange    = UpdateState,
            tooltip     = i == 3 and "Checkbox tooltip" or nil,
            tooltipText = i == 3 and "Checkboxes take tooltip and tooltipText too." or nil,
        })
        cb:SetPoint("TOPLEFT", 262, -176 - (i - 1) * 26)
        boxes[i] = cb
    end
    UpdateState()

    Lib:CreateSeparator(p, { y = -296, x1 = 2, x2 = -2 })

    Heading(p, "Dropdowns", 8, -306)

    if not Lib:HasDropdown() then
        Hint(p, "This client has no modern dropdown (WowStyle1DropdownTemplate).", 12, -330, 480)
        return
    end

    local zoneText = Hint(p, "Zone: Elwynn Forest", 12, -366)
    Lib:CreateDropdown(p, {
        label    = "Zone",
        width    = 200,
        options  = { "Elwynn Forest", "Westfall", "Redridge Mountains", "Duskwood", "Stranglethorn Vale" },
        selected = "Elwynn Forest",
        onChange = function(v) zoneText:SetText("Zone: " .. v) end,
    }):SetPoint("TOPLEFT", 12, -336)

    -- starts empty; its options are swapped by the button next to it
    local sets = {
        { "Small", "Medium", "Large" },
        { "Red", "Green", "Blue", "Purple" },
    }
    local set = 1
    local swap = Lib:CreateDropdown(p, {
        label       = "Placeholder + SetOptions",
        width       = 150,
        options     = sets[set],
        placeholder = "Pick one...",
        tooltip     = "Dropdown tooltip",
        tooltipText = "Dropdowns take tooltip and tooltipText too.",
    })
    swap:SetPoint("TOPLEFT", 262, -336)

    local swapBtn = Lib:CreateButton(p, {
        text    = "Swap",
        width   = 60,
        height  = 22,
        onClick = function()
            set = set % #sets + 1
            swap:SetValue(nil)
            swap:SetOptions(sets[set])
        end,
    })
    swapBtn:SetPoint("LEFT", swap, "RIGHT", 6, 0)
end

--------------------------------------------------
-- Buttons tab: text buttons, icon buttons, tooltips
--------------------------------------------------

local ICONS = {
    { "Interface\\Icons\\INV_Sword_04",          "Sword",   "A sharp sword." },
    { "Interface\\Icons\\INV_Shield_06",         "Shield",  "Blocks things." },
    { "Interface\\Icons\\INV_Staff_08",          "Staff",   "For casters." },
    { "Interface\\Icons\\INV_Misc_Bag_08",       "Bag",     "Holds loot." },
    { "Interface\\Icons\\INV_Potion_54",         "Potion",  "Restores health." },
    { "Interface\\Icons\\Spell_Holy_Heal",       "Heal",    "Heals a friend." },
    { "Interface\\Icons\\Spell_Fire_Fireball02", "Fireball", "Burns an enemy." },
    { "Interface\\Icons\\INV_Misc_Coin_01",      "Gold",    "Shiny." },
}

local function BuildButtonsTab(p)
    Heading(p, "Text buttons", 8, -4)

    local clicks = 0
    local clickText = Hint(p, "Clicked 0 times", 12, -58)

    local clickMe = Lib:CreateButton(p, {
        text        = "Click Me",
        tooltip     = "Click Me",
        tooltipText = "Counts your clicks.",
        onClick     = function()
            clicks = clicks + 1
            clickText:SetText("Clicked " .. clicks .. " time" .. (clicks == 1 and "" or "s"))
        end,
    })
    clickMe:SetPoint("TOPLEFT", 8, -24)

    local disabled = Lib:CreateButton(p, {
        text        = "Disabled",
        disabled    = true,
        tooltip     = "Disabled button",
        tooltipText = "Tooltips still show on disabled buttons.",
        onClick     = function() print("|cff33ff99AlniarezUI:|r the formerly disabled button was clicked") end,
    })
    disabled:SetPoint("LEFT", clickMe, "RIGHT", 8, 0)

    local toggle = Lib:CreateButton(p, {
        text    = "Enable It",
        onClick = function(self)
            disabled:SetEnabled(not disabled:IsEnabled())
            self:SetText(disabled:IsEnabled() and "Disable It" or "Enable It")
        end,
    })
    toggle:SetPoint("LEFT", disabled, "RIGHT", 8, 0)

    -- size variants
    local small = Lib:CreateButton(p, { text = "Small", width = 60, height = 20 })
    small:SetPoint("TOPLEFT", 8, -76)
    local wide = Lib:CreateButton(p, { text = "A wide button", width = 200 })
    wide:SetPoint("LEFT", small, "RIGHT", 8, 0)
    local tall = Lib:CreateButton(p, { text = "Tall", width = 80, height = 32 })
    tall:SetPoint("LEFT", wide, "RIGHT", 8, 0)

    Lib:CreateSeparator(p, { y = -118, x1 = 2, x2 = -2 })

    Heading(p, "Icon buttons", 8, -128)
    local picked = Hint(p, "Hover for tooltips, click to pick.", 12, -196)

    local prev
    for i, info in ipairs(ICONS) do
        local b = Lib:CreateIconButton(p, {
            icon        = info[1],
            size        = 36,
            tooltip     = info[2],
            tooltipText = info[3],
            onClick     = function() picked:SetText("Picked: " .. info[2]) end,
        })
        if prev then
            b:SetPoint("LEFT", prev, "RIGHT", 6, 0)
        else
            b:SetPoint("TOPLEFT", 8, -148)
        end
        prev = b
    end

    -- sizes + disabled icon
    Heading(p, "Sizes and disabled", 8, -218)
    local sizes = { 20, 28, 40, 52 }
    prev = nil
    for _, size in ipairs(sizes) do
        local b = Lib:CreateIconButton(p, {
            size    = size,
            icon    = "Interface\\Icons\\INV_Misc_Gem_Pearl_05",
            tooltip = size .. "x" .. size,
        })
        if prev then
            b:SetPoint("BOTTOMLEFT", prev, "BOTTOMRIGHT", 8, 0)
        else
            b:SetPoint("TOPLEFT", 8, -290 + size)
        end
        prev = b
    end

    local off = Lib:CreateIconButton(p, {
        size        = 40,
        icon        = "Interface\\Icons\\INV_Misc_Key_03",
        disabled    = true,
        tooltip     = "Disabled",
        tooltipText = "Greyed out while disabled.",
    })
    off:SetPoint("BOTTOMLEFT", prev, "BOTTOMRIGHT", 24, 0)

    local toggleIcon = Lib:CreateButton(p, {
        text    = "Toggle Key",
        width   = 100,
        onClick = function() off:SetEnabled(not off:IsEnabled()) end,
    })
    toggleIcon:SetPoint("LEFT", off, "RIGHT", 12, 0)

    -- dynamic tooltip
    Heading(p, "Dynamic tooltip", 8, -304)
    local hoverCount = 0
    local dynamic = Lib:CreateButton(p, { text = "Hover Me", width = 120 })
    Lib:AddTooltip(dynamic, function()
        hoverCount = hoverCount + 1
        return "Hovered " .. hoverCount .. " time" .. (hoverCount == 1 and "" or "s"),
            "The text comes from a function, so it can change. Time: " .. date("%H:%M:%S")
    end)
    dynamic:SetPoint("TOPLEFT", 8, -322)
end

--------------------------------------------------
-- Feedback tab: progress bars, separators, toasts
--------------------------------------------------

local function BuildFeedbackTab(p)
    Heading(p, "Progress bars", 8, -4)

    local xp = Lib:CreateProgressBar(p, {
        width = 300, height = 18, max = 1000, value = 350, labelFormat = "XP %d / %d",
        color = { 0.58, 0, 0.55 },
    })
    xp:SetPoint("TOPLEFT", 8, -24)

    local function Step(delta)
        local _, max = xp:GetMinMaxValues()
        xp:SetValue(math.max(0, math.min(max, xp:GetValue() + delta)))
    end

    local minus = Lib:CreateButton(p, { text = "-100", width = 56, height = 20, onClick = function() Step(-100) end })
    minus:SetPoint("LEFT", xp, "RIGHT", 10, 0)
    local plus = Lib:CreateButton(p, { text = "+100", width = 56, height = 20, onClick = function() Step(100) end })
    plus:SetPoint("LEFT", minus, "RIGHT", 4, 0)

    local health = Lib:CreateProgressBar(p, {
        width = 300, height = 14, value = 72, labelFormat = "%d%%", color = { 0.8, 0.1, 0.1 },
    })
    health:SetPoint("TOPLEFT", 8, -50)

    local plain = Lib:CreateProgressBar(p, { width = 300, height = 8, value = 40 })
    plain:SetPoint("TOPLEFT", 8, -72)
    Hint(p, "No label", 316, -70)

    -- animated bar
    local cast = Lib:CreateProgressBar(p, {
        width = 300, height = 16, max = 2.5, labelFormat = "Casting... %.1f / %.1fs",
        color = { 1, 0.7, 0 },
    })
    cast:SetPoint("TOPLEFT", 8, -90)

    local castBtn = Lib:CreateButton(p, { text = "Cast", width = 116, height = 20 })
    castBtn:SetPoint("LEFT", cast, "RIGHT", 10, 0)
    castBtn:SetScript("OnClick", function(self)
        self:Disable()
        cast:SetValue(0)
        cast:SetScript("OnUpdate", function(bar, elapsed)
            local v = bar:GetValue() + elapsed
            local _, max = bar:GetMinMaxValues()
            if v >= max then
                bar:SetValue(max)
                bar:SetScript("OnUpdate", nil)
                self:Enable()
            else
                bar:SetValue(v)
            end
        end)
    end)

    Lib:CreateSeparator(p, { y = -120, x1 = 2, x2 = -2 })

    Heading(p, "Separators", 8, -130)
    local seps = {
        { "Default (1px grey)", {} },
        { "2px gold",           { thickness = 2, color = GOLD } },
        { "4px red, inset",     { thickness = 4, color = { 0.8, 0.1, 0.1, 0.8 }, x1 = 60, x2 = -60 } },
        { "1px white, faint",   { color = { 1, 1, 1, 0.2 } } },
    }
    for i, s in ipairs(seps) do
        local y = -150 - (i - 1) * 22
        Hint(p, s[1], 12, y)
        local o = s[2]
        o.y  = y - 16
        o.x1 = (o.x1 or 0) + 8
        o.x2 = (o.x2 or 0) - 8
        Lib:CreateSeparator(p, o)
    end

    Lib:CreateSeparator(p, { y = -246, x1 = 2, x2 = -2 })

    Heading(p, "Toasts", 8, -256)
    local toasts = {
        { "Gold",     { title = "Gold Toast",     text = "The default theme.", icon = "Interface\\Icons\\INV_Misc_Coin_01" } },
        { "Standard", { title = "Standard Toast", text = "The standard theme.", theme = "standard", icon = "Interface\\Icons\\INV_Misc_Note_01" } },
        { "No Icon",  { title = "No Icon",        text = "Text stays centered." } },
        { "Long",     { title = "Long Toast",     text = "Stays up for 8 seconds.", duration = 8, width = 480 } },
    }

    local function Toast(extra)
        local o = { duration = 3, sound = SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPEN }
        for k, v in pairs(extra) do o[k] = v end
        Lib:ShowToast(o)
    end

    local prev
    local function Place(b)
        if prev then b:SetPoint("LEFT", prev, "RIGHT", 8, 0) else b:SetPoint("TOPLEFT", 8, -276) end
        prev = b
    end

    for _, t in ipairs(toasts) do
        Place(Lib:CreateButton(p, {
            text    = t[1],
            width   = 76,
            onClick = function() Toast(t[2]) end,
        }))
    end

    Place(Lib:CreateButton(p, {
        text        = "Queue 3",
        width       = 76,
        tooltip     = "Queue 3",
        tooltipText = "Shows three toasts one after another.",
        onClick     = function()
            for i = 1, 3 do
                Toast({ title = "Queued Toast " .. i, text = "Toast " .. i .. " of 3.", duration = 1.5 })
            end
        end,
    }))

    Place(Lib:CreateButton(p, {
        text    = "Clear",
        width   = 64,
        onClick = function() Lib:ClearToasts() end,
    }))

    -- live queue status while this tab is open
    local status = Hint(p, "", 70, -258, 400)
    local elapsed = 0
    p:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        if elapsed < 0.1 then return end
        elapsed = 0
        local active = Lib:GetActiveToast()
        status:SetText(string.format("Showing: %s   Queued: %d",
            active and (active.alnOpts.title or "untitled") or "none",
            Lib:GetNumQueuedToasts()))
    end)

    Lib:CreateSeparator(p, { y = -306, x1 = 2, x2 = -2 })

    Heading(p, "Bottom style tabs", 8, -314)

    if not Lib:HasTabs("bottom") then
        Hint(p, "This client has no PanelTabButtonTemplate.", 12, -334, 480)
        return
    end

    -- a small box with bottom tabs hanging under it, like the Character window
    local box = CreateFrame("Frame", nil, p)
    box:SetSize(300, 24)
    box:SetPoint("TOPLEFT", 8, -332)
    local bg = box:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.4)

    local names = { "Character", "Reputation", "Currency" }
    local shown = Lib:CreateLabel(box, { text = "Showing: Character" })
    shown:SetPoint("LEFT", 8, 0)

    Lib:CreateTabs(box, {
        tabs     = names,
        style    = "bottom",
        onSelect = function(i) shown:SetText("Showing: " .. names[i]) end,
    }):SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, 2)
end

--------------------------------------------------
-- Window
--------------------------------------------------

local function BuildDemo()
    local f = Lib:CreateDialog({
        name       = "AlniarezUIDemoFrame",
        title      = "AlnUI Demo",
        titleWidth = 260,
        width      = 540,
        height     = 500,
        theme      = "gold",
        strata     = "DIALOG",
        -- drag the bottom-right grip; the List tab follows the new size
        resizable  = true,
        minWidth   = 540,
        minHeight  = 500,
        maxWidth   = 1000,
        maxHeight  = 800,
    })

    local panels = { NewPanel(f), NewPanel(f), NewPanel(f), NewPanel(f) }
    BuildListTab(panels[1])
    BuildInputsTab(panels[2], f)
    BuildButtonsTab(panels[3])
    BuildFeedbackTab(panels[4])

    -- native top tabs standing on the gold line; bottom tabs below the
    -- window on clients without top tabs
    local style = Lib:HasTabs("top") and "top" or "bottom"
    local tabs = Lib:CreateTabs(f, {
        tabs   = { "List", "Inputs", "Buttons", "Feedback" },
        panels = panels,
        style  = style,
    })
    if style == "top" then
        tabs:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 20, -60)
    else
        tabs:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 12, 6)
    end

    Lib:CreateSeparator(f, { y = -60, x1 = 16, x2 = -16, color = GOLD, thickness = 1 })
    -- anchored to the bottom so it stays above the buttons while resizing
    local bottomLine = Lib:CreateSeparator(f, { x1 = 16, x2 = -16 })
    bottomLine:ClearAllPoints()
    bottomLine:SetPoint("BOTTOMLEFT", 16, 46)
    bottomLine:SetPoint("BOTTOMRIGHT", -16, 46)

    local runBtn = Lib:CreateButton(f, {
        text    = "Run Tests",
        onClick = function() ns.RunTests() end,
    })
    runBtn:SetPoint("BOTTOMRIGHT", -24, 18)

    local testsBtn = Lib:CreateButton(f, {
        text    = "Test Window",
        onClick = function() ns.TogglePanel() end,
    })
    testsBtn:SetPoint("RIGHT", runBtn, "LEFT", -8, 0)

    -- theme switcher, listing every theme the library knows
    if Lib:HasDropdown() then
        local themeLabel = Lib:CreateLabel(f, { text = "Theme:", font = "GameFontNormal" })
        themeLabel:SetPoint("BOTTOMLEFT", 26, 24)

        local options = {}
        for i, name in ipairs(Lib:GetThemes()) do
            options[i] = { value = name, label = name:sub(1, 1):upper() .. name:sub(2) }
        end

        Lib:CreateDropdown(f, {
            width       = 120,
            options     = options,
            selected    = f:GetTheme(),
            onChange    = function(name) f:SetTheme(name) end,
            tooltip     = "Window theme",
            tooltipText = "Switches this window with dialog:SetTheme().",
        }):SetPoint("LEFT", themeLabel, "RIGHT", 8, 0)
    end

    return f
end

function ns.ToggleDemo()
    demo = demo or BuildDemo()
    demo:SetShown(not demo:IsShown())
    -- same strata as the test window, so bring it to the front
    if demo:IsShown() then demo:Raise() end
end
