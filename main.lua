
local GRID_SIZE = 5
local CELL_SIZE = 40
local SHIP_COUNT = 3

local playerGrid, computerGrid
local playerHits, computerHits
local playerTurn
local gameState

function love.load()
    love.window.setTitle("Sinking Ships")
    love.window.setMode(GRID_SIZE * CELL_SIZE * 2, GRID_SIZE * CELL_SIZE)

    playerGrid = createGrid()
    computerGrid = createGrid()
    playerHits = {}
    computerHits = {}
    playerTurn = true
    gameState = "playing"

    placeShips(playerGrid, SHIP_COUNT)
    placeShips(computerGrid, SHIP_COUNT)
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


function placeShips(grid, count)
    local placed = 0
    while placed < count do
        local x = math.random(1, GRID_SIZE)
        local y = math.random(1, GRID_SIZE)
        if grid[x][y] == 0 then
            grid[x][y] = 1
            placed = placed + 1
        end
    end
end


function love.draw()
    love.graphics.clear()
    drawGrid(playerGrid, 0, "Player's Grid")
    drawGrid(computerGrid, GRID_SIZE * CELL_SIZE, "Computer's Grid", true)

    if gameState == "won" then
        love.graphics.print("You Won!", 10, GRID_SIZE * CELL_SIZE + 10)
    elseif gameState == "lost" then
        love.graphics.print("You Lost!", 10, GRID_SIZE * CELL_SIZE + 10)
    end
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
    if button == 1 and playerTurn and gameState == "playing" then
        local gridX, gridY = getGridCoordinates(x, y, GRID_SIZE * CELL_SIZE)
        if gridX and gridY then
            if computerGrid[gridX][gridY] == 1 then
                computerGrid[gridX][gridY] = 2
                table.insert(playerHits, {gridX, gridY})
            else
                computerGrid[gridX][gridY] = 3
            end
            playerTurn = false
            checkGameState()
            if gameState == "playing" then
                computerMove()
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
    else
        playerGrid[gridX][gridY] = 3
    end
    playerTurn = true
    checkGameState()
end

function checkGameState()
    if #playerHits == SHIP_COUNT then
        gameState = "won"
    elseif #computerHits == SHIP_COUNT then
        gameState = "lost"
    end
end
