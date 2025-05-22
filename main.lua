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

local Fonts = {
    Titolo = {
        Colore = {1, 1, 1}, 
        Carattere = love.graphics.newFont("Resources/Font/TimesNewRoman.ttf", love.graphics.getHeight() * 0.1)
    },
    Menu = {
        Colore_Normale = {0.42, 0.48, 0.54},
        Colore_Scelta = {0.57, 0.44, 0.86},
        Carattere = love.graphics.newFont("Resources/Font/DSGabriele.ttf", love.graphics.getHeight() * 0.05)
    }, 
    Crediti = {
        Colore = {1, 1, 1},
        Carattere = love.graphics.newFont("Resources/Font/TimesNewRoman.ttf", 28)
    },
    Giocatore = {
        Colore = {1, 1, 1},
        Carattere = love.graphics.newFont("Resources/Font/TimesNewRoman.ttf", love.graphics.getHeight() * 0.085)
    },
    Testo = {
        Colore = {1, 1, 1},
        Carattere = love.graphics.newFont(20),
    }
}

local Menu = { "SinglePlayer", "MultiPlayer", "Crediti", "Exit" }
local SchedaSelezionata = "Menu"
local MenuScelta = 1

-- Proprietà della barra del volume della musica.
local Barra_Volume_Musica = {
    x = love.graphics.getWidth() * 0.125,
    y = love.graphics.getHeight() * 0.3333333333333333333333333333333,
    Larghezza = love.graphics.getWidth() * 0.375,
    Altezza = math.max(4, love.graphics.getHeight() * 0.016666666666667),
    Punto_Lato = math.max(10, love.graphics.getHeight() * 0.025),
    Punto_X = nil, -- Impostato in love.load()
    Valore = nil,  -- Impostato in love.load()
    Usato = false
}

-- Proprietà della barra del volume della musica.
local Barra_Volume_SFX = {
    x = love.graphics.getWidth() * 0.125,
    y = love.graphics.getHeight() * 0.3333333333333333333333333333333,
    Larghezza = love.graphics.getWidth() * 0.375,
    Altezza = math.max(4, love.graphics.getHeight() * 0.016666666666667),
    Punto_Lato = math.max(10, love.graphics.getHeight() * 0.025),
    Punto_X = nil, -- Impostato in love.load()
    Valore = nil,  -- Impostato in love.load()
    Usato = false
}

-- Proprietà del pulsante di riavvio.
local Tasto_Restart = {
    Dimensione = math.min(love.graphics.getWidth(), love.graphics.getHeight()) * 0.08,
    x = love.graphics.getWidth() * 0.02,
    y = love.graphics.getHeight() * 0.02,
    Icona = love.graphics.newImage("Resources/Game_Buttons/Restart.png")
}

-- Proprietà del pulsante delle impostazioni.
local Tasto_Impostazioni = {
    Dimensione = math.min(love.graphics.getWidth(), love.graphics.getHeight()) * 0.10,
    x = love.graphics.getWidth() - math.min(love.graphics.getWidth(), love.graphics.getHeight()) * 0.10 -
    love.graphics.getWidth() * 0.01,
    y = love.graphics.getHeight() * 0.01,
    Icona = love.graphics.newImage("Resources/Game_Buttons/Config.png")
}

-- Proprietà per il disegno della tavola di gioco.
local Tabella_Grafica = {
    Dimensione = math.min(love.graphics.getWidth(), love.graphics.getHeight()) * 0.6,
    Offset_X = (love.graphics.getWidth() - math.min(love.graphics.getWidth(), love.graphics.getHeight()) * 0.6) / 2,
    Offset_Y = (love.graphics.getHeight() - math.min(love.graphics.getWidth(), love.graphics.getHeight()) * 0.6) / 2,
    Dimensione_Cella = math.min(love.graphics.getWidth(), love.graphics.getHeight()) * 0.6 / 3
}

local StadioGioco = 0
local Giocatore = 1
local Partita = 1

--- Converte la tabella Lua in un array C per l'interazione FFI.
--- @param tavola table Tabella Lua che rappresenta la tavola di gioco.
--- @return table CArray che rappresenta la tavola di gioco.
local function Tabella_Lua_C(tavola)
    local CArray = ffi.new("char[3][3]")
    for i = 1, 3 do
        for j = 1, 3 do
            CArray[i - 1][j - 1] = tavola[i][j]:byte()
        end
    end
    return CArray
end

