function love.load()
  math.randomseed(os.time())

  love.window.setTitle("ZombieKill")

  sprites = {}

  sprites.background = love.graphics.newImage('sprites/background.png')
  sprites.bullet = love.graphics.newImage('sprites/bullet.png')
  sprites.player = love.graphics.newImage('sprites/player.png')
  sprites.zombie = love.graphics.newImage('sprites/zombie.png')
  sprites.crosshairs = love.graphics.newImage('sprites/crosshairs.png')

  love.mouse.setVisible(false)

  success = love.window.setFullscreen(true)

  player = {}
  player.x = love.graphics.getWidth() / 2
  player.y = love.graphics.getHeight() / 2
  player.speed = 3 * 60

  player.injured = false
  player.injuredSpeed = 270

  myFont = love.graphics.newFont(30)

  zombies = {}
  bullets = {}

  gameState = 1
  maxTime = 2
  timer = maxTime

  score = 0

  zombieSpeed = 100
end

function love.update(dt)
  if gameState == 2 then
    local moveSpeed = player.speed

    if player.injured then
        moveSpeed = player.injuredSpeed
    end

    if love.keyboard.isDown("d") and player.x < love.graphics.getWidth() then
      player.x = player.x + moveSpeed * dt
    end

    if love.keyboard.isDown("a") and player.x > 0 then
      player.x = player.x - moveSpeed * dt
    end

    if love.keyboard.isDown("w") and player.y > 0 then
      player.y = player.y - moveSpeed * dt
    end

    if love.keyboard.isDown("s") and player.y < love.graphics.getHeight() then
      player.y = player.y + moveSpeed * dt
    end

    for i, z in ipairs(zombies) do
      local currentPlayerAngle = zombiePlayerAngle(z)
      z.x = z.x + math.cos( currentPlayerAngle ) * z.speed * dt
      z.y = z.y + math.sin( currentPlayerAngle ) * z.speed * dt

      if distanceBetween(z.x, z.y, player.x, player.y) < 30 then
        if player.injured == false then
          player.injured = true
          z.dead = true
          score = score + 1
        else
          for i, z in ipairs(zombies) do
            zombies[i] = nil
          end

          if player.injured then
            gameState = 1
            maxTime = 2
            player.x = love.graphics.getWidth() / 2
            player.y = love.graphics.getHeight() / 2
            player.injured = false
          end
        end
      end
    end

    for i, b in ipairs(bullets) do
      b.x = b.x + math.cos( b.direction ) * b.speed * dt
      b.y = b.y + math.sin( b.direction ) * b.speed * dt
    end

    for i=#bullets, 1, -1 do
      local b = bullets[i]
      if b.x < 0 or
        b.y < 0 or
        b.x > love.graphics.getWidth() or
        b.y > love.graphics.getHeight() then

        table.remove(bullets, i)
      end
    end

    for i, z in ipairs(zombies) do
      for j, b in ipairs(bullets) do
        if distanceBetween(z.x, z.y, b.x, b.y) < 20 then
          z.dead = true
          b.dead = true

          score = score + 1
        end
      end
    end

    for i=#zombies, 1, -1 do
      local z = zombies[i]

      if z.dead == true then
        table.remove(zombies, i)
      end
    end

    for i=#bullets, 1, -1 do
      local z = bullets[i]

      if z.dead == true then
        table.remove(bullets, i)
      end
    end

    if gameState == 2 then
      timer = timer - dt

      if timer <= 0 then
        spawnZombie()

        local mintime = 0.5

        if maxTime > mintime then
          maxTime = 0.95 * maxTime
          timer = maxTime
        else
          maxTime = mintime
          timer = maxTime
          if zombieSpeed < 250 then
            zombieSpeed = zombieSpeed + zombieSpeed * dt
          end
        end
      end
    end
  end
end

function love.draw()
  love.graphics.draw(sprites.background, 0, 0, nil, love.graphics.getWidth(), love.graphics.getHeight())

  -- DEBUG ONLY
  -- love.graphics.printf(timer.. "|" .. maxTime .."|".. zombieSpeed, 0, love.graphics.getHeight() - 30, love.graphics.getWidth(), "center")

  if gameState == 1 then
    love.graphics.setFont(myFont)
    love.graphics.printf("Click anywhere to begin!", 0, 50, love.graphics.getWidth(), "center")
  end

  love.graphics.printf("Score: " .. score, 0, love.graphics.getHeight() - 100, love.graphics.getWidth(), "center")

  if player.injured then
    love.graphics.setColor(1, 0, 0)
  end

  love.graphics.draw(
    sprites.player,
    player.x,
    player.y,
    playerMouseAngle(),
    nil,
    nil,
    sprites.player:getWidth()/2,
    sprites.player:getHeight()/2)

  love.graphics.setColor(1, 1, 1)

  for i,z in ipairs(zombies) do
    love.graphics.draw(sprites.zombie, z.x, z.y, zombiePlayerAngle(z), nil, nil, sprites.zombie:getWidth()/2, sprites.zombie:getHeight()/2)
  end

  for i, b in ipairs(bullets) do
    love.graphics.draw(
      sprites.bullet,
      b.x,
      b.y,
      nil,
      0.5,
      nil,
      sprites.bullet:getWidth()/2,
      sprites.bullet:getHeight()/2)
  end

  love.graphics.draw(sprites.crosshairs, love.mouse.getX() - 20, love.mouse.getY() - 20)
end

function playerMouseAngle()
  -- atan2(y1-y2, x1-x2) + add 180º
  return  math.atan2(player.y - love.mouse.getY(), player.x - love.mouse.getX()) + math.pi
end

function zombiePlayerAngle(zombie)
  return  math.atan2(player.y - zombie.y, player.x - zombie.x)
end

function spawnZombie()
  local zombie = {}

  zombie.x = 0
  zombie.y = 0
  zombie.speed = zombieSpeed
  zombie.dead = false

  local side = math.random(1, 4)
  if side == 1 then
    zombie.x = -30
    zombie.y = math.random(0, love.graphics.getHeight())
  elseif side == 2 then
    zombie.x = love.graphics.getWidth() + 30
    zombie.y = math.random(0, love.graphics.getHeight())
  elseif side == 3 then
    zombie.x = math.random(0, love.graphics.getWidth())
    zombie.y = -30
  elseif side == 4 then
    zombie.x = math.random(0, love.graphics.getWidth())
    zombie.y = love.graphics.getHeight() + 30
  end

  table.insert(zombies, zombie)
end

function distanceBetween(x1, y1, x2, y2)
  return math.sqrt( (x2 - x1)^2 + (y2 - y1)^2 )
end

function spawnBullet()
  local bullet = {}
  bullet.x = player.x
  bullet.y = player.y
  bullet.speed = 500
  bullet.direction = playerMouseAngle()
  bullet.dead = false

  table.insert(bullets, bullet)
end

function love.mousepressed(x, y, button)
  if button == 1 and gameState == 2 then
    spawnBullet()
  elseif button == 1 and gameState == 1 then
    gameState = 2
    maxTime = 2
    timer = maxTime
    score = 0
    zombieSpeed = 100
  end
end