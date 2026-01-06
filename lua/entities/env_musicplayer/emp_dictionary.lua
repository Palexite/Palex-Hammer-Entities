include('lyrics.lua')

function PHE_EMP_GetIndexFromKey(tbl, key)
local keytbl = table.GetKeys(tbl)
return keytbl[key] end

function PHE_EMP_GetKeyFromIndex(tbl, index)
local keytbl = table.GetKeys(tbl)
return table.KeyFromValue(keytbl, index) end

local function HandleNewTrack(self, Chan, nu, str, fadein, fadefunc, index, time)
    local offset = 0
    local pause = false
    if index >= 2 then
        offset, pause = self:RecalcChannelOffset(index)
            timer.Simple(5, function()
            end)
                        timer.Simple(2, function()
                        print('Channel is currently ' .. Chan:GetState(), Chan)
            end)
    else
    
    end
    if not isnumber(nu) then
        Chan:SetVolume(0)

        if time then
            Chan:SetTime(time - offset)
        end


        local trackinfo = self.EMP_Tracks[self:GetTrack()]
        local subtrackinfo = trackinfo.SubTracks[index]
        self.Channels[index] = Chan
        if subtrackinfo.LyricChannel then
            self.LyricChannel = index
            self:AddTask('RecalcLyricMacroStream', 'RecalcLyricMacroStream', {TrackTime = Chan:GetTime()})
        
        end
        self:AddTask('RecalcMacroStream', 'RecalcMacroStream', {TrackTime = Chan:GetTime(), Index = index})
        self:AddTickTask('SubTrack' .. index, 'VolumeModTick', {Chan = Chan, StartVolume = Chan:GetVolume(), TargetVolume = self:GetTargetVolume(), StartTime = CurTime(), Duration = fadein, Func = fadefunc})

        if not paused then
            Chan:Play()
            self.ChannelInitialStates[index] = true
        else

            self.ChannelInitialStates[index] = false
        end
    end
end

---------------------------------------------------------------------- TABLE STUFF -------------------------------------------------------------------------------------------------------------------------
    ENT.EMP_Tracks = {
        ['Palex_SurgeStreet'] = {
        ['Name'] = 'Surge Street',
        ['Artist'] = "Palexite",
        ['SubTracks'] =
         {
            {
            Sound = 'sound/map/palex_surgestreet_drumbass.ogg',
            FadeIn = 2,
            FadeOut = 2,
            FadeFunction = 'InOutSine'
            },
            {
            Sound = 'sound/map/palex_surgestreet_electricguitar.ogg',
            FadeIn = 2,
            FadeOut = 2,
            FadeFunction = 'InOutSine'
            },
            {
            Sound = 'sound/map/palex_surgestreet_synth.ogg',
            FadeIn = 2,
            FadeOut = 2,
            FadeFunction = 'InOutSine',
            }
        }
    },
}

ENT.TrackMacros = {}

ENT.NodeProfiler = {
}


--------------------------------TASK FUNCTIONS-------------------------------------


local function VolumeMod(self, data)
    local tgrchans = data.TargetChans
    if data.Kill then
        for i, v in pairs(tgrchans) do
            self.TempChannels[i] = v -- Moving to the temporary channel.
            self.Channels[i] = nil
            self:AddTickTask(1 .. '_' .. i, 'VolumeModTick', data)
        end
    end
end


local function VolumeModTick(self, data)
    local startvol = data.StartVolume
    local targetvol = data.TargetVolume
    local dur = data.Duration
    local func = data.Func
    local st = data.StartTime
    local chan = data.Chan
    local remainder = CurTime() - st
    local ratio  = math.Clamp(remainder / dur, 0, 1)
    local finalvol = Lerp(math.ease['InOutSine'](ratio), startvol, targetvol)
    if chan and chan:IsValid() then
        chan:SetVolume(finalvol)
    end
    if ratio >= 1 then
        if data.Kill then
        end
        if data.Pause then
        chan:Pause()
        end
        return true
    end
end


