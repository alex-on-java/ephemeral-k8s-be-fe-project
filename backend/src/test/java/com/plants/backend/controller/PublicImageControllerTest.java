package com.plants.backend.controller;

import com.plants.backend.BaseIntegrationTest;
import com.plants.backend.dto.ImageResponse;
import com.plants.backend.service.ImageService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@AutoConfigureMockMvc
class PublicImageControllerTest extends BaseIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ImageService imageService;

    @Test
    void getImage_shouldReturnBinaryImageWithCorrectContentType() throws Exception {
        // Given
        byte[] imageData = "test-image-binary-content".getBytes();
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "test-image.jpg",
                "image/jpeg",
                imageData
        );
        ImageResponse uploadedImage = imageService.uploadImage(file);

        // When/Then
        mockMvc.perform(get("/api/images/{id}", uploadedImage.id()))
                .andExpect(status().isOk())
                .andExpect(header().string("Content-Type", "image/jpeg"))
                .andExpect(content().bytes(imageData));
    }

    @Test
    void getImage_shouldReturn404WhenImageNotFound() throws Exception {
        // When/Then
        mockMvc.perform(get("/api/images/{id}", "non-existent-id"))
                .andExpect(status().isNotFound());
    }

    @Test
    void getImage_shouldHandlePngContentType() throws Exception {
        // Given
        byte[] imageData = "png-image-data".getBytes();
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "test-image.png",
                "image/png",
                imageData
        );
        ImageResponse uploadedImage = imageService.uploadImage(file);

        // When/Then
        mockMvc.perform(get("/api/images/{id}", uploadedImage.id()))
                .andExpect(status().isOk())
                .andExpect(header().string("Content-Type", "image/png"))
                .andExpect(content().bytes(imageData));
    }
}
