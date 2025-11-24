package com.plants.backend.controller;

import com.plants.backend.BaseIntegrationTest;
import com.plants.backend.dto.CreatePlantGroupRequest;
import com.plants.backend.entity.Image;
import com.plants.backend.repository.ImageRepository;
import com.plants.backend.repository.PlantGroupRepository;
import com.plants.backend.service.PlantGroupService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.UUID;

import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.is;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@AutoConfigureMockMvc
class PublicPlantGroupControllerTest extends BaseIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

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
    void getAllGroups_shouldReturnAllGroups() throws Exception {
        // Given
        plantGroupService.createGroup(new CreatePlantGroupRequest(
                "succulents", "Succulents & Cacti", testImageId));
        plantGroupService.createGroup(new CreatePlantGroupRequest(
                "tropical", "Tropical Plants", testImageId));

        // When/Then
        mockMvc.perform(get("/api/plant-groups"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[0].id").exists())
                .andExpect(jsonPath("$[0].name").exists())
                .andExpect(jsonPath("$[0].imageId", is(testImageId)));
    }

    @Test
    void getAllGroups_shouldReturnEmptyListWhenNoGroups() throws Exception {
        // When/Then
        mockMvc.perform(get("/api/plant-groups"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(0)));
    }

    @Test
    void getPlantsByGroup_shouldReturnEmptyListForValidGroup() throws Exception {
        // Given
        plantGroupService.createGroup(new CreatePlantGroupRequest(
                "succulents", "Succulents & Cacti", testImageId));

        // When/Then
        mockMvc.perform(get("/api/plant-groups/succulents/plants"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(0)));
    }

    @Test
    void getPlantsByGroup_shouldReturn404ForInvalidGroup() throws Exception {
        // When/Then
        mockMvc.perform(get("/api/plant-groups/non-existent/plants"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").exists());
    }
}