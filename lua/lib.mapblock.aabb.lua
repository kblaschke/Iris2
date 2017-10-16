-- ***** ***** ***** ***** ***** quadratic block baseclass

cMapBlockAABB = CreateClass(cMapBlock)
cMapBlockAABB.iBlockSize			= 8 	-- block size in tiles

function cMapBlockAABB:Init			(x,y,w,h)		
	cMapBlock.Init(self)
	self.x = x
	self.y = y
	self.w = w
	self.h = h
end

-- returns the bounding box of the map block (x,y,w,h) in tiles
function cMapBlockAABB:GetAABB	()
	return self.x, self.y, self.w, self.h
end
