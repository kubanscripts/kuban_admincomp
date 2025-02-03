local selectedItem = nil
local selectedAmount = nil
local selectedPlayer = nil

RegisterNetEvent("kuban-comp:client:OpenCreateCompMenu")
AddEventHandler("kuban-comp:client:OpenCreateCompMenu", function()
    openCompensationMenu()
end)

-- 📜 Open Compensation Menu
function openCompensationMenu()
    local options = {
        {
            title = "Item: " .. (selectedItem or "Not Set"),
            icon = "box",
            iconColor = selectedItem and "green" or "red",
            event = "kuban-comp:client:SelectItem"
        },
        {
            title = "Amount: " .. (selectedAmount or "Not Set"),
            icon = "hashtag",
            iconColor = selectedAmount and "green" or "red",
            event = "kuban-comp:client:SelectAmount"
        },
        {
            title = "Create Compensation",
            icon = "plus",
            iconColor = (selectedItem and selectedAmount) and "green" or "red",
            event = "kuban-comp:client:ConfirmCompensation",
            disabled = (not selectedItem or not selectedAmount)
        }
    }

    lib.registerContext({
        id = "comp_main_menu",
        title = "Create Compensation",
        options = options
    })
    lib.showContext("comp_main_menu")
end

-- 📜 Select Item
RegisterNetEvent("kuban-comp:client:SelectItem")
AddEventHandler("kuban-comp:client:SelectItem", function()
    local input = lib.inputDialog("Select Item", {
        { type = "input", label = "Item Name", required = true }
    })
    
    if input and input[1] then
        selectedItem = input[1]
        openCompensationMenu()
    end
end)

-- 📜 Select Amount
RegisterNetEvent("kuban-comp:client:SelectAmount")
AddEventHandler("kuban-comp:client:SelectAmount", function()
    local input = lib.inputDialog("Select Amount", {
        { type = "number", label = "Amount", required = true, min = 1 }
    })
    
    if input and input[1] then
        selectedAmount = input[1]
        openCompensationMenu()
    end
end)


-- 📜 Set Selected Player (Online)
RegisterNetEvent("kuban-comp:client:SetPlayer")
AddEventHandler("kuban-comp:client:SetPlayer", function(playerId)
    selectedPlayer = playerId
    openCompensationMenu()
end)

-- 📜 Select Offline Player
RegisterNetEvent("kuban-comp:client:SelectOfflinePlayer")
AddEventHandler("kuban-comp:client:SelectOfflinePlayer", function()
    local input = lib.inputDialog("Enter Offline Player ID", {
        { type = "number", label = "Player ID", required = true }
    })

    if input and input[1] then
        selectedPlayer = input[1]
        openCompensationMenu()
    end
end)

-- 📜 Confirm Compensation & Trigger Server Event
RegisterNetEvent("kuban-comp:client:ConfirmCompensation")
AddEventHandler("kuban-comp:client:ConfirmCompensation", function()
    if selectedItem and selectedAmount then
        TriggerServerEvent("kuban-comp:server:CreateComp", selectedItem, selectedAmount) -- ✅ Corrected event trigger
    else
        TriggerEvent("QBCore:Notify", "All fields must be filled!", "error")
    end
end)

-- 📜 Copy Code to Clipboard
RegisterNetEvent("kuban-comp:client:CopyCode")
AddEventHandler("kuban-comp:client:CopyCode", function(code)
    lib.setClipboard(code)
    TriggerEvent("QBCore:Notify", "Compensation code copied to clipboard: " .. code, "success")
end)
