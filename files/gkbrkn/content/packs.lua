--[[ Pack to consider

Alchemy - useful for finding alchemic recipes
Book - Encyclopedias, paper shot
Multicast - 
Explosives - 
Summoning - 
Digging/Mining - 
Exploration - 
Ocean Friends 2 - 
Danger - 
Electric - 
Celebration/Festive - 
Velocity - 
Archery - homing????????????????????????????????????????
Fields - 
Geometry - 


]]

dofile_once( "mods/gkbrkn_noita/files/gkbrkn/helper.lua" );
dofile( "data/scripts/gun/gun_actions.lua" )

local memoize_packs = {};
function find_pack( id )
    local pack = nil;
    if memoize_packs[id] then
        pack = memoize_packs[id];
    else
        for _,entry in pairs(packs) do
            if entry.id == id then
                pack = entry;
                parse_pack_action_weights( entry );
                memoize_packs[id] = entry;
            end
        end
    end
    return pack;
end

local RARITY = {
    Common = 1,
    Uncommon = 2,
    Rare = 3,
    VeryRare = 4,
    Legendary = 5
}

local RARITY_RATIOS = {
    [RARITY.Common] = 0.38,
    [RARITY.Uncommon] = 0.28,
    [RARITY.Rare] = 0.18,
    [RARITY.VeryRare] = 0.10,
    [RARITY.Legendary] = 0.06,
}