--- Resetta il gioco allo stato iniziale.
local function ResetGame()
    Tabella = {
        { ' ', ' ', ' ' },
        { ' ', ' ', ' ' },
        { ' ', ' ', ' ' }
    }
    StadioGioco = 0
    Giocatore = 1
end

--- Registra un messaggio nella console e nel backend (se disponibile).
--- @param tipo string Il tipo di messaggio (es., "INFO", "DEBUG", "ERROR").
--- @param msg string Il messaggio da registrare.
local function Debbuging(tipo, msg)
    print("[" .. tipo .. "] " .. msg)
    if Backend then
        Backend.Log(tipo, msg)
    end
end

--- Esegue una mossa nella cella cliccata e controlla la vittoria/pareggio.
--- @param riga number La riga della cella.
--- @param colonna number La colonna della cella.
--- @param simbolo string 'X' o 'O'.
local function EseguiMossa(riga, colonna, simbolo)
    Tabella[riga][colonna] = simbolo
    local risultato = Backend.Vittoria(Tabella_Lua_C(Tabella))
    if risultato ~= 0 then
        StadioGioco = risultato
        Debbuging("INFO", "Il giocatore '" .. simbolo .. "' ha vinto con risultato = " .. StadioGioco .. "!")
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

--- Chiamato quando il gioco viene caricato. Inizializza le impostazioni del gioco.
function love.load()
    love.filesystem.setIdentity("Il_TrES")

    love.window.setTitle("TrES")
    love.window.setIcon(love.image.newImageData("Resources/Icon/Tris_icon.png"))
    -- Caratteri
    love.graphics.setFont(love.graphics.newFont(20))

    -- Carica le tracce musicali di sottofondo.
    for _, file in ipairs(love.filesystem.getDirectoryItems("Resources/Music")) do
        if file:match("%.ogg$") or file:match("%.mp3$") then
            table.insert(Traccie_Background, "Resources/Music/" .. file)
        end
    end
    if #Traccie_Background == 0 then
        Debbuging("ERRORE", "Nessuna traccia musicale trovata!")
    end

    -- Carica il volume salvato o imposta il valore predefinito.
    if love.filesystem.getInfo("Barra_Volume_Musica.txt") then
        local Valore_Salvato = love.filesystem.read("Barra_Volume_Musica.txt")
        Barra_Volume_Musica.Valore = Valore_Salvato and tonumber(Valore_Salvato) or 0.5
        Debbuging("DEBUG", "File di salvataggio trovato, volume impostato a: " .. Barra_Volume_Musica.Valore * 100 .. "%")
    else
        Barra_Volume_Musica.Valore = 0.5
        Debbuging("DEBUG", "Nessun file di salvataggio trovato, volume predefinito: 0.5")
    end
    Barra_Volume_Musica.Punto_X = Barra_Volume_Musica.x + (Barra_Volume_Musica.Larghezza - Barra_Volume_Musica.Punto_Lato) * Barra_Volume_Musica.Valore

    -- Carica gli effetti sonori.
    Selezione = love.audio.newSource("Resources/SoundEffects/Select.mp3", "stream")
    Selezione:setLooping(false)
    Selezione:setVolume(0.09)

    Debbuging("START", "Gioco avviato con successo, buon divertimento!")
end

--- Chiamato quando si esce dal gioco.
function love.quit()
    Debbuging("CLOSE", "Il gioco e' stato chiuso.")
end

