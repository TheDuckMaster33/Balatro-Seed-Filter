original_love_draw = love.draw

InputField = SMODS.load_file("src/UI/input_field.lua")()

love.keyboard.setKeyRepeat(true)

local new_filter_criteria = {}


local FONT_SIZE          = 20
local FONT_LINE_HEIGHT   = 1.3

local FIELD_TYPE         = "multiwrap" -- Possible values: normal, password, multiwrap, multinowrap

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

field = InputField("", FIELD_TYPE)
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
local submit_status_node = { n = G.UIT.T, config = { text = "", colour = G.C.UI.TEXT_LIGHT, scale = 0.5 } }

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

    -- seed_filter_ui.nodes[1].nodes[2].nodes[1].nodes[1].config.button = 'apply_filter_criteria_changes'

    seed_filter_ui.nodes[1].nodes[2].nodes[1].nodes[1].nodes = { UIBox_button({
        button = 'apply_filter_criteria_changes',
        label = { "Apply" },
        minw = 3,
        func =
        'filter_criteria_apply_button_UI'
    }), }

    seed_filter_ui.nodes[1].nodes[2].nodes[2].nodes[1].nodes = {
        UIBox_button({
            button = 'discard_filter_criteria_changes',
            label = { "Discard" },
            minw = 3,
            func =
            'filter_criteria_discard_button_UI'
        }),
    }

    should_draw_seed_filter_textbox_fun()
    -- G.UIDEF.settings_tab('Game')

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

        local query, err = parse_yaml(field.text)

        if self.config.choice and deep_compare(filter_criteria, query) then
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
    local query, err = parse_yaml(field.text)

    -- x = UIBox { definition = seed_filter_tab.tab_definition_function(), config = {} }
    --     UIBox.remove(x)

    if err or not deep_compare(filter_criteria, query) then
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

        -- original_settings_tab(seed_filter_tab)

        return
    end

    should_draw_seed_filter_textbox = false
    original_options()
end

original_settings_tab = G.UIDEF.settings_tab

function G.UIDEF.settings_tab(tab)
    local query, err = parse_yaml(field.text)

    -- x = UIBox { definition = seed_filter_tab.tab_definition_function(), config = {} }
    --     UIBox.remove(x)

    if err or not deep_compare(filter_criteria, query) then
        -- print("Please submit or discard changes.")
        -- print(field.text)
        -- print(submitted_filter_criteria)
        submit_status_node.config.text = "Please submit or discard changes."
        -- seed_filter_tab.chosen = true
        -- local tab_but = G.OVERLAY_MENU:get_UIE_by_ID('tab_but_Seed Filter')
        -- G.FUNCS.change_tab(seed_filter_tab)
        -- G.buttons:recalculate()
        -- G.HUD:recalculate()

        args = args or {}
        args.colour = args.colour or G.C.RED
        args.tab_alignment = args.tab_alignment or 'cm'
        args.opt_callback = args.opt_callback or nil
        args.scale = args.scale or 1
        args.tab_w = args.tab_w or 0
        args.tab_h = args.tab_h or 0
        args.text_scale = (args.text_scale or 0.5)
        args.tabs = tabs

        x = UIBox { definition = seed_filter_tab.tab_definition_function(), config = {} }
        UIBox.remove(x)

        return seed_filter_ui
    end

    should_draw_seed_filter_textbox = false
    return original_settings_tab(tab)
end

-- original_create_UIBox_generic_options = create_UIBox_generic_options

-- function create_UIBox_generic_options(args)
--     if not deep_compare(filter_criteria, parse_yaml(field.text)) then
--         print("Please submit or discard changes.")
--         print(field.text)
--         print(submitted_filter_criteria)
--         submit_status_node.config.text = "Please submit or discard changes."

--     end

--     original_create_UIBox_generic_options(args)
-- end

local original_create_tabs = create_tabs

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

function deep_compare(t1, t2)
    local ty1 = type(t1)
    local ty2 = type(t2)
    if ty1 ~= ty2 then return false end
    -- non-table types can be directly compared
    if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
    for k1, v1 in pairs(t1) do
        local v2 = t2[k1]
        if v2 == nil or not deep_compare(v1, v2) then return false end
    end
    for k2, v2 in pairs(t2) do
        local v1 = t1[k2]
        if v1 == nil or not deep_compare(v1, v2) then return false end
    end
    return true
end

-- local filter_criteria_changed = false

function G.FUNCS.apply_filter_criteria_changes(_initial)
    new_filter_criteria, err = parse_yaml(field.text)

    if err then
        submit_status_node.config.text = err

        -- tab_definition_function()

        -- args = args or {}
        -- args.colour = args.colour or G.C.RED
        -- args.tab_alignment = args.tab_alignment or 'cm'
        -- args.opt_callback = args.opt_callback or nil
        -- args.scale = args.scale or 1
        -- args.tab_w = args.tab_w or 0
        -- args.tab_h = args.tab_h or 0
        -- args.text_scale = (args.text_scale or 0.5)
        -- args.tabs = tabs

        -- seed_filter_tab.tab_definition_function()
        local x = UIBox { definition = seed_filter_tab.tab_definition_function(), config = {} }
        UIBox.remove(x)
    else
        submit_status_node.config.text = "Filter criteria submitted"
        local x = UIBox { definition = seed_filter_tab.tab_definition_function(), config = {} }
        UIBox.remove(x)
        filter_criteria = new_filter_criteria
        submitted_filter_criteria = field.text
    end

    -- local filter_criteria = parse_yaml(field.text)
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

    submit_status_node.config.text = ""

    -- tab_definition_function()

    -- args = args or {}
    -- args.colour = args.colour or G.C.RED
    -- args.tab_alignment = args.tab_alignment or 'cm'
    -- args.opt_callback = args.opt_callback or nil
    -- args.scale = args.scale or 1
    -- args.tab_w = args.tab_w or 0
    -- args.tab_h = args.tab_h or 0
    -- args.text_scale = (args.text_scale or 0.5)
    -- args.tabs = tabs

    -- seed_filter_tab.tab_definition_function()
    local x                        = UIBox { definition = seed_filter_tab.tab_definition_function(), config = {} }
    UIBox.remove(x)

    new_filter_criteria = filter_criteria
end

function G.FUNCS.filter_criteria_apply_button_UI(e)
    -- e.config.disable_button = false

    local query, err = parse_yaml(field.text)

    -- print("apply")
    -- print(e.config.button)

    if err or not deep_compare(filter_criteria, query) then
        e.config.button = 'apply_filter_criteria_changes'
        e.config.colour = G.C.GREEN
    else
        e.config.button = nil
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
    end
end

function G.FUNCS.filter_criteria_discard_button_UI(e)
    local query, err = parse_yaml(field.text)

    -- print("discard")
    -- print(e.config.button)

    if err or not deep_compare(filter_criteria, query) then
        e.config.button = 'discard_filter_criteria_changes'
        e.config.colour = G.C.RED
    else
        e.config.button = nil
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
    end

    -- print(seed_filter_ui.nodes[1].nodes[2].nodes[1].nodes[1].nodes[1].config.button)
end
