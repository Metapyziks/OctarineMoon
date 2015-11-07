local PLUGIN = {}

PLUGIN.Title = "TTT Get Traitors"
PLUGIN.Description = "Allows spectating players to discover who the traitors are."
PLUGIN.Author = "Ziks"
PLUGIN.ChatCommand = "gettraitors"
PLUGIN.Privileges = { "Get Traitors" }

if SERVER then
    function PLUGIN:Call(ply, args)
        if not ply:EV_HasPrivilege("Get Traitors") then
            evolve:Notify(ply, evolve.colors.red, evolve.constants.notallowed)
            return
        end

        if ply:Alive() and ply:IsTerror() then
            evolve:Notify( ply, evolve.colors.red, "You can't check who is traitor while you are playing!" )
            return
        end

        local traitors = {}
        for _, pl in ipairs(player.GetAll()) do
            if pl:IsTraitor() and pl:Alive() then
                table.insert(traitors, pl)
            end
        end
        
        evolve:Notify(ply, evolve.colors.red,
            evolve:CreatePlayerList(traitors),
            evolve.colors.white, " is a traitor!")
    end
end

evolve:RegisterPlugin(PLUGIN)
