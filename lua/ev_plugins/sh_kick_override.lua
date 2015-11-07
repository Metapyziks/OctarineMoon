/*-------------------------------------------------------------------------------------------------------------------------
    Kick a player
-------------------------------------------------------------------------------------------------------------------------*/

local PLUGIN = {}
PLUGIN.Title = "Kick Override"
PLUGIN.Override = "Kick"

function PLUGIN:Call( ply, args )
    if ( ply:EV_HasPrivilege( "Kick" ) ) then
        local pl = evolve:FindPlayer( args[1] )
        
        if ( #pl > 1 ) then
            evolve:Notify( ply, evolve.colors.white, "Did you mean ", evolve.colors.red, evolve:CreatePlayerList( pl, true ), evolve.colors.white, "?" )
        elseif ( #pl == 1 ) then
            if ( ply:EV_BetterThan( pl[1] ) ) then
                local reason = table.concat( args, " ", 2 ) or ""
                
                for _, v in ipairs( ents.GetAll() ) do
                    if ( v:EV_GetOwner() == pl[1]:UniqueID() ) then v:Remove() end
                end
                
                if ( #reason == 0 || reason == "No reason" ) then
                    evolve:Notify( evolve.colors.blue, ply:Nick(), evolve.colors.white, " has kicked ", evolve.colors.red, pl[1]:Nick(), evolve.colors.white, "." )
                    
                    if ( gatekeeper ) then
                        gatekeeper.Drop( pl[1]:UserID(), "Kicked without a reason." )
                    else
                        pl[1]:Kick( "No reason specified." )
                        ziksnet.LogAdminAction( "Kick", ply, pl[1], "" )
                    end
                else
                    evolve:Notify( evolve.colors.blue, ply:Nick(), evolve.colors.white, " has kicked ", evolve.colors.red, pl[1]:Nick(), evolve.colors.white, " with the reason \"" .. reason .."\"." )
                    
                    if ( gatekeeper ) then
                        gatekeeper.Drop( pl[1]:UserID(), "Kicked: " .. reason )
                    else
                        pl[1]:Kick( reason )
                        ziksnet.LogAdminAction( "Kick", ply, pl[1], reason )
                    end
                end
            else
                evolve:Notify( ply, evolve.colors.red, evolve.constants.noplayers2 )
            end
        else
            evolve:Notify( ply, evolve.colors.red, evolve.constants.noplayers )
        end
    else
        evolve:Notify( ply, evolve.colors.red, evolve.constants.notallowed )
    end
end

evolve:RegisterPlugin( PLUGIN )
