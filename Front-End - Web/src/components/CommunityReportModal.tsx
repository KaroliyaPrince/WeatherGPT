import { useState } from 'react';
import { Card, CardHeader, CardTitle, CardContent } from './Card';
import { ShieldAlert, X, Camera } from 'lucide-react';
import { cn } from '../utils/cn';

export function CommunityReportModal({ isOpen, onClose }: { isOpen: boolean, onClose: () => void }) {
  const [condition, setCondition] = useState('');
  const [intensity, setIntensity] = useState('');
  
  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Simulate POST /api/community/report
    setTimeout(() => {
      onClose();
      // Show success toast here in real app
    }, 500);
  };

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
      <Card className="w-full max-w-md shadow-2xl border-none animate-in fade-in zoom-in-95">
        <CardHeader className="flex flex-row items-center justify-between p-4 border-b">
          <CardTitle className="text-lg flex items-center gap-2 text-primary">
            <ShieldAlert className="w-5 h-5" />
            Report Local Weather
          </CardTitle>
          <button onClick={onClose} className="p-2 hover:bg-muted rounded-full transition-colors cursor-pointer">
            <X className="w-5 h-5" />
          </button>
        </CardHeader>
        <CardContent className="p-4">
          <form onSubmit={handleSubmit} className="space-y-5">
            <div>
              <label className="block text-sm font-bold mb-2">Condition</label>
              <div className="grid grid-cols-2 gap-2">
                {['Heavy Rain', 'Light Rain', 'Sunny', 'Flooding', 'Thunderstorm', 'High Wind'].map(c => (
                  <button
                    key={c}
                    type="button"
                    onClick={() => setCondition(c)}
                    className={cn(
                      "px-3 py-2 border rounded-xl text-xs font-semibold cursor-pointer transition-all",
                      condition === c ? "bg-primary text-primary-foreground border-primary" : "hover:bg-muted"
                    )}
                  >
                    {c}
                  </button>
                ))}
              </div>
            </div>

            <div>
              <label className="block text-sm font-bold mb-2">Intensity</label>
              <div className="flex gap-2">
                {['Low', 'Moderate', 'High'].map(i => (
                  <button
                    key={i}
                    type="button"
                    onClick={() => setIntensity(i)}
                    className={cn(
                      "flex-1 py-2 border rounded-xl text-xs font-semibold cursor-pointer transition-all",
                      intensity === i 
                        ? i === 'High' ? 'bg-red-500 text-white border-red-500' : 'bg-primary text-primary-foreground border-primary'
                        : "hover:bg-muted"
                    )}
                  >
                    {i}
                  </button>
                ))}
              </div>
            </div>

            <div className="border-2 border-dashed border-border/60 rounded-xl p-4 text-center hover:bg-muted/50 transition-colors cursor-pointer">
              <Camera className="w-6 h-6 mx-auto mb-2 text-muted-foreground" />
              <span className="text-xs text-muted-foreground font-semibold">Upload Photo (Optional)</span>
            </div>

            <div>
              <label className="block text-sm font-bold mb-2">Notes</label>
              <textarea 
                className="w-full bg-muted border border-border/50 rounded-xl p-3 text-sm min-h-[80px]"
                placeholder="Describe the weather condition in your area..."
              />
            </div>

            <button 
              type="submit" 
              disabled={!condition || !intensity}
              className="w-full bg-primary text-primary-foreground rounded-xl py-3 font-bold disabled:opacity-50 hover:opacity-90 transition-opacity cursor-pointer"
            >
              Submit Report
            </button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
