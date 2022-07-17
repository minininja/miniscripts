pathUtils={"wait": 0, "blockList": ["Crafting", "Character", "Basic", "Tree", "Clump", "Building", "Property", "Stone"], "north": 0, "south": 2, "east": 1, "west": 3}
pathUtils.distance = function(a, b)
    // print "pathUtils.distance"
    return sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y))
end function

pathUtils.isBlocked = function(tile)
    // print "pathUtils.isBlocked"
    // print "isBlocked: " + tile
    if not (tile.x >= 0 and tile.x < farm.width) then return 0
    if not (tile.y >= 0 and tile.y < farm.height) then return 0
    if self.blockList.indexOf(tile.type) == null then return 0
    return 1
end function

pathUtils.cost = function(a)
    // print "pathUtils.cost"
    return 1 + 2 * a.distance
end function

pathUtils.position = function(x, y)
    // print "pathUtils.position"
    tile = farm.tile(x, y)

    if not tile then
        tile = {"type": "Empty", "Name": null}
    end if

    tile.hash = function()
        hash = 29
        hash = 31 * hash + ((37 * self.x) % 41)
        hash = 31 * hash + ((43 * self.y) % 47)
        return hash
    end function

    tile.x = x
    tile.y = y

    tile.blocked = self.isBlocked(tile)

    return tile
end function

pathUtils.removeTile = function(tile, list)
    // print "pathUtils.removeTile"
    result = []
    for l in list
        if tile.hash != l.hash then result.push(l)
    end for
    return result
end function

pathUtils.adjacent = function(tile)
    result = []

    x = tile.x - 1
    y = tile.y - 1
    if x >= 0 then result.push(self.position(x, tile.y))
    if y >= 0 then result.push(self.position(tile.x, y))

    x = tile.x + 1
    y = tile.y + 1
    if x < farm.width then result.push(self.position(x, tile.y))
    if y < farm.height then result.push(self.position(tile.x, y))

    return result
end function

pathUtils.unblocked = function(tiles)
    // print "pathUtils.unblocked"
    result = []
    for t in tiles
        if not t.blocked then result.push(t)
    end for
    return result
end function

pathUtils.itemExist = function(tile, list)
    // print "pathUtils.itemExist"
    for l in list
        if l.hash == tile.hash then return l
    end for
    return null
end function

pathUtils.cheapestMove = function(list)
    // print "pathUtils.cheapestMove"
    result = null
    for l in list
        if not result then result = l
        if l.cost < result.cost then result = l
    end for
    return result
end function

pathUtils.debugPosition = function(loc)
    return loc.x + ", " + loc.y
end function

pathUtils.logStep = function(current, destin, open, closed)
    print "pathUtils.path: open=" + open.len + " closed=" + closed.len
    print "pathUtils.path: current: " + self.debugPosition(current) + " " + current.hash
    print "pathUtils.path: current: " + current.type + " " + current.cost
    print "pathUtils.path: destin: " + self.debugPosition(destin) + " " + destin.hash
    print "pathUtils.path: destin: " + destin.type

    wait(self.wait)
end function

pathUtils.path = function(origin, destination)
    print "pathUtils.path, looking from " + self.debugPosition(origin) + " to " + self.debugPosition(destination)
    destin = self.position(destination.x, destination.y)

    // can't go there if it's blocked
    if destin.blocked then return []

    current = self.position(origin.x, origin.y)
    current.parent = null
    current.distance = self.distance(origin, destin)
    current.cost = 0

    open = [current]
    closed = []

    self.logStep(current, destin, open, closed)

    while true
        if current.hash == destin.hash then break
        if open.len == 0 then
            // no path
            current = null
            break
        end if

        open = self.removeTile(current, open)
        closed.push(current)

        // find all the unblocked tiles that we haven't moved to yet
        for t in self.unblocked(self.adjacent(current))
            t.distance = self.distance(t, destin)
            t.cost = self.cost(t)
            t.parent = current

            // print "pathUtils.path: adjacent " + self.debugPosition(t) + " cost=" + t.cost + ", distance=" + t.distance

            openItem = self.itemExist(t, open)
            if openItem and t.cost < openItem.cost then
                open = self.removeTile(openItem, open)
            end if
            if not self.itemExist(t, closed) then
                open.push(t)
            end if
        end for

        // find the cheapest cost
        current  = self.cheapestMove(open)
        self.logStep(current, destin, open, closed)
    end while

    path = []
    if current then
        print "pathUtils.path: path found building steps"
        wait(self.wait)

        // construct and reverse the path
        tmp = []
        while current
            // skip the origin point
            if current.parent then tmp.push(current)
            current = current.parent
        end while
        // and reverse the list
        while tmp.len > 0
            // cleanup
            t = tmp.pop()
            if t.hasIndex("parent") then t.remove("parent")
            path.push(t)
        end while
    end if
    return path
end function

pathUtils.reqFacing = function(origin, next)
    if origin.x == next.x then
        if origin.y == next.y + 1 then return self.north
        if origin.y == next.y - 1 then return self.south
    else
        if origin.x == next.x - 1 then return self.east
        if origin.x == next.x + 1 then return self.west
    end if
end function

worldUtils = {"wait": 0}
worldUtils.findType = function(type, name)
    result = []
    for x in range(0, farm.width)
        for y in range(0, farm.height)
            tile = pathUtils.position(x, y)

            if tile.type == type then
                if not name then
                    result.push(tile)
                else
                    if tile.name == name then result.push(tile)
                end if
            end if
        end for
    end for
    return result
end function

