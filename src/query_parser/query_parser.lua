function get_legendary_list_from_filter_criteria(filter_criteria)
    local legendaries = {}
    local legendaries_max_tag = nil
    local legendaries_min_tag = nil

    if filter_criteria.legendary then
        for _, legendary in ipairs(filter_criteria.legendary) do
            local name = legendary['name']
            local min_ante = legendary['min_ante'] or 0
            local max_ante = legendary['max_ante'] or min_ante

            local at_least_tag = min_ante == 0 and 1 or (min_ante * 2) - 1
            local at_most_tag = max_ante == 0 and 1 or (max_ante * 2)

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

    local petroglyph_max_ante = nil


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

            local min_ante = voucher['min_ante'] or 1
            local max_ante = voucher['max_ante'] or min_ante

            if name == "v_petroglyph" then
                petroglyph_max_ante = max_ante
            end

            vouchers[#vouchers + 1] = { name = name, min_ante = min_ante, max_ante = max_ante }

            if max_voucher_ante == nil then
                max_voucher_ante = max_ante
            else
                max_voucher_ante = math.max(max_voucher_ante, max_ante)
            end
        end
    end

    if max_voucher_ante and petroglyph_max_ante then
        max_voucher_ante = math.max(max_voucher_ante, petroglyph_max_ante + 1)
    end

    return vouchers, max_voucher_ante
end

function get_spectral_cards_list_from_filter_criteria(filter_criteria)
    local spectral_cards = {}
    local spectral_cards_max_tag = nil
    local spectral_cards_min_tag = nil

    if filter_criteria.spectral then
        for _, spectral_card in ipairs(filter_criteria.spectral) do
            local name = spectral_card['name']
            local min_ante = spectral_card['min_ante'] or 2
            local max_ante = spectral_card['max_ante'] or min_ante

            local at_least_tag = min_ante == 0 and 1 or (min_ante * 2) - 1
            local at_most_tag = max_ante == 0 and 1 or (max_ante * 2)
           
            assert(min_ante >= 2)
            assert(at_least_tag <= at_most_tag)

            spectral_cards[#spectral_cards + 1] = { name = name, at_least_tag = at_least_tag, at_most_tag = at_most_tag }

            if spectral_cards_max_tag == nil or spectral_cards_min_tag == nil then
                spectral_cards_max_tag = at_most_tag
                spectral_cards_min_tag = at_least_tag
            else
                spectral_cards_max_tag = math.max(spectral_cards_max_tag, at_most_tag)
                spectral_cards_min_tag = math.min(spectral_cards_min_tag, at_least_tag)
            end
        end
    end

    function sort_by_at_most_tag(card1, card2)
        return card1['at_most_tag'] < card2['at_most_tag']
    end

    table.sort(spectral_cards, sort_by_at_most_tag)

    return spectral_cards, spectral_cards_max_tag, spectral_cards_min_tag
end

function parse_yaml(yaml_string)
    local filter_criteria = {}
    local current_header = nil

    for line in yaml_string:gmatch("[^\r\n]+") do
        local empty = line:match("^%s*$") or line:match("^%s*//.*$")
        local header =
            line:match("^%s*([^-:]+):%s*$") or
            line:match("^%s*([^-:]+):%s*//.*$")

        local key, value = line:match("^%s*-%s*([^:]+)%s*:%s*(.+)%s*$")
        if key == nil then
            line:match("^%s*-%s*([^:]+)%s*:%s*(.+)%s*//.*$")
        end

        if header and empty or key and empty or header and key then
            -- print("Query invalid") -- Should never occur according to our regex definitions
            return nil, "Query invalid"
        end

        if not (empty or header or key or value) then
            -- print("Query line invalid:\n" .. line)
            -- print("\nPlease add a query header or item field. See documentation for more details.")

            if line:match("^%s*([^-:]+)%s*$") or line:match("^%s*([^-:]+)%s*//.*$") then
                return nil,
                    "Query line invalid:\n" ..
                    line ..
                    "\nPlease add a query header or item field: did you forget a colon ':'? See documentation for more details."


                -- print(
                --     "\nPlease add a query header or item field: did you forget a colon ':'? See documentation for more details.")
            elseif line:match("^%s*%s*([^:]+)%s*:%s*(.+)%s*$") or line:match("^%s*%s*([^:]+)%s*:%s*(.+)%s*//.*$") then
                return nil,
                    "Query line invalid:\n" ..
                    line ..
                    "\nPlease add a query header or item field: did you forget a hyphen '-'? See documentation for more details."
            else
                return nil,
                    "Query line invalid:\n" ..
                    line .. "\nPlease add a query header or item field. See documentation for more details."
            end
        end

        if header then
            if not (header == "legendary" or header == "voucher" or header == "spectral") then
                return nil,
                    "Query line invalid:\n" ..
                    line ..
                    "\nPlease add a valid header (legendary, voucher, spectral). See documentation for more details."
            end

            current_header = header

            if not filter_criteria[current_header] then
                filter_criteria[current_header] = { {} }
            else
                local filter_criteria_header = filter_criteria[current_header]
                filter_criteria_header[#filter_criteria_header + 1] = {}
            end
        end

        if key then
            value = value:gsub("%s+", "")

            if current_header == "legendary" then
                local legendary_filter_criteria = filter_criteria["legendary"]

                if key == "name" then
                    if value == "Any" then
                        legendary_filter_criteria[#legendary_filter_criteria]["name"] = nil
                    end
                    legendary_filter_criteria[#legendary_filter_criteria]["name"] = value
                elseif key == "max_ante" then
                    legendary_filter_criteria[#legendary_filter_criteria]["max_ante"] = tonumber(value)
                elseif key == "min_ante" then
                    legendary_filter_criteria[#legendary_filter_criteria]["min_ante"] = tonumber(value)
                else
                    return nil,
                        "Query line invalid:\n" ..
                        line ..
                        "\nPlease include a valid field key (name, max_ante, min_ante). See documentation for more details."
                end
            elseif current_header == "voucher" then
                local voucher_filter_criteria = filter_criteria["voucher"]

                if key == "name" then
                    voucher_filter_criteria[#voucher_filter_criteria]["name"] = value
                elseif key == "max_ante" then
                    voucher_filter_criteria[#voucher_filter_criteria]["max_ante"] = tonumber(value)
                elseif key == "min_ante" then
                    voucher_filter_criteria[#voucher_filter_criteria]["min_ante"] = tonumber(value)
                else
                    return nil, "Query line invalid:\n" ..
                        line ..
                        "\nPlease include a valid field key (name, max_ante, min_ante). See documentation for more details."
                end
            elseif current_header == "spectral" then
                local spectral_filter_criteria = filter_criteria["spectral"]

                if key == "name" then
                    spectral_filter_criteria[#spectral_filter_criteria]["name"] = value
                elseif key == "max_ante" then
                    spectral_filter_criteria[#spectral_filter_criteria]["max_ante"] = tonumber(value)
                elseif key == "min_ante" then
                    spectral_filter_criteria[#spectral_filter_criteria]["min_ante"] = tonumber(value)
                else
                    return nil, "Query line invalid:\n" ..
                        line ..
                        "\nPlease include a valid field key (name, max_ante, min_ante). See documentation for more details."
                end
            else
                if not current_header then
                    return nil, "Query line invalid:\n" ..
                        line ..
                        "\nPlease include a valid header (legendary, voucher, spectral) before the item field. See documentation for more details."
                end
            end
        end
    end

    return filter_criteria, nil
end
