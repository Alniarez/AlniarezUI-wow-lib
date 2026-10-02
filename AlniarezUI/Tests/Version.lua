-- AlniarezUI/Tests/Version.lua
-- The version check at the top of Libs/AlnUI.lua: the newest copy loaded
-- is the one used. Loading the file again cannot be done from inside the
-- game, so the load-order cases are checked outside it; these tests check
-- what the game can see.

local ADDON_NAME, ns = ...
local T, A, Lib = ns.T, ns.A, ns.Lib

T:Describe("AlnUI version", function()

    T:It("has a version number", function()
        A.Equal(type(Lib.version), "number", "type of AlnUI.version")
        -- 1 is every copy from before the version number, so this one is newer
        A.True(Lib.version >= 2, "AlnUI.version is at least 2")
    end)

    T:It("records which addon's copy is in use", function()
        A.Equal(type(Lib.loadedFrom), "string", "type of AlnUI.loadedFrom")
    end)

    T:It("tests this folder's copy of AlnUI", function()
        A.True(ns.TestsOwnLibrary, "the suite is testing the copy from " .. tostring(Lib.loadedFrom)
            .. ", not " .. ADDON_NAME .. "'s own Libs/AlnUI.lua")
    end)

    T:It("shows the version in the main windows", function()
        A.True(ns.VersionText():find("AlnUI v" .. Lib.version, 1, true) ~= nil, "VersionText")
        local learn = ns.GetLearnFrame()
        A.Type(learn.versionLabel, "FontString", "Learn window's version label")
        A.Equal(learn.versionLabel:GetText(), ns.VersionText(), "Learn window's version text")
    end)

    T:It("never tests a copy newer than the one in use", function()
        A.True(AlnUI.version >= Lib.version, "the global AlnUI is never older than the snapshot")
    end)
end)
