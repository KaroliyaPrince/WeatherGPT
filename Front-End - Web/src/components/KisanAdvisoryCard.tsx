import { useState, useEffect } from 'react';
import { Card, CardHeader, CardTitle, CardContent } from './Card';
import { Loader2, Droplets, Sprout, ShieldAlert, CloudRain } from 'lucide-react';
import { motion } from 'framer-motion';
import { CircularGauge } from './ui/CircularGauge';
import { cn } from '../utils/cn';

interface AdvisoryData {
  krishiIndex: number;
  irrigation: {
    status: 'Irrigate' | 'Postpone';
    reason: string;
  };
  pesticide: {
    status: 'SUITABLE' | 'CAUTION' | 'UNSUITABLE';
    reason: string;
  };
  soilMoisture: string;
  nextRainWindow: string;
}

export function KisanAdvisoryCard({ location, language }: { location: string; language: string }) {
  const [data, setData] = useState<AdvisoryData | null>(null);
  const [loading, setLoading] = useState(true);

  // Mocking the API fetch for the Hackathon (since we need to GET /api/agri/advisory)
  useEffect(() => {
    setLoading(true);
    // In a real scenario:
    // fetch(`/api/agri/advisory?location=${location}&language=${language}&cropType=wheat`)
    
    setTimeout(() => {
      setData({
        krishiIndex: 78,
        irrigation: {
          status: 'Postpone',
          reason: 'Heavy rain expected in 48 hours'
        },
        pesticide: {
          status: 'CAUTION',
          reason: 'High wind speed (15 km/h) could cause spray drift'
        },
        soilMoisture: 'Moderate (45%)',
        nextRainWindow: 'Tomorrow evening (6 PM)'
      });
      setLoading(false);
    }, 1500);
  }, [location, language]);

  if (loading) {
    return (
      <Card className="shadow-lg min-h-[300px] flex items-center justify-center">
        <Loader2 className="w-8 h-8 animate-spin text-green-600" />
      </Card>
    );
  }

  if (!data) return null;

  return (
    <Card className="shadow-lg border-green-500/20 bg-gradient-to-br from-green-500/5 to-emerald-500/10">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-green-700 dark:text-green-400">
          <Sprout className="w-5 h-5" />
          Kisan Advisory / Farmer Mode
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {/* Krishi Index */}
          <div className="flex flex-col items-center justify-center bg-card rounded-2xl p-4 shadow-sm border border-border/50">
            <CircularGauge 
              value={data.krishiIndex} 
              title="Krishi Index" 
              color={data.krishiIndex > 70 ? 'text-green-500' : 'text-amber-500'} 
              size={140}
              icon={<Sprout className="w-6 h-6" />}
            />
            <p className="text-xs text-center text-muted-foreground mt-3 font-semibold">
              Farming Suitability Score
            </p>
          </div>

          {/* Actionable Advice */}
          <div className="md:col-span-2 space-y-4">
            {/* Irrigation */}
            <motion.div 
              whileHover={{ scale: 1.02 }}
              className={cn(
                "p-4 rounded-xl border flex items-start gap-3",
                data.irrigation.status === 'Irrigate' 
                  ? "bg-green-500/10 border-green-500/30 text-green-700 dark:text-green-400"
                  : "bg-red-500/10 border-red-500/30 text-red-700 dark:text-red-400"
              )}
            >
              <Droplets className="w-5 h-5 flex-shrink-0 mt-0.5" />
              <div>
                <h4 className="font-bold text-sm uppercase tracking-wide">Irrigation: {data.irrigation.status}</h4>
                <p className="text-xs mt-1 opacity-90">{data.irrigation.reason}</p>
              </div>
            </motion.div>

            {/* Pesticide */}
            <motion.div 
              whileHover={{ scale: 1.02 }}
              className={cn(
                "p-4 rounded-xl border flex items-start gap-3",
                data.pesticide.status === 'SUITABLE' ? "bg-green-500/10 border-green-500/30 text-green-700 dark:text-green-400"
                : data.pesticide.status === 'CAUTION' ? "bg-amber-500/10 border-amber-500/30 text-amber-700 dark:text-amber-400"
                : "bg-red-500/10 border-red-500/30 text-red-700 dark:text-red-400"
              )}
            >
              <ShieldAlert className="w-5 h-5 flex-shrink-0 mt-0.5" />
              <div>
                <h4 className="font-bold text-sm uppercase tracking-wide">Pesticide Spray: {data.pesticide.status}</h4>
                <p className="text-xs mt-1 opacity-90">{data.pesticide.reason}</p>
              </div>
            </motion.div>

            {/* Soil & Rain Info */}
            <div className="grid grid-cols-2 gap-3 mt-2">
              <div className="bg-background rounded-lg p-3 border border-border shadow-sm flex flex-col justify-center">
                <span className="text-[10px] text-muted-foreground uppercase font-bold">Soil Moisture</span>
                <span className="text-sm font-extrabold mt-0.5">{data.soilMoisture}</span>
              </div>
              <div className="bg-background rounded-lg p-3 border border-border shadow-sm flex flex-col justify-center">
                <span className="text-[10px] text-muted-foreground uppercase font-bold">Next Rain Window</span>
                <span className="text-sm font-extrabold mt-0.5 text-blue-500 flex items-center gap-1">
                  <CloudRain className="w-3.5 h-3.5" /> {data.nextRainWindow}
                </span>
              </div>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
