gPacketType = {}

gPacketType.kPacket_CharacterCreation 								= { id=0x00, size=104 }
gPacketType.kPacket_Logout					 						= { id=0x01, size=5 }
gPacketType.kPacket_Request_Movement								= { id=0x02, size=7 }
gPacketType.kPacket_Speech											= { id=0x03, size=0 }
gPacketType.kPacket_Request_God_Mode								= { id=0x04, size=2 }
gPacketType.kPacket_Attack											= { id=0x05, size=5 }
gPacketType.kPacket_Double_Click									= { id=0x06, size=5 }
gPacketType.kPacket_Take_Object										= { id=0x07, size=7 }
gPacketType.kPacket_Drop_Object										= { id=0x08, size=14 }
gPacketType.kPacket_Single_Click									= { id=0x09, size=5 }
gPacketType.kPacket_Edit											= { id=0x0A, size=11 }
gPacketType.kPacket_Damage											= { id=0x0B, size=7 }
gPacketType.kPacket_Tile_Data										= { id=0x0C, size=0 }
gPacketType.kPacket_NPC_Data										= { id=0x0D, size=3 }
gPacketType.kPacket_Edit_Template_Data								= { id=0x0E, size=0 }
gPacketType.kPacket_Paperdoll_Old									= { id=0x0F, size=61 }
gPacketType.kPacket_Hue_Data										= { id=0x10, size=215 }
gPacketType.kPacket_Mobile_Stats									= { id=0x11, size=0 }
gPacketType.kPacket_Request_SkillOrSpell							= { id=0x12, size=0 }
gPacketType.kPacket_Equip_Item_Request								= { id=0x13, size=10 }
gPacketType.kPacket_Change_Elevation								= { id=0x14, size=6 }
gPacketType.kPacket_Follow											= { id=0x15, size=9 }
gPacketType.kPacket_Request_Script_Names							= { id=0x16, size=1 }
gPacketType.kPacket_Script_Tree_Command								= { id=0x17, size=0 }
gPacketType.kPacket_Script_Attach									= { id=0x18, size=0 }
gPacketType.kPacket_NPC_Conversation_Data							= { id=0x19, size=0 }
gPacketType.kPacket_Show_Item										= { id=0x1A, size=0 }
gPacketType.kPacket_Login_Confirm									= { id=0x1B, size=37 }
gPacketType.kPacket_Text											= { id=0x1C, size=0 }
gPacketType.kPacket_Destroy											= { id=0x1D, size=5 }
gPacketType.kPacket_Animate											= { id=0x1E, size=4 }
gPacketType.kPacket_Explode											= { id=0x1F, size=8 }

gPacketType.kPacket_Teleport										= { id=0x20, size=19 }
gPacketType.kPacket_Block_Movement									= { id=0x21, size=8 }
gPacketType.kPacket_Accept_Movement_Resync_Request					= { id=0x22, size=3 }
gPacketType.kPacket_Drag_Item										= { id=0x23, size=26 } -- todo : DragEffect?
gPacketType.kPacket_Open_Container									= { id=0x24, size=7 }
gPacketType.kPacket_Object_to_Object								= { id=0x25, size=20 }
gPacketType.kPacket_Old_Client										= { id=0x26, size=5 }
gPacketType.kPacket_Get_Item_Failed									= { id=0x27, size=2 }
gPacketType.kPacket_Drop_Item_Failed								= { id=0x28, size=5 }
gPacketType.kPacket_Drop_Item_OK									= { id=0x29, size=1 }
gPacketType.kPacket_Blood											= { id=0x2A, size=5 }
gPacketType.kPacket_God_Mode										= { id=0x2B, size=2 }
gPacketType.kPacket_Death											= { id=0x2C, size=2 }
gPacketType.kPacket_Health											= { id=0x2D, size=17 }
gPacketType.kPacket_Equip_Item										= { id=0x2E, size=15 }
gPacketType.kPacket_Swing											= { id=0x2F, size=10 }

