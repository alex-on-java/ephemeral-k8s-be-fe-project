package com.plants.backend.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.plants.backend.dto.*;
import com.plants.backend.entity.*;
import com.plants.backend.repository.ImageRepository;
import com.plants.backend.repository.IssueRepository;
import com.plants.backend.repository.PlantGroupRepository;
import com.plants.backend.repository.PlantRepository;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.*;

/**
 * Service for seeding the database with initial plant data.
 * Loads images and plant data from classpath resources.
 */
@Service
@Transactional
public class SeedService {

    private final ResourceLoader resourceLoader;
    private final ObjectMapper objectMapper;
    private final ImageRepository imageRepository;
    private final PlantGroupRepository plantGroupRepository;
    private final PlantRepository plantRepository;
    private final IssueRepository issueRepository;

    public SeedService(
            ResourceLoader resourceLoader,
            ObjectMapper objectMapper,
            ImageRepository imageRepository,
            PlantGroupRepository plantGroupRepository,
            PlantRepository plantRepository,
            IssueRepository issueRepository
    ) {
        this.resourceLoader = resourceLoader;
        this.objectMapper = objectMapper;
        this.imageRepository = imageRepository;
        this.plantGroupRepository = plantGroupRepository;
        this.plantRepository = plantRepository;
        this.issueRepository = issueRepository;
    }

    /**
     * Seeds the database with plant data from classpath resources.
     * Loads images and creates plant groups and plants with all relationships.
     *
     * @throws IOException if resource loading or parsing fails
     */
    public void seedDatabase() throws IOException {
        // 1. Load and parse plants-data.json
        Resource dataResource = resourceLoader.getResource("classpath:seed-data/plants-data.json");
        SeedData seedData = objectMapper.readValue(dataResource.getInputStream(), SeedData.class);

        // 2. Load all images and create mapping from filename to UUID
        Map<String, String> filenameToIdMap = loadImages(seedData);

        // 3. Create plant groups with image references
        createPlantGroups(seedData.plantGroups(), filenameToIdMap);

        // 4. Create plants with all relationships
        createPlants(seedData.plants(), filenameToIdMap);
    }

    /**
     * Resets the database by deleting all data and re-seeding.
     *
     * @throws IOException if seeding fails
     */
    public void resetDatabase() throws IOException {
        // Delete all data (in correct order due to foreign keys)
        // Issues and plant-image relationships are cascaded from plants
        plantRepository.deleteAll();
        plantGroupRepository.deleteAll();
        imageRepository.deleteAll();

        // Re-seed
        seedDatabase();
    }

    /**
     * Loads all image files from classpath and stores them in the database.
     * Returns a mapping from filename to generated UUID.
     */
    private Map<String, String> loadImages(SeedData seedData) throws IOException {
        Map<String, String> filenameToId = new HashMap<>();
        Set<String> allImageFilenames = collectAllImageFilenames(seedData);

        for (String filename : allImageFilenames) {
            // Load image from classpath
            Resource imageResource = resourceLoader.getResource(
                    "classpath:seed-data/images/" + filename
            );

            if (!imageResource.exists()) {
                throw new IOException("Image file not found: " + filename);
            }

            // Read bytes
            byte[] bytes = imageResource.getInputStream().readAllBytes();

            // Determine content type from filename
            String contentType = getContentType(filename);

            // Create and save Image entity
            Image image = new Image();
            image.setId(UUID.randomUUID().toString());
            image.setFilename(filename);
            image.setContentType(contentType);
            image.setBytes(bytes);
            image.setCreatedDate(LocalDateTime.now());

            imageRepository.save(image);
            filenameToId.put(filename, image.getId());
        }

        // Flush to ensure all images are persisted before creating relationships
        imageRepository.flush();

        return filenameToId;
    }

