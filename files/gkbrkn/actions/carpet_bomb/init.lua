dofile_once( "mods/gkbrkn_noita/files/gkbrkn/lib/helper.lua");
table.insert( actions, generate_action_entry(
    "GKBRKN_CARPET_BOMB", "carpet_bomb", ACTION_TYPE_OTHER,
    "0,1,2,3,4,5,6", "1,1,1,1,1,1,1", 100, 50, -1,
    nil,
    function()
        current_reload_time = current_reload_time + 30;
        local _current_reload_time = current_reload_time;
        if reflecting then 
            return;
        end
        local _deck = deck;
        local _hand = hand;
        local _discarded = discarded;
        gkbrkn.add_projectile_capture_callback = function( filepath )
            gkbrkn.add_projectile_capture_callback = nil;
            local captured_deck = nil;
            local old_c = c;
            BeginProjectile( filepath );
                BeginTriggerTimer( 2 );
                    c = {};
                    reset_modifiers( c );
                    c.speed_multiplier = 0;
                    c.gravity = c.gravity + 1000;
                    if captured_deck == nil then
                        captured_deck = capture_draw_actions( 1, true );
                        hand, discarded = {}, {};
                    end
                    state_per_cast( c );
                    register_action( c );
                    SetProjectileConfigs();
                EndTrigger();
                for i=1,10 do
                    BeginTriggerTimer( 2 + i * 2 );
                        reset_modifiers( c );
                        c.speed_multiplier = 0;
                        c.gravity = c.gravity + 1000;
                        deck = {};
                        for _,v in pairs( captured_deck ) do
                            table.insert( deck, v );
                        end
                        draw_actions( 1, true );
                        state_per_cast( c );
                        register_action( c );
                        SetProjectileConfigs();
                    EndTrigger();
                end
            EndProjectile();
            hand, discarded = _hand, _discarded;
            c = old_c;
            register_action( c );
            SetProjectileConfigs();
        end
        draw_actions( 1, true );
        deck = _deck;
        current_reload_time = _current_reload_time;
    end
) );