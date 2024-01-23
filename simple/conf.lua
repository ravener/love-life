
function love.conf(t)
  t.version = "11.4"

  -- Disable modules we don't need for faster startup
  t.modules.joystick = false
  t.modules.physics = false
  t.modules.audio = false
end
