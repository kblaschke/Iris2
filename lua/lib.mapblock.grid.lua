-- ***** ***** ***** ***** ***** quadratic block baseclass

cMapBlockGrid = CreateClass(cMapBlock)
cMapBlockGrid.iBlockSize			= 8 	-- block size in tiles

function cMapBlockGrid:Init			(bx,by)		
	cMapBlock.Init(self)
	self.bx = bx
	self.by = by
end

-- returns the bounding box of the map block (x,y,w,h) in tiles
function cMapBlockGrid:GetAABB	()
	return self.bx * self.iBlockSize, self.by * self.iBlockSize, self.iBlockSize, self.iBlockSize
end