local function SetPos(self, data)
    local pos = data.Pos
    local nodename = data.NodeName
    local nodepfp = self.NodeProfiler[self:GetTrack()]
    local tracktbl = self.EMPTracks[self:GetTrack()]
    if nodename then
        local randompospool = {}

        for i, v in pairs(nodepfp) do
            if v['Name'] == nodename then
                randompospool[i] = v
            end
        end

        if not table.IsEmpty(randompospool) then

            local args, t = table.Random(randompospool)
            local tracktbl = self.EMP_Tracks[self:GetTrack()]
            local fadein = self:GetVolumeChangeDuration()
            local func = self:GetVolumeFunction()
            if args['FadeIn'] then
                fadein = args['FadeIn']
            end

            if args['Func'] then
                func = args['Func']
            end

            if tracktbl then
                self:AddTask('SetPosTrackStart', 'StartTrack', {OldTrack = self:GetTrack(), Track = self:GetTrack(), Time = t, Fade = fadein, Func = func, isNetworked = true})
            end
        end
    else
        local t = data.Time
        local func = 'InOutSine'
        local fadein = self:GetVolumeChangeDuration()

        if data.FadeIn then
            fadein = data.FadeIn
        end

        if data.Func then
            func = data.Func
        end

         self:AddTask('SetPosTrackStart', 'StartTrack', {OldTrack = self:GetTrack(), Track = self:GetTrack(), Time = t, Fade = fadein, Func = func, isNetworked = true})
    
    
    end
end

local function SpeedMod(self, data)
    local start_s = data.StartSpeed
    local target_s = data.TargetSpeed
    local dur = data.Duration
    local func = data.Func
    local st = data.StartTime
    local chan = data.Chan
    local remainder = CurTime() - st
    local ratio  = math.Clamp(remainder / dur, 0, 1)
    local finalspeed = Lerp(math.ease['InOutSine'](ratio), start_s, target_s)
    if chan and chan:IsValid() then
        chan:SetPlaybackRate(finalspeed)
    end
    if ratio >= 1 then
        if data.Pause then
            chan:Pause()
        end
        return true
    end
end

local function RecalcMacroStream(self, data)
    local tracktime = data.TrackTime
    local curtrack = self:GetTrack()
    local subtrack = data.Index
    local trackmacros = table.Copy(self.TrackMacros[curtrack])
    local chan = self.Channels[subtrack]
    if trackmacros then
        local subtrackmacros = table.Copy(trackmacros[subtrack])
        if subtrackmacros then
            for t, cmds in SortedPairs(subtrackmacros) do
                if t >= tracktime then
                    subtrackmacros[t] = cmds
                else
                    if cmds[1] == 'Pause' or cmds[1] == 'Play' then -- These are already executed as part of a different function.

                    else
                        local shouldkill = self.Macros[cmds[1]](self, cmds[2], t, self.Channels[1]:GetTime(), chan)
                        if shouldkill then
                            subtrackmacros[t] = nil
                        end
                    end
                end
            end
                    self.MacroStream[subtrack] = subtrackmacros
        end
    end
end







local function RecalcLyricMacroStream(self, data)
    local tracktime = data.TrackTime
    local curtrack = self:GetTrack()

    local lyricmacros = table.Copy(PHE_Lyrics_Macros[curtrack])
    if lyricmacros then
        self.LyricMacroStream = lyricmacros
    end
end



local function StartTrack(self, data)
    local oldtrack = self.EMP_Tracks[data.OldTrack]
    local newtrack = self.EMP_Tracks[data.Track]
    local time = 0
    local fadedur = self:GetVolumeChangeDuration()
    local func = self:GetVolumeFunction()

    if data.Time then
        time = data.Time
    end
    if oldtrack then
        self.TempChannels = table.Copy(self.Channels)
        table.Empty(self.Channels)
        for i, v in pairs(self.TempChannels) do
            if v and v:IsValid() then
                self:AddTickTask('temp' .. i * -1, 'VolumeModTick', {Chan = v, StartVolume = v:GetVolume(), TargetVolume = 0, Duration = fadedur, Func = func, StartTime = CurTime(),  Kill = true})
            end
            
        end
    end
    for i, v in pairs(newtrack.SubTracks) do
        fadedur = v.FadeIn
        func = v.FadeFunction


        if data.Fade then -- Incase we're wishing to override the typical instrument parameters.
            fadedur = data.Fade
        end

        if data.Func then
            func = data.Func
        end

        if data.Time then
            time = data.Time
        end

        time = time
        sound.PlayFile(v.Sound, 'noblock noplay', function(chan, nu, str) HandleNewTrack(self, chan, nu, str, fadedur, func, i, time) end)
    end
    self.OldTrack = data.Track
    print(self.OldTrack)
