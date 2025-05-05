local ffi = require("ffi")
ffi.cdef [[
    int Pareggio(char Tavola[3][3]);
    int Vittoria(char Tavola[3][3]);
    void Log(const char *Tipo, const char *Messaggio);
]]
local Backend = ffi.load("Back-end\\Back.dll")
local Msg

local musicTracks = {}
local currentTrack = 1
local music

local Tabella = {
    { ' ', ' ', ' ' },
    { ' ', ' ', ' ' },
    { ' ', ' ', ' ' }
}
local SchedaSelezionata = "Menu"

local Menu = { "SinglePlayer", "MultiPlayer", "Online", "Exit" }
local MenuScelta = 1

local StadioGioco = 0
local Partita = 1
local Giocatore = 1

function Tabella_Lua_C(Tavola)
    local CArray = ffi.new("char[3][3]")
    for i = 1, 3 do
        for j = 1, 3 do
            CArray[i - 1][j - 1] = Tavola[i][j]:byte()
        end
    end
    return CArray
end

function ResetGame()
    Tabella = {
        { ' ', ' ', ' ' },
        { ' ', ' ', ' ' },
        { ' ', ' ', ' ' }
    }
    StadioGioco = 0
    Giocatore = 1
end

function Debbuging(Tipo, Msg)
    print("[" .. Tipo .. "] " .. Msg)
    Backend.Log(Tipo, Msg)
end

function love.load()
    love.window.setTitle("Tris")
    love.window.setIcon(love.image.newImageData("Resources/Icon/Tris_icon.png"))
    love.graphics.setFont(love.graphics.newFont(20))
    IconaRestart = love.graphics.newImage("Resources/Game_Buttons/Restart.png")

    for _, file in ipairs(love.filesystem.getDirectoryItems("Resources/Music")) do
        if file:match("%.ogg$") or file:match("%.mp3$") then
            table.insert(musicTracks, "Resources/Music/" .. file)
        end
    end

    Debbuging("START", "Gioco avviato con successo, buon divertimento!")
end

function love.quit()
    Debbuging("CLOSE", "Il gioco e' stato chiuso.")
end

