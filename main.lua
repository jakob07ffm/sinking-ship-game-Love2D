local GRID_SIZE = 5
local CELL_SIZE = 40
local SHIP_SIZES = {2, 3, 3}
local SHIP_COUNT = #SHIP_SIZES

local playerGrid, computerGrid
local playerHits, computerHits
local playerTurn
local gameState
local placingShipIndex
local placingShipOrientation
local playerScore, computerScore
local sounds
local hitAnimations, missAnimations

function love.load()
    love.window.setTitle("Sinking Ships")
    love.window.setMode(GRID_SIZE * CELL_SIZE * 2, GRID_SIZE * CELL_SIZE + 100)

    sounds = {
        hit = love.audio.newSource("hit.wav", "static"),
        miss = love.audio.newSource("miss.wav", "static"),
        sunk = love.audio.newSource("sunk.wav", "static")
    }

    resetGame()
end

function resetGame()
    playerGrid = createGrid()
    computerGrid = createGrid()
    playerHits = {}
    computerHits = {}
    playerTurn = false
    gameState = "placing"
    placingShipIndex = 1
    placingShipOrientation = 0
    playerScore = {hits = 0, misses = 0, sunk = 0}
    computerScore = {hits = 0, misses = 0, sunk = 0}
    hitAnimations = {}
    missAnimations = {}

    placeShips(computerGrid, SHIP_SIZES)
end

function createGrid()
    local grid = {}
    for i = 1, GRID_SIZE do
        grid[i] = {}
        for j = 1, GRID_SIZE do
            grid[i][j] = {status = 0, ship = 0}
        end
    end
    return grid
end

function placeShips(grid, sizes)
    for id, size in ipairs(sizes) do
        local placed = false
        while not placed do
            local x = math.random(1, GRID_SIZE)
            local y = math.random(1, GRID_SIZE)
            local orientation = math.random(0, 1)
            if canPlaceShip(grid, x, y, size, orientation) then
                for i = 0, size - 1 do
                    if orientation == 0 then
                        grid[x + i][y] = {status = 1, ship = id}
                    else
                        grid[x][y + i] = {status = 1, ship = id}
                    end
                end
                placed = true
            end
        end
    end
end

function canPlaceShip(grid, x, y, size, orientation)
    if orientation == 0 then
        if x + size - 1 > GRID_SIZE then return false end
        for i = 0, size - 1 do
            if grid[x + i][y].status ~= 0 then return false end
        end
    else
        if y + size - 1 > GRID_SIZE then return false end
        for i = 0, size - 1 do
            if grid[x][y + i].status ~= 0 then return false end
        end
    end
    return true
end

function love.draw()
    love.graphics.clear()
    drawGrid(playerGrid, 0, "Player's Grid", gameState ~= "placing")
    drawGrid(computerGrid, GRID_SIZE * CELL_SIZE, "Computer's Grid", true)

    if gameState == "won" then
        love.graphics.print("You Won!", 10, GRID_SIZE * CELL_SIZE + 10)
    elseif gameState == "lost" then
        love.graphics.print("You Lost!", 10, GRID_SIZE * CELL_SIZE + 10)
    elseif gameState == "placing" then
        love.graphics.print("Place your ships", 10, GRID_SIZE * CELL_SIZE + 10)
    else
        love.graphics.print("Your turn!", 10, GRID_SIZE * CELL_SIZE + 10)
    end

    love.graphics.print("Press R to Reset", 10, GRID_SIZE * CELL_SIZE + 30)

    drawScores()
    drawAnimations()
end

