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
            if not (header == "legendary" or header == "voucher") then
                return nil,
                    "Query line invalid:\n" ..
                    line .. "\nPlease add a valid header (legendary, voucher). See documentation for more details."
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
            else
                if not current_header then
                    return nil, "Query line invalid:\n" ..
                        line ..
                        "\nPlease include a valid header (legendary, voucher) before the item field. See documentation for more details."
                end
            end
        end
    end

    return filter_criteria, nil
end
