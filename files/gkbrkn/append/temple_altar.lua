local MISC = dofile_once( "mods/gkbrkn_noita/files/gkbrkn/lib/options.lua" );
dofile_once( "mods/gkbrkn_noita/files/gkbrkn/lib/mod_settings.lua" );
dofile_once( "mods/gkbrkn_noita/files/gkbrkn/lib/variables.lua");
dofile_once( "mods/gkbrkn_noita/files/gkbrkn/helper.lua" );
dofile( "mods/gkbrkn_noita/files/gkbrkn/content/packs.lua" );
local _spawn_hp = spawn_hp;
function spawn_hp( x, y )
	_spawn_hp( x, y );
    if setting_get( MISC.TargetDummy.EnabledFlag ) then
        EntityLoad( "mods/gkbrkn_noita/files/gkbrkn/misc/dummy_target.xml", x - 198, y + 20 );
    end
end

local _spawn_all_shopitems = spawn_all_shopitems;
function spawn_all_shopitems( x, y )
    if setting_get( MISC.ShopReroll.EnabledFlag ) then
        EntityLoad( "mods/gkbrkn_noita/files/gkbrkn/misc/shop_reroll/shop_reroll.xml", x - 35, y - 12 );
    end
    if setting_get( MISC.SlotMachine.EnabledFlag ) then
        EntityLoad( "mods/gkbrkn_noita/files/gkbrkn/misc/slot_machine/slot_machine.xml", x + 136, y );
    end
    if not setting_get( MISC.PackShops.EnabledFlag) then
        _spawn_all_shopitems( x, y );
    else
        local spawn_shop, spawn_perks = temple_random( x, y )
        if( spawn_shop == "0" ) then return; end

        EntityLoad( "data/entities/buildings/shop_hitbox.xml", x, y );
        
        SetRandomSeed( x, y );
        local count = tonumber( GlobalsGetValue( "TEMPLE_SHOP_ITEM_COUNT", "5" ) );
        local width = 132;
        local item_width = width / count;

        local pack_weight_table = get_pack_weight_table();
        for i=1,count do
            --generate_shop_item( x + (i-1)*item_width, y, false, nil, true );
			generate_shop_pack(pack_weight_table, x + (i-1)*item_width, y, false, nil, true)
        end
    end
end
