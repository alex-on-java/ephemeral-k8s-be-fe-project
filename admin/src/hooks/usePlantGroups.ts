/**
 * TanStack Query hooks for plant groups API.
 */

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import {
  createPlantGroup,
  deletePlantGroup,
  getPlantGroup,
  getPlantGroups,
  updatePlantGroup,
} from '@/lib/api';
import type {
  CreatePlantGroupRequest,
  PlantGroupResponse,
  UpdatePlantGroupRequest,
} from '@/types/api';

// ============================================================================
// Query Keys
// ============================================================================

export const plantGroupKeys = {
  all: ['plant-groups'] as const,
  lists: () => [...plantGroupKeys.all, 'list'] as const,
  list: () => [...plantGroupKeys.lists()] as const,
  details: () => [...plantGroupKeys.all, 'detail'] as const,
  detail: (id: string) => [...plantGroupKeys.details(), id] as const,
};

// ============================================================================
// Query Hooks
// ============================================================================

/**
 * Fetch all plant groups.
 */
export const usePlantGroups = () => {
  return useQuery({
    queryKey: plantGroupKeys.list(),
    queryFn: getPlantGroups,
  });
};

/**
 * Fetch a specific plant group by ID.
 */
export const usePlantGroup = (id: string) => {
  return useQuery({
    queryKey: plantGroupKeys.detail(id),
    queryFn: () => getPlantGroup(id),
    enabled: !!id,
  });
};

// ============================================================================
// Mutation Hooks
// ============================================================================

/**
 * Create a new plant group.
 */
export const useCreatePlantGroup = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreatePlantGroupRequest) => createPlantGroup(data),
    onSuccess: () => {
      // Invalidate and refetch plant groups list
      queryClient.invalidateQueries({ queryKey: plantGroupKeys.list() });
    },
  });
};

/**
 * Update an existing plant group.
 */
export const useUpdatePlantGroup = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      id,
      data,
    }: {
      id: string;
      data: UpdatePlantGroupRequest;
    }) => updatePlantGroup(id, data),
    onSuccess: (updatedGroup: PlantGroupResponse) => {
      // Invalidate list
      queryClient.invalidateQueries({ queryKey: plantGroupKeys.list() });
      // Update detail cache
      queryClient.setQueryData(
        plantGroupKeys.detail(updatedGroup.id),
        updatedGroup
      );
    },
  });
};

/**
 * Delete a plant group.
 */
export const useDeletePlantGroup = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => deletePlantGroup(id),
    onSuccess: (_, deletedId) => {
      // Invalidate list
      queryClient.invalidateQueries({ queryKey: plantGroupKeys.list() });
      // Remove from detail cache
      queryClient.removeQueries({ queryKey: plantGroupKeys.detail(deletedId) });
    },
  });
};
