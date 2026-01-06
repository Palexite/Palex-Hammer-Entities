AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
AddCSLuaFile('lyrics.lua')
AddCSLuaFile('emp_dictionary.lua')
AddCSLuaFile('vgui/EMP_Lyrics.lua')
AddCSLuaFile('emp_dictionary.lua')
include('shared.lua')

function ENT:AcceptInput(Input, Activator, Caller, Params)
    if Input == 'Disable' then
self:SetEnabled(false)
    elseif Input == 'Enable' then
        self:SetEnabled(true)

    elseif Input == 'SetTime' and tonumber(Params) then

        net.Start('PHE_MusicPlayer_Task')
            net.WriteString('SetPos')
                        net.WriteEntity(self)
                net.WriteFloat(tonumber(Params))
        net.Broadcast()

    elseif Input == 'SnapToNode' then
        net.Start('PHE_MusicPlayer_Task')
            net.WriteString('SnapPosToNode')
            net.WriteEntity(self)
            net.WriteString(Params)
        net.Broadcast()
        
    elseif Input == 'SetTrack' then
    self:SetTrack(Params)

    elseif Input == 'SetSubTracks' and tonumber(Params) then
        self:SetSubTracks(tonumber(Params))

    elseif Input == 'SetTargetVolume' and tonumber(Params) then
        self:SetTargetVolume(tonumber(Params))
    
    elseif Input == 'SetVolumeChangeDuration' and tonumber(Params) then
        self:SetVolumeChangeDuration(tonumber(Params))
    
    elseif Input == 'SetVolumeFunction' then 
        self:SetVolumeFunction(Params)
    
    elseif Input == 'SetLyricsEnabled' and tobool(Params) then 
    self:SetLyricsEnabled(tobool(Params))

    elseif Input == 'SetLooping' and isbool(tobool(Params)) then
        self:SetLooping(tobool(Params))
    

    elseif Input == 'SetLoopStart' and isnumber(tonumber(Params)) then
        self:SetLoopStart(tonumber(Params))

    elseif Input == 'SetLoopEnd' and isnumber(tonumber(Params)) then
        self:SetLoopEnd(tonumber(Params))
        
    elseif Input == 'SetLoopFade' and isnumber(tonumber(Params)) then
        self:SetLoopFade(tonumber(Params))

    elseif Input == 'SetToggleEffects' and isnumber(tonumber(Params)) then
        self:SetToggleEffects(tonumber(Params))
    end
end

function ENT:UpdateTransmitState()
return true end
