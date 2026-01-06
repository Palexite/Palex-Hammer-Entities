PANEL = {}
surface.CreateFont('zs_qte', {font = 'hidden', size = 254, blursize = 0, shadow = true})
local BGTexture = Material('effects/zs_qte_ray')
BGTexture:SetVector( "$color", Vector(4, 4, 4))
BGTexture:Recompute()
local boxmin, boxmax = Vector(-128, -128, -16), Vector(128, 128, 16)
-- effects/strider_bulge_dx60
-- effects/blueflare1.vmt
function PANEL:UpdateFunc(ent, pos, ang, scale)
    local final_scale = scale

    local final_pos = pos
    local final_ang = ang
    local final_color = Vector(4, 4, 4)
    if self.StateTime then
        if self.State == 0 then -- Disabled
            local ratio = math.Clamp((CurTime() - self.StateTime) / (0.5), 0, 1)
            final_scale = Lerp(math.ease.OutElastic(ratio), self.OldScale, 0)
            final_color = Vector(4, 4, 4)

        elseif self.State == 1 then -- Enabled

            local ratio = math.Clamp((CurTime() - self.StateTime) / (0.5), 0, 1)
            final_scale = Lerp(math.ease.OutElastic(ratio), self.OldScale, scale)
            final_color = Vector(4, 4, 4)

        elseif self.State == 2 then -- Success
        local ratio = math.Clamp((CurTime() - self.StateTime) / (0.1), 0, 1)
        final_scale = Lerp(ratio, self.OldScale, self.OldScale + 2)
        final_color = LerpVector(ratio, self.OldColor, Vector(0, 0, 0))
        

        elseif self.State == 3 then -- Failure
            local ratio = math.Clamp((CurTime() - self.StateTime) / (0.2), 0, 1)
            local ratio2 = math.Clamp(((CurTime() - 0.2) - self.StateTime) / (0.2), 0, 1)

            if CurTime() < self.StateTime + 0.2 then

            final_color = LerpVector(ratio, self.OldColor, Vector(4, 0, 0)) -- Changing color to red

            else
            final_color = LerpVector(ratio2, Vector(4, 0, 0), Vector(0, 0, 0)) -- Fading out
            end
        end
    end

    if ent and ent:IsValid() then
        cam.Start3D2D(final_pos, final_ang, final_scale * 0.2)
            if self.StateTime and ent.GetKey then
                local ct = CurTime()
                cam.IgnoreZ(ent:GetIgnoreZ())
                BGTexture:SetVector("$color", final_color)
                render.SetMaterial(BGTexture)
                local color = final_color:ToColor()
                color.a = color.r
                local color_outline = Color(0, 0, 0, color.a)
                render.DrawBox(vector_origin + Vector(5, 10, 0), self.OldBoxAng + Angle(0, 20, 0), boxmin, boxmax)
                draw.SimpleTextOutlined(ent:GetKey(), 'zs_qte', 0, 0, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0, color_outline)
                cam.IgnoreZ(false)
            self.OldBoxAng = self.OldBoxAng + Angle(0, 20, 0)
            self.OldPos = pos

            self.CurrentScale = final_scale
            self.CurrentColor = final_color
            end
            cam.End3D2D()
    end
end

function PANEL:Init()
self.State = 0
self.StateTime = CurTime()

self.OldPos = 0
self.OldBoxAng = Angle(0, 0, 0)
self.OldScale = 0
self.OldColor = Vector(4, 4, 4)

self.CurrentColor = Vector(4, 4, 4) -- Currents so we can change values only during a state switch in order to keep the Lerp animations smooth.
self.CurrentScale = 0
end

function PANEL:UpdateState(old, new)
self.OldState = old
self.State = new
self.StateTime = CurTime()

self.OldScale = self.CurrentScale
self.OldColor = self.CurrentColor
end

vgui.Register('qte_zombiesurvival', PANEL, 'Panel')