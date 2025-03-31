require "functions/misc_functions"
require "functions/common_events"

-- Seed generation code copied from Balatro source code (for some reason, calling the function directly from the source does not produce the correct results)
function pseudoseed(key, predict_seed)
    if key == 'seed' then return math.random() end

    if predict_seed then
        local _pseed = pseudohash(key .. (predict_seed or ''))
        _pseed = math.abs(tonumber(string.format("%.13f", (2.134453429141 + _pseed * 1.72431234) % 1)))
        return (_pseed + (pseudohash(predict_seed) or 0)) / 2
    end

    if not G.GAME.pseudorandom[key] then
        G.GAME.pseudorandom[key] = pseudohash(key .. (G.GAME.pseudorandom.seed or ''))
    end

    G.GAME.pseudorandom[key] = math.abs(tonumber(string.format("%.13f",
        (2.134453429141 + G.GAME.pseudorandom[key] * 1.72431234) % 1)))
    return (G.GAME.pseudorandom[key] + (G.GAME.pseudorandom.hashed_seed or 0)) / 2
end

--- Generate the next tarot card in the seed sequence
function find_next_tarot_card(resample_count)
    if pseudorandom('soul_' .. 'Tarot' .. G.GAME.round_resets.ante) > 0.997 then
        return 'Soul'
    else
        local _pool, _pool_key = get_current_pool('Tarot', nil, nil, 'ar1')

        if resample_count > 0 then
            center = pseudorandom_element(_pool, pseudoseed(_pool_key .. '_resample' .. (resample_count + 1))) --
        else
            center = pseudorandom_element(_pool, pseudoseed(_pool_key))
        end

        return G.P_CENTERS[center].name
    end
end

-- Find all tarot cards in the next mega arcana pack (5 cards)
function find_tarot_cards_in_next_mega_arcana_pack()
    local tarot_cards_in_pack = {}
    local resample_count = 0

    for _ = 1, 5 do
        resample_count = 0

        while true do
            tarot_card = find_next_tarot_card(resample_count)

            if tarot_cards_in_pack[tarot_card] == nil then
                tarot_cards_in_pack[tarot_card] = true
                break
            end

            resample_count = resample_count + 1
        end
    end

    return tarot_cards_in_pack
end

-- Generate a new seed according to the filter criteria
function generate_filtered_starting_seed()
    local seed = nil
    local crack_count = 0

    while true do
        crack_count = crack_count + 1 
        print(crack_count)

        seed = random_string(8)

        G.GAME = G:init_game_object()
        G.GAME.pseudorandom.seed = seed
        G.GAME.pseudorandom.hashed_seed = pseudohash(seed)

        first_tag = get_next_tag_key()
        second_tag = get_next_tag_key()

        if first_tag == "tag_charm" then
            local tarot_cards = find_tarot_cards_in_next_mega_arcana_pack()
            
            if tarot_cards['Soul'] then
                return seed
            end
        end

        -- if second_tag == "tag_charm" then
        --     tarot_cards = find_tarot_cards_in_next_mega_arcana_pack()
        -- end

    end
end

local Orginal_game_start_run = Game.start_run

function Game:start_run(args)
    G.SETTINGS.tutorial_progress = nil
    args.seed = generate_filtered_starting_seed()
    Orginal_game_start_run(self, args)
end
