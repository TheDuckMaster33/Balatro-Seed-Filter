local char_set = {
    '1', '2', '3', '4', '5', '6', '7', '8', '9',
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
    'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
    'U', 'V', 'W', 'X', 'Y', 'Z'
}

function optimised_random_string()
    local result = {}
    for i = 1, 8 do
        result[i] = char_set[math.random(35)]
    end

    return table.concat(result)
end

function optimised_pseudorandom_element(_t, seed)
    math.randomseed(seed)
    return _t[math.random(#_t)]
end

function optimised_pseudohash(str)
    local num = 1
    local byte = string.byte
    local pi = math.pi
    for i = #str, 1, -1 do
        num = ((1.1239285023 / num) * byte(str, i) * pi + pi * i) % 1
    end
    return num
end

function optimised_pseudoseed(key)
    if not pseudorandom[key] then
        pseudorandom[key] = optimised_pseudohash(key .. pseudorandom_seed)
    end

    local val = (2.134453429141 + pseudorandom[key] * 1.72431234) % 1
    pseudorandom[key] = math.floor(val * 1e13 + 0.5) / 1e13

    return (pseudorandom[key] + pseudorandom_hashed_seed) / 2
end

function optimised_pseudorandom(seed)
    math.randomseed(optimised_pseudoseed(seed))
    return math.random()
end

function optimised_get_tag_pool()
    return {
        'tag_uncommon',
        'tag_rare',
        'tag_negative',
        'tag_foil',
        'tag_holo',
        'tag_polychrome',
        'tag_investment',
        'tag_voucher',
        'tag_boss',
        'tag_standard',
        'tag_charm',
        'tag_meteor',
        'tag_buffoon',
        'tag_handy',
        'tag_garbage',
        'tag_ethereal',
        'tag_coupon',
        'tag_double',
        'tag_juggle',
        'tag_d_six',
        'tag_top_up',
        'tag_skip',
        'tag_orbital',
        'tag_economy'
    }, 'Tag' .. G.GAME.round_resets.ante
end

function optimised_get_next_tag_key()
    local _pool, _pool_key = optimised_get_tag_pool()
    return optimised_pseudorandom_element(_pool, optimised_pseudoseed(_pool_key))
end