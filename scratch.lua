n = require("navigate")
--Block = require("block")
Blocks = require("load_blocks")

for name, block in pairs(Blocks) do
    print(name)
    n:returnToBlock(block)
end
