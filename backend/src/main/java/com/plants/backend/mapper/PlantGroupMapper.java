package com.plants.backend.mapper;

import com.plants.backend.dto.CreatePlantGroupRequest;
import com.plants.backend.dto.PlantGroupResponse;
import com.plants.backend.dto.UpdatePlantGroupRequest;
import com.plants.backend.entity.PlantGroup;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;

/**
 * MapStruct mapper for PlantGroup entity and DTOs.
 */
@Mapper(componentModel = "spring")
public interface PlantGroupMapper {

    PlantGroupResponse toResponse(PlantGroup plantGroup);

    @Mapping(target = "image", ignore = true)
    PlantGroup toEntity(CreatePlantGroupRequest request);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "image", ignore = true)
    void updateEntityFromRequest(UpdatePlantGroupRequest request, @MappingTarget PlantGroup plantGroup);
}