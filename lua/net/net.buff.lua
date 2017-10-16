--[[
Buff/DeBuff System
--------------------
http://update.uo.com/design_523.html

Packet Build:
BYTE[1] Cmd					-- 0xDF
BYTE[2] Length 
BYTE[4] Serial of player 

BYTE[2] Icon Number to show 
BYTE[2] 0x1 = Show, 0x0 = Remove. On remove byte, packet ends here. 
BYTE[4] 0x00000000

BYTE[2] Icon Number to show. 
BYTE[2] 0x1 = Show 
BYTE[4] 0x00000000

BYTE[2] Buff Duration in seconds - Time in seconds (simple countdown without automatic remove) 
BYTE[2] 0x0000 
BYTE[1] 0x00 
BYTE[4] Buff Title Cliloc - Cliloc ID of title of icon. 
BYTE[4] Buff Secondary Cliloc - Cliloc ID for the Description of the icon. If no arguments for cliloc, then add 10 more bytes 0x00000000000000000000 and end packet 
BYTE[4] 0x00000000 
BYTE[2] 0x00 01			-Arguments Mode

BYTE[2] 0x00 00			-If (Arguments Mode = 0x01)
BYTE[len(str)*2] Flipped Unicode String (" "+str) (To seperate the entrys add " ") 
BYTE[2] 0x00 01			-EndIf Arguments Mode

BYTE[2] 0x00 00			-EndIf Type


--RUNUO2 code
		public AddBuffPacket( Mobile m, BuffInfo info )
			: this( m, info.ID, info.TitleCliloc, info.SecondaryCliloc, info.Args, (info.TimeStart != DateTime.MinValue) ? ((info.TimeStart + info.TimeLength) - DateTime.Now) : TimeSpan.Zero )
		{
		}
		public AddBuffPacket( Mobile mob, BuffIcon iconID, int titleCliloc, int secondaryCliloc, TextDefinition args, TimeSpan length )
			: base( 0xDF )
		{
			bool hasArgs = (args != null);

			this.EnsureCapacity( (hasArgs ? (48 + args.ToString().Length * 2): 44) );
			m_Stream.Write( (int)mob.Serial );


			m_Stream.Write( (short)iconID );	//ID
			m_Stream.Write( (short)0x1 );	//Type 0 for removal. 1 for add 2 for Data

			m_Stream.Fill( 4 );

			m_Stream.Write( (short)iconID );	//ID
			m_Stream.Write( (short)0x01 );	//Type 0 for removal. 1 for add 2 for Data

			m_Stream.Fill( 4 );

			if( length < TimeSpan.Zero )
				length = TimeSpan.Zero;

			m_Stream.Write( (short)length.TotalSeconds );	//Time in seconds

			m_Stream.Fill( 3 );
			m_Stream.Write( (int)titleCliloc );
			m_Stream.Write( (int)secondaryCliloc );

			if( !hasArgs )
			{
				//m_Stream.Fill( 2 );
				m_Stream.Fill( 10 );
			}
			else
			{
				m_Stream.Fill( 4 );
				m_Stream.Write( (short)0x1 );	//Unknown -> Possibly something saying 'hey, I have more data!'?
				m_Stream.Fill( 2 );

				//m_Stream.WriteLittleUniNull( "\t#1018280" );
				m_Stream.WriteLittleUniNull( String.Format( "\t{0}", args.ToString() ) );

				m_Stream.Write( (short)0x1 );	//Even more Unknown -> Possibly something saying 'hey, I have more data!'?
				m_Stream.Fill( 2 );
			}
		}
	}

	public class RemoveBuffPacket : Packet
	{
		public RemoveBuffPacket( Mobile mob, BuffInfo info )
			: this( mob, info.ID )
		{
		}

		public RemoveBuffPacket( Mobile mob, BuffIcon iconID )
			: base( 0xDF )
		{
			this.EnsureCapacity( 13 );
			m_Stream.Write( (int)mob.Serial );


			m_Stream.Write( (short)iconID );	//ID
			m_Stream.Write( (short)0x0 );	//Type 0 for removal. 1 for add 2 for Data

			m_Stream.Fill( 4 );
		}
	}
]]--

