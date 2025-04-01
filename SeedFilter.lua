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

function find_next_card(pack_type, pack_type_seed_id, resample_count)
    if pack_type == "Tarot" or pack_type == "Spectral" then
        if resample_count == 0 and pseudorandom('soul_' .. pack_type .. G.GAME.round_resets.ante) > 0.997 then
            return 'Soul'
        end
    end

    local rarity = nil
    local center = nil

    if pack_type_seed_id == 'sou' then
        rarity = true
    end

    local _pool, _pool_key = get_current_pool(pack_type, nil, rarity, pack_type_seed_id)

    if resample_count > 0 then
        center = pseudorandom_element(_pool, pseudoseed(_pool_key .. '_resample' .. (resample_count + 1))) --
    else
        center = pseudorandom_element(_pool, pseudoseed(_pool_key))
    end

    return G.P_CENTERS[center].name
end

function find_all_cards_in_next_pack(pack_type, pack_size, pack_type_seed_id)
    local cards_in_pack = {}
    local card = nil

    for _ = 1, pack_size do
        local resample_count = 0

        while true do
            card = find_next_card(pack_type, pack_type_seed_id, resample_count)

            if cards_in_pack[card] == nil then
                cards_in_pack[card] = true
                break
            end

            resample_count = resample_count + 1
        end
    end

    return cards_in_pack
end

function is_legendary_in_pack(pack_type, pack_size)
    for _ = 1, pack_size do
        if pseudorandom('soul_' .. pack_type .. G.GAME.round_resets.ante) > 0.997 then
            return true
        end
    end

    return false
end

function find_legendary_in_arcana()
    if is_legendary_in_pack('Tarot', 5) then
        return find_next_card('Joker', 'sou', 0)
    end

    return nil
end

-- local _pool, _pool_key = get_current_pool('Joker', nil, true, 'sou')



-- function find_tarot_cards_in_next_mega_arcana_pack()
--     local tarot_cards_in_pack = {}
--     local resample_count = 0

--     for _ = 1, 5 do
--         resample_count = 0

--         while true do
--             tarot_card = find_next_tarot_card(resample_count)

--             if tarot_cards_in_pack[tarot_card] == nil then
--                 tarot_cards_in_pack[tarot_card] = true
--                 break
--             end

--             resample_count = resample_count + 1
--         end
--     end

--     return tarot_cards_in_pack
-- end






-- --- Find the next tarot card in the seed sequence
-- function find_next_tarot_card(resample_count)
--     if resample_count == 0 and pseudorandom('soul_' .. 'Tarot' .. G.GAME.round_resets.ante) > 0.997 then
--         return 'Soul'
--     else
--         local _pool, _pool_key = get_current_pool('Tarot', nil, nil, 'ar1')

--         if resample_count > 0 then
--             center = pseudorandom_element(_pool, pseudoseed(_pool_key .. '_resample' .. (resample_count + 1))) --
--         else
--             center = pseudorandom_element(_pool, pseudoseed(_pool_key))
--         end

--         return G.P_CENTERS[center].name
--     end
-- end

-- -- Find the next legendary joker in the seed sequence
-- function find_next_legendary_joker()
--     local _pool, _pool_key = get_current_pool('Joker', nil, true, 'sou')
--     center = pseudorandom_element(_pool, pseudoseed(_pool_key))
--     return G.P_CENTERS[center].name
-- end

-- Return all of the tarot cards in the next mega arcana pack (5 cards)



-- function get_num_tags_to_analyse(filter_criteria)
--     if filter_criteria.legendary then
--         if filter_criteria.legendary.by_ante then
--             if filter_criteria.legendary.by_ante == 0 then
--                 return 1
--             else
--                 return filter_criteria.legendary.by_ante * 2
--             end
--         else
--             return 1
--         end
--     end
-- end

-- function get_num_vouchers_to_analyse(filter_criteria)
--     if filter_criteria.voucher then
--         if filter_criteria.voucher.by_ante then
--             return math.max(1, filter_criteria.voucher.by_ante)
--         else
--             return 1
--         end
--     end
-- end

