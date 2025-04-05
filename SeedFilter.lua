require "functions/misc_functions"
require "functions/common_events"

-- Seed generation code copied from Balatro source code (for some reason, calling the function directly from the source does not produce the correct results)
function pseudoseed(key, predict_seed)
    if key == 'seed' then return math.random() end

    if predict_seed then
        local _pseed = pseudohash(key .. (predict_seed or ''))
        _pseed = math.abs(tonumber(string.format("%.13f", (2.134453429141 + _pseed * 1.72431234) % 1)))
        return (_pseed + (pseudohash(predict_seed) or 0)) / 2
    end

    if not G.GAME.pseudorandom[key] then
        G.GAME.pseudorandom[key] = pseudohash(key .. (G.GAME.pseudorandom.seed or ''))
    end

    G.GAME.pseudorandom[key] = math.abs(tonumber(string.format("%.13f",
        (2.134453429141 + G.GAME.pseudorandom[key] * 1.72431234) % 1)))
    return (G.GAME.pseudorandom[key] + (G.GAME.pseudorandom.hashed_seed or 0)) / 2
end

function find_next_card(pack_type, pack_type_seed_id, resample_count)
    if pack_type == "Tarot" or pack_type == "Spectral" then
        if resample_count == 0 and pseudorandom('soul_' .. pack_type .. G.GAME.round_resets.ante) > 0.997 then
            return 'Soul'
        end
    end

    if pack_type == 'Spectral' then
        if resample_count == 0 and pseudorandom('soul_' .. pack_type .. G.GAME.round_resets.ante) > 0.997 then
            return 'Black Hole'
        end
    end

    local rarity = nil
    local center = nil

    if pack_type_seed_id == 'sou' then
        rarity = true
    end

    local _pool, _pool_key = get_current_pool(pack_type, nil, rarity, pack_type_seed_id)

    if resample_count > 0 then
        center = pseudorandom_element(_pool, pseudoseed(_pool_key .. '_resample' .. (resample_count + 1))) --
    else
        center = pseudorandom_element(_pool, pseudoseed(_pool_key))
    end

    return G.P_CENTERS[center].name
end

function find_all_cards_in_next_pack(pack_type, pack_size, pack_type_seed_id)
    local cards_in_pack = {}
    local card = nil

    for _ = 1, pack_size do
        local resample_count = 0

        while true do
            card = find_next_card(pack_type, pack_type_seed_id, resample_count)

            if cards_in_pack[card] == nil then
                cards_in_pack[card] = true
                break
            end

            resample_count = resample_count + 1
        end
    end

    return cards_in_pack
end

function find_legendary_in_pack(pack_type, pack_size)
    local legendary = nil

    for _ = 1, pack_size do
        if pseudorandom('soul_' .. pack_type .. G.GAME.round_resets.ante) > 0.997 then
            legendary = find_next_card('Joker', 'sou', 0)
        end
    end

    return legendary
end

function are_legendaries_found(legendaries, legendaries_min_tag, legendaries_max_tag)
    local remaining_legendaries = {}
    for k, v in pairs(legendaries) do remaining_legendaries[k] = v end

    for tag_num = 1, legendaries_max_tag do
        local ante = math.floor((tag_num + 1) / 2)

        G.GAME.round_resets.ante = ante

        local tag = get_next_tag_key()

        if tag_num >= legendaries_min_tag then
            local found_legendary = nil

            if tag == "tag_charm" then
                found_legendary = find_legendary_in_pack('Tarot', 5)
            elseif tag == "tag_ethereal" then
                found_legendary = find_legendary_in_pack('Spectral', 2)
            end

            if found_legendary then
                for key, legendary in pairs(remaining_legendaries) do
                    local is_legendary_found = true

                    if legendary['name'] ~= "Any" and legendary['name'] ~= found_legendary
                        or tag_num < legendary['at_least_tag']
                        or tag_num > legendary['at_most_tag'] then
                        is_legendary_found = false
                    end

                    if is_legendary_found then
                        remaining_legendaries[key] = nil

                        if #remaining_legendaries == 0 then
                            G.GAME.round_resets.ante = 1
                            return true
                        end

                        break
                    end
                end
            end
        end
    end

    G.GAME.round_resets.ante = 1
    return false
