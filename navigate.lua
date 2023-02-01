local robot = require("robot")
local serialization = require("serialization")

-- Set up the persistent location memory
--fb ud, rl
local Location = {0, 0, 0}
-- 0 = forwards, 1 = right, 2 = back, 3 = left
local Facing = 0
local function loadLocation()
    local lfile = io.open("location.txt", "r")
    local ffile = io.open("facing.txt", "r")
    if lfile then Location = serialization.unserialize(lfile:read "*a") end
    if ffile then Facing = serialization.unserialize(ffile:read "*a") end
end
loadLocation()
local function shallow_copy(t)
    local t2 = {}
    for k,v in pairs(t) do
        t2[k] = v
    end
    return t2
end

local Block = {}
--- Initializes a block location
--- @param location table The current location. defaults to Location
--- @param facing number the current facing. defaults to Facing
function Block:add(location, facing)
    local inst = {}
    setmetatable(inst, self)
    self._index = self

    -- Need to deep copy so we don't modify the local copy when changing location.
    inst._relative_location = shallow_copy(location) or shallow_copy(Location)
    inst._relative_direction = facing or Facing
    return inst
end

--- Adds each item in two tables together
--- Must be two equally sized tables containing only numbers.
--- @param t1 table the table to return from after adding
--- @param t2 table the second table to add with
--- @return table t1 the table added to
local function table_add(t1, t2)
    -- do the equivalent of:
    -- t1[1] = t1[1] + t2[1]
    -- t1[2] = t1[2] + t2[2]
    -- and so on
    for t1i, t1v in pairs(t1) do
        t1[t1i] = t1v + t2[t1i]
    end
    return t1
end

--- Calculates and applies the location offset
--- @param direction number -1 is up -2 is down 0 is forward, 1 is right, 2 is backward, 3 is left
--- @return table Location the current Location
local function calculate_movement(direction)
    --- @type table
    local offset = nil
    if direction == -2 then
        offset = {0, -1, 0}
    elseif direction == -1 then
        offset = {0, 1, 0}
    elseif direction == 0 then
        offset = {1, 0, 0}
    elseif direction == 1 then
        offset = {0, 0, 1}
    elseif direction == 2 then
        offset = {-1, 0, 0}
    elseif direction == 3 then
        offset = {0, 0, -1}
    end
    table_add(Location, offset)
    return Location
end

local function saveLocation()
    local lfile = io.open("location.txt", "w")
    if lfile then
        lfile:write(serialization.serialize(Location))
        lfile:close()
    end
    local ffile = io.open("facing.txt", "w")
    if ffile then
        ffile:write(serialization.serialize(Facing))
        ffile:close()
    end
end
--- Sends the robot forwards and calculates that.
--- @return boolean success Whether or not the movement was successful
local function forward()
    if robot.forward() then
        calculate_movement(Facing)
        saveLocation()
        return true
    end
    return false
end
--- Sends the robot backwards and calculates that.
--- @return boolean success Whether or not the movement was successful
local function back()
    if robot.back() then
        calculate_movement((Facing + 2) % 4)
        saveLocation()
        return true
    end
    return false
end

local function up()
    if robot.up() then
        calculate_movement(-1)
        saveLocation()
        return true
    end
    return false
end

local function down()
    if robot.down() then
        calculate_movement(-2)
        saveLocation()
        return true
    end
    return false
end
local function turnRight()
    if robot.turnRight() then
        Facing = (Facing + 1) % 4
        saveLocation()
        return true
    end
    return false
end

local function turnLeft()
    if robot.turnLeft() then
        Facing = (Facing - 1) % 4
        saveLocation()
        return true
    end
    return false
end

--- Turns to the given Facing
--- @param direction number the direction to turn to
local function turnTo(direction)
    local f = (Facing - direction) % 4
    if f == 0 then
        return true
    elseif f == 1 then
        return turnLeft()
    elseif f == 2 then
        return turnRight() and turnRight()
    elseif f == 3 then
        return turnRight()
    end
end

--- Paths back to a Block
--- @return boolean returned whether it was successful returning.
local function returnToBlock(block)
    -- This won't work if there's a roof over the block in question.
    local function move()
        if not forward() then
            if not up() then
                return down()
            end
        end
        return true
    end
    local x, y, z = table.unpack(block._relative_location)

    print(x)
    -- Equalize the X
    if x > Location[1] then
        if not turnTo(0) then
            return false
        end
    elseif x < Location[1] then
        if not turnTo(2) then
            return false
        end
    end
    while x ~= Location[1] do
        if not move() then
            return false
        end
    end
    -- Equalize the Z
    if z > Location[3] then
        if not turnTo(1) then
            return false
        end
    elseif z < Location[3] then
        if not turnTo(3) then
            return false
        end
    end
    while z ~= Location[3] do
        if not move() then
            return false
        end
    end
    while y ~= Location[2] do
        if y > Location[2] then
            up()
        else
            down()
        end
    end
    return turnTo(block._relative_direction)
end