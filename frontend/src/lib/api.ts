import type { PlantGroup, Plant, ApiError } from "@/types/api";

/**
 * API Base URL
 * - In development: Empty string (uses Vite proxy to localhost:8080)
 * - In production: Full URL to backend API
 */
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || "";

class ApiClient {
  private baseUrl: string;

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl;
  }

  /**
   * Base fetch wrapper with error handling
   */
  private async fetch<T>(endpoint: string, options?: RequestInit): Promise<T> {
    const url = `${this.baseUrl}${endpoint}`;

    try {
      const response = await fetch(url, {
        ...options,
        headers: {
          "Content-Type": "application/json",
          ...options?.headers,
        },
      });

      if (!response.ok) {
        const error: ApiError = {
          message: `API Error: ${response.statusText}`,
          status: response.status,
        };
        throw error;
      }

      return await response.json();
    } catch (error) {
      if (error instanceof Error) {
        throw {
          message: error.message,
          status: 500,
        } as ApiError;
      }
      throw error;
    }
  }

  /**
   * Constructs full URL for image endpoint
   */
  getImageUrl(imageId: string): string {
    return `${this.baseUrl}/api/images/${imageId}`;
  }

  /**
   * Fetches all plant groups
   * GET /api/plant-groups
   */
  async fetchPlantGroups(): Promise<PlantGroup[]> {
    return this.fetch<PlantGroup[]>("/api/plant-groups");
  }

  /**
   * Fetches all plants in a specific group
   * GET /api/plant-groups/{groupId}/plants
   */
  async fetchPlantsByGroup(groupId: string): Promise<Plant[]> {
    return this.fetch<Plant[]>(`/api/plant-groups/${groupId}/plants`);
  }

  /**
   * Fetches detailed information for a specific plant
   * GET /api/plants/{plantId}
   */
  async fetchPlantById(plantId: string): Promise<Plant> {
    return this.fetch<Plant>(`/api/plants/${plantId}`);
  }
}

// Export singleton instance
export const apiClient = new ApiClient(API_BASE_URL);

// Export helper function for image URLs
export const getImageUrl = (imageId: string) => apiClient.getImageUrl(imageId);
