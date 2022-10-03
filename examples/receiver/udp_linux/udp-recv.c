/*
        demo-udp-03: udp-recv: a simple udp server
	receive udp messages

        usage:  udp-recv

        Paul Krzyzanowski

        adapted for Pixie-Net XL readout by W. Hennig
        last modified 8/19/2022
*/


#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <signal.h>
#include <netdb.h>
#include <sys/socket.h>
#include <arpa/inet.h>

#define BUFSIZE 	4096
#define SERVICE_PORT	61002	/* hard-coded port number */


/* monitor data rate
bmon -p 'enp*' -o  format:fmt='$(attr:rxrate:packets) packets/s $(attr:rxrate:bytes) bytes/s\n' | tee logfile.txt
bmon -p enp* -o format:fmt='$(element:name) $(attr:rxrate:bytes) byte/s $(attr:rxrate:packets) packets/s \n'

alternatively save with 
sudo tcpdump udp port 61002 -w LMdata.bin

*/

void sighandler(int sig){

	printf("\nCTRL-C detected, exiting\n");
	exit(1);

}

int
main(int argc, char **argv)
{
	struct sockaddr_in myaddr;	/* our address */
	struct sockaddr_in remaddr;	/* remote address */
	socklen_t addrlen = sizeof(remaddr);		/* length of addresses */
	int recvlen;			/* # bytes received */
	int fd;				/* our socket */
	unsigned char buf[BUFSIZE];	/* receive buffer */

	struct sigaction sigIntHandler;
	sigIntHandler.sa_handler = sighandler;
	sigemptyset(&sigIntHandler.sa_mask);
	sigIntHandler.sa_flags = 0;

	/*  variables for possible 0x400 run type export
   unsigned int ch;
	unsigned int RunType = 0x400;			            // to be read from ini file?	
	unsigned int COINCIDENCE_PATTERN = 0xFFFE;	   // to be read from ini file?
	unsigned int COINCIDENCE_WINDOW = 1000;		   // to be read from ini file?
	unsigned int revsn = 0xA1100003;		            // to be read from HW
	unsigned int TL[NCHANNELS] = {64,64,64,64};	   // to be read from ini file?
	unsigned short buffer1[FILE_HEAD_LENGTH_400] = {0};
*/
   //long CollectedBytes = 0;	
	//long OldBytes = 0;		
   //long MaxRunBytes = 20000000000;		// should be a time
   int k;
  	FILE * fil;

   int pck_count = 0;

 	// Identify version
	printf("UDP receiver utility, compiled for Linux \n");
   printf("Using default port %d, any IP\n", SERVICE_PORT);



	// =================== Socket Setup ===================================

	/* create a UDP socket */

	if ((fd = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
		perror("cannot create socket\n");
		return 0;
	}
   printf("   Socket created.\n");

	/* bind the socket to any valid IP address and a specific port */

	memset((char *)&myaddr, 0, sizeof(myaddr));
	myaddr.sin_family = AF_INET;
	myaddr.sin_addr.s_addr = htonl(INADDR_ANY);
	myaddr.sin_port = htons(SERVICE_PORT);

	if (bind(fd, (struct sockaddr *)&myaddr, sizeof(myaddr)) < 0) {
		perror("bind failed");
		return 0;
	}
   printf("   Bind done"); 


	// ======================== Data File Setup ===========================================


        fil = fopen("LMdata.bin","wb");
	   // no header for P16 0x100 runtype

     	// write a 0x400 header
      // fwrite is slow so we will write to a buffer, and then to the file.
     /* fil = fopen("LMdata.b00","wb");  
	     buffer1[0] = BLOCKSIZE_400;
        buffer1[1] = 0;                          // module number (get from settings file?)
        buffer1[2] = RunType;
        buffer1[3] = CHAN_HEAD_LENGTH_400;
        buffer1[4] = COINCIDENCE_PATTERN;
        buffer1[5] = COINCIDENCE_WINDOW;
        buffer1[7] = revsn>>16;               // HW revision from EEPROM
        buffer1[12] = revsn & 0xFFFF;         // serial number from EEPROM
        for( ch = 0; ch < NCHANNELS; ch++) {
            buffer1[6]   +=(TL[ch] + CHAN_HEAD_LENGTH_400) / BLOCKSIZE_400;         // combined event length, in blocks
            buffer1[8+ch] =(TL[ch] + CHAN_HEAD_LENGTH_400) / BLOCKSIZE_400;		// each channel's event length, in blocks
        }

        fwrite( buffer1, 2, FILE_HEAD_LENGTH_400, fil );     // write to file
*/
	// ======================== Loop, receive from socket, write to file ===========================================
	sigaction(SIGINT, &sigIntHandler, NULL);
   printf("Waiting for data...press CTRL-C to quit\n");
   //while(CollectedBytes < MaxRunBytes)     // run for defined file size
   while(1)
   {
		
		recvlen = recvfrom(fd, buf, BUFSIZE, 0, (struct sockaddr *)&remaddr, &addrlen);
		if (recvlen > 0) {
			//buf[recvlen] = 0;
			//printf("received message: \"%s\"\n", buf);
			
         // print header
			//for(k=0;k<5;k++) {
			//	printf(" 0x %02x%02x %02x%02x   ", buf[8*k+1], buf[8*k+0], buf[8*k+3], buf[8*k+2]);
			//	printf("    %02x%02x %02x%02x \n", buf[8*k+5], buf[8*k+4], buf[8*k+7], buf[8*k+6]);
			//	printf(" 0x %02x%02x %02x%02x   ", buf[8*k+7], buf[8*k+6], buf[8*k+5], buf[8*k+4]);
			//	printf("    %02x%02x %02x%02x \n", buf[8*k+3], buf[8*k+2], buf[8*k+1], buf[8*k+0]);
			//}

			// print trace
   		//	for(k=8*k;k<recvlen/2;k++) {
   		//		printf("%d \n  ", buf[2*k+0]+256*buf[2*k+1]);
   		//	}

         if(pck_count % 10000 == 1)	printf(" Received packet %d \n", pck_count ); 
         // Windows version:  if(pck_count % 10000 == 1)	printf(" Received packet %d from %s:%d\n", pck_count, inet_ntoa(si_other.sin_addr), ntohs(si_other.sin_port));
         pck_count++;

			fwrite( buf, 1, recvlen, fil );     // write to file

         /* count bytes instead of packages
			CollectedBytes = CollectedBytes + recvlen;
			if (CollectedBytes - OldBytes > (1024* 1024) )
			{
				printf("Collected %5.5G MB\n", (float)CollectedBytes/1024/1024);
				OldBytes = CollectedBytes;
			}
         */
		}

	} // end while

	// ======================== Clean up and exit ===========================================
	fclose(fil);
	return(0);

}


