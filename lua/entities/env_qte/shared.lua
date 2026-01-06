ENT.Type = 'anim'

function ENT:SetupDataTables()
self:NetworkVar('String', 0, 'UI', {'KeyName'})
self:NetworkVar('String', 1, 'Key', {'KeyName'})
self:NetworkVar('Bool', 0, 'LockToScreen', {'KeyName'})
self:NetworkVar('Bool', 1, 'LockToPlayerDirection', {'KeyName'})
self:NetworkVar('Bool', 2, 'IgnoreZ', {'KeyName'})
self:NetworkVar('Int', 1, 'State', {'KeyName'}) -- Im too tired to do anymore util.AddNetworkString bullshit. Just fucking notify it mkay.
self:NetworkVar('Vector', 2, 'Offset', {'KeyName'})
self:NetworkVar('Float', 0, 'Scale', {'KeyName'})
self:NetworkVar('Entity', 0, 'Player', {'KeyName'})
end

function ENT:KeyValue(k, v)
    if k == 'ui' then
        self:SetUI(v)

    elseif k == 'keypress' then
        self:SetKey(v)

    elseif k == 'locktoscreen' and tobool(v) then
        self:SetLockToScreen(tobool(v)) 

    elseif k == 'locktodirection' and tobool(v) then
        self:SetLockToPlayerDirection(tobool(v)) 

    elseif k == 'ignorez' and tobool(v) then
        self:SetIgnoreZ(tobool(v)) 

    elseif k == 'scale' and tonumber(v) then
        self:SetScale(tonumber(v))

    elseif k == 'offset' then
        local vect = Vector(v)
        if isvector(vect) then
            self:SetOffset(vect)
        end
    elseif string.Left(k, 2) == 'On' then
    self:StoreOutput(k, v)
    end

end

function ENT:AcceptInput(Input, activator, caller, params)
    if Input == 'Enable' then
        self:SetState(1)

        elseif Input == 'Disable' then
            self:SetState(0)

        elseif Input == 'Success' then
            self:SetState(2)
            self:TriggerOutput('OnSuccess', activator)

        elseif Input == 'Fail' then
            self:SetState(3)
            self:TriggerOutput('OnFail', activator)

        elseif Input == 'SetKey' then
        self:SetKey(params)

        elseif Input == 'LockToScreen' and tobool(params) then
            self:SetLockToScreen(tobool(params))

        elseif Input == 'LockToPlayerDirection' and tobool(params) then
            self:SetLockToPlayerDirection(tobool(params))

        elseif Input == 'SetScale' and tonumber(params) then
            self:SetScale(tonumber(params))

        elseif Input == 'SetIgnoreZ' and tobool(params) then
            self:SetIgnoreZ(tobool(params))

        elseif Input == 'SetPlayerViaActivator' and activator and activator:IsValid() and activator:IsPlayer() then
            self:SetPlayer(activator)

        elseif Input == 'ReleasePlayer' and self:GetPlayer():IsValid() then
        self:SetPlayer(nil)

        elseif Input == 'setXOffset' and tonumber(params) then
        self:SetXOffset(tonumber(params))

        elseif Input == 'setYOffset' and tonumber(params) then
        self:SetYOffset(tonumber(params))

        elseif Input == 'setZOffset' and tonumber(params) then
        self:SetYOffset(tonumber(params))
        

    end
    
end

hook.Add('')

if SERVER then
function ENT:UpdateTransmitState()
return true
end
end