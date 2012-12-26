#include <stdio.h>
#include <inttypes.h>

int main(int argc, char *argv[])
{
	uint32_t pfn = strtol(argv[1], 0, NULL);
	uint32_t phmask = strtol(argv[2], 0, NULL);
	uint32_t phpattern = strtol(argv[3], 0, NULL);
	int ncolor = strtol(argv[4], 0, NULL);
	int match = (~(~(pfn ^ phpattern) | ~phmask) == 0);
	printf("pf=0x%x(%d) mask=0x%x patt=0x%x (color=%d, match=%d)\n", 
	       pfn, pfn, phmask, phpattern,
	       pfn % ncolor, match);
}
