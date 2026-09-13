import React from 'react';
import { Activity, ShieldCheck, Wind, Gauge, Sparkles } from 'lucide-react';

interface AirQualityGlassProps {
  score?: number;
  pm25?: number;
  pm10?: number;
  o3?: number;
  no2?: number;
  statusText?: string;
  className?: string;
}

export const AirQualityGlass: React.FC<AirQualityGlassProps> = ({
  score = 50,
  pm25 = 9.4,
  pm10 = 18.1,
  o3 = 24.2,
  no2 = 12.8,
  statusText,
  className = '',
}) => {
  const getAQIInfo = (val: number) => {
    if (val <= 50) {
      return {
        label: statusText || 'Good',
        color: 'text-emerald-300',
        badgeBg: 'bg-emerald-400/20 border-emerald-400/30 text-emerald-200',
        advice: 'Air quality is satisfactory and poses little or no risk for outdoor activities.',
        progressColor: 'from-emerald-400 to-teal-300',
      };
    }
    if (val <= 100) {
      return {
        label: statusText || 'Satisfactory',
        color: 'text-amber-300',
        badgeBg: 'bg-amber-400/20 border-amber-400/30 text-amber-200',
        advice: 'Air quality is acceptable; sensitive individuals should monitor prolonged exposure.',
        progressColor: 'from-emerald-400 via-amber-300 to-amber-400',
      };
    }
    if (val <= 150) {
      return {
        label: statusText || 'Moderate',
        color: 'text-orange-300',
        badgeBg: 'bg-orange-400/20 border-orange-400/30 text-orange-200',
        advice: 'Sensitive groups may experience health effects. Limit prolonged outdoor exertion.',
        progressColor: 'from-amber-400 to-orange-500',
      };
    }
    return {
      label: statusText || 'Unhealthy',
      color: 'text-rose-300',
      badgeBg: 'bg-rose-500/20 border-rose-500/30 text-rose-200',
      advice: 'Health warnings of emergency conditions. Everyone should avoid outdoor activity.',
      progressColor: 'from-orange-500 to-rose-600',
    };
  };

  const aqiInfo = getAQIInfo(score);
  const percentage = Math.min(100, Math.round((score / 300) * 100));

  return (
    <div className={`glass-panel rounded-3xl p-5 sm:p-6 text-white flex flex-col justify-between ${className}`}>
      <div>
        {/* Header */}
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <Activity className="w-4 h-4 text-emerald-300" />
            <h2 className="text-sm sm:text-base font-bold text-white tracking-wide">
              Air Quality
            </h2>
          </div>
          <span className={`px-2.5 py-0.5 rounded-full text-xs font-bold border ${aqiInfo.badgeBg}`}>
            {aqiInfo.label}
          </span>
        </div>

        {/* Main Score Display */}
        <div className="flex items-baseline justify-between mb-3">
          <div>
            <span className="text-4xl sm:text-5xl font-black text-white tracking-tight">
              {score}
            </span>
            <span className="text-xs text-white/60 font-semibold ml-1.5">
              AQI
            </span>
          </div>
          <div className="flex items-center gap-1 text-xs text-white/75 font-medium">
            <ShieldCheck className="w-3.5 h-3.5 text-emerald-300" />
            <span>Real-time index</span>
          </div>
        </div>

        {/* Gradient Progress Bar */}
        <div className="w-full h-2 rounded-full bg-black/20 overflow-hidden mb-4 p-0.5">
          <div
            className={`h-full rounded-full bg-gradient-to-r ${aqiInfo.progressColor} transition-all duration-700`}
            style={{ width: `${Math.max(8, percentage)}%` }}
          />
        </div>

        {/* Pollutants Breakdown (4 Metrics Grid) */}
        <div className="grid grid-cols-2 gap-2.5 pt-3 border-t border-white/10">
          <div className="glass-panel p-2.5 rounded-xl flex items-center justify-between">
            <div className="flex items-center gap-1.5">
              <Wind className="w-3.5 h-3.5 text-white/60" />
              <span className="text-xs font-semibold text-white/80">PM 2.5</span>
            </div>
            <span className="text-xs font-extrabold text-white">{pm25} µg/m³</span>
          </div>

          <div className="glass-panel p-2.5 rounded-xl flex items-center justify-between">
            <div className="flex items-center gap-1.5">
              <Wind className="w-3.5 h-3.5 text-white/60" />
              <span className="text-xs font-semibold text-white/80">PM 10</span>
            </div>
            <span className="text-xs font-extrabold text-white">{pm10} µg/m³</span>
          </div>

          <div className="glass-panel p-2.5 rounded-xl flex items-center justify-between">
            <div className="flex items-center gap-1.5">
              <Gauge className="w-3.5 h-3.5 text-white/60" />
              <span className="text-xs font-semibold text-white/80">O3 Ozone</span>
            </div>
            <span className="text-xs font-extrabold text-white">{o3} ppb</span>
          </div>

          <div className="glass-panel p-2.5 rounded-xl flex items-center justify-between">
            <div className="flex items-center gap-1.5">
              <Gauge className="w-3.5 h-3.5 text-white/60" />
              <span className="text-xs font-semibold text-white/80">NO2</span>
            </div>
            <span className="text-xs font-extrabold text-white">{no2} ppb</span>
          </div>
        </div>
      </div>

      {/* Health Advice & Status Card at Bottom */}
      <div className="mt-4 pt-3 border-t border-white/10 bg-white/5 rounded-2xl p-3 flex items-start gap-2.5">
        <Sparkles className="w-4 h-4 text-emerald-300 flex-shrink-0 mt-0.5" />
        <p className="text-xs text-white/80 leading-relaxed">
          {aqiInfo.advice}
        </p>
      </div>
    </div>
  );
};
