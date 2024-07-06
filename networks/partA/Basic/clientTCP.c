#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

int main() {
    char *ip = "192.168.121.135";
    int port = 5566;

    int sock;
    struct sockaddr_in addr;
    socklen_t addr_size;
    char buffer[1024];
    int n;

    sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) {
        perror("[-]Socket error");
        exit(1);
    }
    printf("[+]TCP client socket created.\n");

    memset(&addr, '\0', sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port); // Corrected port conversion
    addr.sin_addr.s_addr = inet_addr(ip);

    n = connect(sock, (struct sockaddr *) &addr, sizeof(addr));
    if (n < 0) {
        perror("[-]Connect error");
        exit(1);
    }
    printf("Connected to the server.\n");

    bzero(buffer, 1024);
    strcpy(buffer, "HELLO, THIS IS CLIENT.");
    printf("Client: %s\n", buffer);
    n = send(sock, buffer, strlen(buffer), 0);
    if (n < 0) {
        perror("[-]Send error");
        exit(1);
    }

    bzero(buffer, 1024);
    n = recv(sock, buffer, sizeof(buffer), 0);
    if (n < 0) {
        perror("[-]Receive error");
        exit(1);
    }
    printf("Server: %s\n", buffer);

    close(sock);
    printf("Disconnected from the server.\n");

    return 0;
}