function gPacketHandler.kPacket_BuffDebuff_System()
	local buffinfos = {}
	local input = GetRecvFIFO()
	local popped_start = input:GetTotalPopped()
	local id = input:PopNetUint8()
	local packetsize = input:PopNetUint16()

	--print("spell buff packet received !!!!!!!!!!",packetsize)
	buffinfos.player_serial	= input:PopNetUint32()

	buffinfos.icon_buffid1		= input:PopNetUint16()
	buffinfos.icon_show1		= input:PopNetUint16() -- runuo : 0x1 //Type 0 for removal. 1 for add 2 for Data
	
	local rest = packetsize - (input:GetTotalPopped() - popped_start)
	if (rest < 4) then print("WARNING: kPacket_BuffDebuff_System underrun while reading temp1") return end
		
	buffinfos.temp1			= input:PopNetUint32()

	local rest = packetsize - (input:GetTotalPopped() - popped_start)
	if (packetsize > 15 and rest >= 2+2+4+2+2+1+4+4+4+2+2) then
		buffinfos.icon_buffid2		= input:PopNetUint16() -- same as above
		buffinfos.icon_show2		= input:PopNetUint16() -- runuo : 0x1 //Type 0 for removal. 1 for add 2 for Data, same as above
		buffinfos.temp2			= input:PopNetUint32()
	
		buffinfos.buff_duration	= input:PopNetUint16()	--Time in seconds
	
		buffinfos.temp3			= input:PopNetUint16()
		buffinfos.temp4			= input:PopNetUint8()
	
		buffinfos.clilocid1		= input:PopNetUint32()	--titleCliloc
		buffinfos.clilocid2		= input:PopNetUint32()	--secondaryCliloc
	
		-- runuo : if (!hasargs) { fill(10) } else { fill(4),short(0x1),fill(2),unicodestring(),short(0x1),fill(2) }
		buffinfos.temp5			= input:PopNetUint32()
	
		buffinfos.argumentsmode_start	= input:PopNetUint16()	-- if 1 -> i have more data
	
		buffinfos.argumentsmode_startif	= input:PopNetUint16()
	
		if (buffinfos.argumentsmode_start == 1) then
	
			local argument_string = ""
			local argument_char
			repeat
				local rest = packetsize - (input:GetTotalPopped() - popped_start)
				if (rest <= 0) then print("WARNING: kPacket_BuffDebuff_System underrun while reading argument_string") break end
				argument_char	= input:PopNetUint8()
				argument_string = argument_string .. argument_char
				--print(argument_char)
			until (argument_char == 1)
			
			--print(argument_string)
		end
	
		local rest = packetsize - (input:GetTotalPopped() - popped_start)
		if (rest < 2) then print("WARNING: kPacket_BuffDebuff_System underrun while reading argumentsmode_end") end
		print("DEBUG kPacket_BuffDebuff_System",packetsize,rest,input:GetTotalPopped(),popped_start)
		buffinfos.argumentsmode_end		= (rest >= 2) and (input:PopNetUint16()) or 0
	end
	
	--print(vardump2(buffinfos))
	HandleBuffInfo(buffinfos)
end

--[[

example output of dump : 
argumentsmode_end=0
argumentsmode_start=0
argumentsmode_startif=0
buff_duration=0
clilocid1=1075655   gClilocLoader:Get(text_messagenum)
clilocid2=1075656   gClilocLoader:Get(text_messagenum)
icon_buffid1=1012
icon_buffid2=1012
icon_show1=1
icon_show2=1
player_serial=141163
temp1=0
temp2=0
temp3=0
temp4=0
temp5=0

]]--

