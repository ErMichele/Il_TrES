local ffi = require("ffi")
ffi.cdef [[
    int Pareggio(char Tavola[3][3]);
    int Vittoria(char Tavola[3][3]);
    void Log(const char *Tipo, const char *Messaggio);
    int MossaCPU(char board[3][3]);
]]
local Backend = ffi.load("Back-end\\Back.dll")

local Traccie_Background = {}
local Traccia_Background_Corrente = 1
local Musica_Background

local Tabella = {
    { ' ', ' ', ' ' },
    { ' ', ' ', ' ' },
    { ' ', ' ', ' ' }
}

local Menu = { "SinglePlayer", "MultiPlayer", "Crediti", "Exit" }
local SchedaSelezionata = "Menu"
local MenuScelta = 1

local Barra_Volume_Musica = {
    x = 100,
    y = 200,
    Larghezza = 300,
    Altezza = 10,
    Punto_X = 250,
    Punto_Lato = 20,
    Valore = 0.5,
    Usato = false
}

local Tasto_Restart = {
    Dimensione = math.min(love.graphics.getWidth(), love.graphics.getHeight()) * 0.08,
    x = love.graphics.getWidth() * 0.02,
    y = love.graphics.getHeight() * 0.02,
    Icona = love.graphics.newImage("Resources/Game_Buttons/Restart.png")
}

local Tasto_Impostazioni = {
    Dimensione = math.min(love.graphics.getWidth(), love.graphics.getHeight()) * 0.10,
    x = love.graphics.getWidth() - math.min(love.graphics.getWidth(), love.graphics.getHeight()) * 0.10 -
    love.graphics.getWidth() * 0.01,
    y = love.graphics.getHeight() * 0.01,
    Icona = love.graphics.newImage("Resources/Game_Buttons/Config.png")
}

local Tabella_Grafica = {
    Dimensione = math.min(love.graphics.getWidth(), love.graphics.getHeight()) * 0.6,
    Offset_X = (love.graphics.getWidth() - math.min(love.graphics.getWidth(), love.graphics.getHeight()) * 0.6) / 2,
    Offset_Y = (love.graphics.getHeight() - math.min(love.graphics.getWidth(), love.graphics.getHeight()) * 0.6) / 2,
    Dimensione_Cella = math.min(love.graphics.getWidth(), love.graphics.getHeight()) * 0.6 / 3
}

local StadioGioco = 0
local Partita = 1
local Giocatore = 1

--- Convert Lua table to C array for FFI interaction.
--- @param Tavola table Lua table representing the game board.
--- @return table CArray representing the game board.
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

--- Logs a message to the console and the backend (if available).
--- @param Tipo string  The type of message (e.g., "INFO", "DEBUG", "ERROR").
--- @param Msg  string The message to log.
function Debbuging(Tipo, Msg)
    print("[" .. Tipo .. "] " .. Msg)
    if Backend then
        Backend.Log(Tipo, Msg)
    end
end

--- Esegue una mossa nella cella cliccata, e controlla vittoria/pareggio
--- @param Riga number
--- @param Colonna number
--- @param Simbolo string 'X' o 'O'
function EseguiMossa(Riga, Colonna, Simbolo)
    Tabella[Riga][Colonna] = Simbolo
    local risultato = Backend.Vittoria(Tabella_Lua_C(Tabella))
    if risultato ~= 0 then
        StadioGioco = risultato
        Debbuging("INFO", "Il giocatore '" .. Simbolo .. "' ha vinto con risultato = " .. StadioGioco .. "!")
        return true
    end

    risultato = Backend.Pareggio(Tabella_Lua_C(Tabella))
    if risultato == -1 then
        StadioGioco = risultato
        Debbuging("INFO", "Partita finita col pareggio!")
        return true
    end

    return false
end

