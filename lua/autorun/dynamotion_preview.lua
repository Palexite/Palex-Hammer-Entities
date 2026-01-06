local comot_viewshakes = {}
OBJ_PrioritizedPvcma = nil
OBJ_PvcmaStartTime = 0

comot = {}

if SERVER then
util.AddNetworkString('Comot_Shake')
end

-- https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/mp/src/game/client/view_effects.cpp#L215 , this turned into lua basically

local function Engine_SDKReplica(i, data, start, die)
    local ratio = 1 - ((CurTime() - start) / (die - start))
    local amp = (data.LinearAmp * ratio) -- Decrease amplitude over time
    local angamp = Vector(1, 1, 1)
    if data.AngAmp then
        angamp = (data.AngAmp)
    end
    local freq = (data.Freq / ratio) -- Increase frequency over time
    local shakeext = data.ShakeExtent
    local shakeangext = data.ShakeAngExtent
    if not shakeext then
        data.ShakeExtent = Vector(math.Rand(amp.X, -amp.X), math.Rand(amp.Y, - amp.Y), math.Rand(amp.Z, -amp.Z))
        data.ShakeAngExtent = Vector(math.Rand(angamp.X, -angamp.X), math.Rand(angamp.Y, - angamp.Y), math.Rand(angamp.Z, -angamp.Z))
        shakeext = data.ShakeExtent
        shakeangext = data.ShakeExtent
    end

    if data.NextShakeExtent then
        if CurTime() > data.NextShakeExtent then
            data.ShakeExtent = Vector(math.Rand(amp, -amp), math.Rand(amp, - amp), math.Rand(amp, -amp))
            data.NextShakeExtent = CurTime() + (1 / freq)
            
        end


        else data.NextShakeExtent = CurTime() + (1 / freq)
    end



    ratio = ratio^2
    local angle = Angle(0, 0, roll)
    local roll = CurTime() * freq
    if ( roll > 1e8 ) then roll = 1e8 end

    ratio = ratio * math.sin(roll)
    local offset = Vector(shakeext.X * ratio, shakeext.Y * ratio, shakeext.Z * ratio)
    local offsetang = Angle(shakeangext.X * ratio, shakeangext.Y * ratio, shakeangext.Z * ratio)
    return {origin = offset, angles = offsetang, tab = data} end

local function Engine_Sinewaves(i, data, start, die)

end

comot.ShakeEngines = {
    ['SDKReplica'] = Engine_SDKReplica,
}

function comot:EngineInput(data)
    if data.Engine then
        local start = data.StartTime
        local die = start + data.Dur
        local result = comot.ShakeEngines[data.Engine](0, data, start, die)
    return result end
 end

function comot:Tick()
    local viewoffset = Vector(0, 0, 0)
    local viewangleoffset = Angle(0, 0, 0)

    for i, v in ipairs(comot_viewshakes) do
        local start = v.StartTime
        local die = start + v.Dur
        if CurTime() > die then
            table.remove(comot_viewshakes, i)
        else
            if v.Engine and self.ShakeEngines[v.Engine] then
                local output = self.ShakeEngines[v.Engine](i, v, start, die)
                comot_viewshakes[i] = output.tab
                viewoffset:Add(output.origin)
                viewangleoffset:Add(output.angles)
            end
        end
    end

    return {origin = viewoffset, angles = viewangleoffset}
end

function comot:StartViewShake(shakedata)
    shakedata.StartTime = CurTime()

    if shakedata.Pos then -- Damping away the amplitude depending on how far the player is.
        local pl = LocalPlayer()
            if pl and pl:IsValid() then
                local mypos = pl:GetPos()
                local dist = mypos:DistToSqr(shakedata.Pos)
                local ratio = 1 - (dist / (shakedata.Rad^2))
                shakedata['LinearAmp'] = shakedata['LinearAmp'] * ratio
                shakedata['AngAmp'] = shakedata['AngAmp'] * ratio
            end
    end


    table.insert(comot_viewshakes, shakedata)
end

