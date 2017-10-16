-- 2d char anim graphics
-- loads the 2d anim-art, not specific to 2d renderer, might also be used in 3d mode for fallbacks

--[[
http://www.runuo.com/forums/server-support-windows/55184-custom-artwork-how.html
http://varan.uodev.de/ Mulpatcher.zip
http://www.runuo.com/forums/server-support-windows/64140-animinfo-mul-corrupt-muopatch.html

gAnimLoader   mHighDetailed   mLowDetailed  : 200,200,

2.0K animinfo.mul	apparently unused, only filled with 		04 02  bytes
1.1M animdata.mul	gAnimdataFile		gAnimDataLoader	 GetAnimDataInfo():	int8 miFrames[64],miUnknown,miCount,miFrameInterval,miFrameStart;
1.8M anim.idx		gAnimidxFile		gAnimLoader
186M anim.mul		gAnimFile			gAnimLoader
264K anim2.idx
132M anim2.mul
1.5M anim3.idx
 25M anim3.mul
993K anim4.idx
 58M anim4.mul
930K anim5.idx
 42M anim5.mul
 
 
 corpseanim    model     anim     framecount
 corpseanim    400     105     x		diebackwards
 corpseanim    400     110     x		dieforward
 corpseanim		1       10      x		diebackwards
 corpseanim		1       15      x		dieforward
     iCurrentId = (iBaseId + GetAnimDataInfo(iBaseId).miFrames[ iCurrentFrame ])
	 
200 	 0	walk
200 	 5	run
200 	10	idle
200 	15	eat(horse)? die?
200 	20	idleanim?(horse:nodge-head)
200 	25	attack1
200 	30	attack2
200 	35	gethit?
200 	40	dieside?
200 	45	gethit?cast?
200 	50	gethit?cast?
200 	55	idlenaim?
200 	60	dieside?

2		 0	walk
2		 5	idle
2		10	dieback
2		15	dieforward
2		20	attack
2		25	attack2
2		30	attack3
2		35	?
2		40	?
2		45	?
2		50	gethit
2		55	pickupitem
2		60	?
2		65	?
2		70	?
2		75	idlenaim?
2		80	idlenaim?
2		85	idlenaim?
2		90	eat/idlenaim?


]]--

--[[
iModelID : 13 = evortex
iModelID : 50 = skeleton
iModelID : 51 = slime
iModelID : 200 = horse
iModelID : 204 = horse
iModelID : 226 = horse
iModelID : 228 = horse
iModelID : 210 = ostard
iModelID : 218 = ostard
iModelID : 219 = ostard
iModelID : 220 = lama

iModelID : 409 = hat
iModelID : 430 = shorts
iModelID : 431 = trousers

iModelID : 469 = finerobe
iModelID : 574 = bladespirit
iModelID : 970 = deathshroud
iModelID : 987 = gmrobe
iModelID : 991 = britain-mage-robe

crane 0xcc=204 in anim4
warning, Renderer2D:UpdateMobile load uoanim failed     254     0       0       0
GetStaticTileType(10084)        {miUnknown3=0,miHue=0,miQuality=0,miAnimID=0,bBackGround=false,iSortBonus2D=6,iCalcHeight=0,miFlags=16384=0x4000,miWeight=0,miQuantity=0,msName="crane",bSurface=false,miUnknown=0,miHeight=0,miUnknown1=0,bBridge=false,miUnknown2=0,}
		10084 = 0x2764  
		10084-254=9830


iModelID : 13 = evortex  in anim1
warning, Renderer2D:UpdateMobile load uoanim failed     164     3       0       0
>1      164     0       0
>2      {miFlags=16464=0x4050,miWeight=-1,miQuantity=0,msName="log wall",  }
>3      {miFlags=0x10002040,miWeight=-1,miQuantity=0,msName="bark roofing",}  GetStaticTileType(mobile.artid+9830)


deathwatch beetle = 3 in anim4:
warning, Renderer2D:UpdateMobile load uoanim failed     242     3       0       0       242

runebeetle = 4 in anim4
warning, Renderer2D:UpdateMobile load uoanim failed     244     3       0       0       244
gargoyle:artid=4

Bodyconv.def 
# <Object> <LBR version (anim2)> <AoS version (anim3)> <AoW version (anim4)><Mondain version (anim5)>		
242	-1	-1	3	-1 			deathwatch beetle
244	-1	-1	4	-1			runebeetle

Body.def 
# <ORIG BODY> {<NEW BODY>} <NEW HUE>
warning, Renderer2D:UpdateMobile load uoanim failed     164     3       0       0       164       energy vortex
164 {13} 20     energy vortex


Body.def 
warning, Renderer2D:UpdateMobile load uoanim failed     776     21      0       0       776
776 {39} 2120          -- 39:mongbat gfx
776	44	-1	-1	-1	 	horde minion in anim2

142 {42, 44, 45} 32875      anim2:44=horde-minion  anim1:42=ratman
]]--