gPacketType.kPacket_Attack_OK										= { id=0x30, size=5 }
gPacketType.kPacket_Attack_End										= { id=0x31, size=1 }
gPacketType.kPacket_Hack_Mover										= { id=0x32, size=2 }
gPacketType.kPacket_Group											= { id=0x33, size=2 }
gPacketType.kPacket_Client_Query									= { id=0x34, size=10 }
gPacketType.kPacket_Resource_Type									= { id=0x35, size=653 }
gPacketType.kPacket_Resource_Tile_Data								= { id=0x36, size=0 }
gPacketType.kPacket_Move_Object										= { id=0x37, size=8 }
gPacketType.kPacket_Follow_Move										= { id=0x38, size=7 } -- runuo:PathfindMessage
gPacketType.kPacket_Groups											= { id=0x39, size=9 }
gPacketType.kPacket_Skills											= { id=0x3A, size=0 }
gPacketType.kPacket_Accept_Offer									= { id=0x3B, size=0 }
gPacketType.kPacket_Container_Contents								= { id=0x3C, size=0 }
gPacketType.kPacket_Ship											= { id=0x3D, size=2 }
gPacketType.kPacket_Versions										= { id=0x3E, size=37 }
gPacketType.kPacket_Update_Statics									= { id=0x3F, size=0 }

gPacketType.kPacket_Update_Terrain									= { id=0x40, size=201 }
gPacketType.kPacket_Update_Tiledata									= { id=0x41, size=0 }
gPacketType.kPacket_Update_Art										= { id=0x42, size=0 }
gPacketType.kPacket_Update_Anim										= { id=0x43, size=553 }
gPacketType.kPacket_Update_Hues										= { id=0x44, size=713 }
gPacketType.kPacket_Ver_OK											= { id=0x45, size=5 }
gPacketType.kPacket_New_Art											= { id=0x46, size=0 }
gPacketType.kPacket_New_Terrain										= { id=0x47, size=11 }
gPacketType.kPacket_New_Anim										= { id=0x48, size=73 }
gPacketType.kPacket_New_Hues										= { id=0x49, size=93 }
gPacketType.kPacket_Destroy_Art										= { id=0x4A, size=5 }
gPacketType.kPacket_Check_Ver										= { id=0x4B, size=9 }
gPacketType.kPacket_Script_Names									= { id=0x4C, size=0 }
gPacketType.kPacket_Script_File										= { id=0x4D, size=0 }
gPacketType.kPacket_Light_Change									= { id=0x4E, size=6 }
gPacketType.kPacket_Sunlight										= { id=0x4F, size=2 }

gPacketType.kPacket_Board_Header									= { id=0x50, size=0 }
gPacketType.kPacket_Board_Message									= { id=0x51, size=0 }
gPacketType.kPacket_Post_Message									= { id=0x52, size=0 }
gPacketType.kPacket_Login_Reject									= { id=0x53, size=2 }
gPacketType.kPacket_Sound											= { id=0x54, size=12 }
gPacketType.kPacket_Login_Complete									= { id=0x55, size=1 }
gPacketType.kPacket_Map_Command										= { id=0x56, size=11 }
gPacketType.kPacket_Update_Regions									= { id=0x57, size=110 }
gPacketType.kPacket_New_Region										= { id=0x58, size=106 }
gPacketType.kPacket_New_Context_FX									= { id=0x59, size=0 }
gPacketType.kPacket_Update_Context_FX								= { id=0x5A, size=0 }
gPacketType.kPacket_Game_Time										= { id=0x5B, size=4 }
gPacketType.kPacket_Restart_Ver										= { id=0x5C, size=2 }
gPacketType.kPacket_Pre_Login										= { id=0x5D, size=73 }
gPacketType.kPacket_Server_List2									= { id=0x5E, size=0 }
gPacketType.kPacket_Add_Server										= { id=0x5F, size=49 }