end

function are_vouchers_found(vouchers, num_vouchers_to_analyse)
    local remaining_vouchers = {}
    for k, v in pairs(vouchers) do remaining_vouchers[k] = v end

    for voucher_num = 1, num_vouchers_to_analyse do
        G.GAME.round_resets.ante = voucher_num

        local voucher_key = get_next_voucher_key()

        for key, voucher in pairs(remaining_vouchers) do
            local is_voucher_found = true

            if voucher_key ~= voucher['name']
                or voucher_num < voucher['min_ante']
                or voucher_num > voucher['max_ante'] then
                is_voucher_found = false
            end

            if not is_voucher_found and voucher['name'] == "v_petroglyph" then
                G.GAME.round_resets.ante = voucher_num - 1

                voucher_key = get_next_voucher_key()
                is_voucher_found = true

                if voucher_key ~= voucher['name']
                    or (voucher_num - 1) < voucher['min_ante']
                    or (voucher_num - 1) > voucher['max_ante'] then
                    is_voucher_found = false
                end
            end

            if is_voucher_found then
                remaining_vouchers[key] = nil
                G.GAME.used_vouchers[voucher_key] = true

                if #remaining_vouchers == 0 then
                    G.GAME.round_resets.ante = 1
                    return true
                end

                break
            end
        end
    end

    G.GAME.round_resets.ante = 1
    return false
end

-- function is_joker_found(joker, num_tags_to_analyse)
--     for tag_num = 1, num_tags_to_analyse do
--         G.GAME.round_resets.ante = math.floor((tag_num + 1) / 2)

--         local tag = get_next_tag_key()

--         if tag == "Buffoon" then
--             if found_joker_in_buffoon(joker) then
--                 print(tag_num)
--                 G.GAME.round_resets.ante = 1
--                 return true
--             end
--         end
--     end

--     G.GAME.round_resets.ante = 1
--     return false
-- end

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

local function parse_yaml(yaml_string)
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
            print("Query invalid") -- Should never occur according to our regex definitions
            return nil
        end

        if not (empty or header or key or value) then
            print("Query line invalid:\n" .. line)
            print("\nPlease add a query header or item field. See documentation for more details.")

            if line:match("^%s*([^-:]+)%s*$") or line:match("^%s*([^-:]+)%s*//.*$") then
                print(
                    "\nPlease add a query header or item field: did you forget a colon ':'? See documentation for more details.")
            elseif line:match("^%s*%s*([^:]+)%s*:%s*(.+)%s*$") or line:match("^%s*%s*([^:]+)%s*:%s*(.+)%s*//.*$") then
                print(
                    "\nPlease add a query header or item field: did you forget a hyphen '-'? See documentation for more details.")
            else
                print("\nPlease add a query header or item field. See documentation for more details.")
            end

            return nil
        end

        if header then
            if not (header == "legendary" or header == "voucher") then
                print("Query line invalid:\n" .. line)
                print("\nPlease add a valid header (legendary, voucher). See documentation for more details.")
                return nil
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
                    print("Query line invalid:\n" .. line)
                    print(
                        "\nPlease include a valid field key (name, max_ante, min_ante). See documentation for more details.")
                    return nil
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
                    print("Query line invalid:\n" .. line)
                    print(
                        "\nPlease include a valid field key (name, max_ante, min_ante). See documentation for more details.")
                    return nil
                end
            else
                if not current_header then
                    print("Query line invalid:\n" .. line)
                    print(
                        "\nPlease include a valid header (legendary, voucher) before the item field. See documentation for more details.")
                    return nil
                end
            end
        end
    end

    return filter_criteria
end

local orginal_game_start_run = Game.start_run

original_love_draw = love.draw

InputField = SMODS.load_file("InputField.lua")()


love.keyboard.setKeyRepeat(true)

local FONT_SIZE        = 20
local FONT_LINE_HEIGHT = 1.3

