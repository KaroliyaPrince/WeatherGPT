import { Card, CardContent } from './Card';
import { cn } from '../utils/cn';
import { motion } from 'motion/react';

interface WeatherStatCardProps {
  icon: React.ElementType;
  label: string;
  value: string | number;
  unit: string;
  description?: string;
  className?: string;
  index?: number;
}

export function WeatherStatCard({ icon: Icon, label, value, unit, description, className, index = 0 }: WeatherStatCardProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 15 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.35, delay: index * 0.05 }}
      whileHover={{ 
        y: -3, 
        transition: { type: 'spring', stiffness: 400, damping: 20 } 
      }}
      className="h-full"
    >
      <Card className={cn("h-full border border-border/70 bg-card hover:bg-muted/40 transition-all duration-300 rounded-3xl", className)}>
        <CardContent className="p-4 sm:p-5 flex flex-col justify-between h-full">
          <div className="flex items-center justify-between gap-2 mb-2">
            <span className="text-xs font-semibold text-muted-foreground tracking-wide">{label}</span>
            <div className="p-2 bg-muted rounded-xl text-foreground/80 flex-shrink-0">
              <Icon className="w-4 h-4 stroke-[1.75]" />
            </div>
          </div>
          <div>
            <div className="flex items-baseline gap-1">
              <h4 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-foreground">{value}</h4>
              <span className="text-xs font-bold text-muted-foreground">{unit}</span>
            </div>
            {description && <p className="text-[11px] text-muted-foreground mt-1 line-clamp-1 leading-normal">{description}</p>}
          </div>
        </CardContent>
      </Card>
    </motion.div>
  );
}
