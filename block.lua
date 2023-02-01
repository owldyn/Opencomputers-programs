local function shallow_copy(t)
    local t2 = {}
    for k,v in pairs(t) do
        t2[k] = v
    end
    return t2
end

local Block = {}
--- Initializes a block location
--- @param location table The current location
--- @param facing number the current facing
function Block:add(location, facing)
    local inst = {}
    setmetatable(inst, self)
    self._index = self

    -- Need to deep copy so we don't modify the local copy when changing location.
    inst._relative_location = shallow_copy(location)
    inst._relative_direction = facing
    return inst
end

return Block