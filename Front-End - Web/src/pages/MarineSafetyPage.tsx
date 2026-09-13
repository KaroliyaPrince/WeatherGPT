import { useState } from 'react';
import { Waves, Anchor, ShieldAlert, Thermometer, Wind, Eye } from 'lucide-react';
import { useLanguage } from '../hooks/useLanguage';

export interface CoastalZone {
  id: string;
  name: string;
  nameGu: string;
  waveHeight: string;
  seaTemp: string;
  windSpeed: string;
  visibility: string;
  alertLevel: 'Red Alert' | 'Orange Advisory' | 'Clear Safe';
  highTide: string;
  lowTide: string;
  advisoryGu: string;
  advisoryEn: string;
}

const COASTAL_ZONES: CoastalZone[] = [
  {
    id: 'saurashtra',
    name: 'Saurashtra Coast & Gulf of Khambhat',
    nameGu: 'સૌરાષ્ટ્ર દરિયાકાંઠો અને ખંભાતનો અખાત',
    waveHeight: '2.8 - 3.4 meters (Rough Sea)',
    seaTemp: '27.4°C',
    windSpeed: '45 - 62 km/h NW',
    visibility: '3.0 km',
    alertLevel: 'Red Alert',
    highTide: '03:45 PM (4.2m)',
    lowTide: '09:20 PM (0.8m)',
    advisoryGu: 'દરિયામાં ખૂબ ઊંચા મોજા ઉછળવાની અને 62 કિમી/કલાકના પવનની શક્યતા હોવાથી માછીમારોને દરિયો ન ખેડવાની કડક સૂચના આપવામાં આવે છે.',
    advisoryEn: 'High wave warning and gale squalls up to 62 km/h. Fishermen are strictly advised not to venture into sea.'
  },
  {
    id: 'porbandar-dwarka',
    name: 'Porbandar & Dwarka Coastline',
    nameGu: 'પોરબંદર અને દ્વારકા દરિયાકાંઠો',
    waveHeight: '2.1 - 2.6 meters (Moderate to Rough)',
    seaTemp: '26.8°C',
    windSpeed: '32 - 40 km/h W',
    visibility: '5.0 km',
    alertLevel: 'Orange Advisory',
    highTide: '04:10 PM (3.8m)',
    lowTide: '10:05 PM (1.1m)',
    advisoryGu: 'દરિયાકિનારે મધ્યમ વાવાઝોડાનો સંકેત છે. નાના હોડી વાહકોએ સાવચેતી રાખવી.',
    advisoryEn: 'Moderate sea state. Small boat operators should exercise caution near shore.'
  },
  {
    id: 'mumbai-coast',
    name: 'Konkan & Mumbai Coastal Waters',
    nameGu: 'કોંકણ અને મુંબઈ દરિયાઈ વિસ્તાર',
    waveHeight: '1.5 - 2.0 meters (Slight)',
    seaTemp: '28.2°C',
    windSpeed: '20 - 28 km/h SW',
    visibility: '7.5 km',
    alertLevel: 'Clear Safe',
    highTide: '02:30 PM (3.4m)',
    lowTide: '08:45 PM (1.3m)',
    advisoryGu: 'દરિયાકાંઠે હવામાન સામાન્ય છે. નિયમિત માછીમારી પ્રવૃત્તિઓ માટે અનુકૂળ પરિસ્થિતિ.',
    advisoryEn: 'Sea conditions normal. Safe for offshore fishing and harbor navigation.'
  }
];

