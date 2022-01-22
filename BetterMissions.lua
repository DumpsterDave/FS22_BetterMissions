BetterMissions = {
	VERSION = "1.0.0.0",
	REWARD_TABLE = {
		HARVEST = {
			COTTON = {
				SMALL=1666.667,
				MEDIUM=1666.667,
				LARGE=1666.667
			},
			GRAIN = {
				SMALL=2000,
				MEDIUM=1315.789,
				LARGE=729.927
			},
			MAIZE = {
				SMALL=2941.176,
				MEDIUM=1666.667,
				LARGE=1111.111
			},
			POTATO = {
				SMALL=5555.556,
				MEDIUM=2500,
				LARGE=2500
			},
			SUGARBEET = {
				SMALL=3333.333,
				MEDIUM=3703.704,
				LARGE=2500
			},
			SUGARCANE = {
				SMALL=5000,
				MEDIUM=5000,
				LARGE=5000
			}
		},
		PLOW = {
			SMALL = 6944.444,
			MEDIUM = 2380.952,
			LARGE = 1388.889
		},
		SOW = { 
			SEEDER = {
				SMALL = 2777.778,
				MEDIUM = 1388.889,
				LARGE = 555.556
			},
			PLANTER = {
				SMALL = 1388.889,
				MEDIUM = 1041.667,
				LARGE = 462.963
			},
			POTATO = {
				SMALL = 2777.778,
				MEDIUM = 1388.889,
				LARGE = 1388.889
			},
			SUGARCANE = {
				SMALL = 8333.333,
				MEDIUM = 4166.667,
				LARGE = 4166.667
			}
		},
		WEED = {
			SMALL = 1388.889,
			MEDIUM = 925.926,
			LARGE = 694.444
		},
		FERTILIZE = {
			SMALL = 132.275,
			MEDIUM = 347.222,
			LARGE = 252.525
		},
		SPRAY = { 
			SMALL = 347.222,
			MEDIUM = 252.525,
			LARGE = 111.111
		},
		CULTIVATE = {
			SMALL = 2222.222,
			MEDIUM = 1111.111,
			LARGE = 546.448
		},
		MOW_BALE = {
			HAY = {
				SMALL = 5086.470,
				MEDIUM = 1968.117,
				LARGE = 1752.848
			},
			SILAGE = {
				SMALL = 4987.531,
				MEDIUM = 2569.373,
				LARGE = 1707.942
			}
		}
	}
}
local BetterMissions_mt = Class(BetterMissions)
addModEventListener(BetterMissions)

function BetterMissions:loadMap()
	Logging.info("[BM] - Loading Better Missions")
    HarvestMission.getData = Utils.overwrittenFunction(HarvestMission.getData, BetterMissions.getHarvestMissionData)
	g_messageCenter:subscribe(MessageType.MISSION_GENERATED, BetterMissions.updateMissionRewards, BetterMissions)
	g_missionManager.MISSION_GENERATION_INTERVAL = 3600000
end

