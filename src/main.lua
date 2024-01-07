local utf8 = require("utf8")

if love.system.getOS() == "Android" then
  -- JIT is disabled by default on Android due to some unstability
  -- However I have noticed great performance boost by turning it on
  -- Please report if there are any issues.
  if not jit.status() then
    jit.on()
  end

  love.window.setFullscreen(true)
end

local colors = {
  green={ 0, 1, 0 },
  red={ 1, 0, 0 },
  orange={ 1, 0.5, 0 },
  cyan={ 0, 1, 1 },
  magenta={ 1, 0, 1 },
  lavender={ 0.9, 0.9, 0.98 },
  teal={ 0, 0.5, 0.5 },
}

local color_order = {
  "green",
  "red",
  "orange",
  "cyan",
  "magenta",
  "lavender",
  "teal",
}

local textbox = {
  text="",
  active=false,
}

local num_colors = 4
local num_atoms = 400
local radius = 80
local seed = 91651088029
local show_info = true
local atoms, groups, rules
local random, randomseed, sqrt, floor, ceil = math.random, math.randomseed, math.sqrt, math.floor, math.ceil
local width, height = love.graphics.getDimensions()
local safe_x, safe_y = love.window.getSafeArea()

safe_x = safe_x + 10
safe_y = safe_y + 10

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
  local c1, c2, g = r[1], r[2], r[3]
  local atoms1, atoms2 = groups[c1], groups[c2]
  local radius2 = radius * radius

  for i, a in ipairs(atoms1) do
    local fx = 0
    local fy = 0

    for j, b in ipairs(atoms2) do
      local dx = a[X] - b[X]
      local dy = a[Y] - b[Y]
      local d2 = dx * dx + dy * dy

      if d2 > 0 and d2 < radius2 then
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
  groups = {}

  randomseed(seed)

  local count = 0

  for i, color in ipairs(color_order) do
    color = color_order[i]
    groups[color] = create(num_atoms, colors[color])
    count = count + 1

    if count == num_colors then
      break
    end
  end

  rules = {}

  for a in pairs(groups) do
    for b in pairs(groups) do
      table.insert(rules, { a, b, random() * 2 - 1 })
    end
  end

  love.keyboard.setKeyRepeat(true)
end

function love.update()
  for i, r in ipairs(rules) do
    rule(r)
  end
end

function love.draw()
  love.graphics.points(atoms)

  if show_info then
    local fps = tostring(love.timer.getFPS())
    love.graphics.print("FPS: " .. fps, safe_x, safe_y)

    love.graphics.print("N: " .. num_atoms, safe_x, safe_y+24)
    love.graphics.print("R: " .. radius, safe_x, safe_y+36)
    love.graphics.print("CLR: " .. num_colors, safe_x, safe_y+48)

    local display_seed = textbox.active and '' or seed
    love.graphics.print("SEED: " .. display_seed, safe_x, safe_y+60)

    keys = {
      {"R", "reset"},
      {"S", "edit seed"},
      {"C", "copy settings"},
      {"V", "paste settings"},
      {"ENTER", "random settings"},
      {"SPACE", "toggle info"},
      {"ESC", "quit"},
      {"7/8", "-/+ N"},
      {"9/0", "-/+ R"},
      {"-/=", "-/+ CLR"},
    }

    local count = 0
    for i, defn in ipairs(keys) do
      local key, label = defn[1], defn[2]
      love.graphics.print(key .. ": " .. label, safe_x, safe_y+84+count*12)
      count = count + 1
    end
  end

  if textbox.active then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 50, 70, 100, 14)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print(textbox.text, 50, 70)
    love.graphics.setColor(1, 1, 1, 1)
  end
end

function love.keypressed(key)
  local keys

  if textbox.active then
    keys = {
      escape=function () textbox.active = false end,
      backspace=function ()
        local byteoffset = utf8.offset(textbox.text, -1)

        if byteoffset then
          textbox.text = string.sub(textbox.text, 1, byteoffset - 1)
        end
      end,
      ["return"]=function () seed = tonumber(textbox.text) textbox.active = false love.load() end,
    }
  else
    keys = {
      escape=function () love.event.quit() end,
      r=function () love.load() end,
      ["return"]=function ()
        num_atoms = (floor(random() * 10) + 1) * 100
        radius = (floor(random() * 20) + 1) * 10
        num_colors = floor(random() * 7) + 1
        seed = floor(random() * 100000000000)
        love.load()
      end,
      space=function () show_info = not show_info end,
      s=function () textbox.text = seed textbox.active = true end,
      c=function () love.system.setClipboardText(num_atoms..":"..radius..":"..num_colors..":"..seed) end,
      v=function ()
        local parts = {}
        for s in string.gmatch(love.system.getClipboardText(), "[^:]+") do
          table.insert(parts, s)
        end
        num_atoms = tonumber(parts[1])
        radius = tonumber(parts[2])
        num_colors = tonumber(parts[3])
        seed = tonumber(parts[4])
        love.load()
      end,
      ["7"]=function () if num_atoms > 100 then num_atoms = num_atoms - 100 love.load() end end,
      ["8"]=function () if num_atoms < 1000 then num_atoms = num_atoms + 100 love.load() end end,
      ["9"]=function () if radius > 10 then radius = radius - 10 love.load() end end,
      ["0"]=function () if radius < 200 then radius = radius + 10 love.load() end end,
      ["-"]=function () if num_colors > 1 then num_colors = num_colors - 1 love.load() end end,
      ["="]=function () if num_colors < 7 then num_colors = num_colors + 1 love.load() end end,
    }
  end

  if keys[key] then
    keys[key]()
  end
end

function love.textinput(text)
  if textbox.active and text >= "0" and text <= "9" then
    textbox.text = textbox.text .. text
  end
end
