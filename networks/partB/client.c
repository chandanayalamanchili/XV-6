#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

#define MAX_CHUNK_SIZE 6

// Structure to represent a data chunk
struct Chunk {
    int sequence_number;
    char data[MAX_CHUNK_SIZE];
};

int compareChunks(const void* a, const void* b) {
    return ((struct Chunk*)a)->sequence_number - ((struct Chunk*)b)->sequence_number;
}

int main() {
    int client_socket;
    struct sockaddr_in server_addr;
    
    // Create a UDP socket
    client_socket = socket(AF_INET, SOCK_DGRAM, 0);
    if (client_socket == -1) {
        perror("Error creating socket");
        exit(1);
    }

    // Initialize server address structure
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(8080);
    server_addr.sin_addr.s_addr = INADDR_ANY;
    socklen_t server_addr_len = sizeof(server_addr);

    // while (1) {
        struct Chunk received_chunks[MAX_CHUNK_SIZE];
        char* fixed_text = "dchdsi dcnnk dc dsncs";  // Fixed text to send
        int fixed_text_len = strlen(fixed_text);
        int total_chunks = (fixed_text_len + MAX_CHUNK_SIZE - 1) / MAX_CHUNK_SIZE;

        // Send the total number of chunks to the server
        sendto(client_socket, &total_chunks, sizeof(total_chunks), 0, (struct sockaddr*)&server_addr, sizeof(server_addr));

        // Send data chunks with sequence numbers
        for (int i = 0; i < total_chunks; i++) {
            struct Chunk chunk;
            chunk.sequence_number = i;
            strncpy(chunk.data, &fixed_text[i * MAX_CHUNK_SIZE], MAX_CHUNK_SIZE);

            // Send the data chunk to the server
            printf("SENT CHUNK #%d\n", i);
            sendto(client_socket, &chunk, sizeof(struct Chunk), 0, (struct sockaddr*)&server_addr, sizeof(server_addr));
        }

        // Receive the exit signal from the server
        int exit_signal;
        recvfrom(client_socket, &exit_signal, sizeof(exit_signal), 0, (struct sockaddr*)&server_addr, &server_addr_len);
        if (exit_signal == -1) {
            printf("Exiting...\n");
            // break;  // Exit the loop if the server sent an exit signal
        }

        // Receive and process data from the server
        for (int i = 0; i < total_chunks; i++) {
            printf("RECEIVED CHUNK #%d\n", i);

            recvfrom(client_socket, &received_chunks[i], sizeof(struct Chunk), 0, (struct sockaddr*)&server_addr, &server_addr_len);
        }

        // Sort the received chunks based on sequence number
        qsort(received_chunks, total_chunks, sizeof(struct Chunk), compareChunks);

        // Display the aggregated text
        printf("Received data:\n");
        for (int i = 0; i < total_chunks; i++) {
            printf("%s", received_chunks[i].data);
        }
    // }

    close(client_socket);
    return 0;
}
