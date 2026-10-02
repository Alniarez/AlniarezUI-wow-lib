-- AlniarezUI/Tests/Learn.lua
-- Checks the Learn window (/alnui learn): every topic is complete, every
-- public AlnUI function is explained somewhere, and every topic window
-- builds with its example. Learn.lua loads after the tests, so these look
-- its functions up when they run, not when this file loads.

local _, ns = ...
local T, A, Lib = ns.T, ns.A, ns.Lib

-- Everything a topic says, as one string to search
local function TopicText(topic)
    return table.concat({ topic.name, topic.text, table.concat(topic.features, "\n"),
        topic.demo, topic.code }, "\n")
end

T:Describe("Learn window", function()

    T:It("gives every topic all its fields", function()
        local keys = {}
        for i, topic in ipairs(ns.LearnTopics) do
            local label = topic.key or ("topic " .. i)
            for _, field in ipairs({ "key", "name", "text", "demo", "code" }) do
                A.Equal(type(topic[field]), "string", label .. "." .. field)
            end
            A.Equal(type(topic.features), "table", label .. ".features")
            A.True(#topic.features > 0, label .. " lists what it can do")
            A.Equal(type(topic.example), "function", label .. ".example")
            A.Nil(keys[topic.key], label .. " key is unique")
            keys[topic.key] = true
        end
    end)

    T:It("lists every topic in exactly one group", function()
        local known, count = {}, {}
        for _, topic in ipairs(ns.LearnTopics) do known[topic.key] = true end
        for _, group in ipairs(ns.LearnGroups) do
            for _, key in ipairs(group.topics) do
                A.True(known[key], group.name .. " lists a topic that exists: " .. key)
                count[key] = (count[key] or 0) + 1
            end
        end
        for _, topic in ipairs(ns.LearnTopics) do
            A.Equal(count[topic.key], 1, topic.key .. ": groups listing it")
        end
    end)

    T:It("explains every public AlnUI function", function()
        local all = {}
        for _, topic in ipairs(ns.LearnTopics) do table.insert(all, TopicText(topic)) end
        all = table.concat(all, "\n")

        local missing = {}
        for name, value in pairs(Lib) do
            if type(value) == "function" and not all:find(name, 1, true) then
                table.insert(missing, name)
            end
        end
        table.sort(missing)
        A.Equal(table.concat(missing, ", "), "", "functions no topic mentions")
    end)

    T:It("gives every topic Lua code that compiles", function()
        local compile = loadstring or load
        for _, topic in ipairs(ns.LearnTopics) do
            if topic.lang ~= "text" then
                local fn, err = compile(topic.code, "=" .. topic.key)
                A.NotNil(fn, topic.key .. " compiles: " .. tostring(err))
            end
        end
    end)

    T:It("has a button for every topic", function()
        local f = ns.GetLearnFrame()
        for _, topic in ipairs(ns.LearnTopics) do
            local btn = f.topicButtons[topic.key]
            A.Type(btn, "Button", topic.key .. " button")
            A.Equal(btn:GetText(), topic.name, topic.key .. " button text")
        end
    end)

    T:It("builds every topic window with its example", function()
        for _, topic in ipairs(ns.LearnTopics) do
            local ok, f = pcall(ns.GetLearnWindow, topic)
            A.True(ok, topic.key .. " builds: " .. tostring(not ok and f or ""))
            A.Equal(f.titleText:GetText(), topic.name, topic.key .. " title")
            A.Equal(f.codeBox:GetText(), topic.code, topic.key .. " code")
            if Lib:HasTabs("top") or Lib:HasTabs("bottom") then
                A.Equal(#f.tabs.buttons, 3, topic.key .. " About, Example and Code tabs")
            end
        end
    end)

    T:It("lets topic windows resize, reflowing to the new width", function()
        local f = ns.GetLearnWindow(ns.LearnTopics[1])
        A.True(f:IsResizeEnabled(), "IsResizeEnabled")
        local width = f:GetWidth()

        f:SetWidth(width + 200)
        f:GetScript("OnSizeChanged")(f, f:GetWidth(), f:GetHeight())
        local wider = f.codeBox:GetWidth()

        f:SetWidth(width)
        f:GetScript("OnSizeChanged")(f, f:GetWidth(), f:GetHeight())
        A.Near(wider - f.codeBox:GetWidth(), 200, "code box follows the window's width")
    end)

    T:It("keeps the code read-only", function()
        local topic = ns.LearnTopics[1]
        local box = ns.GetLearnWindow(topic).codeBox
        box:SetText("typed over")
        box:GetScript("OnTextChanged")(box, true)
        A.Equal(box:GetText(), topic.code, "code after typing")
    end)
end)
