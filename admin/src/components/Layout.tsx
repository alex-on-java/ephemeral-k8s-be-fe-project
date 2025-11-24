import { Link, useLocation } from 'react-router-dom';
import { cn } from '@/lib/utils';

export function Layout({ children }: { children: React.ReactNode }) {
  const location = useLocation();

  const isActive = (path: string) => {
    return location.pathname === path;
  };

  return (
    <div className="min-h-screen bg-background">
      <header className="border-b bg-card">
        <div className="container mx-auto px-4 py-4">
          <h1 className="text-2xl font-bold text-foreground mb-4">
            Green Haven Admin
          </h1>
          <nav className="flex gap-6">
            <Link
              to="/plant-groups"
              className={cn(
                'px-4 py-2 rounded-md text-sm font-medium transition-colors',
                isActive('/plant-groups')
                  ? 'bg-primary text-primary-foreground'
                  : 'text-muted-foreground hover:text-foreground hover:bg-accent'
              )}
            >
              Plant Groups
            </Link>
            <Link
              to="/plants"
              className={cn(
                'px-4 py-2 rounded-md text-sm font-medium transition-colors',
                isActive('/plants')
                  ? 'bg-primary text-primary-foreground'
                  : 'text-muted-foreground hover:text-foreground hover:bg-accent'
              )}
            >
              Plants
            </Link>
            <Link
              to="/images"
              className={cn(
                'px-4 py-2 rounded-md text-sm font-medium transition-colors',
                isActive('/images')
                  ? 'bg-primary text-primary-foreground'
                  : 'text-muted-foreground hover:text-foreground hover:bg-accent'
              )}
            >
              Images
            </Link>
          </nav>
        </div>
      </header>
      <main className="container mx-auto px-4 py-8">{children}</main>
    </div>
  );
}
