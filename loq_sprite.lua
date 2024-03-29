-- Copyright 2011 Loqheart

--[[
    Module: loq_sprite

    Defines the SpriteFactory and SpriteGroup creation module. 

    This module lets you create complex sprites in Corona from
    metadata exported from Spriteloq, a Flash SWF to Corona SDK Exporter.  

    To use create a SpriteFactory with newFactory()
    passing in the names of the SpriteLoq exported metadata.

    Usage:
        local loqsprite = require("loq_sprite")

]]
require('loq_util')

if loq_DeclareGlobals then
    if loq_undeclared('loq_sprite') then
        loq_declare('loq_sprite')
    end
end

module(..., package.seeall)

if loq_DeclareGlobals then
    if loq_undeclared('sprite') then
        loq_declare('sprite')
    end
end

require('sprite')

local SpriteFactory = {}
local SpriteGroup = {}

--[[
    Function: newFactory

        Creates a new factory for creating SpriteGroup instances.

        Call newFactory and pass in some initial sprite module names exported from Spriteloq.

        If you don't pass in some initial modules, then you can add them later with SpriteFactory:addSpriteSheetModule.
        You can manually add in individual sprite set infomation with SpriteFactory:addSpriteSetInfo which can be used in conjunction with SpriteFactory:newMultiSet.

    Parameters:

        - ... Optional module names of sprite metadata generated by Spriteloq

    Returns:

        A SpriteFactory instance.
]]
function newFactory(...) 
    local fact = {}
    setmetatable(fact, {__index = SpriteFactory})

    fact.setNames = {}
    fact.spriteInfos = {}
    fact.spriteNames = {}
    fact.spriteSheets = {}
    fact.spriteShapes = {}
    fact.shapeNames = {}

    if #arg > 0 then
        fact:addSpriteSheetModule(unpack(arg))
    end
    return fact
end

--[[
    Class: SpriteFactory

        A factory to create SpriteGroup instances.
]]

--[[
    Property: shapeNames
        The names of the sprite shapes available for the SpriteGroup instance for use with addPhysics.
]]

--[[
    Property: spriteNames
        The names of the sprite animations available for playback in a SpriteGroup instance.
]]

--[[
    Method: addSpriteSetInfo
        Manually add sprite set info to the SpriteFactory.

    Parameters:
        - _setInfos An array of sprites and references: { (spriteName = {set, xReference, yReference})+ }
]]
function SpriteFactory:addSpriteSetInfo(_setInfos)
    for spriteName, spriteInfo in pairs(_setInfos) do
        self.spriteInfos[spriteName] = spriteInfo
        table.insert(self.spriteNames, spriteName)
    end
end

-- addSpriteShapes
function SpriteFactory:addSpriteShapes(_shapes)
    for spriteName, spriteShapes in pairs(_shapes) do
        self.spriteShapes[spriteName] = spriteShapes
    end
end

--[[
    Method: addSpriteSheetModule
        Adds new spritesheet modules exported from Spriteloq to this SpriteFactory.

    Parameters:
        - ... Optional module names of sprite metadata exported from Spriteloq
]]
function SpriteFactory:addSpriteSheetModule(...)
    for i, setName in ipairs(arg) do

        table.insert(self.setNames, setName)

        local spriteModule = require(setName).load()
        local setInfo = spriteModule.setInfo
        for spriteName, spriteInfo in pairs(setInfo) do
            self.spriteInfos[spriteName] = spriteInfo
            table.insert(self.spriteNames, spriteName)
        end
        
        table.insert(self.spriteSheets, spriteModule.spriteSheet)

        local shapes = spriteModule.shapes
        for spriteName, spriteShapes in pairs(shapes) do
            self.spriteShapes[spriteName] = spriteShapes
        end
    end
end

--[[
    Method: dispose
        Removes the sprite sheets from texture memory.

        *Note*: Because of a bug in Corona, dispose uses a timer to dispose of the spritesheet and sheet module.
]]
function SpriteFactory:dispose()
    timer.performWithDelay(1, function()
        for i, setName in pairs(self.setNames) do
            require(setName).destroy()
            unrequire(setName)
        end
        self.setNames = nil
        self.spriteInfos = nil
        self.spriteNames = nil
        self.spriteSheets = nil
        self.spriteShapes = nil
        self.shapeNames = nil 
    end)
end