gBodyDef = {}
gBodyConfDef = {}
gEquipConvDef = {}

-- loads Body.def
function LoadBodyDef (filename)
	gBodyDef = {}
	if file_exists(filename) then
		for line in io.lines(filename) do
			-- # Format is: <ORIG BODY> {<NEW BODY>} <NEW HUE>
			-- 142 {42, 44, 45} 32875      anim2:44=horde-minion  anim1:42=ratman      
			-- multiple <NEW BODY> entries : maybe in the higher anim files? (anim2.mul - anim5.mul)?
			local s1,s2, bodyid,newbodylist,newhue = string.find(line,"([%-%d]+)%s+%{([^%}]+)%}%s+([%-%d]+)")
			if (s1) then 
				newbodylist = explode("%s*,%s*",newbodylist)
				for k,v in pairs(newbodylist) do newbodylist[k] = tonumber(v) end
				gBodyDef[tonumber(bodyid)] = {newbodylist,tonumber(newhue)}
			end
		end
	else
		print("LoadBodyDef error, file not found",filename)
	end
end

-- loads Bodyconv.def
function LoadBodyConfDef (filename)
	gBodyConfDef = {}
	if file_exists(filename) then
		for line in io.lines(filename) do
			-- # <Object> <LBR version (anim2)> <AoS version (anim3)> <AoW version (anim4)><Mondain version (anim5)>	
			-- 157	1	-1	-1	-1
			local s1,s2, bodyid,anim2,anim3,anim4,anim5 = string.find(line,"([%-%d]+)%s+([%-%d]+)%s+([%-%d]+)%s+([%-%d]+)%s+([%-%d]+)")
			if (s1) then gBodyConfDef[tonumber(bodyid)] = {tonumber(anim2),tonumber(anim3),tonumber(anim4),tonumber(anim5)} end
		end
	else
		print("LoadBodyConfDef error, file not found",filename)
	end
end

-- loads Equipconv.def
function LoadEquipConvDef (filename)
	gEquipConvDef = {}
	if file_exists(filename) then
		for line in io.lines(filename) do
			-- #  #bodyType	#equipmentID	#convertToID	#GumpIDToUse	#hue	
			-- 401	538	986	0	0			# female chain substitution	
			-- mainly female and elven stuff, probably not needed
		end
	else
		print("LoadEquipConvDef error, file not found",filename)
	end
end


-- TODO : http://svn.berlios.de/viewcvs/wolfpack/trunk/client/  

gAnimAtlasCache = {}
kAnimIDRangeLen_HighDetailed	= 200  -- mHighDetailed    WARNING ! depends on iLoaderIndex, see Anim_GetRealID
kAnimIDRangeLen_LowDetailed		= 200  -- mLowDetailed


function Anim2DAtlas_TranslateAndLoad (iModelID,iAnimID,iFrame,iHue) 
	local iLoaderIndex = 1
	iModelID,iHue,iLoaderIndex = UOAnimTranslateBodyID(iModelID,iHue)
	return Anim2DAtlas_Load(iModelID,iAnimID,iFrame,iHue,iLoaderIndex) 
end

