import React from 'react';
import { Cloud, Sun, CloudRain, CloudLightning, Snowflake, CloudSun, Calendar, Droplets, Wind } from 'lucide-react';

export interface ForecastDay {
  date: string;
  day: string;
  min_temp: number;
  max_temp: number;
  condition: string;
  chance_of_rain?: number;
  rainfall_mm?: number;
  humidity?: number;
  wind_kph?: number;
}

interface DailyForecastGlassProps {
  forecastData: ForecastDay[];
  convertTemp: (val: number) => number;
  tempUnit: string;
  className?: string;
  timelineTab?: 'forecast' | 'history';
  onSelectTab?: (tab: 'forecast' | 'history') => void;
}

export const DailyForecastGlass: React.FC<DailyForecastGlassProps> = ({
  forecastData,
  convertTemp,
  tempUnit,
  className = '',
  timelineTab,
  onSelectTab,
}) => {
  const getConditionIcon = (cond?: string) => {
    const c = (cond || '').toLowerCase();
    if (c.includes('rain') || c.includes('drizzle')) return <CloudRain className="w-5 h-5 text-blue-200 shrink-0" />;
    if (c.includes('storm') || c.includes('thunder')) return <CloudLightning className="w-5 h-5 text-amber-300 shrink-0" />;
    if (c.includes('snow')) return <Snowflake className="w-5 h-5 text-cyan-200 shrink-0" />;
    if (c.includes('partly') || (c.includes('sun') && c.includes('cloud'))) return <CloudSun className="w-5 h-5 text-amber-200 shrink-0" />;
    if (c.includes('sun') || c.includes('clear')) return <Sun className="w-5 h-5 text-amber-300 shrink-0" />;
    return <Cloud className="w-5 h-5 text-white/80 shrink-0" />;
  };

  const formattedUnit = tempUnit.startsWith('°') ? tempUnit : `°${tempUnit}`;

  // Find min/max across all days for normalized temperature range bars
  const globalMin = Math.min(...forecastData.map(d => convertTemp(d.min_temp)));
  const globalMax = Math.max(...forecastData.map(d => convertTemp(d.max_temp)));
  const globalRange = globalMax - globalMin || 1;

  return (
    <div className={`glass-panel rounded-3xl p-5 sm:p-6 text-white h-full flex flex-col justify-between ${className}`}>
      <div>
        <div className="flex items-center justify-between mb-4 flex-wrap gap-2">
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
            <h2 className="text-sm sm:text-base font-bold text-white tracking-wide flex items-center gap-2">
              <Calendar className="w-4 h-4 text-white/75" />
              <span>7-Day Forecast</span>
            </h2>
          )}

          <span className="text-xs font-semibold text-white/60">
            Daily High / Low ({formattedUnit})
          </span>
        </div>

        <div className="space-y-2">
          {forecastData.map((item, idx) => {
            const isToday = idx === 0;
            const min = convertTemp(item.min_temp);
            const max = convertTemp(item.max_temp);
            
            // Calculate percentage bar width and left offset
            const leftPercent = Math.max(0, Math.min(100, ((min - globalMin) / globalRange) * 100));
            const widthPercent = Math.max(15, Math.min(100 - leftPercent, ((max - min) / globalRange) * 100));

            // Format date string for display (e.g., 09/12)
            const dateLabel = item.date ? item.date.slice(5).replace('-', '/') : '';

            return (
              <div
                key={idx}
                className={`flex items-center gap-3 py-2.5 px-3.5 rounded-2xl transition-all ${
                  isToday 
                    ? 'bg-white/18 border border-white/25 shadow-xs font-semibold' 
                    : 'hover:bg-white/8 border border-transparent'
                }`}
              >
                {/* Day & Date */}
                <div className="flex items-center gap-2 w-[92px] min-w-[92px] shrink-0">
                  <span className="text-xs text-white/50 font-mono w-[38px] min-w-[38px]">{dateLabel}</span>
                  <span className={`text-xs sm:text-sm font-bold truncate ${isToday ? 'text-white' : 'text-white/90'}`}>
                    {isToday ? 'Today' : item.day}
                  </span>
                </div>

                {/* Condition Icon & Text */}
                <div className="flex items-center gap-2 w-[125px] min-w-[125px] shrink-0">
                  {getConditionIcon(item.condition)}
                  <span className="text-xs font-medium text-white/85 truncate">
                    {item.condition}
                  </span>
                </div>

                {/* Rain Badge */}
                <div className="w-[82px] min-w-[82px] shrink-0 flex items-center justify-start">
                  {(item.rainfall_mm !== undefined && item.rainfall_mm > 0) ? (
                    <span className="w-full py-0.5 px-2 rounded-full bg-blue-500/20 text-blue-200 border border-blue-400/25 font-semibold flex items-center justify-center gap-1 text-[11px] whitespace-nowrap">
                      <CloudRain className="w-3 h-3 shrink-0" /> {item.rainfall_mm} mm
                    </span>
                  ) : item.chance_of_rain !== undefined && item.chance_of_rain > 0 ? (
                    <span className="w-full py-0.5 px-2 rounded-full bg-sky-500/20 text-sky-200 border border-sky-400/25 font-semibold flex items-center justify-center gap-1 text-[11px] whitespace-nowrap">
                      <CloudRain className="w-3 h-3 shrink-0" /> {item.chance_of_rain}%
                    </span>
                  ) : (
                    <span className="w-full py-0.5 px-2 rounded-full bg-white/5 text-white/40 border border-white/10 text-[10px] font-medium flex items-center justify-center whitespace-nowrap">
                      No Rain
                    </span>
                  )}
                </div>

                {/* Humidity telemetry */}
                <div className="w-[55px] min-w-[55px] shrink-0 hidden md:flex items-center gap-1 text-[11px] text-white/60">
                  {item.humidity !== undefined && (
                    <>
                      <Droplets className="w-3 h-3 text-sky-300 shrink-0" />
                      <span>{item.humidity}%</span>
                    </>
                  )}
                </div>

                {/* Wind telemetry */}
                <div className="w-[75px] min-w-[75px] shrink-0 hidden lg:flex items-center gap-1 text-[11px] text-white/60">
                  {item.wind_kph !== undefined && (
                    <>
                      <Wind className="w-3 h-3 text-cyan-300 shrink-0" />
                      <span>{item.wind_kph} km/h</span>
                    </>
                  )}
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
                        width: `${widthPercent}%`,
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
