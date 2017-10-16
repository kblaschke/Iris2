--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        Buff/DeBuff System
        --------------------
        http://update.uo.com/design_523.html
        Notes: 
        This is a submitted packet, information here is yet to be verified. Use at own risk. 
        
        buff icon holder: 0x757F or 0x7580 or 0x7581 or 0x7582 
        buff icon holder button: 0x7583,0x7584,0x7585,0x7586
        guild button  - 0x57B2, 0x57B3, 0x57B4
        quests button - 0x57B5, 0x57B6, 0x57B7
        
        gumpid 0x756 and following : buff-bar gumps
        unknown : 0x7555(snakes),0x7556(man,justice-spell?),0x7564(run),0x753A(?)
]]--

--List of current Icon Names:
gBuffIcons = {}
gBuffIcons[1001] = { iGumpID=hex2num("0x754c"), name="Dismount"                 }
gBuffIcons[1002] = { iGumpID=hex2num("0x754a"), name="Disarm"                   }
gBuffIcons[1005] = { iGumpID=hex2num("0x755e"), name="Nightsight"               }
gBuffIcons[1006] = { iGumpID=hex2num("0x7549"), name="Death Strike"             }
gBuffIcons[1007] = { iGumpID=hex2num("0x7551"), name="Evil Omen"                }
gBuffIcons[1008] = { iGumpID=hex2num("0x7556"), name="?"                        }
gBuffIcons[1009] = { iGumpID=hex2num("0x753A"), name="?"                        }
gBuffIcons[1010] = { iGumpID=hex2num("0x754d"), name="Divine Fury"              }
gBuffIcons[1011] = { iGumpID=hex2num("0x754e"), name="Enemy Of One"             }
gBuffIcons[1012] = { iGumpID=hex2num("0x7565"), name="Stealth"                  }
gBuffIcons[1013] = { iGumpID=hex2num("0x753b"), name="Active Meditation"        }
gBuffIcons[1014] = { iGumpID=hex2num("0x7543"), name="Blood Oath caster"        }
gBuffIcons[1015] = { iGumpID=hex2num("0x7544"), name="Blood Oath curse"         }
gBuffIcons[1016] = { iGumpID=hex2num("0x7546"), name="Corpse Skin"              }
gBuffIcons[1017] = { iGumpID=hex2num("0x755c"), name="Mindrot"                  }
gBuffIcons[1018] = { iGumpID=hex2num("0x755f"), name="Pain Spike"               }
gBuffIcons[1019] = { iGumpID=hex2num("0x7566"), name="Strangle"                 }
gBuffIcons[1020] = { iGumpID=hex2num("0x7554"), name="Gift of Renewal"          }
gBuffIcons[1021] = { iGumpID=hex2num("0x7540"), name="Attune Weapon"            }
gBuffIcons[1022] = { iGumpID=hex2num("0x7568"), name="Thunderstorm"             }
gBuffIcons[1023] = { iGumpID=hex2num("0x754f"), name="Essence of Wind"          }
gBuffIcons[1024] = { iGumpID=hex2num("0x7550"), name="Ethereal Voyage"          }
gBuffIcons[1025] = { iGumpID=hex2num("0x7553"), name="Gift Of Life"             }
gBuffIcons[1026] = { iGumpID=hex2num("0x753e"), name="Arcane Empowerment"       }
gBuffIcons[1027] = { iGumpID=hex2num("0x755d"), name="Mortal Strike"            }
gBuffIcons[1028] = { iGumpID=hex2num("0x7563"), name="Reactive Armor"           }
gBuffIcons[1029] = { iGumpID=hex2num("0x7562"), name="Protection"               }
gBuffIcons[1030] = { iGumpID=hex2num("0x753f"), name="Arch Protection"          }
gBuffIcons[1031] = { iGumpID=hex2num("0x7559"), name="Magic Reflection"         }
gBuffIcons[1032] = { iGumpID=hex2num("0x7557"), name="Incognito"                }
gBuffIcons[1033] = { iGumpID=hex2num("0x754b"), name="Disguised"                }
gBuffIcons[1034] = { iGumpID=hex2num("0x753d"), name="Animal Form"              }
gBuffIcons[1035] = { iGumpID=hex2num("0x7561"), name="Polymorph"                }
gBuffIcons[1036] = { iGumpID=hex2num("0x7558"), name="Invisibility"             }
gBuffIcons[1037] = { iGumpID=hex2num("0x755b"), name="Paralyze"                 }
gBuffIcons[1038] = { iGumpID=hex2num("0x7560"), name="Poison"                   }
gBuffIcons[1039] = { iGumpID=hex2num("0x7541"), name="Bleed"                    }
gBuffIcons[1040] = { iGumpID=hex2num("0x7545"), name="Clumsy"                   }
gBuffIcons[1041] = { iGumpID=hex2num("0x7552"), name="Feeble Mind"              }
gBuffIcons[1042] = { iGumpID=hex2num("0x7569"), name="Weaken"                   }
gBuffIcons[1043] = { iGumpID=hex2num("0x7548"), name="Curse"                    }
gBuffIcons[1044] = { iGumpID=hex2num("0x755a"), name="Mass Curse"               }
gBuffIcons[1045] = { iGumpID=hex2num("0x753c"), name="Agility"                  }
gBuffIcons[1046] = { iGumpID=hex2num("0x7547"), name="Cunning"                  }
gBuffIcons[1047] = { iGumpID=hex2num("0x7567"), name="Strength"                 }
gBuffIcons[1048] = { iGumpID=hex2num("0x7542"), name="Bless"                    }