local FIELD_TYPE       = "multiwrap" -- Possible values: normal, password, multiwrap, multinowrap



local FIELD_OUTER_X      = nil
local FIELD_OUTER_Y      = nil
local FIELD_OUTER_WIDTH  = nil
local FIELD_OUTER_HEIGHT = nil
local FIELD_PADDING      = 6

local FIELD_INNER_X      = nil
local FIELD_INNER_Y      = nil
local FIELD_INNER_WIDTH  = nil
local FIELD_INNER_HEIGHT = nil

function recalculate_field_size()
    FIELD_OUTER_X      = love.graphics.getWidth() * 0.17
    FIELD_OUTER_Y      = love.graphics.getHeight() * 0.16
    FIELD_OUTER_WIDTH  = love.graphics.getWidth() * 0.65
    FIELD_OUTER_HEIGHT = love.graphics.getHeight() * 0.45

    FIELD_INNER_X      = FIELD_OUTER_X + FIELD_PADDING
    FIELD_INNER_Y      = FIELD_OUTER_Y + FIELD_PADDING
    FIELD_INNER_WIDTH  = FIELD_OUTER_WIDTH - 2 * FIELD_PADDING
    FIELD_INNER_HEIGHT = FIELD_OUTER_HEIGHT - 2 * FIELD_PADDING
end

recalculate_field_size() 

local SCROLLBAR_WIDTH = 5
local BLINK_INTERVAL  = 0.90

love.keyboard.setKeyRepeat(true)

local theFont = love.graphics.newFont(FONT_SIZE)
theFont:setLineHeight(FONT_LINE_HEIGHT)

local field = InputField("", FIELD_TYPE)
field:setFont(theFont)
field:setDimensions(FIELD_INNER_WIDTH, FIELD_INNER_HEIGHT)


original_keypressed = love.keypressed

-- print(original_keypressed)

function love.keypressed(key, scancode, isRepeat)
    original_keypressed(key, scancode, isRepeat)
    field:keypressed(key, isRepeat)
end

function love.textinput(text)
    field:textinput(text)
end

original_mousepressed = love.mousepressed

function love.mousepressed(mx, my, mbutton, pressCount)
    original_mousepressed(mx, my, mbutton, pressCount)
    field:mousepressed(mx - FIELD_INNER_X, my - FIELD_INNER_Y, mbutton, pressCount)
end

original_mousemoved = love.mousemoved

function love.mousemoved(mx, my, dx, dy)
    original_mousemoved(mx, my, dx, dy)
    field:mousemoved(mx - FIELD_INNER_X, my - FIELD_INNER_Y)
end

original_mousereleased = love.mousereleased

function love.mousereleased(mx, my, mbutton, pressCount)
    original_mousereleased(mx, my, mbutton, pressCount)
    field:mousereleased(mx - FIELD_INNER_X, my - FIELD_INNER_Y, mbutton)
end

function love.wheelmoved(dx, dy)
    field:wheelmoved(dx, dy)
end

original_update = love.update

local should_draw_seed_filter_textbox = false

function love.update(dt)
    -- should_draw_seed_filter_textbox = false
    original_update(dt)
    field:update(dt)
end

local extraFont = love.graphics.newFont(12)

