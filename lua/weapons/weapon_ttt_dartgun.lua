if SERVER then
    AddCSLuaFile()
    resource.AddFile("materials/vgui/ttt/icon_dart.vmt")
end

SWEP.HoldType = "crossbow"

if CLIENT then
    SWEP.PrintName = "Poison Dartgun"

    SWEP.Slot = 7
    SWEP.Icon = "vgui/ttt/icon_dart"

    SWEP.EquipMenuData = {
        type = "Weapon",
        desc = "Silent dartgun that\n"
            .. "slowly kills the target\n"
            .. "over time."
    }
end

SWEP.Base = "weapon_tttbase"

SWEP.Kind         = WEAPON_EQUIP
SWEP.WeaponID     = AMMO_RIFLE
SWEP.CanBuy       = { ROLE_TRAITOR }
SWEP.LimitedStock = true

SWEP.IsSilent = true

SWEP.Primary.Delay       = 1.5
SWEP.Primary.Recoil      = 3
SWEP.Primary.Automatic   = false
SWEP.Primary.Cone        = 0.0
SWEP.Primary.ClipSize    = 1
SWEP.Primary.ClipMax     = 1 -- keep mirrored to ammo
SWEP.Primary.DefaultClip = 1

SWEP.StoredAmmo = 1

SWEP.AutoSpawnable = false
SWEP.Primary.Ammo  = "XBowBolt"
SWEP.ViewModel     = Model("models/weapons/v_crossbow.mdl")
SWEP.WorldModel    = Model("models/weapons/w_crossbow.mdl")

SWEP.ViewModelFlip = false
SWEP.ViewModelFOV  = 50

SWEP.Primary.Sound      = Sound("weapons/usp/usp1.wav")
SWEP.Primary.SoundLevel = 50
SWEP.Secondary.Sound    = Sound("Default.Zoom")

SWEP.IronSightsPos      = Vector(5, -15, -2)
SWEP.IronSightsAng      = Vector(2.6, 1.37, 3.5)

SWEP.PoisonedColor = Color(128, 255, 160, 255)

function SWEP:SetZoom(state)
    if CLIENT then
        return
    elseif IsValid(self.Owner) and self.Owner:IsPlayer() then
        if state then
            self.Owner:SetFOV(20, 0.3)
        else
            self.Owner:SetFOV(0, 0.2)
        end
    end
end

