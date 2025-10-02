--- Registra un messaggio nella console e in un file di log.
--- @param tipo string Il tipo di messaggio (es., "INFO", "DEBUG", "ERRORE").
--- @param messaggio string Il messaggio da registrare.
local function Debug(tipo, messaggio)
    -- Implementazione semplificata del logging su file in Lua
    local logDir = "Logs/"
    love.filesystem.createDirectory(logDir)
    local logFilePath = logDir .. "log.log"

    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local logEntry = string.format("<%s> [%s] %s\n", timestamp, tipo, messaggio)

    -- Gestione rotazione log (semplificata)
    local currentLogContent = ""
    if love.filesystem.getInfo(logFilePath) then
        currentLogContent = love.filesystem.read(logFilePath)
    end

    local lines = 0
    for _ in currentLogContent:gmatch("\n") do
        lines = lines + 1
    end

    local maxLines = 1000
    if lines >= maxLines then
        -- Sposta i log esistenti
        for i = 9, 1, -1 do
            local oldName = logDir .. "log" .. i .. ".log"
            local newName = logDir .. "log" .. (i + 1) .. ".log"
            if love.filesystem.exists(oldName) then
                love.filesystem.move(oldName, newName)
            end
        end
        if love.filesystem.exists(logFilePath) then
            love.filesystem.move(logFilePath, logDir .. "log1.log")
        end
    end

    love.filesystem.append(logFilePath, logEntry)
end

return {
    Debug = Debug
}
