// huffman de-/compression
// decompression alg taken from old iris1 source
// compression alg taken from runuo2 code (Network/Compression.cs)

#include "lugre_prefix.h"
#include "lugre_fifo.h"
#include "huffman.h"

using namespace Lugre;

// ***** ***** ***** ***** *****  Summary


void	HuffmanCompress			(cFIFO *pInFifo, cFIFO *pOutFifo);
void	HuffmanDecompress		(cFIFO *pInFifo, cFIFO *pOutFifo);
bool	HuffmanDecompressOne	(cFIFO *pInFifo, cFIFO *pOutFifo);


// ***** ***** ***** ***** *****  DECOMPRESSION

/*
    Decompression Table
    This is a static huffman tree that is walked down for decompression,
    negative nodes (and 0) are final values,
    positive nodes point to other nodes.
    If drawn this tree is sorted from up to down (layer by layer)
    and left to right.
*/
const short HuffmanDecompressingTree[] =
{
    /*   0*/     1, 2,
    /*   1*/     3, 4,
    /*   2*/     5, 0,
    /*   3*/     6, 7,
    /*   4*/     8, 9,
    /*   5*/    10,   11,
    /*   6*/    12,   13,
    /*   7*/  -256,   14,
    /*   8*/    15,   16,
    /*   9*/    17,   18,
    /*  10*/    19,   20,
    /*  11*/    21,   22,
    /*  12*/    -1,   23,
    /*  13*/    24,   25,
    /*  14*/    26,   27,
    /*  15*/    28,   29,
    /*  16*/    30,   31,
    /*  17*/    32,   33,
    /*  18*/    34,   35,
    /*  19*/    36,   37,
    /*  20*/    38,   39,
    /*  21*/    40,  -64,
    /*  22*/    41,   42,
    /*  23*/    43,   44,
    /*  24*/    -6,   45,
    /*  25*/    46,   47,
    /*  26*/    48,   49,
    /*  27*/    50,   51,
    /*  28*/  -119,   52,
    /*  29*/   -32,   53,
    /*  30*/    54,  -14,
    /*  31*/    55,   -5,
    /*  32*/    56,   57,
    /*  33*/    58,   59,
    /*  34*/    60,   -2,
    /*  35*/    61,   62,
    /*  36*/    63,   64,
    /*  37*/    65,   66,
    /*  38*/    67,   68,
    /*  39*/    69,   70,
    /*  40*/    71,   72,
    /*  41*/   -51,   73,
    /*  42*/    74,   75,
    /*  43*/    76,   77,
    /*  44*/  -101, -111,
    /*  45*/    -4,  -97,
    /*  46*/    78,   79,
    /*  47*/  -110,   80,
    /*  48*/    81, -116,
    /*  49*/    82,   83,
    /*  50*/    84, -255,
    /*  51*/    85,   86,
    /*  52*/    87,   88,
    /*  53*/    89,   90,
    /*  54*/   -15,  -10,
    /*  55*/    91,   92,
    /*  56*/   -21,   93,
    /*  57*/  -117,   94,
    /*  58*/    95,   96,
    /*  59*/    97,   98,
    /*  60*/    99,  100,
    /*  61*/  -114,  101,
    /*  62*/  -105,  102,
    /*  63*/   -26,  103,
    /*  64*/   104,  105,
    /*  65*/   106,  107,
    /*  66*/   108,  109,
    /*  67*/   110,  111,
    /*  68*/   112,   -3,
    /*  69*/   113,   -7,
    /*  70*/   114, -131,
    /*  71*/   115, -144,
    /*  72*/   116,  117,
    /*  73*/   -20,  118,
    /*  74*/   119,  120,
    /*  75*/   121,  122,
    /*  76*/   123,  124,
    /*  77*/   125,  126,
    /*  78*/   127,  128,
    /*  79*/   129, -100 ,
    /*  80*/   130,   -8,
    /*  81*/   131,  132,
    /*  82*/   133,  134,
    /*  83*/  -120,  135,
    /*  84*/   136,  -31,
    /*  85*/   137,  138,
    /*  86*/  -109, -234,
    /*  87*/   139,  140,
    /*  88*/   141,  142,
    /*  89*/   143,  144,
    /*  90*/  -112,  145,
    /*  91*/   -19,  146,
    /*  92*/   147,  148,
    /*  93*/   149,  -66,
    /*  94*/   150, -145,
    /*  95*/   -13,  -65,
    /*  96*/   151,  152,
    /*  97*/   153,  154,
    /*  98*/   -30,  155,
    /*  99*/   156,  157,
    /* 100*/   -99,  158,
    /* 101*/   159,  160,
    /* 102*/   161,  162,
    /* 103*/   -23,  163,
    /* 104*/   -29,  164,
    /* 105*/   -11,  165,
    /* 106*/   166, -115,
    /* 107*/   167,  168,
    /* 108*/   169,  170,
    /* 109*/   -16,  171,
    /* 110*/   -34,  172,
    /* 111*/   173, -132,
    /* 112*/   174, -108,
    /* 113*/   175,  -22,
    /* 114*/   176,   -9,
    /* 115*/   177,  -84,
    /* 116*/   -17,  -37,
    /* 117*/   -28,  178,
    /* 118*/   179,  180,
    /* 119*/   181,  182,
    /* 120*/   183,  184,
    /* 121*/   185,  186,
    /* 122*/   187, -104,
    /* 123*/   188,  -78,
    /* 124*/   189,  -61,
    /* 125*/   -79, -178,
    /* 126*/   -59, -134,
    /* 127*/   190,  -25,
    /* 128*/   -83,  -18,
    /* 129*/   191,  -57,
    /* 130*/   -67,  192,
    /* 131*/   -98,  193,
    /* 132*/   -12,  -68,
    /* 133*/   194,  195,
    /* 134*/   -55, -128,
    /* 135*/   -24,  -50,
    /* 136*/   -70,  196,
    /* 137*/   -94,  -33,
    /* 138*/   197, -129,
    /* 139*/   -74,  198,
    /* 140*/   -82,  199,
    /* 141*/   -56,  -87,
    /* 142*/   -44,  200,
    /* 143*/  -248,  201,
    /* 144*/  -163,  -81,
    /* 145*/   -52, -123,
    /* 146*/   202, -113,
    /* 147*/   -48,  -41,
    /* 148*/  -122,  -40,
    /* 149*/   203,  -90,
    /* 150*/   -54,  204,
    /* 151*/   -86, -192,
    /* 152*/   205,  206,
    /* 153*/   207, -130,
    /* 154*/   -53,  208,
    /* 155*/  -133,  -45,
    /* 156*/   209,  210,
    /* 157*/   211,  -91,
    /* 158*/   212,  213,
    /* 159*/  -106,  -88,
    /* 160*/   214,  215,
    /* 161*/   216,  217,
    /* 162*/   218,  -49,
    /* 163*/   219,  220,
    /* 164*/   221,  222,
    /* 165*/   223,  224,
    /* 166*/   225,  226,
    /* 167*/   227, -102,
    /* 168*/  -160,  228,
    /* 169*/   -46,  229,
    /* 170*/  -127,  230,
    /* 171*/  -103,  231,
    /* 172*/   232,  233,
    /* 173*/   -60,  234,
    /* 174*/   235,  -76,
    /* 175*/   236, -121,
    /* 176*/   237,  -73,
    /* 177*/  -149,  238,
    /* 178*/   239, -107,
    /* 179*/   -35,  240,
    /* 180*/   -71,  -27,
    /* 181*/   -69,  241,
    /* 182*/   -89,  -77,
    /* 183*/   -62, -118,
    /* 184*/   -75,  -85,
    /* 185*/   -72,  -58,
    /* 186*/   -63,  -80,
    /* 187*/   242,  -42,
    /* 188*/  -150, -157,
    /* 189*/  -139, -236,
    /* 190*/  -126, -243,
    /* 191*/  -142, -214,
    /* 192*/  -138, -206,
    /* 193*/  -240, -146,
    /* 194*/  -204, -147,
    /* 195*/  -152, -201,
    /* 196*/  -227, -207,
    /* 197*/  -154, -209,
    /* 198*/  -153, -254,
    /* 199*/  -176, -156,
    /* 200*/  -165, -210,
    /* 201*/  -172, -185,
    /* 202*/  -195, -170,
    /* 203*/  -232, -211,
    /* 204*/  -219, -239,
    /* 205*/  -200, -177,
    /* 206*/  -175, -212,
    /* 207*/  -244, -143,
    /* 208*/  -246, -171,
    /* 209*/  -203, -221,
    /* 210*/  -202, -181,
    /* 211*/  -173, -250,
    /* 212*/  -184, -164,
    /* 213*/  -193, -218,
    /* 214*/  -199, -220,
    /* 215*/  -190, -249,
    /* 216*/  -230, -217,
    /* 217*/  -169, -216,
    /* 218*/  -191, -197,
    /* 219*/   -47,  243,
    /* 220*/   244,  245,
    /* 221*/   246,  247,
    /* 222*/  -148, -159,
    /* 223*/   248,  249,
    /* 224*/   -92,  -93,
    /* 225*/   -96, -225,
    /* 226*/  -151,  -95,
    /* 227*/   250,  251,
    /* 228*/  -241,  252,
    /* 229*/  -161,  -36,
    /* 230*/   253,  254,
    /* 231*/  -135,  -39,
    /* 232*/  -187, -124,
    /* 233*/   255, -251,
    /* 234*/  -162, -238,
    /* 235*/  -242,  -38,
    /* 236*/   -43, -125,
    /* 237*/  -215, -253,
    /* 238*/  -140, -208,
    /* 239*/  -137, -235,
    /* 240*/  -158, -237,
    /* 241*/  -136, -205,
    /* 242*/  -155, -141,
    /* 243*/  -228, -229,
    /* 244*/  -213, -168,
    /* 245*/  -224, -194,
    /* 246*/  -196, -226,
    /* 247*/  -183, -233,
    /* 248*/  -231, -167,
    /* 249*/  -174, -189,
    /* 250*/  -252, -166,
    /* 251*/  -198, -222,
    /* 252*/  -188, -179,
    /* 253*/  -223, -182,
    /* 254*/  -180, -186,
    /* 255*/  -245, -247,
};


