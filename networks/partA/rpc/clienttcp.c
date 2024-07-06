#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

int main(int argc, char *argv[])
{
    if (argc != 3)
    {
        fprintf(stderr, "Usage: %s <IP> <Port>\n", argv[0]);
        exit(1);
    }

    char *ip = argv[1];
    int port = atoi(argv[2]);

    int sock;
    struct sockaddr_in addr;
    socklen_t addr_size;
    char buffer[1024];
    int n;

    sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0)
    {
        perror("[-]Socket error");
        exit(1);
    }
    printf("[+]TCP client socket created.\n");

    memset(&addr, '\0', sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port); // Connect to the appropriate port for clientA or clientB
    addr.sin_addr.s_addr = inet_addr(ip);

    n = connect(sock, (struct sockaddr *)&addr, sizeof(addr));
    if (n < 0)
    {
        perror("[-]Connect error");
        exit(1);
    }
    printf("Connected to the server.\n");

    while (1)
    {
        int choice;

        printf("Enter your choice (0 for Rock, 1 for Paper, 2 for Scissors): ");
        scanf("%d", &choice);

        sprintf(buffer, "%d", choice);

        n = send(sock, buffer, strlen(buffer), 0);
        if (n < 0)
        {
            perror("[-]Send error");
            exit(1);
        }

        bzero(buffer, 1024);
        n = recv(sock, buffer, sizeof(buffer), 0);
        if (n < 0)
        {
            perror("[-]Receive error");
            exit(1);
        }
        printf("Result: %s\n", buffer);

        // Prompt for another game
        char playAgain[1024];
        printf("Do you want to play another game? (yes/no): ");
        scanf("%s", playAgain);
        send(sock, playAgain, strlen(playAgain), 0);

        // Receive the server's decision on whether to continue
        int serverPlayAgain;
        recv(sock, &serverPlayAgain, sizeof(serverPlayAgain), 0);

        if (serverPlayAgain == 0)
        {
            printf("Server decided not to play another game. Disconnecting...\n");
            break; // Exit the loop if the server decides not to play another game
        }
    }

    close(sock);
    printf("Disconnected from the server.\n");

    return 0;
}