function love.update(dt)
    if music and music:isPlaying() and musicTracks[1] then return end

    local success, newMusic = pcall(love.audio.newSource, musicTracks[currentTrack], "stream")
    if success then
        music = newMusic
        music:setLooping(false)
        music:play()
        Debbuging("DEBUG", "Avviato la esecuzione di " .. musicTracks[currentTrack] .. "!")
    else
        if musicTracks[currentTrack] ~= nil then
            Debbuging("ERRORE", musicTracks[currentTrack] .. " non può essere caricato!")
        end
    end

    currentTrack = (currentTrack % #musicTracks) + 1
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
                Msg = "Avvio SinglePlayer"
                love.window.setTitle("Tris - SinglePlayer")
            elseif Menu[MenuScelta] == "MultiPlayer" then
                Msg = "Avvio MultiPlayer"
                love.window.setTitle("Tris - MultiPlayer")
            elseif Menu[MenuScelta] == "Online" then
                Msg = "Avvio Online (Ancora da aggiungere)!"
                love.window.setTitle("Tris - Online")
            elseif Menu[MenuScelta] == "Exit" then
                love.event.quit()
            end
            Debbuging("INFO", Msg)
            SchedaSelezionata = Menu[MenuScelta]
        end
    end
end

function love.mousepressed(x, y, button)
    if button == 1 and SchedaSelezionata == "MultiPlayer" and StadioGioco == 0 then
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
                        Debbuging("DEBUG", "Il giocatore " .. Giocatore .. " ha cliccato la casella: " .. Riga .. ", " .. Colonna)
                        if Giocatore == 1 then
                            Tabella[Riga][Colonna] = 'X'
                        else
                            Tabella[Riga][Colonna] = 'O'
                        end
                    end
                end
            end
        end
        local Risultato = Backend.Vittoria(Tabella_Lua_C(Tabella))
        if Risultato ~= 0 then
            StadioGioco = Risultato
            Debbuging("INFO", "Giocatore " .. Giocatore .. " ha vinto con il risultato = " .. StadioGioco .. "!")
        else
            Risultato = Backend.Pareggio(Tabella_Lua_C(Tabella))
            if result == -1 then
                StadioGioco = Risultato
                Debbuging("INFO", "Partita finita col pareggio!")
            end
        end
        if Giocatore == 1 then
            Giocatore = 2
        else
            Giocatore = 1
        end
    elseif button == 1 and StadioGioco ~= 0 then
        local restartSize = math.min(love.graphics.getWidth(), love.graphics.getHeight()) * 0.1
        local restartX = love.graphics.getWidth() * 0.02
        local restartY = love.graphics.getHeight() * 0.02

        if button == 1 and x >= restartX and x <= restartX + restartSize and y >= restartY and y <= restartY + restartSize then
            ResetGame()
            Debbuging("INFO", "Partita resettata!")
        end

        local exitSize = math.min(love.graphics.getWidth(), love.graphics.getHeight()) * 0.1
        local exitX = love.graphics.getWidth() * 0.95 - exitSize
        local exitY = love.graphics.getHeight() * 0.02

        if x >= exitX and x <= exitX + exitSize and y >= exitY and y <= exitY + exitSize then
            SchedaSelezionata = "Menu"
            ResetGame()
            Debbuging("INFO", "Tornato al menu principale")
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
    else
        if SchedaSelezionata == "SinglePlayer" then

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

            if StadioGioco > 0 then
                love.graphics.setColor(1, 0, 0)
                love.graphics.setLineWidth(5)

                if StadioGioco >= 10 and StadioGioco < 20 then -- Row win
                    local row = StadioGioco - 10
                    love.graphics.line(offsetX, offsetY + row * cellSize + cellSize / 2, offsetX + tableSize,
                        offsetY + row * cellSize + cellSize / 2)
                elseif StadioGioco >= 20 and StadioGioco < 30 then -- Column win
                    local col = StadioGioco - 20
                    love.graphics.line(offsetX + col * cellSize + cellSize / 2, offsetY,
                        offsetX + col * cellSize + cellSize / 2, offsetY + tableSize)
                elseif StadioGioco == 31 then -- Diagonal win
                    love.graphics.line(offsetX, offsetY, offsetX + tableSize, offsetY + tableSize)
                elseif StadioGioco == 32 then
                    love.graphics.line(offsetX + tableSize, offsetY, offsetX, offsetY + tableSize)
                end
            end
        elseif SchedaSelezionata == "Online" then

        end
    end
    if StadioGioco ~= 0 then
        local buttonSize = math.min(love.graphics.getWidth(), love.graphics.getHeight()) * 0.08 -- Slightly smaller

        local restartX = love.graphics.getWidth() * 0.02
        local restartY = love.graphics.getHeight() * 0.02
        love.graphics.draw(IconaRestart, restartX, restartY, 0, buttonSize / IconaRestart:getWidth(),
            buttonSize / IconaRestart:getHeight())

        local exitX = love.graphics.getWidth() - buttonSize - love.graphics.getWidth() * 0.02
        local exitY = restartY

        love.graphics.setColor(1, 1, 1)
        love.graphics.setLineWidth(4)
        love.graphics.line(exitX + buttonSize * 0.1, exitY + buttonSize * 0.1, exitX + buttonSize * 0.9,
            exitY + buttonSize * 0.9)                                                                                              -- Diagonal line /
        love.graphics.line(exitX + buttonSize * 0.9, exitY + buttonSize * 0.1, exitX + buttonSize * 0.1,
            exitY + buttonSize * 0.9)                                                                                              -- Diagonal line \
    end
end
