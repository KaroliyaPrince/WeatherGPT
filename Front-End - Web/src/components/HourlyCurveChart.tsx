import { useState } from 'react';
import { CloudRain, Sun, Cloud, Wind, Droplets } from 'lucide-react';
import { useUserProfile } from '../hooks/useUserProfile';
import { motion } from 'motion/react';
import { cn } from '../utils/cn';

interface HourlyData {
  time: string;
  temp_c: number;
  condition: string;
  chance_of_rain: number;
  wind_kph?: number;
  icon?: string;
}

interface HourlyCurveChartProps {
  hourly?: HourlyData[];
  className?: string;
}

export function HourlyCurveChart({ hourly, className }: HourlyCurveChartProps) {
  const { convertTemp, tempUnitSymbol } = useUserProfile();
  const [selectedIdx, setSelectedIdx] = useState<number | null>(null);

  // Fallback demo hourly data matching reference photo structure if data is missing
  const defaultHourly: HourlyData[] = [
    { time: '8 AM', temp_c: 26, condition: 'Cloudy', chance_of_rain: 10, wind_kph: 12 },
    { time: '9 AM', temp_c: 27, condition: 'Cloudy', chance_of_rain: 15, wind_kph: 14 },
    { time: '10 AM', temp_c: 29, condition: 'Partly Cloudy', chance_of_rain: 20, wind_kph: 15 },
    { time: '11 AM', temp_c: 29.5, condition: 'Partly Cloudy', chance_of_rain: 25, wind_kph: 16 },
    { time: '12 PM', temp_c: 31, condition: 'Sunny', chance_of_rain: 5, wind_kph: 18 },
    { time: '1 PM', temp_c: 33, condition: 'Sunny', chance_of_rain: 5, wind_kph: 20 },
    { time: '2 PM', temp_c: 34, condition: 'Sunny', chance_of_rain: 10, wind_kph: 19 },
    { time: '3 PM', temp_c: 33.5, condition: 'Partly Cloudy', chance_of_rain: 20, wind_kph: 17 },
    { time: '4 PM', temp_c: 32, condition: 'Rain', chance_of_rain: 60, wind_kph: 22 },
    { time: '5 PM', temp_c: 30, condition: 'Rain', chance_of_rain: 80, wind_kph: 25 },
    { time: '6 PM', temp_c: 28, condition: 'Cloudy', chance_of_rain: 40, wind_kph: 18 },
    { time: '7 PM', temp_c: 27, condition: 'Clear', chance_of_rain: 10, wind_kph: 15 }
  ];

  const dataList = (hourly && hourly.length > 0) ? hourly : defaultHourly;

  // Compute curve metrics
  const temps = dataList.map(d => convertTemp(d.temp_c));
  const minTemp = Math.min(...temps) - 2;
  const maxTemp = Math.max(...temps) + 2;
  const tempRange = Math.max(1, maxTemp - minTemp);

  const cardHeight = 220;
  const itemWidth = 85;
  const paddingX = 40;
  const chartHeight = 110;
  const topOffset = 70;

  const points = temps.map((t, i) => {
    const x = paddingX + i * itemWidth;
    // inverted Y scale (higher temp = smaller Y)
    const normalized = (t - minTemp) / tempRange;
    const y = topOffset + (1 - normalized) * chartHeight;
    return { x, y, temp: t, raw: dataList[i] };
  });

  // Smooth SVG Path generator (Cubic Bezier)
  const generateSmoothPath = (pts: { x: number; y: number }[]) => {
    if (pts.length === 0) return '';
    if (pts.length === 1) return `M ${pts[0].x} ${pts[0].y}`;

    let path = `M ${pts[0].x} ${pts[0].y}`;
    for (let i = 0; i < pts.length - 1; i++) {
      const current = pts[i];
      const next = pts[i + 1];
      const mx = (current.x + next.x) / 2;
      path += ` C ${mx} ${current.y}, ${mx} ${next.y}, ${next.x} ${next.y}`;
    }
    return path;
  };

  const curvePath = generateSmoothPath(points);
  const totalWidth = paddingX * 2 + (points.length - 1) * itemWidth;
  
  // Closed area path for gradient under curve
  const firstPt = points[0];
  const lastPt = points[points.length - 1];
  const areaPath = points.length > 0 
    ? `${curvePath} L ${lastPt.x} ${cardHeight + 20} L ${firstPt.x} ${cardHeight + 20} Z`
    : '';

  const getRainIntensity = (chance: number) => {
    if (chance > 60) return { label: 'Mod', color: 'bg-blue-500/20 text-blue-400 border-blue-500/30' };
    if (chance > 20) return { label: 'Weak', color: 'bg-teal-500/20 text-teal-400 border-teal-500/30' };
    return { label: 'None', color: 'bg-slate-700/30 text-slate-400 border-slate-700/30' };
  };

  const getWeatherIcon = (cond?: string) => {
    const lower = (cond || '').toLowerCase();
    if (lower.includes('rain') || lower.includes('drizzle')) return <CloudRain className="w-5 h-5 text-blue-400 animate-pulse" />;
    if (lower.includes('cloud')) return <Cloud className="w-5 h-5 text-slate-300" />;
    return <Sun className="w-5 h-5 text-amber-400" />;
  };

  return (
    <div className={cn("bg-[#122247] border border-[#23386f] rounded-3xl p-5 shadow-xl text-white overflow-hidden", className)}>
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div>
          <h3 className="text-base font-bold tracking-wide flex items-center gap-2">
            <span className="w-2.5 h-2.5 rounded-full bg-amber-400 animate-ping" />
            Hourly Temperature Curve
          </h3>
          <p className="text-xs text-slate-400 mt-0.5">Smooth forecast curve & rain intensity nodes</p>
        </div>
        <span className="text-xs font-bold px-3 py-1 bg-[#1e2f5b] border border-[#23386f] rounded-full text-amber-400">
          {tempUnitSymbol.startsWith('°') ? tempUnitSymbol : `°${tempUnitSymbol}`} Curve
        </span>
      </div>

      {/* SVG & Scrollable Container */}
      <div className="overflow-x-auto hide-scrollbar relative pt-2 pb-4">
        <div style={{ width: `${Math.max(totalWidth, 600)}px`, height: `${cardHeight + 60}px` }} className="relative select-none">
          
          <svg className="absolute inset-0 w-full h-full overflow-visible pointer-events-none">
            <defs>
              <linearGradient id="curveGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#fb923c" stopOpacity="0.45" />
                <stop offset="50%" stopColor="#38bdf8" stopOpacity="0.15" />
                <stop offset="100%" stopColor="#122247" stopOpacity="0" />
              </linearGradient>
              <linearGradient id="strokeGradient" x1="0" y1="0" x2="1" y2="0">
                <stop offset="0%" stopColor="#fb923c" />
                <stop offset="50%" stopColor="#f59e0b" />
                <stop offset="100%" stopColor="#38bdf8" />
              </linearGradient>
            </defs>

            {/* Gradient Fill under curve */}
            <path d={areaPath} fill="url(#curveGradient)" />

            {/* Dashed Vertical Gridlines for each node */}
            {points.map((pt, i) => (
              <line
                key={`grid-${i}`}
                x1={pt.x}
                y1={pt.y + 12}
                x2={pt.x}
                y2={cardHeight + 10}
                stroke="#23386f"
                strokeWidth="1.5"
                strokeDasharray="4 4"
              />
            ))}

            {/* Main Smooth Bezier Line */}
            <path
              d={curvePath}
              fill="none"
              stroke="url(#strokeGradient)"
              strokeWidth="3.5"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>

          {/* HTML Overlay Nodes for crisp interactive elements */}
          {points.map((pt, i) => {
            const rainInfo = getRainIntensity(pt.raw.chance_of_rain);
            const isSelected = selectedIdx === i;

            return (
              <div
                key={`node-${i}`}
                onClick={() => setSelectedIdx(isSelected ? null : i)}
                style={{ left: `${pt.x}px` }}
                className="absolute transform -translate-x-1/2 cursor-pointer group flex flex-col items-center"
              >
                {/* Weather Icon (Positioned above temp node) */}
                <div 
                  style={{ top: `${Math.max(10, pt.y - 48)}px` }} 
                  className="absolute flex flex-col items-center transition-transform group-hover:scale-110"
                >
                  {getWeatherIcon(pt.raw.condition)}
                </div>

                {/* Temperature Node Badge (On the curve) */}
                <motion.div
                  style={{ top: `${pt.y - 14}px` }}
                  whileHover={{ scale: 1.15 }}
                  className={cn(
                    "absolute px-2.5 py-0.5 rounded-full text-xs font-black shadow-md border transition-all z-20 flex items-center justify-center min-w-[38px]",
                    isSelected 
                      ? "bg-amber-500 text-slate-950 border-amber-300 scale-110 shadow-amber-500/40" 
                      : "bg-[#122247] text-amber-300 border-[#fb923c]/70 hover:border-amber-400 hover:bg-[#1a2e5d]"
                  )}
                >
                  {pt.temp}°
                </motion.div>

                {/* Bottom Details Container (Fixed at bottom line) */}
                <div 
                  style={{ top: `${cardHeight - 20}px` }} 
                  className="absolute flex flex-col items-center gap-1.5 w-20 text-center"
                >
                  {/* Rain Intensity Pill */}
                  <span className={cn("text-[10px] font-bold px-2 py-0.5 rounded-md border", rainInfo.color)}>
                    {rainInfo.label}
                  </span>

                  {/* Wind Speed */}
                  <div className="flex items-center gap-0.5 text-[11px] text-slate-400 font-semibold">
                    <Wind className="w-3 h-3 text-slate-500" />
                    <span>{pt.raw.wind_kph || 12} km/h</span>
                  </div>

                  {/* Rain Chance */}
                  <div className="flex items-center gap-0.5 text-[11px] text-blue-400 font-bold">
                    <Droplets className="w-3 h-3" />
                    <span>{pt.raw.chance_of_rain}%</span>
                  </div>

                  {/* Hour Time Label */}
                  <span className="text-xs font-bold text-slate-200 mt-1">
                    {pt.raw.time}
                  </span>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
