function getconsole()
    local ok, c = pcall(require, "con")
    if not ok then
        return {
            font = nil,
            messages = {},
            maxLines = 20,
            visible = false,
            bgColor = {0, 0, 0, 0},
            textColor = {0, 0, 0, 0},
            input = "",
            history = {},
            historyIndex = 0,
            active = false,
            backspaceHeld = false,
            backspaceTimer = 0,
            backspaceDelay = 0,
            backspaceRepeat = 0,
            scroll = 0,
            lineHeight = 0,

            load = function() print("call:load") end,
            log = function(p) print(tostring(p)) end,
            toggle = function() end,
            run = function() end,
            keypressed = function(_) end,
            draw = function() end,
            update = function(_) end,
            deleteChar = function() end
        }
    else
        return c
    end
end

fonts = { _28 = love.graphics.newFont(28) }
function getfont(size)
    local key = "_" .. tostring(size)

    if fonts[key] then
        return fonts[key]
    end

    local newFont = love.graphics.newFont(size)
    fonts[key] = newFont
    return newFont
end

function love.load()
    console = getconsole()

    love.window.setMode(0, 0, {
        fullscreen = true,
        vsync = true
    })
    love.window.setTitle("Billy's Adventure")

    screenWidth, screenHeight = love.graphics.getDimensions()

    targetWidth = screenWidth
    targetHeight = math.floor(screenWidth * 9 / 16)

    if targetHeight > screenHeight then
        targetHeight = screenHeight
        targetWidth = math.floor(screenHeight * 16 / 9)
    end
    hitboxVisible = false

    math.randomseed(os.time())

    transitioning = false
    transitioningPhase = nil
    transitionAlpha = 0
    transitionSpeed = 3
    transitionPause = 0
    postTransitionPlrSpeed = nil
    nextRoomTarget = nil

    dialogQueue = {}
    currentDialog = nil
    dialogActive = false

    room = "room0"

    script = {
        -- 1-11: Intro
        { s = "", t = "*Ehem*", p = nil },
        { s = "", t = "Welcome, dear...", p = nil },
        { s = "", t = "...Billy, right, sorry.", p = nil },
        { s = "", t = "Welcome, Billy, to your very own adventure!", p = nil },
        { s = "", t = "Here, you'll be exploring the place you work at.", p = nil },
        { s = "", t = "*Guess what the \"place\" is...*", p = nil, e = 16 },
        { s = "", t = "Anyway, your mission is to collect tokens scattered around your workplace.", p = nil },
        { s = "", t = "And for doing s-", p = nil, a = true },
        { s = "respnull", t = "You'll get tokens!", p = "assets/resphappy.png" },
        { s = "", t = "Yeah...", p = nil},
        { s = "", t = "Without further ado, let's get to playing. Good luck, Billy!", p = nil },

        -- 12-16: Table Interaction
        { s = "", t = "It's a table.", p = nil },
        { s = "", t = "Wonder why it's there...", p = nil },
        { s = "", t = "Or why even in a wide room with nothing but four corners?", p = nil },
        { s = "", t = "...", p = nil },
        { s = "", t = "Guess there's nothing useful here, might as well leave.", p = nil },

        -- 17-18: More Table Interaction
        { s = "", t = "...", p = nil },
        { s = "", t = "It's still a table. Shocking.", p = nil },

        -- 19-29: Traffic Resplings
        { s = "", t = "They appear to be very busy doing their job.", p = nil },
        { s = "", t = "...which is, being a traffic cube.", p = nil },
        { s = "", t = "Could they not be shaped to be a cone? Is that illegal?", p = nil },
        { s = "", t = "Their job is probably more illegal.", p = nil },
        { s = "", t = "They're obstructing my route for no reason at all.", p = nil },
        { s = "", t = "...", p = nil },
        { s = "", t = "Will any of them leave?", p = nil },
        { s = "You", t = "hey, culd yu guys leav?", p = "assets/billy.png" },
        { s = "", t = "...", p = nil },
        { s = "", t = "They don't react, as if they didn't hear a thing.", p = nil },
        { s = "", t = "Rude.", p = nil },

        -- 30-31: Traffic Resplings (Puzzle Completed)
        { s = "Traffic Respling", t = "puzzle completed? ok we'll move now", p = "assets/trafficresp.png" },
        { s = "", t = "Odd...", p = nil },

        -- 32-40: Respling Corpse
        { s = "", t = "It's a puddle of spilled paint.", p = nil },
        { s = "", t = "Wait, no, nevermind, it's the corpse of a respling.", p = nil },
        { s = "", t = "Damn, didn't know they could die.", p = nil },
        { s = "", t = "Maybe he isn't dead though...", p = nil },
        { s = "", t = "...gotta ask resp.", p = nil },
        { s = "", t = "Wonder how this one died.", p = nil },
        { s = "", t = "Maybe it could be a hint to something...", p = nil },
        { s = "", t = "...", p = nil },
        { s = "", t = "I shouldn't get too distracted.", p = nil },

        -- 41-42: Respling Corpse (Again)
        { s = "", t = "What, you just wanna stay here and stare at a corpse?", p = nil },
        { s = "", t = "Weird thing to do, but fine i guess.", p = nil },

        -- 43: Respling Corpse (Again+)
        { s = "", t = "...", p = nil },

        -- 44-53: Blocked Way to Maintenance Room
        { s = "", t = "The gate is blocking me from going there.", p = nil },
        { s = "", t = "There's a sign in the center. It reads:", p = nil },
        { s = "", t = "\"This path is currently being obstructed by a 4000 kilogram elephant,\"", p = nil },
        { s = "", t = "\"and is therefore unavailable for use.\"", p = nil },
        { s = "", t = "\"Please take the other path instead.\"", p = nil },
        { s = "", t = "\"\"", p = nil },
        { s = "", t = "\"Thank you for your understanding.\"", p = nil },
        { s = "", t = "...", p = nil },
        { s = "", t = "Am i expected to fall for this?", p = nil },
        { s = "", t = "...well, i guess i am, seeing something this absurd being used as an excuse.", p = nil },

        -- 54-55: Elephant Sight
        { s = "", t = ". . .", p = nil },
        { s = "", t = "tasty.", p = nil },
    }

    walls = {
        { x = 0, y = 0, w = 400, h = 720 }, -- Left
        { x = 880, y = 200, w = 400, h = 520 }, -- Right
        { x = 400, y = 0, w = 880, h = 100 }, -- Top
        { x = 400, y = 700, w = 480, h = 20 } -- Bottom
    }

    roomsw = {
        { x = 1270, y = 100, w = 10, h = 100, r = "room1" }
    }

    interactable = { }

    token = { x = -9999, y = -9999, w = 35, h = 35, id = 1, nodraw = true }
    token_ow_image = love.graphics.newImage("assets/token_ow.png")

    bg = love.graphics.newImage("assets/room0.png")

    particleTexture = love.graphics.newImage("assets/ps2.png")
    ps = love.graphics.newParticleSystem(particleTexture, 18)

    ps:setParticleLifetime(0.3, 0.6)
    ps:setEmissionRate(0)
    ps:setSpeed(50, 120)
    ps:setSizes(1, 0)
    ps:setSpread(math.rad(360))
    ps:setLinearAcceleration(0, 200)

    player = {}
    player.x = (1280 - 50) / 2
    player.y = (720 - 50) / 3.5
    player.speed = 200

    player.image = love.graphics.newImage("assets/billy_sprites.png")
    player.frameWidth = 36
    player.frameHeight = 41
    player.numFrames = 3

    player.currentFrame = 1
    player.frameTimer = 0
    player.frameDuration = 0.1

    player.direction = "up"

    player.freeze = false
    player.freezeMode = 0xEEE -- Enabled (3822)

    tokens = 0
    tokensCollection = { 0,0,0,0,0 }

    puzzleCompleted = false

    trafficresp = {}
    trafficresp.x = 590
    trafficresp.y = 180
    trafficresp.w = 100
    trafficresp.h = 20
    trafficresp.block = true
    trafficresp.image = love.graphics.newImage("assets/trafficresps.png")

    trafficrespMove = {
        active = false,
        startX = trafficresp.x,
        targetX = trafficresp.x + 500,
        startY = trafficresp.y,
        targetY = trafficresp.y - 50,
        duration = 5,
        elapsed = 0
    }

    tFont = love.graphics.newFont("assets/Hack-Regular.ttf", 64)
    tIcon = love.graphics.newImage("assets/token.png")

    tokenState = "hidden"
    tokenY = -100
    tokenTargetY = 20
    tokenPauseY = 10
    tokenTimer = 0
    tokenSpeed = 250

    bgm = love.audio.newSource("assets/cipher.ogg", "stream")
    bgm:setLooping(true)
    love.audio.play(bgm)
    intr = love.audio.newSource("assets/ba_intro_spedup.wav", "static")
    ding = love.audio.newSource("assets/ding.wav", "static")
    ouch = love.audio.newSource("assets/ouch.wav", "static")

    musicVolume = 1
    musicTargetVolume = 1
    musicFadeSpeed = 0.5

    console.load()
    console.log("OK")
