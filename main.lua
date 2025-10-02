---@diagnostic disable: undefined-field
-- =====================================================================================
-- Module Imports
-- =====================================================================================
local Backend = require("Modules/Backend") -- Funzioni di backend (Vittoria, Pareggio, MossaCPU)
local DebugModule = require("Modules/Debug")   -- Funzioni di debug (Debug)
local LingueModule = require("Modules/Lingue")  -- Funzioni di localizzazione (PrendiTesto, MettiLingua, IndiceLingua)

-- Alias for frequently used functions
local GetLocalizedText = LingueModule.PrendiTesto
local IndiceLinguaCorrente = LingueModule.IndiceLIngua
local MettiLingua = LingueModule.MettiLingua
local PrendiLingua = LingueModule.PrendiLingua
local Debug = DebugModule.Debug

-- =====================================================================================
-- Global Game State Variables
-- =====================================================================================
local Tracce_Sfondo = {}
local Traccia_Sfondo_Corrente = 1
local Musica_Sfondo

local LogCheck = true -- Controls whether debug messages are written to file

local Effetti_Sonori = { -- Sound effects
    Selezione = love.audio.newSource("Resources/SoundEffects/Select.mp3", "stream"),
}

local Fonts = { -- Fonts used in the game
    Titolo = {
        Colore = { 1, 1, 1 },
        Carattere = nil -- Initialized in love.load() and love.resize()
    },
    Menu = {
        Colore_Normale = { 0.42, 0.48, 0.54 },
        Colore_Scelta = { 0.57, 0.44, 0.86 },
        Carattere = nil -- Initialized in love.load() and love.resize()
    },
    Crediti = {
        Colore = { 1, 1, 1 },
        Carattere = nil -- Initialized in love.load() and love.resize()
    },
    Giocatore = {
        Colore = { 1, 1, 1 },
        Carattere = nil -- Initialized in love.load() and love.resize()
    },
    Testo = {
        Colore = { 1, 1, 1 },
        Carattere = nil, -- Initialized in love.load() and love.resize()
    }
}

local Menu = { "SinglePlayer", "MultiPlayer", "Crediti", "Exit" }
local SchedaSelezionata = "Menu" -- Current active screen: "Menu", "SinglePlayer", "MultiPlayer", "Crediti", "Impostazioni"
local SceltaMenu = 1 -- Currently selected item in the main menu

local Tabella = { -- Game board
    { ' ', ' ', ' ' },
    { ' ', ' ', ' ' },
    { ' ', ' ', ' ' }
}

local StatoGioco = 0 -- 0: game in progress, -1: draw, >0: win code
local GiocatoreCorrente = 1 -- 1 for Player 1 ('X'), 2 for Player 2 ('O') in Multiplayer
local NumeroPartita = 1

-- UI Element Properties (initialized with placeholder values, updated in love.load/resize)
local Barra_Volume_Musica = {
    x = 0, y = 0, Larghezza = 0, Altezza = 0, Punto_Lato = 0, Punto_X = 0, Valore = 0.5, Usato = false
}
local Barra_Volume_Effetti_Sonori = {
    x = 0, y = 0, Larghezza = 0, Altezza = 0, Punto_Lato = 0, Punto_X = 0, Valore = 0.5, Usato = false
}
local Opzione_Lingua = {
    x = 0, y = 0, Larghezza = 0, Altezza = 0, Dimensione_Freccia = 0, Freccia_Sinistra_X = 0, Freccia_Destra_X = 0
}
local Pulsante_Riavvio = {
    Dimensione = 0, x = 0, y = 0, Icona = nil
}
local Pulsante_Impostazioni = {
    Dimensione = 0, x = 0, y = 0, Icona = nil
}
local Tabella_Grafica = {
    Dimensione = 0, Offset_X = 0, Offset_Y = 0, Dimensione_Cella = 0
}

local Checkbox_Log = {
    x = 0, y = 0, Larghezza = 0, Altezza = 0, Selezionata = true, Testo = GetLocalizedText("Abilita_Log")
}

-- =====================================================================================
-- Utility Functions
-- =====================================================================================

--- Prints a message to the console and logs it to a file if LogCheck is true.
--- @param tipo string The type of message (e.g., "INFO", "DEBUG", "ERRORE").
--- @param messaggio string The message to log.
local function Stampa(tipo, messaggio)
    print("[" .. tipo .. "] " .. messaggio)
    if LogCheck then
        Debug(tipo, messaggio)
    end
end

--- Resets the game to its initial state.
local function Resetta_Gioco()
    Tabella = {
        { ' ', ' ', ' ' },
        { ' ', ' ', ' ' },
        { ' ', ' ', ' ' }
    }
    StatoGioco = 0
    GiocatoreCorrente = 1
    Stampa("INFO", GetLocalizedText("Log_ResetGioco"))
end

--- Executes a move on the clicked cell and checks for win/draw conditions.
--- @param riga number The row of the cell.
--- @param colonna number The column of the cell.
--- @param simbolo string 'X' or 'O'.
--- @return boolean True if the game ended (win or draw), false otherwise.
local function Esegui_Mossa(riga, colonna, simbolo)
    Tabella[riga][colonna] = simbolo
    local risultato_vittoria = Backend.Vittoria(Tabella)
    if risultato_vittoria ~= 0 then
        StatoGioco = risultato_vittoria
        Stampa("INFO", GetLocalizedText("Log_VittoriaGiocatore", simbolo, StatoGioco))
        return true
    end

    local risultato_pareggio = Backend.Pareggio(Tabella)
    if risultato_pareggio == -1 then
        StatoGioco = risultato_pareggio
        Stampa("INFO", GetLocalizedText("Log_Pareggio"))
        return true
    end

    return false
