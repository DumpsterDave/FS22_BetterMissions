BMSendExtendedMissionDataEvent = {}
BMSendExtendedMissionDataEvent_mt = Class(BMSendExtendedMissionDataEvent, Event)

InitEventClass(BMSendExtendedMissionDataEvent, "BMSendExtendedMissionDataEvent")

function BMSendExtendedMissionDataEvent.emptyNew()
    local self = Event.new(BMSendExtendedMissionDataEvent_mt)
    return self
end

function BMSendExtendedMissionDataEvent.new(fieldId, expectedLiters, expectedFieldTime)
    BetterMissions.debug("EVENT: BMSend " .. fieldId .. ", " .. expectedLiters .. ", " .. expectedFieldTime)
    local self = BMSendExtendedMissionDataEvent.emptyNew()
    self.fieldId = fieldId
    self.expectedLiters = expectedLiters
    self.expectedFieldTime = expectedFieldTime
    return self
end

function BMSendExtendedMissionDataEvent:writeStream(streamId)
    BetterMissions.debug("EVENT: BMSendWrite " .. streamId)
    streamWriteInt32(streamId, self.fieldId)
    streamWriteFloat32(streamId, self.expectedLiters)
    streamWriteFloat32(streamId, self.expectedFieldTime)
end

function BMSendExtendedMissionDataEvent:readStream(streamId, connection)
    --BetterMissions.debug("EVENT: BMSendRead " .. streamId .. ", " .. tostring(connection))
    self.fieldId = streamReadInt32(streamId)
    self.expectedLiters = streamReadFloat32(streamId)
    self.expectedFieldTime = streamReadFloat32(streamId)
    BetterMissions.debug("Updating mission info for field " .. self.fieldId .. "(" .. self.expectedLiters .. "," .. self.expectedFieldTime .. ")")
    local missionFound = false
    for _,mission in pairs(g_missionManager.missions) do
        if mission.field.fieldId == self.fieldId then
            BetterMissions.debug("Found Matching mission for field " .. self.fieldId)
            mission.expectedLiters = self.expectedLiters
            mission.expectedFieldTime = self.expectedFieldTime
            missionFound = true
        end
    end
    BetterMissions.debug("Field  " .. self.fieldId .. " mission found: " .. tostring(missionFound))
end

function BMSendExtendedMissionDataEvent:run(connection)
   
end