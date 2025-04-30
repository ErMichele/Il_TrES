local ffi = require("ffi")
ffi.cdef [[
    int Pareggio(char Tavola[3][3]);
    int Vittoria(char Tavola[3][3]);
    void Test();
]]
local Backend = ffi.load("Back-end\\Back.dll")

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
        end
    end
end

function love.draw()
    if SchedaSelezionata == "Menu" then
        love.graphics.printf("Menu del Gioco", 0, 50, love.graphics.getWidth(), "center")

        for i, Scelta in ipairs(Menu) do
            if i == MenuScelta then
                love.graphics.setColor(1, 0, 0) -- Colore rosso per l'opzione selezionata
            else
                love.graphics.setColor(1, 1, 1) -- Colore bianco per le altre opzioni
            end

            love.graphics.printf(Scelta, 0, 100 + i * 30, love.graphics.getWidth(), "center")
        end

        love.graphics.setColor(1, 1, 1)
    end
end