function draw_seed_filter_textbox()
    love.graphics.setScissor(FIELD_OUTER_X, FIELD_OUTER_Y, FIELD_OUTER_WIDTH, FIELD_OUTER_HEIGHT)

    -- Background.
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", FIELD_OUTER_X, FIELD_OUTER_Y, FIELD_OUTER_WIDTH, FIELD_OUTER_HEIGHT)

    -- Selection.
    love.graphics.setColor(.2, .2, 1)
    for _, selectionX, selectionY, selectionWidth, selectionHeight in field:eachSelection() do
        love.graphics.rectangle("fill", FIELD_INNER_X + selectionX, FIELD_INNER_Y + selectionY, selectionWidth,
            selectionHeight)
    end

    -- Text.
    love.graphics.setFont(theFont)
    love.graphics.setColor(1, 1, 1)
    for _, lineText, lineX, lineY in field:eachVisibleLine() do
        love.graphics.print(lineText, FIELD_INNER_X + lineX, FIELD_INNER_Y + lineY)
    end

    -- Cursor.
    local cursorWidth = 2
    local cursorX, cursorY, cursorHeight = field:getCursorLayout()
    local alpha = ((field:getBlinkPhase() / BLINK_INTERVAL) % 1 < .5) and 1 or 0
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.rectangle("fill", FIELD_INNER_X + cursorX - cursorWidth / 2, FIELD_INNER_Y + cursorY, cursorWidth,
        cursorHeight)

    love.graphics.setScissor()

    --
    -- Scrollbars.
    --
    local horiOffset, horiCoverage, vertOffset, vertCoverage = field:getScrollHandles()

    local horiHandleLength                                   = horiCoverage * FIELD_OUTER_WIDTH
    local vertHandleLength                                   = vertCoverage * FIELD_OUTER_HEIGHT
    local horiHandlePos                                      = horiOffset * FIELD_OUTER_WIDTH
    local vertHandlePos                                      = vertOffset * FIELD_OUTER_HEIGHT

    -- Backgrounds.
    love.graphics.setColor(0, 0, 0, .3)
    love.graphics.rectangle("fill", FIELD_OUTER_X + FIELD_OUTER_WIDTH, FIELD_OUTER_Y, SCROLLBAR_WIDTH, FIELD_OUTER_HEIGHT) -- Vertical scrollbar.
    love.graphics.rectangle("fill", FIELD_OUTER_X, FIELD_OUTER_Y + FIELD_OUTER_HEIGHT, FIELD_OUTER_WIDTH, SCROLLBAR_WIDTH) -- Horizontal scrollbar.

    -- Handles.
    love.graphics.setColor(.7, .7, .7)
    love.graphics.rectangle("fill", FIELD_OUTER_X + FIELD_OUTER_WIDTH, FIELD_OUTER_Y + vertHandlePos, SCROLLBAR_WIDTH,
        vertHandleLength) -- Vertical scrollbar.
    love.graphics.rectangle("fill", FIELD_OUTER_X + horiHandlePos, FIELD_OUTER_Y + FIELD_OUTER_HEIGHT, horiHandleLength,
        SCROLLBAR_WIDTH)  -- Horizontal scrollbar.
end

function love.draw()
    original_love_draw()

    if should_draw_seed_filter_textbox then
        draw_seed_filter_textbox()
    end
end

function should_draw_seed_filter_textbox_fun()
    should_draw_seed_filter_textbox = true
end

local tabs = nil
local submit_status_node = { n = G.UIT.T, config = { text = "Hello, world!", colour = G.C.UI.TEXT_LIGHT, scale = 0.5 } }

local seed_filter_ui = {
    n = G.UIT.ROOT,
    config = {
        align = "cm",
        padding = 0.05,
        colour = G.C.CLEAR,
    },
    nodes = {
        {
            n = G.UIT.C,
            config = { minw = 15, minh = 4, align = "c", colour = G.C.MONEY },
            nodes = {
                {
                    n = G.UIT.R,
                    config = { minw = 15, minh = 6, align = "cm", colour = G.C.WHITE },
                    nodes = {
                        UIBox({
                            definition = {
                                n = G.UIT.R,
                                config = { minw = 15, minh = 6, align = "cm", colour = G.C.WHITE }
                            },
                            config = { align = "tm", colour = G.C.WHITE }
                        })
                    }
                },

                {
                    n = G.UIT.R,
                    config = { minw = 2, minh = 2, colour = G.C.RED },
                    nodes = {
                        {
                            n = G.UIT.C,
                            config = { minw = 1, minh = 1, colour = G.C.BLUE },
                            nodes = {
                                UIBox_button({
                                    button = 'apply_filter_criteria_changes',
                                    label = { "Apply" },
                                    minw = 3,
                                    func =
                                    'filter_criteria_apply_button_UI'
                                }),
                            }
                        },
                        {
                            n = G.UIT.C,
                            config = { minw = 1, minh = 1, colour = G.C.BLUE },
                            nodes = {
                                UIBox_button({
                                    button = 'discard_filter_criteria_changes',
                                    label = { "Discard" },
                                    minw = 3,
                                    func =
                                    'filter_criteria_discard_button_UI'
                                }),
                            }
                        }
                    }
                },

                {
                    n = G.UIT.R,
                    config = { minw = 2, minh = 1, align = "cm", colour = G.C.RED },
                    nodes = {
                        submit_status_node
                    }
                }
            }
        },
    },
}

