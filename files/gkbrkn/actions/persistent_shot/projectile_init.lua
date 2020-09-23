dofile_once( "mods/gkbrkn_noita/files/gkbrkn/lib/variables.lua");
dofile_once( "mods/gkbrkn_noita/files/gkbrkn/helper.lua");
local entity = GetUpdatedEntityID();
local projectile = EntityGetFirstComponentIncludingDisabled( entity, "ProjectileComponent" );
if projectile ~= nil then
    local keep = false;
    local shooter = ComponentGetValue2( projectile, "mWhoShot" ) or 0;
    local active_wand = WandGetActive( shooter );
    if active_wand ~= nil then
        local aim_angle = 0;
        local controls = EntityGetFirstComponentIncludingDisabled( entity, "ControlsComponent" );
        if controls then
            local ax, ay = ComponentGetValue2( component, "mAimingVector" );
            aim_angle = math.atan2( ay, ax );
        end
        local velocity = EntityGetFirstComponentIncludingDisabled( entity, "VelocityComponent" );
        local magnitude = 0;
        if velocity ~= nil then
            local vx, vy = ComponentGetValue2( velocity, "mVelocity" );
            magnitude = math.sqrt( vx * vx + vy * vy ) / 60;
        end
        local x, y, angle = EntityGetTransform( entity );
        angle = aim_angle - angle;
        local wx, wy = EntityGetTransform( active_wand );
        EntitySetVariableNumber( entity, "gkbrkn_magic_hand_angle", angle );
    end
end