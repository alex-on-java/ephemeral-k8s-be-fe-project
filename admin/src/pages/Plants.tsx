import { useState } from 'react';
import { toast } from 'sonner';
import {
  usePlants,
  useCreatePlant,
  useUpdatePlant,
  useDeletePlant,
} from '@/hooks/usePlants';
import { usePlantGroups } from '@/hooks/usePlantGroups';
import { useImages } from '@/hooks/useImages';
import { getImageUrl } from '@/lib/api';
import type { CreatePlantRequest, CareGuide, Issue } from '@/types/api';
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
import { Textarea } from '@/components/ui/textarea';
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
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';

interface FormData {
  id: string;
  groupId: string;
  name: string;
  scientificName: string;
  thumbnailId: string;
  imageIds: string[];
  description: string;
  size: string;
  toxicity: string;
  benefits: string[];
  care: CareGuide;
  commonIssues: Issue[];
}

const emptyFormData: FormData = {
  id: '',
  groupId: '',
  name: '',
  scientificName: '',
  thumbnailId: '',
  imageIds: [],
  description: '',
  size: '',
  toxicity: '',
  benefits: ['', '', '', ''],
  care: {
    watering: '',
    light: '',
    temperature: '',
    humidity: '',
    soil: '',
    fertilizing: '',
  },
  commonIssues: [
    { issue: '', solution: '' },
    { issue: '', solution: '' },
  ],
};

