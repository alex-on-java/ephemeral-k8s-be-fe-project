/**
 * TanStack Query hooks for images API.
 */

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { getImages, uploadImage } from '@/lib/api';

// ============================================================================
// Query Keys
// ============================================================================

export const imageKeys = {
  all: ['images'] as const,
  lists: () => [...imageKeys.all, 'list'] as const,
  list: () => [...imageKeys.lists()] as const,
};

// ============================================================================
// Query Hooks
// ============================================================================

/**
 * Fetch all images.
 */
export const useImages = () => {
  return useQuery({
    queryKey: imageKeys.list(),
    queryFn: getImages,
  });
};

// ============================================================================
// Mutation Hooks
// ============================================================================

/**
 * Upload an image file.
 *
 * Usage:
 * ```typescript
 * const { mutate, isPending, isError, data } = useUploadImage();
 *
 * const handleFileSelect = (file: File) => {
 *   mutate(file, {
 *     onSuccess: (response) => {
 *       console.log('Image uploaded:', response.imageId);
 *     },
 *     onError: (error) => {
 *       console.error('Upload failed:', error);
 *     }
 *   });
 * };
 * ```
 */
export const useUploadImage = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (file: File) => uploadImage(file),
    onSuccess: () => {
      // Invalidate and refetch images list
      queryClient.invalidateQueries({ queryKey: imageKeys.list() });
    },
  });
};
