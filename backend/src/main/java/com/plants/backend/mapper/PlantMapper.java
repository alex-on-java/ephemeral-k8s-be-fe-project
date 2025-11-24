package com.plants.backend.mapper;

import com.plants.backend.dto.*;
import com.plants.backend.entity.CareGuide;
import com.plants.backend.entity.Image;
import com.plants.backend.entity.Issue;
import com.plants.backend.entity.Plant;
import org.mapstruct.*;

import java.util.List;
import java.util.stream.Collectors;

/**
 * MapStruct mapper for Plant entity and DTOs.
 */
@Mapper(componentModel = "spring")
public interface PlantMapper {

    /**
     * Convert Plant entity to PlantResponse DTO.
     */
    @Mapping(target = "imageIds", source = "images")
    @Mapping(target = "care", source = "care")
    @Mapping(target = "commonIssues", source = "commonIssues")
    PlantResponse toResponse(Plant plant);

    /**
     * Convert Plant entity to PlantSummaryResponse DTO.
     */
    PlantSummaryResponse toSummaryResponse(Plant plant);

    /**
     * Convert CareGuide entity to CareGuideDto.
     */
    CareGuideDto toCareGuideDto(CareGuide careGuide);

    /**
     * Convert CareGuideDto to CareGuide entity.
     */
    CareGuide toCareGuide(CareGuideDto dto);

    /**
     * Convert Issue entity to IssueDto.
     */
    @Mapping(target = "issue", source = "issue")
    @Mapping(target = "solution", source = "solution")
    IssueDto toIssueDto(Issue issue);

    /**
     * Convert IssueDto to Issue entity.
     */
    @Mapping(target = "id", ignore = true)
    @Mapping(target = "plantId", ignore = true)
    @Mapping(target = "plant", ignore = true)
    Issue toIssue(IssueDto dto);

    /**
     * Convert list of Issue entities to list of IssueDtos.
     */
    List<IssueDto> toIssueDtos(List<Issue> issues);

    /**
     * Convert list of IssueDtos to list of Issue entities.
     */
    List<Issue> toIssues(List<IssueDto> dtos);

    /**
     * Convert list of Image entities to array of image IDs.
     */
    default String[] mapImagesToIds(List<Image> images) {
        if (images == null || images.isEmpty()) {
            return new String[0];
        }
        return images.stream()
                .map(Image::getId)
                .toArray(String[]::new);
    }

    /**
     * Convert CreatePlantRequest to Plant entity.
     * Note: Images list will be populated by service layer.
     */
    @Mapping(target = "images", ignore = true)
    @Mapping(target = "commonIssues", ignore = true)
    @Mapping(target = "group", ignore = true)
    @Mapping(target = "thumbnail", ignore = true)
    Plant toEntity(CreatePlantRequest request);

    /**
     * Update Plant entity from UpdatePlantRequest.
     */
    @Mapping(target = "id", ignore = true)
    @Mapping(target = "images", ignore = true)
    @Mapping(target = "commonIssues", ignore = true)
    @Mapping(target = "group", ignore = true)
    @Mapping(target = "thumbnail", ignore = true)
    void updateEntityFromRequest(UpdatePlantRequest request, @MappingTarget Plant plant);
}
