package com.plants.backend.mapper;

import com.plants.backend.dto.ImageResponse;
import com.plants.backend.entity.Image;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface ImageMapper {

    ImageResponse toResponse(Image image);
}
