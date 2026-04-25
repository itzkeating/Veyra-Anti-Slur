RegisterNetEvent("veyra:openUnbanMenu", function(bans)
    if not bans or #bans == 0 then
        lib.notify({
            title = "Veyra System",
            description = "There has been no bans placed.",
            type = "inform"
        })
        return
    end
    local options = {}
    for i, v in ipairs(bans) do
        options[#options + 1] = {
            title = v.name,
            description = v.reason,
            onSelect = function()
                TriggerServerEvent("veyra:unban", i)
            end
        }
    end
    lib.registerContext({
        id = "veyra_unban_menu",
        title = "Veyra Ban List",
        options = options
    })
    lib.showContext("veyra_unban_menu")
end)