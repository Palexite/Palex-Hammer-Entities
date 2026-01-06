AddCSLuaFile('cl_init.lua')
ENT.Type = 'anim'
--local valid_principles = {'SPEED', 'HEALTH', 'MAXSPEED', 'MAXHEALTH'}


function ENT:SetupDataTables()
    self.Principle = 'MaxSpeed'

    self:NetworkVar('Bool', 0, 'ShowUI')
    self:NetworkVar('Bool', 1, 'ShowPB')
    self:NetworkVar('Bool', 2, 'LocalizeUI')
    self:NetworkVar('Float', 0, 'Bar')
    self:NetworkVar('Float', 1, 'MarginBar')
    self:NetworkVar('Float', 2, 'Progress')
    self:NetworkVar('Float', 3, 'MaxProgress')
    self:NetworkVar('Float', 4, 'UIScale')
    self:NetworkVar('Float', 5, 'Value')
    self:NetworkVar('Entity', 0, 'Player')

    self.principle_funcs = {
    ['SPEED'] = function() return self:GetPlayer():GetVelocity():Length() end,
    ['HEALTH'] = function() return self:GetPlayer():Health() end,
    ['MAXSPEED'] = function() return self:GetPlayer():GetMaxSpeed() end,
    ['MAXHEALTH'] = function() return self:GetPlayer():GetMaxHealth() end,
    ['JUMPPOWER'] = function() return self:GetPlayer():GetJumpPower() end,
    ['SCALE'] = function() return self:GetPlayer():GetModelScale() end,
    ['VIEWPUNCH'] = function() return self:GetPlayer():GetViewPunchVelocity():GetLength() end,
    ['FRAGS'] = function() return self:GetPlayer():Frags() end,
    ['DEATHS'] = function() return self:GetPlayer():Deaths() end,
    ['ARMOR'] = function() return self:GetPlayer():Armor() end
}
end



function ENT:KeyValue(k, v)
    if string.StartsWith(k,'On') then 
        self:StoreOutput(k, v)
    elseif k == 'principle' then
        self.Principle = v
    elseif k == 'showpb' and tobool(v) then
        self:SetShowPB(tobool(v))

    elseif k == 'showui' and tobool(v) then
        self:SetShowUI(tobool(v))
        print(self:GetShowUI())
    elseif k == 'localizeui' and tobool(v) then
        self:SetLocalizeUI(tobool(v))
    
    elseif k == 'uiscale' and tonumber(v) then
        self:SetUIScale(tonumber(v))

    elseif k == 'bar' and tonumber(v) then
        self:SetBar(tonumber(v))

    elseif k == 'barmargin' and tonumber(v) then
        self:SetMarginBar(tonumber(v))

    elseif k == 'maxprogress' and tonumber(v) then
        self:SetMaxProgress(tonumber(v))

    elseif string.Left(k, 2) == 'On' then
    self:StoreOutput(k, v)
    end
end

function ENT:AcceptInput(Input, Activator, Caller, Params)
    if Input == 'GetValue' and self:GetPlayer() and self:GetPlayer():IsPlayer() and self:GetPlayer():IsValid() then
    self:TriggerOutput('OnGetValue', Activator, self.principle_funcs[string.upper(self.Principle)]())

    elseif Input == 'SetPlayerUsingActivator' and Activator and Activator:IsValid() and Activator:IsPlayer() then
        self:SetPlayer(Activator)
        local value = self.principle_funcs[string.upper(self.Principle)]()
        self:SetValue(value)
        if (value > self:GetBar() - self:GetMarginBar()) and (value < self:GetBar() + self:GetMarginBar()) then
            self:TriggerOutput('OnNeutral', Activator)

        elseif value < self:GetBar() then
            self:TriggerOutput('OnNegative', Activator)
        else self:TriggerOutput('OnPositive', Activator)
        end


    elseif Input == 'SetPrinciple' and table.HasValue(string.upper(Params)) then 
        self.Principle = Params

    if self:GetPlayer() and self:GetPlayer():IsValid() then
        self:SetValue(self.principle_funcs[string.upper(self.Principle)]())
    end

    elseif Input == 'SetShowProgressBar' and tobool(Params) then
    self:SetShowPB(tobool(Params))
    
    elseif Input == 'SetShowUI' and tobool(Params) then
    self:SetShowPB(tobool(Params))

    elseif Input == 'SetBar' and tonumber(Params) then
        self:SetBar(tonumber(Params))

    elseif Input == 'SetProgress' and tonumber(Params) then
        self:SetProgress(tonumber(Params))
        print(Params)
    elseif Input == 'SetMaxProgress' and tonumber(Params) then
        self:SetMaxProgress(tonumber(Params))
    elseif Input == 'SetMargin' and tonumber(Params) then 
        self:SetMargin(tonumber(Params)) 

    elseif Input == 'SetUIScale' and tonumber(Params) then
    self:SetUIScale(tonumber(Params))
    
    end
end