--[[
    Method: newMultiSet
        Used to stitch multiple sprite module's sprite sheet's into one set.

    Parameters:
        - _modules An array of module names of sprite metadata generated by Spriteloq
        - _spriteInfo A table specifying the animation info of the sprite

    SpriteInfo Properties:

    name - The name of the sprite as defined in the sprite sheet.
    frameCount - How many frames in the sprite's animation.
    frameRate - The frameRate of the animation.
    loopParam - The loop option as specified in the Corona docs for sprites. 0 for loop, 1 for play once, -1 for bounce, -2 for bounce loop
]]
function SpriteFactory:newMultiSet(_modules, _spriteInfo)
    local multiSet = {}
    local xref
    local yref = 0
    local spriteSourceSize

    local msFactor = _spriteInfo.msFactor
    if (msFactor == nil) then
        msFactor = 500 -- used to correct playback timing bug in Corona
    end

    table.insert(self.spriteNames, _spriteInfo.name)

    for i, setName in ipairs(_modules) do
        local setModule = require(setName).load()
        local sheet = setModule.sheet

        if i == 1 then
            local setInfo = setModule.setInfo
            xref = setInfo[_spriteInfo.name].xReference
            yref = setInfo[_spriteInfo.name].yReference
            spriteSourceSize = setInfo[_spriteInfo.name].spriteSourceSize
        end

        local frames = {}

        for i = 1, sheet.frameCount do
            frames[i] = i
        end
        
        table.insert(self.spriteSheets, sheet)
        table.insert(multiSet, {sheet = sheet, frames = frames})
    end
    local theSet = sprite.newSpriteMultiSet(multiSet)

    sprite.add(theSet, _spriteInfo.name, 1, _spriteInfo.frameCount, math.floor(_spriteInfo.frameCount / _spriteInfo.frameRate * msFactor), _spriteInfo.loopParam)

    self.spriteInfos[_spriteInfo.name] = {set = theSet, xReference = xref, yReference = yref, spriteSourceSize = spriteSourceSize }
    table.insert(self.spriteNames, _spriteInfo.name)
end

-- An internal function to give the display group the behavior of a sprite
--     When a sprite is prepared a sprite event with phase == 'prepare' is dispatched.
local decorateGSprite = function (self)
    self.prepareEvent = { name = 'sprite', phase = 'prepare', target = self }
    self.prepare = SpriteGroup.prepare
    self.sprite = SpriteGroup.sprite
    self.play = SpriteGroup.play
    self.pause = SpriteGroup.pause
    self.animating = SpriteGroup.animating
    self.currentFrame = SpriteGroup.currentFrame
    self.sequence = SpriteGroup.sequence
    self.timeScale = SpriteGroup.timeScale
    self.m_timeScale = 1
    self.getSpriteNames = SpriteGroup.getSpriteNames
    self.propagateReference = SpriteGroup.propagateReference
    self._propagateReferenceHelper = SpriteGroup._propagateReferenceHelper
    self.getRectShape = SpriteGroup.getRectShape
    self.getShapes = SpriteGroup.getShapes
    self.addPhysics = SpriteGroup.addPhysics

    loq_listeners(self)
end

--[[
    Method: newSpriteGroup
        Creates a SpriteGroup instance.

    Parameters:
        - _spriteName Optional name of the initial animation.  Otherwise defaults to the first sprite animation.

    Returns:
        A SpriteGroup instance.

    Event:
        Dispatches a sprite event with phase set to 'prepare' if a spriteName is passed in.
]]
function SpriteFactory:newSpriteGroup(_spriteName)
    local gs = display.newGroup()
    gs.spriteFactory = self
    if _spriteName == nil then
        for spriteName, v in pairs(self.spriteInfos) do
            _spriteName = spriteName
            break
        end
    end
    decorateGSprite(gs)
    gs:prepare(_spriteName)

    return gs
end

--[[
    Class: SpriteGroup
        A group of sprites in a display group instance.
]]

--[[
    Group: Properties
]]

--[[
    Property: curSprite
        The current sprite instance of the SpriteGroup. 
        This sprite is changed when a new sprite animation sequence is prepared.
]]

--[[
    Group: Events
]]

--[[
    Event: sprite
        SpriteGroup instances will dispatch events propagated from curSprite.

    Phases:
        end - The sprite stops playing.
        loop - The sprite loops (from last to first, or reverses direction)
        next - The sprite's next frame is played
        prepare - The spriteGroup prepares a new animation.  This is dispatched if the spriteGroup plays a new animation.
]]

