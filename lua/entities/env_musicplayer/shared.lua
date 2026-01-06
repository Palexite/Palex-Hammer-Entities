include('emp_dictionary.lua')
include('lyrics.lua')
ENT.Type = 'anim'



function ENT:SetupDataTables()
    self:NetworkVar('Float', 0, 'TargetVolume')
    self:NetworkVar('Float', 1, 'VolumeChangeDuration')
    self:NetworkVar('Float', 2, 'LoopStart')
    self:NetworkVar('Float', 3, 'LoopEnd')
    self:NetworkVar('Float', 4, 'LoopFade')


    self:NetworkVar('Int', 0, 'SubTracks')
    self:NetworkVar('Int', 1, 'ToggleEffects')

    self:NetworkVar('String', 0, 'Track')
    self:NetworkVar('String', 1, 'VolumeFunction')
    self:NetworkVar('Bool', 2, 'LyricsEnabled')
    self:NetworkVar('Bool', 3, 'Looping')
    self:NetworkVar('Bool', 4, 'Enabled')
    self.StartVol = nil

    if SERVER then
    util.AddNetworkString('PHE_MusicPlayer_Task')
    end

    if CLIENT then

            self.EMPTracks = { -- WHEN THE FUCK WILL THEY FIX SELF NOT FUCKING WORKING. CAN'T ASSIGN TO the ENT TABLE BECAUSE LUA IS FUCKING STUPID WHEN IT COMES TO NET.RECIEVE. DEAR FUCKING GOD.
    ['LP_TheEmptinessMachine'] = {
    ['Name'] = 'The Emptiness Machine',
    ['Artist'] = 'Linkin Park',
    ['SubTracks'] = 
        {
            {
                Sound = 'sound/obj_panter/emptinessmachine_inst.ogg', -- PUT THE LONGEST AUDIO FILE ON TOP OR ELSE STUFF MAY BREAK. This is used for time tracking for other tracks and their channels.
                FadeIn = 1,
                FadeOut = 4,
                FadeFunction = 'InOutSine'
            },

            {
                Sound = 'sound/obj_panter/emptinessmachine_cape_trimmed.ogg',
                FadeIn = 2,
                FadeOut = 4,
                FadeFunction = 'InOutSine',
                LyricChannel = true
            }
        }
    }
}


        self.Channels = {}
        self.TempChannels = {}
        self.TickTasks = {}
        self.LyricChannel = 1
        self.Lyric = ''

        self.LyricOldColor = Color(141 ,141 ,141)
        self.LyricOldPeakColor = Color(255 ,255 ,255)
        self.LyricOldSize = 1
        self.LyricOldShadowColor = Color(0, 0, 0, 255)
        self.LyricOldShadowOffset = {X = 4, Y = 4}
        self.LyricOldShadowDance_Freq = 8

        self.LyricSize = 1
        self.LyricPeakSizeMulti = 1.4
        self.LyricColor = Color(141 ,141 ,141)
        self.LyricPeakColor = Color(255 ,255 ,255)
        self.LyricShadowColor = Color(0, 0, 0, 255)
        self.LyricShadowDance = true
        self.LyricShadowOffset = {X = 42, Y = 42}
        self.LyricShadowDance_Freq = 8
        self.LyricFont = 'PHE_EMP_Arial'

    end
end

function ENT:KeyValue(key, value)
    if key == 'track' then
        self:SetTrack(value)

    elseif key == 'subtracks' and isnumber(tonumber(value)) then
        self:SetSubTracks(tonumber(value))

    elseif key == 'lyrics' and isbool(tobool(value)) then
    self:SetLyricsEnabled(tobool(value))

    elseif key == 'loop' and isbool(tobool(value)) then
    self:SetLooping(true)
    print(tobool(value))

    elseif key == 'targetvolume' and isnumber(tonumber(value)) then
        self:SetTargetVolume(tonumber(value))

    elseif key == 'volumechangeduration' and isnumber(tonumber(value)) then
        self:SetVolumeChangeDuration(tonumber(value))

    elseif key == 'volumechangefunc' and isnumber(tonumber(value)) then
        self:SetVolumeFunction(tonumber(value))
    
    elseif key == 'lyrics' and isbool(tobool(value)) then
        self:SetLyricsEnabled(tobool(value))

    elseif key == 'StartDisabled' and isbool(tobool(value)) then
        self:SetEnabled(not tobool(value))

    elseif key == 'loopstart' and isnumber(tonumber(value)) then
        self:SetLoopStart(value)
    elseif key == 'loopend' and isnumber(tonumber(value)) then
        self:SetLoopEnd(value)
    elseif key == 'loopfade' and isnumber(tonumber(value)) then
        self:SetLoopFade(tonumber(value))
    elseif key == 'togglefx' and isnumber(tonumber(value)) then 
        self:SetToggleEffects(tonumber(value))
    end
end


function ENT:Initialize()
self:SetRenderMode(RENDERMODE_ENVIROMENTAL)
end