gPacketType.kPacket_Server_Remove									= { id=0x60, size=5 }
gPacketType.kPacket_Destroy_Static									= { id=0x61, size=9 }
gPacketType.kPacket_Move_Static										= { id=0x62, size=15 }
gPacketType.kPacket_Area_Load										= { id=0x63, size=13 }
gPacketType.kPacket_Area_Load_Request								= { id=0x64, size=1 }
gPacketType.kPacket_Weather_Change									= { id=0x65, size=4 }
gPacketType.kPacket_Book_Contents									= { id=0x66, size=0 }
gPacketType.kPacket_Simple_Edit										= { id=0x67, size=21 }
gPacketType.kPacket_Script_LS_Attach								= { id=0x68, size=0 }
gPacketType.kPacket_Friends											= { id=0x69, size=0 }
gPacketType.kPacket_Friend_Notify									= { id=0x6A, size=3 }
gPacketType.kPacket_Key_Use											= { id=0x6B, size=9 }
gPacketType.kPacket_Target											= { id=0x6C, size=19 }
gPacketType.kPacket_Music											= { id=0x6D, size=3 }
gPacketType.kPacket_Animation										= { id=0x6E, size=14 }
gPacketType.kPacket_SecureTrade										= { id=0x6F, size=0 }

gPacketType.kPacket_Effect											= { id=0x70, size=28 }
gPacketType.kPacket_Bulletin_Board									= { id=0x71, size=0 }
gPacketType.kPacket_SetPlayerWarmode								= { id=0x72, size=5 }
gPacketType.kPacket_Ping											= { id=0x73, size=2 }
gPacketType.kPacket_Shop_Data										= { id=0x74, size=0 }
gPacketType.kPacket_Rename_MOB										= { id=0x75, size=35 }
gPacketType.kPacket_Server_Change									= { id=0x76, size=16 }
gPacketType.kPacket_Naked_MOB										= { id=0x77, size=17 }
gPacketType.kPacket_Equipped_MOB									= { id=0x78, size=0 }
gPacketType.kPacket_Resource_Query									= { id=0x79, size=9 }
gPacketType.kPacket_Resource_Data									= { id=0x7A, size=0 }
gPacketType.kPacket_Sequence										= { id=0x7B, size=2 }
gPacketType.kPacket_Object_Picker									= { id=0x7C, size=0 }
gPacketType.kPacket_Picked_Object									= { id=0x7D, size=13 }
gPacketType.kPacket_God_View_Query									= { id=0x7E, size=2 }
gPacketType.kPacket_God_View_Data									= { id=0x7F, size=0 }

gPacketType.kPacket_Account_Login_Request							= { id=0x80, size=62 }
gPacketType.kPacket_Account_Login_OK								= { id=0x81, size=0 }
gPacketType.kPacket_Account_Login_Failed							= { id=0x82, size=2 }
gPacketType.kPacket_Account_Delete_Character						= { id=0x83, size=39 }
gPacketType.kPacket_Change_Character_Password						= { id=0x84, size=69 }
gPacketType.kPacket_Delete_Character_Failed							= { id=0x85, size=2 }
gPacketType.kPacket_All_Characters									= { id=0x86, size=0 }
gPacketType.kPacket_Send_Resources									= { id=0x87, size=0 }
gPacketType.kPacket_Open_Paperdoll									= { id=0x88, size=66 }
gPacketType.kPacket_Corpse_Equipment								= { id=0x89, size=0 }
gPacketType.kPacket_Trigger_Edit									= { id=0x8A, size=0 }
gPacketType.kPacket_Display_Sign									= { id=0x8B, size=0 }
gPacketType.kPacket_Server_Redirect									= { id=0x8C, size=11 }
gPacketType.kPacket_KR_CharacterCreation							= { id=0x8D, size=0 }
gPacketType.kPacket_Move_Character									= { id=0x8E, size=0 }
gPacketType.kPacket_Unused4											= { id=0x8F, size=0 }

