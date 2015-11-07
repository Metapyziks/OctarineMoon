ziksnet = ziksnet or {}

local secret = CreateConVar("sv_ziksnet_secret", "",
    { FCVAR_PROTECTED, FCVAR_SERVER_CAN_EXECUTE, FCVAR_UNLOGGED },
    "Ziks.net webhook secret.")

function ziksnet.Post(action, params, onSuccess, onFailure)
    params = params or {}
    params.action = action
    params.secret = secret:GetString()

    http.Post("http://localhost/webhooks/evolve", params, onSuccess, onFailure)
end

function ziksnet.Fetch(action, onSuccess, onFailure)
    ziksnet.Post(action, {}, onSuccess, onFailure)
end

function ziksnet.LogPlayerCount(count)
    ziksnet.Post("player-count", { value = tostring(count) })
end

function ziksnet.LogMapChange(mapName, votedFor)
    ziksnet.Post("map-change", { map_name = mapName, voted_for = tostring(votedFor ~= false) })
end

function ziksnet.LogAdminAction(type, admin, ply, reason, data)
    if not IsValid(admin) or not IsValid(ply) then return end

    data = data or {}

    data.admin_id = tostring(admin:SteamID64())
    data.player_id = tostring(ply:SteamID64())

    data.type = type
    data.reason = reason

    ziksnet.Post("admin-action", data)
end

local PLUGIN = {}

PLUGIN.Title = "Ziks.net Webhook Communication"
PLUGIN.Description = "Some functions for posting data to / querying Ziks.net."
PLUGIN.Author = "Ziks"

function PLUGIN:PlayerInitialSpawn(ply)
    ziksnet.LogPlayerCount(#player.GetHumans())
end

function PLUGIN:PlayerDisconnected(ply)
    local players = player.GetHumans()
    if not table.HasValue(players, ply) then
        ziksnet.LogPlayerCount(#players)
    else
        ziksnet.LogPlayerCount(#players - 1)
    end
end

PLUGIN.InitialLogSent = false

function PLUGIN:Think()
    if not self.InitialLogSent then
        self.InitialLogSent = true

        ziksnet.LogMapChange(game.GetMap(), false)
        ziksnet.LogPlayerCount(#player.GetHumans())
    end
end

function PLUGIN:MapVoteChange(map)
    ziksnet.LogMapChange(map, true)
end

local origBan = evolve.Ban
function evolve:Ban(uid, length, reason, adminuid)
    local ply = player.GetByUniqueID(uid)
    local admin = player.GetByUniqueID(adminuid)

    ziksnet.LogAdminAction("Ban", admin, ply, reason, { duration = length })

    origBan(self, uid, length, reason, adminuid)
end

evolve:RegisterPlugin(PLUGIN)
