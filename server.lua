local bansFile = "bans.json"
local kicksFile = "kick.json"
local function loadBans()
    local data = LoadResourceFile(GetCurrentResourceName(), bansFile)
    if data and data ~= "" then
        local success, result = pcall(json.decode, data)
        if success then
            return result
        end
    end
    return {}
end

local function saveBans(bans)
    local success = SaveResourceFile(GetCurrentResourceName(), bansFile, json.encode(bans, { indent = true }), -1)
    if not success then
        print("^1[Veyra] Error saving bans.json^7")
    else
        print("^2[Veyra] Saved to bans.json^7")
    end
end

local function loadKicks()
    local data = LoadResourceFile(GetCurrentResourceName(), kicksFile)
    if data and data ~= "" then
        local success, result = pcall(json.decode, data)
        if success then
            return result
        end
    end
    return {}
end

local function saveKicks(kicks)
    local success = SaveResourceFile(GetCurrentResourceName(), kicksFile, json.encode(kicks, { indent = true }), -1)
    if not success then
        print("^1[Veyra] Error saving kick.json^7")
    else
        print("^2[Veyra] Saved to kick.json^7")
    end
end

local bans = loadBans()
local kicks = loadKicks()

local function getIdentifiers(src)
    local ids = {
        license = nil,
        steam = nil,
        discord = nil,
        fivem = nil
    }
    for _, v in pairs(GetPlayerIdentifiers(src)) do
        if string.find(v, "license:") then ids.license = v end
        if string.find(v, "steam:") then ids.steam = v end
        if string.find(v, "discord:") then ids.discord = v end
        if string.find(v, "fivem:") then ids.fivem = v end
    end

    return ids
end
AddEventHandler("chatMessage", function(src, name, msg)
    local lower = string.lower(msg)

    for _, word in pairs(Config.BlacklistedWords) do
        if string.find(lower, word) then
            TriggerEvent("veyra:banPlayer", src, msg)
            CancelEvent()
            return
        end
    end
end)

RegisterNetEvent("veyra:banPlayer")
AddEventHandler("veyra:banPlayer", function(src, message)
    local ids = getIdentifiers(src)
    local playerName = GetPlayerName(src)

    local banData = {
        name = playerName,
        identifiers = ids,
        reason = Config.BanReason,
        message = message,
        time = os.time()
    }

    if Config.Mode == "ban" then
        table.insert(bans, banData)
        saveBans(bans)
        DropPlayer(src, "You have been banned by Veyra Anti Slur System\nReason: " .. Config.BanReason .. "\nYou can only be unbanned by staff.")
    else
        table.insert(kicks, banData)
        saveKicks(kicks)
        DropPlayer(src, "You have been kicked by Veyra Anti Slur System\nReason: " .. Config.BanReason)
    end

    SendDiscordLog(banData)
end)

function SendDiscordLog(data)
    local title = Config.Mode == "kick" and "Veyra Blacklist Kick" or "Veyra Blacklist Ban"
    local embed = {
        {
            title = title,
            color = 16711680,
            thumbnail = { url = Config.Logo },
            fields = {
                { name = "Player", value = data.name, inline = true },
                { name = "Message", value = data.message, inline = false },
                { name = "License", value = data.identifiers.license or "N/A", inline = false },
                { name = "Steam", value = data.identifiers.steam or "N/A", inline = false },
                { name = "Discord", value = data.identifiers.discord or "N/A", inline = false },
                { name = "FiveM", value = data.identifiers.fivem or "N/A", inline = false }
            },
            footer = {
                text = os.date("%Y-%m-%d %H:%M:%S")
            }
        }
    }

    PerformHttpRequest(Config.Webhook, function(errorCode, resultData, resultHeaders)
        if errorCode ~= 204 then
            print("^1[Veyra] Webhook error: " .. errorCode .. "^7")
        else
            print("^2[Veyra] Webhook logged successfully^7")
        end
    end, "POST", json.encode({
        username = "Veyra AntiSlur System",
        embeds = embed
    }), { ["Content-Type"] = "application/json" })
end

AddEventHandler("playerConnecting", function(_, setKick, def)
    local src = source
    def.defer()

    if Config.Mode == "ban" then
        local ids = getIdentifiers(src)

        for _, ban in pairs(bans) do
            for _, id in pairs(ids) do
                if id and (
                    id == ban.identifiers.license or
                    id == ban.identifiers.steam or
                    id == ban.identifiers.discord or
                    id == ban.identifiers.fivem
                ) then
                    def.done("You are banned from Veyra\nReason: " .. ban.reason .. "\nOnly staff can unban you.")
                    return
                end
            end
        end
    end
    def.done()
end)