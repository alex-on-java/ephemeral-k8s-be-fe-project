import { useState } from 'react';
import { toast } from 'sonner';
import {
  usePlantGroups,
  useCreatePlantGroup,
  useUpdatePlantGroup,
  useDeletePlantGroup,
} from '@/hooks/usePlantGroups';
import { useImages } from '@/hooks/useImages';
import { getImageUrl } from '@/lib/api';
import {
  validatePlantGroupId,
  validatePlantGroupName,
} from '@/lib/validation';
import { Button } from '@/components/ui/button';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog';

interface FormData {
  id: string;
  name: string;
  imageId: string;
}

interface FormErrors {
  id?: string;
  name?: string;
}

const PlantGroups = () => {
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [isEditOpen, setIsEditOpen] = useState(false);
  const [deleteId, setDeleteId] = useState<string | null>(null);
  const [formData, setFormData] = useState<FormData>({
    id: '',
    name: '',
    imageId: '',
  });
  const [formErrors, setFormErrors] = useState<FormErrors>({});

  const { data: plantGroups, isLoading, isError } = usePlantGroups();
  const { data: images = [] } = useImages();
  const createMutation = useCreatePlantGroup();
  const updateMutation = useUpdatePlantGroup();
  const deleteMutation = useDeletePlantGroup();

  const validateForm = (isCreate: boolean): boolean => {
    const errors: FormErrors = {};

    if (isCreate) {
      const idResult = validatePlantGroupId(formData.id);
      if (!idResult.isValid) {
        errors.id = idResult.errors[0];
      }
    }

    const nameResult = validatePlantGroupName(formData.name);
    if (!nameResult.isValid) {
      errors.name = nameResult.errors[0];
    }

    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleCreate = () => {
    if (!validateForm(true)) return;

    createMutation.mutate(
      {
        id: formData.id.trim(),
        name: formData.name.trim(),
        imageId: formData.imageId || undefined,
      },
      {
        onSuccess: () => {
          toast.success('Plant group created successfully');
          setIsCreateOpen(false);
          setFormData({ id: '', name: '', imageId: '' });
          setFormErrors({});
        },
        onError: (error) => {
          toast.error(`Failed to create plant group: ${error.message}`);
        },
      }
    );
  };

  const handleEdit = (id: string) => {
    const group = plantGroups?.find((g) => g.id === id);
    if (group) {
      setFormData({
        id: group.id,
        name: group.name,
        imageId: group.imageId || '',
      });
      setIsEditOpen(true);
    }
  };

  const handleUpdate = () => {
    if (!validateForm(false)) return;

    updateMutation.mutate(
      {
        id: formData.id,
        data: {
          name: formData.name.trim(),
          imageId: formData.imageId || undefined,
        },
      },
      {
        onSuccess: () => {
          toast.success('Plant group updated successfully');
          setIsEditOpen(false);
          setFormData({ id: '', name: '', imageId: '' });
          setFormErrors({});
        },
        onError: (error) => {
          toast.error(`Failed to update plant group: ${error.message}`);
        },
      }
    );
  };

  const handleDelete = () => {
    if (!deleteId) return;

    deleteMutation.mutate(deleteId, {
      onSuccess: () => {
        toast.success('Plant group deleted successfully');
        setDeleteId(null);
      },
      onError: (error) => {
        toast.error(`Failed to delete plant group: ${error.message}`);
        setDeleteId(null);
      },
    });
  };

  const openCreateDialog = () => {
    setFormData({ id: '', name: '', imageId: '' });
    setFormErrors({});
    setIsCreateOpen(true);
  };

  const closeCreateDialog = () => {
    setIsCreateOpen(false);
    setFormData({ id: '', name: '', imageId: '' });
    setFormErrors({});
  };

  const closeEditDialog = () => {
    setIsEditOpen(false);
    setFormData({ id: '', name: '', imageId: '' });
    setFormErrors({});
  };

  if (isLoading) {
    return (
      <div className="space-y-4">
        <div className="flex justify-between items-center">
          <div>
            <h2 className="text-3xl font-bold">Plant Groups</h2>
            <p className="text-muted-foreground mt-2">
              Manage plant categories and their organization.
            </p>
          </div>
        </div>
        <Card>
          <CardContent className="pt-6">
            <p className="text-center text-muted-foreground">Loading...</p>
          </CardContent>
        </Card>
      </div>
    );
  }

  if (isError) {
    return (
      <div className="space-y-4">
        <div className="flex justify-between items-center">
          <div>
            <h2 className="text-3xl font-bold">Plant Groups</h2>
            <p className="text-muted-foreground mt-2">
              Manage plant categories and their organization.
            </p>
          </div>
        </div>
        <Card>
          <CardContent className="pt-6">
            <p className="text-center text-destructive">
              Failed to load plant groups. Please try again.
            </p>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-3xl font-bold">Plant Groups</h2>
          <p className="text-muted-foreground mt-2">
            Manage plant categories and their organization.
          </p>
        </div>
        <Button onClick={openCreateDialog}>Create Plant Group</Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>All Plant Groups</CardTitle>
          <CardDescription>
            {plantGroups?.length || 0} group(s) total
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>ID</TableHead>
                <TableHead>Name</TableHead>
                <TableHead>Image</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {plantGroups?.length === 0 && (
                <TableRow>
                  <TableCell colSpan={4} className="text-center text-muted-foreground">
                    No plant groups found. Create one to get started.
                  </TableCell>
                </TableRow>
              )}
              {plantGroups?.map((group) => (
                <TableRow key={group.id}>
                  <TableCell className="font-mono text-sm">{group.id}</TableCell>
                  <TableCell className="font-medium">{group.name}</TableCell>
                  <TableCell>
                    {group.imageId ? (
                      <img
                        src={getImageUrl(group.imageId)}
                        alt={group.name}
                        className="w-16 h-10 object-cover rounded"
                      />
                    ) : (
                      <span className="text-muted-foreground text-sm">No image</span>
                    )}
                  </TableCell>
                  <TableCell className="text-right space-x-2">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => handleEdit(group.id)}
                    >
                      Edit
                    </Button>
                    <Button
                      variant="destructive"
                      size="sm"
                      onClick={() => setDeleteId(group.id)}
                    >
                      Delete
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      {/* Create Dialog */}
      <Dialog open={isCreateOpen} onOpenChange={setIsCreateOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Create Plant Group</DialogTitle>
            <DialogDescription>
              Add a new plant group to organize your plants by category.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="create-id">
                ID <span className="text-muted-foreground text-xs">(max 100 chars, lowercase)</span>
              </Label>
              <Input
                id="create-id"
                value={formData.id}
                onChange={(e) => setFormData({ ...formData, id: e.target.value })}
                placeholder="e.g., succulents, tropical"
                maxLength={100}
                className={formErrors.id ? 'border-destructive' : ''}
              />
              {formErrors.id && (
                <p className="text-sm text-destructive">{formErrors.id}</p>
              )}
              <p className="text-xs text-muted-foreground">
                {formData.id.length} / 100 characters
              </p>
            </div>

            <div className="space-y-2">
              <Label htmlFor="create-name">
                Name <span className="text-muted-foreground text-xs">(max 255 chars)</span>
              </Label>
              <Input
                id="create-name"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                placeholder="e.g., Succulents & Cacti"
                maxLength={255}
                className={formErrors.name ? 'border-destructive' : ''}
              />
              {formErrors.name && (
                <p className="text-sm text-destructive">{formErrors.name}</p>
              )}
              <p className="text-xs text-muted-foreground">
                {formData.name.length} / 255 characters
              </p>
            </div>

            <div className="space-y-2">
              <Label htmlFor="create-image">
                Cover Image <span className="text-muted-foreground text-xs">(optional)</span>
              </Label>
              <Select
                value={formData.imageId}
                onValueChange={(value) => setFormData({ ...formData, imageId: value })}
              >
                <SelectTrigger id="create-image">
                  <SelectValue placeholder="Select an image" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="">None</SelectItem>
                  {images.map((img) => (
                    <SelectItem key={img.id} value={img.id}>
                      {img.filename}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={closeCreateDialog}>
              Cancel
            </Button>
            <Button onClick={handleCreate} disabled={createMutation.isPending}>
              {createMutation.isPending ? 'Creating...' : 'Create'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Edit Dialog */}
      <Dialog open={isEditOpen} onOpenChange={setIsEditOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit Plant Group</DialogTitle>
            <DialogDescription>
              Update the plant group details. ID cannot be changed.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="edit-id">ID</Label>
              <Input id="edit-id" value={formData.id} disabled className="bg-muted" />
              <p className="text-xs text-muted-foreground">ID cannot be changed</p>
            </div>

            <div className="space-y-2">
              <Label htmlFor="edit-name">
                Name <span className="text-muted-foreground text-xs">(max 255 chars)</span>
              </Label>
              <Input
                id="edit-name"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                placeholder="e.g., Succulents & Cacti"
                maxLength={255}
                className={formErrors.name ? 'border-destructive' : ''}
              />
              {formErrors.name && (
                <p className="text-sm text-destructive">{formErrors.name}</p>
              )}
              <p className="text-xs text-muted-foreground">
                {formData.name.length} / 255 characters
              </p>
            </div>

            <div className="space-y-2">
              <Label htmlFor="edit-image">
                Cover Image <span className="text-muted-foreground text-xs">(optional)</span>
              </Label>
              <Select
                value={formData.imageId}
                onValueChange={(value) => setFormData({ ...formData, imageId: value })}
              >
                <SelectTrigger id="edit-image">
                  <SelectValue placeholder="Select an image" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="">None</SelectItem>
                  {images.map((img) => (
                    <SelectItem key={img.id} value={img.id}>
                      {img.filename}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={closeEditDialog}>
              Cancel
            </Button>
            <Button onClick={handleUpdate} disabled={updateMutation.isPending}>
              {updateMutation.isPending ? 'Updating...' : 'Update'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <AlertDialog open={!!deleteId} onOpenChange={(open) => !open && setDeleteId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Are you sure?</AlertDialogTitle>
            <AlertDialogDescription>
              This will permanently delete the plant group <strong>{deleteId}</strong>.
              Plants in this group will not be affected.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleDelete}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              {deleteMutation.isPending ? 'Deleting...' : 'Delete'}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
};

export default PlantGroups;
