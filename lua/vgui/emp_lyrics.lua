local PANEL = {}


function PANEL:Init()
local OldLyric = ''
self.Offset = Vector(0, 0, 8)
self.NextShadowDance = 1
self.CurrentShadowDanceOffset = {X = 1, Y = 1}
end

function PANEL:RenderFunc(ent)
    local pl = LocalPlayer()
    local finalpos = EyePos() + (EyeVector() * 16)
    local finalang = EyeAngles()

    local lyricchan = ent.Channels[ent.LyricChannel]
    if lyricchan and lyricchan:IsValid() then
        local textcolor = LerpVector(lyricchan:GetLevel(), ent.LyricColor:ToVector(), ent.LyricPeakColor:ToVector())
        local textcolor_rgb = textcolor:ToColor()


        -- Shadow FX stuff, similar to how Zombie Survival does it
        local nextshadowdance = self.NextShadowDance
        local shadowcolor = ent.LyricShadowColor:Copy()
        local shadowdance = ent.LyricShadowDance
        local LyricShadowOffset = ent.LyricShadowOffset
        local LyricShadowFreq = ent.LyricShadowDance_Freq
        local font = ent.LyricFont

        local curdanceshadowoffset = self.CurrentShadowDanceOffset
        local finalshadowoffset = {X = 0, Y = 0}



            self.NextShadowDance = self.NextShadowDance - 1

        if shadowdance then
            if nextshadowdance <= 0 then
                self.NextShadowDance = (10 / LyricShadowFreq)
                curdanceshadowoffset = {X = math.Rand(-1, 1), Y = math.Rand(-1, 1)}
                self.CurrentShadowDanceOffset = curdanceshadowoffset
            end
        end
        finalshadowoffset.X = curdanceshadowoffset.X * LyricShadowOffset.X
        finalshadowoffset.Y = curdanceshadowoffset.Y * LyricShadowOffset.Y


        textcolor_rgb.a = textcolor_rgb.a * lyricchan:GetVolume()
        local textoutlinecolor = Color(0, 0, 0, 255)
        textoutlinecolor.a = textcolor_rgb.a
        shadowcolor.a = shadowcolor.a * (textcolor_rgb.a / 255 )

        local finaltextcolor = textcolor_rgb

            finalang:RotateAroundAxis(finalang:Up(), 270)
            finalang:RotateAroundAxis(finalang:Forward(), 45)
            if ent and ent:IsValid() and ent.Lyric then
                cam.Start3D2D(finalpos, finalang, (0.004 * ent.LyricSize) + ((0.0001 * lyricchan:GetLevel()) * ent.LyricPeakSizeMulti))

                -- Drawing the shadow
                    draw.SimpleText(ent.Lyric, font, finalshadowoffset.X, ScrH() + finalshadowoffset.Y, shadowcolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                -- Drawing actual text
                draw.SimpleTextOutlined(ent.Lyric, font, 0, ScrH(), finaltextcolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 6, textoutlinecolor)


                cam.End3D2D()
            end
    end
end

vgui.Register('emp_lyrics', PANEL, 'Panel')