#include <stdio.h>
#include <fcntl.h> /* open() */
#include <string.h>

#include <stdlib.h>

#include <errno.h>

#define ARGS 2
#define FILE_ARG 1
#define BUFFER_SIZE 100
#define TEMP_LEN 5

int main (int argc, char * argv[])
{
	// tempature file
	int tfile = 0;
	// buffer for read of file
	char buffer[BUFFER_SIZE];
	char * ptmp = NULL;
	char temp[TEMP_LEN+1];

	if( argc < ARGS)
	{
		fprintf(stderr, "invalid number of arguments\n");
		return 1;
	}

	// Open file + error chk
	tfile = open(argv[FILE_ARG], O_RDONLY );
	if (tfile < 0)
	{
		fprintf(stderr, "unable to open file\n");
		return 1;
	}
	
	// Read file in
	int bytes_read = read(tfile, buffer, BUFFER_SIZE-1);
	
	buffer[bytes_read] = '\0';

	if (strstr( buffer, "YES") == NULL )
	{
		fprintf(stderr, "Valid Temp not found\n");
		return 1;
	}

	ptmp = strstr(buffer, " t=");
	strncpy(temp, ptmp+3, TEMP_LEN);
	temp[TEMP_LEN] = '\0';

	printf("%s", temp);
	
	//printf("%i\n%s\n", tfile, strerror(errno));
	//printf("%s", buffer);

	return 0; //atoi(temp);
}
