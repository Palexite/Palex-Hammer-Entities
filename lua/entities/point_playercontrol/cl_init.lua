include('shared.lua')

local function PlayerInputControl(id, pl, cmd)
    local self = Entity(id)
    if self.Getdisabled and not self:Getdisabled() then
        local pltable = nil
        local directory = PHE_PPC_Registry[self:EntIndex()]
        pltable = directory.subjects

        if pltable and table.HasValue(pltable, pl:UserID()) then
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

local function PlayerRotationControl(id, cmd)
    local self = Entity(id)
    if self and self:IsValid() and self.Getdisabled and not self:Getdisabled() then
        local directory = PHE_PPC_Registry[id]
        pltable = directory.subjects

        if pltable and table.HasValue(pltable, LocalPlayer():UserID()) then
            if self:Getfaceangles() then
                cmd:SetViewAngles(self:GetAngles())
            return true end
        end
    end
end

net.Receive('PHE_PPC_Subject', function()
local pps_id = net.ReadUInt(13)
local pl_id = net.ReadUInt(7) + 1
local enabled = net.ReadBool()
if pl_id == LocalPlayer():UserID() then
    if enabled then
        hook.Add('InputMouseApply', 'PHE_PPC_Rotation_' .. pps_id, function(cmd) PlayerRotationControl(pps_id, cmd) end)
        hook.Add('StartCommand', 'PHE_PPC_' .. pps_id, function(pl, cmd) PlayerInputControl(pps_id, pl, cmd) end)
    else
        hook.Remove('InputMouseApply', 'PHE_PPC_Rotation_' .. pps_id)
        hook.Remove('StartCommand', 'PHE_PPC_' .. pps_id)
    end
end

local directory = PHE_PPC_Registry[pps_id]
    if not PHE_PPC_Registry[pps_id] then
        PHE_PPC_Registry[pps_id] = {}
        directory = PHE_PPC_Registry[pps_id]
    end

        if not directory['subjects'] and enabled then
            directory['subjects'] = {pl_id}
        elseif enabled then
            table.insert(directory['subjects'], pl_id)
        elseif not enabled and directory['subjects'] then table.RemoveByValue(directory['subjects'], pl_id) end
end)

net.Receive('PHE_PPC_Animate', AnimateSetup)