end

--- Updates the UI element properties based on current window dimensions.
--- This function is called in love.load and love.resize.
local function updateUIProperties(w, h)
    -- Buttons
    Pulsante_Riavvio.Dimensione = math.min(w, h) * 0.08
    Pulsante_Riavvio.x = w * 0.02
    Pulsante_Riavvio.y = h * 0.02

    Pulsante_Impostazioni.Dimensione = math.min(w, h) * 0.10
    Pulsante_Impostazioni.x = w - Pulsante_Impostazioni.Dimensione - w * 0.01
    Pulsante_Impostazioni.y = h * 0.01

    -- Game Board
    Tabella_Grafica.Dimensione = math.min(w, h) * 0.6
    Tabella_Grafica.Offset_X = (w - Tabella_Grafica.Dimensione) / 2
    Tabella_Grafica.Offset_Y = (h - Tabella_Grafica.Dimensione) / 2
    Tabella_Grafica.Dimensione_Cella = Tabella_Grafica.Dimensione / 3

    -- Music Volume Bar
    Barra_Volume_Musica.x = w * 0.125
    Barra_Volume_Musica.y = h * 0.3333333333333333333333333333333
    Barra_Volume_Musica.Larghezza = w * 0.375
    Barra_Volume_Musica.Altezza = math.max(4, h * 0.016666666666667)
    Barra_Volume_Musica.Punto_Lato = math.max(10, h * 0.025)
    Barra_Volume_Musica.Punto_X = Barra_Volume_Musica.x +
    (Barra_Volume_Musica.Larghezza - Barra_Volume_Musica.Punto_Lato) * Barra_Volume_Musica.Valore

    -- SFX Volume Bar
    Barra_Volume_Effetti_Sonori.x = w * 0.125
    Barra_Volume_Effetti_Sonori.y = h * 0.45
    Barra_Volume_Effetti_Sonori.Larghezza = w * 0.375
    Barra_Volume_Effetti_Sonori.Altezza = math.max(4, h * 0.016666666666667)
    Barra_Volume_Effetti_Sonori.Punto_Lato = math.max(10, h * 0.025)
    Barra_Volume_Effetti_Sonori.Punto_X = Barra_Volume_Effetti_Sonori.x +
    (Barra_Volume_Effetti_Sonori.Larghezza - Barra_Volume_Effetti_Sonori.Punto_Lato) * Barra_Volume_Effetti_Sonori.Valore

    -- Language Option
    Opzione_Lingua.x = w * 0.125
    Opzione_Lingua.y = h * 0.5666666666666667
    Opzione_Lingua.Larghezza = w * 0.375
    Opzione_Lingua.Altezza = math.max(40, h * 0.05)
    Opzione_Lingua.Dimensione_Freccia = math.max(20, h * 0.03)

    -- Fonts (re-create with new height)
    Fonts.Titolo.Carattere = love.graphics.newFont("Resources/Font/TimesNewRoman.ttf", h * 0.1)
    Fonts.Menu.Carattere = love.graphics.newFont("Resources/Font/DSGabriele.ttf", h * 0.05)
    Fonts.Crediti.Carattere = love.graphics.newFont("Resources/Font/TimesNewRoman.ttf", 28) -- Fixed size for credits
    Fonts.Giocatore.Carattere = love.graphics.newFont("Resources/Font/TimesNewRoman.ttf", h * 0.085)
    Fonts.Testo.Carattere = love.graphics.newFont(20) -- Fixed size for general text

    -- Update language option arrow positions after font resize
    local testoLingua = GetLocalizedText("Linguaggio") .. ": " .. PrendiLingua()
    local larghezzaTestoLingua = Fonts.Testo.Carattere:getWidth(testoLingua)
    Opzione_Lingua.Freccia_Sinistra_X = Opzione_Lingua.x +
    (Opzione_Lingua.Larghezza - larghezzaTestoLingua) / 2 - Opzione_Lingua.Dimensione_Freccia - 10
    Opzione_Lingua.Freccia_Destra_X = Opzione_Lingua.x +
    (Opzione_Lingua.Larghezza - larghezzaTestoLingua) / 2 + larghezzaTestoLingua + 10

    Checkbox_Log.x = w * 0.125
    Checkbox_Log.y = h * 0.7
    Checkbox_Log.Larghezza = math.max(20, h * 0.03)
    Checkbox_Log.Altezza = Checkbox_Log.Larghezza
    Checkbox_Log.Testo = GetLocalizedText("Abilita_Log")
end

-- =====================================================================================
-- LÖVE2D Callbacks
-- =====================================================================================

