ENT.Type = 'anim'
PHE_anmmodel = {}
function ENT:SetupDataTables()
self:Spawn()
end
function ENT:Initialize()
timer.Simple(1, function()
PHE_anmmodel[self:EntIndex()] = ClientsideModel(self:GetModel(), RENDERGROUP_OTHER)
PHE_anmmodel[self:EntIndex()]:SetPos(self:GetPos())
PHE_anmmodel[self:EntIndex()]:SetRenderMode(RENDERMODE_ENVIROMENTAL)
RunConsoleCommand('r_flushlod') end) -- may crash ppls games but oh well, there is no other way.
print('r_flushloding complete! animations hopefully loaded.')
end