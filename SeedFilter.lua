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

--- Find the next tarot card in the seed sequence
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

-- Find the next legendary joker in the seed sequence
function find_next_legendary_joker()
    local _pool, _pool_key = get_current_pool('Joker', nil, true, 'sou')
    center = pseudorandom_element(_pool, pseudoseed(_pool_key))
    return G.P_CENTERS[center].name
end

-- Return all of the tarot cards in the next mega arcana pack (5 cards)
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

function found_legendary_in_arcana(legendary)
    local tarot_cards = find_tarot_cards_in_next_mega_arcana_pack()

    if tarot_cards['Soul'] then
        if legendary then
            return legendary.name == find_next_legendary_joker()
        else
            return true
        end
    end

    return false
end

function get_num_tags_to_analyse(filter_criteria)
    if filter_criteria.legendary then
        if filter_criteria.by_ante then
            if filter_criteria.by_ante == 0 then
                return 1
            else
                return filter_criteria.by_ante * 2
            end
        else
            return 1
        end
    end
end

function get_num_vouchers_to_analyse(filter_criteria)
    if filter_criteria.voucher then
        if filter_criteria.by_ante then
            return math.max(1, filter_criteria.by_ante)
        else
            return 1
        end
    end
end

function is_legendary_found(legendary, num_tags_to_analyse)
    for _ = 1, num_tags_to_analyse do

        local tag = get_next_tag_key()

        if tag == "tag_charm" then

            if found_legendary_in_arcana(legendary) then
                return true
            end
        end
    end

    return false
end

function is_voucher_found(voucher, num_vouchers_to_analyse)
    for _ = 1, num_vouchers_to_analyse do

        local voucher_name = nil 

        if voucher.name == "Overstock" then 
            voucher_name = "v_overstock_norm"
        else 
            voucher_name = "v_"..string.gsub(string.lower(voucher.name), " ", "_")
        end 

        local voucher_key = get_next_voucher_key()

        if voucher_name == voucher_key then
            return true
        end
    end

    return false
end

-- Generate a new seed according to the filter criteria
function generate_filtered_starting_seed(filter_criteria)
    local seed = nil
    local crack_count = 0

    G.GAME = G:init_game_object()

    local num_tags_to_analyse = get_num_tags_to_analyse(filter_criteria)
    local num_vouchers_to_analyse = get_num_vouchers_to_analyse(filter_criteria)

    while true do 
        repeat
            crack_count = crack_count + 1
            -- print(crack_count)

            seed = random_string(8)

            G.GAME.pseudorandom = {}
            G.GAME.pseudorandom.seed = seed
            G.GAME.pseudorandom.hashed_seed = pseudohash(seed)

            if filter_criteria.legendary then
                if not is_legendary_found(filter_criteria.legendary, num_tags_to_analyse) then
                    break
                end
            end

            if filter_criteria.voucher then
                if not is_voucher_found(filter_criteria.voucher, num_vouchers_to_analyse) then
                    break
                end
            end

            return seed
        until true
    end 

    -- first_tag = get_next_tag_key()
    -- second_tag = get_next_tag_key()


    -- if filter_criteria.legendary then
    --     first_tag = get_next_tag_key()
    --     second_tag = get_next_tag_key()

    --     if first_tag == "tag_charm" then
    --         local tarot_cards = find_tarot_cards_in_next_mega_arcana_pack()
    --         if found_legendary(filter_criteria.legendary) then
    --             return seed
    --         end
    --     end

    --     if second_tag == "tag_charm" then
    --         local tarot_cards = find_tarot_cards_in_next_mega_arcana_pack()
    --         if found_legendary(filter_criteria.legendary) then
    --             return seed
    --         end
    --     end
    -- end


    -- first_tag = get_next_tag_key()
    -- second_tag = get_next_tag_key()

    -- if first_tag == "tag_charm" then
    --     local tarot_cards = find_tarot_cards_in_next_mega_arcana_pack()
    --     if found_legendary()

    -- if first_tag == "tag_charm" then
    --     local tarot_cards = find_tarot_cards_in_next_mega_arcana_pack()

    --     if tarot_cards['Soul'] then
    --         local legendary_joker = find_next_legendary_joker()

    --         if legendary_joker == "Triboulet" then
    --             return seed
    --         end
    --     end
    -- end

    -- if second_tag == "tag_charm" then
    --     local tarot_cards = find_tarot_cards_in_next_mega_arcana_pack()

    --     if tarot_cards['Soul'] then
    --         print(find_next_legendary_joker())
    --         return seed
    --     end
    -- end

    -- if second_tag == "tag_charm" then
    --     tarot_cards = find_tarot_cards_in_next_mega_arcana_pack()
    -- end
end

local orginal_game_start_run = Game.start_run

local filter_criteria = { legendary = { name = "Triboulet", by_ante = 0 }, voucher = { name = "Overstock", by_ante = 1 } }

function Game:start_run(args)
    G.SETTINGS.tutorial_progress = nil
    args.seed = generate_filtered_starting_seed(filter_criteria)
    orginal_game_start_run(self, args)
end