/// decompresses until no more complete packets are left (half packets might remain)
/// pops (reads+removes complete packets) from in and pushes (writes complete packets) onto out
void	HuffmanDecompress	(cFIFO *pInFifo, cFIFO *pOutFifo) {
	while (HuffmanDecompressOne(pInFifo,pOutFifo)) ;
}

/// returns true if packet was complete
/// pops (reads+removes) data out of infifo if and only if packet is complete
/// pushes (writes) data into outfifo if and only if packet is complete  (implemented via rollback on incomplete packet end)
/// reads no more than 1 packet
bool	HuffmanDecompressOne	(cFIFO *pInFifo, cFIFO *pOutFifo) {
	assert(pInFifo && "HuffmanDecompress : pInFifo missing");
	assert(pOutFifo && "HuffmanDecompress : pOutFifo missing");
	if (pInFifo->size() == 0) return false; // nothing to do
		
    int bit_num = 8;
    int treepos = 0;
	int value = 0;
	int mask = 0;
	
    const unsigned char * psrc = (const unsigned char *)pInFifo->HackGetRawReader();//reinterpret_cast<const unsigned char *>(src);
    int len = pInFifo->size();//src_size; // len will decrease
    //int dest_index = 0;
	
	// char *rw = mpInBuffer->HackGetRawWriter(kConMinRecvSpace);
	// int fs = mpInBuffer->HackGetFreeSpace();
	
	// prepare rollback
	int iOutSizeBefore = pOutFifo->size();

    while ( true ) {
        if(bit_num == 8)
        {
            // End of input.
            if(len == 0)
            {
                //dest_size = dest_index;
                // src_size is unchanged
				// if (treepos != 0) { printf("FATAL ! decompression error\n"); exit(42); }
				
				// rollback
				// remove pushed bytes from out
				pOutFifo->HackSubLength(pOutFifo->size() - iOutSizeBefore);
				
				return false;
            }
            len--;
            value = *psrc++;
            bit_num = 0;
            mask = 0x80;
        }
        if(value & mask)
            treepos = HuffmanDecompressingTree[treepos * 2];
        else
            treepos = HuffmanDecompressingTree[treepos * 2 + 1];
        mask >>= 1; // shift on reck
        bit_num++;

        if(treepos <= 0) // this is a leaf.
        {
            if(treepos == -256) // special flush character, marks end of packet
            {
                bit_num = 8; // flush rest of byte
                treepos = 0; // start on tree top again
				
				// commit here, marks end of one uo packet
				pInFifo->PopRaw(pInFifo->size() - len);
				
                return true;
            }
            pOutFifo->PushUint8(-treepos);   // data is negative value
            treepos = 0;      // start on tree top again
        }
    }
}


