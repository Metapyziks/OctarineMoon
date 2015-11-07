if SERVER then
    AddCSLuaFile()
    
    ENT.CanRetrieve = true
    ENT.CanUseKey = true
    ENT.UseOverride = true
else
    ENT.PrintName = "Poison Dart"
    ENT.Icon = "VGUI/ttt/icon_dart"
end

ENT.Type = "anim"
ENT.Model = Model("models/props_c17/TrapPropeller_Lever.mdl")
ENT.Sound = Sound("weapons/crossbow/hit1.wav")
ENT.CanHavePrints = true

function ENT:Initialize()
    self:SetModel(self.Model)
    self:PhysicsInit(SOLID_VPHYSICS)
    
    local b = 32
    self:SetCollisionBounds(Vector(-b, -b, -b), Vector(b,b,b))
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

    self:EmitSound(self.Sound, 50, 100)
    
    if SERVER then
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_BBOX)
    
        self:SetUseType(SIMPLE_USE)
    end
end

if SERVER then
    function ENT:UseOverride(ply)
        if self.CanRetrieve and ply:Alive() and ply:HasWeapon("weapon_ttt_dartgun") then
            ply:GiveAmmo(1, "XBowBolt")
            self:Remove()
        end
    end
end
