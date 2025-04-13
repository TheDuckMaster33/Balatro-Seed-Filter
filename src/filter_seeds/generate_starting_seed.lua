function satisfies_filter(filter)
    if filter.type == "legendary" then
        for tag = filter.min_tag, filter.max_tag do
            local ante = math.floor((tag + 1) / 2)

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

function generate_filtered_starting_seed()
    filter_yaml = [[
        Legendary:
            - name: Any
    ]]

    filter_query, err = parse_yaml(filter_yaml)

    if err then 
        return
    end 

    for key, val in pairs(filter_query[1]) do
        print(key)
        print(val)
    end

    filters, err = validate_query(filter_query)

    if err then 
        return 
    end 

    for key, val in pairs(filters[1]) do
        print(key)
        print(val)
    end

    -- filters = {
    --     {
    --         type = 'legendary',
    --         name = 'any',
    --         min_tag = 1,
    --         max_tag = 2,
    --     },
    --     {
    --         type = 'legendary',
    --         name = 'any',
    --         min_tag = 2,
    --         max_tag = 6,
    --     },
    -- }

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