-- todo : humans : one atlas with complete equipment, will need alpha-blit for images ?
-- todo : mobile : load anim only on demand, e.g. only load walk anim when the mobile actually walks
-- returns sMatName,iWidth,iHeight,iCenterX,iCenterY,iFrames,u0,v0,u1,v1
function Anim2DAtlas_Load (iModelID,iAnimID,iFrame,iHue,iLoaderIndex) 
	local o = Anim2DAtlas_LoadAtlasPiece(iModelID,iAnimID,iFrame,iHue,iLoaderIndex)
	if (o) then 
		local basematerial = "renderer2dbillboard"
		local matname = o.atlas.atlasgroup:LoadAtlasMat(o.atlas,basematerial)
		return matname,o.origw,o.origh,o.iCenterX,o.iCenterY,o.iFrames,o.u0,o.v0,o.u1,o.v1 
	end 
end

gAnimFrameCountCache = {}
function Anim2D_GetFrameCount (iRealID,iLoaderIndex)
	local n = iRealID..","..iLoaderIndex
	local o = gAnimFrameCountCache[n] 
	if (o ~= nil) then return o end
	local loader = gAnimLoader[iLoaderIndex or 1]
	local o = loader and loader:GetNumberOfFrames(iRealID)
	gAnimFrameCountCache[n] = o or false
	return o
end



-- returns atlaspiece
function Anim2DAtlas_LoadAtlasPiece (iModelID,iAnimID,iFrame,iHue,iLoaderIndex)
	return Anim2DAtlas_LoadAtlasPieceEx(Anim_GetRealID(iModelID,iAnimID,iLoaderIndex),iFrame,iHue,iLoaderIndex)
end

function Anim2DAtlas_LoadAtlasPieceEx (iRealID,iFrame,iHue,iLoaderIndex)
	iLoaderIndex = iLoaderIndex or 1
	local n = iRealID..","..iFrame..","..iHue..","..iLoaderIndex
	local o = gAnimAtlasCache[n]
	if (o ~= nil) then return o end
	
	-- load frame image
	--~ local iFrameCount = Anim2D_GetFrameCount(iRealID,iLoaderIndex)
	--~ iFrame = iFrame % iFrameCount
	--~ print("Anim2DAtlas_LoadAtlasPieceEx:ExportAnimFrameToImage",iRealID,iFrame,iHue,iLoaderIndex)
	local img,iWidth,iHeight,iCenterX,iCenterY,iFrames = ExportAnimFrameToImage(iRealID,iFrame,iHue,iLoaderIndex)
	--~ print("Anim2DAtlas_LoadAtlasPieceEx:ExportAnimFrameToImage = ",img,iWidth,iHeight,iCenterX,iCenterY,iFrames)
	--~ if (not img) then print("Anim2DAtlas_Load : dead anim ",iModelID,iAnimID,iFrame,iHue) end
	if (not img) then gAnimAtlasCache[n] = false return end
		
	-- add to atlas
	local w = 64
	local iBorderPixels = 4
	local bWrap = false
	local b = iBorderPixels
	while (w < b+iWidth+b) do w = w * 2 end
	while (w < b+iHeight+b) do w = w * 2 end
	local atlasgroup = CreateAtlasGroup(w,w,iBorderPixels,bWrap)
	local atlas,u0,v0,u1,v1,origw,origh = atlasgroup:AddImageToAtlasGroup(img)
	img:Destroy()
	if (not atlas) then gAnimAtlasCache[n] = false return end
	assert(iWidth == origw)
	assert(iHeight == origh)
	
	-- create and store extended atlaspiece
	local atlaspiece = {
		atlas	=atlas,
		u0		=u0,
		v0		=v0,
		u1		=u1,
		v1		=v1,
		uvw		=u1-u0,
		uvh		=v1-v0,
		origw	=origw,
		origh	=origh,
		iCenterX=iCenterX,
		iCenterY=iCenterY,
		iFrames=iFrames,
		}
	gAnimAtlasCache[n] = atlaspiece
	return atlaspiece
