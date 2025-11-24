package com.plants.backend.dto;

public record ValidationError(
        String field,
        String message
) {
}
