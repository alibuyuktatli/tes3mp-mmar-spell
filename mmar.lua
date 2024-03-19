local MMAR = {}

MMAR.gui = {
    markInputDialog = 31102,
    recallList = 31103,
    markSelection = 31104,
    markDelete = 31105
}

MMAR.config = {
    maxMarks = 18,
    msgMark = color.Green .. "The mark \"%s\" has been set!" .. color.Default,
    msgMarkRm = color.Green .. "The mark \"%s\" has been deleted!" .. color.Default,
    msgRecallNotAllowed = color.Red .. "Recall is not allowed here!" .. color.Default,
    msgMarkNotAllowed = color.Red .. "Mark is not allowed here!" .. color.Default,
    msgRecall = color.Green .. "Recalled to: \"%s\"!" .. color.Default,
    msgNoMarkLeft = color.Red .. "You do not have any free marks!" .. color.Default,
    over10mod = 2,
    over50mod = 7,
    recallMagickaCost = 10,
    markMagickaCost = 10,
    skill = "Mysticism",
    logPrefix = "[MMAR]: ",
    recallForbiddenCells = {
        "Akulakhan's Chamber",
        "Sotha Sil,", "Solstheim, Mortrag Glacier: Entry", "Solstheim, Mortrag Glacier: Outer Ring",
        "Solstheim, Mortrag Glacier: Inner Ring", "Solstheim, Mortrag Glacier: Huntsman's Hall"
    },
    markForbiddenCells = {},
}

local function dbg(msg)
    tes3mp.LogMessage(enumerations.log.VERBOSE, MMAR.config.logPrefix .. msg)
end

local function fatal(msg)
   tes3mp.LogMessage(enumerations.log.FATAL, MMAR.config.logPrefix .. msg)
end

local function warn(msg)
    tes3mp.LogMessage(enumerations.log.WARN, MMAR.config.logPrefix .. msg)
end

local function info(msg)
    tes3mp.LogMessage(enumerations.log.INFO, MMAR.config.logPrefix .. msg)
end

local function chatMsg(pid, msg)
    dbg("Called chatMsg for pid: " .. pid .. " and msg: " .. msg)
   tes3mp.SendMessage(pid, MMAR.config.logPrefix .. msg .. "\n")
end

local function isRecallForbidden(pid)
    dbg("Called isRecallForbidden for pid: " .. pid)
    local currentCell = tes3mp.GetCell(pid)
    return tableHelper.containsValue(MMAR.config.recallForbiddenCells, currentCell)
end

local function isMarkForbidden(pid)
    dbg("Called isMarkForbidden for pid: " .. pid)
    local currentCell = tes3mp.GetCell(pid)
    return tableHelper.containsValue(MMAR.config.markForbiddenCells, currentCell)
end

local function doRecall(pid, name)
    dbg("Called doRecall for pid: " .. pid .. " and name: " .. name)
    local player = Players[pid]

    local mark = player.data.customVariables.MultipleMarkAndRecall.marks[name]

    player.data.location.cell = mark.cell
    player.data.location.posX = mark.x
    player.data.location.posY = mark.y
    player.data.location.posZ = mark.z
    player.data.location.rotZ = mark.rot

    player:LoadCell()
    chatMsg(pid, string.format(MMAR.config.msgRecall, name))
end

local function getMarkCount(pid)
    dbg("Called getMarkCount for pid: " .. pid)
    local extraMarks = 0
    local markCount = 2
    local mysticism = Players[pid].data.skills[MMAR.config.skill].base
    local totalMarks

    if mysticism >= 50 then
        local count = math.floor((mysticism - 50) / 5) + MMAR.config.over50mod
        extraMarks = extraMarks + count
    elseif mysticism >= 10 then
        extraMarks = math.floor(mysticism / 10) + MMAR.config.over10mod
    else
        extraMarks = 0
    end

    totalMarks = markCount + extraMarks

    if totalMarks > MMAR.config.maxMarks then
        totalMarks = MMAR.config.maxMarks
    end

    return totalMarks
