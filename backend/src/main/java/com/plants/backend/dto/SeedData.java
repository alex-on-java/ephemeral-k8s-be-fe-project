package com.plants.backend.dto;

import java.util.List;

/**
 * Root DTO for parsing seed data JSON file.
 * Contains lists of plant groups and plants to be loaded into the database.
 */
public record SeedData(
    List<SeedPlantGroup> plantGroups,
    List<SeedPlant> plants
) {
}
