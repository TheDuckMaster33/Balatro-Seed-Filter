filter_query = {}

local orginal_game_start_run = Game.start_run

function profile()
    profiler.start()

    for _ = 1, 10 do
        generate_filtered_starting_seed()
    end

    profiler.stop()

    print(profiler.report(20))
    profiler.reset()
end

function Game:start_run(args)
    args.seed = generate_filtered_starting_seed()
    orginal_game_start_run(self, args)
end
