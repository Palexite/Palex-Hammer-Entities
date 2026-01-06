include('shared.lua')

local function HandleStateChange(self, name, old, new)

    if self.VGUI then
        self.VGUI:UpdateState(old, new)
    end

end

local function DrawUI(self)
    if not self.VGUI then
        self.VGUI = vgui.Create(self:GetUI())
    end
    if self.VGUI and self.VGUI:IsValid() and self:GetPlayer() == LocalPlayer() then
    local pos = self:GetPos()
    local ang = self:GetAngles()
    local scale = 0.5
    local pl = LocalPlayer()

        if self.GetLockToScreen and self:GetLockToScreen() then
        local eyeup = Vector(EyeAngles():Up())
            local traceres = util.TraceLine({
                start = EyePos(),
                endpos = EyePos() + (EyeVector()) + (eyeup * (self:GetOffset().Z * 0.01))}) -- Traceline is needed in order to get the correct normal, otherwise soley using EyeVector would result in weird panning by the UI in regards to it's offset.
        

            pos = (EyePos()) + (traceres.Normal * 128)
        end
        if self:GetLockToPlayerDirection() then
            ang = EyeAngles()
            ang:RotateAroundAxis(ang:Up(), 270)
	        ang:RotateAroundAxis(ang:Forward(), 90)
        end
        if self.GetScale then
            scale = self:GetScale()
        end

        
    self.VGUI:UpdateFunc(self, pos, ang, scale)
    end
end

function ENT:Initialize()
    self:SetRenderMode(RENDERMODE_ENVIROMENTAL)
self:NetworkVarNotify('State', function(name, old, new) timer.Simple(0.05, function() HandleStateChange(self, name, old, self:GetState()) end) end)

hook.Add('PostDrawOpaqueRenderables', 'PHE_QTE_' .. self:EntIndex(), function() DrawUI(self) end)
end

function ENT:OnRemove()
hook.Remove('PostDrawOpaqueRenderables', 'PHE_QTE_' .. self:EntIndex())

end