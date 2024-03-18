local MultipleMarkAndRecall = {}

local scriptName = "MultipleMarkAndRecall"
local logPrefix = "[MMAR]: "

local Mysticism = "Mysticism"
local teleportForbidden = {
    "Akulakhan's Chamber",
    "Sotha Sil,", "Solstheim, Mortrag Glacier: Entry", "Solstheim, Mortrag Glacier: Outer Ring",
    "Solstheim, Mortrag Glacier: Inner Ring", "Solstheim, Mortrag Glacier: Huntsman's Hall"
}

MultipleMarkAndRecall.guis = {
    markInputDialog = 31102,
    recallList = 31103,
    markSelection = 31104,
    markDelete = 31105
}

MultipleMarkAndRecall.defaultConfig = {
    maxMarks = 18,
    msgMark = color.Green .. "The mark \"%s\" has been set!" .. color.Default,
    msgMarkRm = color.Green .. "The mark \"%s\" has been deleted!" .. color.Default,
    msgNotAllowed = color.Red .. "Teleportation is not allowed here!" .. color.Default,
    msgRecall = color.Green .. "Recalled to: \"%s\"!" .. color.Default,
    over10mod = 2,
    over50mod = 7,
    spellMagickaCost = 12,
    teleportForbidden = teleportForbidden
}

if DataManager then
    MultipleMarkAndRecall.config = DataManager.loadConfiguration(scriptName, MultipleMarkAndRecall.defaultConfig)
else
    MultipleMarkAndRecall.config = MultipleMarkAndRecall.defaultConfig
end

math.randomseed(os.time())

local function dbg(msg)
    tes3mp.LogMessage(enumerations.log.VERBOSE, logPrefix .. msg)
end

local function fatal(msg)
   tes3mp.LogMessage(enumerations.log.FATAL, logPrefix .. msg)
end

local function warn(msg)
    tes3mp.LogMessage(enumerations.log.WARN, logPrefix .. msg)
end

local function info(msg)
    tes3mp.LogMessage(enumerations.log.INFO, logPrefix .. msg)
end

-- Check for new settings that may not be present
if MultipleMarkAndRecall.config.over10mod == nil then
    warn("No 'over10mod' value was found in your config!")
    warn("Please set that, the default of '2' is being used.")
    MultipleMarkAndRecall.config.over10mod = 2
end
if MultipleMarkAndRecall.config.over50mod == nil then
    warn("No 'over50mod' value was found in your config!")
    warn("Please set that, the default of '7' is being used.")
    MultipleMarkAndRecall.config.over50mod = 7
end

local function chatMsg(pid, msg)
    dbg("Called chatMsg for pid: " .. pid .. " and msg: " .. msg)
   tes3mp.SendMessage(pid, "[MMAR]: " .. msg .. "\n")
end

local function canTeleport(pid)
    dbg("Called canTeleport for pid: " .. pid)
    local currentCell = tes3mp.GetCell(pid)
    if tableHelper.containsValue(MultipleMarkAndRecall.config.teleportForbidden, currentCell) then
        return false
    end
    return true
end

local function doRecall(pid, name)
    dbg("Called doRecall for pid: " .. pid .. " and name: " .. name)
    local player = Players[pid]

    if not canTeleport(pid) then
        chatMsg(pid, MultipleMarkAndRecall.config.msgNotAllowed)
        return
    end

    local mark = player.data.customVariables.MultipleMarkAndRecall.marks[name]

    player.data.location.cell = mark.cell
    player.data.location.posX = mark.x
    player.data.location.posY = mark.y
    player.data.location.posZ = mark.z
    player.data.location.rotZ = mark.rot

    player:LoadCell()
    chatMsg(pid, string.format(MultipleMarkAndRecall.config.msgRecall, name))
end

