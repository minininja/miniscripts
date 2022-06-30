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

blockingTypes = ["Crafting", "Character", "Basic", "Tree", "Clump", "Building", "Property"]
isBlocked = function(tile)
    if not tile then return 0
    for t in blockingTypes
        if tile.type == t then
            pprint tile
            return 1
        end if
    end for
    return 0
end function

turnTo = function(bot, facing)
    if bot.facing == facing then return

    print "  current facing " + bot.facing + " turning to " + facing
    while bot.facing != facing
        bot.left
    end while
end function

moveForward = function(bot)
    if isBlocked(bot.ahead) then
        print "the way is blocked"
        pprint bot.ahead
        return 0
    end if

    bot.forward
    return 1
end function

turnAndGo = function(bot, facing)
    turnTo(bot, facing)
    if not moveForward(bot) then
        print "blocked, going around"
        turnAndGo(bot, (facing + 1) % 4)
    end if
end function

moveTo = function(bot, x, y)
    north = 0
    south = 2
    west = 1
    east = 3

    while not (bot.position.x == x and bot.position.y == y)
        print "  currently at " + bot.position.x + ", " + bot.position.y + " moving towards " + x + ", " + y
        while bot.position.x != x
            if bot.position.x < x then turnAndGo(bot, west)
            if bot.position.x > x then turnAndGo(bot, east)
        end while
        while bot.position.y != y
            if bot.position.y < y then turnAndGo(bot, south)
            if bot.position.y > y then turnAndGo(bot, north)
        end while
        // print "  post move at " + bot.position.x + ", " + bot.position.y + " target is " + x + ", " + y
    end while
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

findTilesByType = function(type, name)
    print "  in findTilesByType"
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
    return tiles
end function

findAdjacent = function(origin, x, y)
    targets = []
    for i in range(-1, 1)
        for j in range(-1, 1)
            // print "looking at " + (x + i) + ", " + (y + j)
            tile = farm.tile(x + i, y + j)
            // print tile

            if not tile then
                tile = {}
                tile.type = "Unblocked"
            end if
            if not isBlocked(tile) then
                tile.x = x + i
                tile.y = y + j
                targets.push(tile)
            end if
        end for
    end for

    result = null
    for t in targets
        result = findCloser(origin, result, t)
    end for
    return result
end function

spinAndFind = function(bot, type, name)
    for i in range(0, 3)
        turnTo(bot, i)
        tile = bot.ahead
        if not tile then continue
        if tile.type == type then
            if name and tile.name == name then
                break
            else
                break
            end if
        end if
    end for
end function

// --------------------------------------------------------------------------------
// the bot script
// --------------------------------------------------------------------------------

for i in range(0, 5)
    water(bot)
end for

moveTo(bot, bot.position.x, bot.position.y - 5)

water = null
for t in findTilesByType("Property", "Water")
    water = findCloser(bot.position, water, t)
end for
print "water location"
pprint water

target = findAdjacent(bot.position, water.x, water.y)
print "target location"
pprint target

origin = bot.position
moveTo(bot, target.x, target.y)

print "at location"
print "watering"

spinAndFind(bot, "Property", "Water")
if bot.ahead.type == "Property" then
    doWater(bot)
else
    print "no water found"
end if

print "returning home"
moveTo(bot, origin.x, origin.y)
