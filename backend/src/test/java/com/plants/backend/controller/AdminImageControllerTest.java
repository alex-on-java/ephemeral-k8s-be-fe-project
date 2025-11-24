package com.plants.backend.controller;

import com.plants.backend.BaseIntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.matchesPattern;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@AutoConfigureMockMvc
class AdminImageControllerTest extends BaseIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void uploadImage_shouldReturnImageIdWithCreatedStatus() throws Exception {
        // Given
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "test-image.jpg",
                "image/jpeg",
                "test-image-content".getBytes()
        );

        // When/Then
        mockMvc.perform(multipart("/api/admin/images")
                        .file(file))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.imageId").exists())
                .andExpect(jsonPath("$.imageId").value(matchesPattern("^[0-9a-f-]{36}$")));
    }

    @Test
    void uploadImage_shouldAcceptPngImages() throws Exception {
        // Given
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "test-image.png",
                "image/png",
                "png-image-content".getBytes()
        );

        // When/Then
        mockMvc.perform(multipart("/api/admin/images")
                        .file(file))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.imageId").exists());
    }

    @Test
    void uploadImage_shouldRejectEmptyFile() throws Exception {
        // Given
        MockMultipartFile emptyFile = new MockMultipartFile(
                "file",
                "empty.jpg",
                "image/jpeg",
                new byte[0]
        );

        // When/Then
        mockMvc.perform(multipart("/api/admin/images")
                        .file(emptyFile))
                .andExpect(status().isBadRequest());
    }

    @Test
    void uploadImage_shouldRejectNonImageFile() throws Exception {
        // Given
        MockMultipartFile nonImageFile = new MockMultipartFile(
                "file",
                "document.pdf",
                "application/pdf",
                "fake-pdf-content".getBytes()
        );

        // When/Then
        mockMvc.perform(multipart("/api/admin/images")
                        .file(nonImageFile))
                .andExpect(status().isBadRequest());
    }
}
