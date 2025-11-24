package com.plants.backend.controller;

import com.plants.backend.BaseIntegrationTest;
import com.plants.backend.dto.*;
import com.plants.backend.entity.PlantGroup;
import com.plants.backend.repository.ImageRepository;
import com.plants.backend.repository.PlantGroupRepository;
import com.plants.backend.repository.PlantRepository;
import com.plants.backend.service.ImageService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.*;
import org.springframework.mock.web.MockMultipartFile;

import java.util.Arrays;

import static org.assertj.core.api.Assertions.assertThat;

class AdminPlantControllerTest extends BaseIntegrationTest {

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private PlantRepository plantRepository;

    @Autowired
    private PlantGroupRepository plantGroupRepository;

    @Autowired
    private ImageRepository imageRepository;

    @Autowired
    private ImageService imageService;

    private String groupId;
    private String thumbnailId;
    private String image1Id;
    private String image2Id;

    @BeforeEach
    void setUp() throws Exception {
        plantRepository.deleteAll();
        plantGroupRepository.deleteAll();
        imageRepository.deleteAll();

        // Create test images
        thumbnailId = createTestImage("thumbnail.jpg");
        image1Id = createTestImage("image1.jpg");
        image2Id = createTestImage("image2.jpg");

        // Create test plant group
        groupId = "test-group";
        PlantGroup group = new PlantGroup();
        group.setId(groupId);
        group.setName("Test Group");
        group.setImageId(thumbnailId);
        plantGroupRepository.save(group);
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

    private CreatePlantRequest createValidRequest(String plantId) {
        return new CreatePlantRequest(
                plantId,
                groupId,
                "Test Plant",
                "Testus plantus",
                thumbnailId,
                new String[]{image1Id, image2Id},
                "A wonderful test plant with detailed description",
                "Small to medium sized",
                "Non-toxic to pets",
                new String[]{"Easy to care for", "Air purifying", "Low light tolerant", "Pet safe"},
                new CareGuideDto(
                        "Water weekly",
                        "Bright indirect light",
                        "18-24°C",
                        "50-60%",
                        "Well-draining potting mix",
                        "Monthly during growing season"
                ),
                Arrays.asList(
                        new IssueDto("Yellow leaves", "Reduce watering frequency"),
                        new IssueDto("Brown tips", "Increase humidity levels")
                )
        );
    }

    @Test
    void createPlant_withValidData_shouldReturn201() {
        CreatePlantRequest request = createValidRequest("new-plant");

        ResponseEntity<PlantResponse> response = restTemplate.postForEntity(
                "/api/admin/plants",
                request,
                PlantResponse.class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().id()).isEqualTo("new-plant");
        assertThat(response.getBody().name()).isEqualTo("Test Plant");
    }

    @Test
    void createPlant_withInvalidData_shouldReturn400() {
        // Missing required field (name is blank)
        CreatePlantRequest invalidRequest = new CreatePlantRequest(
                "invalid-plant",
                groupId,
                "",  // Blank name
                "Testus plantus",
                thumbnailId,
                new String[]{image1Id},
                "Description",
                "Size",
                "Toxicity",
                new String[]{"B1", "B2", "B3", "B4"},
                new CareGuideDto("W", "L", "T", "H", "S", "F"),
                Arrays.asList(
                        new IssueDto("Issue", "Solution"),
                        new IssueDto("Issue2", "Solution2")
                )
        );

        ResponseEntity<String> response = restTemplate.postForEntity(
                "/api/admin/plants",
                invalidRequest,
                String.class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    void getAllPlants_shouldReturnPlants() {
        CreatePlantRequest request = createValidRequest("plant-1");
        restTemplate.postForEntity("/api/admin/plants", request, PlantResponse.class);

        ResponseEntity<PlantSummaryResponse[]> response = restTemplate.getForEntity(
                "/api/admin/plants",
                PlantSummaryResponse[].class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).hasSize(1);
    }

    @Test
    void getPlantById_shouldReturnPlant() {
        CreatePlantRequest request = createValidRequest("plant-1");
        restTemplate.postForEntity("/api/admin/plants", request, PlantResponse.class);

        ResponseEntity<PlantResponse> response = restTemplate.getForEntity(
                "/api/admin/plants/plant-1",
                PlantResponse.class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().id()).isEqualTo("plant-1");
    }

    @Test
    void getPlantById_withInvalidId_shouldReturn404() {
        ResponseEntity<String> response = restTemplate.getForEntity(
                "/api/admin/plants/non-existent",
                String.class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
    }

    @Test
    void updatePlant_shouldModifyPlant() {
        CreatePlantRequest createRequest = createValidRequest("plant-1");
        restTemplate.postForEntity("/api/admin/plants", createRequest, PlantResponse.class);

        UpdatePlantRequest updateRequest = new UpdatePlantRequest(
                groupId,
                "Updated Plant Name",
                "Testus updatus",
                thumbnailId,
                new String[]{image2Id},
                "Updated description",
                "Large sized",
                "Toxic to cats",
                new String[]{"New benefit 1", "New benefit 2", "New benefit 3", "New benefit 4"},
                new CareGuideDto("New water", "New light", "New temp", "New humid", "New soil", "New fert"),
                Arrays.asList(
                        new IssueDto("New issue 1", "New solution 1"),
                        new IssueDto("New issue 2", "New solution 2")
                )
        );

        HttpEntity<UpdatePlantRequest> requestEntity = new HttpEntity<>(updateRequest);
        ResponseEntity<PlantResponse> response = restTemplate.exchange(
                "/api/admin/plants/plant-1",
                HttpMethod.PUT,
                requestEntity,
                PlantResponse.class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().name()).isEqualTo("Updated Plant Name");
        assertThat(response.getBody().scientificName()).isEqualTo("Testus updatus");
    }

    @Test
    void updatePlant_withInvalidId_shouldReturn404() {
        UpdatePlantRequest updateRequest = new UpdatePlantRequest(
                groupId,
                "Name",
                "Scientific",
                thumbnailId,
                new String[]{image1Id},
                "Desc",
                "Size",
                "Tox",
                new String[]{"B1", "B2", "B3", "B4"},
                new CareGuideDto("W", "L", "T", "H", "S", "F"),
                Arrays.asList(new IssueDto("I1", "S1"), new IssueDto("I2", "S2"))
        );

        HttpEntity<UpdatePlantRequest> requestEntity = new HttpEntity<>(updateRequest);
        ResponseEntity<String> response = restTemplate.exchange(
                "/api/admin/plants/non-existent",
                HttpMethod.PUT,
                requestEntity,
                String.class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
    }

    @Test
    void deletePlant_shouldReturn204() {
        CreatePlantRequest createRequest = createValidRequest("plant-1");
        restTemplate.postForEntity("/api/admin/plants", createRequest, PlantResponse.class);

        ResponseEntity<Void> response = restTemplate.exchange(
                "/api/admin/plants/plant-1",
                HttpMethod.DELETE,
                null,
                Void.class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);
        assertThat(plantRepository.findById("plant-1")).isEmpty();
    }

    @Test
    void deletePlant_withInvalidId_shouldReturn404() {
        ResponseEntity<String> response = restTemplate.exchange(
                "/api/admin/plants/non-existent",
                HttpMethod.DELETE,
                null,
                String.class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
    }

    @Test
    void createPlant_withComplexRelationships_shouldHandleIssuesAndImages() {
        CreatePlantRequest request = createValidRequest("complex-plant");

        ResponseEntity<PlantResponse> response = restTemplate.postForEntity(
                "/api/admin/plants",
                request,
                PlantResponse.class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        PlantResponse plant = response.getBody();
        assertThat(plant).isNotNull();
        assertThat(plant.commonIssues()).hasSize(2);
        assertThat(plant.imageIds()).hasSize(2);
        assertThat(plant.imageIds()).containsExactly(image1Id, image2Id);
    }
}
