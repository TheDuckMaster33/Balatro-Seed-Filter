local orginal_game_start_run = Game.start_run

function Game:start_run(args)
    -- profile(generate_filtered_starting_seed, 100)

    args.seed = generate_filtered_starting_seed()

    orginal_game_start_run(self, args)
end
