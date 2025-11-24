/**
 * API client for admin endpoints.
 * Handles all HTTP communication with the backend.
 */

import {
  ApiError,
  CreatePlantGroupRequest,
  CreatePlantRequest,
  ErrorResponse,
  ImageResponse,
  PlantGroupResponse,
  PlantResponse,
  PlantSummaryResponse,
  UpdatePlantGroupRequest,
  UpdatePlantRequest,
  UploadImageResponse,
} from '@/types/api';

// ============================================================================
// Configuration
// ============================================================================

/**
 * Get backend API base URL from environment variable.
 * Empty string for local development (uses Vite proxy).
 * Set to full URL for production builds.
 */
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || "";
const ADMIN_BASE = `${API_BASE_URL}/api/admin`;

// ============================================================================
// HTTP Client Utilities
// ============================================================================

/**
 * Parse error response from backend.
 */
const parseErrorResponse = async (response: Response): Promise<ApiError> => {
  try {
    const errorData: ErrorResponse = await response.json();
    return new ApiError(
      errorData.message || 'An error occurred',
      response.status,
      errorData
    );
  } catch {
    // If JSON parsing fails, create generic error
    return new ApiError(
      `HTTP ${response.status}: ${response.statusText}`,
      response.status
    );
  }
};

/**
 * Make HTTP request with error handling.
 */
const fetchWithErrorHandling = async <T>(
  url: string,
  options?: RequestInit
): Promise<T> => {
  try {
    const response = await fetch(url, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...options?.headers,
      },
    });

    if (!response.ok) {
      throw await parseErrorResponse(response);
    }

    // Handle 204 No Content (delete operations)
    if (response.status === 204) {
      return undefined as T;
    }

    return await response.json();
  } catch (error) {
    if (error instanceof ApiError) {
      throw error;
    }
    // Network error or other unexpected error
    throw new ApiError(
      error instanceof Error ? error.message : 'Network error',
      0
    );
  }
};

// ============================================================================
// Plant Groups API
// ============================================================================

/**
 * Get all plant groups.
 * GET /api/admin/plant-groups
 */
export const getPlantGroups = async (): Promise<PlantGroupResponse[]> => {
  return fetchWithErrorHandling<PlantGroupResponse[]>(
    `${ADMIN_BASE}/plant-groups`
  );
};

/**
 * Get a specific plant group by ID.
 * GET /api/admin/plant-groups/{id}
 */
export const getPlantGroup = async (id: string): Promise<PlantGroupResponse> => {
  return fetchWithErrorHandling<PlantGroupResponse>(
    `${ADMIN_BASE}/plant-groups/${encodeURIComponent(id)}`
  );
};

/**
 * Create a new plant group.
 * POST /api/admin/plant-groups
 */
export const createPlantGroup = async (
  data: CreatePlantGroupRequest
): Promise<PlantGroupResponse> => {
  return fetchWithErrorHandling<PlantGroupResponse>(
    `${ADMIN_BASE}/plant-groups`,
    {
      method: 'POST',
      body: JSON.stringify(data),
    }
  );
};

/**
 * Update an existing plant group.
 * PUT /api/admin/plant-groups/{id}
 */
export const updatePlantGroup = async (
  id: string,
  data: UpdatePlantGroupRequest
): Promise<PlantGroupResponse> => {
  return fetchWithErrorHandling<PlantGroupResponse>(
    `${ADMIN_BASE}/plant-groups/${encodeURIComponent(id)}`,
    {
      method: 'PUT',
      body: JSON.stringify(data),
    }
  );
};

/**
 * Delete a plant group.
 * DELETE /api/admin/plant-groups/{id}
 */
export const deletePlantGroup = async (id: string): Promise<void> => {
  return fetchWithErrorHandling<void>(
    `${ADMIN_BASE}/plant-groups/${encodeURIComponent(id)}`,
    {
      method: 'DELETE',
    }
  );
};

// ============================================================================
// Plants API
// ============================================================================

/**
 * Get all plants (summary view).
 * GET /api/admin/plants
 */
export const getPlants = async (): Promise<PlantSummaryResponse[]> => {
  return fetchWithErrorHandling<PlantSummaryResponse[]>(
    `${ADMIN_BASE}/plants`
  );
};

/**
 * Get a specific plant by ID (full details).
 * GET /api/admin/plants/{id}
 */
export const getPlant = async (id: string): Promise<PlantResponse> => {
  return fetchWithErrorHandling<PlantResponse>(
    `${ADMIN_BASE}/plants/${encodeURIComponent(id)}`
  );
};

/**
 * Create a new plant.
 * POST /api/admin/plants
 */
export const createPlant = async (
  data: CreatePlantRequest
): Promise<PlantResponse> => {
  return fetchWithErrorHandling<PlantResponse>(
    `${ADMIN_BASE}/plants`,
    {
      method: 'POST',
      body: JSON.stringify(data),
    }
  );
};

/**
 * Update an existing plant.
 * PUT /api/admin/plants/{id}
 */
export const updatePlant = async (
  id: string,
  data: UpdatePlantRequest
): Promise<PlantResponse> => {
  return fetchWithErrorHandling<PlantResponse>(
    `${ADMIN_BASE}/plants/${encodeURIComponent(id)}`,
    {
      method: 'PUT',
      body: JSON.stringify(data),
    }
  );
};

/**
 * Delete a plant.
 * DELETE /api/admin/plants/{id}
 */
export const deletePlant = async (id: string): Promise<void> => {
  return fetchWithErrorHandling<void>(
    `${ADMIN_BASE}/plants/${encodeURIComponent(id)}`,
    {
      method: 'DELETE',
    }
  );
};

// ============================================================================
// Images API
// ============================================================================

/**
 * Get all images.
 * GET /api/admin/images
 */
export const getImages = async (): Promise<ImageResponse[]> => {
  return fetchWithErrorHandling<ImageResponse[]>(
    `${ADMIN_BASE}/images`
  );
};

/**
 * Upload an image file.
 * POST /api/admin/images
 *
 * @param file - Image file to upload (multipart/form-data)
 * @returns Response with imageId
 */
export const uploadImage = async (file: File): Promise<UploadImageResponse> => {
  const formData = new FormData();
  formData.append('file', file);

  try {
    const response = await fetch(`${ADMIN_BASE}/images`, {
      method: 'POST',
      body: formData,
      // Note: Do NOT set Content-Type header for FormData
      // Browser will set it automatically with correct boundary
    });

    if (!response.ok) {
      throw await parseErrorResponse(response);
    }

    return await response.json();
  } catch (error) {
    if (error instanceof ApiError) {
      throw error;
    }
    throw new ApiError(
      error instanceof Error ? error.message : 'Upload failed',
      0
    );
  }
};

/**
 * Get the URL for displaying an image.
 * This is a public endpoint (not under /admin).
 *
 * @param imageId - Image ID
 * @returns Full URL to image resource
 */
export const getImageUrl = (imageId: string): string => {
  return `${API_BASE_URL}/api/images/${encodeURIComponent(imageId)}`;
};
