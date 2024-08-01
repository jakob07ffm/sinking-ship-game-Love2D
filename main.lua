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
local sounds

function love.load()
    love.window.setTitle("Sinking Ships")
    love.window.setMode(GRID_SIZE * CELL_SIZE * 2, GRID_SIZE * CELL_SIZE + 50)

    sounds = {
        hit = love.audio.newSource("hit.wav", "static"),
        miss = love.audio.newSource("miss.wav", "static")
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

    placeShips(computerGrid, SHIP_SIZES)
end

function createGrid()
    local grid = {}
    for i = 1, GRID_SIZE do
        grid[i] = {}
        for j = 1, GRID_SIZE do
            grid[i][j] = 0
        end
    end
    return grid
end

function placeShips(grid, sizes)
    for _, size in ipairs(sizes) do
        local placed = false
        while not placed do
            local x = math.random(1, GRID_SIZE)
            local y = math.random(1, GRID_SIZE)
            local orientation = math.random(0, 1)
            if canPlaceShip(grid, x, y, size, orientation) then
                for i = 0, size - 1 do
                    if orientation == 0 then
                        grid[x + i][y] = 1
                    else
                        grid[x][y + i] = 1
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
            if grid[x + i][y] ~= 0 then return false end
        end
    else
        if y + size - 1 > GRID_SIZE then return false end
        for i = 0, size - 1 do
            if grid[x][y + i] ~= 0 then return false end
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
end

function drawGrid(grid, offsetX, title, hidden)
    love.graphics.print(title, offsetX, 10)
    for i = 1, GRID_SIZE do
        for j = 1, GRID_SIZE do
            local x = (i - 1) * CELL_SIZE + offsetX
            local y = (j - 1) * CELL_SIZE + 20
            love.graphics.rectangle("line", x, y, CELL_SIZE, CELL_SIZE)
            if grid[i][j] == 1 and (not hidden or (hidden and playerTurn == false)) then
                love.graphics.rectangle("fill", x, y, CELL_SIZE, CELL_SIZE)
            end
            if grid[i][j] == 2 then
                love.graphics.setColor(1, 0, 0)
                love.graphics.rectangle("fill", x, y, CELL_SIZE, CELL_SIZE)
                love.graphics.setColor(1, 1, 1)
            elseif grid[i][j] == 3 then
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
                            playerGrid[gridX + i][gridY] = 1
                        else
                            playerGrid[gridX][gridY + i] = 1
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
                if computerGrid[gridX][gridY] == 1 then
                    computerGrid[gridX][gridY] = 2
                    table.insert(playerHits, {gridX, gridY})
                    sounds.hit:play()
                else
                    computerGrid[gridX][gridY] = 3
                    sounds.miss:play()
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
    repeat
        gridX = math.random(1, GRID_SIZE)
        gridY = math.random(1, GRID_SIZE)
    until playerGrid[gridX][gridY] < 2

    if playerGrid[gridX][gridY] == 1 then
        playerGrid[gridX][gridY] = 2
        table.insert(computerHits, {gridX, gridY})
        sounds.hit:play()
    else
        playerGrid[gridX][gridY] = 3
        sounds.miss:play()
    end
    playerTurn = true
    checkGameState()
end

function checkGameState()
    if #playerHits == #SHIP_SIZES then
        gameState = "won"
    elseif #computerHits == #SHIP_SIZES then
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
