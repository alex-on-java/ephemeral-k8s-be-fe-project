package com.plants.backend.service;

import com.plants.backend.BaseIntegrationTest;
import com.plants.backend.dto.CreatePlantGroupRequest;
import com.plants.backend.dto.PlantGroupResponse;
import com.plants.backend.dto.UpdatePlantGroupRequest;
import com.plants.backend.entity.Image;
import com.plants.backend.exception.ResourceNotFoundException;
import com.plants.backend.repository.ImageRepository;
import com.plants.backend.repository.PlantGroupRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;

class PlantGroupServiceTest extends BaseIntegrationTest {

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
    void createGroup_shouldCreateNewGroup() {
        // Given
        CreatePlantGroupRequest request = new CreatePlantGroupRequest(
                "succulents",
                "Succulents & Cacti",
                testImageId
        );

        // When
        PlantGroupResponse response = plantGroupService.createGroup(request);

        // Then
        assertThat(response).isNotNull();
        assertThat(response.id()).isEqualTo("succulents");
        assertThat(response.name()).isEqualTo("Succulents & Cacti");
        assertThat(response.imageId()).isEqualTo(testImageId);

        assertThat(plantGroupRepository.existsById("succulents")).isTrue();
    }

    @Test
    void createGroup_shouldRejectDuplicateId() {
        // Given
        CreatePlantGroupRequest request = new CreatePlantGroupRequest(
                "succulents",
                "Succulents & Cacti",
                testImageId
        );
        plantGroupService.createGroup(request);

        // When/Then
        assertThatThrownBy(() -> plantGroupService.createGroup(request))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("already exists");
    }

    @Test
    void createGroup_shouldRejectInvalidImageId() {
        // Given
        CreatePlantGroupRequest request = new CreatePlantGroupRequest(
                "succulents",
                "Succulents & Cacti",
                "invalid-image-id"
        );

        // When/Then
        assertThatThrownBy(() -> plantGroupService.createGroup(request))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Image not found");
    }

    @Test
    void getAllGroups_shouldReturnAllGroups() {
        // Given
        plantGroupService.createGroup(new CreatePlantGroupRequest(
                "succulents", "Succulents & Cacti", testImageId));
        plantGroupService.createGroup(new CreatePlantGroupRequest(
                "tropical", "Tropical Plants", testImageId));

        // When
        List<PlantGroupResponse> groups = plantGroupService.getAllGroups();

        // Then
        assertThat(groups).hasSize(2);
        assertThat(groups).extracting(PlantGroupResponse::id)
                .containsExactlyInAnyOrder("succulents", "tropical");
    }

    @Test
    void getGroupById_shouldReturnGroup() {
        // Given
        plantGroupService.createGroup(new CreatePlantGroupRequest(
                "succulents", "Succulents & Cacti", testImageId));

        // When
        PlantGroupResponse response = plantGroupService.getGroupById("succulents");

        // Then
        assertThat(response).isNotNull();
        assertThat(response.id()).isEqualTo("succulents");
        assertThat(response.name()).isEqualTo("Succulents & Cacti");
    }

    @Test
    void getGroupById_shouldThrow404ForNonExistent() {
        // When/Then
        assertThatThrownBy(() -> plantGroupService.getGroupById("non-existent"))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Plant group not found");
    }

    @Test
    void updateGroup_shouldUpdateExistingGroup() {
        // Given
        plantGroupService.createGroup(new CreatePlantGroupRequest(
                "succulents", "Succulents & Cacti", testImageId));
        UpdatePlantGroupRequest updateRequest = new UpdatePlantGroupRequest(
                "Desert Plants", null);

        // When
        PlantGroupResponse response = plantGroupService.updateGroup("succulents", updateRequest);

        // Then
        assertThat(response.name()).isEqualTo("Desert Plants");
        assertThat(response.imageId()).isNull();
    }

    @Test
    void updateGroup_shouldThrow404ForNonExistent() {
        // Given
        UpdatePlantGroupRequest request = new UpdatePlantGroupRequest(
                "New Name", testImageId);

        // When/Then
        assertThatThrownBy(() -> plantGroupService.updateGroup("non-existent", request))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Plant group not found");
    }

    @Test
    void deleteGroup_shouldRemoveGroup() {
        // Given
        plantGroupService.createGroup(new CreatePlantGroupRequest(
                "succulents", "Succulents & Cacti", testImageId));

        // When
        plantGroupService.deleteGroup("succulents");

        // Then
        assertThat(plantGroupRepository.existsById("succulents")).isFalse();
    }

    @Test
    void deleteGroup_shouldThrow404ForNonExistent() {
        // When/Then
        assertThatThrownBy(() -> plantGroupService.deleteGroup("non-existent"))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Plant group not found");
    }
}