/*
	Simple UDP Server
   adapted from https://www.binarytides.com/udp-socket-programming-in-winsock/
   last modified 8/19/2022
*/

#include<stdio.h>
#include<winsock2.h>
#include<signal.h>

#pragma comment(lib,"ws2_32.lib") //Winsock Library

#define BUFLEN 4096			// Max length of buffer in bytes (packets limited to ~1500)
#define PORT 61002			// The port on which to listen for incoming data

void sighandler(int sig){

	printf("\nCTRL-C detected, exiting\n");
	exit(1);

}

int main(int argc, char* argv[])
{
	SOCKET s;
	struct sockaddr_in server, si_other;
	int slen , recv_len;
	char buf[BUFLEN];
	WSADATA wsa;
	FILE * fil;

	int iResult = 0;
	int iOptVal = 0;
	int iOptLen = sizeof(int);
	int pck_count =0;
	unsigned short userport = PORT;
	int seg_count = 0;
	int misseg_count = 0;
	int debug_count = 0;
	int maxmsg = 20;
	int extra, Nextra, tracesegment;
	unsigned int runtype;
	unsigned int HDRLEN_410 = 62;	// Event header in bytes
	unsigned int zeros[BUFLEN] = { 0 };


	slen = sizeof(si_other) ;

	// Identify version
	printf("UDP receiver utility, compiled for Windows 10, 32 bit, 1/2024\n");

	if (argc < 3) 
	{
		printf("Using default port %d, any IP\n", userport);
	}
	else 
	{
		userport = (unsigned short)strtol(argv[1], NULL, 0);  //atoi(argv[1]);
		printf("Using port %d, IP %s\n", userport, argv[2]);
	}
	
	
	//Initialise winsock
	printf("   Initialising Winsock...");
	if (WSAStartup(MAKEWORD(2,2),&wsa) != 0)
	{
		printf("Failed. Error Code : %d",WSAGetLastError());
		exit(EXIT_FAILURE);
	}
	printf("Initialised.\n");
	
	//Create a socket
	if((s = socket(AF_INET , SOCK_DGRAM , 0 )) == INVALID_SOCKET)
	{
		printf("Could not create socket : %d" , WSAGetLastError());
	}
	printf("   Socket created.\n");
	
	//Prepare the sockaddr_in structure
	server.sin_family = AF_INET;
	if (argc < 3) {
		server.sin_addr.s_addr = INADDR_ANY; //inet_addr(argv[2]);
	}
	else {
		server.sin_addr.s_addr = inet_addr(argv[2]);
	}
	server.sin_port = htons(userport); // htons(PORT);
	
	//Bind
	if( bind(s ,(struct sockaddr *)&server , sizeof(server)) == SOCKET_ERROR)
	{
		printf("Bind failed with error code : %d" , WSAGetLastError());
		exit(EXIT_FAILURE);
	}
	puts("   Bind done"); 

	iResult = getsockopt(s, SOL_SOCKET, SO_RCVBUF, (char*)&iOptVal, &iOptLen);
	if (iResult == SOCKET_ERROR) 
	{
		wprintf(L"getsockopt for SO_RCVBUF failed with error: %u\n", WSAGetLastError());
	}
	else
	{
		wprintf(L"   SO_RCVBUF Value: %ld\n", iOptVal);
	}


	int a = 10000000;
	if (setsockopt(s, SOL_SOCKET, SO_RCVBUF, &a, sizeof(int)) == -1) 
	{
		fprintf(stderr, "Error setting socket opts: %s\n", strerror(errno));
	}

	iResult = getsockopt(s, SOL_SOCKET, SO_RCVBUF, (char*)&iOptVal, &iOptLen);
	if (iResult == SOCKET_ERROR) 
	{
		wprintf(L"getsockopt for SO_RCVBUF failed with error: %u\n", WSAGetLastError());
	}
	else
	{
		wprintf(L"   SO_RCVBUF Value: %ld\n", iOptVal);
	}


	//clear the buffer by filling null, it might have previously received data
	memset(buf,'\0;', BUFLEN);

	// open destination LM file
    fil = fopen("LMdata.bin","wb");

	signal(SIGINT, sighandler);
	printf("Waiting for data...press CTRL-C to quit\n");

	//keep listening for data
	while(1)
	{
		//printf("Waiting for data...");
		fflush(stdout);
		
		//try to receive some data, this is a blocking call
		// i.e. it waits in the if condition until data ready
		if ((recv_len = recvfrom(s, buf, BUFLEN, 0, (struct sockaddr *) &si_other, &slen)) == SOCKET_ERROR)
		{
			printf("recvfrom() failed with error code : %d" , WSAGetLastError());
			exit(EXIT_FAILURE);
		}
		
		//print details of the client/peer and the data received
		// one recvfrom is one UDP packet (is that always true??)
        if(pck_count % 100000 == 1)	printf(" Received packet %d from %s:%d\n", pck_count, inet_ntoa(si_other.sin_addr), ntohs(si_other.sin_port));
        pck_count++;

		// --------- adjustments to data ------------
		runtype = buf[4] + (buf[5] << 8);
		tracesegment = (int)buf[57];

		//if (debug_count < maxmsg)	printf("packet # %d, Runtype 0x%x, traceseg %d  \n", pck_count, runtype, tracesegment);
		//debug_count++;
		//if(0)
		if(runtype ==0x410)             // special treatment for mult-package events in 0x410
		{
			if(tracesegment == 0 ) // check word 28 for the traceseg counter  
			{
				//if (debug_count < maxmsg)	printf("packet # %d, Runtype 0x%x, traceseg 0  \n", pck_count, runtype);
				//debug_count++;

				// handle any lost segments before the start of a new event
				if (tracesegment != seg_count)   // ((seg_count > 0) & (seg_count < 7) )
				{
					Nextra = 8 - seg_count;
					if (misseg_count < maxmsg)	printf("Lost part of multi-event packet (in packet # %d,  seg # is %d, expected %d), inserting %d blocks of zeros  \n", pck_count, tracesegment, seg_count, Nextra);
					misseg_count++;
					
					for (extra = 0; extra < Nextra; extra++)
					{
						fwrite(zeros, 1, recv_len - HDRLEN_410, fil);     // write zeros to file
					}
				}
		
				fwrite( buf, 1, recv_len, fil );     // write everything to file

				seg_count = 1;
			}
			else
			{
				//if (debug_count < maxmsg)	printf("packet # %d, Runtype 0x%x, traceseg > 0  \n", pck_count, runtype);
				//debug_count++;

				
				//seg_count++;

				if ((tracesegment < 8) & (tracesegment != seg_count)  )           // check for missing packets. 0 following 0 is ok (short trace), 8 is ok
				{
					
					if(tracesegment > seg_count) Nextra = tracesegment - seg_count;
					if(tracesegment < seg_count) Nextra = tracesegment - seg_count + 8;
	
					if (misseg_count < maxmsg)	printf("Lost part of multi-event packet (in packet # %d,  seg # is %d, expected %d), inserting %d blocks of zeros  \n", pck_count, tracesegment, seg_count, Nextra);
					misseg_count++;

					for (extra = 0; extra < Nextra; extra++)
					{
						fwrite(zeros, 1, recv_len - HDRLEN_410, fil);     // write zeros to file
					}

					
				}

				fwrite(buf + HDRLEN_410, 1, recv_len - HDRLEN_410, fil);     // write trace only to file

				seg_count = tracesegment+1;					  // reset expectation for next segment number 
				if (seg_count > 7) seg_count = 0;
			}

			if (misseg_count % 20 == 1)
			{
				printf("Lost parts of multi-event packets %d times \n", misseg_count);
				misseg_count++;		// count error 1 in N, but since it does not increment for successful packets, it would keep reporting N+1 lost
			}

		} 
		else  // other run types
		{
			//printf("Data: %s\n" , buf);
			fwrite( buf, 1, recv_len, fil );     // write to file
		}

		

	}	// end while

	closesocket(s);
	WSACleanup();
    fclose(fil);
	
	return 0;
}