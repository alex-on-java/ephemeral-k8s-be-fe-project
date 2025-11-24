package com.plants.backend.service;

import com.plants.backend.BaseIntegrationTest;
import com.plants.backend.dto.*;
import com.plants.backend.entity.Image;
import com.plants.backend.entity.PlantGroup;
import com.plants.backend.exception.ResourceNotFoundException;
import com.plants.backend.repository.ImageRepository;
import com.plants.backend.repository.PlantGroupRepository;
import com.plants.backend.repository.PlantRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class PlantServiceTest extends BaseIntegrationTest {

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
        MultipartFile file = new MockMultipartFile(
                "file",
                filename,
                "image/jpeg",
                "test image content".getBytes()
        );
        ImageResponse response = imageService.uploadImage(file);
        return response.id();
    }

    private CreatePlantRequest createValidPlantRequest() {
        CareGuideDto care = new CareGuideDto(
                "Water weekly",
                "Bright indirect light",
                "18-24°C",
                "50-60%",
                "Well-draining soil",
                "Monthly in growing season"
        );

        List<IssueDto> issues = Arrays.asList(
                new IssueDto("Yellow leaves", "Reduce watering"),
                new IssueDto("Brown tips", "Increase humidity")
        );

        return new CreatePlantRequest(
                "test-plant",
                groupId,
                "Test Plant",
                "Testus plantus",
                thumbnailId,
                new String[]{image1Id, image2Id},
                "A wonderful test plant",
                "Small to medium",
                "Non-toxic to pets",
                new String[]{"Easy care", "Air purifying", "Low light", "Pet safe"},
                care,
                issues
        );
    }

    @Test
    void createPlant_withValidData_shouldSucceed() {
        CreatePlantRequest request = createValidPlantRequest();

        PlantResponse response = plantService.createPlant(request);

        assertThat(response).isNotNull();
        assertThat(response.id()).isEqualTo("test-plant");
        assertThat(response.name()).isEqualTo("Test Plant");
        assertThat(response.groupId()).isEqualTo(groupId);
        assertThat(response.thumbnailId()).isEqualTo(thumbnailId);
        assertThat(response.imageIds()).containsExactly(image1Id, image2Id);
        assertThat(response.benefits()).hasSize(4);
        assertThat(response.care()).isNotNull();
        assertThat(response.commonIssues()).hasSize(2);
    }

    @Test
    void createPlant_withDuplicateId_shouldThrowException() {
        CreatePlantRequest request = createValidPlantRequest();
        plantService.createPlant(request);

        assertThatThrownBy(() -> plantService.createPlant(request))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("already exists");
    }

    @Test
    void createPlant_withInvalidGroupId_shouldThrowException() {
        CreatePlantRequest request = createValidPlantRequest();
        CreatePlantRequest invalidRequest = new CreatePlantRequest(
                "test-plant-2",
                "non-existent-group",
                request.name(),
                request.scientificName(),
                request.thumbnailId(),
                request.imageIds(),
                request.description(),
                request.size(),
                request.toxicity(),
                request.benefits(),
                request.care(),
                request.commonIssues()
        );

        assertThatThrownBy(() -> plantService.createPlant(invalidRequest))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Plant group not found");
    }

    @Test
    void createPlant_withInvalidThumbnailId_shouldThrowException() {
        CreatePlantRequest request = createValidPlantRequest();
        CreatePlantRequest invalidRequest = new CreatePlantRequest(
                "test-plant-2",
                request.groupId(),
                request.name(),
                request.scientificName(),
                "non-existent-thumbnail",
                request.imageIds(),
                request.description(),
                request.size(),
                request.toxicity(),
                request.benefits(),
                request.care(),
                request.commonIssues()
        );

        assertThatThrownBy(() -> plantService.createPlant(invalidRequest))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Thumbnail image not found");
    }

    @Test
    void createPlant_withInvalidImageId_shouldThrowException() {
        CreatePlantRequest request = createValidPlantRequest();
        CreatePlantRequest invalidRequest = new CreatePlantRequest(
                "test-plant-2",
                request.groupId(),
                request.name(),
                request.scientificName(),
                request.thumbnailId(),
                new String[]{image1Id, "non-existent-image"},
                request.description(),
                request.size(),
                request.toxicity(),
                request.benefits(),
                request.care(),
                request.commonIssues()
        );

        assertThatThrownBy(() -> plantService.createPlant(invalidRequest))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Image not found");
    }

    @Test
    void getAllPlants_shouldReturnAllPlants() {
        plantService.createPlant(createValidPlantRequest());

        List<PlantSummaryResponse> plants = plantService.getAllPlants();

        assertThat(plants).hasSize(1);
        assertThat(plants.get(0).id()).isEqualTo("test-plant");
    }

    @Test
    void getPlantsByGroup_shouldReturnFilteredPlants() {
        plantService.createPlant(createValidPlantRequest());

        List<PlantSummaryResponse> plants = plantService.getPlantsByGroup(groupId);

        assertThat(plants).hasSize(1);
        assertThat(plants.get(0).id()).isEqualTo("test-plant");
    }

    @Test
    void getPlantsByGroup_withInvalidGroupId_shouldThrowException() {
        assertThatThrownBy(() -> plantService.getPlantsByGroup("non-existent"))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Plant group not found");
    }

    @Test
    void getPlantById_shouldReturnPlant() {
        plantService.createPlant(createValidPlantRequest());

        PlantResponse plant = plantService.getPlantById("test-plant");

        assertThat(plant).isNotNull();
        assertThat(plant.id()).isEqualTo("test-plant");
    }

    @Test
    void getPlantById_withInvalidId_shouldThrowException() {
        assertThatThrownBy(() -> plantService.getPlantById("non-existent"))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Plant not found");
    }

    @Test
    void updatePlant_shouldModifyPlant() {
        plantService.createPlant(createValidPlantRequest());

        CareGuideDto updatedCare = new CareGuideDto(
                "Water twice weekly",
                "Full sun",
                "20-26°C",
                "40-50%",
                "Sandy soil",
                "Bi-weekly"
        );

        List<IssueDto> updatedIssues = Arrays.asList(
                new IssueDto("Wilting", "Water more"),
                new IssueDto("Drooping", "Check roots")
        );

        UpdatePlantRequest updateRequest = new UpdatePlantRequest(
                groupId,
                "Updated Test Plant",
                "Testus updatus",
                thumbnailId,
                new String[]{image2Id},
                "Updated description",
                "Large",
                "Toxic to cats",
                new String[]{"Updated 1", "Updated 2", "Updated 3", "Updated 4"},
                updatedCare,
                updatedIssues
        );

        PlantResponse updated = plantService.updatePlant("test-plant", updateRequest);

        assertThat(updated.name()).isEqualTo("Updated Test Plant");
        assertThat(updated.scientificName()).isEqualTo("Testus updatus");
        assertThat(updated.imageIds()).containsExactly(image2Id);
        assertThat(updated.commonIssues()).hasSize(2);
    }

    @Test
    void updatePlant_withInvalidId_shouldThrowException() {
        UpdatePlantRequest request = new UpdatePlantRequest(
                groupId,
                "Test",
                "Test",
                thumbnailId,
                new String[]{image1Id},
                "Desc",
                "Size",
                "Tox",
                new String[]{"B1", "B2", "B3", "B4"},
                new CareGuideDto("W", "L", "T", "H", "S", "F"),
                Arrays.asList(new IssueDto("I1", "S1"), new IssueDto("I2", "S2"))
        );

        assertThatThrownBy(() -> plantService.updatePlant("non-existent", request))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Plant not found");
    }

    @Test
    void deletePlant_shouldRemovePlant() {
        plantService.createPlant(createValidPlantRequest());

        plantService.deletePlant("test-plant");

        assertThat(plantRepository.findById("test-plant")).isEmpty();
    }

    @Test
    void deletePlant_withInvalidId_shouldThrowException() {
        assertThatThrownBy(() -> plantService.deletePlant("non-existent"))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Plant not found");
    }
}
