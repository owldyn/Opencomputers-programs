n = require("navigate")
Block = require("block")
charger = Block:add(n.Location, n.Facing)
test = Block:add({5,0,0}, n.Facing)
tree = Block:add({6,0,10}, n.Facing)

n:returnToBlock(test)
n:returnToBlock(charger)


