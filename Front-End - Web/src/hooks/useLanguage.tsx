import React, { createContext, useContext, useState, useEffect } from 'react';

import en from '../locales/en.json';
import gu from '../locales/gu.json';
import hi from '../locales/hi.json';
import mr from '../locales/mr.json';
import pa from '../locales/pa.json';
import bn from '../locales/bn.json';
import ta from '../locales/ta.json';
import te from '../locales/te.json';
import kn from '../locales/kn.json';
import ml from '../locales/ml.json';
import ur from '../locales/ur.json';
import or from '../locales/or.json';
import as from '../locales/as.json';
import sa from '../locales/sa.json';
import kok from '../locales/kok.json';
import mai from '../locales/mai.json';
import sd from '../locales/sd.json';
import ks from '../locales/ks.json';
import mni from '../locales/mni.json';
import brx from '../locales/brx.json';
import doi from '../locales/doi.json';
import sat from '../locales/sat.json';
import ne from '../locales/ne.json';

export interface SupportedLang {
  code: string;
  name: string;
  nativeName: string;
  flag: string;
}

export const SITE_LANGUAGES: SupportedLang[] = [
  { code: 'en', name: 'English', nativeName: 'English', flag: '🇺🇸' },
  { code: 'gu', name: 'Gujarati', nativeName: 'ગુજરાતી', flag: '🇮🇳' },
  { code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳' }
];

export const TRANSLATIONS: Record<string, Record<string, string>> = {
  en, gu, hi, mr, pa, bn, ta, te, kn, ml, ur, or, as, sa, kok, mai, sd, ks, mni, brx, doi, sat, ne
};

interface LanguageContextType {
  currentLang: SupportedLang;
  setLanguage: (lang: SupportedLang) => void;
  t: (key: string, fallback?: string) => string;
}

const LanguageContext = createContext<LanguageContextType | undefined>(undefined);

export const LanguageProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [currentLang, setCurrentLang] = useState<SupportedLang>(() => {
    const saved = localStorage.getItem('weathergpt_ui_lang');
    if (saved) {
      try {
        const parsed = JSON.parse(saved);
        // Ensure it's still supported
        const exists = SITE_LANGUAGES.find(l => l.code === parsed.code);
        if (exists) return exists;
      } catch (e) {
        console.error("Failed to parse language preference", e);
      }
    }
    return SITE_LANGUAGES[0]; // Default to English
  });

  useEffect(() => {
    localStorage.setItem('weathergpt_ui_lang', JSON.stringify(currentLang));
    
    // Set Document Language
    document.documentElement.lang = currentLang.code;
    
    // Set Text Direction (RTL support for Urdu, Sindhi, Kashmiri)
    const rtlLanguages = ['ur', 'sd', 'ks'];
    document.documentElement.dir = rtlLanguages.includes(currentLang.code) ? 'rtl' : 'ltr';

  }, [currentLang]);

  const setLanguage = (lang: SupportedLang) => {
    setCurrentLang(lang);
  };

  const t = (key: string, fallback?: string): string => {
    const code = currentLang.code;
    if (TRANSLATIONS[code] && TRANSLATIONS[code][key]) {
      return TRANSLATIONS[code][key];
    }
    // Fallback to English dictionary
    if (TRANSLATIONS['en'] && TRANSLATIONS['en'][key]) {
      return TRANSLATIONS['en'][key];
    }
    return fallback || key;
  };

  return (
    <LanguageContext.Provider value={{ currentLang, setLanguage, t }}>
      {children}
    </LanguageContext.Provider>
  );
};

export const useLanguage = () => {
  const context = useContext(LanguageContext);
  if (!context) {
    throw new Error('useLanguage must be used within a LanguageProvider');
  }
  return context;
};
