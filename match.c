#include <stdio.h>
#include <inttypes.h>

int main(int argc, char *argv[])
{
	uint32_t pfn = strtol(argv[1], 0, NULL);
	uint32_t phmask = strtol(argv[2], 0, NULL);
	uint32_t phpattern = strtol(argv[3], 0, NULL);
	int match2 = (((phpattern & phmask) & pfn) != 0);
	int match = (~(~(pfn ^ phpattern) | ~phmask) == 0);
	printf("pf=%d (match=%d, match2=%d)\n", pfn, match, match2);
}