end

-- function doSmth() jumpSound:play() end

function nextRoom(_room, prevRoom)
    if prevRoom == nil then prevRoom = "" end
    token = { x = -9999, y = -9999, w = 35, h = 35, id = -1 }

    if _room == "room0" then
        bg = love.graphics.newImage("assets/room0.png")

        player.x = 1200

        walls = {
            { x = 0, y = 0, w = 400, h = 720 }, -- Left
            { x = 880, y = 200, w = 400, h = 520 }, -- Right
            { x = 400, y = 0, w = 880, h = 100 }, -- Top
            { x = 400, y = 700, w = 480, h = 20 } -- Bottom
        }

        roomsw = {
            { x = 1270, y = 100, w = 10, h = 100, r = "room1" }
        }

    elseif _room == "room1" then
        bg = love.graphics.newImage("assets/room1L.png")

        player.x = 30
        if prevRoom == "room2" then player.x = 1200 end

        walls = {
            { x = 0, y = 0, w = 1280, h = 100 }, -- Top
            { x = 0, y = 200, w = 590, h = 520 }, -- Left
            { x = 690, y = 200, w = 590, h = 170 }, -- Right
            { x = 690, y = 500, w = 590, h = 220 }, -- Bottom
            { x = 690, y = 370, w = 1, h = 30 }, -- RightSide
            { x = 590, y = 384, w = 100, h = 16 } -- LaserGate
        }

        roomsw = {
            { x = 0, y = 100, w = 10, h = 100, r = "room0" },
            { x = 1270, y = 100, w = 10, h = 100, r = "room2" }
        }

        interactable = nil

    elseif _room == "room2" or _room == "room2a" then
        bg = love.graphics.newImage("assets/room2.png")

        player.x = 30
        if prevRoom == "room2t" then player.x = 625 player.y = 30 end
        if string.find(prevRoom, "room3") then player.x = 1200 end
        if _room == "room2a" then player.y = 426 end

        walls = {
            { x = 0, y = 0, w = 590, h = 100 }, -- Topleft
            { x = 690, y = 0, w = 590, h = 100 }, -- Topright
            { x = 0, y = 200, w = 590, h = 520 }, -- Left
            { x = 690, y = 200, w = 590, h = 200 }, -- Right
            { x = 590, y = 500, w = 690, h = 220 } -- Bottom
        }

        roomsw = {
            { x = 0, y = 100, w = 10, h = 100, r = "room1" },
            { x = 590, y = 0, w = 100, h = 10, r = "room2t" },
            { x = 1270, y = 100, w = 10, h = 100, r = "room3" },
            { x = 1270, y = 400, w = 10, h = 100, r = "room3a" }
        }

        interactable = nil

        musicTargetVolume = 1

    elseif _room == "room2t" then
        bg = love.graphics.newImage("assets/room2t.png")

        musicTargetVolume = 0

        player.y = 650

        walls = {
            { x = 0, y = 373, w = 590, h = 347 }, -- Left
            { x = 0, y = 0, w = 20, h = 373 }, -- LeftCorner
            { x = 690, y = 373, w = 590, h = 347 }, -- Right
            { x = 1260, y = 0, w = 20, h = 373 }, -- RightCorner
            { x = 20, y = 0, w = 1240, h = 20 }, -- TopCorner
            --{ x = 610, y = 100, w = 55, h = 25 }, -- Table
            { x = 0, y = 100, w = 1280, h = 1 } -- ???
        }

        roomsw = {
            { x = 590, y = 709, w = 100, h = 10, r = "room2" }
        }

        interactable = {
            {
                x = 616, y = 100, w = 48, h = 20, face = "up", i = 0, imax = math.huge, state = nil,
                used = false,
                onInteract = function(self)
                    if dialogActive then return end

                    if self.i == 0 then
                        for k = 12, 16 do
                            queueDialog(script[k].s, script[k].t, script[k].p, script[k].a, true, script[k].e)
                        end
                        self.used = true
                    else
                        for k = 17, 18 do
                            queueDialog(script[k].s, script[k].t, script[k].p, script[k].a, true, script[k].e)
                        end
                        self.postUsedTriggered = true
                    end
                end
            }
        }

    elseif _room == "room3" or _room == "room3a" then
        bg = love.graphics.newImage("assets/room3.png")

        player.x = 30
        if prevRoom == "room4" then player.x = 1200 end

        walls = {
            { x = 0, y = 0, w = 1280, h = 100 }, -- Top
            { x = 0, y = 200, w = 590, h = 200 }, -- LeftMiddle
            { x = 690, y = 100, w = 590, h = 210 }, -- Right
            { x = 690, y = 410, w = 590, h = 90 }, -- Right2
            { x = 0, y = 500, w = 1280, h = 220 }, -- Bottom
        }

        roomsw = {
            { x = 0, y = 100, w = 10, h = 100, r = "room2" },
            { x = 0, y = 400, w = 10, h = 100, r = "room2a" },
            { x = 1270, y = 310, w = 10, h = 100, r = "room4" }
        }

        interactable = nil

    elseif _room == "room4" then
        bg = love.graphics.newImage("assets/room4.png")

        player.x = 30
        if prevRoom == "room5" then player.y = 30 end
        if prevRoom == "room5" and puzzleCompleted then trafficresp.x = -9999 end

        walls = {
            { x = 0, y = 0, w = 590, h = 310 }, -- LeftTop
            { x = 0, y = 410, w = 690, h = 310 }, -- LeftBottom
            { x = 690, y = 0, w = 590, h = 720 } -- Right
        }

        roomsw = {
            { x = 0, y = 310, w = 10, h = 100, r = "room3" },
            { x = 590, y = 0, w = 100, h = 10, r = "room5" }
        }

        interactable = nil

    elseif _room == "room5" then
        bg = love.graphics.newImage("assets/room5.png")

        player.y = 650
        if prevRoom == "room6" then player.y = 30 end

        walls = {
            { x = 0, y = 0, w = 50, h = 720 }, -- Left
            { x = 50, y = 0, w = 540, h = 200 }, -- LeftTop
            { x = 50, y = 300, w = 540, h = 120 }, -- LeftMiddle
            { x = 50, y = 520, w = 540, h = 200 }, -- LeftBottom
            { x = 1230, y = 0, w = 50, h = 720 }, -- Right
            { x = 690, y = 0, w = 540, h = 200 }, -- RightTop
            { x = 690, y = 300, w = 540, h = 120 }, -- RightMiddle
            { x = 690, y = 520, w = 540, h = 200 }, -- RightBottom
            { x = 590, y = 180, w = 100, h = 20 } -- trafficresp
        }

        roomsw = {
            { x = 590, y = 710, w = 100, h = 10, r = "room4" },
            { x = 590, y = 0, w = 100, h = 10, r = "room6" }
        }

        interactable = {
            {
                x = 81, y = 241, w = 18, h = 18, i = 0, imax = math.huge, state = nil,
                used = false, interactOnContact = true, padID = 1,
                onInteract = function() if interactable[1].i < 1 then ding:play() end end
            },

            {
                x = 1181, y = 241, w = 18, h = 18, i = 0, imax = math.huge, state = nil,
                used = false, interactOnContact = true, padID = 2,
                onInteract = function()
                    if not (interactable[1].i > 0) then ouch:play() nextRoom("room5", "room4") return end
                    if interactable[2].i < 1 then ding:play() end
                end
            },

            {
                x = 81, y = 461, w = 18, h = 18, i = 0, imax = math.huge, state = nil,
                used = false, interactOnContact = true, padID = 3,
                onInteract = function()
                    if not (interactable[1].i > 0)
                    or not (interactable[2].i > 0) then ouch:play() nextRoom("room5", "room4") return end
                    if interactable[3].i < 1 then ding:play() end
                end
            },

            {
                x = 1181, y = 461, w = 18, h = 18, i = 0, imax = math.huge, state = nil,
                used = false, interactOnContact = true, padID = 4,
                onInteract = function()
                    if not (interactable[1].i > 0)
                    or not (interactable[2].i > 0)
                    or not (interactable[3].i > 0) then ouch:play() nextRoom("room5", "room4")
                    else
                        puzzleCompleted = true
                        if interactable[4].i < 1 then ding:play() end
                    end
                end
            },

            {
                x = 590, y = 200, w = 100, h = 20, face = "up", i = 0, imax = math.huge, state = nil,
                used = false,
                onInteract = function()
                    if dialogActive then return end

                    if not puzzleCompleted then
                        for k = 19, 29 do
                            queueDialog(script[k].s, script[k].t, script[k].p, script[k].a, true, script[k].e)
                        end
                    else
                        queueDialog(
                            script[30].s, script[30].t, script[30].p, script[30].a, true, script[30].e
                        )
                        trafficrespMove.pending = true
                    end
                end
            }
        }

        if puzzleCompleted then
            walls[9], interactable[5] = nil, nil
            for _, i in ipairs(interactable) do
                i.onInteract = function() end
            end
        end

    elseif _room == "room6" then
        bg = love.graphics.newImage("assets/room6.png")

        trafficresp.x = -9999
        if prevRoom == "room5" then player.y = 650 end
        if prevRoom == "room6l" then player.x = 30 end

        walls = {
            { x = 0, y = 0, w = 790, h = 110 }, -- LeftTop
            { x = 0, y = 210, w = 296, h = 200 }, -- LeftMiddle
            { x = 0, y = 410, w = 590, h = 310 }, -- LeftBottom
            { x = 396, y = 110, w = 394, h = 200 }, -- Middle
            { x = 890, y = 0, w = 390, h = 310 }, -- RightTop
            { x = 690, y = 410, w = 590, h = 310 }, -- RightBottom
            { x = 790, y = 10, w = 100, h = 15 }, -- Sign
	    { x = 1210, y = 310, w = 70, h = 100 }, -- Traffic resps
        }

        roomsw = {
            { x = 590, y = 710, w = 100, h = 10, r = "room5" },
            { x = 0, y = 110, w = 10, h = 100, r = "room6l" },
            { x = 1270, y = 310, w = 10, h = 100, r = "room6r" },
            { x = 790, y = 0, w = 100, h = 10, r = "room7" }
        }

        interactable = {
            {
                x = 790, y = 30, w = 100, h = 30, face = "up", i = 0, imax = math.huge, state = nil,
                used = false,
                onInteract = function()
                    if dialogActive then return end

                    for k = 44, 53 do
                        queueDialog(script[k].s, script[k].t, script[k].p, script[k].a, true, script[k].e)
                    end
                end
            }
        }

    elseif _room == "room6l" then
        bg = love.graphics.newImage("assets/room6l.png")

        player.x = 1200
        if prevRoom == "room6la" then player.x = 30 end

        walls = {
            { x = 0, y = 0, w = 1280, h = 110 }, -- Top
            { x = 0, y = 210, w = 590, h = 510 }, -- Left
            { x = 690, y = 210, w = 590, h = 510 } -- Right
        }

        roomsw = {
            { x = 1270, y = 110, w = 10, h = 100, r = "room6" },
            { x = 0, y = 110, w = 10, h = 100, r = "room6la" }
        }

        interactable = nil

    elseif _room == "room6la" then
        bg = love.graphics.newImage("assets/room6la.png")

        player.x = 1200
        if prevRoom == "room6lb" then player.x = 30 end

        walls = {
            { x = 0, y = 0, w = 541, h = 510 }, -- Left
            { x = 541, y = 0, w = 739, h = 110 }, -- Top
            { x = 641, y = 210, w = 639, h = 510 }, -- Right
            { x = 0, y = 610, w = 641, h = 110 } -- Bottom
        }

        roomsw = {
            { x = 1270, y = 110, w = 10, h = 100, r = "room6l" },
            { x = 0, y = 510, w = 10, h = 100, r = "room6lb" }
        }

        interactable = nil

    elseif _room == "room6lb" then
        bg = love.graphics.newImage("assets/room6lb.png")

        player.x = 1200
        if prevRoom == "room6lc" then player.x = 30 end

        walls = {
            { x = 0, y = 0, w = 1280, h = 110 }, -- Top
            { x = 0, y = 210, w = 639, h = 300 }, -- Left
            { x = 739, y = 110, w = 541, h = 400 }, -- Right
            { x = 0, y = 610, w = 1280, h = 110 } -- Bottom
        }

        roomsw = {
            { x = 1270, y = 510, w = 10, h = 100, r = "room6la" },
            { x = 0, y = 110, w = 10, h = 100, r = "room6lc" },
            { x = 0, y = 510, w = 10, h = 100, r = "room6lc" }
        }

        interactable = nil

    elseif _room == "room6lc" then
        bg = love.graphics.newImage("assets/room6lc.png")

        if prevRoom == "room6ld" then player.y = 650
        elseif prevRoom == "room6le" then player.y = 30
        else player.x = 1200 end

        walls = {
            { x = 0, y = 0, w = 590, h = 720 }, -- Left
            { x = 590, y = 210, w = 690, h = 300 }, -- Middle
            { x = 690, y = 0, w = 590, h = 110 }, -- Top
            { x = 690, y = 610, w = 590, h = 110 } -- Bottom
        }

        roomsw = {
            { x = 1270, y = 110, w = 10, h = 100, r = "room6lb" },
            { x = 1270, y = 510, w = 10, h = 100, r = "room6lb" },
            { x = 590, y = 710, w = 100, h = 10, r = "room6ld" },
            { x = 590, y = 0, w = 100, h = 10, r = "room6le" }
        }

        interactable = nil

    elseif _room == "room6ld" then
        bg = love.graphics.newImage("assets/room6ld.png")

        player.y = 30

        walls = {
            { x = 0, y = 0, w = 590, h = 720 }, -- Left
            { x = 690, y = 0, w = 590, h = 720 }, -- Right
            { x = 590, y = 640, w = 100, h = 80 }, -- Bottom
            { x = 590, y = 570, w = 100, h = 70 } -- Corpse
        }

        roomsw = {
            { x = 590, y = 0, w = 100, h = 10, r = "room6lc" }
        }

        interactable = {
            {
                x = 590, y = 550, w = 100, h = 20, face = "down", i = 0, imax = math.huge, state = nil,
                used = false,
                onInteract = function(self)
                    if dialogActive then return end

                    if self.i == 0 then
                        for k = 32, 40 do
                            queueDialog(script[k].s, script[k].t, script[k].p, script[k].a, true, script[k].e)
                        end
                        self.used = true
                    elseif self.i == 1 then
                        for k = 41, 42 do
                            queueDialog(script[k].s, script[k].t, script[k].p, script[k].a, true, script[k].e)
                        end
                        self.postUsedTriggered = true
                    else
                        queueDialog(script[43].s, script[43].t, script[43].p, script[43].a, true, script[43].e)
                    end
                end
            }
        }

    elseif _room == "room6le" then
        bg = love.graphics.newImage("assets/room6le.png")

        if prevRoom == "room6lf" then player.x = 1200 else player.y = 650 end

        walls = {
            { x = 0, y = 0, w = 590, h = 720 }, -- Left
            { x = 590, y = 0, w = 690, h = 100 }, -- Top
            { x = 690, y = 200, w = 590, h = 520 }, -- Bottom
        }

        roomsw = {
            { x = 590, y = 710, w = 100, h = 10, r = "room6lc" },
            { x = 1270, y = 100, w = 10, h = 100, r = "room6lf" }
        }

        interactable = nil

    elseif _room == "room6lf" then
        bg = love.graphics.newImage("assets/room6lf.png")

        if prevRoom == "room6lg" then player.x = 1200 else player.x = 30 end

        if tokensCollection[1] < 1 then
            token = { x = 680, y = 530, w = 35, h = 35, id = 1, nodraw = false }
        end

        walls = {
            { x = 0, y = 0, w = 1280, h = 100 }, -- Top
            { x = 0, y = 200, w = 500, h = 720 }, -- Left
            { x = 500, y = 328, w = 175, h = 194 }, -- LeftMiddle
            { x = 500, y = 522, w = 171, h = 198 }, -- LeftBottom
            { x = 538, y = 200, w = 176, h = 87 }, -- Right
            { x = 714, y = 200, w = 566, h = 322 }, -- RightMiddle
            { x = 722, y = 522, w = 558, h = 198 }, -- RightBottom
            { x = 671, y = 573, w = 51, h = 147 } -- Bottom
        }

        roomsw = {
            { x = 0, y = 100, w = 10, h = 100, r = "room6le" },
            { x = 1270, y = 100, w = 10, h = 100, r = "room6lg" }
        }

        interactable = nil

    elseif _room == "room6lg" then
        bg = love.graphics.newImage("assets/room6lg.png")

        if prevRoom == "room6lh" then player.x = 1200 else player.x = 30 end

        walls = {
            { x = 0, y = 0, w = 1280, h = 100 }, -- Top
            { x = 0, y = 200, w = 1280, h = 520 } -- Bottom
        }

        roomsw = {
            { x = 0, y = 100, w = 10, h = 100, r = "room6lf" },
            { x = 1270, y = 100, w = 10, h = 100, r = "room6lh" }
        }

        interactable = nil

    elseif _room == "room6lh" then
        bg = love.graphics.newImage("assets/room6lh.png")

        if prevRoom == "room7" then player.x = 1200 else player.x = 30 end

        walls = {
            { x = 0, y = 0, w = 1280, h = 100 }, -- Top
            { x = 0, y = 200, w = 590, h = 520 }, -- Left
            { x = 690, y = 200, w = 590, h = 100 }, -- Middle
            { x = 690, y = 400, w = 590, h = 100 }, -- Right
            { x = 590, y = 600, w = 690, h = 120 } -- Bottom
        }

        roomsw = {
            { x = 0, y = 100, w = 10, h = 100, r = "room6lg" },
            { x = 1270, y = 100, w = 10, h = 100, r = "room7" }
        }

        interactable = {
            {
                x = 1160, y = 310, w = 180, h = 80, i = 0, imax = math.huge, state = nil,
                used = false, interactOnContact = true, alpha = 0,
                image = love.graphics.newImage("assets/resp333.png")
            },

            {
                x = 1160, y = 510, w = 180, h = 80, i = 0, imax = math.huge, state = nil,
                used = false, interactOnContact = true, alpha = 0,
                image = love.graphics.newImage("assets/resp333.png")
            }
        }

    elseif _room == "room7" then
        bg = love.graphics.newImage("assets/room7.png")

        if prevRoom == "room8" then player.y = 30 else player.x = 30 end

        walls = {
            { x = 0, y = 0, w = 790, h = 100 }, -- Left
            { x = 890, y = 0, w = 390, h = 200 }, -- Right
            { x = 0, y = 200, w = 1280, h = 520 } -- Bottom
        }

        roomsw = {
            { x = 0, y = 100, w = 10, h = 100, r = "room6lh" },
            { x = 790, y = 0, w = 100, h = 10, r = "room8" }
        }

        interactable = {
            {
                x = 0, y = 100, w = 100, h = 100, i = 0, imax = math.huge, state = nil,
                used = false, interactOnContact = true,
                onInteract = function(self)
                    if self.i ~= 1 then return end
                    self.i = 2
                    if dialogActive then return end

                    musicTargetVolume = 0
                    player.freeze = true
                    player.freezeMode = 0xEAD -- Enable After Dialog (3757)
                    for k = 54, 55 do
                        queueDialog(script[k].s, script[k].t, script[k].p, script[k].a, true, script[k].e)
                    end
                end
            }
        }

    elseif _room == "room8" then
	bg = love.graphics.newImage("assets/room8.png")
	walls = { { x = 0, y = 0, w = 1280, h = 720 } }
	player.image = love.graphics.newImage("assets/empty.png")

    else
        error("Unknown room " .. _room)
    end

    room = _room
