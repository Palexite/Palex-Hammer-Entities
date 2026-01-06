ENT.Type = 'anim'
local boxmin, boxmax = vector_origin, vector_origin

local function ArgSplit(str)
    if str then
        local args = string.Split(str, '@ ') -- @[space] IS HOW ARGUMENTS ARE SEPERATED IN THE PARAMETER LINE FOR HAMMER I/O
    return args end
end

local function VectorSplit(str)
    if str then
        local dimensions = string.Split(str, ' ') -- [space] IS HOW VECTOR ELEMENTS ARE SEPERATED IN THE PARAMETER LINE FOR HAMMER I/O
        local vector = Vector(tonumber(dimensions[1]), tonumber(dimensions[2]), tonumber(dimensions[3]))
    return vector end
end

function ENT:Initialize()
self:SetNoDraw(true)
end

function ENT:SetupDataTables()
    self.MaxPhysSubjects = 2562
    self.SubjectNumber = 1
    self.MaxCorrections = 323
    self.TickDuration = 0.1

    self.shakedata = {}
    self.PhysShakeData = {}
    self.subjects = {}
    self.players = {}
end

function ENT:KeyValue(k, v)
    if not self.shakedata then
        self['shakedata'] = {}
    end
    if k == 'linearamp' then
        local Vect = VectorSplit(v)
        self.shakedata['LinearAmp'] = Vect

    elseif k == 'angularamp' then
        self.shakedata['AngAmp'] = VectorSplit(v)

    elseif k == 'frequency' and tonumber(v) then
    self.shakedata['Freq'] = tonumber(v) 

    elseif k == 'duration' and tonumber(v) then
        self.shakedata['Dur'] = tonumber(v)
    
    elseif k == 'radius' and tonumber(v) then
    self.shakedata['Rad'] = tonumber(v) 

    elseif k == 'maxphysics' and tonumber(v) then
    self.MaxPhysSubjects = tonumber(v)

    elseif k == 'engine' then
        self.shakedata['Engine'] = v

    elseif k == 'maxcorrection' and tonumber(v) then
        self.MaxCorrections = tonumber(v)

    elseif k == 'tickduration' and tonumber(v) then
    self.TickDuration = tonumber(v)
    end
end



function ENT:AcceptInput(IN, Activator, Caller, Param)
    local mypos = self:GetPos()
    if IN == 'StartDynamicShake' then
        local args = ArgSplit(Param)
        local eng = args[1]
        local linearamplitude = VectorSplit(args[2])
        local angularamplitude = VectorSplit(args[3])
        local frequency = tonumber(args[4])
        local duration = tonumber(args[5])
        local radius = tonumber(args[6])
        local phys = tobool(args[7])

        if linearamplitude and angularamplitude and frequency and duration and radius and eng then -- All of these are required args

            if phys and tobool(phys) then 
                local args = {Rad = radius, Dur = duration, LinearAmp = linearamplitude, AngAmp = angularamplitude, Freq = frequency, StartTime = CurTime()}
                self:StartPhysicsShake(args)
            end

        self:StartShake({LinearAmp = linearamplitude, AngAmp = angularamplitude, Freq = frequency, Dur = duration, Rad = radius, Engine = eng})
        end

    elseif IN == 'StartShake' then
        self:StartShake(self.shakedata)

    elseif IN == 'StartPhysicsShake' then
    self:StartPhysicsShake(self.shakedata)
    end
end

function ENT:StartShake(shakedata)
    if shakedata.Phys then
        self:StartPhysicsShake(shakedata)
    end

    local mypos = self:GetPos()
    for i, v in ipairs(ents.FindInSphere(mypos, shakedata.Rad)) do
        if v and v:IsValid() and v:IsPlayer() then
            table.insert(self.players, v)
        end
    end
    net.Start('Comot_Shake')
    net.WriteVector(self:GetPos())
    net.WriteTable(shakedata)
    net.Send(self.players)
    self.players = {}
end

function ENT:StartPhysicsShake(data)
    table.Empty(self.subjects)
    local mypos = self:GetPos()
    shakedata = data
    shakedata['StartTime'] = CurTime()
    self.PhysShakeData = shakedata
    if shakedata.Rad then
    min, max = Vector(mypos.X - shakedata.Rad, mypos.Y - shakedata.Rad, mypos.Z - shakedata.Rad), Vector(mypos.X + shakedata.Rad, mypos.Y + shakedata.Rad, mypos.Z + shakedata.Rad)
        for i, v in pairs(self:TraceForSubjects(min, max)) do
                        local num = v:GetPhysicsObjectCount()
            if num > 0 then
                for i = 0, num - 1 do
                    local phys = v:GetPhysicsObjectNum(i)
                    table.insert(self.subjects, phys)
                                        phys:Wake()
                end
                if i >= self.MaxPhysSubjects then
                    break 
                end
            end
        end
    end
end

function ENT:TraceForSubjects(min, max)
local results = ents.FindInBox(min, max) -- Box is probably the most stable. sometimes a sphere search can cause crashes.
--local results = ents.FindInSphere(self:GetPos(), max.X)
return results end

function ENT:SetData(data)
    self.PhysShakeData = data
end

local function vectorclamp(vector, min, max)
vector.X = math.Clamp(vector.X, min ,max)
vector.Y = math.Clamp(vector.Y, min ,max)
vector.Z = math.Clamp(vector.Z, min ,max)
return vector end


function ENT:Think()
    if SERVER then
    local shakedata = self.PhysShakeData
    if shakedata and not table.IsEmpty(shakedata) and not table.IsEmpty(self.subjects) and shakedata.StartTime and not (CurTime() >= shakedata.StartTime + shakedata.Dur) then
        for i = 1, self.MaxCorrections do
            local physnum = self.SubjectNumber
            if self.subjects and self.subjects[physnum] then
                local physbody = self.subjects[physnum]
                if physbody and physbody:IsValid() then
                    local result = comot:EngineInput(shakedata)
                    local resultorigin = result.origin
                    local resultangle = result.angles
                    self:SetData(result.tab)
                    local ent = physbody:GetEntity()
                    physbody:AddVelocity(vectorclamp(resultorigin, -128, 128) * 10)
                    physbody:AddAngleVelocity(vectorclamp(Vector(resultangle.X, resultangle.Y, resultangle.Z) * 5, -720, 720))
                    physbody:Wake()
                    if self.SubjectNumber >= #self.subjects then
                        self.SubjectNumber = 1
                        break 
                    end
                end
            end
            self.SubjectNumber = self.SubjectNumber + 1
        end
    end
end
    self:NextThink(self.TickDuration)
    return true
end