function drawGrid(grid, offsetX, title, hidden)
    love.graphics.print(title, offsetX, 10)
    for i = 1, GRID_SIZE do
        for j = 1, GRID_SIZE do
            local x = (i - 1) * CELL_SIZE + offsetX
            local y = (j - 1) * CELL_SIZE + 20
            love.graphics.rectangle("line", x, y, CELL_SIZE, CELL_SIZE)
            if grid[i][j].status == 1 and (not hidden or (hidden and playerTurn == false)) then
                love.graphics.setColor(0, 1, 0)
                love.graphics.rectangle("fill", x, y, CELL_SIZE, CELL_SIZE)
                love.graphics.setColor(1, 1, 1)
            end
            if grid[i][j].status == 2 then
                love.graphics.setColor(1, 0, 0)
                love.graphics.rectangle("fill", x, y, CELL_SIZE, CELL_SIZE)
                love.graphics.setColor(1, 1, 1)
            elseif grid[i][j].status == 3 then
                love.graphics.setColor(0, 0, 1)
                love.graphics.rectangle("fill", x, y, CELL_SIZE, CELL_SIZE)
                love.graphics.setColor(1, 1, 1)
            end
        end
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        if gameState == "placing" then
            local gridX, gridY = getGridCoordinates(x, y, 0)
            if gridX and gridY then
                if canPlaceShip(playerGrid, gridX, gridY, SHIP_SIZES[placingShipIndex], placingShipOrientation) then
                    for i = 0, SHIP_SIZES[placingShipIndex] - 1 do
                        if placingShipOrientation == 0 then
                            playerGrid[gridX + i][gridY] = {status = 1, ship = placingShipIndex}
                        else
                            playerGrid[gridX][gridY + i] = {status = 1, ship = placingShipIndex}
                        end
                    end
                    placingShipIndex = placingShipIndex + 1
                    if placingShipIndex > SHIP_COUNT then
                        gameState = "playing"
                        playerTurn = true
                    end
                end
            end
        elseif gameState == "playing" and playerTurn then
            local gridX, gridY = getGridCoordinates(x, y, GRID_SIZE * CELL_SIZE)
            if gridX and gridY then
                if computerGrid[gridX][gridY].status == 1 then
                    computerGrid[gridX][gridY].status = 2
                    table.insert(playerHits, {gridX, gridY})
                    playerScore.hits = playerScore.hits + 1
                    checkSunkShip(computerGrid, computerGrid[gridX][gridY].ship, playerScore)
                    sounds.hit:play()
                    table.insert(hitAnimations, {x = gridX, y = gridY, time = 0})
                else
                    computerGrid[gridX][gridY].status = 3
                    playerScore.misses = playerScore.misses + 1
                    sounds.miss:play()
                    table.insert(missAnimations, {x = gridX, y = gridY, time = 0})
                end
                playerTurn = false
                checkGameState()
                if gameState == "playing" then
                    computerMove()
                end
            end
        end
    end
end

function getGridCoordinates(x, y, offsetX)
    if x > offsetX and x < offsetX + GRID_SIZE * CELL_SIZE and y > 20 and y < 20 + GRID_SIZE * CELL_SIZE then
        local gridX = math.floor((x - offsetX) / CELL_SIZE) + 1
        local gridY = math.floor((y - 20) / CELL_SIZE) + 1
        return gridX, gridY
    end
    return nil, nil
end

function computerMove()
    local gridX, gridY
    local hitAdjacent = false

    for _, hit in ipairs(computerHits) do
        local adjacents = getAdjacentCells(hit[1], hit[2])
        for _, cell in ipairs(adjacents) do
            if playerGrid[cell.x][cell.y].status == 0 or playerGrid[cell.x][cell.y].status == 1 then
                gridX, gridY = cell.x, cell.y
                hitAdjacent = true
                break
            end
        end
        if hitAdjacent then break end
    end

    if not hitAdjacent then
        repeat
            gridX = math.random(1, GRID_SIZE)
            gridY = math.random(1, GRID_SIZE)
        until playerGrid[gridX][gridY].status < 2
    end

    if playerGrid[gridX][gridY].status == 1 then
        playerGrid[gridX][gridY].status = 2
        table.insert(computerHits, {gridX, gridY})
        computerScore.hits = computerScore.hits + 1
        checkSunkShip(playerGrid, playerGrid[gridX][gridY].ship, computerScore)
        sounds.hit:play()
        table.insert(hitAnimations, {x = gridX, y = gridY, time = 0})
    else
        playerGrid[gridX][gridY].status = 3
        computerScore.misses = computerScore.misses + 1
        sounds.miss:play()
        table.insert(missAnimations, {x = gridX, y = gridY, time = 0})
    end
    playerTurn = true
    checkGameState()
