local pageSize = 12
local rows, members = {}, {}
local page, waiting, status = 1, nil, ""

local window = CreateFrame("Frame", "GRMSirusPersonalWindow", UIParent)
window:SetWidth(550)
window:SetHeight(338)
window:SetPoint("CENTER")
window:SetFrameStrata("DIALOG")
window:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    edgeSize = 24,
    insets = {left = 6, right = 6, top = 6, bottom = 6},
})
window:SetMovable(true)
window:SetClampedToScreen(true)
window:EnableMouse(true)
window:RegisterForDrag("LeftButton")
window:SetScript("OnDragStart", window.StartMoving)
window:SetScript("OnDragStop", window.StopMovingOrSizing)
window:Hide()
tinsert(UISpecialFrames, window:GetName())

local function label(parent, font, x, y, text)
    local field = parent:CreateFontString(nil, "OVERLAY", font)
    field:SetPoint("TOPLEFT", x, y)
    field:SetText(text)
    return field
end

local function button(text, x, y, width)
    local control = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
    control:SetWidth(width)
    control:SetHeight(22)
    control:SetPoint("TOPLEFT", x, y)
    control:SetText(text)
    return control
end

label(window, "GameFontNormalLarge", 20, -15, "Состав гильдии")
local summary = label(window, "GameFontHighlightSmall", 20, -40, "")
local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", -4, -4)
close:SetScript("OnClick", function() window:Hide() end)

local previous = button("Назад", 20, -298, 82)
local nextPage = button("Дальше", 110, -298, 82)
local refresh = button("Обновить", 424, -298, 104)
local pageLabel = label(window, "GameFontHighlightSmall", 208, -303, "")

local function plain(text)
    return (text or ""):gsub("|", "||"):gsub("[\r\n]", " ")
end

for index = 1, pageSize do
    local row = CreateFrame("Button", nil, window)
    row:SetPoint("TOPLEFT", 20, -62 - (index - 1) * 19)
    row:SetWidth(508)
    row:SetHeight(19)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row.text = label(row, "GameFontHighlight", 3, -2, "")
    row:SetScript("OnEnter", function(self)
        local member = self.member
        if not member then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(plain(member.name))
        if member.note ~= "" then
            GameTooltip:AddLine("Заметка: " .. plain(member.note), 1, 1, 1, true)
        end
        if member.officerNote ~= "" and CanViewOfficerNote and CanViewOfficerNote() then
            GameTooltip:AddLine("Офицерская: " .. plain(member.officerNote), 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    rows[index] = row
end

local function render()
    local pages = math.max(1, math.ceil(#members / pageSize))
    page = math.min(page, pages)
    summary:SetText(status)
    pageLabel:SetText(page .. " / " .. pages)
    GameTooltip:Hide()
    for index, row in ipairs(rows) do
        local member = members[(page - 1) * pageSize + index]
        row.member = member
        if member then
            row.text:SetText(plain(member.name) .. "  [" .. plain(member.rankName) .. "]  "
                .. (member.isOnline and "онлайн" or "офлайн"))
            row:Show()
        else
            row:Hide()
        end
    end
    if page > 1 then previous:Enable() else previous:Disable() end
    if page < pages then nextPage:Enable() else nextPage:Disable() end
end

local function readRoster(cached)
    local count = GetNumGuildMembers(true)
    if not count or count == 0 then return end
    local snapshot = {}
    local mayReadNotes = CanViewOfficerNote and CanViewOfficerNote()
    for index = 1, count do
        local name, rank, _, _, _, _, note, officerNote, online = GetGuildRosterInfo(index)
        if not name or name == "" then return end
        snapshot[index] = {
            name = name, rankName = rank or "?", isOnline = online,
            note = note or "", officerNote = mayReadNotes and officerNote or "",
        }
    end
    members = snapshot
    status = "Участников: " .. count .. (cached and " (кэш клиента)" or "")
    render()
    return true
end

local function requestRoster()
    waiting, members, page = nil, {}, 1
    if not IsInGuild() then
        status = "Персонаж не состоит в гильдии."
        render()
        return
    end
    waiting, status = 0, "Загрузка состава…"
    render()
    GuildRoster()
    if waiting then readRoster(true) end
end

window:RegisterEvent("PLAYER_GUILD_UPDATE")
window:RegisterEvent("GUILD_ROSTER_UPDATE")
window:SetScript("OnEvent", function(_, event)
    if not window:IsShown() then return end
    if event == "PLAYER_GUILD_UPDATE" then
        requestRoster()
    elseif IsInGuild() and readRoster(false) then
        waiting = nil
    end
end)
window:SetScript("OnUpdate", function(_, elapsed)
    if not waiting then return end
    waiting = waiting + elapsed
    if waiting >= 10 then
        waiting = nil
        if #members == 0 then
            status = "Состав не получен. Откройте окно гильдии и нажмите «Обновить»."
            render()
        end
    end
end)
window:SetScript("OnHide", function()
    members, waiting = {}, nil
    render()
end)

previous:SetScript("OnClick", function() page = math.max(1, page - 1); render() end)
nextPage:SetScript("OnClick", function() page = page + 1; render() end)
refresh:SetScript("OnClick", requestRoster)
SLASH_GRMSIRUSPERSONAL1 = "/grmpersonal"
SlashCmdList.GRMSIRUSPERSONAL = function()
    if window:IsShown() then window:Hide(); return end
    window:Show()
    requestRoster()
end
