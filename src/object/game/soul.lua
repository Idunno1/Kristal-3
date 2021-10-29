local Soul, super = Class(Object)

function Soul:init(x, y)
    super:init(self, x, y)

    self:setOrigin(0.5, 0.5)

    self.color = {1, 0, 0, 1}

    self.sprite = Sprite("player/heart_dodge")
    self.sprite.color = self.color
    self:addChild(self.sprite)

    --self.width = self.sprite.width
    --self.height = self.sprite.height
    self.width = 16
    self.height = 16
    self.hitbox_x = 2
    self.hitbox_y = 2

    self.collider = Hitbox(2, 2, self.width, self.height, self)

    self.original_x = x
    self.original_y = y
    self.target_x = x
    self.target_y = y
    self.timer = 0
    self.transitioning = false
    self.speed = 4
    self.alpha = 0

    -- 1px movement increments
    self.partial_x = (self.x % 1)
    self.partial_y = (self.y % 1)

    self.last_collided_x = false
    self.last_collided_y = false

    self.x = math.floor(self.x)
    self.y = math.floor(self.y)

    self.noclip = false
end

function Soul:transitionTo(x, y)
    self.transitioning = true
    self.target_x = x
    self.target_y = y
    self.timer = 0
end

function Soul:getExactPosition(x, y)
    return self.x + self.partial_x, self.y + self.partial_y
end

function Soul:setExactPosition(x, y)
    self.x = math.floor(x)
    self.partial_x = x - self.x
    self.y = math.floor(y)
    self.partial_y = y - self.y
end

function Soul:move(x, y, speed)
    local movex, movey = x * (speed or 1), y * (speed or 1)
    self:moveX(movex, movey)
    self:moveY(movey, movex)
end

function Soul:moveX(amount, move_y)
    if amount == 0 then
        return false
    end

    self.partial_x = self.partial_x + amount

    local move = math.floor(self.partial_x)
    self.partial_x = self.partial_x % 1

    if move ~= 0 then
        return self:moveXExact(move, move_y)
    else
        return not self.last_collided_x
    end
end

function Soul:moveY(amount, move_x)
    if amount == 0 then
        return false
    end

    self.partial_y = self.partial_y + amount

    local move = math.floor(self.partial_y)
    self.partial_y = self.partial_y % 1

    if move ~= 0 then
        return self:moveYExact(move, move_x)
    else
        return not self.last_collided_y
    end
end

function Soul:moveXExact(amount, move_y)
    local sign = Utils.sign(amount)
    for i = sign, amount, sign do
        local last_x = self.x
        local last_y = self.y

        self.x = self.x + sign

        if not self.noclip then
            Object.startCache()
            local collided, target = Game.battle:checkSolidCollision(self)
            if collided and not (move_y > 0) then
                for i = 1, 2 do
                    Object.uncache(self)
                    self.y = self.y - i
                    collided, target = Game.battle:checkSolidCollision(self)
                    if not collided then break end
                end
            end
            if collided and not (move_y < 0) then
                self.y = last_y
                for i = 1, 2 do
                    Object.uncache(self)
                    self.y = self.y + i
                    collided, target = Game.battle:checkSolidCollision(self)
                    if not collided then break end
                end
            end
            Object.endCache()

            if collided then
                self.x = last_x
                self.y = last_y

                if target and target.onCollide then
                    target:onCollide(self)
                end

                self.last_collided_x = true
                return false, target
            end
        end
    end
    self.last_collided_x = false
    return true
end

function Soul:moveYExact(amount, move_x)
    local sign = Utils.sign(amount)
    for i = sign, amount, sign do
        local last_x = self.x
        local last_y = self.y

        self.y = self.y + sign

        if not self.noclip then
            Object.startCache()
            local collided, target = Game.battle:checkSolidCollision(self)
            if collided and not (move_x > 0) then
                for i = 1, 2 do
                    Object.uncache(self)
                    self.x = self.x - i
                    collided, target = Game.battle:checkSolidCollision(self)
                    if not collided then break end
                end
            end
            if collided and not (move_x < 0) then
                self.x = last_x
                for i = 1, 2 do
                    Object.uncache(self)
                    self.x = self.x + i
                    collided, target = Game.battle:checkSolidCollision(self)
                    if not collided then break end
                end
            end
            Object.endCache()

            if collided then
                self.x = last_x
                self.y = last_y

                if target and target.onCollide then
                    target:onCollide(self)
                end

                self.last_collided_y = true
                return i ~= sign, target
            end
        end
    end
    self.last_collided_y = false
    return true
end

function Soul:update(dt)
    if self.transitioning then
        if self.timer >= 7 then
            self.transitioning = false
            self.timer = 0
            self:setExactPosition(self.target_x, self.target_y)
        else
            self:setExactPosition(
                Utils.lerp(self.original_x, self.target_x, self.timer / 7),
                Utils.lerp(self.original_y, self.target_y, self.timer / 7)
            )
            self.alpha = Utils.lerp(0, self.color[4], self.timer / 3)
            self.sprite:setColor(self.color[1], self.color[2], self.color[3], self.alpha)
            self.timer = self.timer + (1 * DTMULT)
            return
        end
    end


    local speed = self.speed

    -- Do speed calculations here if required.

    if Input.down("cancel") then speed = speed / 2 end -- Focus mode.

    local move_x, move_y = 0, 0

    -- Keyboard input:
    if love.keyboard.isDown("left")  then move_x = move_x - 1 end
    if love.keyboard.isDown("right") then move_x = move_x + 1 end
    if love.keyboard.isDown("up")    then move_y = move_y - 1 end
    if love.keyboard.isDown("down")  then move_y = move_y + 1 end

    if move_x ~= 0 or move_y ~= 0 then
        self:move(move_x, move_y, speed * DTMULT)
    end

    self:updateChildren(dt)
end

return Soul