local QBCore = exports['qb-core']:GetCoreObject()
local webhookURL = Config.Webhook

local function generateCompCode()
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local code = ""
    for i = 1, 5 do
        local rand = math.random(1, #charset)
        code = code .. string.sub(charset, rand, rand)
    end
    return code
end

local function saveCompCode(code, item, amount)
    MySQL.Async.execute(
        "INSERT INTO kuban_comp (code, item, amount) VALUES (@code, @item, @amount)", 
        {
            ["@code"] = code,
            ["@item"] = item,
            ["@amount"] = amount
        }, function(rowsChanged)
            if rowsChanged == 1 then
                print("^2[kuban-comp] Compensation successfully saved to database!^0")
            else
                print("^1[kuban-comp] Failed to insert compensation into database!^0")
            end
        end
    )
end

local function deleteCompCode(code)
    MySQL.Async.execute("DELETE FROM kuban_comp WHERE code = @code", {["@code"] = code})
end

local function logToDiscord(title, description, color)
    PerformHttpRequest(webhookURL, function(err, text, headers)
        if err ~= 200 then
            print("^2[KubanScripts] Discord webhook Success^0")
        end
    end, "POST", json.encode({embeds = {{["title"] = title, ["description"] = description, ["color"] = color}}}), {["Content-Type"] = "application/json"})
end

QBCore.Commands.Add("createcomp", "Open the compensation menu", {}, true, function(source)
    TriggerClientEvent("kuban-comp:client:OpenCreateCompMenu", source)
end, "admin")

RegisterNetEvent("kuban-comp:server:CreateComp")
AddEventHandler("kuban-comp:server:CreateComp", function(selectedItem, selectedAmount)
    local source = source
    if not selectedItem or not selectedAmount then return end

    selectedAmount = tonumber(selectedAmount)
    local code = generateCompCode()
    saveCompCode(code, selectedItem, selectedAmount)
    TriggerClientEvent("kuban-comp:client:CopyCode", source, code)
    TriggerClientEvent("QBCore:Notify", source, "Compensation created! Code copied to clipboard.", "success")
    logToDiscord("🎁 Compensation Created", 
        "**Admin:** " .. GetPlayerName(source) .. " (ID: " .. source .. ")\n" ..
        "**Item:** " .. selectedItem .. "\n" ..
        "**Amount:** " .. selectedAmount .. "\n" ..
        "**Code:** " .. code, 
    3447003)
end)

QBCore.Commands.Add("claimcomp", "Claim a compensation reward", {
    {name = "code", help = "Compensation Code"}
}, false, function(source, args)
    local code = args[1]

    MySQL.Async.fetchAll("SELECT * FROM kuban_comp WHERE code = @code", {["@code"] = code}, function(result)
        if not result or #result == 0 then
            TriggerClientEvent("QBCore:Notify", source, "Invalid or expired compensation code!", "error")
            return
        end
        local claimData = result[1]
        local item = claimData.item
        local amount = claimData.amount
        local Player = QBCore.Functions.GetPlayer(source)

        if Player then
            if Config.Inventory == "qb" then
                Player.Functions.AddItem(item, amount)
                TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items[item], "add", amount)
            elseif Config.Inventory == "ox" then
                exports.ox_inventory:AddItem(source, item, amount)
                TriggerClientEvent("ox_inventory:notify", source, "Added " .. amount .. "x " .. item, "success")
            end
        end

        deleteCompCode(code)
        TriggerClientEvent("QBCore:Notify", source, "You have successfully claimed your compensation!", "success")
        logToDiscord("✅ Compensation Claimed", 
            "**Player:** " .. GetPlayerName(source) .. " (ID: " .. source .. ")\n" ..
            "**Item:** " .. item .. "\n" ..
            "**Amount:** " .. amount .. "\n" ..
            "**Code Used:** " .. code, 
        65280)
    end)
end)

CreateThread(function()
    Wait(2000) 
    MySQL.Async.fetchAll("SELECT * FROM kuban_comp", {}, function(result)
        if result then
            print("^2[KubanScripts] Loaded " .. #result .. " active compensation codes from the database.^0")
        end
    end)
end)