    /**
     * Collects all unique image filenames referenced in the seed data.
     */
    private Set<String> collectAllImageFilenames(SeedData seedData) {
        Set<String> filenames = new HashSet<>();

        // Collect group images
        for (SeedPlantGroup group : seedData.plantGroups()) {
            if (group.imageFilename() != null) {
                filenames.add(group.imageFilename());
            }
        }

        // Collect plant images (thumbnails and detail images)
        for (SeedPlant plant : seedData.plants()) {
            if (plant.thumbnailFilename() != null) {
                filenames.add(plant.thumbnailFilename());
            }
            if (plant.imageFilenames() != null) {
                filenames.addAll(plant.imageFilenames());
            }
        }

        return filenames;
    }

    /**
     * Determines content type from file extension.
     */
    private String getContentType(String filename) {
        String extension = filename.substring(filename.lastIndexOf('.') + 1).toLowerCase();
        return switch (extension) {
            case "jpg", "jpeg" -> "image/jpeg";
            case "png" -> "image/png";
            case "gif" -> "image/gif";
            case "webp" -> "image/webp";
            default -> "application/octet-stream";
        };
    }

    /**
     * Creates plant groups with image references.
     */
    private void createPlantGroups(List<SeedPlantGroup> seedGroups, Map<String, String> filenameToIdMap) {
        for (SeedPlantGroup seedGroup : seedGroups) {
            PlantGroup group = new PlantGroup();
            group.setId(seedGroup.id());
            group.setName(seedGroup.name());

            // Resolve image ID from filename
            if (seedGroup.imageFilename() != null) {
                String imageId = filenameToIdMap.get(seedGroup.imageFilename());
                group.setImageId(imageId);
            }

            plantGroupRepository.save(group);
        }

        // Flush to ensure all groups are persisted
        plantGroupRepository.flush();
    }

    /**
     * Creates plants with all relationships (issues, images, care guide).
     */
    private void createPlants(List<SeedPlant> seedPlants, Map<String, String> filenameToIdMap) {
        for (SeedPlant seedPlant : seedPlants) {
            Plant plant = new Plant();
            plant.setId(seedPlant.id());
            plant.setGroupId(seedPlant.groupId());
            plant.setName(seedPlant.name());
            plant.setScientificName(seedPlant.scientificName());
            plant.setDescription(seedPlant.description());
            plant.setSize(seedPlant.size());
            plant.setToxicity(seedPlant.toxicity());

            // Convert benefits list to array
            if (seedPlant.benefits() != null) {
                plant.setBenefits(seedPlant.benefits().toArray(new String[0]));
            }

            // Resolve thumbnail ID
            if (seedPlant.thumbnailFilename() != null) {
                String thumbnailId = filenameToIdMap.get(seedPlant.thumbnailFilename());
                plant.setThumbnailId(thumbnailId);
            }

            // Create embedded care guide
            if (seedPlant.care() != null) {
                SeedCareGuide seedCare = seedPlant.care();
                CareGuide care = new CareGuide();
                care.setWatering(seedCare.watering());
                care.setLight(seedCare.light());
                care.setTemperature(seedCare.temperature());
                care.setHumidity(seedCare.humidity());
                care.setSoil(seedCare.soil());
                care.setFertilizing(seedCare.fertilizing());
                plant.setCare(care);
            }

            // Resolve detail image IDs and add to plant
            if (seedPlant.imageFilenames() != null) {
                List<Image> detailImages = new ArrayList<>();
                for (String filename : seedPlant.imageFilenames()) {
                    String imageId = filenameToIdMap.get(filename);
                    if (imageId != null) {
                        // Create a reference to the image (JPA will manage the relationship)
                        Image imageRef = imageRepository.getReferenceById(imageId);
                        detailImages.add(imageRef);
                    }
                }
                plant.setImages(detailImages);
            }

            // Create issues (will be saved via cascade when plant is saved)
            if (seedPlant.commonIssues() != null) {
                for (SeedIssue seedIssue : seedPlant.commonIssues()) {
                    Issue issue = new Issue();
                    issue.setPlantId(plant.getId());
                    issue.setIssue(seedIssue.issue());
                    issue.setSolution(seedIssue.solution());
                    plant.getCommonIssues().add(issue);
                }
            }

            // Save plant (cascades to issues and images relationships)
            plantRepository.save(plant);
        }
    }
}