--[[
    Group: Functions
]]

--[[
    Method: animating
        The status of the current animation.

    Returns:
        true if animating, false otherwise
]]
function SpriteGroup:animating()
    return self.curSprite.animating
end

--[[
    Method: currentFrame
        Get or set the frame of the current animation sequence.

    Parameters:
        - _frame Optional, to set the current frame of the animation.

    Returns:
        The current frame of the animation.
]]
function SpriteGroup:currentFrame(_frame)
    if _frame ~= nil then
        self.curSprite.currentFrame = _frame
    else
        _frame = self.curSprite.currentFrame
    end
    return _frame
end

--[[ 
    Method: getSpriteNames
        A table of the names of the playable sprite animations.
]]
function SpriteGroup:getSpriteNames()
    return self.spriteFactory.spriteNames
end

--[[
    Method: pause
        Pauses the current sprite animation.
]]
function SpriteGroup:pause()
    self.curSprite:pause()
end

--[[
    Method: play
        Plays prepares and plays a sprite animation.

    Parameters:
        - _spriteName Optional - The name of the sprite animation, or plays the current animation sequence.
        - _keep If the current animation is the same as the new sprite animation, do not reset it.

    Event:
        A sprite event with phase equal to "prepare" is dispatched when if a new sprite animation is prepared.
]]
function SpriteGroup:play(_spriteName, _keep)
    if (_spriteName ~= nil) then
        if (_keep and _spriteName == self:sequence()) then
            -- don't reset
        else

            local sInfo = self.spriteFactory.spriteInfos[_spriteName]

            assert(sInfo ~= nil, "Could not play( '" .. _spriteName .. "' ) - Not a valid sprite sequence name.")

            self:prepare(_spriteName)
            self.curSprite:play()
        end
    else
        self.curSprite:play()
    end
end

--[[
    Method: prepare
        Switches the sprite sequence, but does not play it.

    Parameters:
        - _spriteName The sprite to display.

    Event:
        A sprite event with phase equal to "prepare" is dispatched when the new sprite animation is prepared.
]]
function SpriteGroup:prepare(_spriteName)
    if self.curSprite ~= nil then
        -- self.curSprite:removeEventListener("sprite", self) -- this breaks things, but excluding it doesn't seem to harm anything
        self.curSprite:removeSelf()
    end

    local sInfo = self.spriteFactory.spriteInfos[_spriteName]

    assert(sInfo ~= nil, "Could not prepare( '" .. _spriteName .. "' ) - Not a valid sprite sequence name.")

    local s = sprite.newSprite(sInfo.set)

    s.xReference = sInfo.xReference
    s.yReference = sInfo.yReference
    s.x = 0
    s.y = 0

    s:addEventListener("sprite", self)
    self:insert(s)

    self.curSprite = s
    self.curSprite.timeScale = self.m_timeScale

    self:_propagateReferenceHelper()

    s:prepare(_spriteName)

    self:dispatchEvent(self.prepareEvent)
end

function SpriteGroup:sprite(event)
    event.target = self
    self:dispatchEvent(event)
end

--[[
    Method: sequence
        The name of the current animation.
]]
function SpriteGroup:sequence()
    return self.curSprite.sequence
end

--[[
    Method: timeScale
        Get or set the timeScale of the SpriteGroup instance.

    Parameters:
        - _timeScale Optional, to set the timeScale of the animations.

    Returns:
        The current timeScale of the SpriteGroup instance.
]]

function SpriteGroup:timeScale(_timeScale)
    if _timeScale ~= nil then
        self.m_timeScale = _timeScale
        self.curSprite.timeScale = _timeScale
    end
    return self.m_timeScale
end

--[[
    Method: propagateReference
        Copies the reference point of the SpriteGroup to target display object
        and resets the reference point of the the internal sprites sprite to 0, 0      

    Parameters:
        - _target The target display object to have its reference point updated.
]]
function SpriteGroup:propagateReference(_target)
    self.propagateReferenceTarget = _target
    self:_propagateReferenceHelper()
end

function SpriteGroup:_propagateReferenceHelper()
    if self.propagateReferenceTarget ~= nil then
        local target = self.propagateReferenceTarget

        local tx = target.x
        local ty = target.y

        target.xReference = self.curSprite.xReference
        target.yReference = self.curSprite.yReference
        target.x = tx 
        target.y = ty 

        self.curSprite.xReference = 0
        self.curSprite.yReference = 0
        self.curSprite.x = 0
        self.curSprite.y = 0
    end