end

local function SetActiveSubTracks(self, data)
    local tracktbl = self.EMP_Tracks[self:GetTrack()]
    local subtracks = tracktbl['SubTracks']
    local newsubtracks = data.SubTracks
    local ct = CurTime()

        for i, v in pairs(subtracks) do
            local chan = self.Channels[i]

            local fadein = self:GetVolumeChangeDuration()
            local fadeout = self:GetVolumeChangeDuration()
            local fadefunc = self:GetVolumeFunction()

            if v.FadeIn then
                fadein = v.FadeIn
            end

            if v.FadeOut then
                fadeout = v.FadeOut
            end

            if v.FadeFunction then
                fadefunc = v.FadeFunction
            end
            if bit.band(bit.lshift(1, i - 1), newsubtracks) > 0 then
                self:AddTickTask('AddTracks_' .. i, 'VolumeModTick', {Chan = chan, StartVolume = chan:GetVolume(), StartTime = ct, Duration = fadein, Func = fadefunc, TargetVolume = self:GetTargetVolume()})
                print('Buffing or reserving track ' .. i)
            else
                self:AddTickTask('RemoveTracks_' .. i, 'VolumeModTick', {Chan = chan, StartVolume = chan:GetVolume(), StartTime = ct, Duration = fadeout, Func = fadefunc, TargetVolume = 0})
                print('Muting Track ' .. i)
            end
        end
    end


local function PauseAllTracks(self, data)
    local ct = CurTime()
    local togglefx = self:GetToggleEffects()
    for i, chan in pairs(self.Channels) do
        if chan and chan:IsValid() then
            if self.ChannelInitialStates[i] == true then -- if not already paused, do something.
                if togglefx > 0 then
                    if bit.band(togglefx, 2) > 0 then
                        
                        self:AddTickTask('PauseTracks_SM' .. i, 'SpeedMod', {Chan = chan, StartSpeed = chan:GetPlaybackRate(), TargetSpeed = 0, StartTime = CurTime(), Duration = self:GetVolumeChangeDuration(), Func = self:GetVolumeFunction(), Pause = true})
                    end

                    if bit.band(togglefx, 1) > 0 then
                        self:AddTickTask('AddTracks_' .. i, 'VolumeModTick', {Chan = chan, StartVolume = chan:GetVolume(), StartTime = ct, Duration = self:GetVolumeChangeDuration(), Func = self:GetVolumeFunction(), TargetVolume = 0, Pause = true})
                    end
                else
                    chan:Pause()
                end
            end
        end
    end
end

local function ResumeActiveTracks(self, data)
    local ct = CurTime()
    local togglefx = self:GetToggleEffects()
    for i, chan in pairs(self.Channels) do
        if self.ChannelInitialStates[i] == true then -- if already paused, don't do anything
            if chan and chan:IsValid() then
                if togglefx > 0 then
                    if bit.band(togglefx, 2) > 0 then
                        chan:Play()
                        self:AddTickTask('PauseTracks_SM' .. i, 'SpeedMod', {Chan = chan, StartSpeed = chan:GetPlaybackRate(), TargetSpeed = 1 , StartTime = CurTime(), Duration = self:GetVolumeChangeDuration(), Func = self:GetVolumeFunction()})
                    end

                    if bit.band(togglefx, 1) > 0 then
                        chan:Play()
                        self:AddTickTask('AddTracks_' .. i, 'VolumeModTick', {Chan = chan, StartVolume = chan:GetVolume(), StartTime = ct, Duration = self:GetVolumeChangeDuration(), Func = self:GetVolumeFunction(), TargetVolume = self:GetTargetVolume()})
                    end
                else
                    chan:Play()
                end
            end
        end
    end
