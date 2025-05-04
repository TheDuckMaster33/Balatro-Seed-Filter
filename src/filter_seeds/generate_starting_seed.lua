package.path = package.path .. ';../?.lua'

require("filter_seeds.find_next_card")
require("filter_seeds.pseudorandom")
require("query_parser.query_parser")

current_ante = nil
pseudorandom = nil
pseudorandom_seed = nil
pseudorandom_hashed_seed = nil

function satisfies_filter(filter)
    if filter.type == "legendary" then
        for tag = filter.min_tag, filter.max_tag do
            local ante = math.floor((tag + 1) / 2)

            current_ante = ante

            local is_second_tag_in_ante = (tag % 2 == 0)

            if find_legendary(ante, is_second_tag_in_ante, filter.name) then
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
    local file = io.open("../../filters/filter.sf", "r")

    if not file then
        print("File could not be opened")
        return nil
    end

    local filter_string = file:read("*all")

    file:close()

    local filter_query, err = parse_yaml(filter_string)

    if err then
        print(err)
        return nil
    end

    local counter = 1

    while true do
        if counter % 2000 == 0 then
            nuGC(nil, nil, true)
        end

        local seed = optimised_random_string()

        current_ante = 1
        pseudorandom = {}
        pseudorandom_seed = seed
        pseudorandom_hashed_seed = optimised_pseudohash(seed)

        if satisfies_all_filters(filter_query) then
            return seed
        end

        counter = counter + 1
    end
end

generate_filtered_starting_seed()
