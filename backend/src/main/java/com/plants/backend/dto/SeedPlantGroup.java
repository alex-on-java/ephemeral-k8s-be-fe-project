package com.plants.backend.dto;

/**
 * DTO for parsing plant group data from seed JSON.
 * References image by filename rather than ID (ID will be generated during seeding).
 */
public record SeedPlantGroup(
    String id,
    String name,
    String imageFilename
) {
}
