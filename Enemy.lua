Enemy = {}

--require "sprite"

Vector2D = require("Vector2D")

-- load the ninja using loq_sprite
local loqsprite = require('loq_sprite')

-- we can load multiple sprite sheets like this
--local nfactory = loqsprite.newFactory('ninja_run_jump_bolt', 'ninja_katana')

-- or we can load one giant sheet like this
 nfactory = loqsprite.newFactory('ninja')
 ninja = nfactory:newSpriteGroup("ninja run")

local ENEMY_SIZE = 4

function Enemy:new(location)  
	local object = { 
		loc = location,  
	    displayObject =  nfactory:newSpriteGroup("ninja run"),
	}

  	setmetatable(object, { __index = Enemy })  
  	return object
end

function Enemy:run(event) 
	self:render()
end

function Enemy:render()
	self.displayObject.x = self.loc.x
	self.displayObject.y = self.loc.y
end
	
local animIndex = 1
function rightTouch(event)
	 if(event.phase=="began") then
	 	animIndex = (animIndex % #event.target:getSpriteNames()) +1
	 	local spriteName = event.target:getSpriteNames()[animIndex]
	 	event.target:play(spriteName)
--	print("in function rightTouch")
--for key, val in pairs(event.target) do
 --   print("self - "..tostring(key).." : "..tostring(val))
	 --end
end


--	 if(event.phase=="began") then
--		animIndex = (animIndex % #Enemy:getSpriteNames()) +1
--		local spriteName = Enemy:getSpriteNames()[animIndex]
--         print(spriteName)
--		self:play(spriteName)

end


return Enemy 