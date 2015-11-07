local PLUGIN = {}

PLUGIN.Title = "TTT Damage Log"
PLUGIN.Description = "Outputs the previous round's damage log."
PLUGIN.Author = "Ziks"
PLUGIN.ChatCommand = "damagelog"
PLUGIN.Usage = "[<all | ff> [player]]"

if SERVER then
    function PLUGIN:Call(ply, args)
        if not IsValid(ply) or ply:IsSuperAdmin() or GetRoundState() ~= ROUND_ACTIVE then
            ply:ConCommand("ttt_print_damagelog " .. table.concat(args, " "))
            evolve:Notify(ply, evolve.colors.white, "Damage log printed to console.")
        else
            evolve:Notify(ply, evolve.colors.red, "You are not allowed to print the damage log until the round ends!")
        end
    end
end

evolve:RegisterPlugin(PLUGIN)
