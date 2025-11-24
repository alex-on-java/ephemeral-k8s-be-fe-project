package com.plants.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * DTO for plant issue and solution information.
 */
public record IssueDto(
    @NotBlank(message = "Issue description is required")
    @Size(max = 5000, message = "Issue description must not exceed 5000 characters")
    String issue,

    @NotBlank(message = "Solution is required")
    @Size(max = 5000, message = "Solution must not exceed 5000 characters")
    String solution
) {}