function parse_pack_action_weights( pack_data )
    local rarity_buckets = {};
    for _,action in pairs( pack_data.actions ) do
        local action_rarity = action.rarity or RARITY.Common;
        rarity_buckets[action_rarity] = ( rarity_buckets[action_rarity] or {} );
        table.insert( rarity_buckets[action_rarity], action );
    end
    local rarity_weights = {};
    for rarity,bucket in pairs( rarity_buckets ) do
        local weight = RARITY_RATIOS[rarity] / ( #bucket or 1 );
        for _,action_data in pairs( bucket ) do
            --action_data.weight = math.ceil( weight * 100 );
            action_data.weight = weight;
        end
    end
end

function crack_pack( pack_data, x, y, i )
    local MISC = dofile_once( "mods/gkbrkn_noita/files/gkbrkn/lib/options.lua");
    if i == nil then
        i = 0;
    end
    SetRandomSeed( x + i, y + i );
    local spawn_attempts = 100;
    local card_amounts = {};
    local card_weight_table = {};
    local chosen_cards = {};
    for card_data_index,action in pairs( pack_data.actions ) do
		if(is_valid_action(action.id)) then
			card_weight_table[card_data_index] = action.weight;
		end
    end
	local cards = pack_data.cards_in_pack or MISC.PackShops.CardsPerPack;
    while #chosen_cards < cards and spawn_attempts > 0 and #card_weight_table > 0 do
        local chosen_card_index = WeightedRandomTable( card_weight_table );
        local chosen_card_data = pack_data.actions[ chosen_card_index ];
        if chosen_card_data and ( chosen_card_data.limit_per_pack or -1 ) > 0 then
            if ( card_amounts[chosen_card_data.id] or 0 ) < chosen_card_data.limit_per_pack then
                card_amounts[chosen_card_data.id] = (card_amounts[chosen_card_data.id] or 0) + 1;
                table.insert( chosen_cards, chosen_card_data.id );
            end
        end
        spawn_attempts = spawn_attempts - 1;
    end
    for j=1,MISC.PackShops.RandomCardsPerPack do
        table.insert( chosen_cards, GetRandomAction( x + i, y + i, 6, j ) );
    end
    return chosen_cards;
end

function is_valid_action( action )
	local valid = false;
	for i,thisitem in ipairs( actions ) do
		if ( string.lower( thisitem.id ) == string.lower( action ) and ( thisitem.spawn_requires_flag == nil or HasFlagPersistent( thisitem.spawn_requires_flag ) ) ) then
			return true;
		end
	end
	return false;
end

function simulate_cracking_packs( pack_id, amount, x, y )
    dofile_once( "mods/gkbrkn_noita/files/gkbrkn/lib/helper.lua");
    local cards_pulled = {};
    for i=1,amount do
        local cards_in_pack = crack_pack( find_pack( pack_id ), x, y, i );
        for _,action_id in pairs( cards_in_pack ) do
            cards_pulled[ action_id ] = ( cards_pulled[ action_id ] or 0 ) + 1;
        end
    end
    print( "\nSimulated opening "..pack_id.." "..amount.." times:" );
    cards_pulled = sort_keyed_table( cards_pulled, function( a, b ) return a.value > b.value; end );
    for k,v in pairs(cards_pulled) do
        print("\t"..v.key..": "..v.value);
    end
end

function get_pack_weight_table()
	local pack_weight_table = {};
    for _,pack_data in pairs( packs ) do
        parse_pack_action_weights( pack_data );
        pack_weight_table[ pack_data.id ] = pack_data.weight;
    end
	return pack_weight_table;
end

function generate_shop_pack( pack_weight_table, x, y, cheap_item, biomeid_, is_stealable )
	-- this makes the shop items deterministic
	SetRandomSeed( x, y )

	local biomes =
	{
		[1] = 0,
		[2] = 0,
		[3] = 0,
		[4] = 1,
		[5] = 1,
		[6] = 1,
		[7] = 2,
		[8] = 2,
		[9] = 2,
		[10] = 2,
		[11] = 2,
		[12] = 2,
		[13] = 3,
		[14] = 3,
		[15] = 3,
		[16] = 3,
		[17] = 4,
		[18] = 4,
		[19] = 4,
		[20] = 4,
		[21] = 5,
		[22] = 5,
		[23] = 5,
		[24] = 5,
		[25] = 6,
		[26] = 6,
		[27] = 6,
		[28] = 6,
		[29] = 6,
		[30] = 6,
		[31] = 6,
		[32] = 6,
		[33] = 6,
	}


	local biomepixel = math.floor(y / 512)
	local biomeid = biomes[biomepixel] or 0
	
	if (biomepixel > 35) then
		biomeid = 7
	end
	
	if (biomes[biomepixel] == nil) and (biomeid_ == nil) then
		print("Unable to find biomeid for chunk at depth " .. tostring(biomepixel))
	end
	
	if (biomeid_ ~= nil) then
		biomeid = biomeid_
	end

	if( is_stealable == nil ) then
		is_stealable = false
	end

	local pack_data = nil
	local packcost = 0

	-- Note( Petri ): Testing how much squaring the biomeid for prices affects things
	local level = biomeid
	biomeid = biomeid * biomeid

	packcost = 0

	local pack_data = find_pack( WeightedRandomTable( pack_weight_table ) );
    if pack_data then
		price = math.max(math.floor( ( (100 * 0.30) + (70 * biomeid) ) / 10 ) * 10, 10)
		packcost = price;
	
		if( cheap_item ) then
			packcost = 0.5 * packcost
		end
	
		if ( biomeid >= 10 ) then
			price = price * 5.0
			packcost = packcost * 5.0
		end
	
        local eid = EntityLoad( "mods/gkbrkn_noita/files/gkbrkn/packs/base_pack_pickup.xml", x, y );
		if pack_data.image_filepath then
            local sprite = EntityGetFirstComponent( eid, "SpriteComponent" );
            if sprite then 
				ComponentSetValue2( sprite, "image_file", pack_data.image_filepath );
				EntityRefreshSprite( eid, sprite );
			end
        end
        --EntityAddComponent( eid, "SpriteComponent", { 
        --    _tags="shop_cost,enabled_in_world",
        --    image_file="data/fonts/font_pixel_white.xml", 
        --    is_text_sprite="1", 
        --    offset_x="7", 
        --    offset_y="25", 
        --    update_transform="1" ,
        --    update_transform_rotation="0",
        --    text="111",
        --} );
        EntitySetVariableString( eid, "gkbrkn_pack_id", pack_data.id );
        local ui_info = EntityGetFirstComponent( eid, "UIInfoComponent" );
        if ui_info then ComponentSetValue2( ui_info, "name", GameTextGetTranslatedOrNot( pack_data.name ) ); end
        local item = EntityGetFirstComponent( eid, "ItemComponent" );
        if item then ComponentSetValue2( item, "item_name", GameTextGetTranslatedOrNot( pack_data.name ) ); end
		
		if( cheap_item ) then
			EntityLoad( "data/entities/misc/sale_indicator.xml", x, y )
		end

		-- local x, y = EntityGetTransform( entity_id )
		-- SetRandomSeed( x, y )
	
		local offsetx = 6
		local text = tostring(packcost)
		local textwidth = 0
	
		for i=1,#text do
			local l = string.sub( text, i, i )
			
			if ( l ~= "1" ) then
				textwidth = textwidth + 6
			else
				textwidth = textwidth + 3
			end
		end
	
		offsetx = textwidth * 0.5 - 0.5

		EntityAddComponent( eid, "SpriteComponent", { 
			_tags="shop_cost,enabled_in_world",
			image_file="data/fonts/font_pixel_white.xml", 
			is_text_sprite="1", 
			offset_x=tostring(offsetx), 
			offset_y="25", 
			update_transform="1" ,
			update_transform_rotation="0",
			text=tostring(packcost),
			z_index="-1",
		} )

		local stealable_value = "0"
		if( is_stealable ) then 
			stealable_value = "1"
		end
	
		EntityAddComponent( eid, "ItemCostComponent", { 
			_tags="shop_cost,enabled_in_world", 
			cost=packcost,
			stealable=stealable_value
		} )
		
		EntityAddComponent( eid, "LuaComponent", { 
			script_item_picked_up="data/scripts/items/shop_effect.lua",
		} )
		-- shop_item_pickup2.lua

		-- display uses remaining, if any
		--  NOTE(Olli): removed this because it didn't work with low resolution rendering
		--[[edit_component( eid, "ItemComponent", function(comp,vars)
			local uses_remaining = tonumber( ComponentGetValue(comp, "uses_remaining" ) )
			if uses_remaining > -1 then
				EntityAddComponent( eid, "SpriteComponent", { 
					_tags="shop_cost,enabled_in_world",
					image_file="data/fonts/font_pixel_white.xml", 
					is_text_sprite="1", 
					offset_x="16", 
					offset_y="32", 
					has_special_scale="1",
					special_scale_x="0.5",
					special_scale_y="0.5",
					update_transform="1" ,
					update_transform_rotation="0",
					text=tostring(uses_remaining),
					} )
			end
		end)]]--
    else
        print( "[goki's things] Could not find pack data" );
	end
end

function generate_pack_contents( filter, generator )
	local contents = {};
	for i,thisitem in ipairs( actions ) do
		if ( filter(thisitem) ) then
			local newpack = {
				id = thisitem.id,
				rarity = RARITY.Legendary,
				limit_per_pack = 3,
			};
			if(generator ~= nil) then
				generator(newpack);
			end
			table.insert(contents, newpack);
		end
	end
	return contents;
end

function filter_is_type( action_type ) 
	return function ( action ) 
		return action.type == action_type;
	end
end

function filter_id_contains( str ) 
	return function ( action ) 
		return string.find( string.lower( action.id ), string.lower( str ), 1, true) ~= nil;
	end
end

function filter_limited_use( action )
	return action.max_uses ~= nil and action.max_uses > 0;
end

function filter_unlimited_use( action )
	return not filter_limited_use( action );
end

function filter_requires_unlock( action )
	return action.spawn_requires_flag ~= nil;
end

function filter_single_use( action )
	return action.max_uses == 1;
end

function filter_price_between( low, high )
	return function ( action ) 
		return action.price ~= nil and action.price >= low and action.price < high;
	end
end

function filter_mana_cost_between( low, high )
	return function ( action ) 
		return action.mana ~= nil and action.mana >= low and action.mana < high;
	end
end

packs = {
    
    {
        id = "gkbrkn_test",
        name = "Test Pack",
        -- this might become an xml to load? that way people could design specialer packs
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-test.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects
        author = "goki", -- your name
        cards_in_pack = 5, -- this is how many cards the player will get when they buy the pack (default 5)
        weight = 1, -- the likelihood that this pack will show up over other packs (higher is more often)
        limit_per_run = -1, -- the max amount this pack can spawn in a run. -1 is no limit
        validation_callback = nil, -- a function callback to see if this can spawn. ignore for the most part
        deprecated = true,
        actions = {
            {
                id = "LIGHT_BULLET", -- the action id. this one is sparkbolt
                rarity = RARITY.Legendary, -- the likelihood this card will be chosen to be in the pack. higher is more often
                limit_per_pack = 3, -- the max amount of this spell you can get in one pack
            },
            {
                id = "HEAVY_BULLET", -- magic bolt
                rarity = RARITY.Uncommon,
                limit_per_pack = 2,
            },
            {
                id = "SLOW_BULLET", -- energy orb
                rarity = RARITY.Common,
                limit_per_pack = 1,
            }
        }
    },
    {
        id = "gkbrkn_alchemy",
        name = "Alchemy",
        -- this might become an xml to load? that way people could design specialer packs
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-alchemical.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects
        author = "goki", -- your name
        cards_in_pack = 5, -- this is how many cards the player will get when they buy the pack (default 5)
        weight = 1, -- the likelihood that this pack will show up over other packs (higher is more often)
        limit_per_run = -1, -- the max amount this pack can spawn in a run. -1 is no limit
        validation_callback = nil, -- a function callback to see if this can spawn. ignore for the most part
        actions = {
            {
                id = "ACIDSHOT",
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            },
            {
                id = "CIRCLE_ACID",
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            },
            {
                id = "MATERIAL_ACID",
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            },
            {
                id = "MATERIAL_CEMENT",
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            },
            {
                id = "BLOOD_TO_ACID",
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            },
            {
                id = "TOXIC_TO_ACID",
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            },
            {
                id = "SEA_ACID",
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            },
            {
                id = "SEA_ACID_GAS",
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            },
            {
                id = "CLOUD_ACID",
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            },
            {
                id = "ACID_TRAIL",
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            },
        }
    },
    {
        id = "gkbrkn_critical_hits",
        name = "Critical Hits",
        local_content = true,
        -- this might become an xml to load? that way people could design specialer packs
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/critical_hits/pack.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects
        author = "goki", -- your name
        weight = 1, -- the likelihood that this pack will show up over other packs (higher is more often)
        limit_per_run = -1, -- the max amount this pack can spawn in a run. -1 is no limit
        validation_callback = nil, -- a function callback to see if this can spawn. ignore for the most part
        actions = {
            {
                id = "SWAPPER_PROJECTILE",
                rarity = RARITY.VeryRare,
                limit_per_pack = 1,
            },
            {
                id = "CRITICAL_HIT",
                rarity = RARITY.VeryRare,
                limit_per_pack = 1,
            },
            {
                id = "LIGHT_BULLET",
                rarity = RARITY.Common,
                limit_per_pack = 3,
            },
            {
                id = "LIGHT_BULLET_TRIGGER",
                rarity = RARITY.Uncommon,
                limit_per_pack = 1,
            },
            {
                id = "LIGHT_BULLET_TRIGGER_2",
                rarity = RARITY.Rare,
                limit_per_pack = 1,
            },
            {
                id = "LIGHT_BULLET_TIMER",
                rarity = RARITY.Uncommon,
                limit_per_pack = 1,
            },
            {
                id = "BULLET",
                rarity = RARITY.Common,
                limit_per_pack = 2,
            },
            {
                id = "BULLET_TRIGGER",
                rarity = RARITY.Uncommon,
                limit_per_pack = 1,
            },
            {
                id = "BULLET_TIMER",
                rarity = RARITY.Uncommon,
                limit_per_pack = 1,
            },
            {
                id = "HEAVY_BULLET",
                rarity = RARITY.Uncommon,
                limit_per_pack = 1,
            },
            {
                id = "HEAVY_BULLET_TRIGGER",
                rarity = RARITY.Rare,
                limit_per_pack = 1,
            },
            {
                id = "HEAVY_BULLET_TIMER",
                rarity = RARITY.Rare,
                limit_per_pack = 1,
            },
            {
                id = "HITFX_BURNING_CRITICAL_HIT",
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            },
            {
                id = "HITFX_CRITICAL_WATER",
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            },
            {
                id = "HITFX_CRITICAL_OIL",
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            },
            {
                id = "HITFX_CRITICAL_BLOOD",
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            }
        }
    },
    {
        id = "pasta_1",
        name = "Hard to Breathe",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-hardtobreathe.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "pasta",
        cards_in_pack = 5,
        weight = 1,
        limit_per_run = -1,
        validation_callback = nil,		
        actions = {
            {
                id = "MIST_ALCOHOL",
                rarity = RARITY.Rare,
                limit_per_pack = 2,
            },
            {
                id = "MIST_BLOOD",
                rarity = RARITY.Uncommon,
                limit_per_pack = 1,
            },
            {
                id = "MIST_RADIOACTIVE",
                rarity = RARITY.Rare,
                limit_per_pack = 1,
            },
            {
                id = "MIST_SLIME",
                rarity = RARITY.Rare,
                limit_per_pack = 2,
            }
        }
    },
    {
        id = "pasta_2",
        name = "Touch of Magic",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-touchofmagic.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "pasta",
        cards_in_pack = 5,
        weight = 1,
        limit_per_run = -1,
        validation_callback = nil,		
        actions = {
            {
                id = "touch_alcohol",
                weight = 20,
                limit_per_pack =3,
            },
            {
                id = "touch_blood",
                weight = 10,
                limit_per_pack =1,
            },
            {
                id = "touch_oil",
                weight = 20,
                limit_per_pack =2,
            },
            {
                id = "touch_smoke",
                weight = 10,
                limit_per_pack =3,
            },
            {
                id = "touch_water",
                rarity = RARITY.Legendary,
                limit_per_pack =2,
            },
            {
                id = "touch_gold",
                rarity = RARITY.Common,
                limit_per_pack =1,
            },
        }
    },
    {
        id = "gkbrkn_starter",
        name = "Starter Pack",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-starter.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "lilyhops",
        cards_in_pack = 5,
        weight = 1,
        validation_callback = nil,		
        actions = {
            {
                id = "BOMB", -- bomb
                rarity = RARITY.Legendary,
                limit_per_pack = 3,
            },
             {
                id = "SPITTER", -- spitter bolt
                rarity = RARITY.Legendary,
                limit_per_pack = 5,
            },
             {
                id = "LIGHT_BULLET", -- light bullet
                rarity = RARITY.Legendary,
                limit_per_pack = 3,
            },
             {
                id = "HORIZONTAL_ARC", -- horizontal path
                rarity = RARITY.Legendary,
                limit_per_pack = 2,
            },
             {
                id = "DISC_BULLET", -- disc projectile
                rarity = RARITY.Rare,
                limit_per_pack = 2,
            },
             {
                id = "SCATTER_2", -- double scatter
                rarity = RARITY.Rare,
                limit_per_pack = 2,
            },
             {
                id = "FREEZE_FIELD", -- circle of stillness
                rarity = RARITY.Rare,
                limit_per_pack = 2,
            },
            {
                id = "CHAIN_BOLT", -- chain bolt
                rarity = RARITY.Common,
                limit_per_pack = 1,
            },
            {
                id = "HOMING", -- homing
                rarity = RARITY.Common,
                limit_per_pack = 1,
            },
        }
    },
    {
        id = "gkbrkn_fire",
        name = "Fire Starter",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-firestarter.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "lilyhops",
        cards_in_pack = 5,
        weight = 1,
        validation_callback = nil,		
        actions = {
            {
                id = "FIREBOMB", -- firebomb
                rarity = RARITY.Rare,
                limit_per_pack = 3,
            },
             {
                id = "BURN_TRAIL", -- burning trail
                rarity = RARITY.Rare,
                limit_per_pack = 2,
            },
             {
                id = "TORCH", -- torch
                rarity = RARITY.Legendary,
                limit_per_pack = 2,
            },
             {
                id = "GRENADE", -- firebolt
                rarity = RARITY.Legendary,
                limit_per_pack = 2,
            },
            {
                id = "GRENADE_ANTI", -- odd firebolt
                rarity = RARITY.Legendary,
                limit_per_pack = 2,
            },
            {
                id = "METEOR", -- meteor
                rarity = RARITY.Common,
                limit_per_pack = 1,
            },
             {
                id = "CIRCLE_FIRE", -- circle of fire
                rarity = RARITY.Common,
                limit_per_pack = 1,
            },
             {
                id = "SEA_LAVA", -- sea of lava
                rarity = RARITY.Common,
                limit_per_pack = 2,
            },
             {
                id = "FIREBALL", -- fireball
                rarity = RARITY.Legendary,
                limit_per_pack = 3,
            },
             {
                id = "GRENADE_ANTI", -- odd firebolt
                rarity = RARITY.Legendary,
                limit_per_pack = 2,
            },
             {
                id = "FIRE_BLAST", -- explosion of brimstone
                rarity = RARITY.Rare,
                limit_per_pack = 2,
            },
        }
    },
    {
        id = "gkbrkn_chaos",
        name = "Chaos Magic",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-chaosmagic.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "lilyhops",
        cards_in_pack = 5,
        weight = 1,
        validation_callback = nil,		
        actions = {
            {
                id = "CHAOTIC_ARC", -- chaotic path
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            },
            {
                id = "TINY_GHOST", -- tiny ghost
                rarity = RARITY.Legendary,
                limit_per_pack = 5,
            },
             {
                id = "BUBBLESHOT", -- bubble spark
                rarity = RARITY.Legendary,
                limit_per_pack = 5,
            },
            {
                id = "SUMMON_WANDGHOST", -- summon taikasauva
                rarity = RARITY.Legendary,
                limit_per_pack = 2,
            },
             {
                id = "ROCKET_DOWNWARDS", -- downwards bolt bundle
                rarity = RARITY.Rare,
                limit_per_pack = 2,
            },
            {
                id = "TRANSMUTATION", -- chaotic transmutation
                rarity = RARITY.Rare,
                limit_per_pack = 1,
            },
              {
                id = "GRAVITY_FIELD_ENEMY", -- personal gravity field
                rarity = RARITY.Rare,
                limit_per_pack = 1,
            },
             {
                id = "CHAOS_POLYMORPH_FIELD", -- circle of unstable metamorphosis
                rarity = RARITY.Rare,
                limit_per_pack = 2,
            },
            {
                id = "gkbrkn_chaotic_burst", -- chaotic burst
                rarity = RARITY.Common,
                limit_per_pack = 5,
            },
             {
                id = "gkbrkn_false_spell", -- false spell
                rarity = RARITY.Common,
                limit_per_pack = 5,
            }
        }
    },
    {
        id = "gkbrkn_death",
        name = "Death Magic",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-deathmagic.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "lilyhops",
        cards_in_pack = 5,
        weight = 1,
        validation_callback = nil,		
        actions = {
            {
                id = "DEATH_CROSS", -- death cross
                rarity = RARITY.Legendary,
                limit_per_pack = 5,
            },
            {
                id = "SUMMON_HOLLOW_EGG", -- summon hollow egg
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            },
            {
                id = "DESTRUCTION", -- destruction
                rarity = RARITY.Legendary,
                limit_per_pack = 5,
            },
            {
                id = "NECROMANCY", -- necromancy
                rarity = RARITY.Rare,
                limit_per_pack = 2,
            },
             {
                id = "PENTAGRAM_SHAPE", -- formation - pentagon
                rarity = RARITY.Rare,
                limit_per_pack = 2,
            },
            {
                id = "MATERIAL_BLOOD", -- blood
                rarity = RARITY.Rare,
                limit_per_pack = 3,
            },
            {
                id = "GKBRKN_TRIGGER_DEATH", -- trigger death
                rarity = RARITY.Rare,
                limit_per_pack = 2,
            },
            {
                id = "GKBRKN_TRIGGER_TAKE_DAMAGE", -- trigger take damage
                rarity = RARITY.Common,
                limit_per_pack = 1,
            },
             {
                id = "TOUCH_BLOOD", -- touch of blood
                rarity = RARITY.Common,
                limit_per_pack = 1,
            }
        }
    },
    {
        id = "gkbrkn_venom",
        name = "Venomous Sting",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-venomous.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "lilyhops",
        cards_in_pack = 5,
        weight = 1,
        validation_callback = nil,		
        actions = {
            {
                id = "POISON_TRAIL", -- poison trail
                rarity = RARITY.Legendary,
                limit_per_pack = 3,
            },
            {
                id = "ACIDSHOT", -- acid ball
                rarity = RARITY.Legendary,
                limit_per_pack = 3,
            },
            {
                id = "POISON_BLAST", -- explosion of poison
                rarity = RARITY.Legendary,
                limit_per_pack = 5,
            },
            {
                id = "MIST_RADIOACTIVE", -- toxic mist
                rarity = RARITY.Legendary,
                limit_per_pack = 5,
            },
            {
                id = "SINEWAVE", -- slithering path
                rarity = RARITY.Rare,
                limit_per_pack = 2,
            },
            {
                id = "WATER_TO_POISON", -- water to poison
                rarity = RARITY.Rare,
                limit_per_pack = 2,
            },
            {
                id = "ARC_POISON", -- poison arc
                rarity = RARITY.Rare,
                limit_per_pack = 2,
            },
            {
                id = "HIT_FX_TOXIC_CHARM", -- charm on toxic sludge
                rarity = RARITY.Rare,
                limit_per_pack = 2,
            },
            {
                id = "PIERCING_SHOT", -- piercing shot
                rarity = RARITY.Common,
                limit_per_pack = 1,
            },
            {
                id = "LIGHT_SHOT", -- light shot
                rarity = RARITY.Common,
                limit_per_pack = 1,
            }
        }
    },
    {
        id = "gkbrkn_density",
        name = "Density Manipulation",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-density.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "lilyhops",
        cards_in_pack = 5,
        weight = 1,
        limit_per_run = -1,
        validation_callback = nil,
        actions = {
            {
                id = "LEVITATION_FIELD", -- circle of buoyancy
                rarity = RARITY.Legendary,
                limit_per_pack = 3,
            },
            {
                id = "GKBRKN_TIME_COMPRESSION", -- time compression
                rarity = RARITY.Legendary,
                limit_per_pack = 3,
            },
            {
                id = "LASER", -- concentrated light
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            },
            {
                id = "GKBRKN_ZERO_GRAVITY", -- zero gravity
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            },
            {
                id = "GKBRKN_TIME_SPLIT", -- time split
                rarity = RARITY.Legendary,
                limit_per_pack = 5,
            },
			{
                id = "BLACK_HOLE", -- black hole
                rarity = RARITY.Common,
                limit_per_pack = 3,
            },
			{
                id = "BLACK_HOLE_DEATH_TRIGGER",
                rarity = RARITY.Uncommon,
                limit_per_pack = 3,
            },
            {
                id = "BLACK_HOLE_BIG", -- giga black hole
                rarity = RARITY.Rare,
                limit_per_pack = 2,
            },
			{
                id = "SPELLBOUND_BLACKHOLE_INFUSION",
                rarity = RARITY.Rare,
                limit_per_pack = 3,
            },
			{
                id = "ALL_BLACKHOLES",
                rarity = RARITY.Rare,
                limit_per_pack = 1,
            },
            {
                id = "GRAVITY", -- gravity
                rarity = RARITY.Rare,
                limit_per_pack = 2,
            },
            {
                id = "TELEPORT_PROJECTILE", -- teleport
                rarity = RARITY.Rare,
                limit_per_pack = 2,
            },
            {
                id = "HEAVY_SHOT", -- heavy shot
                rarity = RARITY.Common,
                limit_per_pack = 1,
            },
            {
                id = "MATTER_EATER", -- matter eater
                rarity = RARITY.Common,
                limit_per_pack = 3,
            },
			{
                id = "SPELLBOUND_VOID_SHOT",
                rarity = RARITY.Rare,
                limit_per_pack = 3,
            },
        }
    },
    {
        id = "pasta_3",
        name = "Steve Slayer",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-steve.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "pasta",
        cards_in_pack = 4,
        weight = 1,
        limit_per_run = 1,
        validation_callback = nil,		
        actions = {
            {
                id = "ELECTROCUTION_FIELD",
                rarity = RARITY.Uncommon,
                limit_per_pack = 1,
            },
            {
                id = "FREEZE_FIELD",
                rarity = RARITY.Uncommon,
                limit_per_pack = 1,
            },
            {
                id = "LIGHT_BULLET_TRIGGER",
                rarity = RARITY.Common,
                limit_per_pack = 1,
            },
            {
                id = "CHAINSAW",
                rarity = RARITY.Common,
                limit_per_pack = 1,
            }
        }
    },
	{
        id = "bord_utility",
        name = "Wand Utility",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-utility.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "bord",
        cards_in_pack = 5,
        weight = 1,
        limit_per_run = -1,
        validation_callback = nil,		
        actions = {
            {
                id = "MANA_REDUCE",
                rarity = RARITY.Rare,
                limit_per_pack = 1,
            },
            {
                id = "EXPLOSION_REMOVE",
                rarity = RARITY.Uncommon,
                limit_per_pack = 1,
            },
            {
                id = "RECHARGE",
                rarity = RARITY.Rare,
                limit_per_pack = 1,
            },
            {
                id = "LIFETIME_UP",
                rarity = RARITY.Uncommon,
                limit_per_pack = 1,
            },
			{
                id = "LIFETIME_DOWN",
                rarity = RARITY.Uncommon,
                limit_per_pack = 1,
            },
			{
                id = "NOLLA",
                rarity = RARITY.Common,
                limit_per_pack = 1,
            },
			{
                id = "GKBRKN_TIME_SPLIT",
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            },
			{
                id = "GKBRKN_MANA_EFFICIENCY",
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            },
			{
                id = "GKBRKN_TIME_COMPRESSION",
                rarity = RARITY.Common,
                limit_per_pack = 1,
            },
			{
                id = "GKBRKN_SEPARATOR",
                rarity = RARITY.Common,
                limit_per_pack = 1,
            },
			{
                id = "SPELLBOUND_DUCK",
                rarity = RARITY.Common,
                limit_per_pack = 1,
            },
			{
                id = "ADD_DEATH_TRIGGER",
                rarity = RARITY.Common,
                limit_per_pack = 1,
            },
			{
                id = "ADD_TIMER",
                rarity = RARITY.Common,
                limit_per_pack = 1,
            },
			{
                id = "ADD_TRIGGER",
                rarity = RARITY.Common,
                limit_per_pack = 1,
            },
			{
                id = "RESET",
                rarity = RARITY.Common,
                limit_per_pack = 1,
            },
        }
    },
	{
        id = "bord_curse",
        name = "Cursed",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-curse.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "bord",
        cards_in_pack = 5,
        weight = 1,
        limit_per_run = -1,
        validation_callback = nil,		
        actions = {
            {
                id = "CURSED_ORB",
                rarity = RARITY.Common,
                limit_per_pack = 3,
            },
            {
                id = "SPELLBOUND_ASCENDANT_FIREBALL",
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            },
            {
                id = "SPELLBOUND_FIRE_SKULL",
                rarity = RARITY.Common,
                limit_per_pack = 3,
            },
            {
                id = "DARKFLAME",
                rarity = RARITY.Uncommon,
                limit_per_pack = 3,
            },
			{
                id = "SPELLBOUND_DARK_FLAME_TRAIL",
                rarity = RARITY.Uncommon,
                limit_per_pack = 3,
            },
			{
                id = "CURSE_WITHER_PROJECTILE",
                rarity = RARITY.Common,
                limit_per_pack = 5,
            },
			{
                id = "CURSE_WITHER_MELEE",
                rarity = RARITY.Common,
                limit_per_pack = 5,
            },
			{
                id = "CURSE_WITHER_EXPLOSION",
                rarity = RARITY.Common,
                limit_per_pack = 5,
            },
			{
                id = "CURSE_WITHER_ELECTRICITY",
                rarity = RARITY.Common,
                limit_per_pack = 5,
            },
			{
                id = "CURSE",
                rarity = RARITY.Common,
                limit_per_pack = 5,
            },
        }
    },
	{
        id = "bord_holy",
        name = "Dies Irae",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-diesirae.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "bord",
        cards_in_pack = 5,
        weight = 1,
        limit_per_run = -1,
        validation_callback = nil,		
        actions = {
            {
                id = "SPELLBOUND_ASCENDANT_FIREBALL",
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            },
            {
                id = "DEATH_CROSS",
                rarity = RARITY.Rare,
                limit_per_pack = 1,
            },
            {
                id = "DEATH_CROSS_BIG",
                rarity = RARITY.Rare,
                limit_per_pack = 1,
            },
            {
                id = "LASER_EMITTER_FOUR",
                rarity = RARITY.Uncommon,
                limit_per_pack = 3,
            },
			{
                id = "GLOWING_BOLT",
                rarity = RARITY.Uncommon,
                limit_per_pack = 3,
            },
			{
                id = "LUMINOUS_DRILL",
                rarity = RARITY.Common,
                limit_per_pack = 5,
            },
			{
                id = "LASER_LUMINOUS_DRILL",
                rarity = RARITY.Common,
                limit_per_pack = 5,
            },
			{
                id = "LASER",
                rarity = RARITY.Common,
                limit_per_pack = 5,
            },
			{
                id = "MEGALASER",
                rarity = RARITY.Uncommon,
                limit_per_pack = 5,
            },
			{
                id = "BOMB_HOLY",
                rarity = RARITY.Rare,
                limit_per_pack = 5,
            },
			{
                id = "ALL_DEATHCROSSES",
                rarity = RARITY.Rare,
                limit_per_pack = 5,
            },
			{
                id = "LIGHT",
                rarity = RARITY.Common,
                limit_per_pack = 5,
            },
			{
                id = "GKBRKN_MODIFICATION_FIELD",
                rarity = RARITY.Uncommon,
                limit_per_pack = 1,
            },
        }
    },
	{
        id = "bord_earth",
        name = "Quaking Earth",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-earth.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "bord",
        cards_in_pack = 5,
        weight = 1,
        limit_per_run = -1,
        validation_callback = nil,		
        actions = {
            {
                id = "CRUMBLING_EARTH",
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            },
            {
                id = "CRUMBLING_EARTH_PROJECTILE",
                rarity = RARITY.Rare,
                limit_per_pack = 1,
            },
            {
                id = "SUMMON_ROCK",
                rarity = RARITY.Common,
                limit_per_pack = 5,
            },
            {
                id = "PEBBLE",
                rarity = RARITY.Uncommon,
                limit_per_pack = 3,
            },
			{
                id = "SPELLBOUND_TRAIL_OF_ROCK_SPIRITS",
                rarity = RARITY.Uncommon,
                limit_per_pack = 1,
            },
			{
                id = "DIGGER",
                rarity = RARITY.Common,
                limit_per_pack = 5,
            },
			{
                id = "POWERDIGGER",
                rarity = RARITY.Common,
                limit_per_pack = 3,
            },
			{
                id = "CLIPPING_SHOT",
                rarity = RARITY.Common,
                limit_per_pack = 3,
            },
			{
                id = "MATTER_EATER",
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            },
			{
                id = "STATIC_TO_SAND",
                rarity = RARITY.Uncommon,
                limit_per_pack = 2,
            },
			{
                id = "SOILBALL",
                rarity = RARITY.Common,
                limit_per_pack = 5,
            },
			{
                id = "HITFX_PETRIFY",
                rarity = RARITY.Rare,
                limit_per_pack = 3,
            },
        }
    },
	{
        id = "bord_plasma",
        name = "Plasma Frenzy",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-plasma.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "bord",
        cards_in_pack = 5,
        weight = 1,
        limit_per_run = -1,
        validation_callback = nil,		
        actions = {
            {
                id = "LASER_EMITTER",
                rarity = RARITY.Common,
                limit_per_pack = 5,
            },
            {
                id = "LASER_EMITTER_FOUR",
                rarity = RARITY.Rare,
                limit_per_pack = 3,
            },
            {
                id = "LASER_EMITTER_CUTTER",
                rarity = RARITY.Uncommon,
                limit_per_pack = 5,
            },
			{
                id = "WALL_HORIZONTAL",
                rarity = RARITY.Rare,
                limit_per_pack = 3,
            },
			{
                id = "WALL_VERTICAL",
                rarity = RARITY.Rare,
                limit_per_pack = 3,
            },
			{
                id = "WALL_SQUARE",
                rarity = RARITY.Rare,
                limit_per_pack = 3,
            },
			{
                id = "LASER_EMITTER_WIDER",
                rarity = RARITY.Uncommon,
                limit_per_pack = 5,
            },
			{
                id = "BOUNCE_LASER_EMITTER",
                rarity = RARITY.Rare,
                limit_per_pack = 3,
            },
			{
                id = "ORBIT_LASERS",
                rarity = RARITY.Legendary,
                limit_per_pack = 3,
            },
        }
    },
	{
        id = "bord_gold",
        name = "Glorious Gold",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-money.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "bord",
        cards_in_pack = 3,
        weight = 1,
        limit_per_run = 5,
        validation_callback = nil,		
        actions = {
            {
                id = "GKBRKN_NUGGET_SHOT",
                rarity = RARITY.Common,
                limit_per_pack = 5,
            },
            {
                id = "TOUCH_GOLD",
                rarity = RARITY.Rare,
                limit_per_pack = 2,
            },
            {
                id = "MONEY_MAGIC",
                rarity = RARITY.Uncommon,
                limit_per_pack = 3,
            },
        }
    },
	{
        id = "bord_heal",
        name = "Healing Hands",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-healing.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "bord",
        cards_in_pack = 1,
        weight = 0.2,
        limit_per_run = 5,
        validation_callback = nil,		
        actions = {
            {
                id = "HEAL_BULLET",
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            },
            {
                id = "REGENERATION_FIELD",
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            },
        }
    },
	{
        id = "bord_water",
        name = "Tides of Change",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-water.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "bord",
        cards_in_pack = 5,
        weight = 1,
        limit_per_run = -1,
        validation_callback = nil,		
        actions = {
            {
                id = "BUBBLESHOT",
                rarity = RARITY.Common,
                limit_per_pack = 5,
            },
            {
                id = "BUBBLESHOT_TRIGGER",
                rarity = RARITY.Common,
                limit_per_pack = 5,
            },
			{
                id = "BOUNCE_SPARK",
                rarity = RARITY.Common,
                limit_per_pack = 3,
            },
			{
                id = "SPELLBOUND_BUBBLE_PROJECTILES",
                rarity = RARITY.Common,
                limit_per_pack = 3,
            },
			{
                id = "CLOUD_WATER",
                rarity = RARITY.Common,
                limit_per_pack = 3,
            },
			{
                id = "WATER_TRAIL",
                rarity = RARITY.Common,
                limit_per_pack = 3,
            },
			{
                id = "HITFX_CRITICAL_WATER",
                rarity = RARITY.Uncommon,
                limit_per_pack = 3,
            },
			{
                id = "TOUCH_WATER",
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            },
			{
                id = "MATERIAL_WATER",
                rarity = RARITY.Common,
                limit_per_pack = 5,
            },
			{
                id = "SEA_WATER",
                rarity = RARITY.Rare,
                limit_per_pack = 1,
            },
			{
                id = "CIRCLE_WATER",
                rarity = RARITY.Uncommon,
                limit_per_pack = 3,
            },
        }
    },
	{
        id = "bord_homing",
        name = "Homing in",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-homing.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "bord",
        cards_in_pack = 5,
        weight = 1,
        limit_per_run = -1,
        validation_callback = nil,		
        actions = {
			{
                id = "HOMING",
                rarity = RARITY.Uncommon,
                limit_per_pack = 3,
            },
			{
                id = "HOMING_SHORT",
                rarity = RARITY.Common,
                limit_per_pack = 3,
            },
            {
                id = "HOMING_ACCELERATING",
                rarity = RARITY.Legendary,
                limit_per_pack = 2,
            },
            {
                id = "HOMING_CURSOR",
                rarity = RARITY.Common,
                limit_per_pack = 3,
            },
			{
                id = "HOMING_ROTATE",
                rarity = RARITY.Rare,
                limit_per_pack = 3,
            },
			{
                id = "HOMING_AREA",
                rarity = RARITY.Rare,
                limit_per_pack = 3,
            },
			{
                id = "AUTOAIM",
                rarity = RARITY.Uncommon,
                limit_per_pack = 3,
            },
			{
                id = "HOMING_SHOOTER",
                rarity = RARITY.Common,
                limit_per_pack = 3,
            },
			{
                id = "SPELLBOUND_CONTROL",
                rarity = RARITY.Uncommon,
                limit_per_pack = 3,
            },
			{
                id = "GKBRKN_CONTROL",
                rarity = RARITY.Uncommon,
                limit_per_pack = 3,
            },
			{
                id = "GKBRKN_GUIDED_SHOT",
                rarity = RARITY.Common,
                limit_per_pack = 3,
            },
			{
                id = "GKBRKN_PATH_CORRECTION",
                rarity = RARITY.Uncommon,
                limit_per_pack = 3,
            },
			{
                id = "GKBRKN_CLINGING_SHOT",
                rarity = RARITY.Uncommon,
                limit_per_pack = 3,
            },
			{
                id = "GKBRKN_SEEKER_SHOT",
                rarity = RARITY.Rare,
                limit_per_pack = 3,
            },
			{
                id = "SPELLBOUND_PATHFINDING",
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            },
        }
    },
	{
        id = "bord_drawpower",
        name = "Pot of Greed",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-potofgreed.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "bord",
        cards_in_pack = 5,
        weight = 1,
        limit_per_run = -1,
        validation_callback = nil,		
        actions = {
            {
                id = "BURST_2",
                rarity = RARITY.Common,
                limit_per_pack = 5,
            },
            {
                id = "BURST_3",
                rarity = RARITY.Common,
                limit_per_pack = 5,
            },
            {
                id = "BURST_4",
                rarity = RARITY.Uncommon,
                limit_per_pack = 3,
            },
			{
                id = "BURST_8",
                rarity = RARITY.Rare,
                limit_per_pack = 3,
            },
			{
                id = "BURST_X",
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            },
			{
                id = "GKBRKN_DOUBLE_CAST",
                rarity = RARITY.Rare,
                limit_per_pack = 3,
            },
			{
                id = "GKBRKN_TRIPLE_CAST",
                rarity = RARITY.Rare,
                limit_per_pack = 3,
            },
			{
                id = "GKBRKN_ORDER_DECK",
                rarity = RARITY.Uncommon,
                limit_per_pack = 3,
            },
        }
    },
	{
        id = "bord_magic_missile",
        name = "Magic Missile",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-test.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "bord",
        cards_in_pack = 5,
        weight = 1,
        limit_per_run = -1,
        validation_callback = nil,		
        actions = {
            {
                id = "ROCKET",
                rarity = RARITY.Common,
                limit_per_pack = 5,
            },
            {
                id = "ROCKET_TIER_2",
                rarity = RARITY.Rare,
                limit_per_pack = 5,
            },
            {
                id = "ROCKET_TIER_3",
                rarity = RARITY.Legendary,
                limit_per_pack = 5,
            },
			{
                id = "ALL_ROCKETS",
                rarity = RARITY.Legendary,
                limit_per_pack = 1,
            },
			{
                id = "SPELLBOUND_ENERGETIC_PROJECTILES",
                rarity = RARITY.Uncommon,
                limit_per_pack = 3,
            },
        }
    },
	{
        id = "bord_music",
        name = "Sound of Music",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-music.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "bord",
        cards_in_pack = 5,
        weight = 1,
        limit_per_run = -1,
        validation_callback = nil,		
        actions = {
            {
                id = "KANTELE_A",
                rarity = RARITY.Common,
                limit_per_pack = 5,
            },
            {
                id = "KANTELE_D",
                rarity = RARITY.Common,
                limit_per_pack = 5,
            },
            {
                id = "KANTELE_DIS",
                rarity = RARITY.Common,
                limit_per_pack = 5,
            },
			{
                id = "KANTELE_E",
                rarity = RARITY.Common,
                limit_per_pack = 5,
            },
			{
                id = "KANTELE_G",
                rarity = RARITY.Common,
                limit_per_pack = 5,
            },
        }
    },
	{
        id = "bord_slime",
        name = "Icky Goopy",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-ickygoopy.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "bord",
        cards_in_pack = 5,
        weight = 1,
        limit_per_run = -1,
        validation_callback = nil,		
        actions = {
            {
                id = "HITFX_EXPLOSION_SLIME",
                rarity = RARITY.Uncommon,
                limit_per_pack = 3,
            },
            {
                id = "HITFX_EXPLOSION_SLIME_GIGA",
                rarity = RARITY.Rare,
                limit_per_pack = 2,
            },
            {
                id = "SPELLBOUND_SLIME_AURA",
                rarity = RARITY.Common,
                limit_per_pack = 3,
            },
			{
                id = "MIST_SLIME",
                rarity = RARITY.Common,
                limit_per_pack = 5,
            },
        }
    },
	{
        id = "autogen_limited_use",
        name = "Premium Spells",
		description = "Contains all spells which have limited uses.",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-premium.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "autogen",
        cards_in_pack = 5,
        weight = 1,
        limit_per_run = -1,
        validation_callback = nil,
        actions = generate_pack_contents( filter_limited_use )
    },
	{
        id = "autogen_single_use",
        name = "Nomi",
        description = "Contains all spells which only have a single use.",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-singleuse.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "autogen",
        cards_in_pack = 5,
        weight = 1,
        limit_per_run = -1,
        validation_callback = nil,
        actions = generate_pack_contents( filter_single_use )
    },
	{
        id = "autogen_requirements",
        name = "Arcane Scripting",
		description = "Contains all spells whose ID contains 'IF_'. By default this includes all Requirement spells. You won't get spells from this pack that you haven't unlocked.",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-arcanescripting.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "autogen",
        cards_in_pack = 5,
        weight = 1,
        limit_per_run = -1,
        validation_callback = nil,
        actions = generate_pack_contents( filter_id_contains( "IF_" ) )
    },
	{
        id = "autogen_unlocks",
        name = "Secrets Unsealed",
		description = "Contains all spells which must be unlocked in some way. You won't get spells from this pack that you haven't unlocked.",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-premium.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "autogen",
        cards_in_pack = 5,
        weight = 1,
        limit_per_run = -1,
        validation_callback = nil,
        actions = generate_pack_contents( filter_requires_unlock )
    },
	{
        id = "autogen_colors",
        name = "Just Colours",
		description = "Contains all spells whose ID contains 'COLOUR_', by default this includes all colour modifiers",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-colors.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "autogen",
        cards_in_pack = 5,
        weight = 1,
        limit_per_run = -1,
        validation_callback = nil,
        actions = generate_pack_contents( filter_id_contains( "COLOUR_" ) )
    },
	{
        id = "autogen_divide",
        name = "Divide and Conquer",
		description = "Contains all spells whose ID contains 'DIVIDE_', by default this includes all divide by spells.",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-divide.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "autogen",
        cards_in_pack = 5,
        weight = 1,
        limit_per_run = -1,
        validation_callback = nil,
        actions = generate_pack_contents( filter_id_contains( "DIVIDE_" ) )
    },
	{
        id = "autogen_trigger",
        name = "Triggered",
		description = "Contains all spells whose ID contains '_TRIGGER', by default this includes all spells involving hit triggers.",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-triggered.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "autogen",
        cards_in_pack = 5,
        weight = 1,
        limit_per_run = -1,
        validation_callback = nil,
        actions = generate_pack_contents( filter_id_contains( "_TRIGGER" ) )
    },
	{
        id = "autogen_timed",
        name = "Time for Cast",
		description = "Contains all spells whose ID contains '_TIMER', by default this includes all spells involving timed triggers.",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-test.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "autogen",
        cards_in_pack = 5,
        weight = 1,
        limit_per_run = -1,
        validation_callback = nil,
        actions = generate_pack_contents( filter_id_contains( "_TIMER" ) )
    },
	{
        id = "autogen_death_trigger",
        name = "Death Trigger",
		description = "Contains all spells whose ID contains '_DEATH_TRIGGER', by default this includes all spells involving death triggers.",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-test.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "autogen",
        cards_in_pack = 5,
        weight = 1,
        limit_per_run = -1,
        validation_callback = nil,
        actions = generate_pack_contents( filter_id_contains( "_DEATH_TRIGGER" ) )
    },
	{
        id = "autogen_trails",
        name = "The Oracle Trail",
		description = "Contains all spells whose ID contains '_TRAIL', by default this includes all trail spells.",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-test.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "autogen",
        cards_in_pack = 5,
        weight = 1,
        limit_per_run = -1,
        validation_callback = nil,
        actions = generate_pack_contents( filter_id_contains( "_TRAIL" ) )
    },
	{
        id = "autogen_all",
        name = "Omnae Ex Magicae",
		description = "Contains all spells whose ID contains 'ALL_', by default this includes all projectile transformation spells.",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-premium.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "autogen",
        cards_in_pack = 3,
        weight = 1,
        limit_per_run = -1,
        validation_callback = nil,
        actions = generate_pack_contents( filter_id_contains( "ALL_" ) )
    },
	{
        id = "autogen_cheap_mana",
        name = "Cheapskate",
		description = "Contains all spells whose mana cost is smaller than 30.",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-test.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "autogen",
        cards_in_pack = 5,
        weight = 1,
        limit_per_run = -1,
        validation_callback = nil,
        actions = generate_pack_contents( filter_mana_cost_between( 0, 30 ) )
    },
	{
        id = "autogen_expensive_mana",
        name = "Manaburner",
		description = "Contains all spells whose mana cost is larger than 30.",
        image_filepath = "mods/gkbrkn_noita/files/gkbrkn/packs/pack-test.png", -- the path to the pack image
        custom_xml = nil, -- this would contain a pack entity that might have cool legendary effects		
        author = "autogen",
        cards_in_pack = 5,
        weight = 1,
        limit_per_run = -1,
        validation_callback = nil,
        actions = generate_pack_contents( filter_mana_cost_between( 30, 100000 ) )
    },
};