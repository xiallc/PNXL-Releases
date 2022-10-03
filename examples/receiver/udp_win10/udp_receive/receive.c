/*
	Simple UDP Server
   adapted from https://www.binarytides.com/udp-socket-programming-in-winsock/
   last modified 8/19/2022
*/

#include<stdio.h>
#include<winsock2.h>
#include<signal.h>

#pragma comment(lib,"ws2_32.lib") //Winsock Library

#define BUFLEN 4096	//Max length of buffer
#define PORT 61002	//The port on which to listen for incoming data

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

	slen = sizeof(si_other) ;

	// Identify version
	printf("UDP receiver utility, compiled for Windows 10, 32 bit\n");

	if (argc < 3) {
		printf("Using default port %d, any IP\n", userport);
	}
	else {
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
	if (iResult == SOCKET_ERROR) {
		wprintf(L"getsockopt for SO_RCVBUF failed with error: %u\n", WSAGetLastError());
	}
	else
		wprintf(L"   SO_RCVBUF Value: %ld\n", iOptVal);


	int a = 10000000;
	if (setsockopt(s, SOL_SOCKET, SO_RCVBUF, &a, sizeof(int)) == -1) {
		fprintf(stderr, "Error setting socket opts: %s\n", strerror(errno));
	}

	iResult = getsockopt(s, SOL_SOCKET, SO_RCVBUF, (char*)&iOptVal, &iOptLen);
	if (iResult == SOCKET_ERROR) {
		wprintf(L"getsockopt for SO_RCVBUF failed with error: %u\n", WSAGetLastError());
	}
	else
		wprintf(L"   SO_RCVBUF Value: %ld\n", iOptVal);


	//clear the buffer by filling null, it might have previously received data
	memset(buf,'\0;', BUFLEN);


    fil = fopen("LMdata.bin","wb");

	signal(SIGINT, sighandler);
	printf("Waiting for data...press CTRL-C to quit\n");

	//keep listening for data
	while(1)
	{
		//printf("Waiting for data...");
		fflush(stdout);
		
		//clear the buffer by filling null, it might have previously received data
		//memset(buf,'\0;', BUFLEN);
		
		//try to receive some data, this is a blocking call
		// i.e. it waits in the if condition until data ready
		if ((recv_len = recvfrom(s, buf, BUFLEN, 0, (struct sockaddr *) &si_other, &slen)) == SOCKET_ERROR)
		{
			printf("recvfrom() failed with error code : %d" , WSAGetLastError());
			exit(EXIT_FAILURE);
		}
		
		//print details of the client/peer and the data received
		// one recvfrom is one UDP packet (is that always true??)
        if(pck_count % 10000 == 1)	printf(" Received packet %d from %s:%d\n", pck_count, inet_ntoa(si_other.sin_addr), ntohs(si_other.sin_port));
        pck_count++;
		
		//printf("Data: %s\n" , buf);
      	fwrite( buf, 1, recv_len, fil );     // write to file
	}

	closesocket(s);
	WSACleanup();
   fclose(fil);
	
	return 0;
}