function BetterMissions:updateMissionRewards()
	Logging.info("[BM] - Missions Generated. Processing new missions.")
	for _,mission in pairs(g_missionManager.missions) do
		--Logging.info(string.format("Found a %s mission for field %d", mission.type.name, mission.field.fieldId))
		if mission.BetterMissions == nil or mission.BetterMissions == false then
			--Get Field Size Class
			local fieldSizeClass = "SMALL"
			if mission.field.fieldArea >= 5 then
				fieldSizeClass = "LARGE"
			elseif mission.field.fieldArea >= 1.5 then
				fieldSizeClass = "MEDIUM"
			end
			local missionType = string.upper(mission.type.name)
			local newRewardPerHa = 0
			--Get info
			local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(mission.field.fruitType)
			local fruitName = string.upper(fruitDesc.name)
			local cropClass = "GRAIN"
			local baleType = "HAY"
			if missionType == "HARVEST" then
				if fruitName == "COTTON" then
					cropClass = "COTTON"
				elseif fruitName == "POTATO" then
					cropClass = "POTATO"
				elseif fruitName == "SUGARBEET" then
					cropClass = "SUGARBEET"
				elseif fruitName == "SUGARCANE" then
					cropClass = "SUGARCANE"
				elseif fruitName == "MAIZE" or fruitName == "SUNFLOWER" then
					cropClass = "MAIZE"
				end
				newRewardPerHa = BetterMissions.REWARD_TABLE["HARVEST"][cropClass][fieldSizeClass]
			elseif missionType == "MOW_BALE" then 
				if mission..workAreaTypes[WorkAreaType.TEDDER] == false then
					baleType = "SILAGE"
				end
				newRewardPerHa = BetterMissions.REWARD_TABLE["MOW_BALE"][baleType][fieldSizeClass]
			else
				newRewardPerHa = BetterMissions.REWARD_TABLE[missionType][fieldSizeClass]
			end

			-- calculate fruit multiplier
			local fruitMultiplier = 1
			if mission.field.fruitType ~= nil then
				if fruitDesc ~= nil then
					fruitMultiplier = fruitDesc.missionMultiplier
				end
			end

			--Calculate New numbers
			local newReward = fruitMultiplier * newRewardPerHa * mission.field.fieldArea + mission.reimbursementPerHa * mission.field.fieldArea
			local displayReward = mission.rewardPerHa * mission.field.fieldArea * (1.3 - 0.1 * g_currentMission.missionInfo.economicDifficulty) + mission.reimbursementPerHa * mission.field.fieldArea * (1.4 - 0.1 * g_currentMission.missionInfo.economicDifficulty)
			local newDisplayReward = newRewardPerHa * mission.field.fieldArea * (1.3 - 0.1 * g_currentMission.missionInfo.economicDifficulty) + mission.reimbursementPerHa * mission.field.fieldArea * (1.4 - 0.1 * g_currentMission.missionInfo.economicDifficulty)

			Logging.info(string.format("[BM] - Updaing mission on field %02d.  Updating RewardPerHa from %.3f to %.3f.  Reward has changed from $%d to $%d.", mission.field.fieldId, mission.rewardPerHa, newRewardPerHa, displayReward, newDisplayReward))
			--set new data
			mission.rewardPerHa = newRewardPerHa
			mission.reward = newReward
			mission.BetterMissions = true
		else 
			Logging.info(string.format("[BM] - Skipping mission for field %02d. It has already been updated.", mission.field.fieldId))
		end
	end
end

function BetterMissions:getHarvestMissionData()
	--Logging.info("[BM] - Getting Harvest Mission Data")
    if self.sellPointId ~= nil then
		self:tryToResolveSellPoint()
	end

	local name = "Unknown"

	if self.sellPoint ~= nil then
		name = self.sellPoint:getName()
	end

	return {
		location = string.format(g_i18n:getText("fieldJob_number"), self.field.fieldId),
		jobType = g_i18n:getText("fieldJob_jobType_harvesting"),
		action = g_i18n:getText("fieldJob_desc_action_harvesting"),
		description = string.format(g_i18n:getText("BM_fieldJob_desc_harvesting"),self.expectedLiters, g_fillTypeManager:getFillTypeByIndex(self.fillType).title, self.field.fieldId, name)
	}
end

function BetterMissions.addModTranslations(i18n)
    local global = getfenv(0).g_i18n.texts

	for key, text in pairs(i18n.texts) do
		global[key] = text
	end
end

function BetterMissions.onMissionWillLoad(i18n)
	BetterMissions.addModTranslations(i18n)
end

function BetterMissions.DumpTables(table)
	print("Dumping table " ..  tostring(table))
	local name = tostring(table)
	name = string.gsub(name, ":", "")
	local exportFilename = g_currentMission.missionInfo.savegameDirectory .. "/" .. name
	local file = createFile(exportFilename, FileAccess.WRITE)
	BetterMissions.dumpTable(table, 0, file)
	delete(file)
end
function BetterMissions.dumpTable(table, depth, file)
	if depth > 4 then
		return
	end

	local indent = ""
	for c = 0, depth do
		indent = indent .. "|  "
	end
	for i,j in pairs(table) do
		fileWrite(file, indent .. tostring(i) .. " :: " ..tostring(j) .. "\n")
		if type(j) == "table" then
			BetterMissions.dumpTable(j, depth + 1, file)
		end
	end
end