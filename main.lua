local ffi = require("ffi")
ffi.cdef [[
    int Pareggio(char Tavola[3][3]);
    int Vittoria(char Tavola[3][3]);
    void Log(const char *Tipo, const char *Messaggio);
    int mossaComputer(char board[3][3]);
]]
local Backend = ffi.load("Back-end\\Back.dll")

local musicTracks = {}
local currentTrack = 1
local music

local Tabella = {
    { ' ', ' ', ' ' },
    { ' ', ' ', ' ' },
    { ' ', ' ', ' ' }
}

local Menu = { "SinglePlayer", "MultiPlayer", "Crediti", "Exit" }
local MenuScelta = 1
local SchedaSelezionata = "Menu"

local BarraVolume = {
    x = 100,
    y = 200,
    width = 300,
    height = 10,
    knobX = 250,
    knobWidth = 20,
    value = 0.5,
    dragging = false
}

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
    love.window.setTitle("TrES")
    love.window.setIcon(love.image.newImageData("Resources/Icon/Tris_icon.png"))

    --Fonts
    love.graphics.setFont(love.graphics.newFont(20))

    --Foto
    IconaRestart = love.graphics.newImage("Resources/Game_Buttons/Restart.png")
    IconaImpostazioni = love.graphics.newImage("Resources/Game_Buttons/Config.png")

    --Musica
    for _, file in ipairs(love.filesystem.getDirectoryItems("Resources/Music")) do
        if file:match("%.ogg$") or file:match("%.mp3$") then
            table.insert(musicTracks, "Resources/Music/" .. file)
        end
    end

    --Suoni
    Selezione = love.audio.newSource("Resources/SoundEffects/Select.mp3", "stream")
    Selezione:setLooping(false)
    Selezione:setVolume(0.09)

    Debbuging("START", "Gioco avviato con successo, buon divertimento!")
end

function love.quit()
    Debbuging("CLOSE", "Il gioco e' stato chiuso.")
end

function love.update(dt)
    if BarraVolume.dragging then
        local mouseX = love.mouse.getX()
        BarraVolume.knobX = math.max(BarraVolume.x, math.min(mouseX, BarraVolume.x + BarraVolume.width - BarraVolume.knobWidth))
        BarraVolume.value = (BarraVolume.knobX - BarraVolume.x) / (BarraVolume.width - BarraVolume.knobWidth)
        music:setVolume(BarraVolume.value)
    end
    
    if music and music:isPlaying() then return end

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
            local Msg
            if Menu[MenuScelta] == "SinglePlayer" then
                Msg = "Avvio SinglePlayer"
                love.window.setTitle("TrES - SinglePlayer")
            elseif Menu[MenuScelta] == "MultiPlayer" then
                Msg = "Avvio MultiPlayer"
                love.window.setTitle("TrES - MultiPlayer")
            elseif Menu[MenuScelta] == "Online" then
                Msg = "Avvio Online (Ancora da aggiungere)!"
                love.window.setTitle("TrES - Online")
            elseif Menu[MenuScelta] == "Crediti" then
                Msg = "Visualizzazione dei crediti"
                love.window.setTitle("TrES - Crediti")
            elseif Menu[MenuScelta] == "Exit" then
                love.event.quit()
            end
            Selezione:play()
            if Menu[MenuScelta] ~= "Exit" then
                Debbuging("INFO", Msg)
                SchedaSelezionata = Menu[MenuScelta]
            end
        end
    elseif SchedaSelezionata ~= "Menu" and key == "escape" then
        SchedaSelezionata = "Menu"
        ResetGame()
        Debbuging("INFO", "Tornato al menu principale")
        love.window.setTitle("TrES")
    end
end