const Plants = () => {
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [deleteId, setDeleteId] = useState<string | null>(null);
  const [formData, setFormData] = useState<FormData>(emptyFormData);

  const { data: plants, isLoading, isError } = usePlants();
  const { data: plantGroups } = usePlantGroups();
  const { data: images = [] } = useImages();
  const createMutation = useCreatePlant();
  const updateMutation = useUpdatePlant();
  const deleteMutation = useDeletePlant();

  const handleCreate = () => {
    // Validation
    if (!formData.id.trim()) {
      toast.error('Plant ID is required');
      return;
    }
    if (!formData.groupId) {
      toast.error('Plant group is required');
      return;
    }
    if (!formData.name.trim()) {
      toast.error('Plant name is required');
      return;
    }
    if (!formData.scientificName.trim()) {
      toast.error('Scientific name is required');
      return;
    }
    if (!formData.thumbnailId) {
      toast.error('Thumbnail is required');
      return;
    }
    if (formData.imageIds.length < 1 || formData.imageIds.length > 3) {
      toast.error('Must select 1-3 detail images');
      return;
    }

    const filteredBenefits = formData.benefits.filter((b) => b.trim());
    if (filteredBenefits.length < 4 || filteredBenefits.length > 5) {
      toast.error('Must have 4-5 benefits');
      return;
    }

    const filteredIssues = formData.commonIssues.filter(
      (i) => i.issue.trim() && i.solution.trim()
    );
    if (filteredIssues.length < 2 || filteredIssues.length > 4) {
      toast.error('Must have 2-4 common issues');
      return;
    }

    const request: CreatePlantRequest = {
      id: formData.id.trim(),
      groupId: formData.groupId,
      name: formData.name.trim(),
      scientificName: formData.scientificName.trim(),
      thumbnailId: formData.thumbnailId,
      imageIds: formData.imageIds,
      description: formData.description.trim(),
      size: formData.size.trim(),
      toxicity: formData.toxicity.trim(),
      benefits: filteredBenefits,
      care: {
        watering: formData.care.watering.trim(),
        light: formData.care.light.trim(),
        temperature: formData.care.temperature.trim(),
        humidity: formData.care.humidity.trim(),
        soil: formData.care.soil.trim(),
        fertilizing: formData.care.fertilizing.trim(),
      },
      commonIssues: filteredIssues,
    };

    createMutation.mutate(request, {
      onSuccess: () => {
        toast.success('Plant created successfully');
        setIsDialogOpen(false);
        setFormData(emptyFormData);
      },
      onError: (error) => {
        toast.error(`Failed to create plant: ${error.message}`);
      },
    });
  };

  const handleUpdate = () => {
    if (!editingId) return;

    // Same validation as create
    const filteredBenefits = formData.benefits.filter((b) => b.trim());
    if (filteredBenefits.length < 4 || filteredBenefits.length > 5) {
      toast.error('Must have 4-5 benefits');
      return;
    }

    const filteredIssues = formData.commonIssues.filter(
      (i) => i.issue.trim() && i.solution.trim()
    );
    if (filteredIssues.length < 2 || filteredIssues.length > 4) {
      toast.error('Must have 2-4 common issues');
      return;
    }

    updateMutation.mutate(
      {
        id: editingId,
        data: {
          groupId: formData.groupId,
          name: formData.name.trim(),
          scientificName: formData.scientificName.trim(),
          thumbnailId: formData.thumbnailId,
          imageIds: formData.imageIds,
          description: formData.description.trim(),
          size: formData.size.trim(),
          toxicity: formData.toxicity.trim(),
          benefits: filteredBenefits,
          care: {
            watering: formData.care.watering.trim(),
            light: formData.care.light.trim(),
            temperature: formData.care.temperature.trim(),
            humidity: formData.care.humidity.trim(),
            soil: formData.care.soil.trim(),
            fertilizing: formData.care.fertilizing.trim(),
          },
          commonIssues: filteredIssues,
        },
      },
      {
        onSuccess: () => {
          toast.success('Plant updated successfully');
          setIsDialogOpen(false);
          setEditingId(null);
          setFormData(emptyFormData);
        },
        onError: (error) => {
          toast.error(`Failed to update plant: ${error.message}`);
        },
      }
    );
  };

  const handleEdit = (id: string) => {
    const plant = plants?.find((p) => p.id === id);
    if (plant) {
      setFormData({
        id: plant.id,
        groupId: plant.groupId,
        name: plant.name,
        scientificName: plant.scientificName,
        thumbnailId: plant.thumbnailId,
        imageIds: plant.imageIds ? [...plant.imageIds] : [],
        description: plant.description,
        size: plant.size,
        toxicity: plant.toxicity,
        benefits: plant.benefits ? [...plant.benefits] : ['', '', '', ''],
        care: { ...plant.care },
        commonIssues: plant.commonIssues
          ? plant.commonIssues.map((i) => ({ ...i }))
          : [
              { issue: '', solution: '' },
              { issue: '', solution: '' },
            ],
      });
      setEditingId(id);
      setIsDialogOpen(true);
    }
  };

  const handleDelete = () => {
    if (!deleteId) return;

    deleteMutation.mutate(deleteId, {
      onSuccess: () => {
        toast.success('Plant deleted successfully');
        setDeleteId(null);
      },
      onError: (error) => {
        toast.error(`Failed to delete plant: ${error.message}`);
        setDeleteId(null);
      },
    });
  };

  const openCreateDialog = () => {
    setFormData(emptyFormData);
    setEditingId(null);
    setIsDialogOpen(true);
  };

  const closeDialog = () => {
    setIsDialogOpen(false);
    setEditingId(null);
    setFormData(emptyFormData);
  };

  const toggleImageId = (imageId: string) => {
    const newImageIds = formData.imageIds.includes(imageId)
      ? formData.imageIds.filter((id) => id !== imageId)
      : [...formData.imageIds, imageId];
    setFormData({ ...formData, imageIds: newImageIds });
  };

  const updateBenefit = (index: number, value: string) => {
    const newBenefits = [...formData.benefits];
    newBenefits[index] = value;
    setFormData({ ...formData, benefits: newBenefits });
  };

  const addBenefit = () => {
    if (formData.benefits.length < 5) {
      setFormData({ ...formData, benefits: [...formData.benefits, ''] });
    }
  };

  const removeBenefit = (index: number) => {
    if (formData.benefits.length > 4) {
      setFormData({
        ...formData,
        benefits: formData.benefits.filter((_, i) => i !== index),
      });
    }
  };

  const updateIssue = (index: number, field: 'issue' | 'solution', value: string) => {
    const newIssues = [...formData.commonIssues];
    newIssues[index][field] = value;
    setFormData({ ...formData, commonIssues: newIssues });
  };

  const addIssue = () => {
    if (formData.commonIssues.length < 4) {
      setFormData({
        ...formData,
        commonIssues: [...formData.commonIssues, { issue: '', solution: '' }],
      });
    }
  };

  const removeIssue = (index: number) => {
    if (formData.commonIssues.length > 2) {
      setFormData({
        ...formData,
        commonIssues: formData.commonIssues.filter((_, i) => i !== index),
      });
    }
  };

  if (isLoading) {
    return (
      <div className="space-y-4">
        <div className="flex justify-between items-center">
          <div>
            <h2 className="text-3xl font-bold">Plants</h2>
            <p className="text-muted-foreground mt-2">
              Manage individual plants and their details.
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
            <h2 className="text-3xl font-bold">Plants</h2>
            <p className="text-muted-foreground mt-2">
              Manage individual plants and their details.
            </p>
          </div>
        </div>
        <Card>
          <CardContent className="pt-6">
            <p className="text-center text-destructive">
              Failed to load plants. Please try again.
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
          <h2 className="text-3xl font-bold">Plants</h2>
          <p className="text-muted-foreground mt-2">
            Manage individual plants and their details.
          </p>
        </div>
        <Button onClick={openCreateDialog}>Create Plant</Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>All Plants</CardTitle>
          <CardDescription>{plants?.length || 0} plant(s) total</CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Thumbnail</TableHead>
                <TableHead>Name</TableHead>
                <TableHead>Scientific Name</TableHead>
                <TableHead>Group</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {plants?.length === 0 && (
                <TableRow>
                  <TableCell colSpan={5} className="text-center text-muted-foreground">
                    No plants found. Create one to get started.
                  </TableCell>
                </TableRow>
              )}
              {plants?.map((plant) => {
                const group = plantGroups?.find((g) => g.id === plant.groupId);
                return (
                  <TableRow key={plant.id}>
                    <TableCell>
                      <img
                        src={getImageUrl(plant.thumbnailId)}
                        alt={plant.name}
                        className="w-16 h-16 object-cover rounded"
                      />
                    </TableCell>
                    <TableCell className="font-medium">{plant.name}</TableCell>
                    <TableCell className="italic text-muted-foreground">
                      {plant.scientificName}
                    </TableCell>
                    <TableCell>{group?.name || plant.groupId}</TableCell>
                    <TableCell className="text-right space-x-2">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleEdit(plant.id)}
                      >
                        Edit
                      </Button>
                      <Button
                        variant="destructive"
                        size="sm"
                        onClick={() => setDeleteId(plant.id)}
                      >
                        Delete
                      </Button>
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      {/* Create/Edit Dialog */}
      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{editingId ? 'Edit Plant' : 'Create Plant'}</DialogTitle>
            <DialogDescription>
              {editingId
                ? 'Update the plant details. ID cannot be changed.'
                : 'Add a new plant with complete care information.'}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-6 py-4">
            {/* Basic Info Section */}
            <div className="space-y-4">
              <h3 className="text-lg font-semibold">Basic Information</h3>
              <Separator />

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="plant-id">
                    ID{' '}
                    <span className="text-muted-foreground text-xs">
                      (lowercase-hyphenated)
                    </span>
                  </Label>
                  <Input
                    id="plant-id"
                    value={formData.id}
                    onChange={(e) => setFormData({ ...formData, id: e.target.value })}
                    placeholder="e.g., aloe-vera"
                    disabled={!!editingId}
                    className={editingId ? 'bg-muted' : ''}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="plant-group">Group</Label>
                  <Select
                    value={formData.groupId}
                    onValueChange={(value) =>
                      setFormData({ ...formData, groupId: value })
                    }
                  >
                    <SelectTrigger id="plant-group">
                      <SelectValue placeholder="Select a group" />
                    </SelectTrigger>
                    <SelectContent>
                      {plantGroups?.map((group) => (
                        <SelectItem key={group.id} value={group.id}>
                          {group.name}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="plant-name">Name</Label>
                  <Input
                    id="plant-name"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    placeholder="e.g., Aloe Vera"
                    maxLength={255}
                  />
                  <p className="text-xs text-muted-foreground">
                    {formData.name.length} / 255
                  </p>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="plant-scientific">Scientific Name</Label>
                  <Input
                    id="plant-scientific"
                    value={formData.scientificName}
                    onChange={(e) =>
                      setFormData({ ...formData, scientificName: e.target.value })
                    }
                    placeholder="e.g., Aloe barbadensis miller"
                    maxLength={255}
                  />
                  <p className="text-xs text-muted-foreground">
                    {formData.scientificName.length} / 255
                  </p>
                </div>
              </div>
            </div>

            {/* Images Section */}
            <div className="space-y-4">
              <h3 className="text-lg font-semibold">Images</h3>
              <Separator />

              <div className="space-y-2">
                <Label htmlFor="plant-thumbnail">Thumbnail</Label>
                <Select
                  value={formData.thumbnailId}
                  onValueChange={(value) =>
                    setFormData({ ...formData, thumbnailId: value })
                  }
                >
                  <SelectTrigger id="plant-thumbnail">
                    <SelectValue placeholder="Select thumbnail" />
                  </SelectTrigger>
                  <SelectContent>
                    {images.map((img) => (
                      <SelectItem key={img.id} value={img.id}>
                        {img.filename}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label>
                  Detail Images{' '}
                  <span className="text-muted-foreground text-xs">(select 1-3)</span>
                </Label>
                <div className="border rounded-md p-4 space-y-2 max-h-40 overflow-y-auto">
                  {images.map((img) => (
                    <label
                      key={img.id}
                      className="flex items-center space-x-2 cursor-pointer hover:bg-accent p-2 rounded"
                    >
                      <input
                        type="checkbox"
                        checked={formData.imageIds.includes(img.id)}
                        onChange={() => toggleImageId(img.id)}
                        className="w-4 h-4"
                      />
                      <span className="text-sm">{img.filename}</span>
                    </label>
                  ))}
                </div>
                <p className="text-xs text-muted-foreground">
                  {formData.imageIds.length} / 3 selected
                </p>
              </div>
            </div>

            {/* Content Section */}
            <div className="space-y-4">
              <h3 className="text-lg font-semibold">Content</h3>
              <Separator />

              <div className="space-y-2">
                <Label htmlFor="plant-description">Description</Label>
                <Textarea
                  id="plant-description"
                  value={formData.description}
                  onChange={(e) =>
                    setFormData({ ...formData, description: e.target.value })
                  }
                  placeholder="2-4 sentence overview..."
                  rows={4}
                  maxLength={10000}
                />
                <p className="text-xs text-muted-foreground">
                  {formData.description.length} / 10,000
                </p>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="plant-size">Size</Label>
                  <Textarea
                    id="plant-size"
                    value={formData.size}
                    onChange={(e) => setFormData({ ...formData, size: e.target.value })}
                    placeholder="Mature height and width..."
                    rows={3}
                    maxLength={5000}
                  />
                  <p className="text-xs text-muted-foreground">
                    {formData.size.length} / 5,000
                  </p>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="plant-toxicity">Toxicity</Label>
                  <Textarea
                    id="plant-toxicity"
                    value={formData.toxicity}
                    onChange={(e) =>
                      setFormData({ ...formData, toxicity: e.target.value })
                    }
                    placeholder="Toxicity information..."
                    rows={3}
                    maxLength={5000}
                  />
                  <p className="text-xs text-muted-foreground">
                    {formData.toxicity.length} / 5,000
                  </p>
                </div>
              </div>
            </div>

            {/* Benefits Section */}
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-semibold">Benefits</h3>
                <Badge variant={formData.benefits.length >= 4 && formData.benefits.length <= 5 ? 'default' : 'destructive'}>
                  {formData.benefits.length} / 4-5 items
                </Badge>
              </div>
              <Separator />

              <div className="space-y-2">
                {formData.benefits.map((benefit, index) => (
                  <div key={index} className="flex gap-2">
                    <Input
                      value={benefit}
                      onChange={(e) => updateBenefit(index, e.target.value)}
                      placeholder="Single-sentence benefit"
                      maxLength={5000}
                    />
                    <Button
                      type="button"
                      variant="destructive"
                      size="sm"
                      onClick={() => removeBenefit(index)}
                      disabled={formData.benefits.length <= 4}
                    >
                      Remove
                    </Button>
                  </div>
                ))}
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={addBenefit}
                  disabled={formData.benefits.length >= 5}
                >
                  Add Benefit
                </Button>
              </div>
            </div>

            {/* Care Guide Section */}
            <div className="space-y-4">
              <h3 className="text-lg font-semibold">Care Guide</h3>
              <Separator />

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="care-watering">Watering</Label>
                  <Textarea
                    id="care-watering"
                    value={formData.care.watering}
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        care: { ...formData.care, watering: e.target.value },
                      })
                    }
                    rows={3}
                    maxLength={5000}
                  />
                  <p className="text-xs text-muted-foreground">
                    {formData.care.watering.length} / 5,000
                  </p>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="care-light">Light</Label>
                  <Textarea
                    id="care-light"
                    value={formData.care.light}
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        care: { ...formData.care, light: e.target.value },
                      })
                    }
                    rows={3}
                    maxLength={5000}
                  />
                  <p className="text-xs text-muted-foreground">
                    {formData.care.light.length} / 5,000
                  </p>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="care-temperature">Temperature</Label>
                  <Textarea
                    id="care-temperature"
                    value={formData.care.temperature}
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        care: { ...formData.care, temperature: e.target.value },
                      })
                    }
                    rows={3}
                    maxLength={5000}
                  />
                  <p className="text-xs text-muted-foreground">
                    {formData.care.temperature.length} / 5,000
                  </p>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="care-humidity">Humidity</Label>
                  <Textarea
                    id="care-humidity"
                    value={formData.care.humidity}
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        care: { ...formData.care, humidity: e.target.value },
                      })
                    }
                    rows={3}
                    maxLength={5000}
                  />
                  <p className="text-xs text-muted-foreground">
                    {formData.care.humidity.length} / 5,000
                  </p>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="care-soil">Soil</Label>
                  <Textarea
                    id="care-soil"
                    value={formData.care.soil}
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        care: { ...formData.care, soil: e.target.value },
                      })
                    }
                    rows={3}
                    maxLength={5000}
                  />
                  <p className="text-xs text-muted-foreground">
                    {formData.care.soil.length} / 5,000
                  </p>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="care-fertilizing">Fertilizing</Label>
                  <Textarea
                    id="care-fertilizing"
                    value={formData.care.fertilizing}
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        care: { ...formData.care, fertilizing: e.target.value },
                      })
                    }
                    rows={3}
                    maxLength={5000}
                  />
                  <p className="text-xs text-muted-foreground">
                    {formData.care.fertilizing.length} / 5,000
                  </p>
                </div>
              </div>
            </div>

            {/* Common Issues Section */}
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-semibold">Common Issues</h3>
                <Badge variant={formData.commonIssues.length >= 2 && formData.commonIssues.length <= 4 ? 'default' : 'destructive'}>
                  {formData.commonIssues.length} / 2-4 pairs
                </Badge>
              </div>
              <Separator />

              <div className="space-y-4">
                {formData.commonIssues.map((issueItem, index) => (
                  <div key={index} className="border rounded-md p-4 space-y-3">
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-medium">Issue #{index + 1}</span>
                      <Button
                        type="button"
                        variant="destructive"
                        size="sm"
                        onClick={() => removeIssue(index)}
                        disabled={formData.commonIssues.length <= 2}
                      >
                        Remove
                      </Button>
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor={`issue-${index}`}>
                        Issue{' '}
                        <span className="text-muted-foreground text-xs">
                          (concise symptom)
                        </span>
                      </Label>
                      <Input
                        id={`issue-${index}`}
                        value={issueItem.issue}
                        onChange={(e) => updateIssue(index, 'issue', e.target.value)}
                        placeholder="e.g., Brown or soft leaves"
                        maxLength={5000}
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor={`solution-${index}`}>
                        Solution{' '}
                        <span className="text-muted-foreground text-xs">
                          (detailed steps)
                        </span>
                      </Label>
                      <Textarea
                        id={`solution-${index}`}
                        value={issueItem.solution}
                        onChange={(e) => updateIssue(index, 'solution', e.target.value)}
                        placeholder="Detailed remediation steps..."
                        rows={3}
                        maxLength={5000}
                      />
                    </div>
                  </div>
                ))}
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={addIssue}
                  disabled={formData.commonIssues.length >= 4}
                >
                  Add Issue
                </Button>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={closeDialog}>
              Cancel
            </Button>
            <Button
              onClick={editingId ? handleUpdate : handleCreate}
              disabled={createMutation.isPending || updateMutation.isPending}
            >
              {createMutation.isPending || updateMutation.isPending
                ? 'Saving...'
                : editingId
                ? 'Update Plant'
                : 'Create Plant'}
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
              This will permanently delete the plant <strong>{deleteId}</strong>.
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

export default Plants;