if SERVER then
    function SWEP:CreatePoisonedPlayerInfo(ply)
        local id = tostring(ply:UniqueID())

        return {
            player = ply,
            poisoner = self.Owner,
            effectTimerName = "PoisonEffect_" .. id,
            endTimerName = "PoisonEnd_" .. id,
        }
    end

    SWEP.PoisonedPlayers = nil

    function SWEP:Initialize()
        self.PoisonedPlayers = {}
    end

    function SWEP:PoisonPlayer(ply, duration)
        if self.PoisonedPlayers[ply] then return end
        if not IsValid(ply) or not IsValid(self.Owner) then return end
        if ply:IsTraitor() and self.Owner:IsTraitor() then return end

        local info = self:CreatePoisonedPlayerInfo(ply)

        self.PoisonedPlayers[ply] = info

        timer.Create(info.effectTimerName, 0.6, 0, function()
            self:PoisonEffects(ply)
        end)

        timer.Create(info.endTimerName, duration, 1, function()
            self:CurePlayer(ply)
        end)

        ply:SetColor(self.PoisonedColor)
    end

    function SWEP:CurePlayer(ply)
        if not IsValid(ply) then return end
        
        local info = self.PoisonedPlayers[ply]
        if not info then return end

        self.PoisonedPlayers[ply] = nil

        if timer.Exists(info.effectTimerName) then
            timer.Destroy(info.effectTimerName)
        end

        if timer.Exists(info.endTimerName) then
            timer.Destroy(info.endTimerName)
        end

        ply:SetColor(Color(255, 255, 255, 255))
    end

    function SWEP:PoisonEffects(ply)
        if not IsValid(ply) then return end

        local info = self.PoisonedPlayers[ply]
        if not info then return end
        
        if not ply:Alive() or GetRoundState() ~= ROUND_ACTIVE then
            self:CurePlayer(ply)
            return
        end

        if ply:Health() > 1 then
            ply:SetHealth(ply:Health() - 1)
            return
        end

        local attacker = info.poisoner         
        local dmginfo = DamageInfo()

        dmginfo:SetDamage(1)
        dmginfo:SetDamageType(DMG_POISON)
        dmginfo:SetAttacker(attacker)
        dmginfo:SetInflictor(self)
        
        ply:TakeDamageInfo(dmginfo)
        
        if not ply:Alive() then
            self:CurePlayer(ply)
        end
    end

    function SWEP:SpawnDart(trace)
        local dart = ents.Create("ttt_dart")

        local vec = self.Owner:GetAimVector()
        dart:SetPos(trace.HitPos - vec * 4)

        local ang = vec:Angle()
        dart:SetAngles(Angle(ang.r, ang.y + 90, ang.p))

        if trace.HitNonWorld and IsValid(trace.Entity) then
            dart:SetParent(trace.Entity)
        end

        dart.CanRetrieve = true
        dart:SetOwner(self.Owner)
        dart.fingerprints = { self.Owner }
        dart:SetNWBool("HasPrints", true)
        dart:Spawn()
    end

    function SWEP:OnRemove()
        for ply, info in pairs(self.PoisonedPlayers) do
            self:CurePlayer(ply)
        end
    end

    local swepTable = SWEP
    local oldCorpseCreate = CORPSE.Create
    function CORPSE.Create(ply, attacker, dmginfo)
        local convar = GetConVar("ttt_server_ragdolls")
        if convar and not convar:GetBool() then
            return oldCorpseCreate(ply, attacker, dmginfo)
        end

        local rag = oldCorpseCreate(ply, attacker, dmginfo)

        if not IsValid(rag) then return nil end

        if dmginfo:GetDamageType() == DMG_POISON then
            rag:SetColor(swepTable.PoisonedColor)

            rag.killer_sample = {
                killer     = attacker,
                killer_uid = attacker:UniqueID(),
                victim     = ply,
                t          = CurTime() + 10
            }
        else
            rag:SetColor(COLOR_WHITE)
        end

        return rag
    end

    function GAMEMODE:TTTPlayerSetColor(ply)
        ply:SetColor(COLOR_WHITE)
        ply:SetPlayerColor(Vector(1, 1, 1, 1))
    end
elseif CLIENT then
    function SWEP.PlayerMaterialOverride(ply)
        local mat = Material(ply:GetMaterials()[1])
        if not mat then return end

        mat:SetInt("$blendtintbybasealpha", 0)

        hook.Remove("PrePlayerDraw", "Dartgun_PlayerMaterialOverride")
    end

    local swepTable = SWEP
    function SWEP.TriggerPlayerMaterialOverride()
        hook.Add("PrePlayerDraw", "Dartgun_PlayerMaterialOverride", swepTable.PlayerMaterialOverride)
    end

    hook.Add("TTTBeginRound", "Dartgun_TriggerPlayerMaterialOverride", SWEP.TriggerPlayerMaterialOverride)
    SWEP.TriggerPlayerMaterialOverride()
end

function SWEP:Deploy()
    if self:Clip1() == 0 then
        self:SendWeaponAnim(ACT_VM_DRAW_EMPTY)
    else
        self:SendWeaponAnim(ACT_VM_DRAW)
    end
    return true
end

