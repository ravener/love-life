
-- JIT is disabled by default on Android due to some unstability
-- However I have noticed great performance boost by turning it on
-- Please report if there are any issues.
if love.system.getOS() == "Android" and not jit.status() then
  jit.on()
end

local atoms = {}
local sqrt, floor, ceil = math.sqrt, math.floor, math.ceil
local yellow, red, green

local function round(x)
  return x >= 0 and floor(x + .5) or ceil(x - .5)
end

local function draw(x, y, color, size)
  love.graphics.setColor(color)

  for _ = 1, size do
    love.graphics.rectangle("fill", x, y, size, size)
  end

  love.graphics.setColor(1, 1, 1)
end

local function atom(x, y, c)
  return {x = x, y = y, vx = 0, vy = 0, color = c}
end

local function randomxy()
  local width, height = love.graphics.getDimensions()

  local x = round(love.math.random() * width  + 1)
  local y = round(love.math.random() * height + 1)

  return x, y
end

local function create(number, color)
  local group = {}

  for i = 1, number do
    local x, y = randomxy()

    table.insert(group, atom(x, y, color))
    table.insert(atoms, group[i])
  end

  return group
end

local function rule(atoms1, atoms2, g)
  local width, height = love.graphics.getDimensions()

  for i = 1, #atoms1 do
    local fx = 0
    local fy = 0
    local a, b

    for j = 1, #atoms2 do
      a = atoms1[i]
      b = atoms2[j]

      local dx = a.x - b.x
      local dy = a.y - b.y
      local d = sqrt(dx * dx + dy * dy)

      if d > 0 and d < 80 then
        local F = g / d

        fx = fx + F * dx
        fy = fy + F * dy
      end
    end

    a.vx = (a.vx + fx) * 0.5
    a.vy = (a.vy + fy) * 0.5
    a.x = a.x + a.vx
    a.y = a.y + a.vy

    if a.x <= 0 or a.x >= width then
      a.vx = a.vx * -1
    end

    if a.y <= 0 or a.y >= height then
      a.vy = a.vy * -1
    end
  end
end

function love.load()
  -- Enter fullscreen on Android
  if love.system.getOS() == "Android" then
    love.window.setFullscreen(true)
  end

  yellow = create(200, { 1, 1, 0 })
  red = create(200, { 1, 0, 0 })
  green = create(200, { 0, 1, 0 })
end

function love.update()
  rule(green, green, -0.32)
  rule(green, red, -0.17)
  rule(green, yellow, 0.34)
  rule(red, red, -0.1)
  rule(red, green, -0.34)
  rule(yellow, yellow, 0.15)
  rule(yellow, green, -0.2)
end

function love.draw()
  for i = 1, #atoms do
    draw(atoms[i].x, atoms[i].y, atoms[i].color, 3)
  end

  local x, y = love.window.getSafeArea()
  local fps = tostring(love.timer.getFPS())
  love.graphics.print("FPS: " .. fps, x, y)
end

function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  end
end
