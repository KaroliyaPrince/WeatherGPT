import { Languages, Check, Sparkles, Globe2, ArrowRight } from 'lucide-react';
import { useLanguage, SITE_LANGUAGES } from '../hooks/useLanguage';
import { useNavigate } from 'react-router-dom';

export default function LanguageSelectionPage() {
  const { currentLang, setLanguage, t } = useLanguage();
  const navigate = useNavigate();

  return (
    <div className="space-y-8 pb-12 animate-in fade-in duration-400">
      {/* Banner */}
      <div className="p-6 sm:p-10 rounded-3xl bg-gradient-to-r from-primary via-blue-600 to-indigo-700 text-white shadow-2xl relative overflow-hidden">
        <div className="relative z-10 flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
          <div>
            <div className="flex items-center gap-2 text-amber-300 font-bold text-xs uppercase tracking-wider mb-2">
              <Globe2 className="w-4 h-4 animate-spin" style={{ animationDuration: '12s' }} />
              <span>Multi-Lingual Portal Settings</span>
            </div>
            <h1 className="text-2xl sm:text-4xl font-black tracking-tight">
              {t('select_language_title', 'Select Your Site Language')}
            </h1>
            <p className="text-sm text-primary-foreground/90 mt-2 max-w-2xl leading-relaxed">
              {t('select_language_subtitle', 'Choose your preferred language to translate the entire WeatherGPT portal interface, menus, AI assistant, and weather advisories.')}
            </p>
          </div>

          <div className="flex items-center gap-3 bg-white/10 backdrop-blur-md px-4 py-3 rounded-2xl border border-white/20">
            <span className="text-3xl">{currentLang.flag}</span>
            <div>
              <div className="text-[10px] text-white/80 font-bold uppercase">{t('active_language', 'Active Language')}</div>
              <div className="text-sm font-extrabold">{currentLang.nativeName} ({currentLang.name})</div>
            </div>
          </div>
        </div>
      </div>

      {/* Grid of Language Options */}
      <div className="space-y-4">
        <h3 className="text-sm font-extrabold text-foreground uppercase tracking-wider flex items-center gap-2">
          <Languages className="w-4 h-4 text-primary" />
          <span>Available Site Languages (ભાષા પસંદ કરો):</span>
        </h3>

        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
          {SITE_LANGUAGES.map((lang) => {
            const isSelected = currentLang.code === lang.code;
            return (
              <button
                key={lang.code}
                type="button"
                onClick={() => setLanguage(lang)}
                className={`p-5 rounded-2xl border text-left transition-all cursor-pointer relative flex flex-col justify-between group ${
                  isSelected
                    ? 'glass-pill-active text-white scale-[1.02]'
                    : 'glass-panel text-white hover:bg-white/10 hover:border-white/40'
                }`}
              >
                {isSelected && (
                  <span className="absolute top-3 right-3 p-1 bg-primary text-primary-foreground rounded-full shadow-md">
                    <Check className="w-3.5 h-3.5" />
                  </span>
                )}

                <div className="flex items-center gap-3 mb-3">
                  <span className="text-4xl drop-shadow-xs">{lang.flag}</span>
                  <div>
                    <h4 className="font-extrabold text-base text-foreground group-hover:text-primary transition-colors">
                      {lang.nativeName}
                    </h4>
                    <p className="text-xs text-muted-foreground font-medium">{lang.name}</p>
                  </div>
                </div>

                <div className="pt-3 border-t border-border/50 flex items-center justify-between text-xs font-bold text-muted-foreground">
                  <span>{isSelected ? 'Selected ✓' : 'Click to apply'}</span>
                  <ArrowRight className={`w-3.5 h-3.5 transition-transform ${isSelected ? 'text-primary' : 'group-hover:translate-x-1'}`} />
                </div>
              </button>
            );
          })}
        </div>
      </div>

      {/* Quick Actions */}
      <div className="p-6 glass-panel border border-white/20 text-white rounded-3xl flex flex-col sm:flex-row items-center justify-between gap-4 shadow-md">
        <div className="flex items-center gap-3">
          <div className="p-3 bg-emerald-500/10 text-emerald-600 rounded-2xl">
            <Sparkles className="w-6 h-6 animate-pulse" />
          </div>
          <div>
            <h4 className="font-bold text-sm text-foreground">Selected: {currentLang.nativeName} ({currentLang.name})</h4>
            <p className="text-xs text-muted-foreground mt-0.5">All dashboard items, voice assistant, and navigation will render in this language.</p>
          </div>
        </div>

        <button
          onClick={() => navigate('/')}
          className="px-5 py-2.5 bg-primary text-primary-foreground font-extrabold text-xs rounded-xl hover:bg-primary/90 transition-all shadow-md cursor-pointer flex-shrink-0"
        >
          Return to Dashboard →
        </button>
      </div>
    </div>
  );
}
