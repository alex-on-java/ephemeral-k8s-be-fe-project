package com.plants.backend.dto;

/**
 * Lightweight response DTO for plant list views.
 * Contains only essential information without detailed care instructions.
 */
public record PlantSummaryResponse(
    String id,
    String name,
    String scientificName,
    String thumbnailId
) {}
