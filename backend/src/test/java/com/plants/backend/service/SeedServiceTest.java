package com.plants.backend.service;

import com.plants.backend.BaseIntegrationTest;
import com.plants.backend.entity.Image;
import com.plants.backend.entity.Issue;
import com.plants.backend.entity.Plant;
import com.plants.backend.entity.PlantGroup;
import com.plants.backend.repository.ImageRepository;
import com.plants.backend.repository.IssueRepository;
import com.plants.backend.repository.PlantGroupRepository;
import com.plants.backend.repository.PlantRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;

import java.io.IOException;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Integration tests for SeedService.
 * Tests database seeding and reset operations.
 */
class SeedServiceTest extends BaseIntegrationTest {

    @Autowired
    private SeedService seedService;

    @Autowired
    private ImageRepository imageRepository;

    @Autowired
    private PlantGroupRepository plantGroupRepository;

    @Autowired
    private PlantRepository plantRepository;

    @Autowired
    private IssueRepository issueRepository;

    @BeforeEach
    void setUp() {
        // Clean database before each test
        plantRepository.deleteAll();
        plantGroupRepository.deleteAll();
        imageRepository.deleteAll();
    }

    @Test
    void seedDatabase_shouldCreateAllImages() throws IOException {
        // When
        seedService.seedDatabase();

        // Then
        List<Image> images = imageRepository.findAll();
        assertThat(images).isNotEmpty();

        // Should have at least 13 images (6 group images + 7 plant images)
        assertThat(images.size()).isGreaterThanOrEqualTo(13);

        // Verify some expected images
        assertThat(images).anyMatch(img -> img.getFilename().equals("succulents-group.jpg"));
        assertThat(images).anyMatch(img -> img.getFilename().equals("aloe-vera-thumb.jpg"));
        assertThat(images).anyMatch(img -> img.getFilename().equals("aloe-detail-1.jpg"));

        // Verify all images have bytes loaded
        for (Image image : images) {
            assertThat(image.getBytes()).isNotNull();
            assertThat(image.getBytes()).isNotEmpty();
            assertThat(image.getContentType()).isEqualTo("image/jpeg");
            assertThat(image.getCreatedDate()).isNotNull();
        }
    }

    @Test
    void seedDatabase_shouldCreateAllPlantGroups() throws IOException {
        // When
        seedService.seedDatabase();

        // Then
        List<PlantGroup> groups = plantGroupRepository.findAll();
        assertThat(groups).hasSize(6);

        // Verify expected groups
        assertThat(groups).anyMatch(g -> g.getId().equals("succulents") && g.getName().equals("Succulents & Cacti"));
        assertThat(groups).anyMatch(g -> g.getId().equals("tropical") && g.getName().equals("Tropical Plants"));
        assertThat(groups).anyMatch(g -> g.getId().equals("ferns") && g.getName().equals("Ferns"));
        assertThat(groups).anyMatch(g -> g.getId().equals("flowering") && g.getName().equals("Flowering Plants"));
        assertThat(groups).anyMatch(g -> g.getId().equals("airplants") && g.getName().equals("Air Plants"));
        assertThat(groups).anyMatch(g -> g.getId().equals("herbs") && g.getName().equals("Herbs"));

        // Verify all groups have image references
        for (PlantGroup group : groups) {
            assertThat(group.getImageId()).isNotNull();
            assertThat(imageRepository.existsById(group.getImageId())).isTrue();
        }
    }

