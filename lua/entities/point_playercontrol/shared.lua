ENT.Type = 'anim'

 ENT.validinputs = {ATTACK = 1, JUMP = 2, DUCK = 4, ATTACK2 = 2048, FORWARD = 8, BACK = 16, MOVELEFT = 512, MOVERIGHT = 1024, USE = 32, SPEED = 131072, SCORE = 65536, RELOAD = 8192, WALK = 262144, WEAPON1 = 1048576, WEAPON2 = 2097152}

local function findyaw(x1, y1, x2, y2)
return math.deg(math.atan2(y1 - y2, x2 - x1)) end

local function PlayerMovementControl(self, pl, mv, cmd)
    if self.Getdisabled and not self:Getdisabled() then
        local pltable = nil
            if SERVER then
                pltable = self.Subjects
                if pltable and table.HasValue(pltable, pl) then
                    if self:Getgotopos() then
                        
                        local mypos = self:GetPos()
                        local plpos = pl:GetPos()
                        if plpos:DistToSqr(mypos) > (self:Getacceptrange() ^ 2) then
                            local rot = mypos - plpos
                            rot:Normalize()
                            mv:SetMoveAngles(rot:Angle())
                            mv:SetForwardSpeed(self:Getdesiredspeed())
                        end
                    end
                end
            else
                local directory = PHE_PPC_Registry[self:EntIndex()]
                pltable = directory.subjects

                if pltable and table.HasValue(pltable, pl:UserID()) then
                    if self:Getgotopos() then

                        local mypos = self:GetPos()
                        local plpos = pl:GetPos()

                        if plpos:DistToSqr(mypos) > (self:Getacceptrange() ^ 2) then
                        local rot = plpos - mypos
                        rot:Normalize()
                        mv:SetMoveAngles(mv:SetMoveAngles(rot:Angle()))
                        mv:SetForwardSpeed(self:Getdesiredspeed())
                    end
                end
            end
        end
    end
end

local function PlayerRotationControl(self, cmd)
    if self.Getdisabled and not self:Getdisabled() then
        local directory = PHE_PPC_Registry[self:EntIndex()]
        pltable = directory.subjects

        if pltable and table.HasValue(pltable, LocalPlayer()) then
            if self:Getfaceangles() then
                cmd:SetViewAngles(self:GetAngles())
            return true end
        end
    end
end

local function PlayerInputControl(self, pl, cmd)
if self.Getdisabled and not self:Getdisabled() then
    local pltable = nil
        if SERVER then
            pltable = self.Subjects
            if pltable and table.HasValue(pltable, pl) then
                if self.OutputInputs then
                    for i, v in pairs(self.validinputs) do
                        if bit.band(cmd:GetButtons(), v) > 0 then
                            self:InputAnOutput(i, pl)
                        end
                    end
                end
                if self.Getinputregisters then
                    local bitresult = bit.band(cmd:GetButtons(), self:Getinputregisters())
                    cmd:SetButtons(bitresult)
                    if self:Getclearmovement() then
                        cmd:ClearMovement()
                    end
                end
            end
        end
    end
end

local function PlayerDeath(self, pl, hpremain, dmg)
    if self.Subjects and table.HasValue(self.Subjects, pl) then
        self:TriggerOutput('OnPlayerDeath', pl)
    end
end

local function PlayerHurt(self, pl, hpremain, dmg)
    if self.Subjects and table.HasValue(self.Subjects, pl) then
        self:TriggerOutput('OnPlayerHurt', pl)
    end
end

