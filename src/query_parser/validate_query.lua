function ante_to_tag(ante, is_max)
    if ante == 0 then
        return 1
    elseif is_max then
        return ante * 2
    else
        return ante * 2 - 1
    end
end

function validate_query(filter_query)
    local validated_filter_query = {}

    for _, query_entry in pairs(filter_query) do
        local validated_query_entry = {}

        -- for key, val in pairs(query_entry) do validated_query_entry[key] = val end

        validated_query_entry["type"] = query_entry["type"]

        if not query_entry["name"] then
            return nil, "Please provide names for all legendaries (or 'Any' for any legendary joker)"
        end

        validated_query_entry["name"] = query_entry["name"]


        local min_ante = query_entry["min_ante"] or 0
        local max_ante = query_entry["max_ante"] or min_ante

        validated_query_entry["min_tag"] = ante_to_tag(min_ante, false)
        validated_query_entry["max_tag"] = ante_to_tag(max_ante, true)


        -- if not query_entry["min_ante"] then
        --     validated_query_entry["min_ante"] = 0
        -- end

        -- if not query_entry["max_ante"] then
        --     validated_query_entry["max_ante"] = validated_query_entry["min_ante"]
        -- end

        validated_filter_query[#validated_filter_query + 1] = validated_query_entry
    end

    return validated_filter_query, nil
end
