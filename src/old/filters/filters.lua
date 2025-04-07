-- Seed generation code copied from Balatro source code (for some reason, calling the function directly from the source does not produce the correct results)
function optimised_pseudoseed(key, predict_seed)
    if key == 'seed' then return math.random() end

    if predict_seed then
        local _pseed = optimised_pseudohash(key .. (predict_seed or ''))
        _pseed = math.abs(tonumber(string.format("%.13f", (2.134453429141 + _pseed * 1.72431234) % 1)))
        return (_pseed + (optimised_pseudohash(predict_seed) or 0)) / 2
    end

    if not G.GAME.pseudorandom[key] then
        G.GAME.pseudorandom[key] = optimised_pseudohash(key .. (G.GAME.pseudorandom.seed or ''))
    end

    G.GAME.pseudorandom[key] = math.abs(tonumber(string.format("%.13f",
        (2.134453429141 + G.GAME.pseudorandom[key] * 1.72431234) % 1)))
    return (G.GAME.pseudorandom[key] + (G.GAME.pseudorandom.hashed_seed or 0)) / 2
end

function find_next_card(pack_type, pack_type_seed_id, resample_count)
    if pack_type == "Tarot" or pack_type == "Spectral" then
        if resample_count == 0 and optimised_pseudorandom('soul_' .. pack_type .. G.GAME.round_resets.ante) > 0.997 then
            return 'Soul'
        end
    end

    if pack_type == 'Spectral' then
        if resample_count == 0 and optimised_pseudorandom('soul_' .. pack_type .. G.GAME.round_resets.ante) > 0.997 then
            return 'Black Hole'
        end
    end

    local rarity = nil
    local center = nil

    if pack_type_seed_id == 'sou' then
        rarity = true
    end

    local _pool, _pool_key = optimised_get_current_pool(pack_type, nil, rarity, pack_type_seed_id)

    if resample_count > 0 then
        center = optimised_pseudorandom_element(_pool, optimised_pseudoseed(_pool_key .. '_resample' .. (resample_count + 1))) --
    else
        center = optimised_pseudorandom_element(_pool, optimised_pseudoseed(_pool_key))
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
        if optimised_pseudorandom('soul_' .. pack_type .. G.GAME.round_resets.ante) > 0.997 then
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

        local tag = optimised_get_next_tag_key()

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

                    if legendary['name'] ~= "Any" and legendary['name'] ~= found_legendary
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
                or voucher_num < voucher['min_ante']
                or voucher_num > voucher['max_ante'] then
                is_voucher_found = false
            end

            if not is_voucher_found and voucher['name'] == "v_petroglyph" then
                G.GAME.round_resets.ante = voucher_num - 1

                voucher_key = get_next_voucher_key()
                is_voucher_found = true

                if voucher_key ~= voucher['name']
                    or (voucher_num - 1) < voucher['min_ante']
                    or (voucher_num - 1) > voucher['max_ante'] then
                    is_voucher_found = false
                end
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

function are_spectral_cards_found(spectral_cards, spectral_cards_min_tag, spectral_cards_max_tag)
    local remaining_spectral_cards = {}
    for k, v in pairs(spectral_cards) do remaining_spectral_cards[k] = v end

    for tag_num = 1, spectral_cards_max_tag do
        local ante = math.floor((tag_num + 1) / 2)

        G.GAME.round_resets.ante = ante

        local tag = optimised_get_next_tag_key()

        if tag_num >= spectral_cards_min_tag then
            local found_spectral_cards = find_all_cards_in_next_pack('Spectral', 2, 'spe')

            for key, spectral_card in pairs(remaining_spectral_cards) do
                local is_spectral_card_found = true

                if found_spectral_cards[spectral_card['name']] == nil or tag_num < spectral_card['at_least_tag']
                    or tag_num > spectral_card['at_most_tag'] then
                    is_spectral_card_found = false
                end

                if is_spectral_card_found then
                    remaining_spectral_cards[key] = nil

                    if #remaining_spectral_cards == 0 then
                        G.GAME.round_resets.ante = 1
                        return true
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

