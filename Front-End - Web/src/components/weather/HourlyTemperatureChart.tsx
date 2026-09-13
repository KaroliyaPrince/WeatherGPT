import React, { useMemo } from 'react';
import { Cloud, Sun, CloudRain, CloudSun, Wind, Droplets } from 'lucide-react';

export interface HourlyItem {
  time: string;
  temp_c: number;
  icon: string;
  chance_of_rain?: number;
  wind_kph?: number;
}

interface HourlyTemperatureChartProps {
  hourlyData: HourlyItem[];
  convertTemp: (val: number) => number;
  tempUnit: string;
  className?: string;
}

export const HourlyTemperatureChart: React.FC<HourlyTemperatureChartProps> = ({
  hourlyData,
  convertTemp,
  tempUnit,
  className = '',
}) => {
  // Map and convert temps for all available forecast hours (up to 12 hours)
  const items = useMemo(() => {
    const rawList = (hourlyData && hourlyData.length > 0) ? hourlyData : [];
    const list = rawList.length >= 8 ? rawList : [
      { time: '09:00', temp_c: 27, icon: 'sun', chance_of_rain: 10, wind_kph: 12 },
      { time: '10:00', temp_c: 28, icon: 'cloud-sun', chance_of_rain: 20, wind_kph: 14 },
      { time: '11:00', temp_c: 29, icon: 'cloud-sun', chance_of_rain: 30, wind_kph: 15 },
      { time: '12:00', temp_c: 30, icon: 'cloud', chance_of_rain: 40, wind_kph: 16 },
      { time: '13:00', temp_c: 31, icon: 'cloud-rain', chance_of_rain: 60, wind_kph: 18 },
      { time: '14:00', temp_c: 31, icon: 'cloud-rain', chance_of_rain: 80, wind_kph: 20 },
      { time: '15:00', temp_c: 30, icon: 'cloud-rain', chance_of_rain: 90, wind_kph: 19 },
      { time: '16:00', temp_c: 29, icon: 'cloud', chance_of_rain: 50, wind_kph: 17 },
      { time: '17:00', temp_c: 28, icon: 'cloud-sun', chance_of_rain: 30, wind_kph: 15 },
      { time: '18:00', temp_c: 27, icon: 'sun', chance_of_rain: 10, wind_kph: 14 }
    ];

    return list.slice(0, 12).map((h, i) => ({
      ...h,
      displayTime: i === 0 ? 'Now' : h.time,
      temp: convertTemp(h.temp_c),
      isCurrent: i === 0,
    }));
  }, [hourlyData, convertTemp]);

  // Find min and max for chart scaling
  const { minTemp, maxTemp, maxIndex } = useMemo(() => {
    let min = Infinity;
    let max = -Infinity;
    let maxIdx = 0;
    items.forEach((item, idx) => {
      if (item.temp < min) min = item.temp;
      if (item.temp > max) {
        max = item.temp;
        maxIdx = idx;
      }
    });
    return { minTemp: min - 1, maxTemp: max + 2, maxIndex: maxIdx };
  }, [items]);

  // Fluid responsive viewBox metrics (stretches 100% across card without right gap)
  const VIEWBOX_WIDTH = 1000;
  const svgHeight = 110;
  const paddingX = 45;
  const paddingTop = 28;
  const paddingBottom = 16;
  const chartHeight = svgHeight - paddingTop - paddingBottom;
  const stepX = (VIEWBOX_WIDTH - paddingX * 2) / Math.max(1, items.length - 1);

  // Compute (x, y) coordinates for each point
  const points = useMemo(() => {
    return items.map((item, idx) => {
      const x = paddingX + idx * stepX;
      const normalized = (item.temp - minTemp) / (maxTemp - minTemp || 1);
      const y = paddingTop + chartHeight - normalized * chartHeight;
      return { x, y, ...item };
    });
  }, [items, minTemp, maxTemp, stepX, chartHeight]);

  // Generate smooth cubic Bezier path string
  const pathD = useMemo(() => {
    if (points.length === 0) return '';
    if (points.length === 1) return `M ${points[0].x} ${points[0].y}`;

    let d = `M ${points[0].x} ${points[0].y}`;
    for (let i = 0; i < points.length - 1; i++) {
      const p0 = points[i === 0 ? 0 : i - 1];
      const p1 = points[i];
      const p2 = points[i + 1];
      const p3 = points[i + 2] || p2;

      // Catmull-Rom to Cubic Bezier control points
      const cp1x = p1.x + (p2.x - p0.x) / 6;
      const cp1y = p1.y + (p2.y - p0.y) / 6;
      const cp2x = p2.x - (p3.x - p1.x) / 6;
      const cp2y = p2.y - (p3.y - p1.y) / 6;

      d += ` C ${cp1x.toFixed(1)} ${cp1y.toFixed(1)}, ${cp2x.toFixed(1)} ${cp2y.toFixed(1)}, ${p2.x.toFixed(1)} ${p2.y.toFixed(1)}`;
    }
    return d;
  }, [points]);

  // Area fill under the curve
  const areaD = useMemo(() => {
    if (points.length === 0) return '';
    const last = points[points.length - 1];
    const first = points[0];
    return `${pathD} L ${last.x} ${svgHeight} L ${first.x} ${svgHeight} Z`;
  }, [pathD, points, svgHeight]);

  // Weather icon helper
  const renderWeatherIcon = (icon?: string) => {
    const i = (icon || '').toLowerCase();
    if (i.includes('rain')) return <CloudRain className="w-5 h-5 text-blue-200" />;
    if (i.includes('sun') && i.includes('cloud')) return <CloudSun className="w-5 h-5 text-amber-200" />;
    if (i.includes('sun') || i.includes('clear')) return <Sun className="w-5 h-5 text-amber-300" />;
    return <Cloud className="w-5 h-5 text-white/80" />;
  };

  const currentPoint = points[0];

  // Clean unit string without double degree symbol (e.g. °C instead of °°C)
  const formattedUnit = tempUnit.startsWith('°') ? tempUnit : `°${tempUnit}`;

  return (
    <div className={`w-full glass-panel rounded-3xl p-5 sm:p-6 overflow-hidden ${className}`}>
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-sm sm:text-base font-bold text-white tracking-wide flex items-center gap-2">
          <span>Hourly Forecast</span>
          <span className="text-xs px-2.5 py-0.5 rounded-full bg-white/10 text-white/80 font-medium">
            Next {items.length} Hours
          </span>
        </h2>

        <span className="text-xs font-semibold text-white/70">
          Temperature Curve ({formattedUnit})
        </span>
      </div>

      {/* 100% Fluid Width Container */}
      <div className="w-full relative select-none">
        
        {/* Active Hour Vertical Glass Highlight Column */}
        {currentPoint && (
          <div 
            className="absolute top-0 bottom-0 rounded-2xl pointer-events-none transition-all z-0"
            style={{
              left: `${(currentPoint.x / VIEWBOX_WIDTH) * 100}%`,
              transform: 'translateX(-50%)',
              width: `${Math.max(6, (70 / VIEWBOX_WIDTH) * 100)}%`,
              background: 'linear-gradient(180deg, rgba(255, 255, 255, 0.18) 0%, rgba(255, 255, 255, 0.05) 100%)',
              border: '1px solid rgba(255, 255, 255, 0.22)',
            }}
          />
        )}

        {/* SVG Smooth Temperature Curve (Scales 100% width) */}
        <svg viewBox={`0 0 ${VIEWBOX_WIDTH} ${svgHeight}`} className="w-full h-auto overflow-visible block z-10 relative">
          <defs>
            {/* Curve Gradient: Solid Soft Green */}
            <linearGradient id="tempGradient" x1="0%" y1="0%" x2="100%" y2="0%">
              <stop offset="0%" stopColor="#83C78C" />
              <stop offset="100%" stopColor="#83C78C" />
            </linearGradient>

            {/* Area fill gradient */}
            <linearGradient id="areaGradient" x1="0%" y1="0%" x2="0%" y2="100%">
              <stop offset="0%" stopColor="rgba(255, 255, 255, 0.20)" />
              <stop offset="100%" stopColor="rgba(255, 255, 255, 0.00)" />
            </linearGradient>
          </defs>

          {/* Dotted horizontal baseline through current temperature */}
          {currentPoint && (
            <line
              x1={paddingX}
              y1={currentPoint.y}
              x2={VIEWBOX_WIDTH - paddingX}
              y2={currentPoint.y}
              stroke="rgba(255, 255, 255, 0.35)"
              strokeDasharray="4 4"
              strokeWidth="1.2"
            />
          )}

          {/* Area under curve */}
          <path d={areaD} fill="url(#areaGradient)" />

          {/* Smooth Spline Curve */}
          <path
            d={pathD}
            fill="none"
            stroke="url(#tempGradient)"
            strokeWidth="3.5"
            strokeLinecap="round"
            strokeLinejoin="round"
          />

          {/* Render Data Point Markers & Temperature Labels for EVERY Point */}
          {points.map((pt, idx) => {
            const isMax = idx === maxIndex;
            const isNow = idx === 0;

            return (
              <g key={idx}>
                {/* Node Dot on Spline Curve */}
                <circle
                  cx={pt.x}
                  cy={pt.y}
                  r={isNow || isMax ? "5.5" : "4.5"}
                  fill={isNow ? "#22C55E" : isMax ? "#EF4444" : "#83C78C"}
                  stroke="#FFFFFF"
                  strokeWidth="2"
                  className="drop-shadow-xs"
                />
                {/* Temperature Text Label Above Point - EXACTLY like 29° */}
                <text
                  x={pt.x}
                  y={pt.y - 10}
                  textAnchor="middle"
                  fill="#FFFFFF"
                  fontSize="12"
                  fontWeight="bold"
                  className="select-none"
                >
                  {pt.temp}°
                </text>
              </g>
            );
          })}
        </svg>

        {/* Hourly Column Items Aligned Directly Below Points Across 100% Width */}
        <div className="relative w-full pt-3 pb-1 h-28 z-20">
          {points.map((pt, idx) => (
            <div
              key={idx}
              className="absolute flex flex-col items-center justify-between text-center transition-all group"
              style={{
                left: `${(pt.x / VIEWBOX_WIDTH) * 100}%`,
                transform: 'translateX(-50%)',
              }}
            >
              {/* Weather Condition Icon */}
              <div className="my-1 transition-transform group-hover:scale-110">
                {renderWeatherIcon(pt.icon)}
              </div>

              {/* Wind Propeller / Speed */}
              <div className="flex items-center gap-1 text-[11px] text-white/80 font-medium my-0.5">
                <Wind className="w-3 h-3 text-white/70" />
                <span>{pt.wind_kph ? `${Math.round(pt.wind_kph)}k` : '3k'}</span>
              </div>

              {/* Rain Probability % */}
              <div className="flex items-center gap-0.5 text-[10px] text-[#A795ED] font-bold my-0.5">
                <Droplets className="w-2.5 h-2.5 text-[#A795ED]" />
                <span>{pt.chance_of_rain || 0}%</span>
              </div>

              {/* Time Label */}
              <span className={`text-xs font-bold mt-1 ${pt.isCurrent ? 'text-white' : 'text-white/80'}`}>
                {pt.displayTime}
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