end

function giveToken(num)
    tokens = tokens + num
    tokenY = -100
    tokenState = "movingUp"
    tokenTimer = 0
    tokenVisible = true
end

function createDialog(speaker, text, portrait, options)
    return {
        speaker = speaker,
        text = text,
        portrait = portrait,
        options = options,
        currentChar = 0,
        finished = false
    }
end

function startDialog(speaker, text)
    currentDialog = {
        speaker = speaker,
        text = text,
        currentChar = 0,
        finished = false
    }
    dialogActive = true
end

function queueDialog(speaker, text, portraitPath, auto, freeze, fontSize)
    local portraitImg = nil
    if portraitPath then
        portraitImg = love.graphics.newImage(portraitPath)
    end

    table.insert(dialogQueue, {
        speaker = speaker,
        text = text,
        portrait = portraitImg,
        currentChar = 0,
        finished = false,
        auto = auto or false,
        freeze = freeze or false,
        fontSize = fontSize or 20
    })

    if not dialogActive then
        advanceDialog()
    end
end

function advanceDialog()
    if #dialogQueue > 0 then
        currentDialog = table.remove(dialogQueue, 1)
        dialogActive = true
    else
        currentDialog = nil
        dialogActive = false
    end
end

local dt_accmltr = 0
local targetFPS = 30
local dtpf = 1 / targetFPS