worldUtils.distances = function(from, tiles)
    for t in tiles
        t.distance = pathUtils.distance(from, t)
    end for
    return tiles
end function

worldUtils.closest = function(tiles)
    result = null
    for t in tiles
        if not result then result = t
        if t.distance < result.distance then result = t
    end for
    return result
end function

worldUtils.closestReachable = function(origin, tiles)
    tiles = worldUtils.distances(origin, worldUtils.findType("Property", "Water"))
    while tiles.len > 0
        tile = self.closest(tiles)
        print "worldUtils.closestReachable: closest " + pathUtils.debugPosition(tile)
        wait(self.wait)
        pathUtils.removeTile(tile, tiles)

        adjacents = pathUtils.unblocked(pathUtils.adjacent(tile))
        while adjacents.len > 0
            t = adjacents[0]
            print "worldUtils.closestReachable: looking for path to " + pathUtils.debugPosition(t)
            wait(self.wait)

            adjacents = pathUtils.removeTile(t, adjacents)
            path = pathUtils.path(origin, t)
            if path.len > 0 then
                print "worldUtils.closestReachable: found path to adjacent"
                wait(self.wait)
                return {"adjacent": t, "target": tile, "path": path}
            end if
        end while
    end while
    return null
end function

botUtils = {"wait": 1}

botUtils.ahead = function(bot)
    if bot.facing == pathUtils.north then
        return pathUtils.position(bot.position.x, bot.position.y+1)
    end if
    if bot.facing == pathUtils.south then
        return pathUtils.position(bot.position.x, bot.position.y-1)
    end if
    if bot.facing == pathUtils.east then
        return pathUtils.position(bot.position.x+1, bot.position.y)
    end if
    if bot.facing == pathUtils.west then
        return pathUtils.position(bot.position.x-1, bot.position.y+1)
    end if
end function

botUtils.turnTo = function(bot, reqFacing)
    while bot.facing != reqFacing
        print bot.facing + " != " + reqFacing
        wait(self.wait)
        bot.left
    end while
end function

botUtils.move = function(bot, path, destin)
    for step in path
        print "botUtils.move: next step"
        pprint step
        wait(self.wait)

        facing = pathUtils.reqFacing(bot.position, step)
        print "botUtils.move: bot.facing=" + bot.facing + " req=" + facing
        print "botUtils.move: " + pathUtils.debugPosition(bot.position) + " -> " + pathUtils.debugPosition(step)
        wait(self.wait)

        if bot.facing != facing then self.turnTo(bot, facing)

        print "ahead:"
        pprint self.ahead(bot)
        wait(self.wait)
        ahead = pathUtils.position(bot.ahead.x, bot.ahead.y)
        print "ahead: " + ahead
        blocked = pathUtils.isBlocked(ahead)
        print "blocked: " + blocked
        wait(self.wait)

        if blocked then
            print "path blocked, redirecting"
            wait(self.wait)

            newOrigin = pathUtils.position(bot.position.x, bot.position.y)
            path = pathUtils.path(newOrigin, destin)
            botUtils.move(bot, path, destin)
            return
        else
            print "path not blocked, moving"
            bot.forward
        end if
    end for
end function

refillWater = function(bot)
    origin = pathUtils.position(bot.position.x, bot.position.y)

    locs = worldUtils.distances(bot.position, worldUtils.findType("Property", "Water"))
    loc = worldUtils.closest(locs)
    locs = pathUtils.adjacent(loc)
    locs = pathUtils.unblocked(locs)
    locs = worldUtils.distances(bot.position, locs)
    target = worldUtils.closest(locs)


    path = pathUtils.path(origin, pathUtils.position(target.x, target.y))
    botUtils.move(bot, path, target)

    print "arrived at destination"

    facing = pathUtils.reqFacing(pathUtils.position(bot.position.x, bot.position.y), target)
    botUtils.turnTo(bot, facing)

    bot.use "Watering Can"
    bot.useTool
end function

if 1 then
    origin = pathUtils.position(bot.position.x, bot.position.y)
    bot.use "Watering Can"
    bot.useTool
    bot.useTool
    bot.useTool
    bot.useTool
    bot.useTool
    refillWater(bot)
    botUtils.move(bot, pathUtils.path(pathUtils.position(bot.position.x, bot.position.y), origin), origin)
end if

if 0 then
origin = pathUtils.position(bot.position.x, bot.position.y)
crops = worldUtils.distances(bot.position, worldUtils.findType("HoeDirt"))
while crops.len > 0
    crop = worldUtils.closest(crops)
    crops = pathUtils.removeTile(crop, crops)
    if crop.dry then
        print "moving to dry crop"
        pprint crop
        wait(1)

        locs = worldUtils.distances(bot.position, pathUtils.unblocked(pathUtils.adjacent(crop)))
        target = worldUtils.closest(locs)
        path = pathUtils.path(bot.position, target)
        if path.len > 0 then
            // move to the adjacent spot
            botUtils.move(bot, path, target)
            facing = pathUtils.reqFacing(pathUtils.position(bot.position.x, bot.position.y), target)
            botUtils.turnTo(bot, facing)

            print "finished move"
            pprint bot.ahead
            wait(5)

            // water
            if bot.ahead.type == "HoeDirt" and bot.ahead.dry then
                bot.use "Watering Can"
                bot.useTool
            else
                print "miss"
            end if
        else
            print "unable to water crop at " + crop
        end if
    end if
end while

path = pathUtils.path(bot.position, origin)
botUtils.move(bot, path, origin)
botUtils.turnTo(bot, pathUtils.south)
end if


