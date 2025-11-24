package com.plants.backend.service;

import com.plants.backend.BaseIntegrationTest;
import com.plants.backend.dto.ImageResponse;
import com.plants.backend.entity.Image;
import com.plants.backend.exception.ResourceNotFoundException;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mock.web.MockMultipartFile;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class ImageServiceTest extends BaseIntegrationTest {

    @Autowired
    private ImageService imageService;

    @Test
    void uploadImage_shouldSaveAndReturnImageResponse() {
        // Given
        byte[] imageData = "test-image-content".getBytes();
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "test-image.jpg",
                "image/jpeg",
                imageData
        );

        // When
        ImageResponse response = imageService.uploadImage(file);

        // Then
        assertThat(response).isNotNull();
        assertThat(response.id()).isNotEmpty();
        assertThat(response.filename()).isEqualTo("test-image.jpg");
        assertThat(response.contentType()).isEqualTo("image/jpeg");
        assertThat(response.createdDate()).isNotNull();
    }

    @Test
    void getImageById_shouldReturnImageWithBytes() {
        // Given
        byte[] imageData = "test-image-content".getBytes();
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "test-image.png",
                "image/png",
                imageData
        );
        ImageResponse uploadedImage = imageService.uploadImage(file);

        // When
        Image retrievedImage = imageService.getImageById(uploadedImage.id());

        // Then
        assertThat(retrievedImage).isNotNull();
        assertThat(retrievedImage.getId()).isEqualTo(uploadedImage.id());
        assertThat(retrievedImage.getFilename()).isEqualTo("test-image.png");
        assertThat(retrievedImage.getContentType()).isEqualTo("image/png");
        assertThat(retrievedImage.getBytes()).isEqualTo(imageData);
    }

    @Test
    void getImageById_shouldThrowExceptionWhenNotFound() {
        // When/Then
        assertThatThrownBy(() -> imageService.getImageById("non-existent-id"))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Image not found with id: non-existent-id");
    }

    @Test
    void deleteImage_shouldRemoveImage() {
        // Given
        byte[] imageData = "test-image-content".getBytes();
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "test-image.jpg",
                "image/jpeg",
                imageData
        );
        ImageResponse uploadedImage = imageService.uploadImage(file);

        // When
        imageService.deleteImage(uploadedImage.id());

        // Then
        assertThatThrownBy(() -> imageService.getImageById(uploadedImage.id()))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void deleteImage_shouldThrowExceptionWhenNotFound() {
        // When/Then
        assertThatThrownBy(() -> imageService.deleteImage("non-existent-id"))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Image not found with id: non-existent-id");
    }

    @Test
    void uploadImage_shouldRejectEmptyFile() {
        // Given
        MockMultipartFile emptyFile = new MockMultipartFile(
                "file",
                "empty.jpg",
                "image/jpeg",
                new byte[0]
        );

        // When/Then
        assertThatThrownBy(() -> imageService.uploadImage(emptyFile))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Image file cannot be empty");
    }

    @Test
    void uploadImage_shouldRejectNonImageFile() {
        // Given
        MockMultipartFile nonImageFile = new MockMultipartFile(
                "file",
                "document.pdf",
                "application/pdf",
                "fake-pdf-content".getBytes()
        );

        // When/Then
        assertThatThrownBy(() -> imageService.uploadImage(nonImageFile))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("File must be an image");
    }
}
