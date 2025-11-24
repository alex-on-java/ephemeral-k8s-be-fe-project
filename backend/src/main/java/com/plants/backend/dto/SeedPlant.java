package com.plants.backend.dto;

import java.util.List;

/**
 * DTO for parsing plant data from seed JSON.
 * References images by filename rather than ID (IDs will be generated during seeding).
 * Contains nested care guide and common issues.
 */
public record SeedPlant(
    String id,
    String groupId,
    String name,
    String scientificName,
    String thumbnailFilename,
    List<String> imageFilenames,
    String description,
    String size,
    String toxicity,
    List<String> benefits,
    SeedCareGuide care,
    List<SeedIssue> commonIssues
) {
}