function love.load()
    love.window.setTitle("TrES")
    love.window.setIcon(love.image.newImageData("Resources/Icon/Tris_icon.png"))

    --Fonts
    love.graphics.setFont(love.graphics.newFont(20))

    --Musica
    for _, file in ipairs(love.filesystem.getDirectoryItems("Resources/Music")) do
        if file:match("%.ogg$") or file:match("%.mp3$") then
            table.insert(Traccie_Background, "Resources/Music/" .. file)
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
    if Barra_Volume_Musica.Usato then
        local mouseX = love.mouse.getX()
        Barra_Volume_Musica.Punto_X = math.max(Barra_Volume_Musica.x,
            math.min(mouseX, Barra_Volume_Musica.x + Barra_Volume_Musica.Larghezza - Barra_Volume_Musica.Punto_Lato))
        Barra_Volume_Musica.Valore = (Barra_Volume_Musica.Punto_X - Barra_Volume_Musica.x) /
        (Barra_Volume_Musica.Larghezza - Barra_Volume_Musica.Punto_Lato)
        Musica_Background:setVolume(Barra_Volume_Musica.Valore)
    end

    if Musica_Background and Musica_Background:isPlaying() then return end

    local success, newMusic = pcall(love.audio.newSource, Traccie_Background[Traccia_Background_Corrente], "stream")
    if success then
        Musica_Background = newMusic
        Musica_Background:setLooping(false)
        Musica_Background:play()
        Debbuging("DEBUG", "Avviato la esecuzione di " .. Traccie_Background[Traccia_Background_Corrente] .. "!")
    else
        if Traccie_Background[Traccia_Background_Corrente] ~= nil then
            Debbuging("ERRORE", Traccie_Background[Traccia_Background_Corrente] .. " non può essere caricato!")
        end
    end

    Traccia_Background_Corrente = (Traccia_Background_Corrente % #Traccie_Background) + 1
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
        if x >= Tasto_Impostazioni.x and x <= Tasto_Impostazioni.x + Tasto_Impostazioni.Dimensione and y >= Tasto_Impostazioni.y and y <= Tasto_Impostazioni.y + Tasto_Impostazioni.Dimensione then
            Debbuging("INFO", "Visualizzazione delle impostazioni!")
            love.window.setTitle("TrES - Impostazioni")
            SchedaSelezionata = "Impostazioni"
        end
    elseif button == 1 and (SchedaSelezionata == "SinglePlayer" or SchedaSelezionata == "MultiPlayer") and StadioGioco == 0 then
        local mossaEseguita = false
        for Riga = 1, 3 do
            for Colonna = 1, 3 do
                local cellX = Tabella_Grafica.Offset_X + (Colonna - 1) * Tabella_Grafica.Dimensione_Cella
                local cellY = Tabella_Grafica.Offset_Y + (Riga - 1) * Tabella_Grafica.Dimensione_Cella

                if x >= cellX and x <= cellX + Tabella_Grafica.Dimensione_Cella and y >= cellY and y <= cellY + Tabella_Grafica.Dimensione_Cella then
                    if Tabella[Riga][Colonna] == ' ' then
                        local simbolo = (SchedaSelezionata == "SinglePlayer" or Giocatore == 1) and 'X' or 'O'
                        Debbuging("DEBUG",
                            "Il giocatore ha cliccato la casella: " ..
                            Riga .. ", " .. Colonna .. " con simbolo '" .. simbolo .. "'")
                        mossaEseguita = true
                        if EseguiMossa(Riga, Colonna, simbolo) then return end
                        if SchedaSelezionata == "MultiPlayer" then
                            Giocatore = (Giocatore == 1) and 2 or 1
                        end
                    end
                end
            end
        end

        -- Mossa CPU (solo per SinglePlayer)
        if mossaEseguita and SchedaSelezionata == "SinglePlayer" and StadioGioco == 0 then
            local Casella = Backend.MossaCPU(Tabella_Lua_C(Tabella))
            local Riga = math.floor(Casella / 3) + 1
            local Colonna = (Casella % 3) + 1
            if Tabella[Riga][Colonna] == ' ' then
                Tabella[Riga][Colonna] = 'O'
                Debbuging("DEBUG", "La CPU ha eseguito la mossa: " .. Riga .. ", " .. Colonna)
                EseguiMossa(Riga, Colonna, 'O')
            else
                Debbuging("ERRORE", "La CPU ha scelto una casella occupata: " .. Riga .. ", " .. Colonna)
            end
        end
    elseif button == 1 and StadioGioco ~= 0 then
        if x >= Tasto_Restart.x and x <= Tasto_Restart.x + Tasto_Restart.Dimensione and y >= Tasto_Restart.y and y <= Tasto_Restart.y + Tasto_Restart.Dimensione then
            ResetGame()
            Debbuging("INFO", "Partita resettata!")
        end
    elseif button == 1 and SchedaSelezionata == "Impostazioni" then
        if x >= Barra_Volume_Musica.Punto_X and x <= Barra_Volume_Musica.Punto_X + Barra_Volume_Musica.Punto_Lato and y >= Barra_Volume_Musica.y - 5 and y <= Barra_Volume_Musica.y + Barra_Volume_Musica.Altezza + 5 then
            Barra_Volume_Musica.Usato = true
        end
    end
end

function love.mousereleased(x, y, button)
    if button == 1 and Barra_Volume_Musica.Usato then
        Barra_Volume_Musica.Usato = false
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

        love.graphics.draw(Tasto_Impostazioni.Icona, Tasto_Impostazioni.x, Tasto_Impostazioni.y, 0,
            Tasto_Impostazioni.Dimensione / Tasto_Impostazioni.Icona:getWidth(),
            Tasto_Impostazioni.Dimensione / Tasto_Impostazioni.Icona:getHeight())
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
        love.graphics.rectangle("fill", Barra_Volume_Musica.x, Barra_Volume_Musica.y, Barra_Volume_Musica.Larghezza,
            Barra_Volume_Musica.Altezza)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", Barra_Volume_Musica.Punto_X, Barra_Volume_Musica.y - 5,
            Barra_Volume_Musica.Punto_Lato, Barra_Volume_Musica.Altezza + 10)

        love.graphics.setFont(love.graphics.newFont(20))
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Volume: " .. math.floor(Barra_Volume_Musica.Valore * 100) .. "%", Barra_Volume_Musica.x,
            Barra_Volume_Musica.y - 30)
    else
        love.graphics.setColor(1, 1, 1)
        love.graphics.setLineWidth(2)
        love.graphics.line(Tabella_Grafica.Offset_X + Tabella_Grafica.Dimensione_Cella, Tabella_Grafica.Offset_Y,
            Tabella_Grafica.Offset_X + Tabella_Grafica.Dimensione_Cella,
            Tabella_Grafica.Offset_Y + Tabella_Grafica.Dimensione)
        love.graphics.line(Tabella_Grafica.Offset_X + 2 * Tabella_Grafica.Dimensione_Cella, Tabella_Grafica.Offset_Y,
            Tabella_Grafica.Offset_X + 2 * Tabella_Grafica.Dimensione_Cella,
            Tabella_Grafica.Offset_Y + Tabella_Grafica.Dimensione)
        love.graphics.line(Tabella_Grafica.Offset_X, Tabella_Grafica.Offset_Y + Tabella_Grafica.Dimensione_Cella,
            Tabella_Grafica.Offset_X + Tabella_Grafica.Dimensione,
            Tabella_Grafica.Offset_Y + Tabella_Grafica.Dimensione_Cella)
        love.graphics.line(Tabella_Grafica.Offset_X, Tabella_Grafica.Offset_Y + 2 * Tabella_Grafica.Dimensione_Cella,
            Tabella_Grafica.Offset_X + Tabella_Grafica.Dimensione,
            Tabella_Grafica.Offset_Y + 2 * Tabella_Grafica.Dimensione_Cella)

        -- Draw player marks dynamically
        for i = 1, 3 do
            for j = 1, 3 do
                local cellX = Tabella_Grafica.Offset_X + (j - 1) * Tabella_Grafica.Dimensione_Cella
                local cellY = Tabella_Grafica.Offset_Y + (i - 1) * Tabella_Grafica.Dimensione_Cella
                if Tabella[i][j] ~= ' ' then
                    love.graphics.setFont(love.graphics.newFont(Tabella_Grafica.Dimensione_Cella * 0.5))
                    love.graphics.setColor(1, 0, 0)
                    love.graphics.printf(Tabella[i][j], cellX, cellY + Tabella_Grafica.Dimensione_Cella * 0.25,
                        Tabella_Grafica.Dimensione_Cella, "center")
                end
            end
        end
        if StadioGioco > 0 then
            love.graphics.setColor(1, 0, 0)
            love.graphics.setLineWidth(5)

            if StadioGioco >= 10 and StadioGioco < 20 then -- Row win
                local row = StadioGioco - 10
                love.graphics.line(Tabella_Grafica.Offset_X,
                    Tabella_Grafica.Offset_Y + row * Tabella_Grafica.Dimensione_Cella +
                    Tabella_Grafica.Dimensione_Cella / 2, Tabella_Grafica.Offset_X + Tabella_Grafica.Dimensione,
                    Tabella_Grafica.Offset_Y + row * Tabella_Grafica.Dimensione_Cella +
                    Tabella_Grafica.Dimensione_Cella / 2)
            elseif StadioGioco >= 20 and StadioGioco < 30 then -- Column win
                local col = StadioGioco - 20
                love.graphics.line(
                    Tabella_Grafica.Offset_X + col * Tabella_Grafica.Dimensione_Cella +
                    Tabella_Grafica.Dimensione_Cella / 2, Tabella_Grafica.Offset_Y,
                    Tabella_Grafica.Offset_X + col * Tabella_Grafica.Dimensione_Cella +
                    Tabella_Grafica.Dimensione_Cella / 2, Tabella_Grafica.Offset_Y + Tabella_Grafica.Dimensione)
            elseif StadioGioco == 31 then -- Diagonal win
                love.graphics.line(Tabella_Grafica.Offset_X, Tabella_Grafica.Offset_Y,
                    Tabella_Grafica.Offset_X + Tabella_Grafica.Dimensione,
                    Tabella_Grafica.Offset_Y + Tabella_Grafica.Dimensione)
            elseif StadioGioco == 32 then
                love.graphics.line(Tabella_Grafica.Offset_X + Tabella_Grafica.Dimensione, Tabella_Grafica.Offset_Y,
                    Tabella_Grafica.Offset_X, Tabella_Grafica.Offset_Y + Tabella_Grafica.Dimensione)
            end
        end
        if StadioGioco ~= 0 then
            love.graphics.draw(Tasto_Restart.Icona, Tasto_Restart.x, Tasto_Restart.y, 0,
                Tasto_Restart.Dimensione / Tasto_Restart.Icona:getWidth(),
                Tasto_Restart.Dimensione / Tasto_Restart.Icona:getHeight())
        end
    end
end

function love.resize(w, h)
    --Tasto del reset delle partite
    Tasto_Restart.Dimensione = math.min(w, h) * 0.08
    Tasto_Restart.x = w * 0.02
    Tasto_Restart.y = h * 0.02

    --Tasto delle impostazioni
    Tasto_Impostazioni.Dimensione = math.min(w, h) * 0.10
    Tasto_Impostazioni.x = w - Tasto_Impostazioni.Dimensione - w * 0.01
    Tasto_Impostazioni.y = h * 0.01

    --Tabella Grafica
    Tabella_Grafica.Dimensione = math.min(w, h) * 0.6
    Tabella_Grafica.Offset_X = (w - Tabella_Grafica.Dimensione) / 2
    Tabella_Grafica.Offset_Y = (h - Tabella_Grafica.Dimensione) / 2
    Tabella_Grafica.Dimensione_Cella = Tabella_Grafica.Dimensione / 3
end
