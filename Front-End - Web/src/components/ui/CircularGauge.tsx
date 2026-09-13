import { motion } from 'framer-motion';
import { cn } from '../../utils/cn';

interface CircularGaugeProps {
  value: number;
  max?: number;
  title: string;
  color?: string;
  icon?: React.ReactNode;
  size?: number;
  strokeWidth?: number;
}

export function CircularGauge({
  value,
  max = 100,
  title,
  color = 'text-primary',
  icon,
  size = 120,
  strokeWidth = 10,
}: CircularGaugeProps) {
  const radius = (size - strokeWidth) / 2;
  const circumference = radius * 2 * Math.PI;
  const safeValue = Math.min(Math.max(value, 0), max);
  const percent = safeValue / max;
  const offset = circumference - percent * circumference;

  return (
    <div className="flex flex-col items-center justify-center relative">
      <div style={{ width: size, height: size }} className="relative drop-shadow-md">
        {/* Background Circle */}
        <svg
          className="transform -rotate-90 w-full h-full"
          width={size}
          height={size}
        >
          <circle
            className="text-muted/30 stroke-current"
            strokeWidth={strokeWidth}
            fill="transparent"
            r={radius}
            cx={size / 2}
            cy={size / 2}
          />
          {/* Foreground Circle */}
          <motion.circle
            className={cn("stroke-current transition-all duration-1000 ease-out", color)}
            strokeWidth={strokeWidth}
            strokeDasharray={circumference}
            strokeDashoffset={circumference}
            strokeLinecap="round"
            fill="transparent"
            r={radius}
            cx={size / 2}
            cy={size / 2}
            initial={{ strokeDashoffset: circumference }}
            animate={{ strokeDashoffset: offset }}
            transition={{ duration: 1.5, ease: "easeOut" }}
          />
        </svg>
        
        {/* Inner Content */}
        <div className="absolute inset-0 flex flex-col items-center justify-center text-center">
          {icon && <div className={cn("mb-0.5", color)}>{icon}</div>}
          <span className="text-xl font-black text-foreground">{Math.round(value)}</span>
          <span className="text-[10px] text-muted-foreground uppercase font-bold tracking-wider">{title}</span>
        </div>
      </div>
    </div>
  );
}