local function getMarkCount(pid)
    dbg("Called getMarkCount for pid: " .. pid)
    local extraMarks = 0
    local markCount = 2
    local mysticism = Players[pid].data.skills[Mysticism].base
    local totalMarks

    if mysticism >= 50 then
        local count = math.floor((mysticism - 50) / 5) + MultipleMarkAndRecall.config.over50mod
        extraMarks = extraMarks + count

    elseif mysticism >= 10 then
        extraMarks = math.floor(mysticism / 10) + MultipleMarkAndRecall.config.over10mod

    else
        extraMarks = 0
    end

    totalMarks = markCount + extraMarks

    if totalMarks > MultipleMarkAndRecall.config.maxMarks then
        totalMarks = MultipleMarkAndRecall.config.maxMarks
    end

    return totalMarks
end

local function rmMark(pid, name)
    dbg("Called rmMark for pid: " .. pid .. " and name: " .. name)
    local player = Players[pid]
    player.data.customVariables.MultipleMarkAndRecall.marks[name] = nil
    tableHelper.cleanNils(player.data.customVariables.MultipleMarkAndRecall.marks)
    chatMsg(pid, string.format(MultipleMarkAndRecall.config.msgMarkRm, name))
end

local function setMark(pid, name)
    dbg("Called setMark for pid: " .. pid .. " and name: " .. name)
    local player = Players[pid]

    player.data.customVariables.MultipleMarkAndRecall.marks[name] = {
        cell = tes3mp.GetCell(pid),
        x = tes3mp.GetPosX(pid),
        y = tes3mp.GetPosY(pid),
        z = tes3mp.GetPosZ(pid),
        rot = tes3mp.GetRotZ(pid)
    }

    chatMsg(pid, string.format(MultipleMarkAndRecall.config.msgMark, name))
end

MultipleMarkAndRecall.OnServerPostInit = function()
    local recordStore = RecordStores.spell.data
    local id = "mmar_mark"
    recordStore.permanentRecords[id] = {
        name = "[MMAR] Mark",
        subtype = 0,
        cost = MultipleMarkAndRecall.config.spellMagickaCost,
        effects = {{
            attribute = -1,
            area = 0,
            duration = 0,
            id = 68,
            rangeType = 0,
            skill = -1,
            magnitudeMin = 0,
            magnitudeMax = 0
        }}
    }
    id = "mmar_recall"
    recordStore.permanentRecords[id] = {
        name = "[MMAR] Recall",
        subtype = 0,
        cost = MultipleMarkAndRecall.config.spellMagickaCost,
        effects = {{
            attribute = -1,
            area = 0,
            duration = 0,
            id = 68,
            rangeType = 0,
            skill = -1,
            magnitudeMin = 0,
            magnitudeMax = 0
        }}
    }
end

MultipleMarkAndRecall.updateOldSpells = function(pid)
    local player = Players[pid]
    local markChange = false
    local recallChange = false
        
    for _, spellId in pairs(player.data.spellbook) do
        if spellId == "mark" then
            markChange = true
        elseif spellId == "recall" then
            recallChange = true
        end
    end
    if markChange then
        logicHandler.RunConsoleCommandOnPlayer(pid, "player->removespell mark", false)
        logicHandler.RunConsoleCommandOnPlayer(pid, "player->addspell mmar_mark", false)
    end
    if recallChange then
        logicHandler.RunConsoleCommandOnPlayer(pid, "player->removespell recall", false)
        logicHandler.RunConsoleCommandOnPlayer(pid, "player->addspell mmar_recall", false)
    end
end

MultipleMarkAndRecall.OnPlayerAuthentified = function(eventStatus, pid)
    if eventStatus.validCustomHandlers then
        dbg("Called MultipleMarkAndRecall.OnPlayerAuthentified for pid: " .. pid)
        local player = Players[pid]
        if player.data.customVariables.MultipleMarkAndRecall == nil then
            player.data.customVariables.MultipleMarkAndRecall = {}
            player.data.customVariables.MultipleMarkAndRecall.marks = {}
        end
        MultipleMarkAndRecall.updateOldSpells(pid)
    else
        fatal(scriptName .. " cannot work right!")
        fatal("Unable to set custom player data!")
    end
end

