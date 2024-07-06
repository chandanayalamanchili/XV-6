#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

int main(int argc, char *argv[])
{
    if (argc != 4)
    {
        fprintf(stderr, "Usage: %s <IP> <Port for clientA> <Port for clientB>\n", argv[0]);
        exit(1);
    }

    char *ip = argv[1];
    int portA = atoi(argv[2]); // Port for clientA
    int portB = atoi(argv[3]); // Port for clientB

    int server_sock_A, server_sock_B;
    struct sockaddr_in server_addr_A, server_addr_B;
    socklen_t addr_size_A, addr_size_B;
    char buffer_A[1024], buffer_B[1024];
    int n_A, n_B;

    server_sock_A = socket(AF_INET, SOCK_STREAM, 0);
    if (server_sock_A < 0)
    {
        perror("[-]Socket error");
        exit(1);
    }
    printf("[+]TCP server socket for clientA created.\n");

    server_sock_B = socket(AF_INET, SOCK_STREAM, 0);
    if (server_sock_B < 0)
    {
        perror("[-]Socket error");
        exit(1);
    }
    printf("[+]TCP server socket for clientB created.\n");

    memset(&server_addr_A, '\0', sizeof(server_addr_A));
    server_addr_A.sin_family = AF_INET;
    server_addr_A.sin_port = htons(portA);
    server_addr_A.sin_addr.s_addr = inet_addr(ip);

    memset(&server_addr_B, '\0', sizeof(server_addr_B));
    server_addr_B.sin_family = AF_INET;
    server_addr_B.sin_port = htons(portB);
    server_addr_B.sin_addr.s_addr = inet_addr(ip);

    n_A = bind(server_sock_A, (struct sockaddr *)&server_addr_A, sizeof(server_addr_A));
    if (n_A < 0)
    {
        perror("[-]Bind error for clientA");
        exit(1);
    }
    printf("[+]Bind to the port number for clientA: %d\n", portA);

    n_B = bind(server_sock_B, (struct sockaddr *)&server_addr_B, sizeof(server_addr_B));
    if (n_B < 0)
    {
        perror("[-]Bind error for clientB");
        exit(1);
    }
    printf("[+]Bind to the port number for clientB: %d\n", portB);

    n_A = listen(server_sock_A, 1);
    if (n_A < 0)
    {
        perror("[-]Listen error for clientA");
        exit(1);
    }

    n_B = listen(server_sock_B, 1);
    if (n_B < 0)
    {
        perror("[-]Listen error for clientB");
        exit(1);
    }

    printf("Waiting for clients...\n");

    addr_size_A = sizeof(server_addr_A);
    addr_size_B = sizeof(server_addr_B);

    int client_sock_A, client_sock_B;

    client_sock_A = accept(server_sock_A, (struct sockaddr *)&server_addr_A, &addr_size_A);
    if (client_sock_A < 0)
    {
        perror("[-]Accept error for clientA");
        exit(1);
    }
    printf("[+]ClientA connected.\n");

    client_sock_B = accept(server_sock_B, (struct sockaddr *)&server_addr_B, &addr_size_B);
    if (client_sock_B < 0)
    {
        perror("[-]Accept error for clientB");
        exit(1);
    }
    printf("[+]ClientB connected.\n");

    while (1)
    {
        bzero(buffer_A, 1024);
        n_A = recv(client_sock_A, buffer_A, sizeof(buffer_A), 0);
        if (n_A < 0)
        {
            perror("[-]Receive error for clientA");
            exit(1);
        }

        bzero(buffer_B, 1024);
        n_B = recv(client_sock_B, buffer_B, sizeof(buffer_B), 0);
        if (n_B < 0)
        {
            perror("[-]Receive error for clientB");
            exit(1);
        }

        int choice_A = atoi(buffer_A);
        int choice_B = atoi(buffer_B);

        char result[1024];
        if (choice_A == choice_B)
        {
            strcpy(result, "Draw");
        }
        else if ((choice_A == 0 && choice_B == 2) || (choice_A == 1 && choice_B == 0) || (choice_A == 2 && choice_B == 1))
        {
            strcpy(result, "ClientA Wins");
        }
        else
        {
            strcpy(result, "ClientB Wins");
        }

        printf("ClientA choice: %d, ClientB choice: %d\n", choice_A, choice_B);
        printf("Result: %s\n", result);

        n_A = send(client_sock_A, result, strlen(result), 0);
        if (n_A < 0)
        {
            perror("[-]Send error for clientA");
            exit(1);
        }

        n_B = send(client_sock_B, result, strlen(result), 0);
        if (n_B < 0)
        {
            perror("[-]Send error for clientB");
            exit(1);
        }
        // Prompt for another game
        int playAgain_A = 0, playAgain_B = 0; // Flags to track if both clients want to play again
        char response_A[1024], response_B[1024];
        bzero(response_A, sizeof(response_A));
        bzero(response_B, sizeof(response_B));

        // printf("Do you want to play another game? (yes/no): ");
        n_A = recv(client_sock_A, response_A, sizeof(response_A), 0);
        if (n_A < 0)
        {
            perror("[-]Receive error for clientA");
            exit(1);
        }

        // printf("Do you want to play another game? (yes/no): ");
        n_B = recv(client_sock_B, response_B, sizeof(response_B), 0);
        if (n_B < 0)
        {
            perror("[-]Receive error for clientB");
            exit(1);
        }
        // printf("%s\n",response_A);
        // printf("%s\n",response_B);

        if (strcmp(response_A, "no") == 0 || strcmp(response_B, "no") == 0)
{
    if (strcmp(response_A, "no") == 0)
    {
        playAgain_A = 0; // Client A does not want to play again
    }
    if (strcmp(response_B, "no") == 0)
    {
        playAgain_B = 0; // Client B does not want to play again
    }
}
else if(strcmp(response_A, "yes") == 0 && strcmp(response_B, "yes") == 0)
{
    playAgain_A = 1; // Client A wants to play again
    playAgain_B = 1; // Client B wants to play again
}

        // Send the playAgain flag to both clients
        send(client_sock_A, &playAgain_A, sizeof(playAgain_A), 0);
        send(client_sock_B, &playAgain_B, sizeof(playAgain_B), 0);

        if (playAgain_A == 0 || playAgain_B == 0)
        {
            break; // Exit the loop if one of the clients doesn't want to play another game
        }
    }

    close(server_sock_A);
    close(server_sock_B);
    printf("Server closed.\n");

    return 0;
}