end




function Anim_GetIdleAnim (iModelID,iLoaderIndex,bHasMount)
	local high,low = unpack(gUOAnimRealIDCatBoundsByLoaderIndex[iLoaderIndex])
	if (iModelID < high			) then return  5 end
	if (iModelID < high + low	) then return 10 end
	return bHasMount and 125 or 20  -- Human
end

--~ chimera : mount item artid = 0x3e90 -> 0x114=276  bodyconf.def : 276 -1 -1 -1 34  mulpatcher graphic : anim5 : 0x66=102
-- chimera loader=5 iModelID=0x66=102
-- chim : RealID = 11210,11274  
-- 11210 : walk  don't move wings, only feet
-- 11215 : run   flap with wings and move feet
-- 11220 : idle
-- 11225 : idle-anim (move a bit)
-- 11230 : cast (roar and flap wings)
-- 11235 : attack (meelee, stand up and claw)
-- 11240 : attack2 (meelee, bite)
-- 11245 : gethit
-- 11250 : die
-- 11255 : cast? roar and flap wings
-- 11260 : gethit ? short anim
-- 11265 : sit on ground
-- 11270 : die forward
-- anim5:1760 - 1870 = 110 
-- anim5:4070 - 4180 = 110    37*110
-- anim5:4180 - 4290 = 110    38*110
-- anim5:4290 - 4385 = 95 ???
-- chim : RealID = 11210,11274 : 65 anims  .. 65*2 = 130
-- first : 11210 : walk 
-- last  : 11270 : die forward

function Anim_GetMoveAnim (iModelID,iLoaderIndex,bHasMount,bRun)
	local high,low = unpack(gUOAnimRealIDCatBoundsByLoaderIndex[iLoaderIndex])
	if (iModelID < high			) then return  0 end
	if (iModelID < high + low	) then return bRun and 5 or 0 end
	return bHasMount and (bRun and 120 or 115) or (bRun and 10 or 0)  -- Human
end


function Anim_GetCorpseAnim (iModelID,iLoaderIndex)
	local high,low = unpack(gUOAnimRealIDCatBoundsByLoaderIndex[iLoaderIndex])
	if (iModelID < high			) then return bForward and 15 or 10 end
	if (iModelID < high + low	) then return 40 end -- 60?
	return bForward and 110 or 105 -- human
end

function Anim_GetModelCategory (iModelID)
	if (iModelID < kAnimIDRangeLen_HighDetailed									) then return 1 end
	if (iModelID < kAnimIDRangeLen_HighDetailed + kAnimIDRangeLen_LowDetailed	) then return 2 end
	return 3
end
function Anim_GetModelCategorySize (iModelCat)
	if (iModelCat == 1) then return 110 end
	if (iModelCat == 2) then return 65 end
	return 175
end
	
-- iID is probably bodyid, and animid the animation ? ported from varans code
gUOAnimRealIDCatBoundsByLoaderIndex = { [1]={200,200}, [2]={200,200}, [3]={700,700}, [4]={200,200}, [5]={100,200,102,11210}}
function Anim_GetRealID (iModelID,iAnimID,iLoaderIndex)
	local high,low,exminmodel,exminreal = unpack(gUOAnimRealIDCatBoundsByLoaderIndex[iLoaderIndex])
	if (exminmodel and iModelID >= exminmodel) then return exminreal + (iModelID-exminmodel)*65 + iAnimID end -- chimera
	if (iModelID < high) then return iAnimID + iModelID*110 end
	if (iModelID < high + low) then
		return iAnimID + high*110 + (iModelID-high)*65
	end
	return iAnimID + high*110 + low*65 + (iModelID-high-low)*175
end

gGetAnimDataInfoCache = {}
function GetAnimDataInfo (id)
	local o = gGetAnimDataInfoCache[id]
	if (o ~= nil) then return o end
	o = {}
	o.miFrames,o.miUnknown,o.miCount,o.miFrameInterval,o.miFrameStart = gAnimDataLoader:GetAnimDataInfo(id)
	gGetAnimDataInfoCache[id] = o
	return o
