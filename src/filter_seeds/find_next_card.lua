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


local legendaries = {
    "caino",
    "triboulet",
    "yorick",
    "chicot",
    "perkeo",
}

local found_legendaries = {} 

function generate_legendary()

    local resample_count = 0

    return optimised_pseudorandom_element(legendaries, "Jokerlegendary")
end 

function find_legendary_in_pack(ante, pack_type, pack_size, legendary_name)
    for _ = 1, pack_size do
        if optimised_pseudorandom('soul_' .. pack_type .. ante) > 0.997 then
            if legendary_name == "Any" then 
                return true
            else 
                return legendary_name == generate_legendary()
            end 
        end
    end
end

function find_legendary(ante, is_second_tag_in_ante, legendary_name)
    local pseudoseed = nil
    if is_second_tag_in_ante then
        optimised_pseudoseed('Tag' .. ante)
        pseudoseed = optimised_pseudoseed('Tag' .. ante)
    else
        pseudoseed = optimised_pseudoseed('Tag' .. ante)
    end

    math.randomseed(pseudoseed)

    if math.random(24) == 11 then
        find_legendary_in_pack(ante, "Tarot", 5)
    elseif ante >= 2 and math.random(24) == 15 then 
        find_legendary_in_pack(ante, "Spectral", 2)
    end 

    return false
end
