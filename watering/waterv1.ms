north = 0
south = 2
west = 1
east = 3

// --------------------------------------------------------------------------------
// tool usage functions
// --------------------------------------------------------------------------------

doWater = function(bot)
    bot.use "Watering Can"
    bot.useTool
end function

selectTool = function(bot, position)
    bot.select(position)
end function

useTool = function(bot, name)
    pos = findToolPosition(bot, name)
    if not pos then return null
    selectTool(bot, pos)
    bot.useTool
end function

getTool = function(bot, position)
    if position < 0 then return null

    inv = bot.inventory
    if not position < inv.len then return null

    return inv[position]
end function

findToolPosition = function(bot, type)
    inv = bot.inventory
    for i in range(0, inv.len)
        if not inv[i] then continue
        if inv[i].type == type then return i
    end for
    return null
end function

// --------------------------------------------------------------------------------
// movement functions
// --------------------------------------------------------------------------------

moveCost = function(bot, facing)
    if bot.facing == facing then return 1

    // think right
    if ((bot.facing + 1) % 4) == facing then return 2
    // think left
    if ((bot.facing + 3) % 4) == facing then return 2
    // 180
    if ((bot.facing + 2) % 4) == facing then return 3
end function

travel = function(bot, origin, destin)
    path = []

    while bot.position.x != destin.x or bot.position.y != destin.y
        print "travel: looking for move"

        possible = []
        for targetFacing in range(0, 4)
            tile = fileByFacing(bot.position, targetFacing)

            // could be off the edge or blocked
            if not tile then continue
            if isBlocked(tile) then continue

            tile.facing = targetFacing
            tile.cost = moveCost(bot, tile) + 10 * distance(tile, destin)
            possible.push(tile)
        end for

        // find the lowest cost move
        targetTile = null
        for tile in possible
            if not targetTile then targetTile = tile
            if tile.cost < targetTile.cost then targatTile = tile
        end for

        print "travel: moving to " + targetTile

        turnAndMove(bot, targetTile.facing)
    end while
end function

turnTo = function(bot, facing)
    if ((bot.facing + 1) % 4) == facing then bot.left
    if ((bot.facing + 4) % 4) == facing then bot.right
    if ((bot.facing + 2) % 4) == facing then
        bot.right
        bot.right
    end if
end function

turnAndMove = function(bot, facing)
    turnTo(bot, facing)
    bot.forward
end function

// --------------------------------------------------------------------------------
// geometry functions
// --------------------------------------------------------------------------------

distance = function(a, b)
    d = sqrt((b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y))
    return d
end function

findCloser = function(origin, a, b)
    if not a then return b

    da = distance(origin, a)
    db = distance(origin, b)
    if da < db then return a
    return b
end function

// --------------------------------------------------------------------------------
// world view functions
// --------------------------------------------------------------------------------

blockingTypes = ["Crafting", "Character", "Basic", "Tree", "Clump", "Building", "Property"]
isBlocked = function(tile)
    if not tile then return 0
    for t in blockingTypes
        if tile.type == t then
            print "isBlocked: blocked " + tile
            return 1
        end if
    end for
    return 0
end function

findTilesByType = function(type, name)
    print "findTilesByType: looking for " + type + " " + name
    tiles = []
    for x in range(0, farm.width)
        for y in range(0, farm.height)
            tile = farm.tile(x,y)
            if not tile then continue

            if tile.type == type then
                tile.x = x
                tile.y = y
                if name and tile.name == name then
                    tiles.push(tile)
                else
                    tiles.push(tile)
                end if
            end if
        end for
    end for
    print "findTilesByType: found " + tiles.len + " tiles"
    return tiles
end function

tileByFacing = function(currentPosition, facing)
    x = currentPosition.x
    y = currentPosition.y

    print "tileByFacing: " + x + ", " + y

    // this is clunky
    if facing == 0 then y = y + 1
    if facing == 1 then x = x - 1
    if facing == 2 then y = y - 1
    if facing == 3 then x = x + 1

    print "tileByFacing: " + x + ", " + y

    tile = farm.tile(x, y)
    if not tile then return

    tile.x = x
    tile.y = y
    tile.facing = facing

    print "tileByFacing: returning " + tile

    return tile
end function

findAdjacent = function(origin, destin)
    print "findAdjacent: looking for tiles"
    targets = []
    for i in range(0, 3)
        possible = tileByFacing(destin, i)
        print "findAdjacent: possible " + possible
        if possible then
            print "findAdjacent: looking at " + possible.x + ", " + possible.y + ": " + possible
            if not isBlocked(possible) then
                print "findAdjacent: not blocked"
                // the direction to the target
                possible.facing = (i + 2) % 4

                print "findAdjacent: pushing " + possible
                targets.push(possible)
            end if
        end if
    end for

    print "findAdjacent: considering " + targets.len + " tiles"
    result = null
    for t in targets
        result = findCloser(origin, result, t)
    end for

    print "findAdjacent: returning " + result
    return result
end function

// --------------------------------------------------------------------------------
// the bot script
// --------------------------------------------------------------------------------


// for i in range(0, 5)
//     water(bot)
// end for

waterCells = findTilesByType("Property", "Water")
print "found " + waterCells.len + " possible locations"

targets = []
for w in waterCells
    targets.push(findAdjacent(bot.position, waterCell))
end for

// targetCell = null
// for t in
//     waterCell = findCloser(bot.position, waterCell, t)
//     targetCell = findAdjacent(bot.position, waterCell)
// end for
// print "water adjacent location: " + targetCell

//origin = bot.position

//travel(bot, target)
//turnTo(bot, target.facing)

//water(bot)

//travel(bot, origin)
//turnTo(bot, south)