function ENT:SetupDataTables()
    self:NetworkVar('String', 0, 'Anim', {'KeyName'})
    self:NetworkVar('Int', 0, 'inputregisters', {'KeyName'})
    self:NetworkVar('Float', 0, 'playbrate', {'KeyName'})
    self:NetworkVar('Float', 1, 'acceptrange', {'KeyName'})
    self:NetworkVar('Float', 2, 'desiredspeed', {'KeyName'})
    self:NetworkVar('Bool', 0, 'gotopos', {'KeyName'})
    self:NetworkVar('Bool', 1, 'faceangles', {'KeyName'})
    self:NetworkVar('Bool', 2, 'disabled', {'KeyName'})
    self:NetworkVar('Bool', 3, 'clearmovement', {'KeyName'})
    self:SetRenderMode(RENDERMODE_ENVIROMENTAL)
    self.OutputInputs = 0
    self.Subjects = {}
    self.FreezePlayer = false
    self.Anim = ''

    if SERVER then
        util.AddNetworkString('PHE_PPC_Subject') -- can't be a network var because there can be multiple subjects.
    end
        self:NetworkVarNotify('gotopos', function(ent, name, old, new)
            if new then
                hook.Add('SetupMove', 'PHE_PPC_' .. self:EntIndex(), function(pl, mv, cmd) PlayerMovementControl(self, pl, mv, cmd) end)
            else
                hook.Remove('SetupMove', 'PHE_PPC_' .. self:EntIndex())
            end
        end)
    if CLIENT then
        self:NetworkVarNotify('faceangles', function(ent, name, old, new)
            if new then
                hook.Add('InputMouseApply', 'PHE_PPC_Rotation_' .. self:EntIndex(), function(pl,cmd) PlayerRotationControl(self, cmd) end)
            else
                hook.Remove('InputMouseApply', 'PHE_PPC_Rotation_' .. self:EntIndex())
            end
        end)

        PHE_PPC_Registry = {} -- Registering stuff here to prevent PVS issues.
        self:NetworkVarNotify('Anim', function(ent, name, old, new) 
            local id = self:EntIndex()
        if new != '' then
            local directory = PHE_PPC_Registry[id]
            if not directory then
            PHE_PPC_Registry[id] = {['activity'] = new}
            directory = PHE_PPC_Registry[id]
            else 
            directory['activity'] = new
            end
                if act != '' then
                    hook.Add('CalcMainActivity', 'PHE_PPC_ANIMATE_' .. self:EntIndex(), function(pl, vel)
                        if self.Getdisabled and not self:Getdisabled() then
                            local directory = PHE_PPC_Registry[id]
                            if directory then
                                local subjects = directory['subjects']
                                local act = directory['activity']
                                local actid = util.GetActivityIDByName(act)
                                print(actid)
                                if subjects and table.HasValue(subjects, pl:UserID()) then 
                                    if actid and actid != -1 then
                                        
                                        pl:SetPlaybackRate(self:Getplaybrate())
                                        return actid, -1
                                    end
                                end
                            end
                        end
                    
                    end)
                else hook.Remove('CalcMainActivity', 'PHE_PPC_ANIMATE_' .. id)
                end
            end
        end)
    end

end
function ENT:KeyValue(key, value)

    if key == 'outputinputs' and tonumber(value) then
        self.OutputInputs = tonumber(value)
    
    elseif key == 'StartDisabled' and tobool(value) then
        self:Setdisabled(true)

    elseif key == 'clearmovement' and tobool(value) then
    self:Setclearmovement(tobool(value))

    elseif key == 'gotopos' and tobool(value) then
        self:Setgotopos(tobool(value))
    
    elseif key =='faceangles' and tobool(value) then
        self:Setfaceangles(tobool(value))

    elseif key == 'animbrate' and tonumber(value) then
        self:Setplaybrate(tonumber(value))
    
    elseif key == 'inputregister' and tonumber(value) then 
    self:Setinputregisters(tonumber(value))

    elseif key == 'desiredspeed' and tonumber(value) then
    self:Setdesiredspeed(tonumber(value))

    elseif key == 'acceptrange' and tonumber(value) then
    self:Setacceptrange(tonumber(value))

    elseif key == 'freezeplayer' and tobool(value) then
    self.FreezePlayer = tobool(value)
    elseif (string.Left(key, 2) == "On") then
		self:StoreOutput(key, value)
    end
end

function ENT:InputAnOutput(input, pl)
    if self.validinputs[input] and pl and pl:IsValid() then
        self:TriggerOutput('On' .. input, pl)
    end
end

function ENT:OnRemove()
hook.Remove('StartCommand', 'PHE_PPC_' .. self:EntIndex())
hook.Remove('SetupMove', 'PHE_PPC_' .. self:EntIndex())
hook.Remove('CalcMainActivity', 'PPS_' .. self:EntIndex())
hook.Remove('InputMouseApply', 'PHE_PPC_Rotation_' .. self:EntIndex())
for i, sub in pairs(self.Subjects) do
        net.Start('PHE_PPC_Subject')
        net.WriteUInt(self:EntIndex(), 13)
        net.WriteUInt(sub:UserID() - 1, 7)
        net.WriteBool(false)
        net.Broadcast()
        sub:Freeze(false)
    end

end