--- Called when the game is loaded. Initializes game settings and resources.
function love.load()
    love.filesystem.setIdentity("Il_TrES")
    love.window.setTitle(GetLocalizedText("Titolo"))
    love.window.setIcon(love.image.newImageData("Resources/Icon/TrES_icon(small).png", 32, 32))

    -- Load UI properties based on initial window size
    updateUIProperties(love.graphics.getWidth(), love.graphics.getHeight())

    -- Load saved language or set default.
    if love.filesystem.getInfo("Lingua_Corrente.txt") then
        local IndiceLinguaSalvata = love.filesystem.read("Lingua_Corrente.txt")
        MettiLingua(IndiceLinguaSalvata and tonumber(IndiceLinguaSalvata) or 1)
        Stampa("DEBUG", "File di salvataggio lingua trovato, lingua impostata a: " .. PrendiLingua())
    else
        MettiLingua(1) -- Default to Italian
        Stampa("DEBUG", "Nessun file di salvataggio lingua trovato, lingua predefinita: Italiano")
    end

    -- Load background music tracks.
    for _, file in ipairs(love.filesystem.getDirectoryItems("Resources/Music")) do
        if file:match("%.ogg$") or file:match("%.mp3$") then
            table.insert(Tracce_Sfondo, "Resources/Music/" .. file)
        end
    end
    if #Tracce_Sfondo == 0 then
        Stampa("ERRORE", GetLocalizedText("Log_NessunaMusicaTrovata"))
    end

    -- Load saved music volume or set default.
    if love.filesystem.getInfo("Barra_Volume_Musica.txt") then
        local Valore_Salvato = love.filesystem.read("Barra_Volume_Musica.txt")
        Barra_Volume_Musica.Valore = Valore_Salvato and tonumber(Valore_Salvato) or 0.5
        Stampa("DEBUG", GetLocalizedText("Log_SalvataggioMusicaTrovato", math.floor(Barra_Volume_Musica.Valore * 100)))
    else
        Barra_Volume_Musica.Valore = 0.5
        Stampa("DEBUG", GetLocalizedText("Log_SalvataggioMusicaNonTrovato", 0.5))
    end
    Barra_Volume_Musica.Punto_X = Barra_Volume_Musica.x +
    (Barra_Volume_Musica.Larghezza - Barra_Volume_Musica.Punto_Lato) * Barra_Volume_Musica.Valore

    -- Load saved SFX volume or set default.
    if love.filesystem.getInfo("Barra_Volume_SFX.txt") then
        local Valore_Salvato_SFX = love.filesystem.read("Barra_Volume_SFX.txt")
        Barra_Volume_Effetti_Sonori.Valore = Valore_Salvato_SFX and tonumber(Valore_Salvato_SFX) or 0.5
        Stampa("DEBUG",
            GetLocalizedText("Log_SalvataggioSFXTrovato", math.floor(Barra_Volume_Effetti_Sonori.Valore * 100)))
    else
        Barra_Volume_Effetti_Sonori.Valore = 0.5
        Stampa("DEBUG", GetLocalizedText("Log_SalvataggioSFXNonTrovato", 0.5))
    end
    Barra_Volume_Effetti_Sonori.Punto_X = Barra_Volume_Effetti_Sonori.x +
    (Barra_Volume_Effetti_Sonori.Larghezza - Barra_Volume_Effetti_Sonori.Punto_Lato) * Barra_Volume_Effetti_Sonori.Valore

    Effetti_Sonori.Selezione:setLooping(false)
    Effetti_Sonori.Selezione:setVolume(Barra_Volume_Effetti_Sonori.Valore)

    if love.filesystem.getInfo("LogCheck.txt") then
        local StatoSalvato = love.filesystem.read("LogCheck.txt")
        local valore = StatoSalvato and (StatoSalvato == "true") and true or false
        Checkbox_Log.Selezionata = valore
        LogCheck = valore
        Stampa("DEBUG", "File di salvataggio log trovato, log abilitati: " .. tostring(LogCheck))
    else
        Checkbox_Log.Selezionata = true -- Default: abilitato
        LogCheck = true
        Stampa("DEBUG", "Nessun file di salvataggio log trovato, log predefiniti: abilitati")
    end

    -- Aggiorna il testo della checkbox dopo la lingua
    Checkbox_Log.Testo = GetLocalizedText("Abilita_Log")

    -- Load button icons
    Pulsante_Riavvio.Icona = love.graphics.newImage("Resources/Game_Buttons/Restart.png")
    Pulsante_Impostazioni.Icona = love.graphics.newImage("Resources/Game_Buttons/Config.png")

    love.window.setTitle(GetLocalizedText("Titolo"))
    Stampa("START", GetLocalizedText("Log_GiocoAvviato"))
end

--- Called when exiting the game.
function love.quit()
    Stampa("CLOSE", GetLocalizedText("Log_GiocoChiusa"))
end

