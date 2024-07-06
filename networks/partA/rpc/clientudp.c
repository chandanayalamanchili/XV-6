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
        printf("Usage: %s <ip> <port>\n", argv[0]);
        exit(1);
    }
    char final[1024];
    strcpy(final,"yes");
    char *ip = argv[1];
    int port = atoi(argv[2]);

    int sockfd;
    struct sockaddr_in server_addr;
    char buffer[MAX_MSG_SIZE];

    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0)
    {
        perror("[-]Socket error");
        exit(1);
    }

    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(port);
    server_addr.sin_addr.s_addr = inet_addr(ip);

    while (strcmp(final,"yes")==0)
    {
        int choice;
        printf("Enter your choice (0 for Rock, 1 for Paper, 2 for Scissors): ");
        scanf("%d", &choice);

        snprintf(buffer, sizeof(buffer), "%d", choice);

        sendto(sockfd, buffer, sizeof(buffer), 0, (struct sockaddr *)&server_addr, sizeof(server_addr));

        // Receive judgment from the server
        char judgment[50];
        socklen_t addr_size = sizeof(server_addr);
        recvfrom(sockfd, judgment, sizeof(judgment), 0, (struct sockaddr *)&server_addr, &addr_size);
        printf("Result: %s\n", judgment);

        // Prompt for another game
        char playAgain[10];
        printf("Play another game? (yes/no): ");
        scanf("%s", playAgain);

        sendto(sockfd, playAgain, sizeof(playAgain), 0, (struct sockaddr *)&server_addr, addr_size);
        recvfrom(sockfd, final, sizeof(final), 0, (struct sockaddr *)&server_addr, &addr_size);

        if (strcmp(final, "no") == 0)
            break;
    }

    close(sockfd);

    return 0;
}