end

--[[
    Group: Shape Functions
]]

--[[
    Method: addPhysics
        Adds physical properties to the SpriteGroup instance.
    
    Parameters:
        - _physics The Corona physics module.
        - _bodyType A string representing the physics body type: 'dynamic', 'kinematic', 'static'.
        - _properties A table with properties that contains the physics body: density, friction, bounce
        - _shapeName Optional shapeName for the physics body.  Otherwise uses the current sprite sequence to determine the shape.

    Returns:
        A table of points for the rectangle containing the current sprite's current frame for use with physics.
]]
function SpriteGroup:addPhysics(_physics, _bodyType, _properties, _shapeName)
    local bodies = {}
    local shapes = self:getShapes(_shapeName)
    for i = 1, #shapes do
        table.insert(bodies, { density = _properties.density, friction = _properties.friction, bounce = _properties.bounce, shape = shapes[i]})
    end
    _physics.addBody(self, _bodyType, unpack(bodies))
end

--[[
    Method: getRectShape
        Returns a table of points that represents a rectangle shape for the current sprite's current frame for use
        as the shape property in the body data for physics.addBody.

    Returns:
        A table of points for the rectangle containing the current sprite's current frame for use with physics.
]]
function SpriteGroup:getRectShape()
    local px, py, pw, ph
    if self.propagateReferenceTarget == nil then
        px = -self.curSprite.xReference
        py = -self.curSprite.yReference
    else
        px = -self.propagateReferenceTarget.xReference
        py = -self.propagateReferenceTarget.yReference
    end

    local sInfo = self.spriteFactory.spriteInfos[self.curSprite.sequence]
    px = px - sInfo.spriteSourceSize.width/2 + sInfo.frames[self.curSprite.currentFrame].spriteColorRect.x
    py = py - sInfo.spriteSourceSize.height/2 + sInfo.frames[self.curSprite.currentFrame].spriteColorRect.y

    pw = self.curSprite.width
    ph = self.curSprite.height

    return { px,        py,  
             px + pw,   py,
             px + pw,   py + ph,
             px,        py + ph
           }
end

--[[
    Method: getShape
        Returns an array of polygon vertices that can be used as the shape data for physics bodies. 
        The method addPhysics calls this function.

    Parameters: 
        - _shapeName Optional name of a sprite with a shape. 
                      Default uses the current sprite sequence name for the shape name.  

    Returns:
        Returns an array of polygon vertices that can be used as the shape data for physics bodies. 
        If the sprite does not have shape data its rectangular frame shape is returned.
]]
function SpriteGroup:getShapes(_shapeName)
    local shapeName = _shapeName
    if shapeName == nil then
        shapeName = self.curSprite.sequence
    else
        assert(self.spriteFactory.spriteShapes[shapeName] ~= nil, "Shape name: '" .. shapeName .. " does not exist in sprite factory.")
    end

    if (self.spriteFactory.spriteShapes[shapeName][1] ~= nil) then
        return (self.spriteFactory.spriteShapes[shapeName][1]).polys
    else
        return {self:getRectShape()};
    end
end

--[[
    Section: Examples

    Example: Creating a SpriteFactory and SpriteGroups

        Creating a SpriteFactory and SpriteGroups

    (start code)

    -- Require the module
    local loqsprite = require('loq_sprite')

    -- Create a SpriteFactory and include some spritesheet modules
    local spriteFactory = loqsprite.newFactory('standing_sheet', 'running_sheet', 'jumping_sheet') 

    -- Create a SpriteGroup instance and pass in an initial animation
    local si = spriteFactory:newSpriteGroup('standing')  

    -- Position the spriteGroup instance
    si.x = 100 
    si.y = 200
    
    -- Play one of the animations
    si:play('running')  

    -- For atrace and xinspect
    require('loq_util') 

    -- Prints out the table of animations: standing, running, jumping
    atrace(xinspect(spriteFactory.spriteNames)) 

    -- Adds a new animation for all SpriteGroup instances of factory
    spriteFactory:addSpriteSheetModule('flying_sheet') 

    -- Prints out: standing, running, jumping, flying
    atrace(xinspect(spriteFactory.spriteNames)) 

    -- New sprite uses the first animation by default.
    local si2 = spriteFactory:newSpriteGroup() 
    si2:play()

    si:prepare('flying') -- Switches to flying without playing it.
    (end)
]]