function love.mousepressed(x, y, button)
    if SchedaSelezionata == "Menu" then
        local ImpostazioniSize = math.min(love.graphics.getWidth(), love.graphics.getHeight()) * 0.10
        local ImpostazioniX = love.graphics.getWidth() - ImpostazioniSize - love.graphics.getWidth() * 0.01
        local ImpostazioniY = love.graphics.getHeight() * 0.01
        if x >= ImpostazioniX and x <= ImpostazioniX + ImpostazioniSize and y >= ImpostazioniY and y <= ImpostazioniY + ImpostazioniSize then
            Debbuging("INFO", "Visualizzazione delle impostazioni!")
            love.window.setTitle("TrES - Impostazioni")
            SchedaSelezionata = "Impostazioni"
        end
    elseif button == 1 and SchedaSelezionata == "MultiPlayer" and StadioGioco == 0 then
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
            if Risultato == -1 then
                StadioGioco = Risultato
                Debbuging("INFO", "Partita finita col pareggio!")
            end
        end
        Giocatore = (Giocatore == 1) and 2 or 1

    elseif button == 1 and SchedaSelezionata == "SinglePlayer" and StadioGioco == 0 then
        local tableSize = math.min(love.graphics.getWidth(), love.graphics.getHeight()) * 0.6
        local offsetX = (love.graphics.getWidth() - tableSize) / 2
        local offsetY = (love.graphics.getHeight() - tableSize) / 2
        local cellSize = tableSize / 3
    
        local mossaEseguita = false
        for Riga = 1, 3 do
            for Colonna = 1, 3 do
                local cellX = offsetX + (Colonna - 1) * cellSize
                local cellY = offsetY + (Riga - 1) * cellSize
    
                if x >= cellX and x <= cellX + cellSize and y >= cellY and y <= cellY + cellSize then
                    if Tabella[Riga][Colonna] == ' ' then
                        Debbuging("DEBUG", "Il giocatore ha cliccato la casella: " .. Riga .. ", " .. Colonna)
                        Tabella[Riga][Colonna] = 'X'
                        mossaEseguita = true
                    end
                end
            end
        end
    
        if mossaEseguita then
            local risultato = Backend.Vittoria(Tabella_Lua_C(Tabella))
            if risultato ~= 0 then
                StadioGioco = risultato
                Debbuging("INFO", "Il giocatore ha vinto con il risultato = " .. StadioGioco .. "!")
                return
            else
                risultato = Backend.Pareggio(Tabella_Lua_C(Tabella))
                if risultato == -1 then
                    StadioGioco = risultato
                    Debbuging("INFO", "Partita finita col pareggio!")
                    return
                end
            end
    
            -- CPU Move
            if StadioGioco == 0 then
                local Casella = Backend.mossaComputer(Tabella_Lua_C(Tabella))
                local Xcord = math.floor(Casella / 3) + 1
                local Ycord = (Casella % 3) + 1
                Tabella[Xcord][Ycord] = 'O'
                Debbuging("DEBUG", "La CPU ha eseguito la seguente mossa: " .. Xcord .. ", " .. Ycord .. "!")
    
                risultato = Backend.Vittoria(Tabella_Lua_C(Tabella))
                if risultato ~= 0 then
                    StadioGioco = risultato
                    Debbuging("INFO", "La CPU ha vinto con il risultato = " .. StadioGioco .. "!")
                else
                    risultato = Backend.Pareggio(Tabella_Lua_C(Tabella))
                    if risultato == -1 then
                        StadioGioco = risultato
                        Debbuging("INFO", "Partita finita col pareggio!")
                    end
                end
            end
        end
    elseif button == 1 and StadioGioco ~= 0 then
        local restartSize = math.min(love.graphics.getWidth(), love.graphics.getHeight()) * 0.1
        local restartX = love.graphics.getWidth() * 0.02
        local restartY = love.graphics.getHeight() * 0.02

        if x >= restartX and x <= restartX + restartSize and y >= restartY and y <= restartY + restartSize then
            ResetGame()
            Debbuging("INFO", "Partita resettata!")
        end
    elseif button == 1 and SchedaSelezionata == "Impostazioni" then
        if  x >= BarraVolume.knobX and x <= BarraVolume.knobX + BarraVolume.knobWidth and y >= BarraVolume.y - 5 and y <= BarraVolume.y + BarraVolume.height + 5 then
            BarraVolume.dragging = true
        end
    end
end

function love.mousereleased(x, y, button)
    if button == 1 then
        BarraVolume.dragging = false
    end
end

