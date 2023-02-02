Block = require("block")
fs = require("filesystem")
s = require("serialization")
Blocks = {}
Dir = "/home/blocks"
for file in fs.list(Dir) do
    print(file)
    local ofile = io.open(fs.concat(Dir,file), "r")
    local locationAndFacing = nil
    if ofile then locationAndFacing = ofile:read "*a"; ofile:close() end
    locationAndFacing = s.unserialize(locationAndFacing)
    Blocks[file] = Block:add(locationAndFacing[1], locationAndFacing[2])
end

return Blocks