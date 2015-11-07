local PLUGIN = {}

PLUGIN.Title = "TTT Punchometre Boost"
PLUGIN.Description = "Add a punchometre boost permission."
PLUGIN.Author = "Ziks"
PLUGIN.Privileges = { "Infinite Punchometre", "Boosted Punchometre" }

PLUGIN.LastThink = 0
PLUGIN.Spectated = {}

function PLUGIN:PostGamemodeLoaded()
    -- Override some TTT functions
    
    local propspec_toggle = GetConVar("ttt_spec_prop_control")

    local propspec_base = GetConVar("ttt_spec_prop_base")
    local propspec_min = GetConVar("ttt_spec_prop_maxpenalty")
    local propspec_max = GetConVar("ttt_spec_prop_maxbonus")
    
    local model_blacklist = {
        "models/props_c17/oildrum001_explosive.mdl"
    }
    
    local function IsWhitelistedClass(cls)
        return string.match(cls, "prop_physics*") or
            string.match(cls, "func_physbox*")
    end
    
    local function IsBlacklistedModel(mdl)
        return not mdl == nil and table.HasValue(model_blacklist, mdl)
    end

    function PROPSPEC.Target(ply, ent)
        if not propspec_toggle:GetBool() then return end
        if not IsValid(ply) or not ply:IsSpec() or not IsValid(ent) then return end

        if IsValid(ent:GetNWEntity("spec_owner", nil)) then return end

        local phys = ent:GetPhysicsObject()

        if ent:GetName() != "" and not GAMEMODE.propspec_allow_named then return end
        if not IsValid(phys) or not phys:IsMoveable() then return end

        -- normally only specific whitelisted ent classes can be possessed, but
        -- custom ents can mark themselves possessable as well
        if not ent.AllowPropspec and not IsWhitelistedClass(ent:GetClass() or IsBlacklistedModel(ent:GetModel())) then return end

        PROPSPEC.Start(ply, ent)
    end
    
    function PROPSPEC.Start(ply, ent)
        ply:Spectate(OBS_MODE_CHASE)
        ply:SpectateEntity(ent, true)

        local bonus = math.Clamp(math.ceil(ply:Frags() / 2), propspec_min:GetInt(), propspec_max:GetInt())

        local startPunches = 0
        local maxPunches = propspec_base:GetInt() + bonus

        if ply:EV_HasPrivilege("Infinite Punchometre") then
            startPunches = maxPunches
        end

        ply.propspec = {
            ent = ent,
            t = 0,
            retime = 0,
            punches = startPunches,
            max = maxPunches
        }

        ent:SetNWEntity("spec_owner", ply)
        table.insert(PLUGIN.Spectated, ent)
        ent.spectated = true
        ply:SetNWInt("bonuspunches", bonus)
    end
    
    local propspec_force = GetConVar("ttt_spec_prop_force")
    local propspec_boosted_force = CreateConVar("ttt_spec_prop_boosted_force", "110")
    
    function PROPSPEC.Key(ply, key)
        local ent = ply.propspec.ent
        local phys = IsValid(ent) and ent:GetPhysicsObject()
        if not IsValid(ent) or not IsValid(phys) then 
            PROPSPEC.End(ply)
            return false
        end

        if not phys:IsMoveable() then
            PROPSPEC.End(ply)
            return true
        elseif phys:HasGameFlag(FVPHYSICS_PLAYER_HELD) then
            -- we can stay with the prop while it's held, but not affect it
            if key == IN_DUCK then
                PROPSPEC.End(ply)
            end
            return true
        end

        -- always allow leaving
        if key == IN_DUCK then
            PROPSPEC.End(ply)
            return true
        end

        local pr = ply.propspec
        if pr.t > CurTime() then return true end

        if pr.punches < 1 then return true end

        local m = math.min(150, phys:GetMass())
        local force = propspec_force:GetInt()

        if ply:EV_HasPrivilege("Boosted Punchometre") then
            force = propspec_boosted_force:GetInt()
        end

        local aim = ply:GetAimVector()

        local mf = m * force

        pr.t = CurTime() + 0.15

        if key == IN_JUMP then
            -- upwards bump
            phys:ApplyForceCenter(Vector(0,0, mf))
            pr.t = CurTime() + 0.05
        elseif key == IN_FORWARD then
            -- bump away from player
            phys:ApplyForceCenter(aim * mf)
        elseif key == IN_BACK then
            phys:ApplyForceCenter(aim * (mf * -1))
        elseif key == IN_MOVELEFT then
            phys:AddAngleVelocity(Vector(0, 0, 200))
            phys:ApplyForceCenter(Vector(0,0, mf / 3))
        elseif key == IN_MOVERIGHT then
            phys:AddAngleVelocity(Vector(0, 0, -200))
            phys:ApplyForceCenter(Vector(0,0, mf / 3))
        else
            return true -- eat other keys, and do not decrement punches
        end

        if not ply:EV_HasPrivilege("Infinite Punchometre") then
            pr.punches = math.max(pr.punches - 1, 0)
        else
            pr.punches = pr.max
        end
        ply:SetNWFloat("specpunches", pr.punches / pr.max)

        return true
    end
end

function PLUGIN:Think()
    local curtime = CurTime()
    if curtime - self.LastThink > 1.0 then
        self.LastThink = curtime
        
        local ended = {}
        for i, ent in ipairs(self.Spectated) do
            local rem = false
            if not ent:IsValid() then
                rem = true
            else
                local ply = ent:GetNWEntity("spec_owner")
                if not ply or not ply:IsValid() then
                    local phys = ent:GetPhysicsObject()
                    if not phys:IsValid() or phys:IsAsleep() then
                        rem = true
                    end
                end
            end
            
            if rem then
                ent.spectated = false
                table.insert(ended, i - #ended)
            end
        end
        
        for _, i in ipairs(ended) do
            table.remove(self.Spectated, i)
        end
    end
end

local propspec_dmgscale = CreateConVar("ttt_spec_prop_damage_scale", "0")
function PLUGIN:EntityTakeDamage(ent, dmginfo)
    local inflictor = dmginfo:GetInflictor()

    if not IsValid(inflictor)
        or inflictor:IsWorld()
        or inflictor:IsPlayer()
        or inflictor:IsWeapon()
        or not inflictor.spectated then
        return
    end
    
    dmginfo:ScaleDamage(propspec_dmgscale:GetFloat())
end

evolve:RegisterPlugin(PLUGIN)