--- Chiamato ogni frame. Aggiorna la logica del gioco.
--- @param dt number Delta time dall'ultimo frame.
function love.update(dt)
    if Barra_Volume_Musica.Usato then
        local mouseX = love.mouse.getX()
        Barra_Volume_Musica.Punto_X = math.max(Barra_Volume_Musica.x,
            math.min(mouseX, Barra_Volume_Musica.x + Barra_Volume_Musica.Larghezza - Barra_Volume_Musica.Punto_Lato))
        Barra_Volume_Musica.Valore =
            (Barra_Volume_Musica.Punto_X - Barra_Volume_Musica.x) / (Barra_Volume_Musica.Larghezza - Barra_Volume_Musica.Punto_Lato)
        love.filesystem.write("Barra_Volume_Musica.txt", tostring(Barra_Volume_Musica.Valore))
        if Musica_Background then
          Musica_Background:setVolume(Barra_Volume_Musica.Valore)
        end
    end

    -- Gestione della musica di sottofondo.
    if not (Musica_Background and Musica_Background:isPlaying()) then
        local success, newMusic = pcall(love.audio.newSource, Traccie_Background[Traccia_Background_Corrente], "stream")
        if success then
            Musica_Background = newMusic
            Musica_Background:setLooping(false)
            Musica_Background:play()
            Musica_Background:setVolume(Barra_Volume_Musica.Valore)
            Debbuging("DEBUG", "Avviato l'esecuzione di " .. Traccie_Background[Traccia_Background_Corrente] .. "!")
        else
            if Traccie_Background[Traccia_Background_Corrente] ~= nil then
                Debbuging("ERRORE", Traccie_Background[Traccia_Background_Corrente] .. " non può essere caricato!")
            end
        end
        Traccia_Background_Corrente = (Traccia_Background_Corrente % #Traccie_Background) + 1
    end

    
end

--- Chiamato quando viene premuto un tasto. Gestisce l'input da tastiera.
--- @param key string Il tasto premuto.
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
        Partita = 1
        Debbuging("INFO", "Tornato al menu principale")
        love.window.setTitle("TrES")
    end
end

--- Chiamato quando viene premuto un pulsante del mouse. Gestisce l'input del mouse.
--- @param x number La coordinata x del mouse.
--- @param y number La coordinata y del mouse.
--- @param button number Il pulsante del mouse premuto.
function love.mousepressed(x, y, button)
    if SchedaSelezionata == "Menu" then
        if x >= Tasto_Impostazioni.x and x <= Tasto_Impostazioni.x + Tasto_Impostazioni.Dimensione and
            y >= Tasto_Impostazioni.y and y <= Tasto_Impostazioni.y + Tasto_Impostazioni.Dimensione then
            Debbuging("INFO", "Visualizzazione delle impostazioni!")
            love.window.setTitle("TrES - Impostazioni")
            SchedaSelezionata = "Impostazioni"
        end
    elseif button == 1 and (SchedaSelezionata == "SinglePlayer" or SchedaSelezionata == "MultiPlayer") and
        StadioGioco == 0 then
        local mossaEseguita = false
        for Riga = 1, 3 do
            for Colonna = 1, 3 do
                local cellX = Tabella_Grafica.Offset_X + (Colonna - 1) * Tabella_Grafica.Dimensione_Cella
                local cellY = Tabella_Grafica.Offset_Y + (Riga - 1) * Tabella_Grafica.Dimensione_Cella

                if x >= cellX and x <= cellX + Tabella_Grafica.Dimensione_Cella and y >= cellY and
                    y <= cellY + Tabella_Grafica.Dimensione_Cella then
                    if Tabella[Riga][Colonna] == ' ' then
                        local simbolo = (SchedaSelezionata == "SinglePlayer" or Giocatore == 1) and 'X' or 'O'
                        Debbuging("DEBUG", "Il giocatore ha cliccato la casella: " .. Riga .. ", " .. Colonna .. " con simbolo '" .. simbolo .. "'")
                        mossaEseguita = true
                        if EseguiMossa(Riga, Colonna, simbolo) then 
                            return 
                        end
                        if SchedaSelezionata == "MultiPlayer" then
                            Giocatore = (Giocatore == 1) and 2 or 1
                        end
                    end
                end
            end
        end

        -- Mossa della CPU (solo per SinglePlayer)
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
        if x >= Tasto_Restart.x and x <= Tasto_Restart.x + Tasto_Restart.Dimensione and
            y >= Tasto_Restart.y and y <= Tasto_Restart.y + Tasto_Restart.Dimensione then
            ResetGame()
            Partita = Partita + 1
            Debbuging("INFO", "Partita resettata!")
        end
    elseif button == 1 and SchedaSelezionata == "Impostazioni" then
        if x >= Barra_Volume_Musica.Punto_X and x <= Barra_Volume_Musica.Punto_X + Barra_Volume_Musica.Punto_Lato and
            y >= Barra_Volume_Musica.y - 5 and y <= Barra_Volume_Musica.y + Barra_Volume_Musica.Altezza + 5 then
            Barra_Volume_Musica.Usato = true
        end
    end
end

--- Chiamato quando viene rilasciato un pulsante del mouse.
function love.mousereleased(x, y, button)
    if button == 1 and Barra_Volume_Musica.Usato then
        Barra_Volume_Musica.Usato = false
    end
end

--- Chiamato ogni frame. Disegna gli elementi del gioco.
function love.draw()
    love.graphics.clear(0.68, 0.85, 0.9)

    if SchedaSelezionata == "Menu" then
        love.graphics.setFont(Fonts.Titolo.Carattere)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Il TrES", 0, love.graphics.getHeight() * 0.1, love.graphics.getWidth(), "center")

        local menuStartY = love.graphics.getHeight() * 0.3
        local menuSpacing = love.graphics.getHeight() * 0.08

        for i, Scelta in ipairs(Menu) do
            love.graphics.setFont(Fonts.Menu.Carattere)
            love.graphics.setColor(i == MenuScelta and Fonts.Menu.Colore_Scelta[1] or Fonts.Menu.Colore_Normale[1], i == MenuScelta and Fonts.Menu.Colore_Scelta[2] or Fonts.Menu.Colore_Normale[2], i == MenuScelta and Fonts.Menu.Colore_Scelta[3] or Fonts.Menu.Colore_Normale[3])
            local menuY = menuStartY + (i - 1) * menuSpacing
            love.graphics.printf(Scelta, 0, menuY, love.graphics.getWidth(), "center")
        end

        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(Tasto_Impostazioni.Icona, Tasto_Impostazioni.x, Tasto_Impostazioni.y, 0,
            Tasto_Impostazioni.Dimensione / Tasto_Impostazioni.Icona:getWidth(),
            Tasto_Impostazioni.Dimensione / Tasto_Impostazioni.Icona:getHeight())

    elseif SchedaSelezionata == "Crediti" then
        love.graphics.setFont(Fonts.Crediti.Carattere)
        love.graphics.setColor(1, 1, 1)

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
        love.graphics.setFont(Fonts.Titolo.Carattere)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Impostazioni", 0, love.graphics.getHeight() * 0.08, love.graphics.getWidth(), "center")

        -- Barra volume musica
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", Barra_Volume_Musica.x, Barra_Volume_Musica.y, Barra_Volume_Musica.Larghezza, Barra_Volume_Musica.Altezza)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", Barra_Volume_Musica.Punto_X, Barra_Volume_Musica.y - 5, Barra_Volume_Musica.Punto_Lato, Barra_Volume_Musica.Altezza + 10)

        love.graphics.setFont(Fonts.Testo.Carattere)
        love.graphics.print("Volume: " .. math.floor(Barra_Volume_Musica.Valore * 100) .. "%", Barra_Volume_Musica.x, Barra_Volume_Musica.y - 30)

        -- Barra volume sfx
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", Barra_Volume_SFX.x, Barra_Volume_SFX.y, Barra_Volume_SFX.Larghezza, Barra_Volume_SFX.Altezza)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", Barra_Volume_SFX.Punto_X, Barra_Volume_SFX.y - 5, Barra_Volume_SFX.Punto_Lato, Barra_Volume_SFX.Altezza + 10)

        love.graphics.setFont(Fonts.Testo.Carattere)
        love.graphics.print("Volume: " .. math.floor(Barra_Volume_SFX.Valore * 100) .. "%", Barra_Volume_SFX.x, Barra_Volume_SFX.y - 30)
 
    else
        love.graphics.setFont(Fonts.Titolo.Carattere)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Partita: " .. Partita, 0, love.graphics.getHeight() * 0.09, love.graphics.getWidth(), "center")

        if SchedaSelezionata == "MultiPlayer" then
            love.graphics.setFont(Fonts.Giocatore.Carattere)
            love.graphics.printf("Giocatore: " .. Giocatore, 0, love.graphics.getHeight() * 0.8, love.graphics.getWidth(), "center")
        end

        -- Griglia
        love.graphics.setLineWidth(2)
        for i = 1, 2 do
            -- Linee verticali
            love.graphics.line(Tabella_Grafica.Offset_X + i * Tabella_Grafica.Dimensione_Cella, Tabella_Grafica.Offset_Y, Tabella_Grafica.Offset_X + i * Tabella_Grafica.Dimensione_Cella, Tabella_Grafica.Offset_Y + Tabella_Grafica.Dimensione)
            -- Linee orizzontali
            love.graphics.line(Tabella_Grafica.Offset_X, Tabella_Grafica.Offset_Y + i * Tabella_Grafica.Dimensione_Cella, Tabella_Grafica.Offset_X + Tabella_Grafica.Dimensione, Tabella_Grafica.Offset_Y + i * Tabella_Grafica.Dimensione_Cella)
        end

        -- Simboli X e O grafici
        for Riga = 1, 3 do
            for Colonna = 1, 3 do
                local Valore = Tabella[Riga][Colonna]
                if Valore ~= ' ' then
                    local cellX = Tabella_Grafica.Offset_X + (Colonna - 1) * Tabella_Grafica.Dimensione_Cella
                    local cellY = Tabella_Grafica.Offset_Y + (Riga - 1) * Tabella_Grafica.Dimensione_Cella
                    local padding = Tabella_Grafica.Dimensione_Cella * 0.2
                    local size = Tabella_Grafica.Dimensione_Cella - padding * 2

                    love.graphics.setLineWidth(4)
                    if Valore == 'X' then
                        love.graphics.setColor(1, 0, 0)
                        love.graphics.line(cellX + padding, cellY + padding, cellX + padding + size, cellY + padding + size)
                        love.graphics.line(cellX + padding + size, cellY + padding, cellX + padding, cellY + padding + size)
                    elseif Valore == 'O' then
                        love.graphics.setColor(0, 0, 1)
                        love.graphics.circle("line", cellX + Tabella_Grafica.Dimensione_Cella / 2, cellY + Tabella_Grafica.Dimensione_Cella / 2, size / 2)
                    end
                end
            end
        end

        -- Linea di vittoria
        if StadioGioco > 0 then
            love.graphics.setColor(1, 1, 1)
            love.graphics.setLineWidth(5)

            if StadioGioco >= 10 and StadioGioco < 20 then
                local row = StadioGioco - 10
                local y = Tabella_Grafica.Offset_Y + row * Tabella_Grafica.Dimensione_Cella + Tabella_Grafica.Dimensione_Cella / 2
                love.graphics.line(Tabella_Grafica.Offset_X, y, Tabella_Grafica.Offset_X + Tabella_Grafica.Dimensione, y)
            elseif StadioGioco >= 20 and StadioGioco < 30 then
                local col = StadioGioco - 20
                local x = Tabella_Grafica.Offset_X + col * Tabella_Grafica.Dimensione_Cella + Tabella_Grafica.Dimensione_Cella / 2
                love.graphics.line(x, Tabella_Grafica.Offset_Y, x, Tabella_Grafica.Offset_Y + Tabella_Grafica.Dimensione)
            elseif StadioGioco == 31 then
                love.graphics.line(Tabella_Grafica.Offset_X, Tabella_Grafica.Offset_Y,
                    Tabella_Grafica.Offset_X + Tabella_Grafica.Dimensione,
                    Tabella_Grafica.Offset_Y + Tabella_Grafica.Dimensione)
            elseif StadioGioco == 32 then
                love.graphics.line(Tabella_Grafica.Offset_X + Tabella_Grafica.Dimensione, Tabella_Grafica.Offset_Y,
                    Tabella_Grafica.Offset_X, Tabella_Grafica.Offset_Y + Tabella_Grafica.Dimensione)
            end
        end

        -- Tasto Restart
        if StadioGioco ~= 0 then
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(Tasto_Restart.Icona, Tasto_Restart.x, Tasto_Restart.y, 0, Tasto_Restart.Dimensione / Tasto_Restart.Icona:getWidth(),Tasto_Restart.Dimensione / Tasto_Restart.Icona:getHeight())
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

    --Barra Volume Musica
    Barra_Volume_Musica.x = w * 0.125
    Barra_Volume_Musica.y = h * 0.3333333333333333333333333333333
    Barra_Volume_Musica.Larghezza = w * 0.375
    Barra_Volume_Musica.Altezza = math.max(4, h * 0.016666666666667)
    Barra_Volume_Musica.Punto_Lato = math.max(10, h * 0.025)
    Barra_Volume_Musica.Punto_X = Barra_Volume_Musica.x + (Barra_Volume_Musica.Larghezza - Barra_Volume_Musica.Punto_Lato) * Barra_Volume_Musica.Valore

    --Fonts
    Fonts.Titolo.Carattere = love.graphics.newFont("Resources/Font/TimesNewRoman.ttf", h * 0.1)
    Fonts.Menu.Carattere = love.graphics.newFont("Resources/Font/DSGabriele.ttf", h * 0.05)
    Fonts.Crediti.Carattere = love.graphics.newFont("Resources/Font/TimesNewRoman.ttf", 28)
    Fonts.Giocatore.Carattere = love.graphics.newFont("Resources/Font/TimesNewRoman.ttf", h * 0.085)
    Fonts.Testo.Carattere = love.graphics.newFont(20)
end