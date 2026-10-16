-- Script not needed in single player
if not isMultiplayer() then return end

require "BuildFromContainersFixMP/initialize"
local log = require("BuildFromContainersFixMP/log")

-- Vanilla function, minus the one line
function ISBuildAction:start()
	if not self.item.noNeedHammer then
		self.sawSound = 0
		self.hammer = self.character:getPrimaryHandItem()
		self.hammerSound = 0
	end
	if self.item.craftingBank then
		self.craftingSound = 0
	end

	self.soundTime = 0

	self.item.ghostSprite = IsoSprite.new()
	self.item.ghostSprite:LoadSingleTexture(self.spriteName)
	self.item.ghostSpriteX = self.x
	self.item.ghostSpriteY = self.y
	self.item.ghostSpriteZ = self.z

	self.item:onTimedActionStart(self)

	if isClient() then
		-- BUG: We do not want to call getContainers here.
		-- Because it's called after the player has walked away from the
		-- containers, it erases the containers the server needs to pull from.

		-- self.item.containers = ISInventoryPaneContextMenu.getContainers(self.character)

		local sq = self.character:getCurrentSquare()
		self.item.floorItems = sq:getX()

		self.action:setWaitForFinished(true)
	end

	self.transactionId = createBuildAction(
		self.character, self.x, self.y, self.z, self.north, self.spriteName, self.item
	)
	self.started = true
end

BuildFromContainersFixMP.ISBuildAction_new = BuildFromContainersFixMP.ISBuildAction_new or ISBuildAction.new
function ISBuildAction:new(character, item, x, y, z, north, spriteName, time, containers)
	item.logic = false
	item.startSquare = getPlayer():getSquare()

	-- Neat Building compatibility
	item._NBPrebuildValidation = nil

	return BuildFromContainersFixMP.ISBuildAction_new(
		self, character, item, x, y, z, north, spriteName, time, containers
	)
end

log("Mod loaded.")
