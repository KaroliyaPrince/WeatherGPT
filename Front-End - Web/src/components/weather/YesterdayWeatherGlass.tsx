import React from 'react';
import { 
  History, 
  TrendingUp, 
  TrendingDown, 
  CloudRain, 
  Sun, 
  CloudSun, 
  Cloud, 
  Wind, 
  Droplets, 
  Sparkles 
} from 'lucide-react';
import type { YesterdayWeatherData } from '../../services/weatherService';

interface YesterdayWeatherGlassProps {
  yesterdayData: YesterdayWeatherData;
  todayTempC: number;
  todayHumidity: number;
  todayPrecipMm: number;
  todayWindKph: number;
  convertTemp: (celsiusVal: number | string) => number;
  tempUnit: string;
  className?: string;
}

export const YesterdayWeatherGlass: React.FC<YesterdayWeatherGlassProps> = ({
  yesterdayData,
  todayTempC,
  todayHumidity,
  todayPrecipMm,
  todayWindKph,
  convertTemp,
  tempUnit,
  className = '',
}) => {
  const getConditionIcon = (iconName?: string) => {
    const icon = (iconName || '').toLowerCase();
    if (icon.includes('rain')) return <CloudRain className="w-5 h-5 text-blue-300" />;
    if (icon.includes('sun') && icon.includes('cloud')) return <CloudSun className="w-5 h-5 text-amber-300" />;
    if (icon.includes('sun') || icon.includes('clear')) return <Sun className="w-5 h-5 text-amber-400" />;
    return <Cloud className="w-5 h-5 text-white/80" />;
  };

  const yMax = convertTemp(yesterdayData.max_temp);
  const yMin = convertTemp(yesterdayData.min_temp);
  const yAvg = convertTemp(yesterdayData.temp_c);
  const tCur = convertTemp(todayTempC);

  const formattedUnit = tempUnit.startsWith('°') ? tempUnit : `°${tempUnit}`;

  const tempDiff = Number((tCur - yAvg).toFixed(1));
  const humidityDiff = todayHumidity - yesterdayData.humidity;
  const rainDiff = Number((todayPrecipMm - yesterdayData.precip_mm).toFixed(1));
  const windDiff = Number((todayWindKph - yesterdayData.wind_kph).toFixed(1));

  return (
    <div className={`glass-panel rounded-3xl p-5 sm:p-6 text-white space-y-6 ${className}`}>
      
      {/* Header Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-4 border-b border-white/10">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-2xl bg-white/10 flex items-center justify-center text-amber-300 border border-white/15 shadow-inner">
            <History className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-base sm:text-lg font-bold text-white tracking-wide flex items-center gap-2">
              <span>Yesterday vs Today</span>
              <span className="text-[10px] uppercase font-extrabold tracking-wider px-2 py-0.5 rounded-full bg-white/15 text-white/90 border border-white/20">
                24h Delta
              </span>
            </h2>
            <p className="text-xs text-white/60">Automated micro-climate shift comparison</p>
          </div>
        </div>

        {/* Dynamic Highlight Pill */}
        <div className="flex items-center gap-2">
          <div className={`px-3 py-1 rounded-full text-xs font-bold border flex items-center gap-1.5 ${
            tempDiff > 0 
              ? 'bg-amber-500/15 text-amber-200 border-amber-500/30' 
              : tempDiff < 0 
              ? 'bg-sky-500/15 text-sky-200 border-sky-500/30' 
              : 'bg-white/10 text-white/80 border-white/20'
          }`}>
            {tempDiff > 0 ? <TrendingUp className="w-3.5 h-3.5" /> : <TrendingDown className="w-3.5 h-3.5" />}
            <span>{tempDiff > 0 ? `+${tempDiff}${formattedUnit} Warmer` : tempDiff < 0 ? `${tempDiff}${formattedUnit} Cooler` : 'Same Temp'} vs Yesterday</span>
          </div>
        </div>
      </div>

      {/* Grid: Yesterday Overview & 4-Metric Delta Comparison */}
      <div className="grid grid-cols-1 md:grid-cols-12 gap-5">
        
        {/* Left Column (5 Cols): Yesterday Snapshot Card */}
        <div className="md:col-span-5 rounded-2xl bg-white/[0.05] border border-white/10 p-4.5 flex flex-col justify-between">
          <div className="flex items-start justify-between">
            <div>
              <div className="text-xs text-white/60 font-medium">Recorded Conditions</div>
              <div className="text-lg font-bold text-white mt-0.5">{yesterdayData.condition.text}</div>
            </div>
            <div className="p-2.5 rounded-xl bg-white/10 border border-white/15 shadow-sm">
              {getConditionIcon(yesterdayData.condition.icon)}
            </div>
          </div>

          {/* Big Temp Stats */}
          <div className="my-4">
            <div className="flex items-baseline gap-2">
              <span className="text-3xl sm:text-4xl font-black text-white">{yAvg}°</span>
              <span className="text-sm font-semibold text-white/60">avg temp</span>
            </div>
            <div className="flex items-center gap-4 text-xs font-semibold text-white/70 mt-1">
              <span>High: <strong className="text-white font-bold">{yMax}{formattedUnit}</strong></span>
              <span>•</span>
              <span>Low: <strong className="text-white font-bold">{yMin}{formattedUnit}</strong></span>
            </div>
          </div>

          {/* Mini Stats Bar */}
          <div className="grid grid-cols-3 gap-2 pt-3 border-t border-white/10 text-center">
            <div className="bg-white/[0.03] rounded-xl p-2">
              <div className="text-[10px] text-white/50">Rainfall</div>
              <div className="text-xs font-bold text-sky-200 mt-0.5">{yesterdayData.precip_mm} mm</div>
            </div>
            <div className="bg-white/[0.03] rounded-xl p-2">
              <div className="text-[10px] text-white/50">Humidity</div>
              <div className="text-xs font-bold text-white mt-0.5">{yesterdayData.humidity}%</div>
            </div>
            <div className="bg-white/[0.03] rounded-xl p-2">
              <div className="text-[10px] text-white/50">Wind Gusts</div>
              <div className="text-xs font-bold text-white mt-0.5">{yesterdayData.wind_kph} km/h</div>
            </div>
          </div>
        </div>

        {/* Right Column (7 Cols): Today vs Yesterday Comparison Cards */}
        <div className="md:col-span-7 grid grid-cols-1 sm:grid-cols-2 gap-3">
          
          {/* Card 1: Temperature Trend */}
          <div className="p-3.5 rounded-2xl bg-white/[0.04] border border-white/10 hover:bg-white/[0.07] transition-all">
            <div className="flex items-center justify-between text-xs text-white/60 mb-2">
              <span className="flex items-center gap-1.5 font-medium">
                <TrendingUp className="w-3.5 h-3.5 text-amber-300" /> Temperature
              </span>
              <span className="font-mono text-[11px] text-white/80">Today vs Y'day</span>
            </div>
            <div className="flex items-baseline justify-between">
              <div>
                <span className="text-xl font-bold text-white">{tCur}{formattedUnit}</span>
                <span className="text-xs text-white/50 ml-1.5">vs {yAvg}{formattedUnit}</span>
              </div>
              <span className={`text-xs font-bold ${tempDiff >= 0 ? 'text-amber-300' : 'text-sky-300'}`}>
                {tempDiff > 0 ? `+${tempDiff}°` : `${tempDiff}°`}
              </span>
            </div>
            <div className="text-[11px] text-white/60 mt-2 leading-tight">
              {tempDiff > 0 
                ? 'Temperatures are warmer than yesterday.' 
                : tempDiff < 0 
                ? 'Noticeably cooler conditions today.' 
                : 'Consistent temperature pattern.'}
            </div>
          </div>

          {/* Card 2: Rainfall Delta */}
          <div className="p-3.5 rounded-2xl bg-white/[0.04] border border-white/10 hover:bg-white/[0.07] transition-all">
            <div className="flex items-center justify-between text-xs text-white/60 mb-2">
              <span className="flex items-center gap-1.5 font-medium">
                <CloudRain className="w-3.5 h-3.5 text-sky-300" /> Rainfall
              </span>
              <span className="font-mono text-[11px] text-white/80">Precipitation</span>
            </div>
            <div className="flex items-baseline justify-between">
              <div>
                <span className="text-xl font-bold text-white">{todayPrecipMm} mm</span>
                <span className="text-xs text-white/50 ml-1.5">vs {yesterdayData.precip_mm} mm</span>
              </div>
              <span className={`text-xs font-bold ${rainDiff <= 0 ? 'text-emerald-300' : 'text-sky-300'}`}>
                {rainDiff > 0 ? `+${rainDiff} mm` : `${rainDiff} mm`}
              </span>
            </div>
            <div className="text-[11px] text-white/60 mt-2 leading-tight">
              {yesterdayData.precip_mm > 0 && todayPrecipMm === 0
                ? `Cleared up after yesterday's ${yesterdayData.precip_mm} mm rain.`
                : todayPrecipMm > yesterdayData.precip_mm
                ? 'Higher precipitation recorded today.'
                : 'No major rainfall change.'}
            </div>
          </div>

          {/* Card 3: Humidity & Moisture */}
          <div className="p-3.5 rounded-2xl bg-white/[0.04] border border-white/10 hover:bg-white/[0.07] transition-all">
            <div className="flex items-center justify-between text-xs text-white/60 mb-2">
              <span className="flex items-center gap-1.5 font-medium">
                <Droplets className="w-3.5 h-3.5 text-blue-300" /> Humidity
              </span>
              <span className="font-mono text-[11px] text-white/80">Atmosphere</span>
            </div>
            <div className="flex items-baseline justify-between">
              <div>
                <span className="text-xl font-bold text-white">{todayHumidity}%</span>
                <span className="text-xs text-white/50 ml-1.5">vs {yesterdayData.humidity}%</span>
              </div>
              <span className={`text-xs font-bold ${humidityDiff > 0 ? 'text-blue-300' : 'text-emerald-300'}`}>
                {humidityDiff > 0 ? `+${humidityDiff}%` : `${humidityDiff}%`}
              </span>
            </div>
            <div className="text-[11px] text-white/60 mt-2 leading-tight">
              {humidityDiff < 0 ? 'Air is crisper & less humid today.' : 'Increased moisture content today.'}
            </div>
          </div>

          {/* Card 4: Wind Speed Comparison */}
          <div className="p-3.5 rounded-2xl bg-white/[0.04] border border-white/10 hover:bg-white/[0.07] transition-all">
            <div className="flex items-center justify-between text-xs text-white/60 mb-2">
              <span className="flex items-center gap-1.5 font-medium">
                <Wind className="w-3.5 h-3.5 text-teal-300" /> Wind Speed
              </span>
              <span className="font-mono text-[11px] text-white/80">Breeze</span>
            </div>
            <div className="flex items-baseline justify-between">
              <div>
                <span className="text-xl font-bold text-white">{todayWindKph} km/h</span>
                <span className="text-xs text-white/50 ml-1.5">vs {yesterdayData.wind_kph} km/h</span>
              </div>
              <span className={`text-xs font-bold ${windDiff > 0 ? 'text-amber-300' : 'text-emerald-300'}`}>
                {windDiff > 0 ? `+${windDiff}` : `${windDiff}`} km/h
              </span>
            </div>
            <div className="text-[11px] text-white/60 mt-2 leading-tight">
              {windDiff < 0 ? 'Calmer wind conditions today.' : 'Slightly gustier breezes today.'}
            </div>
          </div>

        </div>
      </div>

      {/* Insight Summary Footer */}
      <div className="mt-4 p-3 rounded-2xl bg-sky-500/10 border border-sky-500/20 flex items-center gap-3 text-xs text-sky-100">
        <Sparkles className="w-4 h-4 text-sky-300 shrink-0" />
        <div>
          <strong>Historical Takeaway:</strong> {yesterdayData.summary}
        </div>
      </div>

    </div>
  );
};
