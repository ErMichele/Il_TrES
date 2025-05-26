local ffi = require("ffi")
ffi.cdef [[
    int Pareggio(char Tavola[3][3]);
    int Vittoria(char Tavola[3][3]);
    void Log(const char *Tipo, const char *Messaggio);
    int MossaCPU(char board[3][3]);
]]
local Backend = ffi.load("Back-end\\Back.dll")

local Tracce_Sfondo = {}
local Traccia_Sfondo_Corrente = 1
local Musica_Sfondo

local Effetti_Sonori = { -- Effetti sonori
    Selezione = love.audio.newSource("Resources/SoundEffects/Select.mp3", "stream"),
}

local Fonts = { -- Font utilizzati nel gioco
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

local Lingue = {"Italiano", "English"}
local IndiceLinguaCorrente = 1
local Localization = require("Resources/Lingue")

-- Funzione per ottenere il testo localizzato
--- @param chiave string La chiave del testo nella tabella di localizzazione.
--- @param ... any Argomenti aggiuntivi per string.format
--- @return string Testo Il testo localizzato.
local function GetLocalizedText(chiave, ...)
    local linguaCorrente = Lingue[IndiceLinguaCorrente]
    local testo = Localization[linguaCorrente][chiave]
    if testo then
        return string.format(testo, ...)
    else
        return string.format(Localization[linguaCorrente]["MissingLocalizationKey"], chiave)
    end
end

local Menu = { "SinglePlayer", "MultiPlayer", "Crediti", "Exit" }
local SchedaSelezionata = "Menu"
local SceltaMenu = 1

local Tabella = {
    { ' ', ' ', ' ' },
    { ' ', ' ', ' ' },
    { ' ', ' ', ' ' }
}

local StatoGioco = 0 
local GiocatoreCorrente = 1 
local NumeroPartita = 1 

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

-- Proprietà della barra del volume degli effetti sonori (SFX).
local Barra_Volume_Effetti_Sonori = {
    x = love.graphics.getWidth() * 0.125,
    y = love.graphics.getHeight() * 0.45,
    Larghezza = love.graphics.getWidth() * 0.375,
    Altezza = math.max(4, love.graphics.getHeight() * 0.016666666666667),
    Punto_Lato = math.max(10, love.graphics.getHeight() * 0.025),
    Punto_X = nil, -- Impostato in love.load()
    Valore = nil,  -- Impostato in love.load()
    Usato = false
}

-- Proprietà per l'opzione della lingua.
local Opzione_Lingua = {
    x = love.graphics.getWidth() * 0.125,
    y = love.graphics.getHeight() * 0.5666666666666667, -- Sotto il volume SFX
    Larghezza = love.graphics.getWidth() * 0.375,
    Altezza = math.max(40, love.graphics.getHeight() * 0.05),
    Dimensione_Freccia = math.max(20, love.graphics.getHeight() * 0.03),
    Freccia_Sinistra_X = nil,
    Freccia_Destra_X = nil,
}

-- Proprietà del pulsante di riavvio.
local Pulsante_Riavvio = {
    Dimensione = math.min(love.graphics.getWidth(), love.graphics.getHeight()) * 0.08,
    x = love.graphics.getWidth() * 0.02,
    y = love.graphics.getHeight() * 0.02,
    Icona = love.graphics.newImage("Resources/Game_Buttons/Restart.png")
}

-- Proprietà del pulsante delle impostazioni.
local Pulsante_Impostazioni = {
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

--- Converte la tabella Lua in un array C per l'interazione FFI.
--- @param tavola table Tabella Lua che rappresenta la tavola di gioco.
--- @return table CArray che rappresenta la tavola di gioco.
local function Converti_Tabella_Lua_C(tavola)
    local CArray = ffi.new("char[3][3]")
    for i = 1, 3 do
        for j = 1, 3 do
            CArray[i - 1][j - 1] = tavola[i][j]:byte()
        end
    end
    return CArray
end

--- Resetta il gioco allo stato iniziale.
local function Resetta_Gioco()
    Tabella = {
        { ' ', ' ', ' ' },
        { ' ', ' ', ' ' },
        { ' ', ' ', ' ' }
    }
    StatoGioco = 0
    GiocatoreCorrente = 1
end

--- Registra un messaggio nella console e nel backend (se disponibile).
--- @param tipo string Il tipo di messaggio (es., "INFO", "DEBUG", "ERRORE").
--- @param messaggio string Il messaggio da registrare.
local function Debug(tipo, messaggio)
    print("[" .. tipo .. "] " .. messaggio)
    if Backend then
        Backend.Log(tipo, messaggio)
    end
end

--- Esegue una mossa nella cella cliccata e controlla la vittoria/pareggio.
--- @param riga number La riga della cella.
--- @param colonna number La colonna della cella.
--- @param simbolo string 'X' o 'O'.
local function Esegui_Mossa(riga, colonna, simbolo)
    Tabella[riga][colonna] = simbolo
    local risultato = Backend.Vittoria(Converti_Tabella_Lua_C(Tabella))
    if risultato ~= 0 then
        StatoGioco = risultato
        Debug("INFO", GetLocalizedText("Log_VittoriaGiocatore", simbolo, StatoGioco))
        return true
    end

    risultato = Backend.Pareggio(Converti_Tabella_Lua_C(Tabella))
    if risultato == -1 then
        StatoGioco = risultato
        Debug("INFO", GetLocalizedText("Log_Pareggio"))
        return true
    end

    return false
end

--- Chiamato quando il gioco viene caricato. Inizializza le impostazioni del gioco.
function love.load()
    love.filesystem.setIdentity("Il_TrES")
    love.window.setTitle(GetLocalizedText("Titolo"))
    love.window.setIcon(love.image.newImageData("Resources/Icon/Tris_icon.png"))

    -- Carica le tracce musicali di sottofondo.
    for _, file in ipairs(love.filesystem.getDirectoryItems("Resources/Music")) do
        if file:match("%.ogg$") or file:match("%.mp3$") then
            table.insert(Tracce_Sfondo, "Resources/Music/" .. file)
        end
    end
    if #Tracce_Sfondo == 0 then
        Debug("ERRORE", GetLocalizedText("NoMusicFound"))
    end

    -- Carica il volume della musica salvato o imposta il valore predefinito.
    if love.filesystem.getInfo("Barra_Volume_Musica.txt") then
        local Valore_Salvato = love.filesystem.read("Barra_Volume_Musica.txt")
        Barra_Volume_Musica.Valore = Valore_Salvato and tonumber(Valore_Salvato) or 0.5
        Debug("DEBUG", GetLocalizedText("Log_SalvataggioMusicaTrovato", math.floor(Barra_Volume_Musica.Valore * 100)))
    else
        Barra_Volume_Musica.Valore = 0.5
        Debug("DEBUG", GetLocalizedText("NoMusicSaveFound", 0.5))
    end
    Barra_Volume_Musica.Punto_X = Barra_Volume_Musica.x + (Barra_Volume_Musica.Larghezza - Barra_Volume_Musica.Punto_Lato) * Barra_Volume_Musica.Valore

    -- Carica il volume degli effetti sonori (SFX) salvato o imposta il valore predefinito.
    if love.filesystem.getInfo("Barra_Volume_SFX.txt") then
        local Valore_Salvato_SFX = love.filesystem.read("Barra_Volume_SFX.txt")
        Barra_Volume_Effetti_Sonori.Valore = Valore_Salvato_SFX and tonumber(Valore_Salvato_SFX) or 0.5
        Debug("DEBUG", GetLocalizedText("Log_SalvataggioSFXTrovato", math.floor(Barra_Volume_Effetti_Sonori.Valore * 100)))
    else
        Barra_Volume_Effetti_Sonori.Valore = 0.5
        Debug("DEBUG", GetLocalizedText("Log_SalvataggioSFXNonTrovato", 0.5))
    end
    Barra_Volume_Effetti_Sonori.Punto_X = Barra_Volume_Effetti_Sonori.x + (Barra_Volume_Effetti_Sonori.Larghezza - Barra_Volume_Effetti_Sonori.Punto_Lato) * Barra_Volume_Effetti_Sonori.Valore

    Effetti_Sonori.Selezione:setLooping(false)
    Effetti_Sonori.Selezione:setVolume(Barra_Volume_Effetti_Sonori.Valore)

    -- Carica la lingua salvata o imposta il valore predefinito.
    if love.filesystem.getInfo("Lingua_Corrente.txt") then
        local IndiceLinguaSalvata = love.filesystem.read("Lingua_Corrente.txt")
        IndiceLinguaCorrente = IndiceLinguaSalvata and tonumber(IndiceLinguaSalvata) or 1
        Debug("DEBUG", "File di salvataggio lingua trovato, lingua impostata a: " .. Lingue[IndiceLinguaCorrente])
    else
        IndiceLinguaCorrente = 1
        Debug("DEBUG", "Nessun file di salvataggio lingua trovato, lingua predefinita: Italiano")
    end

    love.window.setTitle(GetLocalizedText("Titolo"))

    Debug("START", GetLocalizedText("Log_GiocoAvviato"))
end

--- Chiamato quando si esce dal gioco.
function love.quit()
    Debug("CLOSE", GetLocalizedText("Log_GiocoChiusa"))
end

--- Chiamato ogni frame. Aggiorna la logica del gioco.
--- @param dt number Delta time dall'ultimo frame.
function love.update(dt)
    if Barra_Volume_Musica.Usato then
        local mouseX = love.mouse.getX()
        Barra_Volume_Musica.Punto_X = math.max(Barra_Volume_Musica.x, math.min(mouseX, Barra_Volume_Musica.x + Barra_Volume_Musica.Larghezza - Barra_Volume_Musica.Punto_Lato))
        Barra_Volume_Musica.Valore = (Barra_Volume_Musica.Punto_X - Barra_Volume_Musica.x) / (Barra_Volume_Musica.Larghezza - Barra_Volume_Musica.Punto_Lato)
        love.filesystem.write("Barra_Volume_Musica.txt", tostring(Barra_Volume_Musica.Valore))
        if Musica_Sfondo then
            Musica_Sfondo:setVolume(Barra_Volume_Musica.Valore)
            Debug("DEBUG", GetLocalizedText("MusicVolumeSet", math.floor(Barra_Volume_Musica.Valore * 100)))
        end
    end

    if Barra_Volume_Effetti_Sonori.Usato then
        local mouseX = love.mouse.getX()
        Barra_Volume_Effetti_Sonori.Punto_X = math.max(Barra_Volume_Effetti_Sonori.x, math.min(mouseX, Barra_Volume_Effetti_Sonori.x + Barra_Volume_Effetti_Sonori.Larghezza - Barra_Volume_Effetti_Sonori.Punto_Lato))
        Barra_Volume_Effetti_Sonori.Valore = (Barra_Volume_Effetti_Sonori.Punto_X - Barra_Volume_Effetti_Sonori.x) / (Barra_Volume_Effetti_Sonori.Larghezza - Barra_Volume_Effetti_Sonori.Punto_Lato)
        love.filesystem.write("Barra_Volume_SFX.txt", tostring(Barra_Volume_Effetti_Sonori.Valore))
        Effetti_Sonori.Selezione:setVolume(Barra_Volume_Effetti_Sonori.Valore)
        Debug("DEBUG", GetLocalizedText("Log_ModificaVolumeSFX", math.floor(Barra_Volume_Effetti_Sonori.Valore * 100)))
    end

    -- Gestione della musica di sottofondo.
    if not (Musica_Sfondo and Musica_Sfondo:isPlaying()) then
        local success, nuovaMusica = pcall(love.audio.newSource, Tracce_Sfondo[Traccia_Sfondo_Corrente], "stream")
        if success then
            Musica_Sfondo = nuovaMusica
            Musica_Sfondo:setLooping(false)
            Musica_Sfondo:play()
            Musica_Sfondo:setVolume(Barra_Volume_Musica.Valore)
            Debug("DEBUG", "Avviato l'esecuzione di " .. Tracce_Sfondo[Traccia_Sfondo_Corrente] .. "!")
        else
            if Tracce_Sfondo[Traccia_Sfondo_Corrente] ~= nil then
                Debug("ERRORE", GetLocalizedText("Log_ErroreMusicaCaricamento", Tracce_Sfondo[Traccia_Sfondo_Corrente]))
            end
        end
        Traccia_Sfondo_Corrente = (Traccia_Sfondo_Corrente % #Tracce_Sfondo) + 1
    end
end

--- Chiamato quando viene premuto un tasto. Gestisce l'input da tastiera.
--- @param tasto string Il tasto premuto.
function love.keypressed(tasto)
    if SchedaSelezionata == "Menu" then
        if tasto == "down" then
            SceltaMenu = SceltaMenu + 1
            if SceltaMenu > #Menu then
                SceltaMenu = 1
            end
        elseif tasto == "up" then
            SceltaMenu = SceltaMenu - 1
            if SceltaMenu < 1 then
                SceltaMenu = #Menu
            end
        elseif tasto == "return" then
            local Messaggio
            if Menu[SceltaMenu] == "SinglePlayer" then
                Messaggio = GetLocalizedText("Log_StartSingleplayer")
                love.window.setTitle(GetLocalizedText("Titolo") .. " - " .. GetLocalizedText("SinglePlayer"))
            elseif Menu[SceltaMenu] == "MultiPlayer" then
                Messaggio = GetLocalizedText("Log_StartMultiPlayer")
                love.window.setTitle(GetLocalizedText("Titolo") .. " - " .. GetLocalizedText("MultiPlayer"))
            elseif Menu[SceltaMenu] == "Crediti" then
                Messaggio = GetLocalizedText("Log_MostraCrediti")
                love.window.setTitle(GetLocalizedText("Titolo") .. " - " .. GetLocalizedText("Credits"))
            elseif Menu[SceltaMenu] == "Exit" then
                love.event.quit()
            end
            Effetti_Sonori.Selezione:play()
            if Menu[SceltaMenu] ~= "Exit" then
                Debug("INFO", Messaggio)
                SchedaSelezionata = Menu[SceltaMenu]
            end
        end
    elseif SchedaSelezionata == "Impostazioni" then
        if tasto == "left" then
            IndiceLinguaCorrente = IndiceLinguaCorrente - 1
            if IndiceLinguaCorrente < 1 then
                IndiceLinguaCorrente = #Lingue
            end
            love.filesystem.write("Lingua_Corrente.txt", tostring(IndiceLinguaCorrente))
            Debug("DEBUG", "Lingua impostata a: " .. Lingue[IndiceLinguaCorrente] .. " e salvata su file.")
            love.window.setTitle(GetLocalizedText("Titolo") .. " - " .. GetLocalizedText("Impostazioni"))
        elseif tasto == "right" then
            IndiceLinguaCorrente = IndiceLinguaCorrente + 1
            if IndiceLinguaCorrente > #Lingue then
                IndiceLinguaCorrente = 1
            end
            love.filesystem.write("Lingua_Corrente.txt", tostring(IndiceLinguaCorrente))
            Debug("DEBUG", "Lingua impostata a: " .. Lingue[IndiceLinguaCorrente] .. " e salvata su file.")
            love.window.setTitle(GetLocalizedText("Titolo") .. " - " .. GetLocalizedText("Impostazioni"))
        end
    end

    if SchedaSelezionata ~= "Menu" and tasto == "escape" then
        SchedaSelezionata = "Menu"
        Resetta_Gioco()
        NumeroPartita = 1
        Debug("INFO", GetLocalizedText("Log_RitornoMenu"))
        love.window.setTitle(GetLocalizedText("Titolo"))
    end
end

--- Chiamato quando viene premuto un pulsante del mouse. Gestisce l'input del mouse.
--- @param x number La coordinata x del mouse.
--- @param y number La coordinata y del mouse.
--- @param pulsante number Il pulsante del mouse premuto.
function love.mousepressed(x, y, pulsante)
    if SchedaSelezionata == "Menu" then
        if x >= Pulsante_Impostazioni.x and x <= Pulsante_Impostazioni.x + Pulsante_Impostazioni.Dimensione and y >= Pulsante_Impostazioni.y and y <= Pulsante_Impostazioni.y + Pulsante_Impostazioni.Dimensione then
            Debug("INFO", GetLocalizedText("Log_MostraImpostanzioni"))
            love.window.setTitle(GetLocalizedText("Titolo") .. " - " .. GetLocalizedText("Impostazioni"))
            SchedaSelezionata = "Impostazioni"
        end
    elseif pulsante == 1 and (SchedaSelezionata == "SinglePlayer" or SchedaSelezionata == "MultiPlayer") and
        StatoGioco == 0 then
        local mossaEseguita = false
        for Riga = 1, 3 do
            for Colonna = 1, 3 do
                local cellaX = Tabella_Grafica.Offset_X + (Colonna - 1) * Tabella_Grafica.Dimensione_Cella
                local cellaY = Tabella_Grafica.Offset_Y + (Riga - 1) * Tabella_Grafica.Dimensione_Cella

                if x >= cellaX and x <= cellaX + Tabella_Grafica.Dimensione_Cella and y >= cellaY and
                    y <= cellaY + Tabella_Grafica.Dimensione_Cella then
                    if Tabella[Riga][Colonna] == ' ' then
                        local simbolo = (SchedaSelezionata == "SinglePlayer" or GiocatoreCorrente == 1) and 'X' or 'O'
                        Debug("DEBUG", GetLocalizedText("Log_CasellaSceltaGiocatore", Riga, Colonna, simbolo))
                        mossaEseguita = true
                        if Esegui_Mossa(Riga, Colonna, simbolo) then
                            return
                        end
                        if SchedaSelezionata == "MultiPlayer" then
                            GiocatoreCorrente = (GiocatoreCorrente == 1) and 2 or 1
                        end
                    end
                end
            end
        end

        -- Mossa della CPU (solo per SinglePlayer)
        if mossaEseguita and SchedaSelezionata == "SinglePlayer" and StatoGioco == 0 then
            local Casella = Backend.MossaCPU(Converti_Tabella_Lua_C(Tabella))
            local Riga = math.floor(Casella / 3) + 1
            local Colonna = (Casella % 3) + 1
            if Tabella[Riga][Colonna] == ' ' then
                Tabella[Riga][Colonna] = 'O'
                Debug("DEBUG", GetLocalizedText("Log_MossaCPU", Riga, Colonna))
                Esegui_Mossa(Riga, Colonna, 'O')
            else
                Debug("ERRORE", GetLocalizedText("Log_CasellaOccupataCPU", Riga, Colonna))
            end
        end
    elseif pulsante == 1 and StatoGioco ~= 0 then
        if x >= Pulsante_Riavvio.x and x <= Pulsante_Riavvio.x + Pulsante_Riavvio.Dimensione and
            y >= Pulsante_Riavvio.y and y <= Pulsante_Riavvio.y + Pulsante_Riavvio.Dimensione then
            Resetta_Gioco()
            NumeroPartita = NumeroPartita + 1
            Debug("INFO", GetLocalizedText("Log_ResetGioco"))
        end
    elseif pulsante == 1 and SchedaSelezionata == "Impostazioni" then
        -- Controllo click sulla barra del volume musica
        if x >= Barra_Volume_Musica.Punto_X and x <= Barra_Volume_Musica.Punto_X + Barra_Volume_Musica.Punto_Lato and
            y >= Barra_Volume_Musica.y - 5 and y <= Barra_Volume_Musica.y + Barra_Volume_Musica.Altezza + 5 then
            Barra_Volume_Musica.Usato = true
        end
        -- Controllo click sulla barra del volume SFX
        if x >= Barra_Volume_Effetti_Sonori.Punto_X and x <= Barra_Volume_Effetti_Sonori.Punto_X + Barra_Volume_Effetti_Sonori.Punto_Lato and
            y >= Barra_Volume_Effetti_Sonori.y - 5 and y <= Barra_Volume_Effetti_Sonori.y + Barra_Volume_Effetti_Sonori.Altezza + 5 then
            Barra_Volume_Effetti_Sonori.Usato = true
        end
        -- Controllo click sulle frecce della lingua
        if x >= Opzione_Lingua.Freccia_Sinistra_X and x <= Opzione_Lingua.Freccia_Sinistra_X + Opzione_Lingua.Dimensione_Freccia and y >= Opzione_Lingua.y + (Opzione_Lingua.Altezza / 2) - (Opzione_Lingua.Dimensione_Freccia / 2) and y <= Opzione_Lingua.y + (Opzione_Lingua.Altezza / 2) + (Opzione_Lingua.Dimensione_Freccia / 2) then
            IndiceLinguaCorrente = IndiceLinguaCorrente - 1
            if IndiceLinguaCorrente < 1 then
                IndiceLinguaCorrente = #Lingue
            end
            love.filesystem.write("Lingua_Corrente.txt", tostring(IndiceLinguaCorrente))
            Debug("DEBUG", "Lingua impostata a: " .. Lingue[IndiceLinguaCorrente] .. " e salvata su file.")
            love.window.setTitle(GetLocalizedText("Titolo") .. " - " .. GetLocalizedText("Impostazioni"))
        elseif x >= Opzione_Lingua.Freccia_Destra_X and x <= Opzione_Lingua.Freccia_Destra_X + Opzione_Lingua.Dimensione_Freccia and y >= Opzione_Lingua.y + (Opzione_Lingua.Altezza / 2) - (Opzione_Lingua.Dimensione_Freccia / 2) and y <= Opzione_Lingua.y + (Opzione_Lingua.Altezza / 2) + (Opzione_Lingua.Dimensione_Freccia / 2) then
            IndiceLinguaCorrente = IndiceLinguaCorrente + 1
            if IndiceLinguaCorrente > #Lingue then
                IndiceLinguaCorrente = 1
            end
            love.filesystem.write("Lingua_Corrente.txt", tostring(IndiceLinguaCorrente))
            Debug("DEBUG", "Lingua impostata a: " .. Lingue[IndiceLinguaCorrente] .. " e salvata su file.")
            love.window.setTitle(GetLocalizedText("Titolo") .. " - " .. GetLocalizedText("Impostazioni"))
        end
    end
end

--- Chiamato quando viene rilasciato un pulsante del mouse.
function love.mousereleased(x, y, pulsante)
    if pulsante == 1 then
        if Barra_Volume_Musica.Usato then
            Barra_Volume_Musica.Usato = false
        end
        if Barra_Volume_Effetti_Sonori.Usato then
            Barra_Volume_Effetti_Sonori.Usato = false
        end
    end
end

--- Chiamato ogni frame. Disegna gli elementi del gioco.
function love.draw()
    love.graphics.clear(0.68, 0.85, 0.9) -- Colore di sfondo azzurro chiaro

    if SchedaSelezionata == "Menu" then
        love.graphics.setFont(Fonts.Titolo.Carattere)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(GetLocalizedText("Titolo"), 0, love.graphics.getHeight() * 0.1, love.graphics.getWidth(), "center")

        local inizioMenuY = love.graphics.getHeight() * 0.3
        local spaziaturaMenu = love.graphics.getHeight() * 0.08

        for i, Scelta in ipairs(Menu) do
            love.graphics.setFont(Fonts.Menu.Carattere)
            love.graphics.setColor(i == SceltaMenu and Fonts.Menu.Colore_Scelta[1] or Fonts.Menu.Colore_Normale[1], i == SceltaMenu and Fonts.Menu.Colore_Scelta[2] or Fonts.Menu.Colore_Normale[2], i == SceltaMenu and Fonts.Menu.Colore_Scelta[3] or Fonts.Menu.Colore_Normale[3])
            local menuY = inizioMenuY + (i - 1) * spaziaturaMenu
            love.graphics.printf(GetLocalizedText(Scelta), 0, menuY, love.graphics.getWidth(), "center")
        end

        love.graphics.setColor(1, 1, 1) -- Colore bianco per l'icona delle impostazioni
        love.graphics.draw(Pulsante_Impostazioni.Icona, Pulsante_Impostazioni.x, Pulsante_Impostazioni.y, 0,
            Pulsante_Impostazioni.Dimensione / Pulsante_Impostazioni.Icona:getWidth(),
            Pulsante_Impostazioni.Dimensione / Pulsante_Impostazioni.Icona:getHeight())

    elseif SchedaSelezionata == "Crediti" then
        love.graphics.setFont(Fonts.Crediti.Carattere)
        love.graphics.setColor(1, 1, 1) -- Colore bianco per il testo dei crediti

        local TestoCrediti = {
            GetLocalizedText("Crediti_Titolo"),
            "",
            GetLocalizedText("Crediti_Propretario"),
            "",
            GetLocalizedText("Crediti_Libreria_Grafica"),
            GetLocalizedText("Crediti_Linguaggi"),
            "",
            GetLocalizedText("Crediti_Programmatore"),
            GetLocalizedText("Crediti_Musica"),
            "",
            GetLocalizedText("Crediti_Ringraziamenti"),
            "",
            GetLocalizedText("Crediti_Uscita")
        }

        for i, line in ipairs(TestoCrediti) do
            love.graphics.printf(line, 0, 100 + i * 30, love.graphics.getWidth(), "center")
        end

    elseif SchedaSelezionata == "Impostazioni" then
        love.graphics.setFont(Fonts.Titolo.Carattere)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(GetLocalizedText("Impostazioni_Titolo"), 0, love.graphics.getHeight() * 0.08, love.graphics.getWidth(), "center")

        -- Sfondo rettangolare per il Volume Musica
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8) -- Sfondo più scuro e semi-trasparente
        love.graphics.rectangle("fill", Barra_Volume_Musica.x - 20, Barra_Volume_Musica.y - 60, Barra_Volume_Musica.Larghezza + 40, Barra_Volume_Musica.Altezza + 100, 10, 10) -- Angoli arrotondati

        -- Barra Volume Musica
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", Barra_Volume_Musica.x, Barra_Volume_Musica.y, Barra_Volume_Musica.Larghezza, Barra_Volume_Musica.Altezza)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", Barra_Volume_Musica.Punto_X, Barra_Volume_Musica.y - 5, Barra_Volume_Musica.Punto_Lato, Barra_Volume_Musica.Altezza + 10)

        love.graphics.setFont(Fonts.Testo.Carattere)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(GetLocalizedText("Volume_Musica") .. ": " .. math.floor(Barra_Volume_Musica.Valore * 100) .. "%", Barra_Volume_Musica.x, Barra_Volume_Musica.y - 30)

        -- Sfondo rettangolare per il Volume SFX
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", Barra_Volume_Effetti_Sonori.x - 20, Barra_Volume_Effetti_Sonori.y - 60, Barra_Volume_Effetti_Sonori.Larghezza + 40, Barra_Volume_Effetti_Sonori.Altezza + 100, 10, 10)

        -- Barra Volume SFX
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", Barra_Volume_Effetti_Sonori.x, Barra_Volume_Effetti_Sonori.y, Barra_Volume_Effetti_Sonori.Larghezza, Barra_Volume_Effetti_Sonori.Altezza)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", Barra_Volume_Effetti_Sonori.Punto_X, Barra_Volume_Effetti_Sonori.y - 5, Barra_Volume_Effetti_Sonori.Punto_Lato, Barra_Volume_Effetti_Sonori.Altezza + 10)

        love.graphics.setFont(Fonts.Testo.Carattere)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(GetLocalizedText("Volume_Effetti_Sonori") .. ": " .. math.floor(Barra_Volume_Effetti_Sonori.Valore * 100) .. "%", Barra_Volume_Effetti_Sonori.x, Barra_Volume_Effetti_Sonori.y - 30)

        -- Sfondo rettangolare per l'Opzione Lingua
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", Opzione_Lingua.x - 20, Opzione_Lingua.y - 60, Opzione_Lingua.Larghezza + 40, Opzione_Lingua.Altezza + 100, 10, 10)

        -- Opzione Lingua
        love.graphics.setFont(Fonts.Testo.Carattere)
        love.graphics.setColor(1, 1, 1)
        -- Calcola la posizione per centrare il testo della lingua
        local testoLingua = GetLocalizedText("Linguaggio") .. ": " .. Lingue[IndiceLinguaCorrente]
        local larghezzaTestoLingua = Fonts.Testo.Carattere:getWidth(testoLingua)
        local testoLinguaX = Opzione_Lingua.x + (Opzione_Lingua.Larghezza - larghezzaTestoLingua) / 2
        love.graphics.print(testoLingua, testoLinguaX, Opzione_Lingua.y - 30)


        -- Frecce per cambiare lingua
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("<", Opzione_Lingua.Freccia_Sinistra_X, Opzione_Lingua.y + (Opzione_Lingua.Altezza / 2) - (Fonts.Testo.Carattere:getHeight() / 2))
        love.graphics.print(">", Opzione_Lingua.Freccia_Destra_X, Opzione_Lingua.y + (Opzione_Lingua.Altezza / 2) - (Fonts.Testo.Carattere:getHeight() / 2))

    else -- Schermata di gioco (SinglePlayer o MultiPlayer)
        love.graphics.setFont(Fonts.Titolo.Carattere)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(GetLocalizedText("Gioco") .. ": " .. NumeroPartita, 0, love.graphics.getHeight() * 0.09, love.graphics.getWidth(), "center")

        if SchedaSelezionata == "MultiPlayer" then
            love.graphics.setFont(Fonts.Giocatore.Carattere)
            love.graphics.printf(GetLocalizedText("Player") .. ": " .. GiocatoreCorrente, 0, love.graphics.getHeight() * 0.8, love.graphics.getWidth(), "center")
        end

        -- Griglia di gioco
        love.graphics.setLineWidth(2)
        for i = 1, 2 do
            -- Linee verticali
            love.graphics.line(Tabella_Grafica.Offset_X + i * Tabella_Grafica.Dimensione_Cella, Tabella_Grafica.Offset_Y, Tabella_Grafica.Offset_X + i * Tabella_Grafica.Dimensione_Cella, Tabella_Grafica.Offset_Y + Tabella_Grafica.Dimensione)
            -- Linee orizzontali
            love.graphics.line(Tabella_Grafica.Offset_X, Tabella_Grafica.Offset_Y + i * Tabella_Grafica.Dimensione_Cella, Tabella_Grafica.Offset_X + Tabella_Grafica.Dimensione, Tabella_Grafica.Offset_Y + i * Tabella_Grafica.Dimensione_Cella)
        end

        -- Simboli X e O grafici sulla tavola
        for Riga = 1, 3 do
            for Colonna = 1, 3 do
                local Valore = Tabella[Riga][Colonna]
                if Valore ~= ' ' then
                    local cellaX = Tabella_Grafica.Offset_X + (Colonna - 1) * Tabella_Grafica.Dimensione_Cella
                    local cellaY = Tabella_Grafica.Offset_Y + (Riga - 1) * Tabella_Grafica.Dimensione_Cella
                    local padding = Tabella_Grafica.Dimensione_Cella * 0.2
                    local dimensione = Tabella_Grafica.Dimensione_Cella - padding * 2

                    love.graphics.setLineWidth(4)
                    if Valore == 'X' then
                        love.graphics.setColor(1, 0, 0) -- Rosso per la 'X'
                        love.graphics.line(cellaX + padding, cellaY + padding, cellaX + padding + dimensione, cellaY + padding + dimensione)
                        love.graphics.line(cellaX + padding + dimensione, cellaY + padding, cellaX + padding, cellaY + padding + dimensione)
                    elseif Valore == 'O' then
                        love.graphics.setColor(0, 0, 1) -- Blu per la 'O'
                        love.graphics.circle("line", cellaX + Tabella_Grafica.Dimensione_Cella / 2, cellaY + Tabella_Grafica.Dimensione_Cella / 2, dimensione / 2)
                    end
                end
            end
        end

        -- Linea di vittoria
        if StatoGioco > 0 then
            love.graphics.setColor(1, 1, 1) -- Colore bianco per la linea di vittoria
            love.graphics.setLineWidth(5)

            if StatoGioco >= 10 and StatoGioco < 20 then -- Vittoria per riga
                local riga = StatoGioco - 10
                local y = Tabella_Grafica.Offset_Y + riga * Tabella_Grafica.Dimensione_Cella + Tabella_Grafica.Dimensione_Cella / 2
                love.graphics.line(Tabella_Grafica.Offset_X, y, Tabella_Grafica.Offset_X + Tabella_Grafica.Dimensione, y)
            elseif StatoGioco >= 20 and StatoGioco < 30 then -- Vittoria per colonna
                local col = StatoGioco - 20
                local x = Tabella_Grafica.Offset_X + col * Tabella_Grafica.Dimensione_Cella + Tabella_Grafica.Dimensione_Cella / 2
                love.graphics.line(x, Tabella_Grafica.Offset_Y, x, Tabella_Grafica.Offset_Y + Tabella_Grafica.Dimensione)
            elseif StatoGioco == 31 then -- Vittoria diagonale (da sinistra a destra)
                love.graphics.line(Tabella_Grafica.Offset_X, Tabella_Grafica.Offset_Y,
                    Tabella_Grafica.Offset_X + Tabella_Grafica.Dimensione,
                    Tabella_Grafica.Offset_Y + Tabella_Grafica.Dimensione)
            elseif StatoGioco == 32 then -- Vittoria diagonale (da destra a sinistra)
                love.graphics.line(Tabella_Grafica.Offset_X + Tabella_Grafica.Dimensione, Tabella_Grafica.Offset_Y,
                    Tabella_Grafica.Offset_X, Tabella_Grafica.Offset_Y + Tabella_Grafica.Dimensione)
            end
        end

        -- Pulsante Riavvio
        if StatoGioco ~= 0 then
            love.graphics.setColor(1, 1, 1) -- Colore bianco per l'icona di riavvio
            love.graphics.draw(Pulsante_Riavvio.Icona, Pulsante_Riavvio.x, Pulsante_Riavvio.y, 0,
                Pulsante_Riavvio.Dimensione / Pulsante_Riavvio.Icona:getWidth(),
                Pulsante_Riavvio.Dimensione / Pulsante_Riavvio.Icona:getHeight())
        end
    end
