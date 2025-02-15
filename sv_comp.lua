local QBCore = exports['qb-core']:GetCoreObject()
local webhookURL = 'YOUR_WEBHOOK_HERE'

---@return string code The generated code.
local function generateCompCode()
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local code = ""
    for i = 1, 5 do
        local rand = math.random(1, #charset)
        code = code .. string.sub(charset, rand, rand)
    end
    return code
end

---@param code string The generated compensation code.
---@param items table The list of items associated with the code.
local function saveCompCode(code, items)
    local itemsJSON = json.encode(items)
    MySQL.Async.execute("INSERT INTO kuban_comp (code, items) VALUES (@code, @items)", 
    {["@code"] = code, ["@items"] = itemsJSON},
    function(rowsChanged)
        if rowsChanged == 1 then
            print("^2[kuban-comp] Compensation saved successfully!^0")
        else
            print("^1[kuban-comp] Failed to save compensation!^0")
        end
    end)
end

---@param code string The compensation code to delete.
local function deleteCompCode(code)
    MySQL.Async.execute("DELETE FROM kuban_comp WHERE code = @code", {["@code"] = code})
end

---@param title string The title of the Discord embed.
---@param description string The description/body of the log.
---@param color number The color of the embed (e.g., success, warning, error).
local function logToDiscord(title, description, color)
    PerformHttpRequest(webhookURL, function(err, text, headers) end, "POST", 
    json.encode({
        embeds = {{
            ["title"] = title,
            ["description"] = description,
            ["color"] = color
        }}
    }), {["Content-Type"] = "application/json"})
end

---@param source number The player's server ID.
---@param message string The notification message.
---@param notifType string The notification type ("info", "error", "success").
local function SendNotification(source, message, notifType)
    if Config.Notification == "qb" then
        TriggerClientEvent("QBCore:Notify", source, message, notifType)
    elseif Config.Notification == "ox" then
        TriggerClientEvent("ox_lib:notify", source, {
            description = message,
            type = notifType or "info"
        })
    elseif Config.Notification == "okok" then
        TriggerClientEvent("okokNotify:Alert", source, "Notification", message, 5000, notifType or "info")
    elseif Config.Notification == "qbx" then
        exports.qbx_core:Notify(source, message, notifType or "info")
    else
        print("^1[ERROR] Unknown notification system configured: " .. Config.Notification .. "^0")
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

---@param items table The items to be included in the compensation.
RegisterNetEvent("kuban-comp:server:CreateComp", function(items)
    local src = source
    if not items or #items == 0 then return end

    local code = generateCompCode()
    saveCompCode(code, items)
    TriggerClientEvent("kuban-comp:client:CopyCode", src, code)

    logToDiscord("🎁 Compensation Created", 
        ("**Admin:** %s (ID: %d)\n**Items:** %s\n**Code:** %s")
        :format(GetPlayerName(src), src, json.encode(items), code), 
    3447003)
end)

---@param code string The compensation code entered by the player.
RegisterNetEvent("kuban-comp:server:ClaimComp", function(code)
    local src = source

    MySQL.Async.fetchAll("SELECT * FROM kuban_comp WHERE code = @code", {["@code"] = code}, function(result)
        if not result or #result == 0 then
            SendNotification(src, "Invalid or expired compensation code!", "error")
            return
        end

        local claimData = result[1]
        local items = json.decode(claimData.items)
        local Player = QBCore.Functions.GetPlayer(src)

        if Player then
            for _, item in ipairs(items) do
                if Config.Inventory == "qb" then
                    Player.Functions.AddItem(item.name, item.amount)
                    TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items[item.name], "add", item.amount)
                elseif Config.Inventory == "ox" then
                    exports.ox_inventory:AddItem(src, item.name, item.amount)
                elseif Config.Inventory == "qs" then
                    Player.Functions.AddItem(item.name, item.amount)
                    TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items[item.name], "add", item.amount)
                end
            end
        end

        deleteCompCode(code)
        SendNotification(src, "You have successfully claimed your compensation!", "success")

        logToDiscord("✅ Compensation Claimed", 
            ("**Player:** %s (ID: %d)\n**Items:** %s\n**Code Used:** %s")
            :format(GetPlayerName(src), src, json.encode(items), code), 
        65280)
    end)
end)

---@param searchTerm string The item name to search for.
RegisterNetEvent("kuban-comp:server:FetchItems", function(searchTerm)
    local src = source
    local allItems = exports.ox_inventory:Items()
    local matchingItems = {}

    for itemName, itemData in pairs(allItems) do
        if string.find(itemName:lower(), searchTerm) then
            table.insert(matchingItems, { name = itemName, label = itemData.label })
        end
    end

    TriggerClientEvent("kuban-comp:client:ShowSearchResults", src, matchingItems)
end)

CreateThread(function()
    Wait(2000)
    MySQL.Async.fetchAll("SELECT * FROM kuban_comp", {}, function(result)
        if result then
            print("^2[KubanScripts] Loaded " .. #result .. " active compensation codes from the database.^0")
        end
    end)
end)
