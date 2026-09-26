-- AlniarezUI/Tests/Dropdown.lua
-- The first test says whether this client has the modern dropdown at all;
-- if it fails, every other test here fails with the same reason.

local _, ns = ...
local T, A, Lib = ns.T, ns.A, ns.Lib

local OPTIONS = {
    { value = "WARRIOR", label = "Warrior" },
    { value = "MAGE",    label = "Mage" },
    { value = "PRIEST",  label = "Priest" },
}

-- The text the closed dropdown shows
local function Shown(dd)
    A.NotNil(dd.Text, "dropdown.Text")
    return dd.Text:GetText() or ""
end

local function New(opts)
    opts = opts or {}
    opts.options = opts.options or OPTIONS
    return Lib:CreateDropdown(ns.sandbox, opts)
end

T:Describe("CreateDropdown", function()

    T:It("client has the modern dropdown", function()
        A.True(Lib:HasDropdown(), "HasDropdown")
    end)

    T:It("creates a dropdown button with defaults", function()
        local dd = New()
        A.Type(dd, "Button")
        A.Near(dd:GetWidth(), 160, "width")
        A.NotNil(dd.SetupMenu, "dropdown:SetupMenu")
        A.Nil(dd.label, "label")
    end)

    T:It("registers a global name", function()
        local name = ns.UniqueName("Dropdown")
        local dd = New({ name = name })
        A.Equal(_G[name], dd, "_G[name]")
    end)

    T:It("applies width", function()
        A.Near(New({ width = 220 }):GetWidth(), 220, "width")
    end)

    T:It("shows a label above the dropdown", function()
        local dd = New({ label = "Class" })
        A.Equal(dd.label:GetText(), "Class", "label text")
        local rel, relPoint = ns.FindPoint(dd.label, "BOTTOMLEFT")
        A.Equal(rel, dd, "label relativeTo")
        A.Equal(relPoint, "TOPLEFT", "label relativePoint")
    end)

    T:It("starts with nothing selected and shows the placeholder", function()
        local dd = New()
        A.Nil(dd:GetValue(), "value")
        A.Equal(Shown(dd), "Select...", "shown text")
    end)

    T:It("applies a custom placeholder", function()
        A.Equal(Shown(New({ placeholder = "Pick a class" })), "Pick a class", "shown text")
    end)

    T:It("shows the initially selected option", function()
        local dd = New({ selected = "MAGE" })
        A.Equal(dd:GetValue(), "MAGE", "value")
        A.Equal(Shown(dd), "Mage", "shown text")
    end)

    T:It("changes selection silently with SetValue", function()
        local calls = 0
        local dd = New({ onChange = function() calls = calls + 1 end })
        dd:SetValue("PRIEST")
        A.Equal(dd:GetValue(), "PRIEST", "value")
        A.Equal(Shown(dd), "Priest", "shown text")
        A.Equal(calls, 0, "onChange calls")
    end)

    T:It("fires onChange from Choose only when the value changes", function()
        local calls, got = 0, nil
        local dd = New({
            selected = "WARRIOR",
            onChange = function(v) calls = calls + 1; got = v end,
        })
        dd:Choose("MAGE")
        A.Equal(calls, 1, "onChange calls")
        A.Equal(got, "MAGE", "onChange value")
        A.Equal(Shown(dd), "Mage", "shown text")
        dd:Choose("MAGE")
        A.Equal(calls, 1, "onChange calls after choosing the same value")
    end)

    T:It("accepts plain values as options", function()
        local dd = New({ options = { "Small", "Large" }, selected = "Large" })
        A.Equal(Shown(dd), "Large", "shown text")
    end)

    T:It("replaces options with SetOptions", function()
        local dd = New({ selected = "MAGE" })
        dd:SetOptions({ { value = "MAGE", label = "Mage (renamed)" }, { value = "ROGUE", label = "Rogue" } })
        A.Equal(Shown(dd), "Mage (renamed)", "shown text after SetOptions")
        dd:SetValue("ROGUE")
        A.Equal(Shown(dd), "Rogue", "shown text for a new option")
    end)

    T:It("adds a tooltip", function()
        local dd = New({ tooltip = "Class", tooltipText = "Pick one" })
        A.Equal(dd.alnTooltip.title, "Class", "tooltip title")
    end)

    T:It("opens and closes its menu", function()
        local host = CreateFrame("Frame", nil, UIParent)
        host:SetSize(200, 40)
        host:SetPoint("CENTER")
        host:SetAlpha(0)
        host:Show()

        local ok, err = pcall(function()
            local dd = Lib:CreateDropdown(host, { options = OPTIONS })
            dd:SetPoint("CENTER")
            dd:OpenMenu()
            A.True(dd:IsMenuOpen(), "menu open")
            dd:CloseMenu()
            A.False(dd:IsMenuOpen(), "menu open after close")
        end)
        host:Hide()
        if not ok then error(err, 0) end
    end)
end)