end

function getAdjacentCells(x, y)
    local cells = {}
    if x > 1 then table.insert(cells, {x = x - 1, y = y}) end
    if x < GRID_SIZE then table.insert(cells, {x = x + 1, y = y}) end
    if y > 1 then table.insert(cells, {x = x, y = y - 1}) end
    if y < GRID_SIZE then table.insert(cells, {x = x, y = y + 1}) end
    return cells
end

function checkSunkShip(grid, shipId, score)
    local sunk = true
    for i = 1, GRID_SIZE do
        for j = 1, GRID_SIZE do
            if grid[i][j].ship == shipId and grid[i][j].status ~= 2 then
                sunk = false
                break
            end
        end
    end
    if sunk then
        score.sunk = score.sunk + 1
        sounds.sunk:play()
    end
end

function checkGameState()
    if playerScore.hits == #SHIP_SIZES then
        gameState = "won"
    elseif computerScore.hits == #SHIP_SIZES then
        gameState = "lost"
    end
end

function love.keypressed(key)
    if key == "r" then
        resetGame()
    elseif key == "space" and gameState == "placing" then
        placingShipOrientation = 1 - placingShipOrientation
    end
end

function drawScores()
    love.graphics.print("Player Score", 10, GRID_SIZE * CELL_SIZE + 50)
    love.graphics.print("Hits: " .. playerScore.hits, 10, GRID_SIZE * CELL_SIZE + 70)
    love.graphics.print("Misses: " .. playerScore.misses, 10, GRID_SIZE * CELL_SIZE + 90)
    love.graphics.print("Sunk: " .. playerScore.sunk, 10, GRID_SIZE * CELL_SIZE + 110)

    love.graphics.print("Computer Score", GRID_SIZE * CELL_SIZE + 10, GRID_SIZE * CELL_SIZE + 50)
    love.graphics.print("Hits: " .. computerScore.hits, GRID_SIZE * CELL_SIZE + 10, GRID_SIZE * CELL_SIZE + 70)
    love.graphics.print("Misses: " .. computerScore.misses, GRID_SIZE * CELL_SIZE + 10, GRID_SIZE * CELL_SIZE + 90)
    love.graphics.print("Sunk: " .. computerScore.sunk, GRID_SIZE * CELL_SIZE + 10, GRID_SIZE * CELL_SIZE + 110)
end

function drawAnimations()
    for i, anim in ipairs(hitAnimations) do
        anim.time = anim.time + love.timer.getDelta()
        if anim.time > 0.5 then
            table.remove(hitAnimations, i)
        else
            local x = (anim.x - 1) * CELL_SIZE + GRID_SIZE * CELL_SIZE
            local y = (anim.y - 1) * CELL_SIZE + 20
            love.graphics.setColor(1, 0, 0, 1 - anim.time / 0.5)
            love.graphics.rectangle("fill", x, y, CELL_SIZE, CELL_SIZE)
            love.graphics.setColor(1, 1, 1)
        end
    end

    for i, anim in ipairs(missAnimations) do
        anim.time = anim.time + love.timer.getDelta()
        if anim.time > 0.5 then
            table.remove(missAnimations, i)
        else
            local x = (anim.x - 1) * CELL_SIZE + GRID_SIZE * CELL_SIZE
            local y = (anim.y - 1) * CELL_SIZE + 20
            love.graphics.setColor(0, 0, 1, 1 - anim.time / 0.5)
            love.graphics.rectangle("fill", x, y, CELL_SIZE, CELL_SIZE)
            love.graphics.setColor(1, 1, 1)
        end
    end
end
