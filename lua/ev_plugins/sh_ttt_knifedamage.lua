local PLUGIN = {}

PLUGIN.Title = "TTT Knife Damage Override"
PLUGIN.Description = "Allows the knife's damage to be set by a ttt_knife_damage console command."
PLUGIN.Author = "Ziks"

CreateConVar("ttt_knife_damage", "50", { FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE }, "Base knife damage.")

function PLUGIN.OnValueChanged(cvarName, oldValue, newValue)
    local num = tonumber(newValue)
    if num == nil then return end

    num = math.Clamp(num, 1, 1000)

    local knife = weapons.GetStored("weapon_ttt_knife")
    knife.Primary.Damage = num

    local thrown = scripted_ents.GetStored("ttt_knife_proj")
    thrown.Damage = num
end

cvars.AddChangeCallback("ttt_knife_damage", PLUGIN.OnValueChanged)

evolve:RegisterPlugin(PLUGIN)
