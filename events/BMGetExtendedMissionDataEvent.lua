BMGetExtendedMissionDataEvent = {}
BMGetExtendedMissionDataEvent_mt = Class(BMGetExtendedMissionDataEvent, Event)

InitEventClass(BMGetExtendedMissionDataEvent, "BMGetExtendedMissionDataEvent")

function BMGetExtendedMissionDataEvent.emptyNew()
    local self = Event.new(BMGetExtendedMissionDataEvent_mt)
    return self
end

function BMGetExtendedMissionDataEvent.new(fieldId)
    --BetterMissions.debug("EVENT: BMGetNew " .. fieldId)
    local self = BMGetExtendedMissionDataEvent.emptyNew()
    self.fieldId = fieldId
    return self
end

function BMGetExtendedMissionDataEvent:writeStream(streamId)
    --BetterMissions.debug("EVENT: BMGetWrite " .. streamId)
    streamWriteInt32(streamId, self.fieldId)
end

function BMGetExtendedMissionDataEvent:readStream(streamId, connection)
    --BetterMissions.debug("EVENT: BMGetRead " .. streamId .. " " .. tostring(connection))
    self.fieldId = streamReadInt32(streamId)
    self:run(connection)
end

function BMGetExtendedMissionDataEvent:run(connection) 
    for _,mission in pairs(g_missionManager.missions) do
        if mission.field.fieldId == self.fieldId then
            if mission.expectedFieldTime == nil then
                BetterMissions.getMissionSteps(mission)
                BetterMissions.calculateNewRewards(mission)
            end
            BetterMissions.debug("Sending mission info for field " .. self.fieldId .. "(" .. Utils.getNoNil(mission.expectedLiters, 0) .. ", " .. Utils.getNoNil(mission.expectedFieldTime, 0) .. ")")
            local event = BMSendExtendedMissionDataEvent.new(self.fieldId, Utils.getNoNil(mission.expectedLiters, 0), Utils.getNoNil(mission.expectedFieldTime, 0))
            connection:sendEvent(event)
        end
    end
end