ENT.Type = 'point'

function ENT:Initialize()
end

function ENT:KeyValue(k, v)
if self.OutputList[k] then
    self.OutputList[k](v)
end

end

function ENT:AcceptInput(IN, activator, caller, param)
if self.OutputList[IN] then
    self.OutputList[IN](param)
end
end

local function ArgSplit(str)
local args = string.Split(str, ', ') -- ",_" IS HOW ARGUMENTS ARE SEPERATED IN THE PARAMETER LINE FOR HAMMER I/O
return args end

local function VectorSplit(str)
local dimensions = string.Split(str, ' ') -- ",_" IS HOW VECTOR ELEMENTS ARE SEPERATED IN THE PARAMETER LINE FOR HAMMER I/O
return dimensions end

local function O_SetVelocity(v)
    local args = ArgSplit(v)
    local target = ents.FindByName(args[1])
    local vel = VectorSplit(args[2])
    if vel[1] and vel[2] and vel[3] then
        for e, r in ipairs(target) do
            if r and r:IsValid() then
                local phys = r:GetPhysicsObject()
                if phys then
                    phys:SetVelocity(Vector(tonumber(vel[1]), tonumber(vel[2]), tonumber(vel[3])))
                end
            end
        end
    end
end

local function O_SetAngVelocity(v)

    local args = ArgSplit(v)
    local target = ents.FindByName(args[1])
    local vel = VectorSplit(args[2])
    if vel[1] and vel[2] and vel[3] then
        for e, r in ipairs(target) do
            if r and r:IsValid() then
                                local phys = r:GetPhysicsObject()
                if phys then
                    phys:SetAngleVelocity(Vector(tonumber(vel[1]), tonumber(vel[2]), tonumber(vel[3])))
                end
            end
        end
    end
end

local function O_SetGravity(v)

    local args = ArgSplit(v)
    if args[1] and args[2] then
        local target = ents.FindByName(args[1])
        for e, r in ipairs(target) do
            if r and r:IsValid() then
                local phys = r:GetPhysicsObject()
                if phys and phys:IsValid() then
                    r:SetGravity(tonumber(args[2]))
                    print(r)
                end
            end
        end
    end
end

local function O_SetFriction(v)

    local args = ArgSplit(v)
    if args[1] and args[2] then
        local target = ents.FindByName(args[1])
        for e, r in ipairs(target) do
            if r and r:IsValid() then
                r:SetFriction(tonumber(args[2]))
                print(args[2])
                print(r)
            end
        end
    end
end

ENT.OutputList = {
    ['setvelocity'] = O_SetVelocity,
    ['setangvelocity'] = O_SetAngVelocity,
    ['setgravity'] = O_SetGravity,
    ['setfriction'] = O_SetFriction
}