function comot:GlobalViewTick(ply, pos, angles, fov)
    if GAMEMODE and GAMEMODE.CalcView then
        local newinfo = GAMEMODE:CalcView(ply, pos, angles, fov) -- What would the gamemode do?

        if newinfo.origin then
            pos = newinfo.origin
        end
        if newinfo.angles then
            angles = newinfo.angles
        end

        if newinfo.fov then
            fov = newinfo.fov
        end
    end

    local pvcma = nil
    if OBJ_PrioritizedPvcma and isnumber(OBJ_PrioritizedPvcma) then
        pvcma = Entity(OBJ_PrioritizedPvcma)
    end

    local abspos = pos
    local absang = angles
    local absfov = fov
    local drawviewer = false

        if pvcma and pvcma:IsValid() and pvcma.GetNetworkVars then
                local pvcma_st = pvcma.StartTime
                local pvcma_returntopov_st = pvcma.ReturnToPovStartTime

                local pvcma_returntopov_transtime = pvcma:GetPlayerPOVTransTime()
                local TransTime = pvcma:GetTransTime()
                local pvcma_tofunc = pvcma:GetTransTimeFunc()
                local pvcma_fromfunc = pvcma:GetPlayerPOVTransFunc()
                local fovtarg = pvcma:GetFOVTarget()
                local fovrate = pvcma:GetFOVRate()
                local curfov = pvcma.FOV

                local entpos = pvcma:GetPos()
                local entang = pvcma:GetAngles()
                local ratio = 0

                local fovchange = math.abs((fovtarg - curfov) * (0.01 * fovrate))
                local newfov = math.Approach(curfov, fovtarg, fovchange)
                pvcma.FOV = newfov

                if OBJ_Pvcma_PendingDisable then

                    local start_ratio = math.Clamp(((CurTime() - pvcma_st) / TransTime), 0, 1)
                    local pos_overridden = LerpVector(math.ease[pvcma_tofunc](start_ratio), abspos, entpos)
                    local rot_overridden = LerpAngle(math.ease[pvcma_tofunc](start_ratio), angles, entang)
                    local fov_overriden = Lerp(math.ease[pvcma_tofunc](ratio), fov, curfov)
                    local ratio = math.Clamp(((CurTime() - pvcma_returntopov_st) / pvcma_returntopov_transtime), 0, 1)
                    drawviewer = true

                abspos = LerpVector(math.ease[pvcma_fromfunc](ratio), pos_overridden, pos)
                absang = LerpAngle(math.ease[pvcma_fromfunc](ratio), rot_overridden, angles)
                absfov = Lerp(math.ease[pvcma_fromfunc](ratio), fov_overriden, fov)
                if ratio >= 1 then
                OBJ_PrioritizedPvcma = nil
                table.RemoveByValue(pvcma.Subjects, LocalPlayer()) -- Tells us our inputs are valid via the start_command hook.
                end
                else
                    local ratio = math.Clamp(((CurTime() - pvcma_st) / TransTime), 0, 1)
                    abspos = LerpVector(math.ease[pvcma_tofunc](ratio), pos, entpos)
                    absang = LerpAngle(math.ease[pvcma_tofunc](ratio), angles, entang)
                    absfov = Lerp(math.ease[pvcma_tofunc](ratio), fov, newfov)
                    drawviewer = true
                end

                if abspos:Distance(pos) < pvcma:GetVMDist() then
                    drawviewer = false -- Give the player their VM back once we are just about on top of them.
                end
        end

    local comotoffset = comot:Tick()
    local finalpos = abspos + comotoffset.origin
    local finalang = absang + comotoffset.angles

    return {origin = finalpos, angles = finalang, fov = absfov, drawviewer = drawviewer}
end


