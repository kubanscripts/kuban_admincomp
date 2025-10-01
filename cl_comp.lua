local selectedItems = {}
local QBCore = exports['qb-core']:GetCoreObject()

local function SendNotification(message, notifType)
    if Config.Notification == "qb" then
        TriggerEvent("QBCore:Notify", message, notifType)
    elseif Config.Notification == "ox" then
        lib.notify({ title = "Notification", description = message, position = 'center-left', type = notifType or "info" })
    elseif Config.Notification == "okok" then
        TriggerEvent("okokNotify:Alert", "Notification", message, 5000, notifType or "info")
    elseif Config.Notification == "qbx" then
        exports.qbx_core:Notify(message, notifType or "info")
    else
        print("^1[ERROR] Unknown notification system: " .. tostring(Config.Notification) .. "^0")
    end
end

local function openCompensationMenu()
    local options = {}
    table.insert(options, { title="Add Item", icon="plus", event="kuban-comp:client:SelectItem" })

    for _, item in ipairs(selectedItems) do
        table.insert(options, {
            title = string.format("%s x%d", item.name, item.amount),
            icon = "box", iconColor = "green",
            event = "kuban-comp:client:RemoveItem",
            args = item.name
        })
    end
    table.insert(options, {
        title="Create Compensation", icon="check",
        event="kuban-comp:client:ConfirmCompensation",
        disabled = #selectedItems == 0
    })

    lib.registerContext({
        id = "comp_create_menu",
        title = "Create Compensation",
        menu = "comp_main_menu",
        options = options
    })
    lib.showContext("comp_create_menu")
end

RegisterNetEvent("kuban-comp:client:OpenCompensationMenu", function()
    QBCore.Functions.TriggerCallback("kuban-comp:server:IsAdmin", function(isAdmin)
        local options = {}
        if isAdmin then
            table.insert(options, {
                title = "Create Compensation",
                icon = "plus",
                event = "kuban-comp:client:OpenCreateCompMenu"
            })
            table.insert(options, {
    title = "Active Codes",
    icon = "list",
    event = "kuban-comp:client:ViewActiveCodes"
})

        end
        lib.registerContext({
            id = "comp_main_menu",
            title = "Compensation System",
            options = options
        })
        lib.showContext("comp_main_menu")
    end)
end)


RegisterNetEvent("kuban-comp:client:ViewActiveCodes", function()
    QBCore.Functions.TriggerCallback("kuban-comp:server:GetActiveCodes", function(data)
        if not data or #data == 0 then
            SendNotification("There are no active compensation codes.", "info")
            return
        end

        local options = {}

        for _, entry in ipairs(data) do
            local itemList = {}
            for _, item in ipairs(entry.items) do
                table.insert(itemList, string.format("%s x%s", item.name, item.amount))
            end
            table.insert(options, {
                title = string.format("🟢 %s — %s left", entry.code, entry.redeems_left),
                description = table.concat(itemList, ", "),
                icon = "tag"
            })
        end

        lib.registerContext({
            id = "comp_active_codes",
            title = "Active Compensation Codes",
            menu = "comp_main_menu",
            options = options
        })

        lib.showContext("comp_active_codes")
    end)
end)

RegisterNetEvent("kuban-comp:client:OpenCreateCompMenu", function()
    openCompensationMenu()
end)

RegisterNetEvent("kuban-comp:client:SelectItem", function()
    local inputFields = {
        { type = "input", label = "Item Name", required = true },
        { type = "number", label = "Amount", required = true, min = 1 }
    }
    if Config.AskTicket then
        table.insert(inputFields, { type = "input", label = "Ticket Name", required = true })
    end
    if Config.MaxRedeems then
        table.insert(inputFields, { type = "number", label = "Max Redeems", required = true, min = 1 })
    end

    local input = lib.inputDialog("Select Item", inputFields)
    if input and input[1] and input[2] then
        local newItem = { name = input[1], amount = tonumber(input[2]) }
        local idx = 3
        if Config.AskTicket then
            newItem.ticket = input[idx]
            idx = idx + 1
        end
        if Config.MaxRedeems then
            newItem.max_uses = tonumber(input[idx])
        end
        table.insert(selectedItems, newItem)
        openCompensationMenu()
    end
end)

RegisterCommand("claim", function(source)
    TriggerEvent("kuban-comp:client:ClaimCompensation", source)
end, false)


RegisterNetEvent("kuban-comp:client:RemoveItem", function(itemName)
    for i, item in ipairs(selectedItems) do
        if item.name == itemName then
            table.remove(selectedItems, i)
            break
        end
    end
    openCompensationMenu()
end)

RegisterNetEvent("kuban-comp:client:ConfirmCompensation", function()
    if #selectedItems > 0 then
        local maxUses = selectedItems[1].max_uses or 1
        TriggerServerEvent("kuban-comp:server:CreateComp", selectedItems, maxUses)
        selectedItems = {}
        lib.hideContext()
    else
        SendNotification("You must select at least one item!", "error")
    end
end)

RegisterNetEvent("kuban-comp:client:ClaimCompensation", function()
    local input = lib.inputDialog("Enter Compensation Code", {
        { type = "input", label = "Compensation Code", required = true }
    })
    if input and input[1] then
        TriggerServerEvent("kuban-comp:server:ClaimComp", input[1])
    else
        SendNotification("Invalid code. Please try again.", "error")
    end
end)

RegisterNetEvent("kuban-comp:client:CopyCode", function(code)
    lib.setClipboard(code)
    SendNotification("Compensation code copied to clipboard: " .. code, "success")
end)