function tab_definition_function()
    -- print(seed_filter_ui.nodes[1].nodes[1].nodes[1].VT.x)

    -- seed_filter_ui.nodes[1].nodes[1].nodes[1].config.button = "apply_filter_criteria_changes"
    -- seed_filter_ui.nodes[1].nodes[2].nodes[1].config.button = "discard_filter_criteria_changes"

    -- print(seed_filter_ui.nodes[1])

    should_draw_seed_filter_textbox_fun()
    return seed_filter_ui
end

local seed_filter_tab = {
    label = "Seed Filter",
    tab_definition_function = tab_definition_function,
    tab_definition_function_args = "Seed Filter",
}

local original_resize = love.resize

function love.resize(w, h)
    original_resize(w, h)

    -- local x = seed_filter_ui.nodes[1].nodes[1].nodes[1].UIRoot.parent
    -- local transform = x.VT or x.T
    -- print(transform.x*G.TILESIZE)
    -- print()
    -- print(seed_filter_ui.nodes[1].nodes[1].nodes[1].calculate_xywh(seed_filter_ui.nodes[1].nodes[1].nodes[1].UIRoot, seed_filter_ui.nodes[1].nodes[1].nodes[1].T, true))
    -- print(seed_filter_ui.nodes[1].nodes[1].nodes[1].T.w * G.TILESCALE) -- G.TILESIZE
    -- print(seed_filter_ui.nodes[1].nodes[1].nodes[1].VT.w * G.TILESCALE)
    -- FIELD_OUTER_X      = love.graphics.getWidth() * 0.15
    -- FIELD_OUTER_Y      = love.graphics.getHeight() * 0.15
    -- FIELD_OUTER_WIDTH  = love.graphics.getWidth() * 0.65
    -- FIELD_OUTER_HEIGHT = love.graphics.getHeight() * 0.45

    -- FIELD_INNER_X      = FIELD_OUTER_X + FIELD_PADDING
    -- FIELD_INNER_Y      = FIELD_OUTER_Y + FIELD_PADDING
    -- FIELD_INNER_WIDTH  = FIELD_OUTER_WIDTH - 2 * FIELD_PADDING
    -- FIELD_INNER_HEIGHT = FIELD_OUTER_HEIGHT - 2 * FIELD_PADDING

    recalculate_field_size()
end

local submitted_filter_criteria = ""

local z = nil

function UIElement:click()
    if self.config.button and (not self.last_clicked or self.last_clicked + 0.1 < G.TIMERS.REAL) and self.states.visible and not self.under_overlay and not self.disable_button then
        if self.config.one_press then self.disable_button = true end
        self.last_clicked = G.TIMERS.REAL

        --Removes a layer from the overlay menu stack
        if self.config.id == 'overlay_menu_back_button' then
            G.CONTROLLER:mod_cursor_context_layer(-1)
            G.NO_MOD_CURSOR_STACK = true
        end
        if G.OVERLAY_TUTORIAL and G.OVERLAY_TUTORIAL.button_listen == self.config.button then
            G.FUNCS.tut_next()
        end
        G.FUNCS[self.config.button](self)

        G.NO_MOD_CURSOR_STACK = nil

        if self.config.choice and field.text == submitted_filter_criteria then
            local choices = self.UIBox:get_group(nil, self.config.group)
            for k, v in pairs(choices) do
                if v.config and v.config.choice then v.config.chosen = false end
            end
            self.config.chosen = true
        end
        play_sound('button', 1, 0.3)
        G.ROOM.jiggle = G.ROOM.jiggle + 0.5
        self.button_clicked = true
    end
    if self.config.button_UIE then
        self.config.button_UIE:click()
    end
