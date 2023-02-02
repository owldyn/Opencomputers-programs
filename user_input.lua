n = require("navigate")
--Block = require("block")
Blocks = require("load_blocks")
function printBlocks()
    local list = "["
    for block, _ in pairs(Blocks) do
        list = list..", "..block
    end
    list = list.."]"
    return list
end
while true do
    print("Input a block to go to, options:"..printBlocks())
    local input = io.read()
    if Blocks[input] then
        n:returnToBlock(Blocks[input])
    else
        print("Block doesn't exist!")
    end
end