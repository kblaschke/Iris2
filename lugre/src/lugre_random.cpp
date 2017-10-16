#include "lugre_prefix.h"
#include "lugre_random.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef WIN32
#define snprintf _snprintf
#endif

#define RANDOM_FLOAT_PRECISION	0xFFFFFF

unsigned int NextValue(unsigned int last){
	//printf("cRandom::NextValue(%d)\n",last);
	
	while(last < 0xFFFF){
		last = last * last + last + 1;
		//printf("last=%d\n",last);
	}
	
	static char buf[128+1];
	char *p = buf;
	snprintf(buf,128,"%d",last);
	//printf("buf=%s\n",buf);
	int len = strlen(buf);
	p += len / 4;
	*(p + len / 2 + 1) = 0;
	unsigned int v = atoi(p);
	v = v * v;
	//printf("-> %d\n",v);
	return v;
}

namespace Lugre {
	
cRandom::cRandom						(unsigned int seed){
	miSeed = seed;
	miLast = miSeed * miSeed;
}
	
unsigned int 	cRandom::GetInt		(unsigned int max){
	return GetInt(1,max);
}

unsigned int 	cRandom::GetInt		(unsigned int min, unsigned int max){
	miLast = NextValue(miLast);
	return min + (miLast % (max - min + 1));
}

float			cRandom::GetFloat	(){
	return (float)GetInt(0,RANDOM_FLOAT_PRECISION) / (float)RANDOM_FLOAT_PRECISION;
}

};