end

local function rmMark(pid, name)
    dbg("Called rmMark for pid: " .. pid .. " and name: " .. name)
    local player = Players[pid]
    player.data.customVariables.MultipleMarkAndRecall.marks[name] = nil
    tableHelper.cleanNils(player.data.customVariables.MultipleMarkAndRecall.marks)
    chatMsg(pid, string.format(MMAR.config.msgMarkRm, name))
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

    chatMsg(pid, string.format(MMAR.config.msgMark, name))
end

local function getChoice(pid, i)
    local x = 1
    for name, data in pairs(Players[pid].data.customVariables.MultipleMarkAndRecall.marks) do
        if x == i then
            return x, name, data
        end
        x = x + 1
    end
end

MMAR.OnServerPostInit = function()
    local permanentSpellRecords = RecordStores.spell
    local permanentEnchantmentRecords = RecordStores.enchantment

        -- Spells
    -- Recall
    permanentSpellRecords.data.permanentRecords.recall = {
        name = "Recall",
        cost = MMAR.config.recallMagickaCost,
        subtype = 0,
        flags = 1,
        effects = { 
            {
                attribute = -1,
                area = 0,
                duration = 0,
                id = 61,
                rangeType = 0,
                skill = -1,
                magnitudeMax = 0,
                magnitudeMin = 0
            }
        }
    }
    -- Mark
    permanentSpellRecords.data.permanentRecords.mark = {
        name = "Mark",
        cost = MMAR.config.markMagickaCost,
        subtype = 0,
        flags = 1,
        effects = {
            {
                attribute = -1,
                area = 0,
                duration = 0,
                id = 60,
                rangeType = 0,
                skill = -1,
                magnitudeMax = 0,
                magnitudeMin = 0
            }
        }
    }
        -- Enchantments
    -- Mark
    local markEnchantment = {
        cost = MMAR.config.markMagickaCost,		
        subtype = 2,
        flags = 90,
        charge = 90,
        effects = {
            {
                attribute = -1,
                area = 0,
                duration = 0,
                id = 60,
                rangeType = 0,
                skill = -1,
                magnitudeMax = 0,
                magnitudeMin = 0
            }
        }
    }
    -- Recall
    local recallEnchantment = {
        cost = MMAR.config.recallMagickaCost,
        subtype = 2,
        flags = 90,
        charge = 90,
        effects = {
            {
                attribute = -1,
                area = 0,
                duration = 0,
                id = 61,
                rangeType = 0,
                skill = -1,
                magnitudeMax = 0,
                magnitudeMin = 0
            }
        }
    }

    permanentEnchantmentRecords.data.permanentRecords.mark_en = markEnchantment
    permanentEnchantmentRecords.data.permanentRecords.markring_en = markEnchantment

    permanentEnchantmentRecords.data.permanentRecords.recallring_en = markEnchantment
    permanentEnchantmentRecords.data.permanentRecords.recall_en = markEnchantment

    permanentSpellRecords:Save()
    permanentEnchantmentRecords:Save()
end

MMAR.OnPlayerAuthentified = function(eventStatus, pid)
    if eventStatus.validCustomHandlers then
        dbg("Called MMAR.OnPlayerAuthentified for pid: " .. pid)
        local player = Players[pid]
        if player.data.customVariables.MultipleMarkAndRecall == nil then
            player.data.customVariables.MultipleMarkAndRecall = {}
            player.data.customVariables.MultipleMarkAndRecall.marks = {}
        end
    else
        fatal("MMAR Unable to set custom player data!")
    end
end

local function listMarks(pid)
    local player = Players[pid]
    local marks = player.data.customVariables.MultipleMarkAndRecall.marks
    local txt = "Cancel"
    if tableHelper.isEmpty(marks) then
        txt = "You have no marks set."
    else
        for name, pos in pairs(marks) do
            txt = txt .. string.format("\n%s (%s)", name, pos.cell)
        end
    end
    return txt
end

