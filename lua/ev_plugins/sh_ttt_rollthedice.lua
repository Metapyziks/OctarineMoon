local PLUGIN = {}

PLUGIN.Title = "TTT Roll the Dice"
PLUGIN.Description = "Roll the dice and see what happens!"
PLUGIN.Author = "Overv, modified by Ziks"
PLUGIN.ChatCommand = "rtd"
PLUGIN.Privileges = { "Roll the Dice" }
PLUGIN.Override = "Roll the Dice"

if SERVER then
    local function CanPlayerRtd(ply)
        return IsValid(ply) and ply:EV_HasPrivilege("Roll the Dice")
            and ply:IsTerror() and GetRoundState() ~= ROUND_PREP
    end

    function PLUGIN:Call(ply, args)
        if not CanPlayerRtd(ply) then
            evolve:Notify(ply, evolve.colors.red, evolve.constants.notallowed)
            return
        end

        if (ply.EV_NextDiceRoll or 0) >= CurTime() then
            evolve:Notify(ply, evolve.colors.red, "Wait a little longer before rolling the dice again!")
            return
        end

        evolve:Notify(evolve.colors.blue, ply:Nick(),
            evolve.colors.white, " has rolled the dice and ",
            evolve.colors.red, self:RollTheDice(ply),
            evolve.colors.white, "!")

        ply.EV_NextDiceRoll = CurTime() + 60

        timer.Simple(60, function()
            if not CanPlayerRtd(ply) then return end
            evolve:Notify(ply, evolve.colors.blue, "You may now roll the dice!")
        end)
    end

    function PLUGIN:PlayerSpawn(ply)
        ply.EV_ProvenInnocent = false
    end

    local rtdWeapons = {
        { "weapon_ttt_health_station",  "Health Station"    },
        { "weapon_ttt_teleport",        "Teleporter"        },
        { "weapon_ttt_stungun",         "UMP Prototype"     },
        
        { "weapon_ttt_m16",             "M16"               },
        { "weapon_zm_mac10",            "MAC10"             },
        { "weapon_zm_rifle",            "Rifle"             },
        { "weapon_zm_shotgun",          "Shotgun"           },
        { "weapon_zm_pistol",           "Pistol"            },
        { "weapon_zm_revolver",         "Deagle"            },
        { "weapon_zm_sledge",           "H.U.G.E-249"       }
    }

    -- { predicate, effect }
    local rtdOutcomes = {
        {
            function(ply) return ply:Health() < 100 end,
            function(ply)
                local hp = math.random(1, 10) * 5
                if hp + ply:Health() >= 100 then
                    hp = 100 - ply:Health()
                end
                
                ply:SetHealth(ply:Health() + hp)
                
                return "received " .. hp .. " health"
            end
        },
        {
            function(ply) return true end,
            function(ply)
                local hp = math.random(1, 10) * 5
                if hp >= ply:Health() then
                    hp = ply:Health() - 1
                end
                
                ply:SetHealth(ply:Health() - hp)
                
                return "lost " .. hp .. " health"
            end
        },
        {
            function(ply)
                if ply:IsTraitor() then return false end

                local proven, tot = 0, 0
                for _, pl in ipairs(player.GetAll()) do
                    if pl:IsTerror() and not pl:IsTraitor() then
                        tot = tot + 1
                        if pl.EV_ProvenInnocent then
                            proven = proven + 1
                        end
                    end
                end

                return not ply.EV_ProvenInnocent
                    and proven / tot <= 0.333
                    and math.random(1, 4) == 1
            end,
            function(ply)
                ply.EV_ProvenInnocent = true
                return "was proven innocent"
            end
        },
        {
            function(ply) return true end,
            function(ply)
                local hasTester = false
            
                if ply:HasWeapon("weapon_ttt_wtester") then
                    hasTester = true
                end
            
                ply:StripWeapons()
                ply:Give("weapon_zm_improvised")
                ply:Give("weapon_ttt_unarmed")
                ply:Give("weapon_zm_carry")
                
                if hasTester then
                    ply:Give("weapon_ttt_wtester")
                end
                
                return "had their weapons stripped"
            end
        },
        {
            function(ply) return true end,
            function(ply)
                if ply:IsTraitor() or ply:IsActiveDetective() then
                    ply:AddCredits(1)
                    if ply:IsActiveDetective() then
                        return "received a credit"
                    else
                        evolve:Notify(ply, evolve.colors.red,
                            "You secretly received an equiptment credit!")
                    end
                end
                
                return "got nothing"
            end
        },
        {
            function(ply) return true end,
            function(ply)
                local canReceive = {}

                for _, weapon in ipairs(rtdWeapons) do
                    if not ply:HasWeapon(weapon[1]) then
                        table.insert(canReceive, weapon)
                    end
                end

                local received = table.Random(canReceive)
                
                weapon = ents.Create(received[1])
                weapon:SetPos(ply:GetPos())
                weapon:Spawn()
                
                return "received a " .. received[2]
            end
        },
        {
            function(ply) return true end,
            function(ply)
                ply:Lock()
                timer.Simple(math.random(10, 15), function()
                    if IsValid(ply) then ply:UnLock() end
                end)
                
                return "lost the ability to move for some time"
            end
        }
    }

    function PLUGIN:RollTheDice(ply)
        local canHappen = {}

        for _, outcome in ipairs(rtdOutcomes) do
            if outcome[1](ply) then
                table.insert(canHappen, outcome)
            end
        end

        if #canHappen == 0 then
            return "got nothing"
        end

        return table.Random(canHappen)[2](ply)
    end
end

evolve:RegisterPlugin(PLUGIN)
