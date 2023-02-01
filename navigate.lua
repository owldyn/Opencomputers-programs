local robot = require("robot")
local serialization = require("serialization")
local Navigate = {}

-- Set up the persistent location memory
--fb ud, rl
Navigate.Location = {0, 0, 0}
-- 0 = forwards, 1 = right, 2 = back, 3 = left
Navigate.Facing = 0
local function loadLocation()
    local lfile = io.open("location.txt", "r")
    local ffile = io.open("facing.txt", "r")
    if lfile then Navigate.Location = serialization.unserialize(lfile:read "*a") end
    if ffile then Navigate.Facing = serialization.unserialize(ffile:read "*a") end
end
loadLocation()

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
    table_add(Navigate.Location, offset)
    return Navigate.Location
end

local function saveLocation()
    local lfile = io.open("location.txt", "w")
    if lfile then
        lfile:write(serialization.serialize(Navigate.Location))
        lfile:close()
    end
    local ffile = io.open("facing.txt", "w")
    if ffile then
        ffile:write(serialization.serialize(Navigate.Facing))
        ffile:close()
    end
end

--- Sends the robot forwards and calculates that.
--- @return boolean success Whether or not the movement was successful
function Navigate:forward()
    if robot.forward() then
        calculate_movement(Navigate.Facing)
        saveLocation()
        return true
    end
    return false
end
--- Sends the robot backwards and calculates that.
--- @return boolean success Whether or not the movement was successful
function Navigate:back()
    if robot.back() then
        calculate_movement((Navigate.Facing + 2) % 4)
        saveLocation()
        return true
    end
    return false
end

function Navigate:up()
    if robot.up() then
        calculate_movement(-1)
        saveLocation()
        return true
    end
    return false
end

function Navigate:down()
    if robot.down() then
        calculate_movement(-2)
        saveLocation()
        return true
    end
    return false
end
function Navigate:turnRight()
    if robot.turnRight() then
        Navigate.Facing = (Navigate.Facing + 1) % 4
        saveLocation()
        return true
    end
    return false
end

function Navigate:turnLeft()
    if robot.turnLeft() then
        Navigate.Facing = (Navigate.Facing - 1) % 4
        saveLocation()
        return true
    end
    return false
end

--- Turns to the given Facing
--- @param direction number the direction to turn to
function Navigate:turnTo(direction)
    local f = (Navigate.Facing - direction) % 4
    if f == 0 then
        return true
    elseif f == 1 then
        return Navigate:turnLeft()
    elseif f == 2 then
        return Navigate:turnRight() and Navigate:turnRight()
    elseif f == 3 then
        return Navigate:turnRight()
    end
end

--- Paths back to a Block
--- @return boolean returned whether it was successful returning.
function Navigate:returnToBlock(block)
    -- This won't work if there's a roof over the block in question.
    local function move()
        if not Navigate:forward() then
            if not Navigate:up() then
                return Navigate:down()
            end
        end
        return true
    end
    local x, y, z = table.unpack(block._relative_location)

    print(x)
    -- Equalize the X
    if x > Navigate.Location[1] then
        if not Navigate:turnTo(0) then
            return false
        end
    elseif x < Navigate.Location[1] then
        if not Navigate:turnTo(2) then
            return false
        end
    end
    while x ~= Navigate.Location[1] do
        if not move() then
            return false
        end
    end
    -- Equalize the Z
    if z > Navigate.Location[3] then
        if not Navigate:turnTo(1) then
            return false
        end
    elseif z < Navigate.Location[3] then
        if not Navigate:turnTo(3) then
            return false
        end
    end
    while z ~= Navigate.Location[3] do
        if not move() then
            return false
        end
    end
    while y ~= Navigate.Location[2] do
        if y > Navigate.Location[2] then
            Navigate:up()
        else
            Navigate:down()
        end
    end
    return Navigate:turnTo(block._relative_direction)
end

return Navigate