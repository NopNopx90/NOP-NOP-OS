#include <stdio.h>
#include <stdlib.h>

#define SECTOR_SIZE 512

int main() {
    FILE *image_file, *bootloader_file;
    char img_path[] = "C:\\Users\\91935\\Documents\\Arman\\Real Mode\\NopOS\\local\\build\\floppy_M.img";
    char bootloader_path[] = "C:\\Users\\91935\\Documents\\Arman\\Real Mode\\NopOS\\local\\build\\bootloader.bin";

    // Open the disk image file
    image_file = fopen(img_path, "r+b");
    if (image_file == NULL) {
        perror("Error opening disk image file");
        return 1;
    }

    bootloader_file = fopen(bootloader_path, "rb");
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
