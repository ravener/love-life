
if love.system.getOS() == "Android" then
  -- JIT is disabled by default on Android due to some unstability
  -- However I have noticed great performance boost by turning it on
  -- Please report if there are any issues.
  if not jit.status() then
    jit.on()
  end

  love.window.setFullscreen(true)
end

local atoms, blue, red, green, rules
local random, sqrt, floor, ceil = math.random, math.sqrt, math.floor, math.ceil
local width, height = love.graphics.getDimensions()
local safe_x, safe_y = love.window.getSafeArea()
local random_g = true

local X = 1
local Y = 2
local R = 3
local G = 4
local B = 5
local A = 6
local VX = 7
local VY = 8

local function create(number, rgb)
  local group = {}

  for i = 1, number do
    table.insert(group, {
      [X]=floor(random() * width),
      [Y]=floor(random() * height),
      [R]=rgb[1],
      [G]=rgb[2],
      [B]=rgb[3],
      [A]=1,
      [VX]=0,
      [VY]=0
    })
    table.insert(atoms, group[i])
  end

  return group
end

local function rule(r)
  local atoms1, atoms2, g = r[1], r[2], r[3]

  for i, a in ipairs(atoms1) do
    local fx = 0
    local fy = 0

    for j, b in ipairs(atoms2) do
      local dx = a[X] - b[X]
      local dy = a[Y] - b[Y]
      local d2 = dx * dx + dy * dy

      if d2 > 0 and d2 < 6400 then
        local F = g / sqrt(d2)

        fx = fx + F * dx
        fy = fy + F * dy
      end
    end

    a[VX] = (a[VX] + fx) * 0.5
    a[VY] = (a[VY] + fy) * 0.5
    a[X] = a[X] + a[VX]
    a[Y] = a[Y] + a[VY]

    if a[X] <= 0 or a[X] >= width then
      a[VX] = a[VX] * -1
    end

    if a[Y] <= 0 or a[Y] >= height then
      a[VY] = a[VY] * -1
    end
  end
end

function love.load()
  atoms = {}
  red = create(200, { 1, 0, 0 })
  green = create(200, { 0, 1, 0 })
  blue = create(200, { 0, 0, 1 })

  rules = {
    { red, red, 0.1 },
    { red, green, -0.34 },
    { red, blue, 0.1 },
    { green, red, 0.17 },
    { green, green, -0.32 },
    { green, blue, 0.34 },
    { blue, red, 0.1 },
    { blue, green, -0.2 },
    { blue, blue, 0.4 }
  }

  if random_g then
    for i, r in ipairs(rules) do
      r[3] = random() * 2 - 1
    end
  end
end

function love.update()
  for i, r in ipairs(rules) do
    rule(r)
  end
end

function love.draw()
  love.graphics.points(atoms)

  local fps = tostring(love.timer.getFPS())
  love.graphics.print("FPS: " .. fps, safe_x, safe_y)
  love.graphics.print("Random: " .. (random_g and 'true' or 'false'), safe_x, safe_y+10)
end

function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  end

  if key == "r" then
    random_g = not random_g
    love.load()
  end

  if key == "return" then
    love.load()
  end
end
