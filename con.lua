local utf8 = require("utf8")

-- con.lua
local console = {
    font = nil,
    messages = {},
    maxLines = 20,
    visible = false,
    bgColor = {0, 0, 0, 0.6},
    textColor = {0, 1, 0, 0.9},
    input = "",
    history = {},
    historyIndex = 0,
    active = false,
    backspaceHeld = false,
    backspaceTimer = 0,
    backspaceDelay = 0.3,
    backspaceRepeat = 0.015,
    scroll = 0,
    lineHeight = 0,
}

function console.load()
    console.font = love.graphics.newFont("assets/Hack-Regular.ttf", 16)
    console.lineHeight = console.font:getHeight()
end

function console.log(msg)
    table.insert(console.messages, tostring(msg))
    print(tostring(msg))
end

function console.toggle()
    console.visible = not console.visible
    console.active = console.visible
end

local function dumpTable(tbl, indent, visited)
    indent = indent or 0
    visited = visited or {}

    if visited[tbl] then
        return string.rep(" ", indent) .. "*recursive*\n"
    end
    visited[tbl] = true

    local output = ""
    for k, v in pairs(tbl) do
        local prefix = string.rep(" ", indent) .. tostring(k) .. " = "

        if type(v) == "table" then
            output = output .. prefix .. "{\n"
            output = output .. dumpTable(v, indent + 4, visited)
            output = output .. string.rep(" ", indent) .. "}\n"
        else
            output = output .. prefix .. tostring(v) .. " (" .. type(v) .. ")\n"
        end
    end

    return output
end

function console.run(code)
    if code == "clear" then
        console.messages = { } console.history = { } console.historyIndex = 0 return
    end

    if code == "vars" then
        for k, v in pairs(_G) do
            if type(v) ~= "function" then
                console.log(k .. " (" .. type(v) .. ")")
            end
        end
        return
    end

    if code:match("^vars") then
        local varName = code:match("^vars%s+(.+)")
        if not varName then
            console.log("Usage: vars <variable>")
            return
        end

        local value = _G[varName]

        if value == nil then
            console.log("Variable not found: " .. varName)
            return
        end

        if type(value) ~= "table" then
            console.log(varName .. " = " .. tostring(value) .. " (" .. type(value) .. ")")
            return
        end

        console.log(varName .. " = {")
        local dumped = dumpTable(value, 4)
        for line in dumped:gmatch("[^\n]+") do
            console.log(line)
        end
        console.log("}")
        return
    end

    local func, err = load(code, "Console", "t", _G)
    if not func then
        console.log("Error: " .. err)
        return
    end
    local ok, result = pcall(func)
    if not ok then
        console.log("Error: " .. result)
    elseif result ~= nil then
        console.log(result)
    end
end

function console.keypressed(key)
    if not console.active then return end

    if key == "return" then
        console.log("> " .. console.input)
        console.run(console.input)
        table.insert(console.history, console.input)
        console.historyIndex = #console.history + 1
        console.input = ""
    elseif key == "backspace" then
        console.backspaceHeld = true
        console.backspaceTimer = 0
        console.deleteChar()
    elseif key == "up" then
        if #console.history > 0 then
            console.historyIndex = math.max(1, console.historyIndex - 1)
            console.input = console.history[console.historyIndex] or ""
        end
    elseif key == "down" then
        if #console.history > 0 then
            console.historyIndex = math.min(#console.history + 1, console.historyIndex + 1)
            console.input = console.history[console.historyIndex] or ""
        end
    elseif key == "pageup" then
        console.scroll = console.scroll + 5
    elseif key == "pagedown" then   
        console.scroll = math.max(0, console.scroll - 5)
    end
end

function console.draw()
    if not console.visible then return end
    love.graphics.push()
    love.graphics.setFont(console.font)

    local width = 800
    local height = console.maxLines * console.font:getHeight() + 30
    local x, y = 10, 10

    love.graphics.setColor(console.bgColor)
    love.graphics.rectangle("fill", x, y, width, height, 5, 5)

    love.graphics.setColor(console.textColor)

    local totalLines = #console.messages
    local visibleLines = console.maxLines


    local startLine = math.max(1, totalLines - visibleLines + 1 - console.scroll)
    local endLine = math.min(totalLines, startLine + visibleLines - 1)

    for i = startLine, endLine do
        local drawIndex = i - startLine
        love.graphics.print(
            console.messages[i],
            x + 5,
            y + drawIndex * console.lineHeight
        )
    end

    love.graphics.setColor(0,1,0,1)
    ok = pcall(function()
            love.graphics.print("> " .. console.input .. "_", x + 5, y + height - console.font:getHeight() - 5)
        end
    )
    if not ok then
        console.input = "error(\"invalid input\")"
    end

    love.graphics.pop()
    love.graphics.setColor(1,1,1,1)
end

function console.update(dt)
    if not console.active then return end

    if console.backspaceHeld then
        console.backspaceTimer = console.backspaceTimer + dt

        if console.backspaceTimer > console.backspaceDelay then
            console.deleteChar()
            console.backspaceTimer = console.backspaceDelay - console.backspaceRepeat
        end
    end
end

function console.deleteChar()
    local byteoffset = utf8.offset(console.input, -1)
    if byteoffset then
        console.input = string.sub(console.input, 1, byteoffset - 1)
    end
end


return console
