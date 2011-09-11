-- Copyright 2011 Loqheart

--[[
    Module: loq_ui_button

        Contains a button class that uses a <SpriteGroup> for its states.

        This module lets you create complex buttons that uses a <SpriteGroup>.
        The Loqheart "Export Layout for Corona" flash extension will generate buttons
        using this module.

        To use require the loq_ui_button module and call newButton() with a SpriteButton "constructor" table.

        The buttons created by loq_ui_button supports additional events and states compared to 
        the buttons created by the ui.lua module created by Ansca.  Check out the code sample below.

    Usage: 
        local loqbutton = require('loq_ui_button')
]]

if loq_DeclareGlobals then
    loq_declare('loq_ui_button')
end

module(..., package.seeall)

require('loq_util')

--[[
    Function: activateMultitouch
        Enables multi-touch.
]]
function activateMultitouch()
    system.activate('multitouch')
end

--[[
    Function: deactivateMultitouch
        Disables multi-touch.
]]
function deactivateMultitouch()
    system.deactivate('multitouch')
end

-----------------
local function setSprite(_button, _state, _keep)
    if _button.autoPlay then
        _button.spriteGroup:play(_button[_state], _keep)
    else
        _button.spriteGroup:prepare(_button[_state])
    end

    if _button[_state .. 'Frame'] ~= nil then
        _button.spriteGroup:currentFrame(_button[_state .. 'Frame'])
    end
end

local function setFocus(target)
    display.getCurrentStage():setFocus(target)
end

local function isInside(self, event)
    local bounds = self.stageBounds
    local x,y = event.x, event.y
    return bounds.xMin <= x and bounds.xMax >= x and bounds.yMin <= y and bounds.yMax >= y
end

local function touchHandler(self, event)

    self.touchEvent = event

    local res = nil

    if (event.phase == "began") then
        if (self.press) then
            setSprite(self, 'press')
        elseif (self.down) then
            setSprite(self, 'down')
        end

        if (self.onPress) then
            res = self:onPress(event) or res
        elseif (self.onDown) then
            res = self:onDown(event) or res
        end

        if self.focus then
            setFocus(self)
        end

        self._inside = true
    elseif (event.phase == "moved") then
        if (isInside(self, event) and self._inside ~= true ) then
            if (self.press) then
                setSprite(self, 'press', true)
            elseif (self.down) then
                setSprite(self, 'down', true)
            end
            if (self.onPress) then
                res = self:onPress(event) or res
            elseif (self.onDown) then
                res = self:onDown(event) or res
            end

            if self.focus then
                setFocus(self)
            end

            self._inside = true
            
        elseif (self._inside and isInside(self, event) == false) then
            if (self.release) then
                setSprite(self, 'release', true)
            elseif (self.up) then
                setSprite(self, 'up', true)
            end
            if (self.onRelease) then
                res =self:onRelease(event) or res
            elseif (self.onUp) then
                res = self:onUp(event) or res
            end

            if self.focus then
                setFocus(nil)
            end
            self._inside = false
        end
    elseif (event.phase == "ended" or event.phase == "cancelled") then
        -- getting a bug where it's possible to to get an 'ended' but not inside!
        --if (isInside(self, event)) then
            if (self.release) then
                setSprite(self, 'release', true)
            elseif (self.up) then
                setSprite(self, 'up', true)
            end

            if (self.onRelease) then
                res = self:onRelease(event) or res
            elseif (self.onUp) then
                res = self:onUp(event) or res
            end
            if (self.onTap and self._inside) then
                res = self:onTap(event) or res
            end

        --end

        if self.focus then
            setFocus(nil)
        end

        self._inside = false
    end

    return res
end

local function spriteHandler(self, event)

    local res = nil

    if (event.phase == "end") then
        if (event.target:sequence() == self.press) then
            setSprite(self, 'down', true)
            if (self.onDown) then
                res = self:onDown(self.touchEvent) or res
            end
        elseif (event.target:sequence() == self.release) then
            setSprite(self, 'up', true)
            if (self.onUp) then
                res = self:onUp(self.touchEvent) or res
            end
            if (isInside(self, self.touchEvent) and self.onTap) then
                res = self:onTap(self.touchEvent) or res
            end
        end
    end

    return res
