local frame = CreateFrame("Frame")
local pending

local function report(message)
    DEFAULT_CHAT_FRAME:AddMessage("GRM Sirus: " .. message)
end

frame:RegisterEvent("GUILD_ROSTER_UPDATE")
frame:SetScript("OnEvent", function()
    if not pending or not IsInGuild() then return end

    local total = GetNumGuildMembers(true)
    if not total or total == 0 then return end

    local mayReadOfficerNotes = CanViewOfficerNote and CanViewOfficerNote()
    local members = {}
    for index = 1, total do
        local name, rank, _, _, _, _, note, officerNote, online =
            GetGuildRosterInfo(index)
        if not name then return end

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

    local limit = pending
    pending = nil
    report("В составе: " .. total)
    for index = 1, math.min(total, limit) do
        report(members[index])
    end
end)

local waitTime = 0
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
        report("Персонаж не состоит в гильдии.")
        return
    end

    pending = math.max(1, math.min(50, math.floor(tonumber(argument) or 5)))
    waitTime = 0
    GuildRoster()
end