--[[
    Example: Using newMultiSet

        Using newMultiSet

        If you have a sprite with too many frames to pack into a sprite sheet, you can manually create
        a sprite from multiple sheets using newMultiSet.  Spriteloq doesn't support the creation of
        multiple spritesheets for one sprite directly, but newMultiSet gives you a way around this.

    (start code)

    local loqsprite = require('loq_sprite')
    local spriteFactory = loqsprite.newFactory()

    -- Here we call newMultiSet passing in an array of 3 spritesheets we created from Spriteloq.
    -- We also need to pass in a table to specify the parameters of this sprite.
    spriteFactory:newMultiSet(
        {'sprite_1_sheet', 'sprite_14_sheet', 'sprite_27_sheet'},
        {name='character', frameCount=28, frameRate=20, loopParam=0})

    local sg = spriteFactory:newSpriteGroup()
    sg:play()

    (end)
]]

--[[
    Example: Adding physics properties with addPhysics

        Adding physics properties with addPhysics

        If the spritesheet metadata for the sprite includes shape data, you can add physics behavior to a
        SpriteGroup by calling addPhysics and passing the physics module and properties for the object.

        (start code)
        local physics = require('physics')
        physics.start();
        physics.setGravity(0, 10)
        physics.setScale(60)
        physics.setDrawMode('hybrid')

        local loqsprite = require('loq_sprite')
        local spriteFactory = loqsprite.newFactory()

        local tri = spriteFactory:newSpriteGroup('triangle')
        tri:addPhysics(physics, 'dynamic', {density = 1.0, friction = 0.2, bounce = 0.2})

        local box = spriteFactory:newSpriteGroup('box')
        box.y = 200
        box.rotation = 5
        box:addPhysics(physics, 'static', {density = 1.0, friction = 0.3, bounce = 0.3})
        (end)
]]

--[[
    Example: Using getRectShape with physics

        Using getRectShape with physics

        If you want to quickly prototype physics using the rectangular shapes of your sprites, you can call
        getRectShape which will return a table of points to use as the shape property in body table
        for a physics.addBody call.

    (start code)
    local loqsprite = require('loq_sprite')
    local spriteFactory = loqsprite.newFactory()
    local hero = spriteFactory:newSpriteGroup('hero idle')
    local heroRectShape = hero:getRectShape()

    heroBody = { friction=0.9, bounce=0.1, density=2, shape = heroRectShape }

    physics.addBody(hero, "dynamic", heroBody)
    (end)
]]

--[[
    Example: Adding an event listener and looping through animations

        Adding an event listener and looping through animations

        If you need to trigger events based on the play back of SpriteGroup instance, add an event listener.
        The example shows how you can trigger some logic to occur depending on the the SpriteGroup's properties.

    (start code)
    local loqsprite = require('loq_sprite')
    local spriteFactory = loqsprite.newFactory()
    local sg = spriteFactory:newSpriteGroup()

    local animIndex = 1 

    local function playNext(self, _e) -- self is the SpriteGroup instance and _e is the event

        -- when the animation of the current sprite ends switch to the next one
        if _e.phase == 'end' then
            animIndex = (animIndex % #spriteFactory.spriteNames) + 1
            local spriteName = spriteFactory.spriteNames[animIndex]
            sg:play(spriteName)
        end
    end

    sg.sprite = playNext
    sg:addEventListener('sprite', sg)
    sg:play()
    (end)
]]

--[[
    Example: Triggering logic on a certain frame of an animation
        
        From the ninja sample app we show a snippet of code from a SpriteGroup 'sprite' event listener.  
        When the ninja jumps we want to create a new bolt ball on frame 17 of the jump animation.
    
    (start code)
    -- 'ninja' is a SpriteGroup instance
    -- 'bolts' is a table of SpriteGroup instances for our bolt animations
    -- 'nfactory' is a SpriteFactory instance
    -- '_e' is the sprite event

    -- on frame 17 of the 'next' phase of the sprite event
    if _e.phase == 'next' and ninja:currentFrame() == 17 then

        -- create a new bolt and display it at the ninja position
        
        local bolt = nfactory:newSpriteGroup('bolt ball')
        bolt.x = ninja.x
        bolt.y = ninja.y
        bolt:play()
        table.insert(bolts, bolt)
    end
    (end)
]]