// ***** ***** ***** ***** *****  COMPRESSION


// compiler directives so we need as little change to the runuo2 source as possible (avoid errors)
typedef unsigned char  byte;

#define null 0
#define m_OutputBufferLength 0x40000
byte m_OutputBuffer[m_OutputBufferLength];
#define out 
#define fixed(code) code;
#define lock(ignored) 

// huffman tree from runuo2, only needed by HuffmanCompress
int m_Table[] = {
	0x2, 0x000,	0x5, 0x01F,	0x6, 0x022,	0x7, 0x034,	0x7, 0x075,	0x6, 0x028,	0x6, 0x03B,	0x7, 0x032,
	0x8, 0x0E0,	0x8, 0x062,	0x7, 0x056,	0x8, 0x079,	0x9, 0x19D,	0x8, 0x097,	0x6, 0x02A,	0x7, 0x057,
	0x8, 0x071,	0x8, 0x05B,	0x9, 0x1CC,	0x8, 0x0A7,	0x7, 0x025,	0x7, 0x04F,	0x8, 0x066,	0x8, 0x07D,
	0x9, 0x191,	0x9, 0x1CE,	0x7, 0x03F,	0x9, 0x090,	0x8, 0x059,	0x8, 0x07B,	0x8, 0x091,	0x8, 0x0C6,
	0x6, 0x02D,	0x9, 0x186,	0x8, 0x06F,	0x9, 0x093,	0xA, 0x1CC,	0x8, 0x05A,	0xA, 0x1AE,	0xA, 0x1C0,
	0x9, 0x148,	0x9, 0x14A,	0x9, 0x082,	0xA, 0x19F,	0x9, 0x171,	0x9, 0x120,	0x9, 0x0E7,	0xA, 0x1F3,
	0x9, 0x14B,	0x9, 0x100,	0x9, 0x190,	0x6, 0x013,	0x9, 0x161,	0x9, 0x125,	0x9, 0x133,	0x9, 0x195,
	0x9, 0x173,	0x9, 0x1CA,	0x9, 0x086,	0x9, 0x1E9,	0x9, 0x0DB,	0x9, 0x1EC,	0x9, 0x08B,	0x9, 0x085,
	
	0x5, 0x00A,	0x8, 0x096,	0x8, 0x09C,	0x9, 0x1C3,	0x9, 0x19C,	0x9, 0x08F,	0x9, 0x18F,	0x9, 0x091,
	0x9, 0x087,	0x9, 0x0C6,	0x9, 0x177,	0x9, 0x089,	0x9, 0x0D6,	0x9, 0x08C,	0x9, 0x1EE,	0x9, 0x1EB,
	0x9, 0x084,	0x9, 0x164,	0x9, 0x175,	0x9, 0x1CD,	0x8, 0x05E,	0x9, 0x088,	0x9, 0x12B,	0x9, 0x172,
	0x9, 0x10A,	0x9, 0x08D,	0x9, 0x13A,	0x9, 0x11C,	0xA, 0x1E1,	0xA, 0x1E0,	0x9, 0x187,	0xA, 0x1DC,
	0xA, 0x1DF,	0x7, 0x074,	0x9, 0x19F,	0x8, 0x08D,	0x8, 0x0E4,	0x7, 0x079,	0x9, 0x0EA,	0x9, 0x0E1,
	0x8, 0x040,	0x7, 0x041,	0x9, 0x10B,	0x9, 0x0B0,	0x8, 0x06A,	0x8, 0x0C1,	0x7, 0x071,	0x7, 0x078,
	0x8, 0x0B1,	0x9, 0x14C,	0x7, 0x043,	0x8, 0x076,	0x7, 0x066,	0x7, 0x04D,	0x9, 0x08A,	0x6, 0x02F,
	0x8, 0x0C9,	0x9, 0x0CE,	0x9, 0x149,	0x9, 0x160,	0xA, 0x1BA,	0xA, 0x19E,	0xA, 0x39F,	0x9, 0x0E5,
	0x9, 0x194,	0x9, 0x184,	0x9, 0x126,	0x7, 0x030,	0x8, 0x06C,	0x9, 0x121,	0x9, 0x1E8,	0xA, 0x1C1,
	
	0xA, 0x11D,	0xA, 0x163,	0xA, 0x385,	0xA, 0x3DB,	0xA, 0x17D,	0xA, 0x106,	0xA, 0x397,	0xA, 0x24E,
	0x7, 0x02E,	0x8, 0x098,	0xA, 0x33C,	0xA, 0x32E,	0xA, 0x1E9,	0x9, 0x0BF,	0xA, 0x3DF,	0xA, 0x1DD,
	0xA, 0x32D,	0xA, 0x2ED,	0xA, 0x30B,	0xA, 0x107,	0xA, 0x2E8,	0xA, 0x3DE,	0xA, 0x125,	0xA, 0x1E8,
	0x9, 0x0E9,	0xA, 0x1CD,	0xA, 0x1B5,	0x9, 0x165,	0xA, 0x232,	0xA, 0x2E1,	0xB, 0x3AE,	0xB, 0x3C6,
	0xB, 0x3E2,	0xA, 0x205,	0xA, 0x29A,	0xA, 0x248,	0xA, 0x2CD,	0xA, 0x23B,	0xB, 0x3C5,	0xA, 0x251,
	0xA, 0x2E9,	0xA, 0x252,	0x9, 0x1EA,	0xB, 0x3A0,	0xB, 0x391,	0xA, 0x23C,	0xB, 0x392,	0xB, 0x3D5,
	0xA, 0x233,	0xA, 0x2CC,	0xB, 0x390,	0xA, 0x1BB,	0xB, 0x3A1,	0xB, 0x3C4,	0xA, 0x211,	0xA, 0x203,
	0x9, 0x12A,	0xA, 0x231,	0xB, 0x3E0,	0xA, 0x29B,	0xB, 0x3D7,	0xA, 0x202,	0xB, 0x3AD,	0xA, 0x213,
	
	0xA, 0x253,	0xA, 0x32C,	0xA, 0x23D,	0xA, 0x23F,	0xA, 0x32F,	0xA, 0x11C,	0xA, 0x384,	0xA, 0x31C,
	0xA, 0x17C,	0xA, 0x30A,	0xA, 0x2E0,	0xA, 0x276,	0xA, 0x250,	0xB, 0x3E3,	0xA, 0x396,	0xA, 0x18F,
	0xA, 0x204,	0xA, 0x206,	0xA, 0x230,	0xA, 0x265,	0xA, 0x212,	0xA, 0x23E,	0xB, 0x3AC,	0xB, 0x393,
	0xB, 0x3E1,	0xA, 0x1DE,	0xB, 0x3D6,	0xA, 0x31D,	0xB, 0x3E5,	0xB, 0x3E4,	0xA, 0x207,	0xB, 0x3C7,
	0xA, 0x277,	0xB, 0x3D4,	0x8, 0x0C0,	0xA, 0x162,	0xA, 0x3DA,	0xA, 0x124,	0xA, 0x1B4,	0xA, 0x264,
	0xA, 0x33D,	0xA, 0x1D1,	0xA, 0x1AF,	0xA, 0x39E,	0xA, 0x24F,	0xB, 0x373,	0xA, 0x249,	0xB, 0x372,
	0x9, 0x167,	0xA, 0x210,	0xA, 0x23A,	0xA, 0x1B8,	0xB, 0x3AF,	0xA, 0x18E,	0xA, 0x2EC,	0x7, 0x062,
	
	0x4, 0x00D  // 0x200 and 0x201
};



