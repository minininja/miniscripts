pathUtils = {}

pathUtils.north = 0
pathUtils.south = 2
pathUtils.west = 1
pathUtils.east = 3
pathUtils.blockList = ["Crafting", "Character", "Basic", "Tree", "Clump", "Building", "Property", "Stone"]

pathUtils.removeElement = function(item, list)
    // self.log("removeElement: list.len = " + list.len, list, 10)
    result = []
    if not item then return list
    if list then
        for l in list
            if l != item then
                result.push(list)
            end if
        end for
    end if
    // self.log("removeElement: list.len = " + result.len, result, 10)
    return result
end function

pathUtils.intersection = function(first, second)
    result = []
    if first and second then
        for f in first
            if second.indexOf(f) != null then
                result.push(f)
            end if
        end for
    end if
    return result
end function

pathUtils.retain = function(keepers, list)
    result = []
    if list then
        for l in list
            if keepers.indexOf(l) != null then
                result.push(l)
            end if
        end for
    end if
    return result
end function

pathUtils.addAll  = function(source, destin)
    if destin and destin.len > 0 then
        for s in source
            if destin.indexOf(s) != null then
                destin.push(s)
            end if
        end for
    end if
end function

pathUtils.distance = function(origin, destination)
    distance = sqrt((destination.x - origin.x) * (destination.x - origin.x) + (destination.y - origin.y) * (destination.y - origin.y))
    return distance
end function

pathUtils.reqFacing = function(origin, destination)
    if origin.x == destination.x then
        if origin.y < destination.y then
            return self.south
        else
            return self.north
        end if
    end if
    if origin.y == destination.y then
        if origin.x < destination.x then
            return self.west
        else
            return self.east
        end if
    end if
end function

pathUtils.moveCost = function(prevFacing, origin, step, destination)
    // you always are going to move forward
    cost = 1

    // determine the facing change required, assuming turns in a single direction
    nextFacing  = self.reqFacing(origin, step)
    while prevFacing != nextFacing
        cost = cost + 1
        nextFacing = (nextFacing + 1) % 4
    end while

    // add the distance cost
    cost = cost + self.distance(step, destination) * 2

    return cost
end function

pathUtils.leastCostMove = function(currentPosition, moves)
    least = null

    for m in moves
        if self.samePosition(currentPosition, m) then continue
        if not least then least = m
        if m.cost < least.cost then least = m
    end for

    return least
end function

pathUtils.samePosition = function(a, b)
    if a.x != b.x then return 0
    if a.y != b.y then return 0
    return 1
end function

pathUtils.log = function(message, obj, time)
    print message
    if obj then
        tmp = {}
        for k in obj.indexes
            if k != "parent" then tmp[k] = obj[k]
        end for
        pprint tmp
    end if
    if time and time > 0 then wait(time)
end function

pathUtils.path = function(startingFacing, startPos, endPos)
    start = self.position(startPos.x, startPos.y)
    current = start
    current.parent = null
    // we are assuming this is the position of a bot, so while it is blocked it's
    // where we are thus not blocked
    current.blocked = 0

    destin = self.position(endPos.x, endPos.y)

    open = []
    closed = []

    steps = 0
    lastMoveCost = 1000000
    while not self.samePosition(current, destin) and not current.blocked
        steps = steps + 1
        print "starting to look " + steps

        // add in the potential moves and their move cost
        for t in self.adjacentTiles(current)
            t.parent = current
            if not t.blocked then
                facing = startingFacing
                if current.parent != null then
                    facing = self.reqFacing(current.parent, current)
                end if
                t.cost = self.moveCost(facing, current, t, destin)
                t.reqFacing = facing
                open.push(t)
            end if
        end for

        // find the cheapest move
        next = self.leastCostMove(current, open)

        // we have gotten as close as we can
        if next.cost > lastMoveCost then break
        lastMoveCost = next.cost

        // clean up the lists, everything we didn't pick goes to closed and we rebuild open with the current
        open = self.removeElement(next, open)
        closed = self.addAll(open, closed)
        open = [next]
        current = next
    end while

    // self.log("path: determined a path", null, 0)

    // now build the list
    path = []
    while current
        // this is the origin
        if current.parent == null then break

        // avoids having to reverse the list later
        path.insert(0, current)
        current = current.parent
    end while

    // self.log("path: built the path", path, 0)

    return path
