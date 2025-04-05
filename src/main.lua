require "functions/misc_functions"
require "functions/common_events"

-- Generate a new seed according to the filter criteria
function generate_filtered_starting_seed(filter_criteria)
    local seed = nil
    local crack_count = 0

    local legendaries, legendaries_max_tag, legendaries_min_tag = get_legendary_list_from_filter_criteria(
        filter_criteria)
    local vouchers, max_voucher_ante = get_voucher_list_from_filter_criteria(filter_criteria)

    while true do
        repeat
            crack_count = crack_count + 1
            -- print(crack_count)

            seed = random_string(8)

            G.GAME.pseudorandom = {}
            G.GAME.pseudorandom.seed = seed
            G.GAME.pseudorandom.hashed_seed = pseudohash(seed)
            G.GAME.used_vouchers = {}

            if #legendaries > 0 then
                if not are_legendaries_found(legendaries, legendaries_min_tag, legendaries_max_tag) then
                    break
                end
            end

            if #vouchers > 0 then
                if not are_vouchers_found(vouchers, max_voucher_ante) then
                    break
                end
            end

            return seed
        until true
    end
end

local orginal_game_start_run = Game.start_run

filter_criteria = {}

function Game:start_run(args)
    -- local filter_criteria = parse_yaml(field.text)

    if filter_criteria == nil then
        return
    end

    G.SETTINGS.tutorial_progress = nil -- check this
    args.seed = generate_filtered_starting_seed(filter_criteria)
    orginal_game_start_run(self, args)
end