function IsBuffActive_Protection        () return gBuffs[1029] end
function IsBuffActive_EssenceOfWind     () return gBuffs[1023] end

kUnknownBuffGumpID = hex2num("0x7555") -- (snakes)

kBuffStartX = 0
kBuffStartY = 64

gBuffDialog = nil
gBuffWidgetList = {}
gBuffs = {}

function SetBuffActive (buffid,bIsActive) 
    gBuffs[buffid] = bIsActive
end

-- returns widget,w,h
function MakeBuffIconWidget (parent,iGumpID,x,y)
    local hueid = 0
    local mat = GetGumpMat(iGumpID,hueid)
    if ((not mat) or mat == "") then
        print("WARNING ! MakeBuffIconWidget : material load failed for iGumpID=", iGumpID)
        mat = "hudUnknown"
    end

    local w,h = GetGumpSize(iGumpID,hueid)
    if (not w) then return end
    local widget = guimaker.MakePlane(parent,mat,x,y,w,h)
    local tw,th = texsize(w),texsize(h)
    widget.gfx:SetUV(0,0,w/tw,h/th)
    widget.mbIgnoreMouseOver = true
    return widget,w,h
end

function Buffs_RebuildList() 
    -- init dialog if needed
    if (gNoRender) then return end
    if (not gBuffDialog) then 
        --~ BuffTestExportGumps() 
        gBuffDialog = guimaker.MyCreateDialog() 
    end
    for k,widget in pairs(gBuffWidgetList) do widget:Destroy() end gBuffWidgetList = {}
    
    local x = kBuffStartX
    local y = kBuffStartY
    for buffid,bActive in pairs(gBuffs) do
        if (bActive) then 
            local buff = gBuffIcons[buffid]
            local widget,w,h = MakeBuffIconWidget(gBuffDialog,buff and buff.iGumpID or kUnknownBuffGumpID,x,y)
            if (widget) then 
                x = x + w
                table.insert(gBuffWidgetList,widget)
            end
        end
    end
end

-- add : argumentsmode_end=0,argumentsmode_start=0,argumentsmode_startif=0,buff_duration=0,clilocid1=1075655,clilocid2=1075656,icon_buffid1=1012,icon_buffid2=1012,icon_show1=1,icon_show2=1,player_serial=72273,temp1=0,temp2=0,temp3=0,temp4=0,temp5=0,
-- del : icon_buffid1=1012,icon_show1=0,player_serial=72273,temp1=0,
function HandleBuffInfo (buffinfo)
    SetBuffActive(buffinfo.icon_buffid1,buffinfo.icon_show1 == 1)
    Buffs_RebuildList()
end

--[[
-- debug
function BuffTestExportGumps ()
    for iGumpID = hex2num("0x7500"),hex2num("0x75ff") do
        ExportGumpMatTexture(iGumpID,sprintf("../old/mygumps/0x%04x.png",iGumpID))
    end
end

function ExportGumpMatTexture (iGumpID,sFilePath)
    ExportMatTexture(GetGumpMat(iGumpID,0),sFilePath)
end

function ExportMatTexture (sMatName,sFilePath)
    if ((not sMatName) or sMatName == "") then return end
    local sTexName = GetTexture(sMatName)
    print("ExportMatTexture",sMatName,sTexName,sFilePath)
    --~ local texname       GetTexture  (sMatName,iTech=0,iPass=0,iTextureUnit=0)
    local img = LoadImageFromTexture(sTexName)
    img:SaveAsFile(sFilePath)
    img:Destroy()
end
]]--

--~ function TestBuff (buffid,bState) HandleBuffInfo({icon_buffid1=buffid,icon_show1=(bState and 1 or 0)})  end
--~ RegisterListener("keydown", function (key) TestBuff(1012,true)  TestBuff(1014,true) end)
--~ RegisterListener("keyup",   function (key) TestBuff(1012,false) TestBuff(1014,false) end)
