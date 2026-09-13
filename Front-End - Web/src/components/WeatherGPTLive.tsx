import { useState } from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { 
  Sparkles, 
  Send, 
  Loader2, 
  AlertCircle, 
  MapPin, 
  Languages, 
  Zap, 
  RefreshCw,
  Search,
  CheckCircle2,
  Copy,
  Check
} from 'lucide-react';
import { askWeatherGPT, getUserLocation, type AskApiResponse } from '../services/weatherGptApi';
import { cn } from '../utils/cn';
import { useLanguage } from '../hooks/useLanguage';

interface WeatherGPTLiveProps {
  className?: string;
  defaultQuestion?: string;
}

export function WeatherGPTLive({ className, defaultQuestion = '' }: WeatherGPTLiveProps) {
  const [question, setQuestion] = useState(defaultQuestion);
  const [loading, setLoading] = useState(false);
  const [response, setResponse] = useState<AskApiResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);
  const { t } = useLanguage();

  const sampleQueries = [
    { label: "Kale Rajkot ma varsad hase?", lang: "Gujarati (Roman)" },
    { label: "Morbi ma kale garmi kevi hase?", lang: "Gujarati" },
    { label: "क्या आज राजकोट में बारिश होगी?", lang: "Hindi" },
    { label: "What is the 7-day weather forecast for Ahmedabad?", lang: "English" },
  ];

  const handleSubmit = async (queryToSubmit?: string) => {
    const q = (queryToSubmit || question).trim();
    if (!q || loading) return;

    setQuestion(q);
    setLoading(true);
    setError(null);

    try {
      // Try fetching location silently
      const loc = await getUserLocation();
      
      const res = await askWeatherGPT({
        question: q,
        location: loc,
      });

      if (res.success && res.answer) {
        setResponse(res);
      } else {
        const errMsg = typeof res.error === 'string' 
          ? res.error 
          : (res.error?.message || res.answer || 'Unable to fetch weather forecast for this query.');
        setError(errMsg);
        // If there's partial answer despite failure indication (e.g., prompt asking for valid city)
        if (res.answer) {
          setResponse(res);
        }
      }
    } catch (err: any) {
      setError(err?.message || 'Failed to connect to WeatherGPT live service.');
    } finally {
      setLoading(false);
    }
  };

  const getIntentBadge = (intent?: string) => {
    switch (intent) {
      case 'rain_forecast':
        return { label: '🌧️ Rain Forecast', color: 'bg-blue-500/15 text-blue-600 dark:text-blue-400 border-blue-500/30' };
      case 'temperature':
        return { label: '🌡️ Temperature', color: 'bg-amber-500/15 text-amber-600 dark:text-amber-400 border-amber-500/30' };
      case 'general_forecast':
        return { label: '🌤️ General Forecast', color: 'bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 border-emerald-500/30' };
      default:
        return { label: intent ? `⚡ ${intent}` : '✨ AI Answer', color: 'bg-purple-500/15 text-purple-600 dark:text-purple-400 border-purple-500/30' };
    }
  };

  const getLanguageLabel = (lang?: string) => {
    switch (lang) {
      case 'gu': return '🇮🇳 Gujarati (ગુજરાતી)';
      case 'hi': return '🇮🇳 Hindi (हिन्दी)';
      case 'en': return '🇺🇸 English';
      default: return lang ? lang.toUpperCase() : '🌐 Auto';
    }
  };

  return (
 <div className={cn("glass-panel dark: text-white border border-[#2A6147] dark:border-[#1E3A2B] rounded-4xl p-6 md:p-8 shadow-xl relative overflow-hidden", className)}> 
      {/* Subtle atmospheric ambient glow inside dark green card */}
      <div className="absolute top-0 right-0 w-72 h-72 bg-emerald-500/10 rounded-full blur-3xl pointer-events-none -mr-20 -mt-20" />
      
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-6 border-b border-white/15 pb-5 relative z-10">
        <div className="flex items-center gap-3.5">
          <div className="p-3 bg-white/10 border border-white/20 text-emerald-300 rounded-2xl shadow-xs">
            <Sparkles className="w-6 h-6 animate-pulse" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h3 className="font-black text-2xl tracking-tight text-white">WeatherGPT</h3>
              <span className="text-[10px] bg-emerald-400/20 text-emerald-200 border border-emerald-400/30 px-2.5 py-0.5 rounded-full font-bold flex items-center gap-1.5">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-ping" />
                Live AI
              </span>
            </div>
            <p className="text-xs text-emerald-100/70 mt-0.5 font-medium">
              AI weather insight
            </p>
          </div>
        </div>

        {response?.location?.name && (
          <div className="flex items-center gap-1.5 text-xs font-bold px-3.5 py-1.5 bg-white/10 text-emerald-100 rounded-full border border-white/20 self-start sm:self-auto">
            <MapPin className="w-3.5 h-3.5 text-emerald-300" />
            <span>{response.location.name}{response.location.state ? `, ${response.location.state}` : ''}</span>
          </div>
        )}
      </div>

      {/* Clean Search Bar */}
      <form 
        onSubmit={(e) => {
          e.preventDefault();
          handleSubmit();
        }}
        className="space-y-3 relative z-10"
      >
        <div className="relative flex items-center">
          <Search className="absolute left-4.5 w-5 h-5 text-white/50 pointer-events-none" />
          <input
            type="text"
            value={question}
            onChange={(e) => setQuestion(e.target.value)}
            placeholder='Search a city or ask "Tomorrow in Rajkot rain chance?"...'
            disabled={loading}
            className="w-full pl-12 pr-32 py-4 bg-black/20 hover:bg-black/25 border border-white/20 rounded-2xl text-sm font-medium text-white placeholder:text-emerald-100/50 focus:outline-none focus:ring-2 focus:ring-emerald-400/50 focus:border-transparent transition-all"
          />
          <button
            type="submit"
            disabled={!question.trim() || loading}
            className="absolute right-2 px-4 py-2.5 bg-white text-[#123F2B] font-bold rounded-xl text-xs flex items-center gap-2 hover:bg-emerald-50 disabled:opacity-50 transition-all shadow-xs cursor-pointer"
          >
            {loading ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin text-[#123F2B]" />
                <span>Asking...</span>
              </>
            ) : (
              <>
                <span>Ask AI</span>
                <Send className="w-3.5 h-3.5" />
              </>
            )}
          </button>
        </div>

        {/* Suggestion Chips */}
        <div className="flex flex-wrap items-center gap-2 pt-1">
          <span className="text-[11px] font-bold text-emerald-200/70 uppercase tracking-wider flex items-center gap-1">
            <Zap className="w-3 h-3 text-amber-300" />
            Try:
          </span>
          {sampleQueries.map((item, idx) => (
            <button
              key={idx}
              type="button"
              onClick={() => handleSubmit(item.label)}
              disabled={loading}
              className="text-xs bg-white/10 hover:bg-white/20 border border-white/15 text-emerald-50 px-3 py-1.5 rounded-xl transition-all cursor-pointer text-left"
            >
              "{item.label}"
            </button>
          ))}
        </div>
      </form>

      {/* Loading Spinner State (Requirement 2) */}
      {loading && (
        <div className="my-6 p-8 bg-muted/30 border border-border/60 rounded-2xl flex flex-col items-center justify-center text-center gap-3 animate-in fade-in duration-300">
          <div className="relative flex items-center justify-center">
            <div className="w-12 h-12 rounded-full border-4 border-primary/20 border-t-primary animate-spin" />
            <Sparkles className="w-5 h-5 text-amber-400 absolute animate-pulse" />
          </div>
          <div>
            <h4 className="font-bold text-sm text-foreground">{t('gpt_fetching')}</h4>
            <p className="text-xs text-muted-foreground mt-1">
              {t('gpt_querying')} <span className="font-mono text-primary">weathergpt-backend-46or.onrender.com</span>
            </p>
          </div>
        </div>
      )}

      {/* Error Handling State (Requirement 4) */}
      {error && !loading && (
        <div className="my-4 p-4 bg-red-500/10 border border-red-500/30 rounded-2xl text-red-600 dark:text-red-400 flex items-start justify-between gap-3 animate-in slide-in-from-top-2">
          <div className="flex items-start gap-2.5">
            <AlertCircle className="w-5 h-5 flex-shrink-0 mt-0.5" />
            <div>
              <h5 className="font-bold text-xs uppercase tracking-wider">{t('gpt_error_title')}</h5>
              <p className="text-xs mt-0.5 leading-relaxed">{error}</p>
            </div>
          </div>
          <button
            type="button"
            onClick={() => handleSubmit()}
            className="px-3 py-1 bg-red-500/20 hover:bg-red-500/30 text-red-700 dark:text-red-300 rounded-lg text-xs font-bold transition-all flex items-center gap-1 cursor-pointer flex-shrink-0"
          >
            <RefreshCw className="w-3 h-3" />
            {t('gpt_retry')}
          </button>
        </div>
      )}

      {/* Response Render with Markdown formatting & newline support (Requirement 3) */}
      {response && !loading && response.answer && (
        <div className="mt-5 space-y-4 animate-in fade-in duration-400">
          {/* Metadata Badges */}
          <div className="flex flex-wrap items-center gap-2 pt-3 border-t border-white/15">
            {response.intent && (
              <span className="text-xs font-bold px-2.5 py-1 rounded-lg bg-white/10 text-white border border-white/20 flex items-center gap-1">
                {getIntentBadge(response.intent).label}
              </span>
            )}

            {response.language && (
              <span className="text-xs font-semibold px-2.5 py-1 bg-white/10 text-emerald-100 rounded-lg border border-white/15 flex items-center gap-1">
                <Languages className="w-3.5 h-3.5 text-emerald-300" />
                {getLanguageLabel(response.language)}
              </span>
            )}

            {response.location?.name && (
              <span className="text-xs font-semibold px-2.5 py-1 bg-white/10 text-emerald-100 rounded-lg border border-white/15 flex items-center gap-1">
                <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400" />
                {t('gpt_location_verified')}
              </span>
            )}
          </div>

          {/* Markdown Content Box with Natural Response Formatting */}
          <div className="relative group p-6 bg-black/20 border border-white/15 rounded-2xl text-white text-sm sm:text-base leading-relaxed overflow-x-auto">
            <button
              onClick={() => {
                navigator.clipboard.writeText(response.answer || '');
                setCopied(true);
                setTimeout(() => setCopied(false), 2000);
              }}
              className="absolute top-3.5 right-3.5 p-2 bg-white/15 hover:bg-white/25 border border-white/20 text-white rounded-lg transition-all opacity-0 group-hover:opacity-100 shadow-xs cursor-pointer z-10"
              title="Copy answer"
            >
              {copied ? <Check className="w-4 h-4 text-emerald-300" /> : <Copy className="w-4 h-4" />}
            </button>
            <article className="prose prose-invert max-w-none prose-p:my-2 prose-p:leading-relaxed prose-headings:font-black prose-headings:text-white prose-ul:my-2 prose-li:my-0.5 prose-strong:text-emerald-200 whitespace-pre-line text-emerald-50">
              <ReactMarkdown remarkPlugins={[remarkGfm]}>
                {typeof response.answer === 'string' ? response.answer : String(response.answer || '')}
              </ReactMarkdown>
            </article>
          </div>

          {/* Current Weather Summary Card */}
          {response.weather && (
            <div className="p-4 bg-primary/5 border border-primary/20 rounded-2xl">
              <h4 className="text-xs font-bold uppercase text-primary mb-3 flex items-center gap-2">
                <Sparkles className="w-4 h-4" /> Current Weather Summary
              </h4>
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                <div className="bg-background/80 p-3 rounded-xl border border-border/50">
                  <span className="text-[10px] text-muted-foreground uppercase font-bold block">Temperature</span>
                  <span className="text-lg font-black">{response.weather.temperature}°C</span>
                  <span className="text-[10px] text-muted-foreground ml-1">Feels {response.weather.apparentTemperature}°</span>
                </div>
                <div className="bg-background/80 p-3 rounded-xl border border-border/50">
                  <span className="text-[10px] text-muted-foreground uppercase font-bold block">Condition</span>
                  <span className="text-sm font-bold mt-1 block">{response.weather.condition}</span>
                </div>
                <div className="bg-background/80 p-3 rounded-xl border border-border/50">
                  <span className="text-[10px] text-muted-foreground uppercase font-bold block">Rain / Humidity</span>
                  <span className="text-sm font-bold mt-1 block">{response.weather.rain_probability}% / {response.weather.humidity}%</span>
                </div>
                <div className="bg-background/80 p-3 rounded-xl border border-border/50">
                  <span className="text-[10px] text-muted-foreground uppercase font-bold block">Wind Speed</span>
                  <span className="text-sm font-bold mt-1 block">{response.weather.windSpeed} km/h</span>
                </div>
                <div className="bg-background/80 p-3 rounded-xl border border-border/50">
                  <span className="text-[10px] text-muted-foreground uppercase font-bold block">UV Index</span>
                  <span className="text-sm font-bold mt-1 block">{response.weather.uvIndex}</span>
                </div>
              </div>
            </div>
          )}

          {/* Risk Badges / Alerts */}
          {response.riskScores?.alerts && response.riskScores.alerts.length > 0 && (
            <div className="space-y-2">
              {response.riskScores.alerts.map((alert, idx) => (
                <div key={idx} className="p-3 bg-red-500/10 border border-red-500/30 rounded-xl text-red-600 dark:text-red-400 text-xs font-semibold flex items-start gap-2">
                  <AlertCircle className="w-4 h-4 mt-0.5 flex-shrink-0" />
                  <span>{typeof alert === 'string' ? alert : (alert as any).message || JSON.stringify(alert)}</span>
                </div>
              ))}
            </div>
          )}

          {/* Smart Advisory Panel */}
          {response.advisories && (
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {response.advisories.mood && (
                <div className="p-4 bg-muted/50 border border-border rounded-xl">
                  <span className="text-2xl mb-2 block">{response.advisories.mood.emoji}</span>
                  <h5 className="font-bold text-sm mb-1">{response.advisories.mood.summary}</h5>
                  {Array.isArray(response.advisories.mood.clothing) && response.advisories.mood.clothing.length > 0 && (
                    <p className="text-xs text-muted-foreground mt-2">
                      <span className="font-semibold text-foreground">Wear:</span> {response.advisories.mood.clothing.join(', ')}
                    </p>
                  )}
                  {response.advisories.mood.umbrellaNeeded && (
                    <div className="mt-3 inline-flex items-center gap-1.5 text-xs font-bold bg-blue-500/10 text-blue-600 px-2 py-1 rounded-md border border-blue-500/20">
                      <span>☂️</span> Take an umbrella
                    </div>
                  )}
                </div>
              )}
              {response.advisories.bestTimeToGoOut && (
                <div className="p-4 bg-emerald-500/10 border border-emerald-500/20 rounded-xl">
                  <h5 className="font-bold text-sm text-emerald-700 dark:text-emerald-400 mb-1">Best Time to Go Out</h5>
                  <p className="text-xs text-emerald-600 dark:text-emerald-500 mt-2 leading-relaxed">
                    {response.advisories.bestTimeToGoOut.reason}
                  </p>
                  <div className="mt-3 text-xs font-bold text-emerald-700 dark:text-emerald-400">
                    Safety Score: {response.advisories.bestTimeToGoOut.safetyScore}/100
                  </div>
                </div>
              )}
            </div>
          )}

          {/* Hourly Forecast Carousel */}
          {response.timeline?.hours && response.timeline.hours.length > 0 && (
            <div className="pt-2">
              <h4 className="text-xs font-bold uppercase text-muted-foreground mb-3 px-1">Hourly Forecast</h4>
              <div className="flex gap-3 overflow-x-auto pb-4 hide-scrollbar snap-x">
                {response.timeline.hours.map((hour, idx) => (
                  <div key={idx} className="flex-shrink-0 w-24 p-3 bg-card border border-border rounded-2xl flex flex-col items-center text-center snap-center shadow-sm">
                    <span className="text-[11px] font-bold text-muted-foreground">{hour.hourLabel}</span>
                    <span className="text-2xl my-2">{hour.conditionEmoji}</span>
                    <span className="font-black text-sm">{hour.temperature}°</span>
                    {hour.rainProbability > 0 && (
                      <span className="text-[10px] text-blue-500 font-bold mt-1 flex items-center gap-0.5">
                        <span>💧</span> {hour.rainProbability}%
                      </span>
                    )}
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

