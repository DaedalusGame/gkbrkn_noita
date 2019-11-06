table.insert( actions,
{
    id          = "GKBRKN_ACTION_TEST",
    name 		= "Test Action",
    description = "For testing",
    sprite 		= "files/gkbrkn/action_undefined.png",
    sprite_unidentified = "files/gkbrkn/action_undefined.png",
    type 		= ACTION_TYPE_MODIFIER,
    spawn_level                       = "2,3,4,5,6",
    spawn_probability                 = "1,1,1,1,1",
    price = 100,
    mana = 7,
    action 		= function()
        c.fire_rate_wait = 0;
        current_reload_time = 0;
        c.extra_entities = c.extra_entities .. "files/gkbrkn/action_brain_worm.xml,";
        draw_actions( 1, true );
    end,
});