function love.draw()
    love.graphics.clear(0.68, 0.85, 0.9)

    if SchedaSelezionata == "Menu" then
        local titleFontSize = love.graphics.getHeight() * 0.1
        local titleY = love.graphics.getHeight() * 0.1
        love.graphics.setFont(love.graphics.newFont("Resources/Font/TimesNewRoman.ttf", titleFontSize))
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Il TrES", 0, titleY, love.graphics.getWidth(), "center")

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
        local ImpostazioniSize = math.min(love.graphics.getWidth(), love.graphics.getHeight()) * 0.10
        local ImpostazioniX = love.graphics.getWidth() - ImpostazioniSize - love.graphics.getWidth() * 0.01
        local ImpostazioniY = love.graphics.getHeight() * 0.01

        love.graphics.draw(IconaImpostazioni, ImpostazioniX, ImpostazioniY, 0, ImpostazioniSize / IconaImpostazioni:getWidth(), ImpostazioniSize / IconaImpostazioni:getHeight())
    elseif SchedaSelezionata == "Crediti" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont("Resources/Font/TimesNewRoman.ttf", 28))
    
        local Testo = {
            "Il TrES - Crediti",
            "",
            "Owner: ErMichele",
            "",
            "Libreria Grafica: LOVE2D",
            "Linguaggio: Lua + C (DLL)",
            "",
            "Coder: ErMichele",
            "Music: LolYeahTheBest e Apothesis", 
            "",
            "Grazie per aver giocato!",
            "",
            "Premi [Esc] per tornare al menu"
        }
    
        for i, line in ipairs(Testo) do
            love.graphics.printf(line, 0, 100 + i * 30, love.graphics.getWidth(), "center")
        end
    elseif SchedaSelezionata == "Impostazioni" then
        local titleFontSize = love.graphics.getHeight() * 0.1
        local titleY = love.graphics.getHeight() * 0.08
        love.graphics.setFont(love.graphics.newFont("Resources/Font/TimesNewRoman.ttf", titleFontSize))
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Impostazioni", 0, titleY, love.graphics.getWidth(), "center")

        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", BarraVolume.x, BarraVolume.y, BarraVolume.width, BarraVolume.height)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", BarraVolume.knobX, BarraVolume.y - 5, BarraVolume.knobWidth, BarraVolume.height + 10)

        love.graphics.setFont(love.graphics.newFont(20))
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Volume: " .. math.floor(BarraVolume.value * 100) .. "%", BarraVolume.x, BarraVolume.y - 30)
    else
        local tableSize = math.min(love.graphics.getWidth(), love.graphics.getHeight()) * 0.6
        local offsetX = (love.graphics.getWidth() - tableSize) / 2
        local offsetY = (love.graphics.getHeight() - tableSize) / 2
        local cellSize = tableSize / 3

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

            if StadioGioco >= 10 and StadioGioco < 20 then     -- Row win
                local row = StadioGioco - 10
                love.graphics.line(offsetX, offsetY + row * cellSize + cellSize / 2, offsetX + tableSize,
                    offsetY + row * cellSize + cellSize / 2)
            elseif StadioGioco >= 20 and StadioGioco < 30 then     -- Column win
                local col = StadioGioco - 20
                love.graphics.line(offsetX + col * cellSize + cellSize / 2, offsetY,
                    offsetX + col * cellSize + cellSize / 2, offsetY + tableSize)
            elseif StadioGioco == 31 then     -- Diagonal win
                love.graphics.line(offsetX, offsetY, offsetX + tableSize, offsetY + tableSize)
            elseif StadioGioco == 32 then
                love.graphics.line(offsetX + tableSize, offsetY, offsetX, offsetY + tableSize)
            end
        end
        if StadioGioco ~= 0 then
            local buttonSize = math.min(love.graphics.getWidth(), love.graphics.getHeight()) * 0.08 -- Slightly smaller

            local restartX = love.graphics.getWidth() * 0.02
            local restartY = love.graphics.getHeight() * 0.02
            love.graphics.draw(IconaRestart, restartX, restartY, 0, buttonSize / IconaRestart:getWidth(), buttonSize / IconaRestart:getHeight())
        end
    end
end
