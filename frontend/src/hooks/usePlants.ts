import { useQuery } from "@tanstack/react-query";
import { apiClient } from "@/lib/api";
import type { PlantGroup, Plant } from "@/types/api";

/**
 * Hook to fetch all plant groups
 */
export const usePlantGroups = () => {
  return useQuery<PlantGroup[]>({
    queryKey: ["plantGroups"],
    queryFn: () => apiClient.fetchPlantGroups(),
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
};

/**
 * Hook to fetch plants by group ID
 */
export const usePlantsByGroup = (groupId: string | null) => {
  return useQuery<Plant[]>({
    queryKey: ["plants", "byGroup", groupId],
    queryFn: () => apiClient.fetchPlantsByGroup(groupId!),
    enabled: !!groupId, // Only run query if groupId is provided
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
};

/**
 * Hook to fetch a single plant by ID
 */
export const usePlant = (plantId: string | null) => {
  return useQuery<Plant>({
    queryKey: ["plant", plantId],
    queryFn: () => apiClient.fetchPlantById(plantId!),
    enabled: !!plantId, // Only run query if plantId is provided
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
};
