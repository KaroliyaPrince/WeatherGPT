import React, { useState } from 'react';
import { 
  History, 
  CloudRain, 
  Droplets, 
  Wind, 
  Sun, 
  Cloud, 
  CloudSun, 
  CloudLightning, 
  Snowflake, 
  TrendingUp, 
  TrendingDown, 
  Gauge,
  CloudOff
} from 'lucide-react';
import type { HistoricalWeatherDay } from '../../services/weatherService';

interface Last7DaysHistoryGlassProps {
  historyData: HistoricalWeatherDay[];
  convertTemp: (val: number) => number;
  tempUnit: string;
  className?: string;
  timelineTab?: 'forecast' | 'history';
  onSelectTab?: (tab: 'forecast' | 'history') => void;
}

export const Last7DaysHistoryGlass: React.FC<Last7DaysHistoryGlassProps> = ({
  historyData,
  convertTemp,
  tempUnit,
  className = '',
  timelineTab,
  onSelectTab,
}) => {
  const [selectedDay, setSelectedDay] = useState<HistoricalWeatherDay | null>(null);

  if (!historyData || historyData.length === 0) return null;

  const formattedUnit = tempUnit.startsWith('°') ? tempUnit : `°${tempUnit}`;

  const getConditionIcon = (cond?: string) => {
    const c = (cond || '').toLowerCase();
    if (c.includes('rain') || c.includes('drizzle')) return <CloudRain className="w-5 h-5 text-blue-200 shrink-0" />;
    if (c.includes('storm') || c.includes('thunder')) return <CloudLightning className="w-5 h-5 text-amber-300 shrink-0" />;
    if (c.includes('snow')) return <Snowflake className="w-5 h-5 text-cyan-200 shrink-0" />;
    if (c.includes('partly') || (c.includes('sun') && c.includes('cloud'))) return <CloudSun className="w-5 h-5 text-amber-200 shrink-0" />;
    if (c.includes('sun') || c.includes('clear')) return <Sun className="w-5 h-5 text-amber-300 shrink-0" />;
    return <Cloud className="w-5 h-5 text-white/80 shrink-0" />;
  };

  // Statistical calculations
  const totalRainfall = historyData.reduce((acc, d) => acc + (d.rainfall_mm || 0), 0);
  const maxTemps = historyData.map(d => convertTemp(d.max_temp));
  const minTemps = historyData.map(d => convertTemp(d.min_temp));
  const highestTemp = Math.max(...maxTemps);
  const lowestTemp = Math.min(...minTemps);
  const avgTemp = Math.round((historyData.reduce((acc, d) => acc + convertTemp(d.avg_temp), 0) / historyData.length) * 10) / 10;
  
  const globalMin = Math.min(...minTemps);
  const globalMax = Math.max(...maxTemps);
  const globalRange = globalMax - globalMin || 1;

  return (
    <div className={`glass-panel rounded-3xl p-5 sm:p-6 text-white transition-all shadow-xl h-full flex flex-col justify-between ${className}`}>
      <div>
        {/* Header Row */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 mb-5">
          {onSelectTab ? (
            <div className="flex items-center gap-1.5 p-1 rounded-2xl bg-white/10 text-white border border-white/10 shadow-xs">
              <button
                onClick={() => onSelectTab('forecast')}
                className={`px-3 py-1 rounded-xl text-xs font-bold transition-all cursor-pointer flex items-center gap-1.5 ${
                  timelineTab === 'forecast'
                    ? 'bg-white text-[#1D4ED8] shadow-md'
                    : 'text-white/70 hover:text-white hover:bg-white/10'
                }`}
              >
                <span>🔮 7-Day Forecast</span>
              </button>
              <button
                onClick={() => onSelectTab('history')}
                className={`px-3 py-1 rounded-xl text-xs font-bold transition-all cursor-pointer flex items-center gap-1.5 ${
                  timelineTab === 'history'
                    ? 'bg-white text-[#1D4ED8] shadow-md'
                    : 'text-white/70 hover:text-white hover:bg-white/10'
                }`}
              >
                <span>📜 Last 7 Days History</span>
              </button>
            </div>
          ) : (
            <div className="flex items-center gap-2.5">
              <div className="w-8 h-8 rounded-xl bg-white/10 flex items-center justify-center text-sky-300 border border-white/15">
                <History className="w-4 h-4" />
              </div>
              <div>
                <h2 className="text-sm sm:text-base font-bold text-white tracking-wide flex items-center gap-2">
                  <span>Past 7 Days History</span>
                  <span className="text-[10px] uppercase font-bold tracking-wider px-2 py-0.5 rounded-full bg-sky-400/20 text-sky-200 border border-sky-400/30">
                    Recorded
                  </span>
                </h2>
                <p className="text-xs text-white/60">Historical observed weather & precipitation telemetry</p>
              </div>
            </div>
          )}

          {/* 7-Day Quick Metric Pills */}
          <div className="flex items-center gap-2 flex-wrap text-xs">
            <div className="px-3 py-1.5 rounded-xl bg-white/8 border border-white/10 flex items-center gap-1.5" title="Total Rainfall in past 7 days">
              <CloudRain className="w-3.5 h-3.5 text-blue-300" />
              <span className="text-white/70">Rain:</span>
              <span className="font-bold text-white">{totalRainfall.toFixed(1)} mm</span>
            </div>

            <div className="px-3 py-1.5 rounded-xl bg-white/8 border border-white/10 flex items-center gap-1.5" title="7-Day Mean Temperature">
              <TrendingUp className="w-3.5 h-3.5 text-amber-300" />
              <span className="text-white/70">Mean:</span>
              <span className="font-bold text-white">{avgTemp}{formattedUnit}</span>
            </div>
          </div>
        </div>

        {/* Summary KPI Badges */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 mb-5">
          <div className="p-3 rounded-2xl bg-white/5 border border-white/10">
            <div className="text-[11px] text-white/60 font-medium flex items-center gap-1">
              <TrendingUp className="w-3 h-3 text-red-300" /> Peak High
            </div>
            <div className="text-lg font-black text-white mt-0.5">{highestTemp}{formattedUnit}</div>
          </div>

          <div className="p-3 rounded-2xl bg-white/5 border border-white/10">
            <div className="text-[11px] text-white/60 font-medium flex items-center gap-1">
              <TrendingDown className="w-3 h-3 text-cyan-300" /> Low Point
            </div>
            <div className="text-lg font-black text-white mt-0.5">{lowestTemp}{formattedUnit}</div>
          </div>

          <div className="p-3 rounded-2xl bg-white/5 border border-white/10">
            <div className="text-[11px] text-white/60 font-medium flex items-center gap-1">
              <Droplets className="w-3 h-3 text-sky-300" /> Wettest Day
            </div>
            <div className="text-lg font-black text-white mt-0.5">
              {historyData.reduce((prev, curr) => (prev.rainfall_mm > curr.rainfall_mm ? prev : curr)).day}
            </div>
          </div>

          <div className="p-3 rounded-2xl bg-white/5 border border-white/10">
            <div className="text-[11px] text-white/60 font-medium flex items-center gap-1">
              <Gauge className="w-3 h-3 text-emerald-300" /> Avg Wind
            </div>
            <div className="text-lg font-black text-white mt-0.5">
              {Math.round(historyData.reduce((acc, d) => acc + d.wind_kph, 0) / historyData.length)} <span className="text-xs font-normal text-white/60">km/h</span>
            </div>
          </div>
        </div>

        {/* Day by Day Historical Table/Cards */}
        <div className="space-y-2">
          {historyData.map((item, idx) => {
            const min = convertTemp(item.min_temp);
            const max = convertTemp(item.max_temp);
            
            const leftPercent = Math.max(0, Math.min(100, ((min - globalMin) / globalRange) * 100));
            const widthPercent = Math.max(15, Math.min(100 - leftPercent, ((max - min) / globalRange) * 100));
            const dateLabel = item.date ? item.date.slice(5).replace('-', '/') : '';
            const isSelected = selectedDay?.date === item.date;

            return (
              <div
                key={idx}
                onClick={() => setSelectedDay(isSelected ? null : item)}
                className={`flex items-center gap-3 py-2.5 px-3.5 rounded-2xl transition-all cursor-pointer border ${
                  isSelected 
                    ? 'bg-white/15 border-sky-400/40 shadow-sm' 
                    : 'hover:bg-white/8 border-transparent bg-white/[0.03]'
                }`}
              >
                {/* Day & Date */}
                <div className="flex items-center gap-2 w-[92px] min-w-[92px] shrink-0">
                  <span className="text-xs text-white/50 font-mono w-[38px] min-w-[38px]">{dateLabel}</span>
                  <span className="text-xs sm:text-sm font-bold text-white truncate">{item.day}</span>
                </div>

                {/* Condition Icon & Text */}
                <div className="flex items-center gap-1.5 w-[140px] min-w-[140px] shrink-0">
                  {getConditionIcon(item.condition)}
                  <span className="text-xs font-medium text-white/85 truncate">
                    {item.condition}
                  </span>
                  {item.is_stale && (
                    <span className="px-1.5 py-0.5 rounded-full bg-amber-500/25 text-amber-200 border border-amber-500/40 text-[9px] font-extrabold flex items-center gap-0.5 shrink-0" title="Cached Weather">
                      <CloudOff className="w-2.5 h-2.5 text-amber-300" /> Cached
                    </span>
                  )}
                </div>

                {/* Rain Badge */}
                <div className="w-[82px] min-w-[82px] shrink-0 flex items-center justify-start">
                  {item.rainfall_mm > 0 ? (
                    <span className="w-full py-0.5 px-2 rounded-full bg-blue-500/20 text-blue-200 border border-blue-400/25 font-semibold flex items-center justify-center gap-1 text-[11px] whitespace-nowrap">
                      <CloudRain className="w-3 h-3 shrink-0" /> {item.rainfall_mm} mm
                    </span>
                  ) : (
                    <span className="w-full py-0.5 px-2 rounded-full bg-white/5 text-white/40 border border-white/10 text-[10px] font-medium flex items-center justify-center whitespace-nowrap">
                      No Rain
                    </span>
                  )}
                </div>

                {/* Humidity telemetry */}
                <div className="w-[55px] min-w-[55px] shrink-0 hidden md:flex items-center gap-1 text-[11px] text-white/60">
                  <Droplets className="w-3 h-3 text-sky-300 shrink-0" />
                  <span>{item.humidity}%</span>
                </div>

                {/* Wind telemetry */}
                <div className="w-[75px] min-w-[75px] shrink-0 hidden lg:flex items-center gap-1 text-[11px] text-white/60">
                  <Wind className="w-3 h-3 text-cyan-300 shrink-0" />
                  <span>{item.wind_kph} km/h</span>
                </div>

                {/* Temperature Bar & Min/Max */}
                <div className="flex items-center gap-2.5 flex-1 min-w-[120px] ml-auto">
                  <span className="text-xs font-medium text-white/70 w-[28px] min-w-[28px] text-right shrink-0">
                    {min}°
                  </span>

                  <div className="flex-1 h-2 bg-black/20 rounded-full relative overflow-hidden min-w-[40px]">
                    <div
                      className="absolute top-0 bottom-0 rounded-full bg-gradient-to-r from-sky-400 via-amber-300 to-rose-400 opacity-90"
                      style={{
                        left: `${leftPercent}%`,
                        width: `${widthPercent}%`
                      }}
                    />
                  </div>

                  <span className="text-xs font-bold text-white w-[28px] min-w-[28px] text-left shrink-0">
                    {max}°
                  </span>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