end

--- returns pImage,iWidth,iHeight,iCenterX,iCenterY,iFrames
function ExportAnimFrameToImage (iRealID,iFrame,iHue,iLoaderIndex)
	local loader = gAnimLoader[iLoaderIndex or 1]
	if (not loader) then return end
	local pImage = CreateImage()
	local bSuccess,iWidth,iHeight,iCenterX,iCenterY,iFrames = loader:ExportToImage(pImage,iRealID,iFrame,gHueLoader,iHue)
	--~ if (bSuccess) then print("ExportAnimFrameToImage",iLoaderIndex,iRealID,iFrame,gHueLoader,iHue) end
	if (not bSuccess) then pImage:Destroy() return end
	return pImage,iWidth,iHeight,iCenterX,iCenterY,iFrames
end

gAnimFrameBitMaskCache = {}
function GetAnimFrameBitMask (iRealID,iFrame,iLoaderIndex)
	iLoaderIndex = iLoaderIndex or 1
	local n = iRealID..","..iFrame..","..iLoaderIndex
	local o = gAnimFrameBitMaskCache[n]
	if (o ~= nil) then return o end
	local loader = gAnimLoader[iLoaderIndex]
	o = loader and loader:CreateBitMask(iRealID,iFrame)
	gAnimFrameBitMaskCache[n] = o
	return o
end

-- returns iNewModelID,iNewHue,iLoaderIndex
function UOAnimTranslateBodyID (iOrigModelID,iOrigHue)
	local iNewModelID,iNewHue,iLoaderIndex = UOAnimTranslateBodyIDAux(iOrigModelID,iOrigHue)
	if (iLoaderIndex == 5 and iNewModelID == 34) then iNewModelID = 102 end -- chimera
	return iNewModelID,iNewHue,iLoaderIndex
end

function UOAnimTranslateBodyIDAux (iOrigModelID,iOrigHue)
	local iModelID,iHue,iLoaderIndex = iOrigModelID,iOrigHue,1
	local bodyConfDef = gBodyConfDef[iModelID] -- gBodyConfDef[bodyid] = {anim2,anim3,anim4,anim5}
	if (bodyConfDef) then
		for k = 4,1,-1 do if (bodyConfDef[k] > 0) then return bodyConfDef[k],iHue,k+1 end end
	end
	local bodyDef = gBodyDef[iModelID] -- gBodyDef[bodyid] = {newbodylist,newhue}
	if (bodyDef) then 
		local newbodylist,newhue = unpack(bodyDef)
		-- todo : not only first entry in newbodylist ?
		iModelID,iHue = newbodylist[1],newhue -- newbodylist[iLoaderIndex] ?
	end
	return iModelID,iHue,iLoaderIndex
end

function UOAnimCheckBitMask (iModelID,iAnimID,iFrame,iLoaderIndex,px,py)
	local iRealID = Anim_GetRealID(iModelID,iAnimID,iLoaderIndex) 
	local bitmask = GetAnimFrameBitMask(iRealID,iFrame,iLoaderIndex)
	if (not bitmask) then return true end -- no bitmask -> always hit
	return bitmask:TestBit(floor(px),floor(py))
end

function UOAnimTest ()
	local iTranslatedModelID = 309 -- PatchWorkSkeleton
	local iAnimID = 13
	local iFrame = 0
	local iHue = 0
	local iLoaderIndex = 3
	local pAtlasPiece = Anim2DAtlas_LoadAtlasPiece(iTranslatedModelID,iAnimID,iFrame,iHue,iLoaderIndex)
	print("UOAnimTestPatchWorkSkeleton",pAtlasPiece)
	os.exit(0)
end

