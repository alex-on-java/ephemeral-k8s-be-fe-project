package com.plants.backend.dto;

/**
 * DTO for parsing common issue data from seed JSON.
 */
public record SeedIssue(
    String issue,
    String solution
) {
}