end

--==========================--
ENT.Tasks = {
    ['VolumeMod'] = VolumeMod,
    ['VolumeModTick'] = VolumeModTick,
    ['SpeedMod'] = SpeedMod,
    ['SetPos'] = SetPos,
    ['StartTrack'] = StartTrack,
    ['PauseAllTracks'] = PauseAllTracks,
    ['ResumeActiveTracks'] = ResumeActiveTracks,
    ['SetActiveSubTracks'] = SetActiveSubTracks,
    ['RecalcLyricMacroStream'] = RecalcLyricMacroStream,
    ['RecalcMacroStream'] = RecalcMacroStream
}
--==========================--



--------------------------------MACROS-------------------------------------

local function Track_Pause(self, data, trackindex, time, chan) -- Track_Pause and Track_Play can't seem to be executed in the same stack.
    local chantime = chan:GetTime()
    if chan and chan:IsValid() then
        chan:Pause()
        self.ChannelInitialStates[trackindex] = false
    end
    return true
end

local function Track_Play(self, data, trackindex, time, chan)
    local chantime = chan:GetTime()
    if chan and chan:IsValid() then
                chan:Play()
            self.ChannelInitialStates[trackindex] = true
    else
    print('Channel is nil')
    end
    return true
end

--==========================--
ENT.Macros = {
['Pause'] = Track_Pause,
['Play'] = Track_Play
}
--==========================--


-------------------------------LYRIC MACROS---------------------------------

local function Lyric_SetColor(self, data, timestamp, chan)
    if chan and chan:IsValid() then
        local color = data[1]
        local duration = data[2]
        local ct = chan:GetTime()

        if duration then
            local ratio = math.Clamp(((ct - timestamp) / duration), 0, 1)

            newcolor = LerpVector(ratio, self.LyricOldColor:ToVector(), color:ToVector())
            self.LyricColor = newcolor:ToColor()

            if ratio >= 1 then
                self.LyricOldColor = color
                return true
            end
        else
            self.LyricOldColor = color
            self.LyricColor = color
            return true
        end
    end
end

local function Lyric_SetPeakColor(self, data, timestamp, chan)
    if chan and chan:IsValid() then
        local color = data[1]
        local duration = data[2]
        local ct = chan:GetTime()

        if duration then
            local ratio = math.Clamp(((ct - timestamp) / duration), 0, 1)

            newcolor = LerpVector(ratio, self.LyricOldPeakColor:ToVector(), color:ToVector())
            self.LyricPeakColor = newcolor:ToColor()
            if ratio >= 1 then
                self.LyricOldPeakColor = color
                return true
            end
        else
            self.LyricOldPeakColor = color
            self.LyricPeakColor = color
            return true
        end
    end
end

local function Lyric_SetSize(self, data, timestamp, chan)
    if chan and chan:IsValid() then
        local size = data[1]
        local duration = data[2]
        local ct = chan:GetTime()

        if duration then
            local ratio = math.Clamp(((ct - timestamp) / duration), 0, 1)

            newsize = Lerp(ratio, self.LyricOldSize, size)
            self.LyricSize = newsize

            if ratio >= 1 then
                self.LyricOldSize = size
                return true
            end
        else
            self.LyricOldSize = size
            self.LyricSize = size
            return true
        end
    end
end

local function Lyric_SetPeakSize(self, data, timestamp, chan)
    if chan and chan:IsValid() then
        local size = data[1]
        local duration = data[2]
        local ct = chan:GetTime()

        if duration then
            local ratio = math.Clamp(((ct - timestamp) / duration), 0, 1)

            newsize = Lerp(ratio, self.LyricOldPeakSizeMulti, size)
            self.LyricPeakSizeMulti = newsize

            if ratio >= 1 then
                self.LyricOldPeakSizeMulti = size
                return true
            end
        else
            self.LyricOldPeakSizeMulti = size
            self.LyricPeakSizeMulti = size
            return true
        end
    end
end

local function Lyric_SetFont(self, data, timestamp, chan)
    self.Font = data[1]
