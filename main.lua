--==== Note: The Spriteloq code starts on line 64. ====--
assert(table.copy, "Are you running Corona build 484? Please run the sample with build 526 or higher")

Vector2D = require("Vector2D")
local enemy = require('Enemy')

display.setStatusBar(display.HiddenStatusBar)

_W = display.contentWidth
_H = display.contentHeight

	--Variable initialization
	local mRand = math.random;
	
local background = display.newImage("background.png") 
background:setReferencePoint(display.TopLeftReferencePoint)

------------------------------------------------------

-- load the ninja using loq_sprite
local loqsprite = require('loq_sprite')

-- we can load multiple sprite sheets like this
--local nfactory = loqsprite.newFactory('ninja_run_jump_bolt', 'ninja_katana')

-- or we can load one giant sheet like this
local nfactory = loqsprite.newFactory('ninja')
local ninja = nfactory:newSpriteGroup("ninja run")

ninja.x = 50
ninja.y = 250
ninja:play("ninja run")


local animIndex = 1
local function onTouch(event)
	 if(event.phase=="began") then
		animIndex = (animIndex % #ninja:getSpriteNames()) +1
		local spriteName = ninja:getSpriteNames()[animIndex]
		ninja:play(spriteName)
	end
end



------------------------------------------------------
--[[

for key, val in pairs(ninja) do
    print("walk table - "..tostring(key).." : "..tostring(val))
end

for key, val in pairs(ninja._class) do
    print("walk._class table - "..tostring(key).." : "..tostring(val))
end

for key, val in pairs(ninja.curSprite) do
    print("walk.curSprite table - "..tostring(key).." : "..tostring(val))
end

for key, val in pairs(ninja.spriteFactory) do
    print("walk.spriteFactory table - "..tostring(key).." : "..tostring(val))
end

for key, val in pairs(ninja.spriteFactory.setNames) do
    print("walk.spriteFactory.setNames table - "..tostring(key).." : "..tostring(val))
end

for key, val in pairs(ninja.spriteFactory.spriteNames) do
    print("walk.spriteFactory.spriteNames table - "..tostring(key).." : "..tostring(val))
end

]]--

--atrace(xinspect(ninja:getSpriteNames()))
  
	local enemys = {}

-- Leave this function here for now

	function animate(event)	
		for i=1,#enemys do
			local enemy = enemys[i]
					enemy:run()
--					enemy:wander()
				enemy.displayObject:play()
		end
	end


	function CreateEnemys()
	local yOffset=50
		for i=1,2 do
			local loc = Vector2D:new(250, 100+yOffset)
			local enemy = enemy:new(loc)
			table.insert(enemys,enemy)
			yOffset = yOffset+150
			enemy.displayObject:addEventListener('touch', rightTouch) 
--			enemy.displayObject:play()
		end
 	Runtime:addEventListener( "enterFrame", animate );
	end



    CreateEnemys()

for key, val in pairs(enemys) do
    print("enemys - "..tostring(key).." : "..tostring(val))
end
for key, val in pairs(enemy) do
    print("enemy table - "..tostring(key).." : "..tostring(val))
end


--walk:addEventListener('touch', onTouch) 
ninja:addEventListener('touch', onTouch) 
--require('loq_profiler').createProfiler();

