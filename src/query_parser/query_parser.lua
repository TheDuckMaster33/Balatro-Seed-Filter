require("query_parser.validate_query")

function generate_query_error(line, error_msg)
    return "Query line invalid:\n" ..
        line ..
        "\n" .. error_msg
end

function parse_legendary_field(filter_query_entry, key, value)
    if key == "name" then
        if value == "any" then
            filter_query_entry["name"] = "any"
        else
            filter_query_entry["name"] = value
        end
    elseif key == "max_ante" then
        local ante = tonumber(value)
        filter_query_entry["max_ante"] = ante
        if ante < 0 or ante > 39 then
            return "Ante must be between 0 and 39 (inclusive)."
        end
    elseif key == "min_ante" then
        local ante = tonumber(value)
        filter_query_entry["min_ante"] = ante
        if ante < 0 or ante > 39 then
            return "Ante must be between 0 and 39 (inclusive)."
        end
    else
        return "Please include a valid field key (name, max_ante, min_ante). See documentation for more details."
    end
end

function parse_yaml(yaml_string)
    local filter_query = {}
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
            return nil, "Query invalid"
        end

        if not (empty or header or key or value) then
            local error_msg = nil

            if line:match("^%s*([^-:]+)%s*$") or line:match("^%s*([^-:]+)%s*//.*$") then
                error_msg =
                "Please add a query header or item field: did you forget a colon ':'? See documentation for more details."
            elseif line:match("^%s*%s*([^:]+)%s*:%s*(.+)%s*$") or line:match("^%s*%s*([^:]+)%s*:%s*(.+)%s*//.*$") then
                error_msg =
                "Please add a query header or item field: did you forget a hyphen '-'? See documentation for more details."
            else
                error_msg = "Please add a query header or item field. See documentation for more details."
            end

            return nil, generate_query_error(line, error_msg)
        end

        if header then
            header = string.lower(header)

            if not (header == "legendary" or header == "voucher" or header == "spectral") then
                return nil, generate_query_error(
                    "Please add a valid header (Legendary, Voucher, Spectral). See documentation for more details.")
            end

            current_header = header

            filter_query[#filter_query + 1] = { type = current_header }

            -- if not filter_query[current_header] then
            --     filter_query[current_header] = { {} }
            -- else
            --     local filter_query_header = filter_query[current_header]
            --     filter_query_header[#filter_query_header + 1] = {}
            -- end
        end

        if key then
            key = string.lower(key)
            value = value:gsub("%s+", "")
            value = string.lower(value)

            local filter_query_entry = filter_query[#filter_query]

            local error_msg = nil

            if current_header == "legendary" then
                error_msg = parse_legendary_field(filter_query_entry, key, value)
            end

            if error_msg then
                return nil, generate_query_error(error_msg)
            end
        end
    end

    local filter_query, err = validate_query(filter_query) 

    return filter_query, err
end

-- function parse_yaml(yaml_string)
--     local filter_query = {}
--     local current_header = nil

--     for line in yaml_string:gmatch("[^\r\n]+") do
--         local empty = line:match("^%s*$") or line:match("^%s*//.*$")
--         local header =
--             line:match("^%s*([^-:]+):%s*$") or
--             line:match("^%s*([^-:]+):%s*//.*$")

--         local key, value = line:match("^%s*-%s*([^:]+)%s*:%s*(.+)%s*$")
--         if key == nil then
--             line:match("^%s*-%s*([^:]+)%s*:%s*(.+)%s*//.*$")
--         end

--         if header and empty or key and empty or header and key then
--             return nil, "Query invalid"
--         end

--         if not (empty or header or key or value) then
--             local error_msg = nil

--             if line:match("^%s*([^-:]+)%s*$") or line:match("^%s*([^-:]+)%s*//.*$") then
--                 error_msg =
--                 "Please add a query header or item field: did you forget a colon ':'? See documentation for more details."
--             elseif line:match("^%s*%s*([^:]+)%s*:%s*(.+)%s*$") or line:match("^%s*%s*([^:]+)%s*:%s*(.+)%s*//.*$") then
--                 error_msg =
--                 "Please add a query header or item field: did you forget a hyphen '-'? See documentation for more details."
--             else
--                 error_msg = "Please add a query header or item field. See documentation for more details."
--             end

--             return nil, generate_query_error(line, error_msg)
--         end

--         if header then
--             if not (header == "legendary" or header == "voucher" or header == "spectral") then
--                 return nil, generate_query_error(
--                     "Please add a valid header (legendary, voucher, spectral). See documentation for more details.")
--             end

--             current_header = header

--             if not filter_query[current_header] then
--                 filter_query[current_header] = { {} }
--             else
--                 local filter_query_header = filter_query[current_header]
--                 filter_query_header[#filter_query_header + 1] = {}
--             end
--         end

--         if key then
--             value = value:gsub("%s+", "")

--             if current_header == "legendary" then
--                 local legendary_filter_query = filter_query["legendary"]

--                 if key == "name" then
--                     if value == "Any" then
--                         legendary_filter_query[#legendary_filter_query]["name"] = nil
--                     end
--                     legendary_filter_query[#legendary_filter_query]["name"] = value
--                 elseif key == "max_ante" then
--                     legendary_filter_query[#legendary_filter_query]["max_ante"] = tonumber(value)
--                 elseif key == "min_ante" then
--                     legendary_filter_query[#legendary_filter_query]["min_ante"] = tonumber(value)
--                 else
--                     return nil,
--                         "Query line invalid:\n" ..
--                         line ..
--                         "\nPlease include a valid field key (name, max_ante, min_ante). See documentation for more details."
--                 end
--             elseif current_header == "voucher" then
--                 local voucher_filter_query = filter_query["voucher"]

--                 if key == "name" then
--                     voucher_filter_query[#voucher_filter_query]["name"] = value
--                 elseif key == "max_ante" then
--                     voucher_filter_query[#voucher_filter_query]["max_ante"] = tonumber(value)
--                 elseif key == "min_ante" then
--                     voucher_filter_query[#voucher_filter_query]["min_ante"] = tonumber(value)
--                 else
--                     return nil, "Query line invalid:\n" ..
--                         line ..
--                         "\nPlease include a valid field key (name, max_ante, min_ante). See documentation for more details."
--                 end
--             elseif current_header == "spectral" then
--                 local spectral_filter_query = filter_query["spectral"]

--                 if key == "name" then
--                     spectral_filter_query[#spectral_filter_query]["name"] = value
--                 elseif key == "max_ante" then
--                     spectral_filter_query[#spectral_filter_query]["max_ante"] = tonumber(value)
--                 elseif key == "min_ante" then
--                     spectral_filter_query[#spectral_filter_query]["min_ante"] = tonumber(value)
--                 else
--                     return nil, "Query line invalid:\n" ..
--                         line ..
--                         "\nPlease include a valid field key (name, max_ante, min_ante). See documentation for more details."
--                 end
--             else
--                 if not current_header then
--                     return nil, "Query line invalid:\n" ..
--                         line ..
--                         "\nPlease include a valid header (legendary, voucher, spectral) before the item field. See documentation for more details."
--                 end
--             end
--         end
--     end

--     return filter_query, nil
-- end
