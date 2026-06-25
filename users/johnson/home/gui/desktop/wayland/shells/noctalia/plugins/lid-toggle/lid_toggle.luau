local lidCommand = barWidget.getConfig("command") or "lid"
local notifyEnabled = barWidget.getConfig("notify") ~= false
local active = false
local busy = false
local refreshPending = false

local function shellQuote(value)
    local text = tostring(value or "")
    return "'" .. string.gsub(text, "'", "'\\''") .. "'"
end

local function statusFromOutput(output)
    local text = output or ""
    if string.find(text, "^on:") or string.find(text, "^already on:") then
        return true
    end
    if string.find(text, "^off:") or string.find(text, "^already off:") then
        return false
    end
    return nil
end

local function applyState(isActive)
    active = isActive == true

    if active then
        barWidget.setGlyph("device-laptop")
        barWidget.setGlyphColor("primary")
        barWidget.setTooltip("Lid mode: on")
    else
        barWidget.setGlyph("device-laptop-off")
        barWidget.setGlyphColor("on_surface_variant")
        barWidget.setTooltip("Lid mode: off")
    end
end

local function notifyState(isActive)
    if not notifyEnabled then return end

    if isActive then
        noctalia.notify("Lid", "on: close lid turns screen off, sleep stays inhibited")
    else
        noctalia.notify("Lid", "off: normal lid/sleep behavior restored")
    end
end

local function refresh()
    if refreshPending then return end

    refreshPending = true
    noctalia.runAsync(shellQuote(lidCommand) .. " status", function(result)
        refreshPending = false
        if result.exitCode ~= 0 then
            return
        end

        local nextState = statusFromOutput(result.stdout)
        if nextState ~= nil then
            applyState(nextState)
        end
    end, 2000)
end

function onClick()
    if busy then return end

    busy = true
    barWidget.setGlyph("loader-2")
    barWidget.setGlyphColor("primary")
    noctalia.runAsync(shellQuote(lidCommand) .. " toggle", function(result)
        busy = false

        if result.exitCode ~= 0 then
            applyState(active)
            noctalia.notifyError("Lid", result.stderr or "toggle failed")
            return
        end

        local nextState = statusFromOutput(result.stdout)
        if nextState == nil then
            refresh()
            return
        end

        applyState(nextState)
        notifyState(nextState)
    end, 5000)
end

function onRightClick()
    if busy then return end

    busy = true
    noctalia.runAsync(shellQuote(lidCommand) .. " off", function(result)
        busy = false
        applyState(false)
        if result.exitCode == 0 then
            notifyState(false)
        else
            noctalia.notifyError("Lid", result.stderr or "off failed")
            refresh()
        end
    end, 5000)
end

function update()
    refresh()
end

noctalia.setUpdateInterval(3000)
applyState(false)
refresh()
