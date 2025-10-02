--- Controlla se c'è una vittoria sulla tavola di gioco.
--- @param tavola table La tavola di gioco 3x3.
--- @return number Un codice che indica la vittoria (10-12 per riga, 20-22 per colonna, 31/32 per diagonale) o 0 se non c'è vittoria.
local function Vittoria(tavola)
    -- Controllo righe
    for riga = 1, 3 do
        if tavola[riga][1] == tavola[riga][2] and tavola[riga][2] == tavola[riga][3] and tavola[riga][1] ~= ' ' then
            return 10 + riga -- 11, 12, 13 per riga 1, 2, 3
        end
    end

    -- Controllo colonne
    for colonna = 1, 3 do
        if tavola[1][colonna] == tavola[2][colonna] and tavola[2][colonna] == tavola[3][colonna] and tavola[1][colonna] ~= ' ' then
            return 20 + colonna -- 21, 22, 23 per colonna 1, 2, 3
        end
    end

    -- Controllo diagonale principale
    if tavola[1][1] == tavola[2][2] and tavola[2][2] == tavola[3][3] and tavola[1][1] ~= ' ' then
        return 31
    end

    -- Controllo diagonale secondaria
    if tavola[1][3] == tavola[2][2] and tavola[2][2] == tavola[3][1] and tavola[1][3] ~= ' ' then
        return 32
    end

    return 0
end

--- Controlla se la partita è in pareggio.
--- @param tavola table La tavola di gioco 3x3.
--- @return number -1 se è pareggio, 0 se la partita è ancora in corso o c'è una vittoria.
local function Pareggio(tavola)
    if Vittoria(tavola) ~= 0 then
        return 0 -- C'è una vittoria, non è pareggio
    end

    for riga = 1, 3 do
        for colonna = 1, 3 do
            if tavola[riga][colonna] == ' ' then
                return 0 -- Ci sono ancora mosse disponibili, non è pareggio
            end
        end
    end
    return -1 -- Nessuna vittoria e nessuna mossa disponibile, è pareggio
end

--- Trova una mossa vincente per un dato simbolo.
--- @param board table La tavola di gioco 3x3.
--- @param simbolo string Il simbolo del giocatore ('X' o 'O').
--- @return number L'indice della cella (0-8) per la mossa vincente, o -1 se non trovata.
local function Trova_mossa_vincente(board, simbolo)
    for i = 1, 3 do
        for j = 1, 3 do
            if board[i][j] == ' ' then
                board[i][j] = simbolo
                if Vittoria(board) ~= 0 then
                    board[i][j] = ' ' -- Ripristina la tavola
                    return (i - 1) * 3 + (j - 1)
                end
                board[i][j] = ' ' -- Ripristina la tavola
            end
        end
    end
    return -1
end

--- Determina la mossa della CPU.
--- @param board table La tavola di gioco 3x3.
--- @return number L'indice della cella (0-8) per la mossa della CPU, o -1 in caso di errore.
local function MossaCPU(board)
    local move

    -- 1. Controlla se la CPU può vincere
    move = Trova_mossa_vincente(board, 'O')
    if move ~= -1 then return move end

    -- 2. Controlla se il giocatore può vincere e bloccalo
    move = Trova_mossa_vincente(board, 'X')
    if move ~= -1 then return move end

    -- 3. Prendi il centro se disponibile
    if board[2][2] == ' ' then return (2 - 1) * 3 + (2 - 1) end

    -- 4. Prendi un angolo se disponibile
    local angoli = { { 1, 1 }, { 1, 3 }, { 3, 1 }, { 3, 3 } }
    for _, pos in ipairs(angoli) do
        if board[pos[1]][pos[2]] == ' ' then return (pos[1] - 1) * 3 + (pos[2] - 1) end
    end

    -- 5. Prendi un lato se disponibile
    local lati = { { 1, 2 }, { 2, 1 }, { 2, 3 }, { 3, 2 } }
    for _, pos in ipairs(lati) do
        if board[pos[1]][pos[2]] == ' ' then return (pos[1] - 1) * 3 + (pos[2] - 1) end
    end

    -- Se non ci sono mosse strategiche, scegli una casella a caso (dovrebbe essere coperto dai punti precedenti)
    local available = {}
    for i = 1, 3 do
        for j = 1, 3 do
            if board[i][j] == ' ' then
                table.insert(available, (i - 1) * 3 + (j - 1))
            end
        end
    end

    if #available > 0 then
        local r = math.random(1, #available)
        return available[r]
    end

    return -1 -- Non dovrebbe accadere in una partita di Tris valida
end

return {
    Vittoria = Vittoria,
    Pareggio = Pareggio,
    MossaCPU = MossaCPU
}
