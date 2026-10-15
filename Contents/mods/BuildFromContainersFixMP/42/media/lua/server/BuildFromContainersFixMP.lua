-- Script not needed in single player
if not isMultiplayer() then return end

require "BuildFromContainersFixMP/initialize"
local log = require("BuildFromContainersFixMP/log")

BuildFromContainersFixMP.ISBuildIsoEntity_new = BuildFromContainersFixMP.ISBuildIsoEntity_new or ISBuildIsoEntity.new
function ISBuildIsoEntity:new(character, objectInfo, nSprite, containers, logic, startSquare)
	if logic then
		-- If logic is supplied, we're running on the client, which
		-- doesn't need the patch.
		return BuildFromContainersFixMP.ISBuildIsoEntity_new(self, character, objectInfo, nSprite, containers, logic)
	end

	local buildLogic = BuildLogic.new(character, nil, nil)

	-- Bug 2: When building, the server needs manualSelectInputs
	-- to be true. Without it, startCraftAction fails to set the inputList in
	-- BuildLogic.java:219. The client sets this to true very early on
	-- when creating the build interface.
	buildLogic:setManualSelectInputs(true)

	-- Bug 3: By default, the server is unaware of the initial floor container
	-- and its contents. This rebuilds the floor container based on the square
	-- the player began building.
	local currentSquare = character:getCurrentSquare()
	character:setSquare(startSquare)
	buildLogic:updateFloorContainer(containers)
	character:setSquare(currentSquare)

	buildLogic:setContainers(containers)

	local craftRecipe = objectInfo:getRecipe() and objectInfo:getRecipe():getCraftRecipe() or false
	buildLogic:setRecipe(craftRecipe)

	local instance = BuildFromContainersFixMP.ISBuildIsoEntity_new(
		self, character, objectInfo, nSprite, containers, buildLogic
	)

	instance.startSquare = startSquare

	return instance
end

-- TODO: See if there's a way to make this work without copying the entire
-- function. Modified sections are marked as such.
function ISBuildIsoEntity:create(x, y, z, north, sprite)
	-- MODIFICATION
	local currentSquare = self.character:getCurrentSquare()
	self.character:setSquare(self.startSquare)
	-- END MODIFICATION

	local playerObj = self.character
	local cheat = self.character:isBuildCheat()

	if isServer() then
		-- MODIFICATION
		self.character:setSquare(self.startSquare)
		self.buildPanelLogic:getPossibleCraftCount(true)
		self.buildPanelLogic:canPerformCurrentRecipe()
		-- END MODIFICATION

		self.buildPanelLogic:startCraftAction(nil)

		-- MODIFICATION
		local emptyArray = ArrayList.new()
		self.buildPanelLogic:setContainers(emptyArray)
		-- END MODIFICATION

		self:getSprite()
	end

	local cell = getWorld():getCell()
	self.sq = cell:getGridSquare(x, y, z)

	if isServer() then
		-- There may be no square at these coordinates, according to the DoTileBuilding function
		if self.sq == nil and getWorld():isValidSquare(x, y, z) then
			self.sq = cell:createNewGridSquare(x, y, z, true)
		end

		-- Not sure if this can happen here, but it does on the client side in the DoTileBuilding function
		if not self.sq then
			print("ISBuildIsoEntity -> can't create square - fail")
			return
		end
		self.sq:EnsureSurroundNotNull()
	end

	local face = self:getFace()
	local openFace = self:getOpenFace(north)

	if not self:isValid(self.sq) then
		print("ISBuildIsoEntity -> square invalid - fail")
		return false
	end

	local consumed = false
	if self.buildPanelLogic then
		if cheat then
			consumed = true
			self.character:getPlayerCraftHistory():addCraftHistoryCraftedEvent(self.craftRecipe:getName())
		else
			consumed = self.buildPanelLogic:performCurrentRecipe()
		end
	else
		consumed = cheat or ISBuildIsoEntity.ConsumeBuildEntityItems(self.objectInfo, playerObj)
	end

	-- MODIFICATION
	if isServer() then
		self.character:setSquare(currentSquare)
	end
	-- END MODIFICATION

	if not consumed then
		print("ISBuildIsoEntity -> consume failed")
		return
	end

	if cheat then
		print("ISBuildingEntity -> BuildCheat is active, materials are not required and will not be consumed")
	else
		print("ISBuildIsoEntity -> consume success")
	end

	if openFace and (openFace:getWidth() ~= face:getWidth() or openFace:getHeight() ~= face:getHeight()) then
		print("ISBuildIsoEntity -> openFace different size to closedFace - discarding")
		-- note: this is normal for doubleDoors and garageDoors - these openFaces are determined by tile offset elsewhere - spurcival
		openFace = nil
	end

	if self.buildPanelLogic then
		self.buildPanelLogic:getRecipeDataInProgress():luaCallOnCreate(self.character)
		if (self.buildPanelLogic:getRecipeDataInProgress():getRecipe()) then
			self.buildPanelLogic:getRecipeDataInProgress():processDestroyAndUsedItems(self.character) -- todo handle syncing items and inventory stuff here
		else
			print("ISBuildIsoEntity -> buildPanel recipe is invalid")
		end
	end

	self:updateModData()

	for zz = 0, face:getzLayers() - 1 do
		for xx = 0, face:getWidth() - 1 do
			for yy = 0, face:getHeight() - 1 do
				local tileInfo = face:getTileInfo(xx, yy, zz)
				local openTileInfo = openFace and openFace:getTileInfo(xx, yy, zz)
				local sq = getCell():getGridSquare(x + xx, y + yy, z + zz)
				if tileInfo and tileInfo:getSpriteName() then
					local sprite = tileInfo:getSpriteName()
					local openSprite = openTileInfo and openTileInfo:getSpriteName() or false
					self:setInfo(sq, north, sprite, openSprite)
				end
			end
		end
	end
end

log("Mod loaded.")
