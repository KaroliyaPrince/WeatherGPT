import React, { useState } from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { 
  Sparkles, 
  Send, 
  Loader2, 
  AlertCircle, 
  Bot, 
  Copy, 
  Check, 
  ArrowRight,
  ShieldCheck
} from 'lucide-react';
import { askWeatherGPT, type AskApiResponse } from '../../services/weatherGptApi';

interface WeatherGPTAssistantGlassProps {
  currentLocationName?: string;
  className?: string;
}

export const WeatherGPTAssistantGlass: React.FC<WeatherGPTAssistantGlassProps> = ({
  currentLocationName = 'your area',
  className = '',
}) => {
  const [question, setQuestion] = useState('');
  const [loading, setLoading] = useState(false);
  const [response, setResponse] = useState<AskApiResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);

  const suggestionChips = [
    `What will the weather be like this evening in ${currentLocationName}?`,
    `Will it rain tomorrow afternoon in ${currentLocationName}?`,
    `Is it a good time for outdoor activities today?`,
    `What should I wear given the current humidity and temperature?`,
  ];

  const handleAsk = async (queryText?: string) => {
    const q = (queryText || question).trim();
    if (!q || loading) return;

    setQuestion(q);
    setLoading(true);
    setError(null);

    try {
      const res = await askWeatherGPT(q);
      if (res.success && res.answer) {
        setResponse(res);
      } else {
        const errMsg = typeof res.error === 'string'
          ? res.error
          : (res.error?.message || res.answer || 'Unable to fetch weather intelligence for this query.');
        setError(errMsg);
        if (res.answer) setResponse(res);
      }
    } catch (err: any) {
      setError(err?.message || 'Failed to connect to WeatherGPT AI services.');
    } finally {
      setLoading(false);
    }
  };

  const handleCopy = () => {
    if (!response?.answer) return;
    navigator.clipboard.writeText(response.answer);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className={`glass-panel rounded-3xl p-6 sm:p-8 text-white relative overflow-hidden ${className}`}>
      {/* Atmospheric Ambient Glow */}
      <div className="absolute top-0 right-0 w-80 h-80 bg-sky-300/10 rounded-full blur-3xl pointer-events-none -mr-24 -mt-24" />

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-5 pb-4 border-b border-white/12 relative z-10">
        <div className="flex items-center gap-3">
          <div className="p-2.5 rounded-2xl bg-white/15 border border-white/20 text-white backdrop-blur-md shadow-xs">
            <Sparkles className="w-5 h-5 text-amber-300 animate-pulse" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h2 className="text-lg sm:text-xl font-extrabold text-white tracking-tight">
                Ask WeatherGPT
              </h2>
              <span className="text-[10px] bg-white/15 text-white/90 border border-white/20 px-2.5 py-0.5 rounded-full font-bold flex items-center gap-1.5 backdrop-blur-sm">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-ping" />
                AI Assistant
              </span>
            </div>
            <p className="text-xs text-white/70 mt-0.5 font-medium">
              Real-time conversational atmospheric intelligence powered by Gemini
            </p>
          </div>
        </div>

        {response?.forecastConfidence && (
          <div className="flex items-center gap-1.5 text-xs text-white/80 bg-white/10 px-3 py-1 rounded-full border border-white/15 self-start sm:self-auto">
            <ShieldCheck className="w-3.5 h-3.5 text-emerald-300" />
            <span>{response.forecastConfidence} Confidence Forecast</span>
          </div>
        )}
      </div>

      {/* Glass Search Input Bar */}
      <form
        onSubmit={(e) => {
          e.preventDefault();
          handleAsk();
        }}
        className="space-y-3 relative z-10"
      >
        <div className="relative flex items-center">
          <input
            type="text"
            value={question}
            onChange={(e) => setQuestion(e.target.value)}
            placeholder="Ask about rain, temperature, clothing advice, or travel conditions..."
            disabled={loading}
            className="w-full pl-5 pr-28 sm:pr-32 py-3.5 sm:py-4 glass-input rounded-2xl text-sm font-medium transition-all"
          />
          <button
            type="submit"
            disabled={!question.trim() || loading}
            className="absolute right-2 px-4 py-2 sm:py-2.5 bg-white text-[#1D4ED8] font-bold rounded-xl text-xs flex items-center gap-1.5 hover:bg-white/90 disabled:opacity-40 transition-all shadow-sm cursor-pointer"
          >
            {loading ? (
              <>
                <Loader2 className="w-3.5 h-3.5 animate-spin text-[#1D4ED8]" />
                <span>Thinking...</span>
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
        <div className="flex items-center gap-2 overflow-x-auto hide-scrollbar pt-1 pb-1">
          <span className="text-[11px] font-semibold text-white/60 whitespace-nowrap">
            Try:
          </span>
          {suggestionChips.map((chip, idx) => (
            <button
              key={idx}
              type="button"
              onClick={() => handleAsk(chip)}
              disabled={loading}
              className="text-xs px-3 py-1.5 rounded-full bg-white/10 hover:bg-white/20 border border-white/15 text-white/90 whitespace-nowrap transition-all flex items-center gap-1 cursor-pointer flex-shrink-0 disabled:opacity-40"
            >
              <span>{chip}</span>
              <ArrowRight className="w-3 h-3 text-white/50" />
            </button>
          ))}
        </div>
      </form>

      {/* AI Error Notification */}
      {error && (
        <div className="mt-4 p-3.5 rounded-2xl bg-rose-500/20 border border-rose-400/30 text-rose-100 flex items-start gap-2.5 text-xs">
          <AlertCircle className="w-4 h-4 text-rose-300 flex-shrink-0 mt-0.5" />
          <p className="leading-relaxed">{error}</p>
        </div>
      )}

      {/* AI Response Card */}
      {response && (
        <div className="mt-5 pt-4 border-t border-white/12 relative z-10 animate-in fade-in duration-300">
          <div className="glass-panel p-5 sm:p-6 rounded-2xl border border-white/20 relative">
            <div className="flex items-center justify-between mb-3 pb-2 border-b border-white/10">
              <div className="flex items-center gap-2 text-xs font-bold text-white">
                <Bot className="w-4 h-4 text-sky-300" />
                <span>WeatherGPT Insight</span>
              </div>
              <button
                type="button"
                onClick={handleCopy}
                className="p-1.5 rounded-lg bg-white/10 hover:bg-white/20 text-white/70 hover:text-white transition-colors cursor-pointer text-xs flex items-center gap-1"
                title="Copy response"
              >
                {copied ? <Check className="w-3.5 h-3.5 text-emerald-300" /> : <Copy className="w-3.5 h-3.5" />}
                <span className="hidden sm:inline">{copied ? 'Copied' : 'Copy'}</span>
              </button>
            </div>

            {/* Markdown Answer Content */}
            <div className="prose prose-invert prose-sm max-w-none text-white/90 leading-relaxed space-y-2 text-xs sm:text-sm">
              <ReactMarkdown remarkPlugins={[remarkGfm]}>
                {response.answer}
              </ReactMarkdown>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