gPacketType.kPacket_Open_Course_Gump								= { id=0x90, size=19 }
gPacketType.kPacket_Post_Login										= { id=0x91, size=65 }
gPacketType.kPacket_Update_Multi									= { id=0x92, size=0 }
gPacketType.kPacket_Book_Header										= { id=0x93, size=99 }
gPacketType.kPacket_Update_Skill									= { id=0x94, size=0 }
gPacketType.kPacket_Hue_Picker										= { id=0x95, size=9 }
gPacketType.kPacket_Game_Central_Monitor							= { id=0x96, size=0 }
gPacketType.kPacket_Move_Player										= { id=0x97, size=2 }
gPacketType.kPacket_MOB_Name										= { id=0x98, size=0 }
gPacketType.kPacket_Target_Multi									= { id=0x99, size=26 }
gPacketType.kPacket_Text_Entry										= { id=0x9A, size=0 }
gPacketType.kPacket_Request_Assistance								= { id=0x9B, size=258 }
gPacketType.kPacket_Assist_Request									= { id=0x9C, size=309 }
gPacketType.kPacket_GM_Single										= { id=0x9D, size=51 }
gPacketType.kPacket_Shop_Sell										= { id=0x9E, size=0 }
gPacketType.kPacket_Shop_Offer										= { id=0x9F, size=0 }

gPacketType.kPacket_Server_Select									= { id=0xA0, size=3 }
gPacketType.kPacket_HP_Health										= { id=0xA1, size=9 }
gPacketType.kPacket_Mana_Health										= { id=0xA2, size=9 }
gPacketType.kPacket_Stamina											= { id=0xA3, size=9 }
gPacketType.kPacket_Hardware_Info									= { id=0xA4, size=149 }
gPacketType.kPacket_Web_Browser										= { id=0xA5, size=0 }
gPacketType.kPacket_Message											= { id=0xA6, size=0 }	--Tips/Notice window
gPacketType.kPacket_Request_Tip										= { id=0xA7, size=4 }
gPacketType.kPacket_Server_List										= { id=0xA8, size=0 } 
gPacketType.kPacket_Character_List									= { id=0xA9, size=0 }
gPacketType.kPacket_Current_Target									= { id=0xAA, size=5 }
gPacketType.kPacket_String_Query									= { id=0xAB, size=0 }
gPacketType.kPacket_String_Response									= { id=0xAC, size=0 }
gPacketType.kPacket_Speech_Unicode									= { id=0xAD, size=0 }
gPacketType.kPacket_Text_Unicode									= { id=0xAE, size=0 }
gPacketType.kPacket_Death_Animation									= { id=0xAF, size=13 }

gPacketType.kPacket_Generic_Gump									= { id=0xB0, size=0 }
gPacketType.kPacket_Generic_Gump_Trigger							= { id=0xB1, size=0 }
gPacketType.kPacket_Chat_Message									= { id=0xB2, size=0 }
gPacketType.kPacket_Chat_Text										= { id=0xB3, size=0 }
gPacketType.kPacket_Target_Object_List								= { id=0xB4, size=0 }
gPacketType.kPacket_Open_Chat										= { id=0xB5, size=64 }
gPacketType.kPacket_Help_Request									= { id=0xB6, size=9 }
gPacketType.kPacket_Help_Text										= { id=0xB7, size=0 }
gPacketType.kPacket_Character_Profile								= { id=0xB8, size=0 }
gPacketType.kPacket_Features										= { id=0xB9, size=3 }
gPacketType.kPacket_TrackingArrow									= { id=0xBA, size=6 }
gPacketType.kPacket_Account_ID										= { id=0xBB, size=9 }
gPacketType.kPacket_Game_Season										= { id=0xBC, size=3 }
gPacketType.kPacket_Client_Version									= { id=0xBD, size=0 }
gPacketType.kPacket_Assist_Version									= { id=0xBE, size=0 }
gPacketType.kPacket_Generic_Command									= { id=0xBF, size=0 }

