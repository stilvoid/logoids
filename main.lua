local WIDTH, HEIGHT = 800, 600

local max_sprite_size = 128

local player = {
    firing = false,
    thrusting = false,
    rotation = 0,
    thrust = 100,
    vel = {
        x = 0,
        y = 0,
    },
    pos = {
        x = 0,
        y = 0,
        a = 0,
    },
}

local sprites = {}

local bullets = {}

local asteroids = {}

local level = 1

function new_level()
    asteroids = {}

    for i = 1, level do
        sprite = sprites[love.math.random(1, #sprites)]

        x = love.math.random(WIDTH / 4)
        if love.math.random() > 0.5 then
            x = x + WIDTH / 2
        end

        y = love.math.random(HEIGHT / 4)
        if love.math.random() > 0.5 then
            y = y + HEIGHT / 2
        end

        asteroids[#asteroids + 1] = {
            sprite = sprite,
            size = max_sprite_size / math.max(sprite:getWidth(), sprite:getHeight()),
            pos = {
                a = love.math.random() * math.pi * 2,
                x = x,
                y = y,
            },
            vel = {
                a = love.math.random() * 4 - 2,
                x = 100 * love.math.random() - 50,
                y = 100 * love.math.random() - 50,
            },
        }
    end

    player.firing = false
    player.thrusting = false
    player.rotation = 0
    player.thrust = 5
    player.turn_speed = 5
    player.vel = {x = 0, y = 0}
    player.pos = {x = WIDTH / 2, y = HEIGHT / 2, a = 0}
    player.size = max_sprite_size / math.max(player.sprite:getWidth(), player.sprite:getHeight()) / 4
end

function love.load()
    love.window.setTitle("Logoids")

    -- Set up the display
    love.window.setMode(WIDTH, HEIGHT)
    love.mouse.setVisible(false)
    love.mouse.setGrabbed(true)

    -- Load up the player sprite
    player.sprite = love.graphics.newImage("resources/player.png")

    -- Load up the asteroid images
    for _, file in pairs(love.filesystem.getDirectoryItems("images")) do
        sprites[#sprites + 1] = love.graphics.newImage("images/" .. file)
    end

    new_level()
end

function love.update(dt)
    -- Rotate player
    player.pos.a = player.pos.a + player.rotation * player.turn_speed * dt

    -- Move player
    if player.thrusting then
        player.vel.x = player.vel.x + math.sin(player.pos.a) * player.thrust * dt
        player.vel.y = player.vel.y + math.cos(player.pos.a) * player.thrust * dt
    end

    player.pos.x = player.pos.x + player.vel.x
    player.pos.y = player.pos.y - player.vel.y

    -- Check player bounds
    s = math.max(player.sprite:getWidth(), player.sprite:getHeight()) * player.size / 2
    if player.pos.x < -s then
        player.pos.x = WIDTH + s
    elseif player.pos.x > WIDTH + s then
        player.pos.x = -s
    end

    if player.pos.y < -s then
        player.pos.y = HEIGHT + s
    elseif player.pos.y > HEIGHT + s then
        player.pos.y = -s
    end

    -- Move asteroids
    for _, a in pairs(asteroids) do
        a.pos.a = a.pos.a + a.vel.a * dt
        a.pos.x = a.pos.x + a.vel.x * dt
        a.pos.y = a.pos.y + a.vel.y * dt
    end

    -- Check asteroid bounds
    for _, a in ipairs(asteroids) do
        s = math.max(a.sprite:getWidth(), a.sprite:getHeight()) * a.size / 2

        if a.pos.x < -s then
            a.pos.x = WIDTH + s
        elseif a.pos.x > WIDTH + s then
            a.pos.x = -s
        end

        if a.pos.y < -s then
            a.pos.y = HEIGHT + s
        elseif a.pos.y > HEIGHT + s then
            a.pos.y = -s
        end
    end

    -- Move bullets
    for _, b in pairs(bullets) do
        b.pos.x = b.pos.x + b.vel.x
        b.pos.y = b.pos.y + b.vel.y

        b.counter = b.counter - 1
        
        if b.counter == 0 then
            b.dead = true
        end
    end

    -- Launch bullets
    if player.firing then
        bullets[#bullets + 1] = {
            vel = {
                x = math.sin(player.pos.a) * 10,
                y = -math.cos(player.pos.a) * 10,
            },
            pos = {
                x = player.pos.x,
                y = player.pos.y,
            },
            counter = 2000,
        }

        player.firing = false
    end

    -- Find collisions
    for _, b in pairs(bullets) do
        if not b.dead then
            for _, a in pairs(asteroids) do
                if not a.dead then
                    dx = a.pos.x - b.pos.x
                    dy = a.pos.y - b.pos.y

                    s = math.max(a.sprite:getWidth(), a.sprite:getHeight()) * a.size

                    d = math.sqrt(dx * dx + dy * dy)

                    if d < s / 2 then
                        a.dead = true
                        b.dead = true

                        -- Split the roid?
                        if s > max_sprite_size / 8 then
                            for _ = 1, 2 do
                                asteroids[#asteroids + 1] = {
                                    sprite = a.sprite,
                                    size = a.size / 2,
                                    pos = {
                                        a = love.math.random() * math.pi * 2,
                                        x = a.pos.x,
                                        y = a.pos.y,
                                    },
                                    vel = {
                                        a = love.math.random() * 2 - 1,
                                        x = 100 * love.math.random() - 50,
                                        y = 100 * love.math.random() - 50,
                                    },
                                }
                            end
                        end

                        break
                    end
                end
            end
        end
    end

    -- Count living enemies
    count = 0
    for _, a in pairs(asteroids) do
        if not a.dead then
            count = 1
            break
        end
    end

    if count == 0 then
        level = level + 1
        new_level()
    end
end

function love.draw()
    love.graphics.clear()

    -- The roids
    for _, a in pairs(asteroids) do
        if not a.dead then
            love.graphics.draw(a.sprite, a.pos.x, a.pos.y, a.pos.a, a.size, a.size, a.sprite:getWidth() / 2, a.sprite:getHeight() / 2)
        end
    end

    -- The player
    love.graphics.draw(player.sprite, player.pos.x, player.pos.y, player.pos.a, player.size, player.size, player.sprite:getWidth() / 2, player.sprite:getHeight() / 2)

    -- Bullets
    for _, b in pairs(bullets) do
        if not b.dead then
            love.graphics.circle("fill", b.pos.x, b.pos.y, 3)
        end
    end
end

function love.keypressed(key)
    if key == "left" then
        player.rotation = player.rotation - 1
    end

    if key == "right" then
        player.rotation = player.rotation + 1
    end

    if key == "up" then
        player.thrusting = true
    end

    if key == "lctrl" then
        player.firing = true
    end

    if key == "q" or key == "escape" then
        love.event.quit()
    end
end

function love.keyreleased(key)
    if key == "left" then
        player.rotation = player.rotation + 1
    end

    if key == "right" then
        player.rotation = player.rotation - 1
    end

    if key == "up" then
        player.thrusting = false
    end

    if key == "lctrl" then
        player.firing = false
    end
end
