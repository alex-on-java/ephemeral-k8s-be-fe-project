package com.plants.backend.controller;

import com.plants.backend.BaseIntegrationTest;
import com.plants.backend.dto.*;
import com.plants.backend.entity.PlantGroup;
import com.plants.backend.repository.ImageRepository;
import com.plants.backend.repository.PlantGroupRepository;
import com.plants.backend.repository.PlantRepository;
import com.plants.backend.service.ImageService;
import com.plants.backend.service.PlantService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockMultipartFile;

import java.util.Arrays;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class PublicPlantControllerTest extends BaseIntegrationTest {

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private PlantService plantService;

    @Autowired
    private PlantRepository plantRepository;

    @Autowired
    private PlantGroupRepository plantGroupRepository;

    @Autowired
    private ImageRepository imageRepository;

    @Autowired
    private ImageService imageService;

    private String groupId;
    private String plantId;

    @BeforeEach
    void setUp() throws Exception {
        plantRepository.deleteAll();
        plantGroupRepository.deleteAll();
        imageRepository.deleteAll();

        // Create test images
        String thumbnailId = createTestImage("thumbnail.jpg");
        String image1Id = createTestImage("image1.jpg");

        // Create test plant group
        groupId = "test-group";
        PlantGroup group = new PlantGroup();
        group.setId(groupId);
        group.setName("Test Group");
        group.setImageId(thumbnailId);
        plantGroupRepository.save(group);

        // Create test plant
        plantId = "test-plant";
        CreatePlantRequest request = new CreatePlantRequest(
                plantId,
                groupId,
                "Test Plant",
                "Testus plantus",
                thumbnailId,
                new String[]{image1Id},
                "Description",
                "Small",
                "Non-toxic",
                new String[]{"Benefit 1", "Benefit 2", "Benefit 3", "Benefit 4"},
                new CareGuideDto("Water", "Light", "Temp", "Humidity", "Soil", "Fertilize"),
                Arrays.asList(
                        new IssueDto("Issue 1", "Solution 1"),
                        new IssueDto("Issue 2", "Solution 2")
                )
        );
        plantService.createPlant(request);
    }

    private String createTestImage(String filename) throws Exception {
        MockMultipartFile file = new MockMultipartFile(
                "file",
                filename,
                "image/jpeg",
                "test content".getBytes()
        );
        ImageResponse response = imageService.uploadImage(file);
        return response.id();
    }

    @Test
    void getPlantById_shouldReturnPlant() {
        ResponseEntity<PlantResponse> response = restTemplate.getForEntity(
                "/api/plants/" + plantId,
                PlantResponse.class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().id()).isEqualTo(plantId);
        assertThat(response.getBody().name()).isEqualTo("Test Plant");
        assertThat(response.getBody().care()).isNotNull();
        assertThat(response.getBody().commonIssues()).hasSize(2);
    }

    @Test
    void getPlantById_withInvalidId_shouldReturn404() {
        ResponseEntity<String> response = restTemplate.getForEntity(
                "/api/plants/non-existent",
                String.class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
    }

    @Test
    void getPlantsByGroup_shouldReturnPlants() {
        ResponseEntity<PlantSummaryResponse[]> response = restTemplate.getForEntity(
                "/api/plant-groups/" + groupId + "/plants",
                PlantSummaryResponse[].class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody()).hasSize(1);
        assertThat(response.getBody()[0].id()).isEqualTo(plantId);
    }

    @Test
    void getPlantsByGroup_withInvalidGroup_shouldReturn404() {
        ResponseEntity<String> response = restTemplate.getForEntity(
                "/api/plant-groups/non-existent/plants",
                String.class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
    }

    @Test
    void getPlantsByGroup_withNoPlants_shouldReturnEmptyList() {
        // Create another group without plants
        PlantGroup emptyGroup = new PlantGroup();
        emptyGroup.setId("empty-group");
        emptyGroup.setName("Empty Group");
        plantGroupRepository.save(emptyGroup);

        ResponseEntity<PlantSummaryResponse[]> response = restTemplate.getForEntity(
                "/api/plant-groups/empty-group/plants",
                PlantSummaryResponse[].class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isEmpty();
    }
}