end function

pathUtils.position = function(x, y)
    pos = farm.tile(x, y)
    if not pos then
        pos = {}
        pos.type = "Empty"
    end if

    pos.x = x
    pos.y = y
    pos.blocked = self.isBlocked(pos)

    return pos
end function

pathUtils.isBlocked = function(tile)
    self.log("isBlocked: start", tile, 0)
    if not tile then return 1

    if not tile.hasIndex("x") then
        self.log("isBlocked: no x found", tile, 10)
    end if

    if tile.x < 0 or tile.x >= farm.width then
        return 1
    end if
    if tile.y < 0 or tile.y >= farm.height then
        return 1
    end if

    for b in self.blockList
        if tile.type == b then
            return 1
        end if
    end for

    return 0
end function

pathUtils.adjacentTiles = function(tile)
    if not tile.hasIndex("x") then
        self.log("adjacentTiles: no x", tile, 10)
    end if
    return [self.position(tile.x - 1, tile.y), self.position(tile.x + 1, tile.y), self.position(tile.x, tile.y - 1), self.position(tile.x, tile.y + 1)]
end function

pathUtils.travel = function(bot, destin)
    keepGoing = 1

    while keepGoing
        blocked = 0
        path = self.path(bot.facing, bot.position, destin)
        for p in self.path(bot.facing, bot.position, destin)
            tile = self.position(p.x, p.y)
            if not tile then tile = p

            if blocked then
                continue
            else
                blocked = self.isBlocked(tile)
                if self.isBlocked(tile) then
                    // self.log("travel: blocked, will re-route", p, 0)
                else
                    // self.log("travel: not blocked", tile, 0)
                    while bot.facing != p.reqFacing
                        bot.left
                    end while
                    bot.forward
                end if
            end if
        end for

        // sometimes we don't end up next to where we want to be
        for t in self.adjacentTiles(destin)
            if keepGoing and self.samePosition(bot.position, t) then keepGoing = 0
        end for
    end while

    // turn to the target
    facing = self.reqFacing(bot.position, destin)
    while bot.facing != facing
        bot.left
    end while
end function

pathUtils.adjacentUnblocked = function(tile)
    tiles = self.adjacentTiles
    self.log("adjacentUnblocked:", tiles, 10)
    for t in tiles
        if not self.isBlocked(t) then return t
    end for
    return null
end function

worldUtils = {}
worldUtils.findByType = function(type, name)
    targets = []
    for x in range(0, farm.width)
        for y in range(0, farm.height)
            tile = pathUtils.position(x, y)
            if tile.type == type then
                if not name then targets.push(tile)
                if tile.name == name then targets.push(tile)
            end if
        end for
    end for
    return targets
end function

worldUtils.closest = function(origin, list)
    result = null

    for l in list
        if l then
            d = pathUtils.distance(origin, l)
            l.distance = d

            pathUtils.log("closest: current result", result, 0)
            pathUtils.log("closest: considering", l, 0)

            if not result then result = l
            if l.distance < result.distance then result = l
        end if
    end for

    return result
end function

botUtils = {}
botUtils.firstWater = function(items)
    for item in items
        if item.type == "WateringCan" then return item
    end for
    return null
end function

origin = bot.position

crops = worldUtils.findByType("HoeDirt", null)
for crop in crops
    if crop.dry then
        can = botUtils.firstWater(bot.inventory)
        if not can then
            print "no watering can, can not continue"
            break
        else if can and can.waterLeft < 1 then
            pathUtils.log("out of water", null, 2)
            water = worldUtils.closest(beforeWater, worldUtils.findByType("Property", "Water"))
            pathUtils.travel(bot, water)
            bot.use "Watering Can"
            bot.useTool
        end if

        // move to an adjacent tile (assume it's free)
        target = pathUtils.adjacentUnblocked(crop)
        if not target then
            pathUtils.log("can not reach to water", crop, 10)
        else
            pathUtils.travel(bot, target)

            // turn to the crop
            reqFacing = pathUtils.reqFacing(bot.position, crop)
            while bot.facing != reqFacing
                bot.left
            end while

            // water
            bot.use "Watering Can"
            bot.useTool
        end if
    end if
end for

pathUtils.travel(bot, origin)