local function checkCollision(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and
           bx < ax + aw and
           ay < by + bh and
           by < ay + ah
end

function love.update(dt)
    dt_accmltr = dt_accmltr + dt
    while dt_accmltr >= dtpf do
        -- START --

        local frozen = (
            dialogActive and currentDialog and currentDialog.freeze
        ) or trafficrespMove.active or player.freeze == true
        local moving = false
        local speed = player.speed
        if love.keyboard.isDown("lshift") then speed = speed * 1.5 end

        if player.freezeMode == 0xEAD and dialogActive == false then -- Enable After Death (3757)
            player.freeze = false
            player.freezeMode = 0xEEE -- Enabled (3822)
        end

        if player.freezeMode == 0xDDD then player.freeze = true end -- Disabled (3549)
        if player.freezeMode == 0xEEE then player.freeze = false end -- Enabled (3822)

        local newX = player.x
        local newY = player.y

        if love.keyboard.isDown("right","d") then
            newX = newX + speed * dtpf
            player.direction = "right"
            moving = true
        elseif love.keyboard.isDown("left","a") then
            newX = newX - speed * dtpf
            player.direction = "left"
            moving = true
        end

        local blockedX = false
        for _, w in ipairs(walls) do
            if checkCollision(newX, player.y, player.frameWidth, player.frameHeight,
                            w.x, w.y, w.w, w.h) then
                blockedX = true
                if newX > player.x then
                    newX = w.x - player.frameWidth
                else
                    newX = w.x + w.w
                end
                break
            end
        end
        if not frozen then player.x = newX end

        if love.keyboard.isDown("down","s") then
            newY = newY + speed * dtpf
            player.direction = "down"
            moving = true
        elseif love.keyboard.isDown("up","w") then
            newY = newY - speed * dtpf
            player.direction = "up"
            moving = true
        end

        local blockedY = false
        for _, w in ipairs(walls) do
            if checkCollision(player.x, newY, player.frameWidth, player.frameHeight,
                            w.x, w.y, w.w, w.h) then
                blockedY = true
                if newY > player.y then
                    newY = w.y - player.frameHeight
                else
                    newY = w.y + w.h
                end
                break
            end
        end
        if not frozen then player.y = newY end

        local playerWidth = player.frameWidth
        local playerHeight = player.frameHeight

        if not frozen then
            player.x = math.max(0, math.min(player.x, 1280 - playerWidth))
            player.y = math.max(0, math.min(player.y, 720 - playerHeight))
        end

        if moving and not frozen and player.speed > 0 then
            player.frameTimer = player.frameTimer + dt * (speed/player.speed)
            if player.frameTimer >= player.frameDuration then
                player.currentFrame = player.currentFrame + 1
                if player.currentFrame > player.numFrames then
                    player.currentFrame = 1
                end
                player.frameTimer = 0
            end
        else
            player.currentFrame = 2
        end

        if dialogActive and currentDialog then
            if not currentDialog.finished then
                currentDialog.currentChar = currentDialog.currentChar + 60 * dt
                if currentDialog.currentChar >= #currentDialog.text then
                    currentDialog.currentChar = #currentDialog.text
                    currentDialog.finished = true
                end
            else
                if currentDialog.auto then
                    advanceDialog()
                end
            end
        end

        if tokenVisible then
            if tokenState == "movingUp" then
                tokenY = tokenY + tokenSpeed * dtpf
                if tokenY >= tokenTargetY then
                    tokenY = tokenTargetY
                    tokenState = "pauseUp"
                    tokenTimer = 0
                end

            elseif tokenState == "pauseUp" then
                tokenTimer = tokenTimer + dtpf
                if tokenTimer >= 1 then
                    tokenState = "movingDown"
                    tokenTimer = 0
                end

            elseif tokenState == "movingDown" then
                tokenY = tokenY - tokenSpeed * dtpf
                if tokenY <= tokenPauseY then
                    tokenY = tokenPauseY
                    tokenState = "pauseDown"
                    tokenTimer = 0
                end

            elseif tokenState == "pauseDown" then
                tokenTimer = tokenTimer + dtpf
                if tokenTimer >= 1 then
                    tokenState = "bounceUp"
                    tokenTimer = 0
                end

            elseif tokenState == "bounceUp" then
                tokenTimer = tokenTimer + dtpf
                tokenY = tokenTimer
                tokenState = "movingOffScreen"

            elseif tokenState == "movingOffScreen" then
                tokenY = tokenY - tokenSpeed * dtpf
                if tokenY <= -100 then
                    tokenY = -100
                    tokenVisible = false
                    tokenState = "hidden"
                end
            end
        end

        if not transitioning then
            for _, s in ipairs(roomsw) do
                if s.x and checkCollision(player.x, player.y, player.frameWidth, player.frameHeight,
                                        s.x, s.y, s.w, s.h) then
                    transitioning = true
                    postTransitionPlrSpeed = player.speed
                    player.speed = 0
                    transitioningPhase = "fadeout"
                    nextRoomTarget = s.r
                    break
                end
            end
        else
            if transitioningPhase == "fadeout" then
                transitionAlpha = transitionAlpha + transitionSpeed * dtpf
                if transitionAlpha >= 1 then
                    transitionAlpha = 1
                    nextRoom(nextRoomTarget, room)
                    transitioningPhase = "pause"
                    transitionPause = 0.1
                end
            elseif transitioningPhase == "pause" then
                transitionPause = transitionPause - dt
                if transitionPause <= 0 then
                    transitioningPhase = "fadein"
                end
            elseif transitioningPhase == "fadein" then
                transitionAlpha = transitionAlpha - transitionSpeed * dtpf
                if transitionAlpha <= 0 then
                    transitionAlpha = 0
                    transitioning = false
                    transitioningPhase = nil
                    player.speed = postTransitionPlrSpeed
                    postTransitionPlrSpeed = nil
                end
            end
        end

        if trafficrespMove.pending and not dialogActive then
            trafficrespMove.pending = false
            trafficrespMove.active = true
            trafficrespMove.elapsed = 0
            trafficrespMove.startX = trafficresp.x
            trafficrespMove.startY = trafficresp.y
            trafficrespMove.targetX = trafficresp.x + 500
            trafficrespMove.targetY = trafficresp.y - 50
        end

        if trafficrespMove.active then
            trafficrespMove.elapsed = trafficrespMove.elapsed + dtpf
            local t = math.min(trafficrespMove.elapsed / trafficrespMove.duration, 1)

            trafficresp.x =
                trafficrespMove.startX +
                (trafficrespMove.targetX - trafficrespMove.startX) * t

            trafficresp.y =
                trafficrespMove.startY +
                (trafficrespMove.targetY - trafficrespMove.startY) * t * 2

            if t >= 1 then
                walls[9], interactable[5] = nil, nil
                trafficrespMove.active = false
            end
        end

        for _, i in ipairs(interactable or {}) do
            local colliding = checkCollision(player.x, player.y, player.frameWidth, player.frameHeight,
                                            i.x, i.y, i.w, i.h)
            if not colliding then
                i.used = false
            end

            if colliding and love.keyboard.isDown("space") and (i.face or player.direction) == player.direction then
                if not i.used and i.onInteract then
                    i:onInteract()
                    i.i = (i.i or 0) + 1
                    i.used = true
                end
            end

            if colliding and i.interactOnContact and i.onInteract then
                i:onInteract()
                i.i = (i.i or 0) + 1
                i.used = true
            end

            if colliding and i.alpha ~= nil then
                local dx = (player.x + player.frameWidth/2) - (i.x + i.w/2)
                local dy = (player.y + player.frameHeight/2) - (i.y + i.h/2)
                local dist = math.sqrt(dx*dx + dy*dy)

                if dist < 100 then
                    i.alpha = 1 - (dist / 100)
                else
                    i.alpha = 0
                end
            end
        end

        if token ~= nil then
            local colliding = checkCollision(player.x, player.y, player.frameWidth, player.frameHeight,
                                            token.x, token.y, token.w, token.h)
            if colliding and tokensCollection[token.id] ~= 1 then
                tokensCollection[token.id] = 1
                giveToken(1)
                ps:emit(math.random(12, 18))
                token.nodraw = true
            end
        end

        if bgm then
            if math.abs(musicVolume - musicTargetVolume) > 0.01 then
                if musicVolume < musicTargetVolume then
                    musicVolume = math.min(musicTargetVolume, musicVolume + musicFadeSpeed * dtpf)
                else
                    musicVolume = math.max(musicTargetVolume, musicVolume - musicFadeSpeed * dtpf)
                end
                bgm:setVolume(musicVolume)

                if musicVolume <= 0 and bgm:isPlaying() then
                    bgm:stop()
                elseif musicVolume > 0 and not bgm:isPlaying() then
                    bgm:play()
                end
            end
        end

        ps:update(dt)

        console.update(dt)
        -- END --
        dt_accmltr = dt_accmltr - dtpf
    end
end

local directionRow = {down=0, left=1, right=2, up=3}
function love.draw()
    love.graphics.push()
    love.graphics.translate((screenWidth - targetWidth) / 2, (screenHeight - targetHeight) / 2)
    love.graphics.scale(targetWidth / 1280, targetHeight / 720)

    -- START --
    love.graphics.draw(bg, 0, 0, 0, 1280 / bg:getWidth(), 720 / bg:getHeight())

    if hitboxVisible then
        love.graphics.setColor(1, 0, 0, 0.4)
        for _, w in ipairs(walls) do love.graphics.rectangle("fill", w.x, w.y, w.w, w.h) end

        love.graphics.setColor(0, 1, 0, 0.4)
        for _, s in ipairs(roomsw) do love.graphics.rectangle("fill", s.x, s.y, s.w, s.h) end

        love.graphics.setColor(0, 0, 1, 0.4)
        if type(interactable) == "table" then
            for _, i in ipairs(interactable) do love.graphics.rectangle("fill", i.x, i.y, i.w, i.h) end
        end
    end

    for _, i in ipairs(interactable or {}) do
        if i.image ~= nil then
            love.graphics.setColor(1, 1, 1, i.alpha or 1)
            love.graphics.draw(i.image, i.x, i.y)
        end
    end
    love.graphics.setColor(1, 1, 1)

    if room == "room5" then
        for index, i in ipairs(interactable) do
            if (i.i > 0 or puzzleCompleted) and index < 5 then
                love.graphics.setColor(0.415, 0.875, 0.224)
                love.graphics.rectangle("fill", i.x, i.y, i.w, i.h)
            end
        end
        love.graphics.setColor(1, 1, 1)

        love.graphics.draw(trafficresp.image, trafficresp.x, trafficresp.y)
    end

    local row = directionRow[player.direction]
    local quad = love.graphics.newQuad(
        (player.currentFrame-1) * player.frameWidth,
        row * player.frameHeight,
        player.frameWidth,
        player.frameHeight,
        player.image:getDimensions()
    )
    love.graphics.draw(player.image, quad, math.floor(player.x), math.floor(player.y))

    if not token.nodraw then love.graphics.draw(token_ow_image, token.x, token.y) end
    love.graphics.draw(ps, token.x, token.y)

    if dialogActive and currentDialog then
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 50, 500, 1180, 200, 10, 10)
        love.graphics.setColor(1, 1, 1)

        local textX = 60
        local textY = 520

        if currentDialog.portrait then
            love.graphics.draw(currentDialog.portrait, 60, 510)
            textX = 60 + currentDialog.portrait:getWidth() + 20
        end

        love.graphics.setFont(getfont(28))
        love.graphics.print(currentDialog.speaker, textX, textY)

        local visibleText = string.sub(currentDialog.text, 1, math.floor(currentDialog.currentChar))
        love.graphics.setFont(getfont(currentDialog.fontSize))
        love.graphics.printf(visibleText, textX, textY + 40, 1180 - textX)
    end

    love.graphics.setFont(tFont)

    local textWidth = tFont:getWidth(tostring(tokens) .. "/20")
    local textHeight = tFont:getHeight()

    local iconWidth = tIcon:getWidth()
    local iconHeight = tIcon:getHeight()

    local totalWidth = iconWidth + 10 + textWidth
    local totalHeight = math.max(iconHeight, textHeight)

    local x = 1280 - totalWidth - 20
    local drawY = math.max(tokenY, 20)
    if tokenY < 0 then
        drawY = tokenY + 20
    end

    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(tIcon, x, drawY)

    love.graphics.print(tostring(tokens) .. "/20", x + iconWidth + 10, drawY)

    if transitionAlpha > 0 then
        love.graphics.setColor(0, 0, 0, transitionAlpha)
        love.graphics.rectangle("fill", 0, 0, 1280, 720)
        love.graphics.setColor(1, 1, 1)
    end
    console.draw()


    -- END --
    love.graphics.pop()
end

function love.textinput(t)
    if console.active then
        console.input = console.input .. t
    end
end

function love.keypressed(key)
    if key == "f1" then
        console.toggle()
    end
    console.keypressed(key)

    if key == "f2" then
        hitboxVisible = not hitboxVisible
    end

    if key == "f3" then
        for i = 1, 11 do
            queueDialog(script[i].s, script[i].t, script[i].p, script[i].a, true, script[i].e)
        end
    end

    if dialogActive and currentDialog then
        if key == "space" then
            if not currentDialog.finished then
                currentDialog.currentChar = #currentDialog.text
                currentDialog.finished = true
            else
                advanceDialog()
            end
        end
    end
end

function love.keyreleased(key)
    if key == "backspace" then
        console.backspaceHeld = false
    end

    if key == "escape" and room == "room8" then
	love.event.quit()
    end
end

function love.wheelmoved(x, y)
    if console.visible then
        console.scroll = console.scroll + y * 2
        if console.scroll < 0 then
            console.scroll = 0
        end
    end
end
