local ffi = require("ffi")
ffi.cdef[[
    int Pareggio(char Tavola[3][3]);
    int Vittoria(char Tavola[3][3]);
]]
local Backend = ffi.load("Back-end\\Back.dll")

local Tabella = {
    {' ', ' ', ' '},
    {' ', ' ', ' '},
    {' ', ' ', ' '}
}
local Menu

function Tabella_Lua_C(Tavola)
    local CArray = ffi.new("char[3][3]")
    for i = 1, 3 do
        for j = 1, 3 do
            CArray[i-1][j-1] = Tavola[i][j]:byte()
        end
    end
    return CArray
end

print(Backend.Vittoria(Tabella_Lua_C(Tabella)))

function love.load()
    love.window.setTitle("Tris")
    love.window.setIcon(love.image.newImageData("Resources/Icon/Tris_icon.png"))
    love.graphics.setFont(love.graphics.newFont(20))
end