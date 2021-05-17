dofile( "data/scripts/items/generate_shop_item.lua" );
dofile( "mods/gkbrkn_noita/files/gkbrkn/content/packs.lua" );
function item_pickup( entity_item, entity_who_picked, item_name )
	local x, y = EntityGetTransform( entity_item );

    SetRandomSeed( x, y );
    -- NOTE: Because of mods, it's not clear how big this radius should be
    local nearby_entities = EntityGetInRadius( x, y, 512 );
    local shop_items = {};
    for _,entity in pairs(nearby_entities) do
        local item_cost = EntityGetFirstComponent( entity, "ItemCostComponent", "shop_cost" );
        if item_cost then
            table.insert( shop_items, entity );
        else
            local sprite = EntityGetFirstComponent( entity, "SpriteComponent" );
            -- remove sale banners
            -- NOTE: Hard coded since there is no other useful data
            if ComponentGetValue2( sprite, "image_file" ) == "data/ui_gfx/sale_indicator.png" then
                EntityKill( entity );
            end
        end
    end
	--local sale_item_i = Random( 1, #shop_items )
    -- NOTE: Because the item has to be moved and the sale tag will be offset, this doesn't allow for sales
	local sale_item_i = -1
    --for shop_item in pairs( shop_items )
    local pull = tonumber( GlobalsGetValue( "gkbrkn_shop_rerolls", "0" ) );
    GlobalsSetValue( "gkbrkn_shop_rerolls", pull + 1 );
    GlobalsSetValue( "gkbrkn_rerolling_shop", "1" );
    local _SetRandomSeed = SetRandomSeed;
    SetRandomSeed = function( x, y )
        return _SetRandomSeed( x + pull * 13, y + pull * 127 );
    end
    local _GetRandomAction = GetRandomAction;
    GetRandomAction = function( x, y, max_level, type, i )
        return _GetRandomAction( x + pull * 13, y + pull * 127, max_level, type, i );
    end
	local pack_weight_table = get_pack_weight_table();
    for i=1,#shop_items do
        local item = shop_items[i];
        local wand = EntityHasTag( item, "wand" );
		local pack = EntityHasTag( item, "gkbrkn_pack" );
        local x, y = EntityGetTransform( item );
        EntityKill( item );
		if pack then
			generate_shop_pack( pack_weight_table, x, y, i == sale_item_i, nil, true);
        elseif wand then
            generate_shop_wand( x, y, i == sale_item_i, nil, true );
        else
            generate_shop_item( x, y, i == sale_item_i, nil, true );
        end
    end
    SetRandomSeed = _SetRandomSeed;
    GetRandomAction = _GetRandomAction;
    GlobalsSetValue( "gkbrkn_rerolling_shop", "0" );

	EntityKill( entity_item );
    EntityLoad( "data/entities/particles/perk_reroll.xml", x, y );
    local break_roll = math.random();
    if break_roll < 1.25 - math.min( 1.0, 0.05 * pull ) then
        EntityLoad( "mods/gkbrkn_noita/files/gkbrkn/misc/shop_reroll/shop_reroll.xml", x, y );
    else
        EntityLoad( "mods/gkbrkn_noita/files/gkbrkn/misc/shop_reroll/shop_reroll_broken.xml", x, y );
    end
end