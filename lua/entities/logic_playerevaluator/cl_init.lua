ENT.Type = 'anim'


function ENT:Initialize()
self.VGUI = nil
end

function ENT:SetupDataTables()
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
end

function ENT:Draw()
    if (not self.VGUI or not self.VGUI:IsValid()) then
        self.VGUI = vgui.Create('phe_playerevaluator')
    end
    
    self.VGUI:DrawFunc(self)
end

function ENT:Remove()
if self.VGUI then
    self.VGUI:Remove()
end
end