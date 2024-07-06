#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

#define MAX_CHUNK_SIZE 6
// #define TOTAL_CHUNKS 4  // Total number of fixed-size chunks

// Structure to represent a data chunk
struct Chunk {
    int sequence_number;
    char data[MAX_CHUNK_SIZE];
};

int compareChunks(const void* a, const void* b) {
    return ((struct Chunk*)a)->sequence_number - ((struct Chunk*)b)->sequence_number;
}

int main() {
    int server_socket;
    struct sockaddr_in server_addr, client_addr;
    socklen_t client_addr_len = sizeof(client_addr);

    // Create a UDP socket
    server_socket = socket(AF_INET, SOCK_DGRAM, 0);
    if (server_socket == -1) {
        perror("Error creating socket");
        exit(1);
    }

    // Initialize server address structure and bind the socket
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(8080);
    server_addr.sin_addr.s_addr = INADDR_ANY;

    if (bind(server_socket, (struct sockaddr*)&server_addr, sizeof(server_addr)) == -1) {
        perror("Error binding socket");
        close(server_socket);
        exit(1);
    }

    // while (1) {
        printf("Waiting for data...\n");
        
        int total_chunks;
        struct Chunk received_chunks[MAX_CHUNK_SIZE]; // Use TOTAL_CHUNKS instead of MAX_CHUNK_SIZE

        // Receive the total number of chunks from the client
        recvfrom(server_socket, &total_chunks, sizeof(total_chunks), 0, (struct sockaddr*)&client_addr, &client_addr_len);

        if (total_chunks == -1) {
            printf("Client has exited.\n");
            // break;  // Exit the loop if the client sent an exit message
        }

        for (int i = 0; i < total_chunks; i++) {
            printf("RECEIVED CHUNK #%d\n", i);

            recvfrom(server_socket, &received_chunks[i], sizeof(struct Chunk), 0, (struct sockaddr*)&client_addr, &client_addr_len);
        }

        // Sort the received chunks based on sequence number
        qsort(received_chunks, total_chunks, sizeof(struct Chunk), compareChunks);

        // Display the aggregated text
        printf("Received data:\n");
        for (int i = 0; i < total_chunks; i++) {
            printf("%s", received_chunks[i].data);
        }

        // Send data chunks to the client
        char* server_text = "vdfvdf fdvdsfv vdsvsd";  // Fixed text to send

        int server_text_len = strlen(server_text);
        int server_total_chunks = (server_text_len + MAX_CHUNK_SIZE - 1) / MAX_CHUNK_SIZE;

        // Send the total number of chunks to the client
        sendto(server_socket, &server_total_chunks, sizeof(server_total_chunks), 0, (struct sockaddr*)&client_addr, sizeof(client_addr));

        for (int i = 0; i < server_total_chunks; i++) {
            struct Chunk chunk;
            chunk.sequence_number = i;
            memset(chunk.data, 0, MAX_CHUNK_SIZE);

            int chunk_size = (i == server_total_chunks - 1) ? (server_text_len % MAX_CHUNK_SIZE) : MAX_CHUNK_SIZE;
            strncpy(chunk.data, &server_text[i * MAX_CHUNK_SIZE], chunk_size);  
            printf("SENT CHUNK #%d\n", i);

            // Send the data chunk to the client
            sendto(server_socket, &chunk, sizeof(struct Chunk), 0, (struct sockaddr*)&client_addr, sizeof(client_addr));
        }
    // }

    close(server_socket);
    return 0;
}
