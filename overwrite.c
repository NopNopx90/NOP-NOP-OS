#include <stdio.h>
#include <stdlib.h>

#define SECTOR_SIZE 512

int main(int argc, char *argv[]) {
    FILE *image_file, *bootloader_file;

    image_file = fopen(argv[1], "r+b");
    if (image_file == NULL) {
        perror("Error opening disk image file");
        return 1;
    }

    bootloader_file = fopen(argv[2], "rb");
    if (bootloader_file == NULL) {
        perror("Error opening bootloader binary file");
        fclose(image_file);
        return 1;
    }

    // Seek to the beginning of the disk image
    fseek(image_file, 0, SEEK_SET);

    unsigned char bootloader_data[SECTOR_SIZE];
    fread(bootloader_data, sizeof(unsigned char), SECTOR_SIZE, bootloader_file);

    // Write bootloader data to the disk image
    fwrite(bootloader_data, sizeof(unsigned char), SECTOR_SIZE, image_file);
    fclose(image_file);
    fclose(bootloader_file);

    printf("Bootloader written to the first sector of the disk image successfully.\n");

    return 0;
}
