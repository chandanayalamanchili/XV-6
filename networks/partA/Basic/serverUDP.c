#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/inet.h>

int main(int argc, char **argv)
{
    if (argc != 2)
    {
        printf("Usage: %s <port>\n", argv[0]);
        exit(1);
    }

    char *ip = "192.168.121.135";
    int port = atoi(argv[1]);

    int sockfd;
    struct sockaddr_in server_addr, client_addr;
    char buffer[1024];
    socklen_t addr_size;
    int n;

    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0)
    {
        perror("[-]Socket error");
        exit(1);
    }

    memset(&server_addr, '\0', sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(port);
    server_addr.sin_addr.s_addr = inet_addr(ip);

    n = bind(sockfd, (struct sockaddr *)&server_addr, sizeof(server_addr));
    if (n < 0)
    {
        perror("[-]Bind error");
        exit(1);
    }
    printf("[+]UDP socket bound to port %d\n", port);
    while (1)
    {

        addr_size = sizeof(client_addr);
        n = recvfrom(sockfd, buffer, sizeof(buffer), 0, (struct sockaddr *)&client_addr, &addr_size);
        if (n < 0)
        {
            perror("[-]Receive from error");
            exit(1);
        }
        printf("Received data: %s\n", buffer);

        char response[] = "Hello from the server!";
        n = sendto(sockfd, response, sizeof(response), 0, (struct sockaddr *)&client_addr, addr_size);
        if (n < 0)
        {
            perror("[-]Sendto error");
            exit(1);
        }
        printf("Sent response to client: %s\n\n\n", response);
    }
    // Process and respond here if needed

    close(sockfd);

    return 0;
}