--[[

TODO : rewrite  cAnim::Decode  :  to not use 2^n width	 and to extract more than one frame ?
	Decode(short* &pBuffer, const int iFrame, _T& filter, short* ColorTable,bool bTexSize=true)  -- use bTexSize=false here


	

class cAnim : public cIndexedRawData     : common baseclass used by all, members : 
		eDataType	miDataType;
		int			miID;
		RawIndex*	mpRawIndex; ///< memory not owned by this class
		char*		mpRawData; 	///< memory not owned by this class
	int	GetWidth () { return mWidth; }
	int	GetHeight () { return mHeight; }
	int GetTexWidth () { return mTexWidth; }
	int GetTexHeight () { return mTexHeight; }
	int GetCenterX () { return mCenterX; }
	int GetCenterY () { return mCenterY; }
	int GetFrames() { return mFrames; }
	... Decode ...
	
cAnimLoader (const int iHighDetailed, const int iLowDetailed) {};
virtual	cAnim*	cAnimLoader::GetAnim	(const int iID)

RawAnimData*		cAnimDataLoader::GetAnimDataType		(const int iID);
		
builder.cpp :
	void	GenerateAnimBitMask		(cAnimLoader& oAnimLoader, const int iID, const int iAnimID, const int iFrame, cBitMask& bitmask);
	bool	GenerateAnimMaterial	(cAnimLoader& oAnimLoader, const char* szMatName,const int iID,const int iAnimID,const int iFrame, int& iWidth, int& iHeight, int& iCenterX, int& iCenterY, int& iFrames, cHueLoader* pHueLoader, short iHue);

		bitmask.SetDataFrom16BitImage(pImgRaw,anim->GetTexWidth(),anim->GetTexHeight());
		
	struct RawAnimData {
		int8 miFrames[64];
		char miUnknown;
		char miCount;
		char miFrameInterval;
		char miFrameStart;
	}  STRUCT_PACKED;
	
	
	if (false and (not gMobileBla)) then
		gMobileBla = true
		for i = 0,0x40000 do
			local iModelID = i
			local iAnimID = 2
			local iFrame = 0
			local iHue = 0
			local iRealID = Anim_GetRealID(iModelID,iAnimID,iLoaderIndex)
			local img,iWidth,iHeight,iCenterX,iCenterY,iFrames = ExportAnimFrameToImage(iRealID,iFrame,iHue)
			if (img) then
				print("exportanim",iModelID)
				--~ img:SaveAsFile(sprintf("../anim5/0x%04x_%d.png",iModelID,iModelID))
				img:Destroy()
			end
		end	
		os.exit(0)
	end
]]--

--[[
-- iAnimID : 0-4=walk down,down-left,left,up-left,up
-- iAnimID : 5-9=walk down (something in hand)
-- iAnimID : 10-14=run
-- iAnimID : 15-19=run (something in hand?)
-- iAnimID : 20-24 idle (1 frame) 
-- iAnimID : 25-29 idle anim? look from left to right
-- iAnimID : 30-24 idle anim? spread arms
-- iAnimID : 35- combat idle
-- iAnimID : 40- combat idle 2hand ?
-- iAnimID : 45- punch/bash anim
-- iAnimID : 50- stab anim
-- iAnimID : 55- punch/bash2 anim
-- iAnimID : 60- punch/bash 2-handed
-- iAnimID : 65- swing 2-handed
-- iAnimID : 70- stab 2-handed ?
-- iAnimID : 75- combat-walk-2-handed
-- iAnimID : 80- cast1
-- iAnimID : 85- cast2
-- iAnimID : 90- fire-bow/crossbow?
-- iAnimID : 95- fire-bow/crossbow?
-- iAnimID : 100- gethit/flinch/pain
-- iAnimID : 105- die backwards
-- iAnimID : 110- die forwards
-- iAnimID : 115- mount-walk
-- iAnimID : 120- mount-run
-- iAnimID : 125- mount-idle
-- iAnimID : 130- mount-attack-swing?
-- iAnimID : 135- mount-attack-bow
-- iAnimID : 140- mount-attack-crossbow
-- iAnimID : 145- mount-attack-bash?
-- iAnimID : 150- attack-stab?
-- iAnimID : 155- attack-punch?
-- iAnimID : 160- bow
-- iAnimID : 165- salute
-- iAnimID : 170- cough/eat/drinkpot?
]]--

