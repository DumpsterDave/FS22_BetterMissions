BMUserConnectedEvent = {}
BMUserConnectedEvent_mt = Class(BMUserConnectedEvent, Event)

InitEventClass(BMUserConnectedEvent, "BMUserConnectedEvent")

function BMUserConnectedEvent.emptyNew()
    local self = Event.new(BMUserConnectedEvent_mt)
    return self
end

function BMUserConnectedEvent.new()
    return BMUserConnectedEvent.emptyNew()
end

function BMUserConnectedEvent:writeStream(streamId, connection)
end

function BMUserConnectedEvent:readStream(streamId, connection)
    self:run(connection)
end

function BMUserConnectedEvent:run(connection)
    if g_server ~= nil then
        BetterMissions.info("User Connected, sending initial mission info")
        for _,mission in pairs(g_missionManager.missions) do
            local stillValid = g_missionManager:canMissionStillRun(mission)
            if (stillValid) then
                if mission.expectedFieldTime == nil then
                    BetterMissions.getMissionSteps(mission)
                    BetterMissions.calculateNewRewards(mission)
                end
                BetterMissions.debug("Sending mission info for field " .. mission.field.fieldId .. "(" .. Utils.getNoNil(mission.expectedLiters, 0) .. ", " .. Utils.getNoNil(mission.expectedFieldTime, 0) .. ")")
                local event = BMSendExtendedMissionDataEvent.new(mission.field.fieldId, Utils.getNoNil(mission.expectedLiters, 0), Utils.getNoNil(mission.expectedFieldTime, 0))
                connection:sendEvent(event)
            end
        end
    end
end

function BMUserConnectedEvent.sendEvent()
    if g_server == nil then
        g_client:getServerConnection():sendEvent(BMUserConnectedEvent.new())
    end
end