export default function MarineSafetyPage() {
  const { t } = useLanguage();
  const [selectedZone, setSelectedZone] = useState<CoastalZone>(COASTAL_ZONES[0]);

  const alertColor = 
    selectedZone.alertLevel === 'Red Alert' ? 'bg-red-500/15 text-red-600 border-red-500/30' :
    selectedZone.alertLevel === 'Orange Advisory' ? 'bg-orange-500/15 text-orange-600 border-orange-500/30' :
    'bg-emerald-500/15 text-emerald-600 border-emerald-500/30';

  return (
    <div className="space-y-6 pb-12 animate-in fade-in duration-300">
      {/* Header Banner */}
      <div className="p-6 sm:p-8 rounded-3xl bg-card border border-border shadow-xs flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <div className="flex items-center gap-2 text-teal-600 dark:text-teal-400 font-bold text-xs uppercase tracking-wider mb-1">
            <Anchor className="w-4 h-4" />
            <span>Marine & Coastal Safety</span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-bold text-foreground">{t('marine_title', 'Marine Safety Advisory')}</h1>
          <p className="text-xs text-muted-foreground mt-1 max-w-xl">
            {t('marine_subtitle', 'Tidal height, wave dynamics, sea surface temperature, and fisherman warnings.')}
          </p>
        </div>
      </div>

      {/* Select Coastal Zone */}
      <div className="space-y-3">
        <h3 className="text-sm font-extrabold text-foreground uppercase tracking-wider">Select Coastal Zone:</h3>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          {COASTAL_ZONES.map((zone) => (
            <button
              key={zone.id}
              onClick={() => setSelectedZone(zone)}
              className={`p-4 rounded-2xl border text-left transition-all cursor-pointer ${
                selectedZone.id === zone.id
                  ? 'bg-teal-500/10 border-teal-500 shadow-md ring-2 ring-teal-500/20'
                  : 'bg-card hover:bg-muted border-border'
              }`}
            >
              <div className="font-extrabold text-sm text-foreground">{zone.nameGu}</div>
              <div className="text-xs text-muted-foreground mt-0.5">{zone.name}</div>
            </button>
          ))}
        </div>
      </div>

      {/* Zone Deep Dive */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-6">
          <div className="p-6 rounded-3xl bg-card border border-border shadow-lg space-y-5">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="text-xl font-black text-foreground">{selectedZone.nameGu}</h2>
                <p className="text-xs text-muted-foreground">{selectedZone.name}</p>
              </div>
              <span className={`px-3.5 py-1.5 rounded-full text-xs font-black border uppercase tracking-wider ${alertColor}`}>
                {selectedZone.alertLevel}
              </span>
            </div>

            {/* Warning Callout */}
            <div className={`p-4 rounded-2xl border flex items-start gap-3 text-xs leading-relaxed ${
              selectedZone.alertLevel === 'Red Alert' ? 'bg-red-500/10 border-red-500/30 text-red-700 dark:text-red-300' : 'bg-amber-500/10 border-amber-500/30 text-amber-700 dark:text-amber-300'
            }`}>
              <ShieldAlert className="w-5 h-5 flex-shrink-0 mt-0.5" />
              <div>
                <strong className="font-extrabold block text-sm mb-0.5">માછીમાર હવામાન સૂચના:</strong>
                <span>{selectedZone.advisoryGu}</span>
              </div>
            </div>

            {/* Metrics Grid */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
              <div className="p-3.5 rounded-2xl bg-muted/50 border border-border/50">
                <div className="flex items-center gap-1.5 text-xs font-bold text-muted-foreground">
                  <Waves className="w-4 h-4 text-cyan-500" />
                  <span>Wave Height</span>
                </div>
                <div className="text-sm font-black text-foreground mt-1">{selectedZone.waveHeight}</div>
              </div>

              <div className="p-3.5 rounded-2xl bg-muted/50 border border-border/50">
                <div className="flex items-center gap-1.5 text-xs font-bold text-muted-foreground">
                  <Wind className="w-4 h-4 text-teal-500" />
                  <span>Wind Velocity</span>
                </div>
                <div className="text-sm font-black text-foreground mt-1">{selectedZone.windSpeed}</div>
              </div>

              <div className="p-3.5 rounded-2xl bg-muted/50 border border-border/50">
                <div className="flex items-center gap-1.5 text-xs font-bold text-muted-foreground">
                  <Thermometer className="w-4 h-4 text-amber-500" />
                  <span>Sea Surface Temp</span>
                </div>
                <div className="text-sm font-black text-foreground mt-1">{selectedZone.seaTemp}</div>
              </div>

              <div className="p-3.5 rounded-2xl bg-muted/50 border border-border/50">
                <div className="flex items-center gap-1.5 text-xs font-bold text-muted-foreground">
                  <Eye className="w-4 h-4 text-blue-500" />
                  <span>Coastal Visibility</span>
                </div>
                <div className="text-sm font-black text-foreground mt-1">{selectedZone.visibility}</div>
              </div>
            </div>
          </div>
        </div>

        {/* High / Low Tide Timetable */}
        <div className="space-y-4">
          <div className="p-5 rounded-3xl bg-card border border-border shadow-lg space-y-3">
            <h3 className="font-extrabold text-sm text-foreground uppercase tracking-wider">Tide Schedule (ભરતી અને ઓટ)</h3>
            <div className="space-y-3">
              <div className="p-4 rounded-2xl bg-cyan-500/10 border border-cyan-500/30 flex items-center justify-between">
                <div>
                  <span className="text-xs font-extrabold text-cyan-600 uppercase">High Tide (ભરતી)</span>
                  <div className="text-base font-black text-foreground mt-0.5">{selectedZone.highTide}</div>
                </div>
                <Waves className="w-8 h-8 text-cyan-500 animate-pulse" />
              </div>

              <div className="p-4 rounded-2xl bg-muted/50 border border-border flex items-center justify-between">
                <div>
                  <span className="text-xs font-extrabold text-muted-foreground uppercase">Low Tide (ઓટ)</span>
                  <div className="text-base font-black text-foreground mt-0.5">{selectedZone.lowTide}</div>
                </div>
                <Anchor className="w-6 h-6 text-muted-foreground" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
