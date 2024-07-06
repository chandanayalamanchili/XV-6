#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define MAX_MSG_SIZE 1024

int main(int argc, char **argv)
{
    if (argc != 3)
    {
        printf("Usage: %s <port1> <port2>\n", argv[0]);
        exit(1);
    }

    char *ip = "10.2.131.141";
    int port1 = atoi(argv[1]);
    int port2 = atoi(argv[2]);

    int sockfd1, sockfd2;
    struct sockaddr_in server_addr1, server_addr2, client_addr1, client_addr2;
    socklen_t addr_size;
    char buffer1[MAX_MSG_SIZE], buffer2[MAX_MSG_SIZE];

    sockfd1 = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd1 < 0)
    {
        perror("[-]Socket error");
        exit(1);
    }

    sockfd2 = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd2 < 0)
    {
        perror("[-]Socket error");
        exit(1);
    }

    memset(&server_addr1, 0, sizeof(server_addr1));
    server_addr1.sin_family = AF_INET;
    server_addr1.sin_port = htons(port1);
    server_addr1.sin_addr.s_addr = inet_addr(ip);

    memset(&server_addr2, 0, sizeof(server_addr2));
    server_addr2.sin_family = AF_INET;
    server_addr2.sin_port = htons(port2);
    server_addr2.sin_addr.s_addr = inet_addr(ip);

    if (bind(sockfd1, (struct sockaddr *)&server_addr1, sizeof(server_addr1)) < 0)
    {
        perror("[-]Bind error");
        exit(1);
    }

    if (bind(sockfd2, (struct sockaddr *)&server_addr2, sizeof(server_addr2)) < 0)
    {
        perror("[-]Bind error");
        exit(1);
    }

    printf("[+]UDP sockets bound to port %d and %d\n", port1, port2);
    char playAgainA[10], playAgainB[10];

    while (1)
    {
        // Receive client A's choice
        addr_size = sizeof(client_addr1);
        int n1 = recvfrom(sockfd1, buffer1, sizeof(buffer1), 0, (struct sockaddr *)&client_addr1, &addr_size);
        if (n1 < 0)
        {
            perror("[-]Receive from error");
            exit(1);
        }
        buffer1[n1] = '\0'; // Null-terminate the received message

        // Receive client B's choice
        addr_size = sizeof(client_addr2);
        int n2 = recvfrom(sockfd2, buffer2, sizeof(buffer2), 0, (struct sockaddr *)&client_addr2, &addr_size);
        if (n2 < 0)
        {
            perror("[-]Receive from error");
            exit(1);
        }
        buffer2[n2] = '\0'; // Null-terminate the received message

        int choice1 = atoi(buffer1);
        int choice2 = atoi(buffer2);
        int result = (choice1 - choice2 + 3) % 3; // Calculate the result of the game

        char judgment[50];
        if (result == 0)
            strcpy(judgment, "Draw");
        else if (result == 1)
            strcpy(judgment, "Client A wins");
        else
            strcpy(judgment, "Client B wins");

        printf("Client A chose: %d\n", choice1);
        printf("Client B chose: %d\n", choice2);
        printf("Result: %s\n", judgment);

        // Send the judgment to both clients
        sendto(sockfd1, judgment, strlen(judgment), 0, (struct sockaddr *)&client_addr1, addr_size);
        sendto(sockfd2, judgment, strlen(judgment), 0, (struct sockaddr *)&client_addr2, addr_size);

        // Receive confirmation from both clients
        recvfrom(sockfd1, playAgainA, sizeof(playAgainA), 0, (struct sockaddr *)&client_addr1, &addr_size);
        recvfrom(sockfd2, playAgainB, sizeof(playAgainB), 0, (struct sockaddr *)&client_addr2, &addr_size);
        char final[1024];
        strcpy(final, "no");
        if (strcmp(playAgainA, "no") == 0 || strcmp(playAgainB, "no") == 0)
        {
            printf("Closing the connection...\n");
            sendto(sockfd2, final, strlen(final), 0, (struct sockaddr *)&client_addr2, addr_size);
            sendto(sockfd1, final, strlen(final), 0, (struct sockaddr *)&client_addr1, addr_size);

            break;
        }
        else
        {
            strcpy(final, "yes");
            sendto(sockfd2, final, strlen(final), 0, (struct sockaddr *)&client_addr2, addr_size);
            sendto(sockfd1, final, strlen(final), 0, (struct sockaddr *)&client_addr1, addr_size);
        }
    }

    close(sockfd1);
    close(sockfd2);

    return 0;
}
