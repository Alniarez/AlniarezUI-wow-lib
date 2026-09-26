-- AlniarezUI/Tests/EditBox.lua

local _, ns = ...
local T, A, Lib = ns.T, ns.A, ns.Lib

T:Describe("CreateEditBox", function()

    T:It("creates an EditBox with defaults", function()
        local eb = Lib:CreateEditBox(ns.sandbox)
        A.Type(eb, "EditBox")
        A.Near(eb:GetWidth(),  160, "width")
        A.Near(eb:GetHeight(), 20,  "height")
        A.False(eb:IsAutoFocus(), "auto focus")
        A.False(eb:IsNumeric(),   "numeric")
        A.Nil(eb.label, "label")
    end)

    T:It("registers a global name", function()
        local name = ns.UniqueName("EditBox")
        local eb = Lib:CreateEditBox(ns.sandbox, { name = name })
        A.Equal(_G[name], eb, "_G[name]")
    end)

    T:It("applies size and text", function()
        local eb = Lib:CreateEditBox(ns.sandbox, { width = 90, height = 24, text = "hello" })
        A.Near(eb:GetWidth(),  90, "width")
        A.Near(eb:GetHeight(), 24, "height")
        A.Equal(eb:GetText(), "hello", "text")
    end)

    T:It("applies maxLetters", function()
        local eb = Lib:CreateEditBox(ns.sandbox, { maxLetters = 5 })
        A.Equal(eb:GetMaxLetters(), 5, "max letters")
        eb:SetText("1234567")
        A.Equal(eb:GetText(), "12345", "text is cut to maxLetters")
    end)

    T:It("applies numeric", function()
        local eb = Lib:CreateEditBox(ns.sandbox, { numeric = true })
        A.True(eb:IsNumeric(), "numeric")
    end)

    T:It("shows a label above the box", function()
        local eb = Lib:CreateEditBox(ns.sandbox, { label = "Name" })
        A.Type(eb.label, "FontString", "label")
        A.Equal(eb.label:GetText(), "Name", "label text")
        local rel, relPoint = ns.FindPoint(eb.label, "BOTTOMLEFT")
        A.Equal(rel, eb, "label relativeTo")
        A.Equal(relPoint, "TOPLEFT", "label relativePoint")
    end)

    T:It("calls onEnterPressed with the text", function()
        local got
        local eb = Lib:CreateEditBox(ns.sandbox, {
            text           = "abc",
            onEnterPressed = function(text) got = text end,
        })
        eb:GetScript("OnEnterPressed")(eb)
        A.Equal(got, "abc", "onEnterPressed text")
    end)

    T:It("clears focus on Enter and Escape", function()
        local eb = Lib:CreateEditBox(ns.sandbox)
        A.NotNil(eb:GetScript("OnEnterPressed"),  "OnEnterPressed")
        A.NotNil(eb:GetScript("OnEscapePressed"), "OnEscapePressed")
        -- must not error without callbacks
        eb:GetScript("OnEnterPressed")(eb)
        eb:GetScript("OnEscapePressed")(eb)
        A.False(eb:HasFocus(), "has focus")
    end)

    T:It("calls onTextChanged only for player typing", function()
        local calls, got = 0, nil
        local eb = Lib:CreateEditBox(ns.sandbox, {
            onTextChanged = function(text) calls = calls + 1; got = text end,
        })
        eb:SetText("typed")
        local handler = eb:GetScript("OnTextChanged")
        handler(eb, false)
        A.Equal(calls, 0, "calls for code changes")
        handler(eb, true)
        A.Equal(calls, 1, "calls for player typing")
        A.Equal(got, "typed", "onTextChanged text")
    end)
end)
