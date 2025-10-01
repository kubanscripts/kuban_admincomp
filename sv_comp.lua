local QBCore = exports['qb-core']:GetCoreObject()
local webhookURL = 'YOUR_WEBHOOK_HERE'

local function generateCompCode()
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local code = ""
    for i = 1, 5 do
        local rand = math.random(1, #charset)
        code = code .. string.sub(charset, rand, rand)
    end
    return code
end

local function saveCompCode(code, items, maxUses)
    local itemsJSON = json.encode(items)
    MySQL.Async.execute([[
        INSERT INTO kuban_comp (code, items, max_uses, used_by)
        VALUES (@code, @items, @max_uses, '[]')
    ]], {
        ["@code"] = code,
        ["@items"] = itemsJSON,
        ["@max_uses"] = maxUses
    }, function(rowsChanged)
        if rowsChanged == 1 then
            print("^2[kuban-comp] Compensation saved successfully!^0")
        else
            print("^1[kuban-comp] Failed to save compensation!^0")
        end
    end)
end

local function formatItemsForLog(items)
    local lines = {}
    for _, item in ipairs(items) do
        local line = ("• `%s` x%s"):format(item.name, item.amount)
        if item.ticket then
            line = line .. (" (Ticket: `%s`)"):format(item.ticket)
        end
        if item.max_uses then
            line = line .. (" — Max Redeems: `%s`"):format(item.max_uses)
        end
        table.insert(lines, line)
    end
    return table.concat(lines, "\n")
end

local function deleteCompCode(code)
    MySQL.Async.execute("DELETE FROM kuban_comp WHERE code = @code", {["@code"] = code})
end

local function logToDiscord(title, description, color)
    PerformHttpRequest(webhookURL, function(...) end, "POST",
        json.encode({ embeds = {{ title = title, description = description, color = color }} }),
        {["Content-Type"] = "application/json"})
end

local function SendNotification(source, message, notifType)
    if Config.Notification == "qb" then
        TriggerClientEvent("QBCore:Notify", source, message, notifType)
    elseif Config.Notification == "ox" then
        TriggerClientEvent("ox_lib:notify", source, { description = message, type = notifType or "info" })
    elseif Config.Notification == "okok" then
        TriggerClientEvent("okokNotify:Alert", source, "Notification", message, 5000, notifType or "info")
    elseif Config.Notification == "qbx" then
        exports.qbx_core:Notify(source, message, notifType or "info")
    else
        print("^1[ERROR] Unknown notification system: " .. tostring(Config.Notification) .. "^0")
    end
end

QBCore.Commands.Add("compmenu", "Open the compensation menu", {}, false, function(source)
    TriggerClientEvent("kuban-comp:client:OpenCompensationMenu", source)
end)

QBCore.Functions.CreateCallback("kuban-comp:server:IsAdmin", function(source, cb)
    local isAdmin = false
    if GetResourceState("qb-core") == "started" then
        isAdmin = QBCore.Functions.HasPermission(source, "admin") or QBCore.Functions.HasPermission(source, "god")
    elseif GetResourceState("qbx_core") == "started" then
        isAdmin = exports.qbx_core:HasPermission(source, "admin") or exports.qbx_core:HasPermission(source, "god")
    end
    cb(isAdmin)
end)

RegisterNetEvent("kuban-comp:server:CreateComp", function(items, maxUses)
    local src = source
    if not items or #items == 0 then return end

    local code = generateCompCode()
    local max = tonumber(maxUses) or 1

    saveCompCode(code, items, max)
    TriggerClientEvent("kuban-comp:client:CopyCode", src, code)

logToDiscord("🎁 Compensation Created",
    ("**Admin:** %s (ID: %d)\n**Code:** `%s`\n**Max Uses:** %d\n\n**Items:**\n%s")
    :format(GetPlayerName(src), src, code, max, formatItemsForLog(items)),
    3447003)


end)

RegisterNetEvent("kuban-comp:server:ClaimComp", function(code)
    local src = source
    MySQL.Async.fetchAll("SELECT * FROM kuban_comp WHERE code = @code", {["@code"] = code}, function(result)
        if not result or #result == 0 then
            return SendNotification(src, "Invalid or expired compensation code!", "error")
        end

        local data = result[1]
        local items = json.decode(data.items)
        local maxUses = data.max_uses or 1
        local usedBy = json.decode(data.used_by or "[]")

        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return end

        local identifier = Player.PlayerData.citizenid or QBCore.Functions.GetIdentifier(src)

        for _, id in ipairs(usedBy) do
            if id == identifier then
                return SendNotification(src, "You have already redeemed this code!", "error")
            end
        end

        if #usedBy >= maxUses then
            deleteCompCode(code)
            return SendNotification(src, "This code has reached its maximum redeems.", "error")
        end

        for _, item in ipairs(items) do
            if Config.Inventory == "qb" then
                TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items[item.name], "add", item.amount)
            elseif Config.Inventory == "ox" then
                exports.ox_inventory:AddItem(src, item.name, item.amount)
            end
        end

        table.insert(usedBy, identifier)
        MySQL.Async.execute("UPDATE kuban_comp SET used_by = @used_by WHERE code = @code", {
            ["@used_by"] = json.encode(usedBy),
            ["@code"] = code
        })

        SendNotification(src, "You have successfully claimed your compensation!", "success")

logToDiscord("✅ Compensation Claimed",
    ("**Player:** %s (ID: %d)\n**Code Used:** `%s`\n\n**Items Received:**\n%s")
    :format(GetPlayerName(src), src, code, formatItemsForLog(items)),
    65280)


        if #usedBy >= maxUses then
            deleteCompCode(code)
        end
    end)
end)

RegisterNetEvent("kuban-comp:server:FetchItems", function(searchTerm)
    local src = source
    local allItems = exports.ox_inventory:Items()
    local matches = {}
    for name, data in pairs(allItems) do
        if name:lower():find(searchTerm) then
            table.insert(matches, { name = name, label = data.label })
        end
    end
    TriggerClientEvent("kuban-comp:client:ShowSearchResults", src, matches)
end)

CreateThread(function()
    Wait(2000)
    MySQL.Async.fetchAll("SELECT * FROM kuban_comp", {}, function(result)
        if result then
            print("^2[KubanScripts] Loaded " .. #result .. " active compensation codes.^0")
        end
    end)
end)

QBCore.Functions.CreateCallback("kuban-comp:server:GetActiveCodes", function(_, cb)
    MySQL.Async.fetchAll("SELECT * FROM kuban_comp", {}, function(results)
        local formatted = {}
        for _, row in pairs(results or {}) do
            local usedBy = json.decode(row.used_by or "[]")
            local items = json.decode(row.items or "[]")
            local redeemsLeft = row.max_uses - #usedBy

            table.insert(formatted, {
                code = row.code,
                redeems_left = redeemsLeft,
                items = items
            })
        end
        cb(formatted)
    end)
end)

