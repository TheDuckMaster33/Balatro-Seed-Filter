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

    if pack_type == 'Spectral' then
        if resample_count == 0 and pseudorandom('soul_' .. pack_type .. G.GAME.round_resets.ante) > 0.997 then
            return 'Black Hole'
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

function find_legendary_in_pack(pack_type, pack_size)
    local legendary = nil

    for _ = 1, pack_size do
        if pseudorandom('soul_' .. pack_type .. G.GAME.round_resets.ante) > 0.997 then
            legendary = find_next_card('Joker', 'sou', 0)
        end
    end

    return legendary
end

function are_legendaries_found(legendaries, legendaries_min_tag, legendaries_max_tag)
    local remaining_legendaries = {}
    for k, v in pairs(legendaries) do remaining_legendaries[k] = v end

    for tag_num = 1, legendaries_max_tag do
        local ante = math.floor((tag_num + 1) / 2)

        G.GAME.round_resets.ante = ante

        local tag = get_next_tag_key()

        if tag_num >= legendaries_min_tag then
            local found_legendary = nil

            if tag == "tag_charm" then
                found_legendary = find_legendary_in_pack('Tarot', 5)
            elseif tag == "tag_ethereal" then
                found_legendary = find_legendary_in_pack('Spectral', 2)
            end

            if found_legendary then
                for key, legendary in pairs(remaining_legendaries) do
                    local is_legendary_found = true

                    if legendary['name'] and legendary['name'] ~= found_legendary
                        or tag_num < legendary['at_least_tag']
                        or tag_num > legendary['at_most_tag'] then
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

function are_vouchers_found(vouchers, num_vouchers_to_analyse)
    local remaining_vouchers = {}
    for k, v in pairs(vouchers) do remaining_vouchers[k] = v end

    for voucher_num = 1, num_vouchers_to_analyse do
        G.GAME.round_resets.ante = voucher_num

        local voucher_key = get_next_voucher_key()

        for key, voucher in pairs(remaining_vouchers) do
            local is_voucher_found = true

            if voucher_key ~= voucher['name']
                or voucher_num < voucher['at_least_ante']
                or voucher_num > voucher['at_most_ante'] then
                is_voucher_found = false
            end

            if is_voucher_found then
                remaining_vouchers[key] = nil
                G.GAME.used_vouchers[voucher_key] = true

                if #remaining_vouchers == 0 then
                    G.GAME.round_resets.ante = 1
                    return true
                end

                break
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

function get_legendary_list_from_filter_criteria(filter_criteria)
    local legendaries = {}
    local legendaries_max_tag = nil
    local legendaries_min_tag = nil

    if filter_criteria.legendary then
        for _, legendary in ipairs(filter_criteria.legendary) do
            local name = legendary['name']
            local at_least_ante = legendary['at_least_ante'] or 0
            local at_most_ante = legendary['at_most_ante'] or at_least_ante

            local at_least_tag = at_least_ante == 0 and 1 or (at_least_ante * 2) - 1
            local at_most_tag = at_most_ante == 0 and 1 or (at_most_ante * 2)

            assert(at_least_tag <= at_most_tag)

            legendaries[#legendaries + 1] = { name = name, at_least_tag = at_least_tag, at_most_tag = at_most_tag }

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

    return legendaries, legendaries_max_tag, legendaries_min_tag
end

function get_voucher_list_from_filter_criteria(filter_criteria)
    local vouchers = {}
    local max_voucher_ante = nil

    if filter_criteria.voucher then
        for _, voucher in ipairs(filter_criteria.voucher) do
            local name = voucher['name']

            if name == "Overstock" then
                name = "v_overstock_norm"
            elseif name == "Director's Cut" then
                name = "v_directors_cut"
            else
                name = "v_" .. string.gsub(string.lower(name), " ", "_")
            end

            local at_least_ante = voucher['at_least_ante'] or 1
            local at_most_ante = voucher['at_most_ante'] or at_least_ante

            vouchers[#vouchers + 1] = { name = name, at_least_ante = at_least_ante, at_most_ante = at_most_ante }

            if max_voucher_ante == nil then
                max_voucher_ante = at_most_ante
            else
                max_voucher_ante = math.max(max_voucher_ante, at_most_ante)
            end
        end
    end

    return vouchers, max_voucher_ante
end

-- Generate a new seed according to the filter criteria
function generate_filtered_starting_seed(filter_criteria)
    local seed = nil
    local crack_count = 0

    G.GAME = G:init_game_object()

    legendaries, legendaries_max_tag, legendaries_min_tag = get_legendary_list_from_filter_criteria(filter_criteria)
    vouchers, max_voucher_ante = get_voucher_list_from_filter_criteria(filter_criteria)

    while true do
        repeat
            crack_count = crack_count + 1
            -- print(crack_count)

            seed = random_string(8)

            G.GAME.pseudorandom = {}
            G.GAME.pseudorandom.seed = seed
            G.GAME.pseudorandom.hashed_seed = pseudohash(seed)
            G.GAME.used_vouchers = {}

            if #legendaries > 0 then
                if not are_legendaries_found(legendaries, legendaries_min_tag, legendaries_max_tag) then
                    break
                end
            end

            if #vouchers > 0 then
                if not are_vouchers_found(vouchers, max_voucher_ante) then
                    break
                end
            end

            return seed
        until true
    end
end

local orginal_game_start_run = Game.start_run

local filter_criteria = {
    legendary = { { at_most_ante = 3 }, { at_most_ante = 3 } },
    -- legendary = { { name = "Triboulet", at_most_ante = 0 } },
    -- voucher = { { name = "Overstock", at_most_ante = 1 }, { name = "Telescope", at_most_ante = 2 } },
    -- joker = { name = "Blueprint", by_ante = 1 }
}

function Game:start_run(args)
    G.SETTINGS.tutorial_progress = nil
    args.seed = generate_filtered_starting_seed(filter_criteria)
    orginal_game_start_run(self, args)
end