function SWEP:PrimaryAttack(worldsnd)
    self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    if not self:CanPrimaryAttack() or not IsValid(self.Owner) then return end
    
    self:SendWeaponAnim(self.PrimaryAnim)
    self.Owner:SetAnimation(PLAYER_ATTACK1)

    if not worldsnd then
        self.Weapon:EmitSound( self.Primary.Sound, self.Primary.SoundLevel )
    elseif SERVER then
        WorldSound(self.Primary.Sound, self:GetPos(), self.Primary.SoundLevel)
    end

    local bullet = {
        Num    = 1,
        Src    = self.Owner:GetShootPos(),
        Dir    = self.Owner:GetAimVector(),
        Spread = Vector(0, 0, 0),
        Tracer = 0,
        Force  = 0,
        Damage = 0
    }

    if SERVER then
        bullet.Callback = function(att, trace, dmginfo)
            if trace.HitNonWorld then
                target = trace.Entity
                if target:IsPlayer() then
                    self:PoisonPlayer(target, 120)
                else
                    if target:GetClass() == "ttt_health_station" then
                        --target:Poison(self)
                    end

                    self:SpawnDart(trace)
                end
            else
                self:SpawnDart(trace)
            end

            return { damage = false, effects = false }
        end
    end
    
    self.Owner:FireBullets(bullet)
    
    self:TakePrimaryAmmo(1)

    local owner = self.Owner   
    if owner:IsNPC() or not owner.ViewPunch then return end

    owner:ViewPunch(Angle(math.Rand(-0.2,-0.1) * self.Primary.Recoil, math.Rand(-0.1,0.1) *self.Primary.Recoil, 0))

    self:Reload()
end

function SWEP:SecondaryAttack()
    if not self.IronSightsPos then return end
    if self:GetNextSecondaryFire() > CurTime() then return end

    local bIronsights = not self:GetIronsights()

    self:SetIronsights(bIronsights)

    if SERVER then
        self:SetZoom(bIronsights)
    else
        self:EmitSound(self.Secondary.Sound)
    end

    self:SetNextSecondaryFire(CurTime() + 0.3)
    self:SetNextPrimaryFire(CurTime() + 0.5)
end

function SWEP:PreDrop()
    self:SetZoom(false)
    self:SetIronsights(false)
    return self.BaseClass.PreDrop(self)
end

function SWEP:Reload()
    if self:Clip1() == self.Primary.ClipSize
        or self.Owner:GetAmmoCount(self.Primary.Ammo) <= 0 then
        return
    end

    self:DefaultReload(ACT_VM_RELOAD)
    self:SetIronsights(false)
    self:SetZoom(false)
end

function SWEP:Holster()
    self:SetIronsights(false)
    self:SetZoom(false)
    return true
end

if CLIENT then
    local scope = surface.GetTextureID("sprites/scope")
    function SWEP:DrawHUD()
        if not self:GetIronsights() then
            return self.BaseClass.DrawHUD(self)
        end

        surface.SetDrawColor( 0, 0, 0, 255 )

        local x = ScrW() / 2.0
        local y = ScrH() / 2.0
        local scope_size = ScrH()

        -- crosshair
        local gap = 80
        local length = scope_size
        surface.DrawLine( x - length, y, x - gap, y )
        surface.DrawLine( x + length, y, x + gap, y )
        surface.DrawLine( x, y - length, x, y - gap )
        surface.DrawLine( x, y + length, x, y + gap )

        gap = 0
        length = 50
        surface.DrawLine( x - length, y, x - gap, y )
        surface.DrawLine( x + length, y, x + gap, y )
        surface.DrawLine( x, y - length, x, y - gap )
        surface.DrawLine( x, y + length, x, y + gap )


        -- cover edges
        local sh = scope_size / 2
        local w = (x - sh) + 2
        surface.DrawRect(0, 0, w, scope_size)
        surface.DrawRect(x + sh - 2, 0, w, scope_size)

        surface.SetDrawColor(255, 0, 0, 255)
        surface.DrawLine(x, y, x + 1, y + 1)

        -- scope
        surface.SetTexture(scope)
        surface.SetDrawColor(255, 255, 255, 255)

        surface.DrawTexturedRectRotated(x, y, scope_size, scope_size, 0)
    end

    function SWEP:AdjustMouseSensitivity()
        return (self:GetIronsights() and 0.2) or nil
    end
end
