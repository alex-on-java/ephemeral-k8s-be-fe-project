package com.plants.backend.service;

import com.plants.backend.dto.ImageResponse;
import com.plants.backend.entity.Image;
import com.plants.backend.exception.ResourceNotFoundException;
import com.plants.backend.mapper.ImageMapper;
import com.plants.backend.repository.ImageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ImageService {

    private final ImageRepository imageRepository;
    private final ImageMapper imageMapper;

    @Transactional
    public ImageResponse uploadImage(MultipartFile file) {
        validateImageFile(file);

        try {
            Image image = new Image();
            image.setId(UUID.randomUUID().toString());
            image.setFilename(file.getOriginalFilename());
            image.setContentType(file.getContentType());
            image.setBytes(file.getBytes());
            image.setCreatedDate(LocalDateTime.now());

            Image savedImage = imageRepository.save(image);
            return imageMapper.toResponse(savedImage);
        } catch (IOException e) {
            throw new IllegalArgumentException("Failed to read image file: " + e.getMessage(), e);
        }
    }

    @Transactional(readOnly = true)
    public Image getImageById(String id) {
        return imageRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Image not found with id: " + id));
    }

    @Transactional(readOnly = true)
    public java.util.List<ImageResponse> getAllImages() {
        return imageRepository.findAll().stream()
                .map(imageMapper::toResponse)
                .toList();
    }

    @Transactional
    public void deleteImage(String id) {
        if (!imageRepository.existsById(id)) {
            throw new ResourceNotFoundException("Image not found with id: " + id);
        }
        imageRepository.deleteById(id);
    }

    private void validateImageFile(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Image file cannot be empty");
        }

        String contentType = file.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            throw new IllegalArgumentException("File must be an image (content type: image/*)");
        }
    }
}