end

local function Lyric_SetShadowOffset(self, data, timestamp, chan)
    local newoffset = data[1]
    local oldoffset = self.LyricOldShadowOffset
    local duration = data[2]
    local ct = chan:GetTime()
    if newoffset.X and newoffset.Y then
        if duration then
            local ratio = math.Clamp(((ct - timestamp) / duration), 0, 1)
            newoffx = Lerp(ratio, oldoffset.X, newoffset.X)
            newoffy = Lerp(ratio, oldoffset.Y, newoffset.Y)
            self.LyricShadowOffset = {X = newoffx, Y = newoffy}
            if ratio >= 1 then
                self.LyricShadowOffset = newoffset
                self.LyricOldShadowOffset = newoffset
                return true
            end
        else
        
        self.LyricShadowOffset = newoffset
        self.LyricOldShadowOffset = newoffset
         return true
        end
    else
        return true
    end
end

local function Lyric_SetShadowFreq(self, data, timestamp, chan)
    local newfreq = data[1]
    local oldfreq = self.LyricOldShadowDance_Freq
    local duration = data[2]
    local ct = chan:GetTime()
    if neqfreq then
        if duration then
            local ratio = math.Clamp(((ct - timestamp) / duration), 0, 1)
            freq = Lerp(ratio, oldfreq, newfreq)
            self.LyricShadowDance_Freq = freq

            if ratio >= 1 then
                self.LyricShadowDance_Freq = newfreq
                self.LyricOldShadowDance_Freq = newfreq
                return true
            end
        else
        
        self.LyricShadowDance_Freq = newfreq
        self.LyricOldShadowDance_Freq = newfreq
         return true
        end
    else
        return true
    end
end

local function Lyric_SetShadowColor(self, data, timestamp, chan)
    if chan and chan:IsValid() then
        local color = data[1]
        local oldcolor = self.LyricOldShadowColor
        local duration = data[2]
        local ct = chan:GetTime()

        if duration then
            local ratio = math.Clamp(((ct - timestamp) / duration), 0, 1)
            local newcolor = Color(0, 0, 0, 0)

            newcolor.r = Lerp(ratio, oldcolor.r, color.r)
            newcolor.g = Lerp(ratio, oldcolor.g, color.g)
            newcolor.b = Lerp(ratio, oldcolor.b, color.b)
            newcolor.a = Lerp(ratio, oldcolor.a, color.a)


            self.LyricShadowColor = newcolor

            if ratio >= 1 then
                self.LyricOldShadowColor = color
                return true
            end
        else
            self.LyricOldShadowColor = color
            self.LyricShadowColor = color
            return true
        end
    end
end

local function Lyric_SetShadowDance(self, data, timestamp, chan)
    self.LyricShadowDance = data[1]

end


--==========================--
ENT.LyricMacros = {
['SetColor'] = Lyric_SetColor,
['SetPeakColor'] = Lyric_SetPeakColor,
['SetSize'] = Lyric_SetSize,
['SetPeakSize'] = Lyric_SetPeakSize,
['SetFont'] = Lyric_SetFont,

['SetShadowDance'] = Lyric_SetShadowDance,
['SetShadowOffset'] = Lyric_SetShadowOffset,
['SetShadowFreq'] = Lyric_SetShadowFreq,
['SetShadowColor'] = Lyric_SetShadowColor

}
--==========================--

----------------------------------------- NETWORKED TASKS ---------------------------------------------------------

local function NT_SetPos(self)
    local time = net.ReadFloat()
self:AddTask('IO', 'SetPos', {Time = time})
end

local function NT_SnapToNode(self)
    local node = net.ReadString()
self:AddTask('IO', 'SetPos', {NodeName = node})
end

local function HandleNetworkTask()
local taskname = net.ReadString()
local ent = net.ReadEntity()
ent.NetworkedTasks[taskname](ent)
end

ENT.NetworkedTasks = {
    ['SetPos'] = NT_SetPos,
    ['SnapPosToNode'] = NT_SnapToNode
}

net.Receive('PHE_MusicPlayer_Task', HandleNetworkTask)