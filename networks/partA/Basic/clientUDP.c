#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <errno.h>

int main(int argc, char **argv) {
    if (argc != 2) {
        printf("Usage: %s <port>\n", argv[0]);
        exit(1);
    }

    char *ip = "192.168.121.135";
    int port = atoi(argv[1]);

    int sockfd;
    struct sockaddr_in addr;
    char buffer[1024];
    socklen_t addr_size;

    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0) {
        perror("[-]Socket error");
        exit(1);
    }
    printf("[+]UDP socket created.\n");

    memset(&addr, '\0', sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = inet_addr(ip);

    bzero(buffer, 1024);
    strcpy(buffer, "Hello, World!");
    if (sendto(sockfd, buffer, 1024, 0, (struct sockaddr *) &addr, sizeof(addr)) < 0) {
        perror("[-]Sendto error");
        close(sockfd);
        exit(1);
    }
    printf("[+]Data sent: %s\n", buffer);

    bzero(buffer, 1024);
    addr_size = sizeof(addr);
    if (recvfrom(sockfd, buffer, 1024, 0, (struct sockaddr *) &addr, &addr_size) < 0) {
        perror("[-]Recvfrom error");
        close(sockfd);
        exit(1);
    }
    printf("[+]Data received: %s\n\n\n", buffer);

    close(sockfd);
    return 0;
}