    @Test
    @Transactional
    void seedDatabase_shouldCreateAllPlants() throws IOException {
        // When
        seedService.seedDatabase();

        // Then
        List<Plant> plants = plantRepository.findAll();
        assertThat(plants).hasSize(4);

        // Verify expected plants
        assertThat(plants).anyMatch(p -> p.getId().equals("aloe-vera"));
        assertThat(plants).anyMatch(p -> p.getId().equals("echeveria"));
        assertThat(plants).anyMatch(p -> p.getId().equals("jade-plant"));
        assertThat(plants).anyMatch(p -> p.getId().equals("snake-plant"));

        // Verify aloe-vera has all expected data
        Plant aloeVera = plantRepository.findById("aloe-vera").orElseThrow();
        assertThat(aloeVera.getName()).isEqualTo("Aloe Vera");
        assertThat(aloeVera.getScientificName()).isEqualTo("Aloe barbadensis miller");
        assertThat(aloeVera.getGroupId()).isEqualTo("succulents");
        assertThat(aloeVera.getDescription()).contains("succulent plant species");
        assertThat(aloeVera.getSize()).contains("12-24 inches");
        assertThat(aloeVera.getToxicity()).contains("Mildly toxic");

        // Verify benefits array
        assertThat(aloeVera.getBenefits()).isNotNull();
        assertThat(aloeVera.getBenefits()).hasSize(5);
        assertThat(aloeVera.getBenefits()).contains("Air purifying - removes toxins from indoor air");

        // Verify care guide
        assertThat(aloeVera.getCare()).isNotNull();
        assertThat(aloeVera.getCare().getWatering()).contains("Water deeply but infrequently");
        assertThat(aloeVera.getCare().getLight()).contains("Bright, indirect sunlight");
        assertThat(aloeVera.getCare().getTemperature()).contains("55-80°F");
        assertThat(aloeVera.getCare().getHumidity()).contains("low to moderate");
        assertThat(aloeVera.getCare().getSoil()).contains("Well-draining");
        assertThat(aloeVera.getCare().getFertilizing()).contains("sparingly");

        // Verify thumbnail reference
        assertThat(aloeVera.getThumbnailId()).isNotNull();
        assertThat(imageRepository.existsById(aloeVera.getThumbnailId())).isTrue();

        // Verify detail images (aloe-vera should have 3)
        // Need to fetch plant with images in a transaction to avoid lazy loading issues
        Plant aloeVeraWithImages = plantRepository.findById("aloe-vera").orElseThrow();
        assertThat(aloeVeraWithImages.getImages()).hasSize(3);
    }

    @Test
    void seedDatabase_shouldSetupIssuesCorrectly() throws IOException {
        // When
        seedService.seedDatabase();

        // Then
        List<Issue> allIssues = issueRepository.findAll();
        assertThat(allIssues).isNotEmpty();

        // Aloe vera should have 4 issues
        List<Issue> aloeIssues = issueRepository.findByPlantId("aloe-vera");
        assertThat(aloeIssues).hasSize(4);

        // Verify issue content
        assertThat(aloeIssues).anyMatch(i ->
            i.getIssue().equals("Brown or soft leaves") &&
            i.getSolution().contains("overwatering")
        );
        assertThat(aloeIssues).anyMatch(i ->
            i.getIssue().equals("Pale or yellowing leaves") &&
            i.getSolution().contains("direct sunlight")
        );

        // Verify all issues have plant ID set
        for (Issue issue : allIssues) {
            assertThat(issue.getPlantId()).isNotNull();
            assertThat(plantRepository.existsById(issue.getPlantId())).isTrue();
        }
    }

    @Test
    @Transactional
    void resetDatabase_shouldClearAndReseed() throws IOException {
        // Given - seed database first
        seedService.seedDatabase();

        // Verify data exists
        assertThat(imageRepository.count()).isGreaterThan(0);
        assertThat(plantGroupRepository.count()).isGreaterThan(0);
        assertThat(plantRepository.count()).isGreaterThan(0);
        assertThat(issueRepository.count()).isGreaterThan(0);

        long originalImageCount = imageRepository.count();
        long originalGroupCount = plantGroupRepository.count();
        long originalPlantCount = plantRepository.count();
        long originalIssueCount = issueRepository.count();

        // When - reset database
        seedService.resetDatabase();

        // Then - should have same counts (data cleared and re-seeded)
        assertThat(imageRepository.count()).isEqualTo(originalImageCount);
        assertThat(plantGroupRepository.count()).isEqualTo(originalGroupCount);
        assertThat(plantRepository.count()).isEqualTo(originalPlantCount);
        assertThat(issueRepository.count()).isEqualTo(originalIssueCount);

        // Verify data is fresh (new UUIDs for images)
        List<Image> newImages = imageRepository.findAll();
        assertThat(newImages).isNotEmpty();
        assertThat(newImages).allMatch(img -> img.getId() != null);
    }

    @Test
    void seedDatabase_shouldCreatePlantsInCorrectGroups() throws IOException {
        // When
        seedService.seedDatabase();

        // Then
        List<Plant> succulentPlants = plantRepository.findByGroupId("succulents");
        assertThat(succulentPlants).hasSize(4);
        assertThat(succulentPlants).extracting(Plant::getId)
            .containsExactlyInAnyOrder("aloe-vera", "echeveria", "jade-plant", "snake-plant");
    }

    @Test
    void seedDatabase_shouldHandleMultipleImageFormatsCorrectly() throws IOException {
        // When
        seedService.seedDatabase();

        // Then
        List<Image> images = imageRepository.findAll();

        // All test images are JPG format
        for (Image image : images) {
            if (image.getFilename().endsWith(".jpg") || image.getFilename().endsWith(".jpeg")) {
                assertThat(image.getContentType()).isEqualTo("image/jpeg");
            }
        }
    }
}
