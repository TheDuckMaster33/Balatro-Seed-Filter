original_love_draw = love.draw

love.keyboard.setKeyRepeat(true)

local new_filter_query = {}

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

should_draw_seed_filter_textbox = false

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