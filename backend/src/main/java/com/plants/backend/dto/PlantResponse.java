package com.plants.backend.dto;

import java.util.List;

/**
 * Response DTO for complete plant details.
 */
public record PlantResponse(
    String id,
    String groupId,
    String name,
    String scientificName,
    String thumbnailId,
    String[] imageIds,
    String description,
    String size,
    String toxicity,
    String[] benefits,
    CareGuideDto care,
    List<IssueDto> commonIssues
) {}
