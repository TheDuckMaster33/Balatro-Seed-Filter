local orginal_game_start_run = Game.start_run

function Game:start_run(args)
    -- profiler.start()

    -- for _ = 1, 10 do 
    --     generate_filtered_starting_seed()
    -- end 

    -- profiler.stop()

    -- print(profiler.report(20))
    -- profiler.reset()

    args.seed = generate_filtered_starting_seed()

    orginal_game_start_run(self, args)
end
