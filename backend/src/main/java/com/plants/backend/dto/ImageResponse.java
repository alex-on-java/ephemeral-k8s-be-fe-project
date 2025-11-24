package com.plants.backend.dto;

import java.time.LocalDateTime;

public record ImageResponse(
        String id,
        String filename,
        String contentType,
        LocalDateTime createdDate
) {
}
