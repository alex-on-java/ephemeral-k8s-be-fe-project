/**
 * TanStack Query hooks for plants API.
 */

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import {
  createPlant,
  deletePlant,
  getPlant,
  getPlants,
  updatePlant,
} from '@/lib/api';
import type {
  CreatePlantRequest,
  PlantResponse,
  UpdatePlantRequest,
} from '@/types/api';

// ============================================================================
// Query Keys
// ============================================================================

export const plantKeys = {
  all: ['plants'] as const,
  lists: () => [...plantKeys.all, 'list'] as const,
  list: () => [...plantKeys.lists()] as const,
  details: () => [...plantKeys.all, 'detail'] as const,
  detail: (id: string) => [...plantKeys.details(), id] as const,
};

// ============================================================================
// Query Hooks
// ============================================================================

/**
 * Fetch all plants (summary view).
 */
export const usePlants = () => {
  return useQuery({
    queryKey: plantKeys.list(),
    queryFn: getPlants,
  });
};

/**
 * Fetch a specific plant by ID (full details).
 */
export const usePlant = (id: string) => {
  return useQuery({
    queryKey: plantKeys.detail(id),
    queryFn: () => getPlant(id),
    enabled: !!id,
  });
};

// ============================================================================
// Mutation Hooks
// ============================================================================

/**
 * Create a new plant.
 */
export const useCreatePlant = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreatePlantRequest) => createPlant(data),
    onSuccess: () => {
      // Invalidate and refetch plants list
      queryClient.invalidateQueries({ queryKey: plantKeys.list() });
    },
  });
};

/**
 * Update an existing plant.
 */
export const useUpdatePlant = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: UpdatePlantRequest }) =>
      updatePlant(id, data),
    onSuccess: (updatedPlant: PlantResponse) => {
      // Invalidate list
      queryClient.invalidateQueries({ queryKey: plantKeys.list() });
      // Update detail cache
      queryClient.setQueryData(plantKeys.detail(updatedPlant.id), updatedPlant);
    },
  });
};

/**
 * Delete a plant.
 */
export const useDeletePlant = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => deletePlant(id),
    onSuccess: (_, deletedId) => {
      // Invalidate list
      queryClient.invalidateQueries({ queryKey: plantKeys.list() });
      // Remove from detail cache
      queryClient.removeQueries({ queryKey: plantKeys.detail(deletedId) });
    },
  });
};