MultipleMarkAndRecall.OnPlayerSpellsActive = function(eventStatus, pid, playerPacket)
    local player = Players[pid]
    local action = playerPacket.action
    if action == enumerations.spellbook.ADD then
        local spells = playerPacket.spellsActive

        for spellId,spellTable in pairs(spells) do
            if spellId == "mmar_mark" then
                tes3mp.CustomMessageBox(pid, MultipleMarkAndRecall.guis.markSelection, "Mark Selection", "Delete Mark;Create Mark;Cancel")
            elseif spellId == "mmar_recall" then
                local marks = player.data.customVariables.MultipleMarkAndRecall.marks
                local txt = "Cancel"
                if tableHelper.isEmpty(marks) then
                    txt = "You have no marks set."
                else
                    for name, pos in pairs(marks) do
                        txt = txt .. string.format("\n%s (%s)", name, pos.cell)
                    end
                end

                local curMarkCount = tableHelper.getCount(player.data.customVariables.MultipleMarkAndRecall.marks)
                local maxMarkCount = getMarkCount(pid)
                tes3mp.ListBox(pid, MultipleMarkAndRecall.guis.recallList, string.format("Marks (%s/%s)", curMarkCount, maxMarkCount), txt)
            end
        end
    end
end

MultipleMarkAndRecall.OnPlayerSpellbook = function(eventStatus, pid)
    MultipleMarkAndRecall.updateOldSpells(pid)
end

MultipleMarkAndRecall.OnGUIAction = function(eventStatus, pid, idGui, data)
    local player = Players[pid]
	if idGui == MultipleMarkAndRecall.guis.markInputDialog then
        if data and string.match(data, "%S") then
            setMark(pid, data)
        end
    elseif idGui == MultipleMarkAndRecall.guis.recallList then
        local sId = tonumber(data)
        local c = 1
        for name, _ in pairs(player.data.customVariables.MultipleMarkAndRecall.marks) do
            if c == sId then
                doRecall(pid, name)
                break
            end
            c = c + 1
        end
    elseif idGui == MultipleMarkAndRecall.guis.markDelete then
        local sId = tonumber(data)
        local c = 1
        for name, _ in pairs(player.data.customVariables.MultipleMarkAndRecall.marks) do
            if c == sId then
                rmMark(pid, name)
                break
            end
            c = c + 1
        end
    elseif idGui == MultipleMarkAndRecall.guis.markSelection then
        data = tonumber(data)
        if data == 0 then
            local marks = player.data.customVariables.MultipleMarkAndRecall.marks
            local txt = "Cancel"
            if tableHelper.isEmpty(marks) then
                txt = "You have no marks set."
            else
                for name, pos in pairs(marks) do
                    txt = txt .. string.format("\n%s (%s)", name, pos.cell)
                end
            end

            local curMarkCount = tableHelper.getCount(player.data.customVariables.MultipleMarkAndRecall.marks)
            local maxMarkCount = getMarkCount(pid)
            tes3mp.ListBox(pid, MultipleMarkAndRecall.guis.markDelete, string.format("Marks (%s/%s)", curMarkCount, maxMarkCount), txt)
        elseif data == 1 then
            local curMarkCount = tableHelper.getCount(player.data.customVariables.MultipleMarkAndRecall.marks)
            local maxMarkCount = getMarkCount(pid)
            if curMarkCount == maxMarkCount then
                chatMsg(pid, color.Red .. "You do not have any free marks!" .. color.Default)
                return
            end
            tes3mp.InputDialog(pid, MultipleMarkAndRecall.guis.markInputDialog, "Mark name (empty for cancel)", "")	
        end
	end	
end

customEventHooks.registerHandler("OnPlayerAuthentified", MultipleMarkAndRecall.OnPlayerAuthentified)
customEventHooks.registerHandler("OnPlayerSpellsActive", MultipleMarkAndRecall.OnPlayerSpellsActive)
customEventHooks.registerHandler("OnServerPostInit", MultipleMarkAndRecall.OnServerPostInit)
customEventHooks.registerHandler("OnPlayerSpellbook", MultipleMarkAndRecall.OnPlayerSpellbook)
customEventHooks.registerHandler("OnGUIAction", MultipleMarkAndRecall.OnGUIAction)