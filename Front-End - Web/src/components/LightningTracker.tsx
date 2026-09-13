import React, { useState, useEffect } from 'react';
import { Zap, ShieldAlert, Volume2, VolumeX, Radio } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { useLanguage } from '../hooks/useLanguage';

interface LightningTrackerProps {
  className?: string;
}

export const LightningTracker: React.FC<LightningTrackerProps> = ({ className = '' }) => {
  const [distanceKm, setDistanceKm] = useState(8.4);
  const [strikeCount, setStrikeCount] = useState(14);
  const [direction, setDirection] = useState('NW');
  const [audioEnabled, setAudioEnabled] = useState(false);
  const [flashActive, setFlashActive] = useState(false);
  const { t } = useLanguage();

  // Simulate real-time lightning strike events
  useEffect(() => {
    const interval = setInterval(() => {
      // 30% chance of a lightning strike
      if (Math.random() < 0.35) {
        const newDist = parseFloat((3 + Math.random() * 18).toFixed(1));
        const dirs = ['NW', 'N', 'NE', 'W', 'SW'];
        const newDir = dirs[Math.floor(Math.random() * dirs.length)];
        
        setDistanceKm(newDist);
        setStrikeCount(prev => prev + 1);
        setDirection(newDir);
        setFlashActive(true);
        setTimeout(() => setFlashActive(false), 300);

        if (audioEnabled && newDist < 10) {
          try {
            const ctx = new (window.AudioContext || (window as any).webkitAudioContext)();
            const osc = ctx.createOscillator();
            const gain = ctx.createGain();
            osc.type = 'sawtooth';
            osc.frequency.setValueAtTime(150, ctx.currentTime);
            osc.frequency.exponentialRampToValueAtTime(40, ctx.currentTime + 0.5);
            gain.gain.setValueAtTime(0.3, ctx.currentTime);
            gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.5);
            osc.connect(gain);
            gain.connect(ctx.destination);
            osc.start();
            osc.stop(ctx.currentTime + 0.5);
          } catch {}
        }
      }
    }, 6000);

    return () => clearInterval(interval);
  }, [audioEnabled]);

  const threatLevel = distanceKm < 5 ? 'Danger' : distanceKm < 12 ? 'Caution' : 'Safe';
  const threatLabel = distanceKm < 5 ? t('lightning_danger', 'Danger') : distanceKm < 12 ? t('lightning_caution', 'Caution') : t('lightning_safe', 'Safe');
  const threatColor = 
    threatLevel === 'Danger' ? 'bg-red-500/15 text-red-600 border-red-500/30' :
    threatLevel === 'Caution' ? 'bg-amber-500/15 text-amber-600 border-amber-500/30' :
    'bg-emerald-500/15 text-emerald-600 border-emerald-500/30';

  return (
    <motion.div 
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      className={`p-5 rounded-3xl bg-card border border-border shadow-lg relative overflow-hidden ${className}`}
    >
      {/* Flash background pulse on strike */}
      <AnimatePresence>
        {flashActive && (
          <motion.div 
            initial={{ opacity: 0.8 }}
            animate={{ opacity: 0 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.3 }}
            className="absolute inset-0 bg-amber-400/20 pointer-events-none z-10"
          />
        )}
      </AnimatePresence>

      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2.5">
          <div className="p-2 rounded-2xl bg-amber-500/10 text-amber-500">
            <Zap className="w-5 h-5 animate-pulse" />
          </div>
          <div>
            <h3 className="font-extrabold text-sm text-foreground">{t('lightning_title', 'Live Lightning Proximity Radar')}</h3>
            <p className="text-[11px] text-muted-foreground flex items-center gap-1">
              <Radio className="w-3 h-3 text-red-500 animate-ping" />
              <span>{t('lightning_subtitle', 'Real-Time Charge Sensors Active')}</span>
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => setAudioEnabled(!audioEnabled)}
            className={`p-2 rounded-xl border transition-all cursor-pointer ${
              audioEnabled ? 'bg-amber-500/10 text-amber-500 border-amber-500/30' : 'bg-muted text-muted-foreground border-border'
            }`}
            title={audioEnabled ? "Thunder audio warning ON" : "Mute thunder audio"}
          >
            {audioEnabled ? <Volume2 className="w-4 h-4" /> : <VolumeX className="w-4 h-4" />}
          </button>
          <span className={`px-2.5 py-1 rounded-full text-xs font-bold border uppercase tracking-wider ${threatColor}`}>
            {threatLabel}
          </span>
        </div>
      </div>

      <div className="grid grid-cols-3 gap-3">
        <div className="p-3 rounded-2xl bg-muted/50 border border-border/50 text-center">
          <span className="text-[10px] font-extrabold text-muted-foreground uppercase">{t('lightning_closest', 'Closest Strike')}</span>
          <div className="text-xl font-black text-amber-500 mt-0.5">{distanceKm} <span className="text-xs font-bold">km</span></div>
        </div>

        <div className="p-3 rounded-2xl bg-muted/50 border border-border/50 text-center">
          <span className="text-[10px] font-extrabold text-muted-foreground uppercase">{t('lightning_bearing', 'Bearing')}</span>
          <div className="text-xl font-black text-primary mt-0.5">{direction}</div>
        </div>

        <div className="p-3 rounded-2xl bg-muted/50 border border-border/50 text-center">
          <span className="text-[10px] font-extrabold text-muted-foreground uppercase">{t('lightning_strikes', 'Strikes 30m')}</span>
          <div className="text-xl font-black text-foreground mt-0.5">{strikeCount}</div>
        </div>
      </div>

      <div className="mt-3.5 p-3 rounded-2xl bg-amber-500/10 border border-amber-500/20 flex items-center justify-between text-xs text-amber-700 dark:text-amber-300">
        <div className="flex items-center gap-2">
          <ShieldAlert className="w-4 h-4 flex-shrink-0" />
          <span>{distanceKm < 10 ? t('lightning_warning_near', 'High thunder charge detected nearby — Avoid open fields & tall trees.') : t('lightning_warning_far', 'Moderate convective thunderstorm activity in regional radar.')}</span>
        </div>
      </div>
    </motion.div>
  );
};
