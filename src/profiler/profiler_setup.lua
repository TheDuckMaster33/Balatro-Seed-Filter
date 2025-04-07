function profile(func, iters)
    profiler.start()
    for _ = 1, iters do
        func()
    end

    profiler.stop()
    print(profiler.report(20))
    profiler.reset()
end

-- local orginal_game_splash_screen = Game.splash_screen

-- function Game:splash_screen()
--     profile()
--     orginal_game_splash_screen(self)
-- end