end

function love.resize(w, h)
    --Pulsante del reset delle partite
    Pulsante_Riavvio.Dimensione = math.min(w, h) * 0.08
    Pulsante_Riavvio.x = w * 0.02
    Pulsante_Riavvio.y = h * 0.02

    --Pulsante delle impostazioni
    Pulsante_Impostazioni.Dimensione = math.min(w, h) * 0.10
    Pulsante_Impostazioni.x = w - Pulsante_Impostazioni.Dimensione - w * 0.01
    Pulsante_Impostazioni.y = h * 0.01

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

    --Barra Volume SFX
    Barra_Volume_Effetti_Sonori.x = w * 0.125
    Barra_Volume_Effetti_Sonori.y = h * 0.45 -- Nuova posizione y per SFX
    Barra_Volume_Effetti_Sonori.Larghezza = w * 0.375
    Barra_Volume_Effetti_Sonori.Altezza = math.max(4, h * 0.016666666666667)
    Barra_Volume_Effetti_Sonori.Punto_Lato = math.max(10, h * 0.025)
    Barra_Volume_Effetti_Sonori.Punto_X = Barra_Volume_Effetti_Sonori.x + (Barra_Volume_Effetti_Sonori.Larghezza - Barra_Volume_Effetti_Sonori.Punto_Lato) * Barra_Volume_Effetti_Sonori.Valore

    --Opzione Lingua
    Opzione_Lingua.x = w * 0.125
    Opzione_Lingua.y = h * 0.5666666666666667
    Opzione_Lingua.Larghezza = w * 0.375
    Opzione_Lingua.Altezza = math.max(40, h * 0.05)
    Opzione_Lingua.Dimensione_Freccia = math.max(20, h * 0.03)

    -- Calcola la posizione delle frecce rispetto al testo della lingua
    local larghezzaTestoLingua = Fonts.Testo.Carattere:getWidth(GetLocalizedText("Linguaggio") .. ": " .. Lingue[IndiceLinguaCorrente])
    local inizioTestoLinguaX = Opzione_Lingua.x + (Opzione_Lingua.Larghezza - larghezzaTestoLingua) / 2
    Opzione_Lingua.Freccia_Sinistra_X = inizioTestoLinguaX - Opzione_Lingua.Dimensione_Freccia - 10 -- 10 pixel di padding
    Opzione_Lingua.Freccia_Destra_X = inizioTestoLinguaX + larghezzaTestoLingua + 10 -- 10 pixel di padding

    --Fonts
    Fonts.Titolo.Carattere = love.graphics.newFont("Resources/Font/TimesNewRoman.ttf", h * 0.1)
    Fonts.Menu.Carattere = love.graphics.newFont("Resources/Font/DSGabriele.ttf", h * 0.05)
    Fonts.Crediti.Carattere = love.graphics.newFont("Resources/Font/TimesNewRoman.ttf", 28)
    Fonts.Giocatore.Carattere = love.graphics.newFont("Resources/Font/TimesNewRoman.ttf", h * 0.085)
    Fonts.Testo.Carattere = love.graphics.newFont(20)
end