--- Called every frame. Updates game logic.
--- @param dt number Delta time since the last frame.
function love.update(dt)
    -- Music Volume Control
    if Barra_Volume_Musica.Usato then
        local mouseX = love.mouse.getX()
        Barra_Volume_Musica.Punto_X = math.max(Barra_Volume_Musica.x,
            math.min(mouseX, Barra_Volume_Musica.x + Barra_Volume_Musica.Larghezza - Barra_Volume_Musica.Punto_Lato))
        Barra_Volume_Musica.Valore = (Barra_Volume_Musica.Punto_X - Barra_Volume_Musica.x) /
        (Barra_Volume_Musica.Larghezza - Barra_Volume_Musica.Punto_Lato)
        love.filesystem.write("Barra_Volume_Musica.txt", tostring(Barra_Volume_Musica.Valore))
        if Musica_Sfondo then
            Musica_Sfondo:setVolume(Barra_Volume_Musica.Valore)
            -- Log only when value changes significantly or on release to avoid spam
            -- Stampa("DEBUG", GetLocalizedText("Log_ModificaVolumeMusica", math.floor(Barra_Volume_Musica.Valore * 100)))
        end
    end

    -- SFX Volume Control
    if Barra_Volume_Effetti_Sonori.Usato then
        local mouseX = love.mouse.getX()
        Barra_Volume_Effetti_Sonori.Punto_X = math.max(Barra_Volume_Effetti_Sonori.x,
            math.min(mouseX,
                Barra_Volume_Effetti_Sonori.x + Barra_Volume_Effetti_Sonori.Larghezza -
                Barra_Volume_Effetti_Sonori.Punto_Lato))
        Barra_Volume_Effetti_Sonori.Valore = (Barra_Volume_Effetti_Sonori.Punto_X - Barra_Volume_Effetti_Sonori.x) /
        (Barra_Volume_Effetti_Sonori.Larghezza - Barra_Volume_Effetti_Sonori.Punto_Lato)
        love.filesystem.write("Barra_Volume_SFX.txt", tostring(Barra_Volume_Effetti_Sonori.Valore))
        Effetti_Sonori.Selezione:setVolume(Barra_Volume_Effetti_Sonori.Valore)
        -- Log only when value changes significantly or on release to avoid spam
        -- Stampa("DEBUG", GetLocalizedText("Log_ModificaVolumeSFX", math.floor(Barra_Volume_Effetti_Sonori.Valore * 100)))
    end

    -- Background music management.
    if #Tracce_Sfondo > 0 and (not Musica_Sfondo or not Musica_Sfondo:isPlaying()) then
        local success, err = pcall(function()
            Musica_Sfondo = love.audio.newSource(Tracce_Sfondo[Traccia_Sfondo_Corrente], "stream")
            Musica_Sfondo:setLooping(false) -- Play once, then switch to next
            Musica_Sfondo:play()
            Musica_Sfondo:setVolume(Barra_Volume_Musica.Valore)
            Stampa("DEBUG", "Avviato l'esecuzione di " .. Tracce_Sfondo[Traccia_Sfondo_Corrente] .. "!")
        end)
        if not success then
            Stampa("ERRORE", GetLocalizedText("Log_ErroreMusicaCaricamento", Tracce_Sfondo[Traccia_Sfondo_Corrente] or "Unknown file") .. ": " .. err)
        end
        Traccia_Sfondo_Corrente = (Traccia_Sfondo_Corrente % #Tracce_Sfondo) + 1
    end
end

--- Called when a key is pressed. Handles keyboard input.
--- @param tasto string The pressed key.
function love.keypressed(tasto)
    if SchedaSelezionata == "Menu" then
        if tasto == "down" then
            SceltaMenu = SceltaMenu + 1
            if SceltaMenu > #Menu then
                SceltaMenu = 1
            end
            Effetti_Sonori.Selezione:play()
        elseif tasto == "up" then
            SceltaMenu = SceltaMenu - 1
            if SceltaMenu < 1 then
                SceltaMenu = #Menu
            end
            Effetti_Sonori.Selezione:play()
        elseif tasto == "return" then
            local Messaggio
            local newTitle = GetLocalizedText("Titolo")
            if Menu[SceltaMenu] == "SinglePlayer" then
                Messaggio = GetLocalizedText("Log_StartSingleplayer")
                newTitle = newTitle .. " - " .. GetLocalizedText("SinglePlayer")
            elseif Menu[SceltaMenu] == "MultiPlayer" then
                Messaggio = GetLocalizedText("Log_StartMultiPlayer")
                newTitle = newTitle .. " - " .. GetLocalizedText("MultiPlayer")
            elseif Menu[SceltaMenu] == "Crediti" then
                Messaggio = GetLocalizedText("Log_MostraCrediti")
                newTitle = newTitle .. " - " .. GetLocalizedText("Crediti")
            elseif Menu[SceltaMenu] == "Exit" then
                love.event.quit()
            end
            Effetti_Sonori.Selezione:play()
            if Menu[SceltaMenu] ~= "Exit" then
                Stampa("INFO", Messaggio)
                SchedaSelezionata = Menu[SceltaMenu]
                love.window.setTitle(newTitle)
            end
        end
    elseif SchedaSelezionata == "Impostazioni" then
        local currentLangIndex = IndiceLinguaCorrente()
        local numLingue = #LingueModule.Lingue -- Assuming Lingue is accessible or a function returns its count
        if tasto == "left" then
            currentLangIndex = currentLangIndex - 1
            if currentLangIndex < 1 then
                currentLangIndex = numLingue
            end
            MettiLingua(currentLangIndex)
            love.filesystem.write("Lingua_Corrente.txt", tostring(currentLangIndex))
            Stampa("DEBUG", "Lingua impostata a: " .. PrendiLingua() .. " e salvata su file.")
            love.window.setTitle(GetLocalizedText("Titolo") .. " - " .. GetLocalizedText("Impostazioni"))
            updateUIProperties(love.graphics.getWidth(), love.graphics.getHeight()) -- Update UI for new text width
        elseif tasto == "right" then
            currentLangIndex = currentLangIndex + 1
            if currentLangIndex > numLingue then
                currentLangIndex = 1
            end
            MettiLingua(currentLangIndex)
            love.filesystem.write("Lingua_Corrente.txt", tostring(currentLangIndex))
            Stampa("DEBUG", "Lingua impostata a: " .. PrendiLingua() .. " e salvata su file.")
            love.window.setTitle(GetLocalizedText("Titolo") .. " - " .. GetLocalizedText("Impostazioni"))
            updateUIProperties(love.graphics.getWidth(), love.graphics.getHeight()) -- Update UI for new text width
        end
    end

    if SchedaSelezionata ~= "Menu" and tasto == "escape" then
        SchedaSelezionata = "Menu"
        Resetta_Gioco()
        NumeroPartita = 1
        Stampa("INFO", GetLocalizedText("Log_RitornoMenu"))
        love.window.setTitle(GetLocalizedText("Titolo"))
    end
end

--- Called when a mouse button is pressed. Handles mouse input.
--- @param x number The x-coordinate of the mouse.
--- @param y number The y-coordinate of the mouse.
--- @param pulsante number The pressed mouse button.
function love.mousepressed(x, y, pulsante)
    if pulsante == 1 then -- Left mouse button
        if SchedaSelezionata == "Menu" then
            -- Check for settings button click
            if x >= Pulsante_Impostazioni.x and x <= Pulsante_Impostazioni.x + Pulsante_Impostazioni.Dimensione and
                y >= Pulsante_Impostazioni.y and y <= Pulsante_Impostazioni.y + Pulsante_Impostazioni.Dimensione then
                Stampa("INFO", GetLocalizedText("Log_MostraImpostanzioni"))
                love.window.setTitle(GetLocalizedText("Titolo") .. " - " .. GetLocalizedText("Impostazioni"))
                SchedaSelezionata = "Impostazioni"
                Effetti_Sonori.Selezione:play()
            else -- Check for menu item clicks
                local inizioMenuY = love.graphics.getHeight() * 0.3
                local spaziaturaMenu = love.graphics.getHeight() * 0.08
                for i, Scelta in ipairs(Menu) do
                    love.graphics.setFont(Fonts.Menu.Carattere)
                    local menuY = inizioMenuY + (i - 1) * spaziaturaMenu
                    local textWidth = Fonts.Menu.Carattere:getWidth(GetLocalizedText(Scelta))
                    local textX = (love.graphics.getWidth() - textWidth) / 2
                    local textHeight = Fonts.Menu.Carattere:getHeight()

                    if x >= textX and x <= textX + textWidth and
                        y >= menuY and y <= menuY + textHeight then
                        SceltaMenu = i -- Update selected menu item
                        love.keypressed("return") -- Simulate return key press
                        break
                    end
                end
            end
        elseif (SchedaSelezionata == "SinglePlayer" or SchedaSelezionata == "MultiPlayer") and StatoGioco == 0 then
            local mossaEseguita = false
            for Riga = 1, 3 do
                for Colonna = 1, 3 do
                    local cellaX = Tabella_Grafica.Offset_X + (Colonna - 1) * Tabella_Grafica.Dimensione_Cella
                    local cellaY = Tabella_Grafica.Offset_Y + (Riga - 1) * Tabella_Grafica.Dimensione_Cella

                    if x >= cellaX and x <= cellaX + Tabella_Grafica.Dimensione_Cella and
                        y >= cellaY and y <= cellaY + Tabella_Grafica.Dimensione_Cella then
                        if Tabella[Riga][Colonna] == ' ' then
                            local simbolo = (SchedaSelezionata == "SinglePlayer" or GiocatoreCorrente == 1) and 'X' or 'O'
                            Stampa("DEBUG", GetLocalizedText("Log_CasellaSceltaGiocatore", Riga, Colonna, simbolo))
                            mossaEseguita = true
                            Effetti_Sonori.Selezione:play()
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

            -- CPU Move (only for SinglePlayer)
            if mossaEseguita and SchedaSelezionata == "SinglePlayer" and StatoGioco == 0 then
                local Casella = Backend.MossaCPU(Tabella)
                local Riga = math.floor(Casella / 3) + 1
                local Colonna = (Casella % 3) + 1
                if Tabella[Riga][Colonna] == ' ' then
                    Tabella[Riga][Colonna] = 'O'
                    Stampa("DEBUG", GetLocalizedText("Log_MossaCPU", Riga, Colonna))
                    Effetti_Sonori.Selezione:play()
                    Esegui_Mossa(Riga, Colonna, 'O')
                else
                    Stampa("ERRORE", GetLocalizedText("Log_CasellaOccupataCPU", Riga, Colonna))
                end
            end
        elseif StatoGioco ~= 0 then -- Game ended, check for restart button
            if x >= Pulsante_Riavvio.x and x <= Pulsante_Riavvio.x + Pulsante_Riavvio.Dimensione and
                y >= Pulsante_Riavvio.y and y <= Pulsante_Riavvio.y + Pulsante_Riavvio.Dimensione then
                Resetta_Gioco()
                NumeroPartita = NumeroPartita + 1
                Effetti_Sonori.Selezione:play()
            end
        elseif SchedaSelezionata == "Impostazioni" then
            -- Check click on music volume bar slider
            if x >= Barra_Volume_Musica.Punto_X and x <= Barra_Volume_Musica.Punto_X + Barra_Volume_Musica.Punto_Lato and
                y >= Barra_Volume_Musica.y - 5 and y <= Barra_Volume_Musica.y + Barra_Volume_Musica.Altezza + 5 then
                Barra_Volume_Musica.Usato = true
                Effetti_Sonori.Selezione:play()
            end
            -- Check click on SFX volume bar slider
            if x >= Barra_Volume_Effetti_Sonori.Punto_X and x <= Barra_Volume_Effetti_Sonori.Punto_X + Barra_Volume_Effetti_Sonori.Punto_Lato and
                y >= Barra_Volume_Effetti_Sonori.y - 5 and y <= Barra_Volume_Effetti_Sonori.y + Barra_Volume_Effetti_Sonori.Altezza + 5 then
                Barra_Volume_Effetti_Sonori.Usato = true
                Effetti_Sonori.Selezione:play()
            end
            -- Check click on language arrows
            local currentLangIndex = IndiceLinguaCorrente()
            local numLingue = #LingueModule.Lingue
            if x >= Opzione_Lingua.Freccia_Sinistra_X and x <= Opzione_Lingua.Freccia_Sinistra_X + Opzione_Lingua.Dimensione_Freccia and
                y >= Opzione_Lingua.y + (Opzione_Lingua.Altezza / 2) - (Opzione_Lingua.Dimensione_Freccia / 2) and
                y <= Opzione_Lingua.y + (Opzione_Lingua.Altezza / 2) + (Opzione_Lingua.Dimensione_Freccia / 2) then
                currentLangIndex = currentLangIndex - 1
                if currentLangIndex < 1 then
                    currentLangIndex = numLingue
                end
                MettiLingua(currentLangIndex)
                love.filesystem.write("Lingua_Corrente.txt", tostring(currentLangIndex))
                Stampa("DEBUG", "Lingua impostata a: " .. PrendiLingua() .. " e salvata su file.")
                love.window.setTitle(GetLocalizedText("Titolo") .. " - " .. GetLocalizedText("Impostazioni"))
                updateUIProperties(love.graphics.getWidth(), love.graphics.getHeight()) -- Update UI for new text width
                Effetti_Sonori.Selezione:play()
            elseif x >= Opzione_Lingua.Freccia_Destra_X and x <= Opzione_Lingua.Freccia_Destra_X + Opzione_Lingua.Dimensione_Freccia and
                y >= Opzione_Lingua.y + (Opzione_Lingua.Altezza / 2) - (Opzione_Lingua.Dimensione_Freccia / 2) and
                y <= Opzione_Lingua.y + (Opzione_Lingua.Altezza / 2) + (Opzione_Lingua.Dimensione_Freccia / 2) then
                currentLangIndex = currentLangIndex + 1
                if currentLangIndex > numLingue then
                    currentLangIndex = 1
                end
                MettiLingua(currentLangIndex)
                love.filesystem.write("Lingua_Corrente.txt", tostring(currentLangIndex))
                Stampa("DEBUG", "Lingua impostata a: " .. PrendiLingua() .. " e salvata su file.")
                love.window.setTitle(GetLocalizedText("Titolo") .. " - " .. GetLocalizedText("Impostazioni"))
                updateUIProperties(love.graphics.getWidth(), love.graphics.getHeight()) -- Update UI for new text width
                Effetti_Sonori.Selezione:play()
            end
            if x >= Checkbox_Log.x and x <= Checkbox_Log.x + Checkbox_Log.Larghezza and y >= Checkbox_Log.y and y <= Checkbox_Log.y + Checkbox_Log.Altezza then
                Checkbox_Log.Selezionata = not Checkbox_Log.Selezionata  -- Toggle
                LogCheck = Checkbox_Log.Selezionata  -- Sincronizza la variabile globale
                love.filesystem.write("LogCheck.txt", tostring(Checkbox_Log.Selezionata))
                Stampa("DEBUG", "Log " .. (LogCheck and "abilitati" or "disabilitati") .. " e salvati su file.")
                Effetti_Sonori.Selezione:play()
            end
        end
    end
end

--- Called when a mouse button is released.
function love.mousereleased(x, y, pulsante)
    if pulsante == 1 then
        if Barra_Volume_Musica.Usato then
            Barra_Volume_Musica.Usato = false
            Stampa("DEBUG", GetLocalizedText("Log_ModificaVolumeMusica", math.floor(Barra_Volume_Musica.Valore * 100)))
        end
        if Barra_Volume_Effetti_Sonori.Usato then
            Barra_Volume_Effetti_Sonori.Usato = false
            Stampa("DEBUG", GetLocalizedText("Log_ModificaVolumeSFX", math.floor(Barra_Volume_Effetti_Sonori.Valore * 100)))
        end
    end
end

--- Called every frame. Draws game elements.
function love.draw()
    love.graphics.clear(0.68, 0.85, 0.9) -- Light blue background color

    if SchedaSelezionata == "Menu" then
        love.graphics.setFont(Fonts.Titolo.Carattere)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(GetLocalizedText("Titolo"), 0, love.graphics.getHeight() * 0.1, love.graphics.getWidth(),
            "center")

        local inizioMenuY = love.graphics.getHeight() * 0.3
        local spaziaturaMenu = love.graphics.getHeight() * 0.08

        for i, Scelta in ipairs(Menu) do
            love.graphics.setFont(Fonts.Menu.Carattere)
            love.graphics.setColor(i == SceltaMenu and Fonts.Menu.Colore_Scelta[1] or Fonts.Menu.Colore_Normale[1],
                i == SceltaMenu and Fonts.Menu.Colore_Scelta[2] or Fonts.Menu.Colore_Normale[2],
                i == SceltaMenu and Fonts.Menu.Colore_Scelta[3] or Fonts.Menu.Colore_Normale[3])
            local menuY = inizioMenuY + (i - 1) * spaziaturaMenu
            love.graphics.printf(GetLocalizedText(Scelta), 0, menuY, love.graphics.getWidth(), "center")
        end

        love.graphics.setColor(1, 1, 1) -- White color for settings icon
        love.graphics.draw(Pulsante_Impostazioni.Icona, Pulsante_Impostazioni.x, Pulsante_Impostazioni.y, 0,
            Pulsante_Impostazioni.Dimensione / Pulsante_Impostazioni.Icona:getWidth(),
            Pulsante_Impostazioni.Dimensione / Pulsante_Impostazioni.Icona:getHeight())
    elseif SchedaSelezionata == "Crediti" then
        love.graphics.setFont(Fonts.Crediti.Carattere)
        love.graphics.setColor(1, 1, 1) -- White color for credits text

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
        love.graphics.printf(GetLocalizedText("Impostazioni_Titolo"), 0, love.graphics.getHeight() * 0.08,
            love.graphics.getWidth(), "center")

        -- Background rectangle for Music Volume
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", Barra_Volume_Musica.x - 20, Barra_Volume_Musica.y - 60,
            Barra_Volume_Musica.Larghezza + 40, Barra_Volume_Musica.Altezza + 100, 10, 10)

        -- Music Volume Bar
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", Barra_Volume_Musica.x, Barra_Volume_Musica.y, Barra_Volume_Musica.Larghezza,
            Barra_Volume_Musica.Altezza)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", Barra_Volume_Musica.Punto_X, Barra_Volume_Musica.y - 5,
            Barra_Volume_Musica.Punto_Lato, Barra_Volume_Musica.Altezza + 10)

        love.graphics.setFont(Fonts.Testo.Carattere)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(
        GetLocalizedText("Volume_Musica") .. ": " .. math.floor(Barra_Volume_Musica.Valore * 100) .. "%",
            Barra_Volume_Musica.x, Barra_Volume_Musica.y - 30)

        -- Background rectangle for SFX Volume
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", Barra_Volume_Effetti_Sonori.x - 20, Barra_Volume_Effetti_Sonori.y - 60,
            Barra_Volume_Effetti_Sonori.Larghezza + 40, Barra_Volume_Effetti_Sonori.Altezza + 100, 10, 10)

        -- SFX Volume Bar
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", Barra_Volume_Effetti_Sonori.x, Barra_Volume_Effetti_Sonori.y,
            Barra_Volume_Effetti_Sonori.Larghezza, Barra_Volume_Effetti_Sonori.Altezza)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", Barra_Volume_Effetti_Sonori.Punto_X, Barra_Volume_Effetti_Sonori.y - 5,
            Barra_Volume_Effetti_Sonori.Punto_Lato, Barra_Volume_Effetti_Sonori.Altezza + 10)

        love.graphics.setFont(Fonts.Testo.Carattere)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(
        GetLocalizedText("Volume_Effetti_Sonori") .. ": " .. math.floor(Barra_Volume_Effetti_Sonori.Valore * 100) .. "%",
            Barra_Volume_Effetti_Sonori.x, Barra_Volume_Effetti_Sonori.y - 30)

        -- Background rectangle for Language Option
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", Opzione_Lingua.x - 20, Opzione_Lingua.y - 60, Opzione_Lingua.Larghezza + 40,
            Opzione_Lingua.Altezza + 100, 10, 10)

        -- Language Option
        love.graphics.setFont(Fonts.Testo.Carattere)
        love.graphics.setColor(1, 1, 1)
        local testoLingua = GetLocalizedText("Linguaggio") .. ": " .. PrendiLingua()
        local larghezzaTestoLingua = Fonts.Testo.Carattere:getWidth(testoLingua)
        local testoLinguaX = Opzione_Lingua.x + (Opzione_Lingua.Larghezza - larghezzaTestoLingua) / 2
        love.graphics.print(testoLingua, testoLinguaX, Opzione_Lingua.y - 30)

        -- Arrows to change language
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("<", Opzione_Lingua.Freccia_Sinistra_X,
            Opzione_Lingua.y + (Opzione_Lingua.Altezza / 2) - (Fonts.Testo.Carattere:getHeight() / 2))
        love.graphics.print(">", Opzione_Lingua.Freccia_Destra_X,
            Opzione_Lingua.y + (Opzione_Lingua.Altezza / 2) - (Fonts.Testo.Carattere:getHeight() / 2))

        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", Checkbox_Log.x - 20, Checkbox_Log.y - 30,
            Checkbox_Log.Larghezza + Fonts.Testo.Carattere:getWidth(Checkbox_Log.Testo) + 40, Checkbox_Log.Altezza + 60,
            10, 10)

        -- Disegno della checkbox (bordo sempre visibile, riempita se selezionata)
        love.graphics.setColor(0.5, 0.5, 0.5) -- Bordo grigio
        love.graphics.rectangle("line", Checkbox_Log.x, Checkbox_Log.y, Checkbox_Log.Larghezza, Checkbox_Log.Altezza)
        if Checkbox_Log.Selezionata then
            love.graphics.setColor(0.57, 0.44, 0.86) -- Colore selezionato (viola, come il menu)
            love.graphics.rectangle("fill", Checkbox_Log.x + 2, Checkbox_Log.y + 2, Checkbox_Log.Larghezza - 4,
                Checkbox_Log.Altezza - 4)
            love.graphics.setColor(1, 1, 1)      -- Reset a bianco
        end

        -- Testo accanto alla checkbox
        love.graphics.setFont(Fonts.Testo.Carattere)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(Checkbox_Log.Testo, Checkbox_Log.x + Checkbox_Log.Larghezza + 10, Checkbox_Log.y)
    else -- Game screen (SinglePlayer or MultiPlayer)
        love.graphics.setFont(Fonts.Titolo.Carattere)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(GetLocalizedText("Gioco") .. ": " .. NumeroPartita, 0, love.graphics.getHeight() * 0.09,
            love.graphics.getWidth(), "center")

        if SchedaSelezionata == "MultiPlayer" then
            love.graphics.setFont(Fonts.Giocatore.Carattere)
            love.graphics.printf(GetLocalizedText("Player") .. ": " .. GiocatoreCorrente, 0,
                love.graphics.getHeight() * 0.8, love.graphics.getWidth(), "center")
        end

        -- Game Grid
        love.graphics.setLineWidth(2)
        for i = 1, 2 do
            -- Vertical lines
            love.graphics.line(Tabella_Grafica.Offset_X + i * Tabella_Grafica.Dimensione_Cella, Tabella_Grafica.Offset_Y,
                Tabella_Grafica.Offset_X + i * Tabella_Grafica.Dimensione_Cella,
                Tabella_Grafica.Offset_Y + Tabella_Grafica.Dimensione)
            -- Horizontal lines
            love.graphics.line(Tabella_Grafica.Offset_X, Tabella_Grafica.Offset_Y + i * Tabella_Grafica.Dimensione_Cella,
                Tabella_Grafica.Offset_X + Tabella_Grafica.Dimensione,
                Tabella_Grafica.Offset_Y + i * Tabella_Grafica.Dimensione_Cella)
        end

        -- Draw X and O symbols on the board
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
                        love.graphics.setColor(1, 0, 0) -- Red for 'X'
                        love.graphics.line(cellaX + padding, cellaY + padding, cellaX + padding + dimensione,
                            cellaY + padding + dimensione)
                        love.graphics.line(cellaX + padding + dimensione, cellaY + padding, cellaX + padding,
                            cellaY + padding + dimensione)
                    elseif Valore == 'O' then
                        love.graphics.setColor(0, 0, 1) -- Blue for 'O'
                        love.graphics.circle("line", cellaX + Tabella_Grafica.Dimensione_Cella / 2,
                            cellaY + Tabella_Grafica.Dimensione_Cella / 2, dimensione / 2)
                    end
                end
            end
        end

        -- Win Line
        if StatoGioco > 0 then
            love.graphics.setColor(1, 1, 1) -- White color for win line
            love.graphics.setLineWidth(5)

            local cell = Tabella_Grafica.Dimensione_Cella -- Alias for brevity

            if StatoGioco >= 10 and StatoGioco < 20 then -- Row win (horizontal line)
                local riga = StatoGioco - 10      -- 1, 2, or 3
                local y = Tabella_Grafica.Offset_Y + (riga - 1) * cell + cell / 2
                love.graphics.line(Tabella_Grafica.Offset_X, y, Tabella_Grafica.Offset_X + Tabella_Grafica.Dimensione, y)
            elseif StatoGioco >= 20 and StatoGioco < 30 then -- Column win (vertical line)
                local col = StatoGioco - 20          -- 1, 2, or 3
                local x = Tabella_Grafica.Offset_X + (col - 1) * cell + cell / 2
                love.graphics.line(x, Tabella_Grafica.Offset_Y, x, Tabella_Grafica.Offset_Y + Tabella_Grafica.Dimensione)
            elseif StatoGioco == 31 then -- Diagonal win (top-left to bottom-right)
                love.graphics.line(Tabella_Grafica.Offset_X, Tabella_Grafica.Offset_Y,
                    Tabella_Grafica.Offset_X + Tabella_Grafica.Dimensione,
                    Tabella_Grafica.Offset_Y + Tabella_Grafica.Dimensione)
            elseif StatoGioco == 32 then -- Diagonal win (top-right to bottom-left)
                love.graphics.line(Tabella_Grafica.Offset_X + Tabella_Grafica.Dimensione, Tabella_Grafica.Offset_Y,
                    Tabella_Grafica.Offset_X, Tabella_Grafica.Offset_Y + Tabella_Grafica.Dimensione)
            end
        end

        -- Restart Button
        if StatoGioco ~= 0 then
            love.graphics.setColor(1, 1, 1) -- White color for restart icon
            love.graphics.draw(Pulsante_Riavvio.Icona, Pulsante_Riavvio.x, Pulsante_Riavvio.y, 0,
                Pulsante_Riavvio.Dimensione / Pulsante_Riavvio.Icona:getWidth(),
                Pulsante_Riavvio.Dimensione / Pulsante_Riavvio.Icona:getHeight())
        end
    end
end

--- Called when the window is resized. Updates UI element positions and sizes.
--- @param w number The new width of the window.
--- @param h number The new height of the window.
function love.resize(w, h)
    updateUIProperties(w, h)
end