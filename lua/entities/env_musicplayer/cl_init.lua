include('shared.lua')




function ENT:AddTask(name, taskname, data)
    data.Prefix= taskname .. '_' .. name 
    data.TaskName = taskname
    self.Tasks[taskname](self, data)
end

function ENT:AddTickTask(name, taskname, data)
    data.Prefix= taskname .. '_' .. name 
    data.TaskName = taskname
self.TickTasks[data.Prefix] = data
end


local function RenderLyrics(self)
    if self.LyricVGUI and self.LyricVGUI:IsValid() then
        self.LyricVGUI:RenderFunc(self)
    else
    self.LyricVGUI = vgui.Create('emp_lyrics')
    end
end


------------------------------------------------------------------------------------------------------------------

function ENT:RecalcChannelOffset(index) -- Needed due to the existence of Pause and Play Macros and the ability to set the time of a track. Thankfully this should only have to be calculated once.
    local chans = self.Channels
    local firstchan = chans[1]
    local firstchan_t = firstchan:GetTime()
    local trackmacrostbl = self.TrackMacros[self:GetTrack()]
    local chan_offset = 0
    local chan_status = false
    if trackmacrostbl and trackmacrostbl[1] then
        local chanmacrostbl = trackmacrostbl[index]
        if chanmacrostbl then
            for t1, tbl in pairs(chanmacrostbl) do
                if t1 <= firstchan_t then -- If it happened before given time, we need to register the whitespace it has left behind, otherwise please fuck off.
                    if table.HasValue(tbl, 'Pause') then
                        local oldpause = t1
                        local nextplay = 999999
                        local status = false

                        for t2, tbl2 in pairs(chanmacrostbl) do
                            if table.HasValue(tbl2, 'Play') then
                                if t2 <= nextplay then
                                    if t2 >= t1 then
                                        if firstchan_t >= t2 then -- if right after a pair of a pause and resume macro.
                                            nextplay = t2
                                            status = false
                                        elseif firstchan_t < t2 then -- If before a resume but after a pause
                                            nextplay = firstchan_t - t1
                                            status = true
                                        end
                                    end
                                end
                            end
                        end
                        local t2offset = nextplay - t1
                        
                        chan_offset = chan_offset + t2offset
                        chan_status = status
                    end
                end
            end
            return chan_offset, chan_status
        else
        return chan_offset, chan_status
        end 
    else
        return chan_offset, chan_status
    end
end

function ENT:Initialize()

    self.LoopInProgress = false
    self.ChannelInitialStates = {}
    self.OldTrack = ''
    self.TrackInit = false
    self.MacroStream = {}
    self.LyricMacroStream = {}
    self:NetworkVarNotify('Track', function(ent, name, o, n)
        self:AddTask('IO', 'StartTrack', {Track = n, FadeDuration = self:GetVolumeChangeDuration(), OldTrack = self.OldTrack}) 
    end)
    if self:GetEnabled() then
        self:AddTask('IO', 'StartTrack', {Track = self:GetTrack(), FadeDuration = self:GetVolumeChangeDuration(), OldTrack = self.OldTrack})
        self.TrackInit = true
    else
        self.TrackInit = false
    end
    self:NetworkVarNotify('SubTracks', function(ent, name, o, n)
        self:AddTask('IO', 'SetActiveSubTracks', {SubTracks = n})
    end)

    self:NetworkVarNotify('Enabled', function(ent, name, o, n) 
        if n == true then
            if self.TrackInit == false then 
                self:AddTask('IO', 'StartTrack', {Track = self:GetTrack(), FadeDuration = self:GetVolumeChangeDuration(), OldTrack = self.OldTrack}) 
            else
                self:AddTask('Enable', 'ResumeActiveTracks', {})
            end
        else
            self:AddTask('Disable', 'PauseAllTracks', {})
        end
    
    end)



    hook.Add('PreDrawEffects', 'PHE_EMP_PreDrawEffects' .. self:EntIndex(), function()
        if self.GetLyricsEnabled and self:GetLyricsEnabled() then
            RenderLyrics(self) 
        end 
    end)
end

local function TaskTick(self)
    for i, data in pairs(self.TickTasks) do
    local shouldkill = self.Tasks[data.TaskName](self, data)
        if shouldkill then
            self.TickTasks[i] = nil
        end
    end
    
end
local function MacroTick(self)
    for i, v in ipairs(self.Channels) do
        subtrackmacros = self.MacroStream[i]
        if subtrackmacros then
            for t, m in SortedPairs(subtrackmacros) do
                if self.Channels[1]:GetTime() >= t then
                    if m[1] then
                        local shouldkill = self.Macros[m[1]](self, m, i, self.Channels[1]:GetTime(), v)
                        if shouldkill then
                            subtrackmacros[t] = nil
                        end
                    end
                end 

            end

        end
    end

    local lyricmacros = self.LyricMacroStream
    local lyricchan = self.Channels[self.LyricChannel]
        if lyricmacros and lyricchan and lyricchan:IsValid() then
            local lyricchan_t = lyricchan:GetTime()

            for t, cmds in SortedPairs(lyricmacros) do

                if lyricchan_t >= t then
                    for i, v in pairs(cmds) do
                        local shouldkill = self.LyricMacros[i](self, v, t, lyricchan)
                        if shouldkill then
                            cmds[i] = nil
                            lyricmacros[t] = cmds
                        end
                    end 

                    if table.IsEmpty(lyricmacros[t]) then
                        self.LyricMacroStream[t] = nil
                    end
                end
            end
        end

end

local function LyricTick(self)
    local lyricchan = self.Channels[self.LyricChannel]
    if lyricchan and lyricchan:IsValid() then
        local chantime = lyricchan:GetTime()
        local lyrictbl = PHE_Lyrics[self:GetTrack()]

        local oldlyrictime = 0
        if lyrictbl then
                for i, v in pairs(lyrictbl) do
                    if i <= chantime and (not oldlyrictime or oldlyrictime <= i) then
                        oldlyrictime = i
                        self.Lyric = v
                    else

                    end
                end
            end
        end
end

local function LoopTick(self)
    local firstchan = self.Channels[1]
        if firstchan and firstchan:IsValid() then
            if firstchan:GetTime() >= self:GetLoopEnd() then
                self:AddTask('LoopTimeUpdate', 'SetPos', {Time = self:GetLoopStart(), Fade = self:GetLoopFade()})
            end
        end

end


function ENT:Think()
    TaskTick(self)

    if self.Channels[1] and self.Channels[1]:IsValid() then
    MacroTick(self)
    end
    LyricTick(self)

        if self:GetLooping() then
            LoopTick(self)
        end

    self:SetNextClientThink(0)


return true
end