function ENT:AcceptInput(Input, Activator, Caller, Args)
    if self.Getdisabled and not self:Getdisabled() then
        local inputstring = string.Replace(Input, 'On', '')
        if Input == 'SetOutputInputs' then
            self.OutputInputs = tonumber(Args)

        elseif Input == 'SetRegisteredInputs' and tonumber(Args) then
            self:Setinputregisters(tonumber(Args))

        elseif Input == 'AddPlayer' and Activator and Activator:IsValid() and Activator:IsPlayer() then
            if not table.HasValue(self.Subjects, Activator:UserID()) then

                table.insert(self.Subjects, Activator)
                net.Start('PHE_PPC_Subject')
                    net.WriteUInt(self:EntIndex(), 13)
                    net.WriteUInt(Activator:UserID() - 1, 7)
                    net.WriteBool(true)
                net.Broadcast()

                    hook.Add('StartCommand', 'PHE_PPC_' .. self:EntIndex(), function(pl, cmd) PlayerInputControl(self, pl, cmd) end)

                    hook.Add('SetupMove', 'PHE_PPC_' .. self:EntIndex(), function(pl, mv, cmd) PlayerMovementControl(self, pl, mv, cmd) end)

                    hook.Add('PlayerDeath', 'PHE_PPC_' .. self:EntIndex(), function(pl, inf, atk) PlayerDeath(self, pl, inf, atk) end)
                    
                    hook.Add('PlayerHurt', 'PHE_PPC_' .. self:EntIndex(), function(pl, hpr, dmg) PlayerHurt(self, pl, hpr, dmg) end)
                    
                if self.FreezePlayer then
                    Activator:Freeze(true)
                end
            end

        elseif Input == 'ReleasePlayer' and Activator and Activator:IsValid() and Activator:IsPlayer() then
            net.Start('PHE_PPC_Subject')
                net.WriteUInt(self:EntIndex(), 13)
                net.WriteUInt(Activator:UserID() - 1, 7)
                net.WriteBool(false)
            net.Broadcast()
            Activator:Freeze(false)
            table.RemoveByValue(self.Subjects, Activator)

        elseif Input == 'AddAllPlayers' then
            for i, sub in ipairs(player.GetAll()) do
                    net.Start('PHE_PPC_Subject')
                    net.WriteUInt(self:EntIndex(), 13)
                    net.WriteUInt(sub:UserID() - 1, 7)
                    net.WriteBool(true)
                net.Broadcast()
                table.insert(sub)

                if self.FreezePlayer then
                    sub:Freeze(true)
                end
            end

        elseif Input == 'ReleaseAllPlayers' then
            for i, sub in pairs(self.Subjects) do
                    net.Start('PHE_PPC_Subject')
                    net.WriteUInt(self:EntIndex(), 13)
                    net.WriteUInt(sub:UserID() - 1, 7)
                    net.WriteBool(false)
                net.Broadcast()
                 sub:Freeze(false)
                table.RemoveByValue(self.Subjects, sub)
            end
            hook.Remove('CalcMainActivity', 'PPS_' .. self:EntIndex())

        elseif Input == 'SetActivity' then
            print('yesssssssssssir')
            self:SetAnim(Args)
            if Args != '' then
                
                hook.Add('CalcMainActivity', 'PPS_' .. self:EntIndex(), function(pl, vel) 
                if self.Getdisabled and not self:Getdisabled() and self.Subjects and table.HasValue(self.Subjects, pl) and self:GetAnim() and self:GetAnim() != '' then
                    local id = util.GetActivityIDByName(self:GetAnim())
                if id != -1 then
                    return id, nil end 
                end end)
            else
            hook.Remove('CalcMainActivity', 'PPS_' .. self:EntIndex())

            end

        elseif Input == 'SetAnimPlaybackRate' and tonumber(Args) and self.Subjects then
            for i, v in pairs(self.Subjects) do
                if v and v:IsValid() then
                    v:SetPlaybackRate(tonumber(Args))
                end
            end

        elseif Input == 'HurtPlayer' and tonumber(Args) then
            for i, v in pairs(self.Subjects) do
                local pl = Player(v)
                if pl and pl:IsValid() and pl:IsPlayer() then
                    pl:TakeDamage(tonumber(Args), game.GetWorld())
                end
        end
        
        elseif Input == 'KillPlayer' then
            for i, pl in pairs(self.Subjects) do
                if pl and pl:IsValid() and pl:IsPlayer() then
                    pl:Kill()
                end
            end
        
        elseif Input == 'SetPlayersWeapon' and self.Subjects then
            for i, pl in pairs(self.Subjects) do
                if pl and pl:IsValid() and pl:IsPlayer() then
                    local swep = pl:GetWeapon(Args)
                    if swep and swep:IsValid() then
                        pl:SetActiveWeapon(swep)
                    end
                end
            end
        elseif Input == 'SetGoToPos' and tonumber(Args) then

            if tobool(Args) then
                self:Setgotopos(tobool(Args))
            end
        elseif Input == 'SetShouldFaceDirection' and tonumber(Args) then

        if tobool(Args) then
            self:Setfaceangles(tobool(Args))
        end
        elseif Input == 'ClearPlayersMovement' and tonumber(Args) then
        if tobool(Args) then
            self:Setclearmovement(tobool(Args))
        end

    elseif Input == 'SetFreezePlayer' and tobool(Args) then
        self.FreezePlayer = false
        for i, v in pairs(self.Subjects) do
            if v and v:IsValid() and v:IsPlayer() then
                v:Freeze(self.FreezePlayer)
            end
        end

        elseif Input == 'disable' then
            self:Setdisabled(true)
        elseif Input == 'enable' then
            self:Setdisabled(false)
        end
    end
end