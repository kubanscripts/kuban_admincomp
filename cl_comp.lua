local selectedItems = {}
local QBCore = exports['qb-core']:GetCoreObject()

---@param message string The notification message.
---@param notifType string The notification type ("info", "error", "success").
local function SendNotification(message, notifType)
    if Config.Notification == "qb" then
        TriggerEvent("QBCore:Notify", message, notifType)
    elseif Config.Notification == "ox" then
        lib.notify({
            title = "Notification",
            description = message,
            type = notifType or "info"
        })
    elseif Config.Notification == "okok" then
        TriggerEvent("okokNotify:Alert", "Notification", message, 5000, notifType or "info")
    elseif Config.Notification == "qbx" then
        exports.qbx_core:Notify(message, notifType or "info")
    else
        print("^1[ERROR] Unknown notification system configured: " .. Config.Notification .. "^0")
    end
end
local function openCompensationMenu()
    local options = {}

    if Config.Inventory == "ox" then
        table.insert(options, {
            title = "Search Items",
            icon = "search",
            event = "kuban-comp:client:SearchItem"
        })
    end

    table.insert(options, {
        title = "Add Item",
        icon = "plus",
        event = "kuban-comp:client:SelectItem"
    })

    for _, item in ipairs(selectedItems) do
        table.insert(options, {
            title = string.format("%s x%d", item.name, item.amount),
            icon = "box",
            iconColor = "green",
            event = "kuban-comp:client:RemoveItem",
            args = item.name
        })
    end

    table.insert(options, {
        title = "Create Compensation",
        icon = "check",
        event = "kuban-comp:client:ConfirmCompensation",
        disabled = #selectedItems == 0
    })

    lib.registerContext({
        id = "comp_create_menu",
        title = "Create Compensation",
        menu = 'comp_main_menu',
        options = options
    })
    lib.showContext("comp_create_menu")
end

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
    local input = lib.inputDialog("Select Item", inputFields)
    if input and input[1] and input[2] then
        local newItem = { name = input[1], amount = tonumber(input[2]) }
        if Config.AskTicket and input[3] then
            newItem.ticket = input[3]
        end
        table.insert(selectedItems, newItem)
        openCompensationMenu()
    end
end)
RegisterNetEvent("kuban-comp:client:SearchItem", function()
    local input = lib.inputDialog("Search Item", {
        { type = "input", label = "Item Name", required = true }
    })

    if input and input[1] then
        TriggerServerEvent("kuban-comp:server:FetchItems", input[1]:lower())
    end
end)

---@param itemName string The name of the selected item.
RegisterNetEvent("kuban-comp:client:SearchItem", function()
    if Config.Inventory ~= "ox" then
        SendNotification("Item search is only available for Ox Inventory!", "error")
        return
    end

    local input = lib.inputDialog("Search Item", {
        { type = "input", label = "Item Name", required = true }
    })

    if input and input[1] then
        TriggerServerEvent("kuban-comp:server:FetchItems", input[1]:lower())
    end
end)
---@param items table The list of items found.
RegisterNetEvent("kuban-comp:client:ShowSearchResults", function(items)
    if Config.Inventory ~= "ox" then return end

    local options = {}

    if #items == 0 then
        table.insert(options, {
            title = "No items found",
            disabled = true
        })
    else
        for _, item in ipairs(items) do
            table.insert(options, {
                title = item.label,
                icon = "box",
                event = "kuban-comp:client:SelectSearchItem",
                args = item.name
            })
        end
    end

    lib.registerContext({
        id = "comp_search_results",
        title = "Search Results",
        options = options
    })
    lib.showContext("comp_search_results")
end)

RegisterNetEvent("kuban-comp:client:OpenCompensationMenu", function()
    QBCore.Functions.TriggerCallback("kuban-comp:server:IsAdmin", function(isAdmin)
        local options = {}
        if isAdmin then
            table.insert(options, {
                title = "Create Compensation",
                icon = "plus",
                event = "kuban-comp:client:OpenCreateCompMenu"
            })
        end
        table.insert(options, {
            title = "Claim Compensation",
            icon = "gift",
            event = "kuban-comp:client:ClaimCompensation"
        })
        lib.registerContext({
            id = "comp_main_menu",
            title = "Compensation System",
            options = options
        })
        lib.showContext("comp_main_menu")
    end)
end)

---@param itemName string The name of the item to remove.
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
        TriggerServerEvent("kuban-comp:server:CreateComp", selectedItems)
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
---@param code string The compensation code.
RegisterNetEvent("kuban-comp:client:CopyCode", function(code)
    lib.setClipboard(code)
    SendNotification("Compensation code copied to clipboard: " .. code, "success")
end)