gPacketType.kPacket_Hued_FX											= { id=0xC0, size=36 }
gPacketType.kPacket_Localized_Text									= { id=0xC1, size=0 }
gPacketType.kPacket_Unicode_Text_Entry								= { id=0xC2, size=0 }
gPacketType.kPacket_Global_Queue									= { id=0xC3, size=0 }
gPacketType.kPacket_Semivisible										= { id=0xC4, size=6 }
gPacketType.kPacket_Invalid_Map										= { id=0xC5, size=203 }
gPacketType.kPacket_Invalid_Map_Enable								= { id=0xC6, size=1 }
gPacketType.kPacket_Particle_Effect									= { id=0xC7, size=49 }
gPacketType.kPacket_Change_Update_Range								= { id=0xC8, size=2 }
gPacketType.kPacket_Trip_Time										= { id=0xC9, size=6 }
gPacketType.kPacket_UTrip_Time										= { id=0xCA, size=6 }
gPacketType.kPacket_Global_Queue_Count								= { id=0xCB, size=7 }
gPacketType.kPacket_Localized_Text_Plus_String						= { id=0xCC, size=0 }
gPacketType.kPacket_Unknown_God_Packet								= { id=0xCD, size=1 }
gPacketType.kPacket_IGR_Client										= { id=0xCE, size=0 }
gPacketType.kPacket_IGR_Login										= { id=0xCF, size=78 }

gPacketType.kPacket_IGR_Configuration								= { id=0xD0, size=0 }
gPacketType.kPacket_IGR_Logout										= { id=0xD1, size=2 }
gPacketType.kPacket_Update_Mobile									= { id=0xD2, size=25 }
gPacketType.kPacket_Show_Mobile										= { id=0xD3, size=0 }
gPacketType.kPacket_Book_Info										= { id=0xD4, size=0 }
gPacketType.kPacket_Unknown_Client_Packet							= { id=0xD5, size=0 }
gPacketType.kPacket_Mega_Cliloc										= { id=0xD6, size=0 }
gPacketType.kPacket_AOS_Command										= { id=0xD7, size=0 }
gPacketType.kPacket_Custom_House									= { id=0xD8, size=0 }
gPacketType.kPacket_Metrics											= { id=0xD9, size=268 }
gPacketType.kPacket_Mahjong											= { id=0xDA, size=0 }
gPacketType.kPacket_Character_Transfer_Log							= { id=0xDB, size=0 }
gPacketType.kPacket_AOSObjProp										= { id=0xDC, size=9 } -- size was not in necro list
-- dd df (compressed gump und buff system)
gPacketType.kPacket_Compressed_Gump									= { id=0xDD, size=0 }
-- unknown yet
gPacketType.kPacket_unknownDEpacket									= { id=0xDE, size=0 }
-- buff/debuff packet
gPacketType.kPacket_BuffDebuff_System								= { id=0xDF, size=0 }
gPacketType.kPacket_MobStateAnimKR									= { id=0xE2, size=10 } -- http://docs.polserver.com/packets/index.php?Packet=0xE2
gPacketType.kPacket_ExtBundledPacket								= { id=0xF0, size=0 } -- party positions, used by razor positioning system
gPacketType.kPacket_ObjectInfo										= { id=0xF3, size=24 }

gPacketSizeOverride6017 = {[0x25]=21,[0x08]=15,} -- 0x3C is changed as well, but was dynamic anyway
gPacketSizeOverride60142 = {[0xB9]=5,} -- see http://docs.polserver.com/packets/index.php?Packet=0xB9



gPacketSizeByID = {}
for k,v in pairs(gPacketType) do gPacketSizeByID[v.id] = v.size end

