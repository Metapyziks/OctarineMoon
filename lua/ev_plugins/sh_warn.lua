local PLUGIN = {}

PLUGIN.Title = "Warn"
PLUGIN.Description = "Warn a player and force them to skip a round."
PLUGIN.Author = "Ziks"
PLUGIN.ChatCommand = "warn"
PLUGIN.Usage = "<player> [skipround (1/0)] [reason]"
PLUGIN.Privileges = { "Warn" }
PLUGIN.SlayNextRound = {}

function PLUGIN:Warn(admin, ply, reason, skipround)
    reason = reason or "unacceptable behaviour"
    
    if not skipround and self.SlayNextRound[ply:UniqueID()] then
        self.SlayNextRound[ply:UniqueID()] = nil

        evolve:Notify(evolve.colors.blue, admin:Nick(),
            evolve.colors.white, " has allowed ",
            evolve.colors.red, ply:Nick(),
            evolve.colors.white, " to take part in the next round.")

        return
    end

    evolve:Notify(evolve.colors.blue, admin:Nick(),
        evolve.colors.white, " warned ",
        evolve.colors.red, ply:Nick(),
        evolve.colors.white, " for ",
        evolve.colors.red, reason,
        evolve.colors.white, "." )

    if skipround then
        evolve:Notify(evolve.colors.red, ply:Nick(),
            evolve.colors.white, " will not take part in the next round.")

        self.SlayNextRound[ply:UniqueID()] = reason
    end

    if ziksnet then
        ziksnet.LogAdminAction("Warn", admin, ply, reason, { skip_round = tostring(skipround) })
    end
end

if SERVER then
    function PLUGIN:Call(ply, args)
        if not ply:EV_HasPrivilege("Warn") then
            evolve:Notify(ply, evolve.colors.red, evolve.constants.notallowed)
        end

        local pl = evolve:FindPlayer(args[1])
        
        if #pl > 1 then
            evolve:Notify(ply,
                evolve.colors.white, "Did you mean ",
                evolve.colors.red, evolve:CreatePlayerList(pl, true),
                evolve.colors.white, "?")
            return
        elseif #pl == 1 then
            pl = pl[1]
        else
            evolve:Notify(ply, evolve.colors.red, evolve.constants.noplayers)
            return
        end
        
        local skipround = (args[2] or "1") ~= "0"
        local reason = nil

        if #args >= 2 then
            local start = 3
            if not args[2] == "1" and not args[2] == "0" then start = 2 end
            for k, v in ipairs(args) do
                if k == start then
                    reason = v
                elseif reason then
                    reason = reason .. " " .. v
                end
            end
        end
        
        self:Warn(ply, pl, reason, skipround)
    end
end

function PLUGIN:Menu(arg, players)
    if arg then
        RunConsoleCommand("ev", "warn", players[1], arg)
    else
        return "Warn", evolve.category.administration, {
            { "RDMing", { 1, "random death matching" } },
            { "Mic Spam", { 1, "mic spamming" } },
            { "Rude to Players", { 1, "being rude to players" } }
        }
    end
end

if SERVER then
    function PLUGIN.ClearWarnings()
        PLUGIN.SlayNextRound = {}
    end

    function PLUGIN:PostGamemodeLoaded()
        local plymeta = FindMetaTable("Player")
        if not plymeta then return end

        function plymeta:WasWarned()
            return PLUGIN.SlayNextRound[self:UniqueID()] ~= nil
        end

        local origSpawnForRound = plymeta.SpawnForRound
        function plymeta:SpawnForRound(dead_only)
            if self:WasWarned() then
                local reason = PLUGIN.SlayNextRound[self:UniqueID()]

                evolve:Notify(evolve.colors.red, self:Nick(),
                    evolve.colors.white, " will not take part in this round due to ",
                    evolve.colors.red, reason, evolve.colors.white, "." )
                
                if self:Alive() then
                    self:Kill()
                end
                
                self:SetNWBool("body_found", true)
                
                return false
            end
        
            return origSpawnForRound(self, dead_only)
        end

        local origShouldSpawn = plymeta.ShouldSpawn
        function plymeta:ShouldSpawn()
            if self:WasWarned() then return false end
            return origShouldSpawn(self)
        end
        
        hook.Add("TTTBeginRound", "ClearWarnings", PLUGIN.ClearWarnings)
    end
end

evolve:RegisterPlugin(PLUGIN)