end

local original_options = G.FUNCS.options

function G.FUNCS.options()
    if field.text ~= submitted_filter_criteria then
        -- print(submit_status_node.config.text)
        submit_status_node.config.text = "Please submit or discard changes."

        -- tab_definition_function()

        args = args or {}
        args.colour = args.colour or G.C.RED
        args.tab_alignment = args.tab_alignment or 'cm'
        args.opt_callback = args.opt_callback or nil
        args.scale = args.scale or 1
        args.tab_w = args.tab_w or 0
        args.tab_h = args.tab_h or 0
        args.text_scale = (args.text_scale or 0.5)
        args.tabs = tabs

        -- seed_filter_tab.tab_definition_function()
        x = UIBox { definition = seed_filter_tab.tab_definition_function(), config = {} }
        UIBox.remove(x)

        return
    end

    should_draw_seed_filter_textbox = false
    original_options()
end

original_settings_tab = G.UIDEF.settings_tab

function G.UIDEF.settings_tab(tab)
    if field.text ~= submitted_filter_criteria then
        print("Please submit or discard changes.")
        print(field.text)
        print(submitted_filter_criteria)
        submit_status_node.config.text = "Please submit or discard changes."
        -- seed_filter_tab.chosen = true
        -- local tab_but = G.OVERLAY_MENU:get_UIE_by_ID('tab_but_Seed Filter')
        -- G.FUNCS.change_tab(seed_filter_tab)
        -- G.buttons:recalculate()
        -- G.HUD:recalculate()
        return seed_filter_ui
    end

    should_draw_seed_filter_textbox = false
    return original_settings_tab(tab)
end

-- original_create_UIBox_generic_options = create_UIBox_generic_options

-- function create_UIBox_generic_options(args)
--     if field.text ~= submitted_filter_criteria then
--         print("Please submit or discard changes.")
--         print(field.text)
--         print(submitted_filter_criteria)
--         submit_status_node.config.text = "Please submit or discard changes."

--     end

--     original_create_UIBox_generic_options(args)
-- end

local original_create_tabs = create_tabs



-- local filter_criteria_changed = false

function G.FUNCS.apply_filter_criteria_changes(_initial)
    submitted_filter_criteria = field.text
end

function G.FUNCS.discard_filter_criteria_changes(_initial)
    field.text = submitted_filter_criteria
    field:releaseMouse()

    field.cursorPosition           = 0
    field.selectionStart           = 0
    field.selectionEnd             = 0

    field.clickCount               = 1
    field.multiClickExpirationTime = 0

    field.navigationTargetX        = nil
end

function G.FUNCS.filter_criteria_apply_button_UI(e)
    if field.text ~= submitted_filter_criteria then
        e.config.button = 'apply_filter_criteria_changes'
        e.config.colour = G.C.GREEN
    else
        e.config.button = nil
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
    end
end

function G.FUNCS.filter_criteria_discard_button_UI(e)
    if field.text ~= submitted_filter_criteria then
        e.config.button = 'discard_filter_criteria_changes'
        e.config.colour = G.C.RED
    else
        e.config.button = nil
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
    end
end

function create_tabs(args)
    if args and args.tab_h == 7.05 then
        args.tabs[#args.tabs + 1] = seed_filter_tab
    end

    tabs = args.tabs

    local w = original_create_tabs(args)

    -- if seed_filter_tab.current then
    --     z = w.nodes[2].nodes[1].config.object
    --     print("AAA")
    -- end

    -- print(z)

    return w
end

function Game:start_run(args)
    for key, val in pairs(G.FUNCS) do
        print(key)
    end

    -- local yaml_string = [[
    --     legendary:
    --         - name: Perkeo
    --     voucher:
    --         - name: Telescope
    -- ]]

    local filter_criteria = parse_yaml(field.text)

    if filter_criteria == nil then
        return
    end

    G.SETTINGS.tutorial_progress = nil -- check this
    args.seed = generate_filtered_starting_seed(filter_criteria)
    orginal_game_start_run(self, args)
end
