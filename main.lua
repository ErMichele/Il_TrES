local ffi = require("ffi")
ffi.cdef [[
    int Pareggio(char Tavola[3][3]);
    int Vittoria(char Tavola[3][3]);
    void Log(const char *Tipo, const char *Messaggio);
]]
local Backend = ffi.load("Back-end\\Back.dll")
local Msg

function Tabella_Lua_C(Tavola)
    local CArray = ffi.new("char[3][3]")
    for i = 1, 3 do
        for j = 1, 3 do
            CArray[i - 1][j - 1] = Tavola[i][j]:byte()
        end
    end
    return CArray
end

local Tabella = {
    { ' ', ' ', ' ' },
    { ' ', ' ', ' ' },
    { ' ', ' ', ' ' }
}
local SchedaSelezionata = "Menu"

local Menu = { "SinglePlayer", "MultiPlayer", "Online", "Exit" }
local MenuScelta = 1

local StadioGioco = "Giocando"
local Partita = 1
local Giocatore = 1

function love.load()
    love.window.setTitle("Tris")
    love.window.setIcon(love.image.newImageData("Resources/Icon/Tris_icon.png"))
    love.graphics.setFont(love.graphics.newFont(20))
end

function love.keypressed(key)
    if SchedaSelezionata == "Menu" then
        if key == "down" then
            MenuScelta = MenuScelta + 1
            if MenuScelta > #Menu then
                MenuScelta = 1
            end
        elseif key == "up" then
            MenuScelta = MenuScelta - 1
            if MenuScelta < 1 then
                MenuScelta = #Menu
            end
        elseif key == "return" then
            if Menu[MenuScelta] == "SinglePlayer" then
                print("Avvio SinglePlayer")
                love.window.setTitle("Tris - SinglePlayer")
            elseif Menu[MenuScelta] == "MultiPlayer" then
                print("Avvio MultiPlayer")
                love.window.setTitle("Tris - MultiPlayer")
            elseif Menu[MenuScelta] == "Online" then
                print("Avvio Online (Ancora da aggiungere)!")
                love.window.setTitle("Tris - Online")
            elseif Menu[MenuScelta] == "Exit" then
                love.event.quit()
            end
            SchedaSelezionata = Menu[MenuScelta]
        end
    end
end

function love.mousepressed(x, y, button)
    if button == 1 and SchedaSelezionata == "MultiPlayer" and StadioGioco == "Giocando" then
        local tableSize = math.min(love.graphics.getWidth(), love.graphics.getHeight()) * 0.6
        local offsetX = (love.graphics.getWidth() - tableSize) / 2
        local offsetY = (love.graphics.getHeight() - tableSize) / 2
        local cellSize = tableSize / 3

        for Riga = 1, 3 do
            for Colonna = 1, 3 do
                local cellX = offsetX + (Colonna - 1) * cellSize
                local cellY = offsetY + (Riga - 1) * cellSize

                if x >= cellX and x <= cellX + cellSize and y >= cellY and y <= cellY + cellSize then
                    if Tabella[Riga][Colonna] == ' ' then
                        print("Il giocatore " .. Giocatore .. " ha cliccato la casella: " .. Riga .. ", " .. Colonna)
                        if Giocatore == 1 then
                            Tabella[Riga][Colonna] = 'X'
                            Giocatore = 2
                        else
                            Tabella[Riga][Colonna] = 'O'
                            Giocatore = 1
                        end
                    end
                end
            end
        end
    end
end

function love.draw()
    love.graphics.clear(0.68, 0.85, 0.9)

    if SchedaSelezionata == "Menu" then
        -- Title dynamically sized and positioned
        local titleFontSize = love.graphics.getHeight() * 0.1
        local titleY = love.graphics.getHeight() * 0.1
        love.graphics.setFont(love.graphics.newFont("Resources/Font/TimesNewRoman.ttf", titleFontSize))
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("IL TRIS", 0, titleY, love.graphics.getWidth(), "center")

        -- Menu options dynamically sized and positioned
        local menuFontSize = love.graphics.getHeight() * 0.05
        local menuStartY = love.graphics.getHeight() * 0.3
        local menuSpacing = love.graphics.getHeight() * 0.08

        for i, Scelta in ipairs(Menu) do
            if i == MenuScelta then
                love.graphics.setColor(1, 1, 0)
            else
                love.graphics.setColor(0.7, 0.5, 0)
            end

            love.graphics.setFont(love.graphics.newFont(menuFontSize))
            local menuY = menuStartY + (i - 1) * menuSpacing
            love.graphics.printf(Scelta, 0, menuY, love.graphics.getWidth(), "center")
        end
    elseif SchedaSelezionata == "SinglePlayer" then

    elseif SchedaSelezionata == "MultiPlayer" then
        -- Grid dynamically sized as before
        local tableSize = math.min(love.graphics.getWidth(), love.graphics.getHeight()) * 0.6
        local offsetX = (love.graphics.getWidth() - tableSize) / 2
        local offsetY = (love.graphics.getHeight() - tableSize) / 2
        local cellSize = tableSize / 3

        -- Draw grid lines
        love.graphics.setColor(1, 1, 1)
        love.graphics.setLineWidth(2)
        love.graphics.line(offsetX + cellSize, offsetY, offsetX + cellSize, offsetY + tableSize)
        love.graphics.line(offsetX + 2 * cellSize, offsetY, offsetX + 2 * cellSize, offsetY + tableSize)
        love.graphics.line(offsetX, offsetY + cellSize, offsetX + tableSize, offsetY + cellSize)
        love.graphics.line(offsetX, offsetY + 2 * cellSize, offsetX + tableSize, offsetY + 2 * cellSize)

        -- Draw player marks dynamically
        for i = 1, 3 do
            for j = 1, 3 do
                local cellX = offsetX + (j - 1) * cellSize
                local cellY = offsetY + (i - 1) * cellSize
                if Tabella[i][j] ~= ' ' then
                    love.graphics.setFont(love.graphics.newFont(cellSize * 0.5))
                    love.graphics.setColor(1, 0, 0)
                    love.graphics.printf(Tabella[i][j], cellX, cellY + cellSize * 0.25, cellSize, "center")
                end
            end
        end
    end
end
