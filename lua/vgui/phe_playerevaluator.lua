local PANEL = {}

surface.CreateFont('zs_pe', {font = 'hidden', size = 128, blursize = 0, shadow = true})
function PANEL:DrawFunc(ent)
    if ent:GetPlayer() and ent:GetPlayer():IsValid() then -- Sometimes Network Vars don't initialize immediately.
        if ent:GetLocalizeUI() and not ent:GetPlayer() == LocalPlayer() then
        return end
    cam.Start3D2D(ent:GetPos(), ent:GetAngles(), ent:GetUIScale() * 0.05)

    if ent:GetShowUI() then
        surface.SetDrawColor(45, 45, 45, 127)
        if ent:GetShowPB() then
        surface.DrawRect(0, 0, 1024, 256)
        else
        surface.DrawRect(0, 0, 1024, 128)
        end


        local text_color = Color(255, 255, 255, 255)
        local extrasign = '+'

            if (ent:GetValue() >= ent:GetBar() - ent:GetMarginBar()) and (ent:GetValue() <= ent:GetBar() + ent:GetMarginBar()) then
                extrasign = ''
            elseif (ent:GetValue() < ent:GetBar() - ent:GetMarginBar()) then
                text_color = Color(255, 0, 0, 255)
                extrasign = ''
                draw.SimpleTextOutlined(extrasign .. ent:GetValue() - (ent:GetBar() - ent:GetMarginBar()), 'zs_pe', 1024, 0, text_color, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1)
            elseif (ent:GetValue() > ent:GetBar() + ent:GetMarginBar()) then
                text_color = Color(0, 255, 0, 255)
                draw.SimpleTextOutlined(extrasign .. ent:GetValue() - (ent:GetBar() - ent:GetMarginBar()), 'zs_pe', 1024, 0, text_color, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1)
            end

        draw.SimpleTextOutlined(ent:GetValue(), 'zs_pe', 0, 0, text_color, TEXT_ALIGN_TOP, TEXT_ALIGN_TOP, 1)
    end

    if ent:GetShowPB() then
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawOutlinedRect(0, 128, 1024, 64, 4)
        local ratio = ent:GetProgress() / ent:GetMaxProgress()
        surface.DrawRect(6, 130, (1018 * ratio), 58)
    end
    cam.End3D2D()
    end
end

vgui.Register('phe_playerevaluator', PANEL, 'Panel')