function are_legendaries_found(legendaries, legendaries_min_tag, legendaries_max_tag)
    -- local max_tags_to_analyse = ante_to_tag_num(legendaries_max_ante)

    local remaining_legendaries = {}
    for k, v in pairs(legendaries) do remaining_legendaries[k] = v end

    for tag_num = 1, legendaries_max_tag do
        local ante = math.floor((tag_num + 1) / 2) -- tag_num_to_ante(tag_num)

        G.GAME.round_resets.ante = ante

        -- local adjusted_ante = ante

        -- if tag_num == 1 then
        --     adjusted_ante = 0
        -- end

        local tag = get_next_tag_key()

        if tag_num >= legendaries_min_tag and tag == "tag_charm" then
            local found_legendary = find_legendary_in_arcana()

            if found_legendary then
                print(#remaining_legendaries)
                for key, legendary in ipairs(remaining_legendaries) do
                    local is_legendary_found = true

                    if legendary['name'] and legendary['name'] ~= found_legendary then
                        is_legendary_found = false
                    elseif tag_num < legendary['at_least_tag'] then
                        is_legendary_found = false
                    elseif tag_num > legendary['at_most_tag'] then
                        is_legendary_found = false
                    end

                    if is_legendary_found then
                        remaining_legendaries[key] = nil

                        if #remaining_legendaries == 0 then
                            G.GAME.round_resets.ante = 1
                            return true
                        end

                        break
                    end
                end
            end
        end
    end

    G.GAME.round_resets.ante = 1
    return false
end

-- function is_joker_found(joker, num_tags_to_analyse)
--     for tag_num = 1, num_tags_to_analyse do
--         G.GAME.round_resets.ante = math.floor((tag_num + 1) / 2)

--         local tag = get_next_tag_key()

--         if tag == "Buffoon" then
--             if found_joker_in_buffoon(joker) then
--                 print(tag_num)
--                 G.GAME.round_resets.ante = 1
--                 return true
--             end
--         end
--     end

--     G.GAME.round_resets.ante = 1
--     return false
-- end

-- function is_voucher_found(voucher, num_vouchers_to_analyse)
--     for voucher_num = 1, num_vouchers_to_analyse do
--         G.GAME.round_resets.ante = voucher_num

--         local voucher_name = nil

--         if voucher.name == "Overstock" then
--             voucher_name = "v_overstock_norm"
--         else
--             voucher_name = "v_" .. string.gsub(string.lower(voucher.name), " ", "_")
--         end

--         local voucher_key = get_next_voucher_key()

--         if voucher_name == voucher_key then
--             print(voucher_num)
--             G.GAME.round_resets.ante = 1
--             return true
--         end
--     end

--     G.GAME.round_resets.ante = 1
--     return false
-- end

-- function ante_to_tag_num(ante)
--     if ante then
--         return ante * 2
--     else
--         return 1
--     end
-- end

-- function tag_num_to_ante(tag_num)
--     return math.floor((tag_num + 1) / 2)
-- end

function ante_to_num_vouchers(ante)
    if ante then
        return ante
    else
        return 1
    end
end

-- Generate a new seed according to the filter criteria
function generate_filtered_starting_seed(filter_criteria)
    local seed = nil
    local crack_count = 0

    G.GAME = G:init_game_object()

    local legendaries = {}
    local legendaries_max_tag = nil
    local legendaries_min_tag = nil

    if filter_criteria.legendary then
        for _, legendary in ipairs(filter_criteria.legendary) do
            local name = legendary['name']
            local at_least_ante = legendary['at_least_ante'] or 0
            local at_most_ante = legendary['at_most_ante'] or math.maxinteger

            local at_least_tag = at_least_ante == 0 and 1 or (at_least_ante * 2) - 1
            local at_most_tag = at_most_ante == 0 and 1 or (at_most_ante * 2)

            print(at_least_tag)
            print(at_most_tag)

            assert(at_least_tag <= at_most_tag)

            legendaries[#legendaries + 1] = ({ name = name, at_least_tag = at_least_tag, at_most_tag = at_most_tag })

            if legendaries_max_tag == nil or legendaries_min_tag == nil then
                legendaries_max_tag = at_most_tag
                legendaries_min_tag = at_least_tag
            else
                legendaries_max_tag = math.max(legendaries_max_tag, at_most_tag)
                legendaries_min_tag = math.min(legendaries_min_tag, at_least_tag)
            end
        end
    end

    function sort_by_at_most_tag(card1, card2)
        return card1['at_most_tag'] < card2['at_most_tag']
    end

    table.sort(legendaries, sort_by_at_most_tag)

    -- local num_tags_to_analyse = get_num_tags_to_analyse(filter_criteria)
    -- local num_vouchers_to_analyse = get_num_vouchers_to_analyse(filter_criteria)


    while true do

        repeat
            crack_count = crack_count + 1
            -- print(crack_count)

            seed = random_string(8)

            G.GAME.pseudorandom = {}
            G.GAME.pseudorandom.seed = seed
            G.GAME.pseudorandom.hashed_seed = pseudohash(seed)

            if #legendaries > 0 then
                if not are_legendaries_found(legendaries, legendaries_min_tag, legendaries_max_tag) then
                    break
                end
            end

            -- if filter_criteria.voucher then
            --     if not is_voucher_found(filter_criteria.voucher, num_vouchers_to_analyse) then
            --         break
            --     end
            -- end

            return seed
        until true
    end
end

local orginal_game_start_run = Game.start_run

local filter_criteria = {
    legendary = { { at_most_ante = 0 } },

    -- legendary = { { name = "Triboulet", at_most_ante = 0 } },
    --   voucher = { name = "Overstock", by_ante = 1 },
    -- joker = { name = "Blueprint", by_ante = 1 }
}

function Game:start_run(args)
    G.SETTINGS.tutorial_progress = nil
    args.seed = generate_filtered_starting_seed(filter_criteria)
    orginal_game_start_run(self, args)
end
