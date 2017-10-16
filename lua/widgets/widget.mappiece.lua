
RegisterWidgetClass("MapPiece","Image")



-- {bVertexBufferDynamic=?,bx0,by0,dbx,dby}
function gWidgetPrototype.MapPiece:Init (parentwidget, params)
	-- generate texture
	local w
	local h
	
	--~ print(SmartDump(params),2)
	
	local k	= "mappiece_"..params.bx0.."_"..params.by0.."_"..params.dbx.."_"..params.dby;
	if params.blocks then 
		k = k.."_"..params.blocks 
		w = params.dbx / params.blocks
		h = params.dby / params.blocks
	else
		w = params.dbx * 8
		h = params.dby * 8
	end
	
	k = k..".png"
	local b = gTempPath
	
	if file_exists(b..k) then
		self.mImage = LoadImageFromFile(k)
	else
		self.mImage = CreateImage()

		if params.blocks then
			self.mImage = CreateImage()
			GenerateRadarImageZoomed(self.mImage, params.blocks, params.bx0, params.by0, params.dbx, params.dby,
				gGroundBlockLoader, gStaticBlockLoader, gRadarColorLoader)
		else
			GenerateRadarImage(self.mImage, params.bx0, params.by0, params.dbx, params.dby,
				gGroundBlockLoader, gStaticBlockLoader, gRadarColorLoader)
		end
	
		self.mImage:SaveAsFile(b..k)
	end
	
	self.mTexture = self.mImage:MakeTexture()
	self.mMaterial = GetPlainTextureGUIMat(self.mTexture)
	
	params.gfxparam_init = MakeSpritePanelParam_SingleSpriteSimple(self.mMaterial, w, h)
	self:SetGfxParam(params.gfxparam_init) -- adjust geometry
end


function gWidgetPrototype.MapPiece:Destroy ()
	self.mImage:Destroy()
	UnloadMaterialName(self.mMaterial)
	UnloadTextureName(self.mTexture)
end
