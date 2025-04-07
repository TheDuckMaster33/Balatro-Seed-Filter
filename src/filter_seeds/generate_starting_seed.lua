local tag_to_ante = {
    [1] = 1,
    [2] = 1,
    [3] = 2,
    [4] = 2,
    [5] = 3,
    [6] = 3,
    [7] = 4,
    [8] = 4,
    [9] = 5,
    [10] = 5,
    [11] = 6,
    [12] = 6,
    [13] = 7,
    [14] = 7,
    [15] = 8,
    [16] = 8,
}

function satisfies_filter(filter)
    if filter.type == "Legendary" then
        for tag = filter.min_tag, filter.max_tag do
            local ante = nil

            if tag_to_ante[tag] then
                ante = tag_to_ante[tag]
            else
                ante = math.floor((tag + 1) / 2)
            end

            G.GAME.round_resets.ante = ante

            local is_second_tag_in_ante = (tag % 2 == 0)

            if find_legendary(is_second_tag_in_ante) then
                return true
            end
        end
    end

    return false
end

function satisfies_all_filters(filters)
    for _, filter in pairs(filters) do
        if not satisfies_filter(filter) then
            return false
        end
    end

    return true
end

-- seen_pseudoseeds = {}

function generate_filtered_starting_seed()
    filters = {
        {
            type = 'Legendary',
            name = 'Any',
            min_tag = 1,
            max_tag = 1,
        },
        {
            type = 'Legendary',
            name = 'Any',
            min_tag = 2,
            max_tag = 6,
        }
    }

    local counter = 1

    while true do
        if counter % 2000 == 0 then
            nuGC(nil, nil, true)
        end

        local seed = optimised_random_string()

        G.GAME.pseudorandom = {}
        G.GAME.pseudorandom.seed = seed
        G.GAME.pseudorandom.hashed_seed = optimised_pseudohash(seed)

        G.GAME.round_resets.ante = 1

        if satisfies_all_filters(filters) then
            return seed
        end

        counter = counter + 1
    end
end
