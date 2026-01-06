AddCSLuaFile('cl_init.lua')
ENT.Type = 'anim'

function ENT:SetupDataTables()
    self:SetRenderMode(RENDERMODE_ENVIROMENTAL)
    self:Spawn()
end

function ENT:AcceptInput(Input, Activator, Caller, Params)
    if Input == 'CacheModel' then
    self:Spawn()
    elseif Input == 'SetModel' then
    self:SetModel(Params)
    end
end

function ENT:CacheModel()
    self:Spawn()
end