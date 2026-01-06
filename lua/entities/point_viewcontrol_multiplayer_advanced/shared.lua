ENT.Type = "anim"
function ENT:SetupDataTables()
    self:NetworkVar('Float', 0, 'TransTime', {'KeyName'})
    self:NetworkVar('Float', 1, 'FOVTarget', {'KeyName'})
    self:NetworkVar('Float', 2, 'FOVRate', {'KeyName'})
    self:NetworkVar('Float', 3, 'PlayerPOVTransTime', {'KeyName'})
    self:NetworkVar('Float', 4, 'VMDist', {'KeyName'})
    self:NetworkVar('String', 0, 'PlayerPOVTransFunc', {'KeyName'})
    self:NetworkVar('String', 1, 'TransTimeFunc', {'KeyName'})
    self:NetworkVar('Bool', 0, 'StopInput', {'KeyName'})

    self.Subjects = {}
    self.StartTime = CurTime()
    self.ReturnToPovStartTime = CurTime()
    self.FOV = 90
    self:SetRenderMode(RENDERMODE_NONE)
    hook.Add('StartCommand', 'obj_pvcma_' .. self:EntIndex(), function(pl, cmd)
        if self and self:IsValid() then
            if SERVER then
                if pl:TestPVS(self) and self.GetNetworkVars and self:GetStopInput() and self.Subjects and table.HasValue(self.Subjects, pl) then
                    cmd:RemoveKey(IN_JUMP)
                    cmd:RemoveKey(IN_FORWARD)
                    cmd:SetForwardMove(0)
                    cmd:SetSideMove(0)
                    cmd:ClearMovement()
                end
            else
                if self.GetStopInput and self:GetStopInput() and self.GetNetworkVars and table.HasValue(self.Subjects, pl) then
                    cmd:SetForwardMove(0)
                    cmd:SetSideMove(0)
                    cmd:SetButtons(0)
                end
            end
        end
    end)
end

function ENT:OnRemove()
hook.Remove('StartCommand', 'obj_pvcma_' .. self:EntIndex())
end



function ENT:KeyValue(key, value)
    local validmathfuncs = {'InBack', 'InBounce', 'InCirc', 'InCubic', 'InElastic', 'InExpo', 'InOutBack', 'InOutBounce', 'InOutCirc', 'InOutCubic', 'InOutElastic', 'InOutExpo',
    'InOutQuad', 'InOutQuart', 'InOutQuint', 'InOutSine', 'InQuad', 'InQuart', 'InQuint', 'InSine', 'OutBack', 'OutBounce', 'OutCirc', 'OutCubic', 'OutElastic', 'OutExpo', 'OutQuad', 'OutQuart', 'OutQuint', 'OutSine'}

    if key == 'transtime' then -- Time to make YandereDev proud
            self:SetTransTime(tonumber(value))
    elseif key == 'fov_target' then
            self:SetFOVTarget(tonumber(value))
    elseif key == 'fov_rate' then
            self:SetFOVRate(tonumber(value)) 
    elseif key == 'transtimefunc' then
        if table.HasValue(validmathfuncs, value) then
            self:SetTransTimeFunc(value) 
        else self:SetTransTimeFunc('OutSine') end
    elseif key == 'stopinput' and tobool(value) then
        self:SetStopInput(tobool(value))
    elseif key == 'disablehud' then
        self:SetDisableHUD(tobool(value))
    elseif key == 'playerpovtranstime' then
        self:SetPlayerPOVTransTime(tonumber(value))
    elseif key == 'playerpovtransfunc' then
        if table.HasValue(validmathfuncs, value) then
        self:SetPlayerPOVTransFunc(value)
        else self:SetPlayerPOVTransFunc('OutSine') end
    elseif key == 'vmdist' and tonumber(value) then
        self:SetVMDist(tonumber(value))
    end
end

if SERVER then
    util.AddNetworkString('zs_obj_pvcma_toggle')
end


if CLIENT then
    function ENT:AddSubject(subject)
    table.insert(self.Subjects, subject)
    end
end

function ENT:AcceptInput(Input, Activator, Caller, Args)
    if Input == 'EnableForAll' then
        net.Start('zs_obj_pvcma_toggle')
        net.WriteUInt(self:EntIndex(), 13)
        net.WriteBool(true)
        net.Broadcast()
        if self.Subjects then
            self.Subjects = table.Copy(player.GetAll())
        end

    elseif Input == 'DisableForAll' then
        net.Start('zs_obj_pvcma_toggle')
        net.WriteUInt(self:EntIndex(), 13)
        net.WriteBool(false)
        net.Broadcast()
        table.Empty(self.Subjects)

    elseif Input == 'EnableForSelect' then
            if Activator and Activator:IsValid() and Activator:IsPlayer() then 
                net.Start('zs_obj_pvcma_toggle')
                net.WriteUInt(self:EntIndex(), 13)
                net.WriteBool(true)
                net.Send(Activator)
                table.insert(self.Subjects, Activator)
            end

    elseif Input == 'DisableForSelect' then
        if Args then 
                net.Start('zs_obj_pvcma_toggle')
                net.WriteUInt(self:EntIndex(), 13)
                net.WriteBool(false)
                net.Send(Activator)
                table.RemoveByValue(self.Subjects, Activator)
        end

    elseif Input == 'SetFOVTarget' and tonumber(Args) then
     self:SetFOVTarget(tonumber(Args))
    elseif Input == 'SetFOVRate' and tonumber(Args) then
        self:SetFOVRate(tonumber(Args))
    end
end