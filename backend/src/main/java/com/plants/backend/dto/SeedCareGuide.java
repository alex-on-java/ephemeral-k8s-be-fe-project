package com.plants.backend.dto;

/**
 * DTO for parsing care guide data from seed JSON.
 */
public record SeedCareGuide(
    String watering,
    String light,
    String temperature,
    String humidity,
    String soil,
    String fertilizing
) {
}