end


--[[
    Function: newButton
        A function that takes a constructor table to create a new <SpriteButton>.

    Parameters:
        - paramObj A <SpriteButton> constructor table

    Returns:
        <SpriteButton> instance

    See Also:
        <SpriteButton>
]]
function newButton( paramObj )
	local button = display.newGroup()
    button._inside = false

    for k, v in pairs(paramObj) do
        button[k] = v
    end

    button:insert( button.spriteGroup, true )
    if button.focus == nil then
        button.focus = true
    end

    button.sprite = spriteHandler
	button.spriteGroup:addEventListener( "sprite", button )

    setSprite(button, 'up')

	button.touch = touchHandler
	button:addEventListener( "touch", button )

	return button
end

--[[
    Class: SpriteButton
        A button class that uses a <SpriteGroup> to represent its visual state.

    See Also: 
        <SpriteGroup>, <newButton>
]]

--[[
    Topic: SpriteButton Constructor Table

    The newButton() function takes a table that can contain the following properties.  Another other custom properties are
    passed along to button.

    spriteGroup  -  The SpriteGroup instance that contains the visual states for the button.
    autoPlay     -  Set the sprite animation play when it changes state.  Default is true.  Otherwise will prepare the sprite without playing.
    up           -  Name of the up animation sequence in the sprite instance.
    down         -  Name of the down animation sequence in the sprite instance.
    release      -  Name of the release animation sequence in the sprite instance.
    press        -  Name of the press animation sequence in the sprite instance.
    upFrame      -  The start frame of the up animation sequence.
    downFrame    -  The start frame of the down animation sequence.
    pressFrame   -  The start frame of the press animation sequence.
    releaseFrame -  The start frame of the release animation sequence.
    onUp         -  A callback function for the up event. Dispatched after a button has been released.  The function receives an event object.
    onDown       -  A callback function for the down event. Dispatched after a button has been pressed.  The function receives an event object.
    onPress      -  A callback function for the press event. Dispatched when button is first pressed.  Only triggers if the press sprite is assigned.  The function receives an event object.
    onRelease    -  A callback function for the press event. Dispatched when the button is released.  Only triggers if the release sprite is assigned.  The function receives an event object.
    onTap        -  A callback function for the tap event. Dispatched when the button is tapped.  The function receives an event object.
]]

--[[
    Section: Examples

    Example: Creating a SpriteButton

        Creating a SpriteButton

    (start code)
    local loqsprite = require("loq_sprite")
    local spriteFactory = loqsprite.newFactory("startButton_sheet")

    -- Create a complex button with press, down, release, up states.
    -- Attaches listeners for onPress, onDown, onRelease, onUp and onTap events.

    local loqbutton = require("loq_ui_button")
    
    local sbtn = loqbutton.newButton { -- create a SpriteButton constructor table
        spriteGroup = spriteFactory:newSpriteGroup("startButton_bup")

        -- when the state changes automatically play the sprite
        , autoPlay = true

        -- the sprites for the button states
        , up = "startButton_bup"
        , down = "startButton_bdown"
        , press = "startButton_bpress"
        , release = "startButton_brelease"

        -- the start frame of the state
        , upFrame = 1
        , downFrame = 2
        , pressFrame = 3
        , releaseFrame = 4
       
        -- the callback functions for the button states
        , onUp = function(event) atrace('startButton up') end
        , onDown = function(event) atrace('startButton down') end
        , onPress = function(event) atrace('startButton press') end
        , onRelease = function(event) atrace('startButton release') end
        , onTap = function(event) atrace('startButton tap') end


        -- custom data passed along to button to position it
        , x = 100
        , y = 100

        -- custom data to set the button's id
        , id = 'button 1'
    }
    (end)
]]