gPacketTypeId2Name = {}
for k,v in pairs(gPacketType) do gPacketTypeId2Name[v.id] = k end

-- make names available as global constants, like kPacket_Account_Login_Request, needed for sending
for k,v in pairs(gPacketType) do _G[k] = v.id end 

function InitPackets ()
	if (ClientVersionIsPost6017()) then 
		print("initializing packets for 6.0.1.7 or later")
		for id,newsize in pairs(gPacketSizeOverride6017) do gPacketSizeByID[id] = newsize end
	end
	if (ClientVersionIsPost60142()) then 
		print("initializing packets for 6.0.14.2 or later")
		for id,newsize in pairs(gPacketSizeOverride60142) do gPacketSizeByID[id] = newsize end
	end
	if (gUse16BitZ) then 
		print("InitPackets : gUse16BitZ active")
		local addarr = {
			[kPacket_Server_Change]		= 1, -- 0x76
			[kPacket_Particle_Effect]	= 2, -- 0xC7
			[kPacket_Hued_FX]			= 2, -- 0xC0 
			--~ [kPacket_Login_Confirm]		= 1, -- 0x1B  NOT ADJUSTED ?
			--~ [kPacket_Equipped_MOB]		= 1, -- 0x78 dynamic size!
			[kPacket_Block_Movement]	= 1, -- 0x21 
			[kPacket_Teleport]			= 1, -- 0x20 (not in prev list?)
			--~ [kPacket_Sound]				= 1, -- 0x54	NOT ADJUSTED ?
			[kPacket_Naked_MOB]			= 0, -- 0x77
		}
		if (gUse16BitZ_MobMove) then addarr[kPacket_Naked_MOB] = 1 end
		for id,add in pairs(addarr) do gPacketSizeByID[id] = gPacketSizeByID[id] + add print(" 16bit:",hex(id).."="..gPacketSizeByID[id],gPacketTypeId2Name[id]) end
	end
end
	
-- changed NecroPacketData - (0x0B oldsize="0x010A" , damage packet)
-- packet sizes from necrotoolz.sourceforge.net/kairpacketguide/index.html (0 means dynamic) contains all sizes from 0x00 to 0xDB

--[[
gPacketType.kPacket_								= { id=0xE0 }
gPacketType.kPacket_								= { id=0xE1 }
gPacketType.kPacket_								= { id=0xE2 }
gPacketType.kPacket_								= { id=0xE3 }
gPacketType.kPacket_								= { id=0xE4 }
gPacketType.kPacket_								= { id=0xE5 }
gPacketType.kPacket_								= { id=0xE6 }
gPacketType.kPacket_								= { id=0xE7 }
gPacketType.kPacket_								= { id=0xE8 }
gPacketType.kPacket_								= { id=0xE9 }
gPacketType.kPacket_								= { id=0xEA }
gPacketType.kPacket_								= { id=0xEB }
gPacketType.kPacket_								= { id=0xEC }
gPacketType.kPacket_								= { id=0xED }
gPacketType.kPacket_								= { id=0xEE }
gPacketType.kPacket_								= { id=0xEF }

gPacketType.kPacket_								= { id=0xF1 }
gPacketType.kPacket_								= { id=0xF2 }
0xF3 .. see above
gPacketType.kPacket_								= { id=0xF4 }
gPacketType.kPacket_								= { id=0xF5 }
gPacketType.kPacket_								= { id=0xF6 }
gPacketType.kPacket_								= { id=0xF7 }
gPacketType.kPacket_								= { id=0xF8 }
gPacketType.kPacket_								= { id=0xF9 }
gPacketType.kPacket_								= { id=0xFA }
gPacketType.kPacket_								= { id=0xFB }
gPacketType.kPacket_								= { id=0xFC }
gPacketType.kPacket_								= { id=0xFD }
gPacketType.kPacket_								= { id=0xFE }
gPacketType.kPacket_								= { id=0xFF }
]]--
