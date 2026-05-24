-- CONFIGURATION --
function love.conf(t)
    -- General --
    t.identity = "billysadventure"         -- Save folder name for this game (used for save files, configs, etc.)
    t.appendidentity = false               -- If true, will append identity to paths instead of replacing default save paths
    t.version = "11.4"                     -- LÖVE version required for this project

    t.console = false                      -- Show a console for debugging (Windows-only)


    -- Window --
    t.window.title = "Billy's Adventure"   -- Window title
    t.window.icon = nil                    -- Path to PNG icon (e.g., "assets/icon.png")
    t.window.width = 1280                  -- Window width in pixels
    t.window.height = 720                  -- Window height in pixels
    t.window.minwidth = 1                  -- Minimum width if resizable
    t.window.minheight = 1                 -- Minimum height if resizable
    t.window.borderless = false            -- Remove OS window borders
    t.window.resizable = false             -- Allow the window to be resized by the user
    t.window.fullscreen = true             -- Start in fullscreen
    t.window.fullscreentype = "desktop"    -- "desktop" = borderless fullscreen, "exclusive" = exclusive fullscreen mode
    t.window.vsync = true                  -- Vertical sync enabled
    t.window.msaa = 0                      -- Multisample anti-aliasing level (0 = off)
    t.window.depth = nil                   -- Depth buffer bits (usually nil for 2D)
    t.window.stencil = nil                 -- Stencil buffer bits (usually nil for 2D)
    t.window.display = 1                   -- Monitor index for window
    t.window.highdpi = false               -- Enable High-DPI mode for Retina / 4K displays
    t.window.x = nil                       -- X position of window (windowed mode)
    t.window.y = nil                       -- Y position of window (windowed mode)


    -- Modules --
    t.modules.audio = true
    t.modules.data = true
    t.modules.event = true
    t.modules.font = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.joystick = false
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.physics = false
    t.modules.sound = true
    t.modules.system = true
    t.modules.thread = false
    t.modules.timer = true
    t.modules.touch = false
    t.modules.video = false
    t.modules.window = true


    -- Miscellanous --
    t.externalstorage = false              -- Android only: store save data on external storage
    t.accelerometerjoystick = false        -- Android/iOS: treat accelerometer as joystick
    t.gammacorrect = false                 -- Enable gamma-correct rendering (Love 11.4+)
end