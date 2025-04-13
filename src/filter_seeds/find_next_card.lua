-- function find_next_card(pack_type, pack_type_seed_id, resample_count)
--     if pack_type == "Tarot" or pack_type == "Spectral" then
--         if resample_count == 0 and optimised_pseudorandom('soul_' .. pack_type .. G.GAME.round_resets.ante) > 0.997 then
--             return 'Soul'
--         end
--     end

--     if pack_type == 'Spectral' then
--         if resample_count == 0 and optimised_pseudorandom('soul_' .. pack_type .. G.GAME.round_resets.ante) > 0.997 then
--             return 'Black Hole'
--         end
--     end

--     local rarity = nil
--     local center = nil

--     if pack_type_seed_id == 'sou' then
--         rarity = true
--     end

--     local _pool, _pool_key = optimised_get_current_pool(pack_type, nil, rarity, pack_type_seed_id)

--     if resample_count > 0 then
--         center = optimised_pseudorandom_element(_pool,
--             optimised_pseudoseed(_pool_key .. '_resample' .. (resample_count + 1))) --
--     else
--         center = optimised_pseudorandom_element(_pool, optimised_pseudoseed(_pool_key))
--     end

--     return G.P_CENTERS[center].name
-- end

function find_legendary(is_second_tag_in_ante)
    local pseudoseed = nil
    if is_second_tag_in_ante then
        optimised_pseudoseed('Tag' .. G.GAME.round_resets.ante)
        pseudoseed = optimised_pseudoseed('Tag' .. G.GAME.round_resets.ante)
    else
        pseudoseed = optimised_pseudoseed('Tag' .. G.GAME.round_resets.ante)
    end

    math.randomseed(pseudoseed)

    if math.random(24) == 11 then
        for _ = 1, 5 do
            if optimised_pseudorandom('soul_' .. 'Tarot' .. G.GAME.round_resets.ante) > 0.997 then
                return true
            end
        end
    end

    return false
end
