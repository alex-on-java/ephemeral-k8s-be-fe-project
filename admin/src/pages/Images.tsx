import { useState, useRef } from 'react';
import { toast } from 'sonner';
import { useImages, useUploadImage } from '@/hooks/useImages';
import { getImageUrl } from '@/lib/api';
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
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Alert, AlertDescription } from '@/components/ui/alert';

const Images = () => {
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const { data: images = [], isLoading, isError, error } = useImages();
  const uploadMutation = useUploadImage();

  const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      setSelectedFile(file);

      // Create preview URL
      const reader = new FileReader();
      reader.onloadend = () => {
        setPreviewUrl(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleUpload = () => {
    if (!selectedFile) {
      toast.error('Please select a file');
      return;
    }

    uploadMutation.mutate(selectedFile, {
      onSuccess: (response) => {
        toast.success(`Image uploaded successfully. ID: ${response.imageId}`);
        closeDialog();
      },
      onError: (error) => {
        toast.error(`Failed to upload image: ${error.message}`);
      },
    });
  };

  const openDialog = () => {
    setIsDialogOpen(true);
  };

  const closeDialog = () => {
    setIsDialogOpen(false);
    setSelectedFile(null);
    setPreviewUrl(null);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  if (isLoading) {
    return (
      <div className="space-y-4">
        <h2 className="text-3xl font-bold">Images</h2>
        <p className="text-muted-foreground">Loading images...</p>
      </div>
    );
  }

  if (isError) {
    return (
      <div className="space-y-4">
        <h2 className="text-3xl font-bold">Images</h2>
        <Alert variant="destructive">
          <AlertDescription>
            Failed to load images: {error?.message || 'Unknown error'}
          </AlertDescription>
        </Alert>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-3xl font-bold">Images</h2>
          <p className="text-muted-foreground mt-2">
            Upload and manage images for plants and groups.
          </p>
        </div>
        <Button onClick={openDialog}>Upload Image</Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Available Images</CardTitle>
          <CardDescription>
            {images.length} image(s) total
          </CardDescription>
        </CardHeader>
        <CardContent>
          {images.length === 0 ? (
            <p className="text-center text-muted-foreground py-8">
              No images found. Upload an image to get started.
            </p>
          ) : (
            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
              {images.map((image) => (
                <Card key={image.id}>
                  <CardContent className="p-4">
                    <div className="aspect-square bg-muted rounded-md overflow-hidden mb-3">
                      <img
                        src={getImageUrl(image.id)}
                        alt={image.filename}
                        className="w-full h-full object-cover"
                        onError={(e) => {
                          // Show placeholder on error
                          const target = e.target as HTMLImageElement;
                          target.style.display = 'none';
                          target.parentElement!.style.display = 'flex';
                          target.parentElement!.style.alignItems = 'center';
                          target.parentElement!.style.justifyContent = 'center';
                          target.parentElement!.innerHTML =
                            '<span class="text-muted-foreground text-sm">Image not found</span>';
                        }}
                      />
                    </div>
                    <div className="space-y-1">
                      <p className="text-sm font-medium truncate" title={image.filename}>
                        {image.filename}
                      </p>
                      <p className="text-xs text-muted-foreground truncate" title={image.id}>
                        {image.id}
                      </p>
                      <p className="text-xs text-muted-foreground">
                        {image.contentType}
                      </p>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Upload Dialog */}
      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Upload Image</DialogTitle>
            <DialogDescription>
              Upload a new image to use in plants or plant groups. Supported formats:
              JPEG, PNG, GIF.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="file-input">Select Image</Label>
              <Input
                id="file-input"
                ref={fileInputRef}
                type="file"
                accept="image/*"
                onChange={handleFileSelect}
              />
            </div>

            {previewUrl && (
              <div className="space-y-2">
                <Label>Preview</Label>
                <div className="border rounded-md overflow-hidden">
                  <img
                    src={previewUrl}
                    alt="Preview"
                    className="w-full max-h-64 object-contain bg-muted"
                  />
                </div>
                {selectedFile && (
                  <p className="text-sm text-muted-foreground">
                    {selectedFile.name} ({(selectedFile.size / 1024).toFixed(1)} KB)
                  </p>
                )}
              </div>
            )}
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={closeDialog}>
              Cancel
            </Button>
            <Button
              onClick={handleUpload}
              disabled={!selectedFile || uploadMutation.isPending}
            >
              {uploadMutation.isPending ? 'Uploading...' : 'Upload'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default Images;
