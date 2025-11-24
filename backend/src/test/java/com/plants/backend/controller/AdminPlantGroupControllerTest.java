package com.plants.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.plants.backend.BaseIntegrationTest;
import com.plants.backend.dto.CreatePlantGroupRequest;
import com.plants.backend.dto.UpdatePlantGroupRequest;
import com.plants.backend.entity.Image;
import com.plants.backend.repository.ImageRepository;
import com.plants.backend.repository.PlantGroupRepository;
import com.plants.backend.service.PlantGroupService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.UUID;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@AutoConfigureMockMvc
class AdminPlantGroupControllerTest extends BaseIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private PlantGroupService plantGroupService;

    @Autowired
    private PlantGroupRepository plantGroupRepository;

    @Autowired
    private ImageRepository imageRepository;

    private String testImageId;

    @BeforeEach
    void setUp() {
        // Clear data
        plantGroupRepository.deleteAll();
        imageRepository.deleteAll();
        // Create a test image
        Image testImage = new Image();
        testImage.setId(UUID.randomUUID().toString());
        testImage.setFilename("test.jpg");
        testImage.setContentType("image/jpeg");
        testImage.setBytes(new byte[]{1, 2, 3});
        testImage.setCreatedDate(LocalDateTime.now());
        testImageId = imageRepository.save(testImage).getId();
    }

    @Test
    void createGroup_shouldReturn201WithNewGroup() throws Exception {
        // Given
        CreatePlantGroupRequest request = new CreatePlantGroupRequest(
                "succulents", "Succulents & Cacti", testImageId);

        // When/Then
        mockMvc.perform(post("/api/admin/plant-groups")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id", is("succulents")))
                .andExpect(jsonPath("$.name", is("Succulents & Cacti")))
                .andExpect(jsonPath("$.imageId", is(testImageId)));
    }

    @Test
    void createGroup_shouldReturn400ForInvalidData() throws Exception {
        // Given - empty name
        String json = "{\"id\":\"test\",\"name\":\"\",\"imageId\":null}";

        // When/Then
        mockMvc.perform(post("/api/admin/plant-groups")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").exists());
    }

    @Test
    void getGroupById_shouldReturnGroup() throws Exception {
        // Given
        plantGroupService.createGroup(new CreatePlantGroupRequest(
                "succulents", "Succulents & Cacti", testImageId));

        // When/Then
        mockMvc.perform(get("/api/admin/plant-groups/succulents"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id", is("succulents")))
                .andExpect(jsonPath("$.name", is("Succulents & Cacti")));
    }

    @Test
    void getGroupById_shouldReturn404ForNonExistent() throws Exception {
        // When/Then
        mockMvc.perform(get("/api/admin/plant-groups/non-existent"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").exists());
    }

    @Test
    void updateGroup_shouldReturnUpdatedGroup() throws Exception {
        // Given
        plantGroupService.createGroup(new CreatePlantGroupRequest(
                "succulents", "Succulents & Cacti", testImageId));
        UpdatePlantGroupRequest updateRequest = new UpdatePlantGroupRequest(
                "Desert Plants", testImageId);

        // When/Then
        mockMvc.perform(put("/api/admin/plant-groups/succulents")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id", is("succulents")))
                .andExpect(jsonPath("$.name", is("Desert Plants")));
    }

    @Test
    void updateGroup_shouldReturn404ForNonExistent() throws Exception {
        // Given
        UpdatePlantGroupRequest request = new UpdatePlantGroupRequest(
                "New Name", testImageId);

        // When/Then
        mockMvc.perform(put("/api/admin/plant-groups/non-existent")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isNotFound());
    }

    @Test
    void deleteGroup_shouldReturn204() throws Exception {
        // Given
        plantGroupService.createGroup(new CreatePlantGroupRequest(
                "succulents", "Succulents & Cacti", testImageId));

        // When/Then
        mockMvc.perform(delete("/api/admin/plant-groups/succulents"))
                .andExpect(status().isNoContent());

        // Verify it's deleted
        mockMvc.perform(get("/api/admin/plant-groups/succulents"))
                .andExpect(status().isNotFound());
    }

    @Test
    void deleteGroup_shouldReturn404ForNonExistent() throws Exception {
        // When/Then
        mockMvc.perform(delete("/api/admin/plant-groups/non-existent"))
                .andExpect(status().isNotFound());
    }
}