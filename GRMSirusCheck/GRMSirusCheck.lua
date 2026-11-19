local frame = CreateFrame("Frame")
local pending
local waitTime = 0

local function report(message)
    DEFAULT_CHAT_FRAME:AddMessage("GRM Sirus: " .. message:gsub("[\r\n]", " "):gsub("|", "||"))
end

local function showRoster(cached)
    if not pending or not IsInGuild() then return end

    local total = GetNumGuildMembers(true)
    if not total or total == 0 then return end

    local limit = math.min(total, pending)
    local mayReadOfficerNotes = CanViewOfficerNote and CanViewOfficerNote()
    local members = {}
    for index = 1, limit do
        local name, rank, _, _, _, _, note, officerNote, online =
            GetGuildRosterInfo(index)
        if not name or name == "" then return end

        local line = name .. " [" .. (rank or "?") .. "]"
            .. (online and " онлайн" or " офлайн")
        if note and note ~= "" then
            line = line .. " — заметка: " .. note
        end
        if mayReadOfficerNotes and officerNote and officerNote ~= "" then
            line = line .. " — офицерская: " .. officerNote
        end
        members[index] = line
    end

    pending = nil
    report("В составе: " .. total .. (cached and " (из кэша клиента)" or ""))
    for index = 1, limit do
        report(members[index])
    end
end

frame:RegisterEvent("GUILD_ROSTER_UPDATE")
frame:SetScript("OnEvent", function()
    showRoster(false)
end)

frame:SetScript("OnUpdate", function(_, elapsed)
    if not pending then return end
    waitTime = waitTime + elapsed
    if waitTime >= 10 then
        pending = nil
        report("Состав не получен. Откройте окно гильдии и повторите команду.")
    end
end)

SLASH_GRMSIRUSCHECK1 = "/grmsirus"
SlashCmdList.GRMSIRUSCHECK = function(argument)
    if not IsInGuild() then
        pending = nil
        report("Персонаж не состоит в гильдии.")
        return
    end

    pending = math.max(1, math.min(50, math.floor(tonumber(argument) or 5)))
    waitTime = 0
    GuildRoster()
    showRoster(true)
end