// compress routine from runuo2, almost exactly copyed
// only needed for testing decompression
void HuffmanCompress ( byte* input, int length, out byte* &output, out int &outputLength )
		{
			if ( length >= m_OutputBufferLength )
			{
				output = null;
				outputLength = length;
				return;
			}

			lock ( m_SyncRoot )
			{
				int holdCount = 0;
				int holdValue = 0;

				int packCount = 0;
				int packValue = 0;

				int byteValue = 0;

				int inputLength = length;
				int inputIndex = 0;

				int outputCount = 0;

				fixed ( int *pTable = m_Table )
				{
					fixed ( byte *pOutputBuffer = m_OutputBuffer )
					{
						while ( inputIndex < inputLength )
						{
							byteValue = input[inputIndex++] << 1;

							packCount = pTable[byteValue];
							packValue = pTable[byteValue | 1];

							holdValue <<= packCount;
							holdValue  |= packValue;
							holdCount  += packCount;

							while ( holdCount >= 8 )
							{
								holdCount -= 8;

								pOutputBuffer[outputCount++] = (byte)(holdValue >> holdCount);
							}
						}

						packCount = pTable[0x200];
						packValue = pTable[0x201];

						holdValue <<= packCount;
						holdValue  |= packValue;
						holdCount  += packCount;

						while ( holdCount >= 8 )
						{
							holdCount -= 8;

							pOutputBuffer[outputCount++] = (byte)(holdValue >> holdCount);
						}

						if ( holdCount > 0 )
							pOutputBuffer[outputCount++] = (byte)(holdValue << (8 - holdCount));
					}
				}

				output = m_OutputBuffer;
				outputLength = outputCount;
			}
		}

void	HuffmanCompress (cFIFO *pInFifo, cFIFO *pOutFifo) {
	byte* 	input = (byte*)pInFifo->HackGetRawReader();
	int 	length = pInFifo->size();
	byte*	output = 0;
	int		outputLength = 0;
	HuffmanCompress(input,length,output,outputLength);
	pOutFifo->PushRaw((char*)output,outputLength);
}