MMAR.openMarkMenu = function(pid)
    if isMarkForbidden(pid) then
        chatMsg(pid, MMAR.config.msgMarkNotAllowed)
        return
    end

    tes3mp.CustomMessageBox(pid, MMAR.gui.markSelection, "Mark Selection", "Delete Mark;Create Mark;Cancel")
end

MMAR.openRecallMenu = function(pid)
    if isRecallForbidden(pid) then
        chatMsg(pid, MMAR.config.msgRecallNotAllowed)
        return
    end

    local curMarkCount = tableHelper.getCount(Players[pid].data.customVariables.MultipleMarkAndRecall.marks)
    local maxMarkCount = getMarkCount(pid)
    tes3mp.ListBox(pid, MMAR.gui.recallList, string.format("Marks (%s/%s)", curMarkCount, maxMarkCount), listMarks(pid))
end

MMAR.OnPlayerSpellsActive = function(eventStatus, pid, playerPacket)
    local action = playerPacket.action
    if action == enumerations.spellbook.ADD then
        for spellId, spellInstances in pairs(playerPacket.spellsActive) do
            for spellInstanceIndex, spellInstanceValues in pairs(spellInstances) do
                for effectIndex, effectTable in pairs(spellInstanceValues.effects) do
                    if effectTable.id == enumerations.effects.MARK then
                        MMAR.openMarkMenu(pid)
                        break
                    elseif effectTable.id == enumerations.effects.RECALL then
                        MMAR.openRecallMenu(pid)
                        break
                    end
                end
            end
        end
    end
end

MMAR.OnGUIAction = function(eventStatus, pid, idGui, data)
    local player = Players[pid]
	if idGui == MMAR.gui.markInputDialog then
        if data and string.match(data, "%S") then
            setMark(pid, data)
        end
    elseif idGui == MMAR.gui.recallList then
        local index, name, data = getChoice(pid, tonumber(data))
        if name then
            doRecall(pid, name)
        end
    elseif idGui == MMAR.gui.markDelete then
        local index, name, data = getChoice(pid, tonumber(data))
        if name then
            rmMark(pid, name)
        end
    elseif idGui == MMAR.gui.markSelection then
        data = tonumber(data)
        if data == 0 then
            local curMarkCount = tableHelper.getCount(player.data.customVariables.MultipleMarkAndRecall.marks)
            local maxMarkCount = getMarkCount(pid)
            tes3mp.ListBox(pid, MMAR.gui.markDelete, string.format("Delete Mark (%s/%s)", curMarkCount, maxMarkCount), listMarks(pid))
        elseif data == 1 then
            local curMarkCount = tableHelper.getCount(player.data.customVariables.MultipleMarkAndRecall.marks)
            local maxMarkCount = getMarkCount(pid)
            if curMarkCount == maxMarkCount then
                chatMsg(pid, MMAR.config.msgNoMarkLeft)
                return
            end
            tes3mp.InputDialog(pid, MMAR.gui.markInputDialog, "Mark name (empty for cancel)", "")	
        end
	end	
end

-- rickoff's function
MMAR.OnRecordDynamic = function(eventStatus, pid, recordArray, storeType)
	if storeType == "enchantment" or storeType == "spell" or storeType == "potion" then
        for _, record in ipairs(recordArray) do
			for _, effect in ipairs(record.effects) do
				if effect.id == enumerations.effects.MARK or effect.id == enumerations.effects.RECALL then
					effect.magnitudeMin = 0
					effect.magnitudeMax = 0
				end
			end
		end
	end
end

customEventHooks.registerHandler("OnPlayerAuthentified", MMAR.OnPlayerAuthentified)
customEventHooks.registerHandler("OnPlayerSpellsActive", MMAR.OnPlayerSpellsActive)
customEventHooks.registerHandler("OnServerPostInit", MMAR.OnServerPostInit)
customEventHooks.registerHandler("OnGUIAction", MMAR.OnGUIAction)
customEventHooks.registerValidator("OnRecordDynamic", MMAR.OnRecordDynamic)