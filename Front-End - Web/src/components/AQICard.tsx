import { Activity, ShieldCheck, Heart } from 'lucide-react';
import { motion } from 'motion/react';
import { useLanguage } from '../hooks/useLanguage';

interface AQICardProps {
  score?: number;
  className?: string;
}

export const AQICard: React.FC<AQICardProps> = ({ score = 64, className = '' }) => {
  const { t } = useLanguage();

  const getAQILabel = (val: number) => {
    if (val <= 50) return { label: t('aqi_good', 'Good'), color: 'text-emerald-500', bg: 'bg-emerald-500/15 border-emerald-500/30' };
    if (val <= 100) return { label: t('aqi_moderate', 'Moderate'), color: 'text-amber-500', bg: 'bg-amber-500/15 border-amber-500/30' };
    if (val <= 150) return { label: t('aqi_unhealthy_sensitive', 'Unhealthy for Sensitive Groups'), color: 'text-orange-500', bg: 'bg-orange-500/15 border-orange-500/30' };
    return { label: t('aqi_unhealthy', 'Unhealthy'), color: 'text-red-500', bg: 'bg-red-500/15 border-red-500/30' };
  };

  const status = getAQILabel(score);

  const pollutants = [
    { name: 'PM2.5', val: '18.4 µg/m³', status: 'Good' },
    { name: 'PM10', val: '42.1 µg/m³', status: 'Good' },
    { name: 'O3', val: '31.0 ppb', status: 'Moderate' },
    { name: 'NO2', val: '14.2 ppb', status: 'Good' },
  ];

  return (
    <motion.div 
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      className={`p-5 rounded-3xl bg-card border border-border shadow-lg space-y-4 ${className}`}
    >
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2.5">
          <div className="p-2 rounded-2xl bg-primary/10 text-primary">
            <Activity className="w-5 h-5" />
          </div>
          <div>
            <h3 className="font-extrabold text-sm text-foreground">{t('aqi_title', 'Air Quality Index (AQI)')}</h3>
            <p className="text-[11px] text-muted-foreground">{t('aqi_subtitle', 'Real-Time Atmospheric Particle Density')}</p>
          </div>
        </div>
        <span className={`px-3 py-1 rounded-full text-xs font-extrabold border ${status.bg} ${status.color}`}>
          {status.label}
        </span>
      </div>

      <div className="flex items-center justify-between p-4 rounded-2xl bg-muted/40 border border-border/60">
        <div>
          <span className="text-xs font-bold text-muted-foreground uppercase">{t('aqi_score_label', 'Current AQI Score')}</span>
          <div className="flex items-baseline gap-2 mt-0.5">
            <span className={`text-4xl font-black ${status.color}`}>{score}</span>
            <span className="text-xs font-bold text-muted-foreground">/ 500</span>
          </div>
        </div>

        <div className="space-y-1 text-right text-xs">
          <div className="flex items-center justify-end gap-1.5 font-bold text-foreground">
            <Heart className="w-3.5 h-3.5 text-red-500" />
            <span>{t('aqi_outdoor', 'Outdoor Running: Suitable')}</span>
          </div>
          <div className="flex items-center justify-end gap-1.5 text-muted-foreground text-[11px]">
            <ShieldCheck className="w-3.5 h-3.5 text-emerald-500" />
            <span>{t('aqi_sensitive', 'Sensitive Groups: Low Risk')}</span>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-4 gap-2">
        {pollutants.map((p, i) => (
          <div key={i} className="p-2.5 rounded-xl bg-muted/60 border border-border/40 text-center">
            <span className="text-[10px] font-extrabold text-muted-foreground block">{p.name}</span>
            <span className="text-xs font-black text-foreground mt-0.5 block">{p.val}</span>
          </div>
        ))}
      </div>
    </motion.div>
  );
};
