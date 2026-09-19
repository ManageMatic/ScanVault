import { useState } from 'react';
import {
  Wrench,
  Files,
  Scissors,
  Minimize2,
  RotateCw,
  FileSpreadsheet,
  Image,
  FileImage,
  Stamp,
  Sparkles,
  Search,
} from 'lucide-react';
import { PDF_TOOLS } from '@/lib/mockData';
import { useToast } from '@/lib/toast';

export function ToolsPage() {
  const { toast } = useToast();
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');

  const filteredTools = PDF_TOOLS.filter((tool) => {
    const matchesSearch =
      tool.title.toLowerCase().includes(searchQuery.toLowerCase().trim()) ||
      tool.description.toLowerCase().includes(searchQuery.toLowerCase().trim());
    const matchesCategory =
      selectedCategory === 'all' || tool.category === selectedCategory;
    return matchesSearch && matchesCategory;
  });

  const getToolIcon = (iconName: string) => {
    switch (iconName) {
      case 'Files':
        return <Files className="w-5 h-5" />;
      case 'Scissors':
        return <Scissors className="w-5 h-5" />;
      case 'Minimize2':
        return <Minimize2 className="w-5 h-5" />;
      case 'RotateCw':
        return <RotateCw className="w-5 h-5" />;
      case 'FileSpreadsheet':
        return <FileSpreadsheet className="w-5 h-5" />;
      case 'Image':
        return <Image className="w-5 h-5" />;
      case 'FileImage':
        return <FileImage className="w-5 h-5" />;
      case 'Stamp':
        return <Stamp className="w-5 h-5" />;
      default:
        return <Wrench className="w-5 h-5" />;
    }
  };

  const categories = [
    { id: 'all', label: 'All Tools' },
    { id: 'organize', label: 'Organize' },
    { id: 'optimize', label: 'Optimize' },
    { id: 'convert', label: 'Convert' },
    { id: 'security', label: 'Security' },
  ];

  return (
    <div className="w-full flex flex-col gap-5">
      {/* 1. Header */}
      <div>
        <div className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-primary/10 text-primary border border-primary/20 mb-1.5">
          <Sparkles className="w-3 h-3" />
          PDF Studio
        </div>
        <h2 className="text-xl xs:text-2xl font-extrabold tracking-tight text-foreground">
          PDF & Document Tools
        </h2>
        <p className="text-xs text-muted-foreground mt-0.5">
          Client-side PDF utilities running 100% offline in browser
        </p>
      </div>

      {/* 2. Search & Category Filters */}
      <div className="flex flex-col gap-3">
        <div className="relative w-full">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground pointer-events-none" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search tools (Merge, Compress, Split)..."
            className="touch-target w-full bg-surface border border-border rounded-xl pl-10 pr-4 text-xs xs:text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/40 transition-all shadow-sm"
          />
        </div>

        {/* Category Pills */}
        <div className="flex items-center gap-2 overflow-x-auto no-scrollbar pb-1 select-none">
          {categories.map((cat) => (
            <button
              key={cat.id}
              onClick={() => setSelectedCategory(cat.id)}
              className={`touch-target px-3.5 rounded-xl text-xs font-semibold whitespace-nowrap transition-all ${
                selectedCategory === cat.id
                  ? 'bg-primary text-primary-foreground shadow-sm shadow-primary/20'
                  : 'bg-surface text-muted-foreground hover:text-foreground border border-border'
              }`}
            >
              {cat.label}
            </button>
          ))}
        </div>
      </div>

      {/* 3. Responsive Tools Grid */}
      <div className="grid grid-cols-1 xs:grid-cols-2 sm:grid-cols-2 md:grid-cols-3 gap-3">
        {filteredTools.map((tool) => (
          <button
            key={tool.id}
            onClick={() =>
              toast({
                title: tool.title,
                description: 'PDF processing engine scheduled for Module 10',
                type: 'info',
              })
            }
            className="group bg-surface hover:bg-surface-secondary border border-border hover:border-primary/50 rounded-2xl p-4 flex flex-col items-start text-left transition-all active:scale-[0.98] shadow-sm hover:shadow"
          >
            <div className="flex items-center justify-between w-full mb-3">
              <div className="w-10 h-10 rounded-xl bg-primary/10 text-primary flex items-center justify-center group-hover:scale-105 transition-transform shadow-sm">
                {getToolIcon(tool.icon)}
              </div>
              {tool.badge && (
                <span className="text-[10px] font-bold text-primary bg-primary/10 px-2 py-0.5 rounded-md border border-primary/20">
                  {tool.badge}
                </span>
              )}
            </div>

            <h3 className="text-xs xs:text-sm font-bold text-foreground group-hover:text-primary transition-colors">
              {tool.title}
            </h3>
            <p className="text-[11px] text-muted-foreground mt-1 line-clamp-2 leading-relaxed">
              {tool.description}
            </p>
          </button>
        ))}
      </div>
    </div>
  );
}