hook.Add( "CalcView", "COMOTCalcView", function( ply, pos, angles, fov )
    if GAMEMODE and GAMEMODE.CalcView then
        local newinfo = GAMEMODE:CalcView(ply, pos, angles, fov)
        if newinfo.origin then
            pos = newinfo.origin
        end
        if newinfo.angles then
            angles = newinfo.angles
        end

        if newinfo.fov then
            fov = newinfo.fov
        end
    end

    local pvcma = nil
    if OBJ_PrioritizedPvcma and isnumber(OBJ_PrioritizedPvcma) then
        pvcma = Entity(OBJ_PrioritizedPvcma)
    end

    local abspos = pos
    local absang = angles
    local absfov = fov
    local drawviewer = false

        if pvcma and pvcma:IsValid() and pvcma.GetNetworkVars then
                local pvcma_st = pvcma.StartTime
                local pvcma_returntopov_st = pvcma.ReturnToPovStartTime

                local pvcma_returntopov_transtime = pvcma:GetPlayerPOVTransTime()
                local TransTime = pvcma:GetTransTime()
                local pvcma_tofunc = pvcma:GetTransTimeFunc()
                local pvcma_fromfunc = pvcma:GetPlayerPOVTransFunc()
                local fovtarg = pvcma:GetFOVTarget()
                local fovrate = pvcma:GetFOVRate()
                local curfov = pvcma.FOV

                local entpos = pvcma:GetPos()
                local entang = pvcma:GetAngles()
                local ratio = 0

                local fovchange = math.abs((fovtarg - curfov) * (0.01 * fovrate))
                local newfov = math.Approach(curfov, fovtarg, fovchange)
                pvcma.FOV = newfov

                if OBJ_Pvcma_PendingDisable then

                    local start_ratio = math.Clamp(((CurTime() - pvcma_st) / TransTime), 0, 1)
                    local pos_overridden = LerpVector(math.ease[pvcma_tofunc](start_ratio), abspos, entpos)
                    local rot_overridden = LerpAngle(math.ease[pvcma_tofunc](start_ratio), angles, entang)
                    local fov_overriden = Lerp(math.ease[pvcma_tofunc](ratio), fov, curfov)
                    local ratio = math.Clamp(((CurTime() - pvcma_returntopov_st) / pvcma_returntopov_transtime), 0, 1)
                    drawviewer = true

                abspos = LerpVector(math.ease[pvcma_fromfunc](ratio), pos_overridden, pos)
                absang = LerpAngle(math.ease[pvcma_fromfunc](ratio), rot_overridden, angles)
                absfov = Lerp(math.ease[pvcma_fromfunc](ratio), fov_overriden, fov)
                if ratio >= 1 then
                OBJ_PrioritizedPvcma = nil
                table.RemoveByValue(pvcma.Subjects, LocalPlayer()) -- Tells us our inputs are valid via the start_command hook.
                end
                else
                    local ratio = math.Clamp(((CurTime() - pvcma_st) / TransTime), 0, 1)
                    abspos = LerpVector(math.ease[pvcma_tofunc](ratio), pos, entpos)
                    absang = LerpAngle(math.ease[pvcma_tofunc](ratio), angles, entang)
                    absfov = Lerp(math.ease[pvcma_tofunc](ratio), fov, newfov)
                    drawviewer = true
                end

                if abspos:Distance(pos) < pvcma:GetVMDist() then
                    drawviewer = false -- Give the player their VM back once we are just about on top of them.
                end
        end

    local comotoffset = comot:Tick()
    local finalpos = abspos + comotoffset.origin
    local finalang = absang + comotoffset.angles

    return {origin = finalpos, angles = finalang, fov = absfov, drawviewer = drawviewer}
end)

hook.Add( "CalcViewModelView", "COMOTCalcViewModelView", function(wep, vm, oldPos, oldAng, pos, ang)

    if GAMEMODE and GAMEMODE.CalcViewModelView then
        newinfo_pos, newinfo_angle = GAMEMODE:CalcViewModelView(wep, vm, oldPos, oldAng, pos, ang)

        if newinfo_pos then
            pos = newinfo_pos
        end
        if newinfo_angles then
            ang = newinfo_angle
        end
    end


    local comotoffset = comot:Tick()
    local angle = comotoffset.angles
    angle:Mul(0.5)
    local finalpos = pos + (comotoffset.origin * 0.5)
    local finalang = ang
    finalang:Add(angle)
    return finalpos, finalang
end)

if CLIENT then
    net.Receive('Comot_Shake', function()
        local pos = net.ReadVector()
        local tab = net.ReadTable()
        tab['Pos'] = pos
        comot:StartViewShake(tab)
    end)
end

net.Receive('zs_obj_pvcma_toggle', function()
    local pvcmaindex = net.ReadUInt(13)
    local pvcma = Entity(pvcmaindex)
    local enabled = net.ReadBool()
    if pvcma and pvcma:IsValid() and pvcma:GetClass() == 'point_viewcontrol_multiplayer_advanced' then
        if enabled then
            OBJ_Pvcma_PendingDisable = false
            OBJ_PrioritizedPvcma = pvcmaindex
                pvcma:AddSubject(LocalPlayer()) -- Tells us our inputs are NOT valid via the start_command hook (If input is disabled)
                pvcma.StartTime = CurTime()
        else
            pvcma.ReturnToPovStartTime = CurTime()
            OBJ_Pvcma_PendingDisable = true -- make this global since we don't know whether the entity exists, and if it doesn't, ReturnToPlayerPov isn't either.
            OBJ_Pvcma_StopInput = false
        end
    elseif enabled then
     OBJ_PrioritizedPvcma = pvcmaindex end -- By giving us the index, we're able to act on the view control the moment it exists on the client.
end)


util.ScreenShake = function(pos, amp, freq, dur, rad)
    net.Start('Comot_Shake')
    net.WriteVector(pos)
    net.WriteTable({LinearAmp = Vector(0, 0, 1 * amp), AngAmp = Vector(0, 0, 0), Freq = freq, Dur = dur, Rad = rad, Engine = 'SDKReplica', MaxPhysSubjects = 128, MaxCorrections = 4, TickDuration = 0.1})
    net.Broadcast()
end

