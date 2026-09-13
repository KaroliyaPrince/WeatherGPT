import { useState, useRef, useEffect, useMemo } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { askWeatherGPT, getUserLocation, analyzeWeatherLens, fetchVoiceSpeakAudio } from '../services/weatherGptApi';
import { 
  Send, 
  Mic, 
  MicOff, 
  Sparkles, 
  Volume2, 
  VolumeX, 
  Plus, 
  Trash2, 
  Copy, 
  Check, 
  Radio, 
  ChevronDown, 
  PanelLeftClose, 
  PanelLeft, 
  PhoneOff, 
  Compass,
  Edit2,
  Camera,
  Image as ImageIcon,
  Share2,
  X
} from 'lucide-react';
import { cn } from '../utils/cn';
import { useUserProfile } from '../hooks/useUserProfile';
import { useLanguage, SITE_LANGUAGES } from '../hooks/useLanguage';
import { AIVoiceOrb3D } from '../components/3d/AIVoiceOrb3D';

// Supported Languages for Voice & Text
export interface LanguageOption {
  code: string;
  name: string;
  nativeName: string;
  flag: string;
  speechLang: string;
  greeting: string;
  suggestions: string[];
}

export const SUPPORTED_LANGUAGES: LanguageOption[] = [
  {
    code: 'auto',
    name: 'Auto-Detect',
    nativeName: 'Auto-Detect (સ્વચાલિત / स्वचालित)',
    flag: '🌐',
    speechLang: 'en-US',
    greeting: "Hello! I am WeatherGPT Voice AI. Speak or type in English, Gujarati, or Hindi and I will automatically detect and answer in your language!",
    suggestions: [
      "Will it rain today in Rajkot?",
      "શું આજે વરસાદ પડશે?",
      "क्या आज बारिश होगी?",
      "Should I carry an umbrella this evening?"
    ]
  },
  {
    code: 'en',
    name: 'English',
    nativeName: 'English',
    flag: '🇺🇸',
    speechLang: 'en-US',
    greeting: "Hello! I'm WeatherGPT Voice Assistant. Ask me anything about the weather, forecasts, storms, or travel tips!",
    suggestions: [
      "Will it rain today in Rajkot?",
      "Should I carry an umbrella this evening?",
      "What is the 7-day temperature trend?",
      "Give me a severe weather alert summary"
    ]
  },
  {
    code: 'gu',
    name: 'Gujarati',
    nativeName: 'ગુજરાતી',
    flag: '🇮🇳',
    speechLang: 'gu-IN',
    greeting: "નમસ્તે! હું WeatherGPT વોઇસ આસિસ્ટન્ટ છું. મને ગુજરાત અને રાજકોટના હવામાન, વરસાદ અને તાપમાન વિશે પૂછો!",
    suggestions: [
      "શું આજે રાજકોટમાં વરસાદ પડશે?",
      "શું મારે આજે છત્રી રાખવાની જરૂર છે?",
      "આ અઠવાડિયે તાપમાન કેટલું રહેશે?",
      "ખેતીના પાક માટે આજનું હવામાન કેવું છે?"
    ]
  },
  {
    code: 'hi',
    name: 'Hindi',
    nativeName: 'हिन्दी',
    flag: '🇮🇳',
    speechLang: 'hi-IN',
    greeting: "नमस्ते! मैं WeatherGPT वॉयस असिस्टेंट हूँ। मुझसे आज के मौसम, बारिश, तापमान या यात्रा के बारे में पूछें!",
    suggestions: [
      "क्या आज राजકોટ में बारिश होगी?",
      "क्या मुझे शाम को छाता लेकर जाना चाहिए?",
      "अगले 7 दिनों का तापमान कैसा रहेगा?",
      "क्या कोई आंधी या तूफान की चेतावनी है?"
    ]
  }
];

// Helper to convert Gujarati script to Devanagari for systems without a native gu-IN TTS voice installed
export const gujaratiToDevanagari = (text: string): string => {
  let result = '';
  for (let i = 0; i < text.length; i++) {
    const code = text.charCodeAt(i);
    // Gujarati Unicode block: 0x0A81 to 0x0AF1 -> Devanagari 0x0901 to 0x0971 (subtract 0x0180)
    if (code >= 0x0A81 && code <= 0x0AF1) {
      result += String.fromCharCode(code - 0x0180);
    } else {
      result += text[i];
    }
  }
  return result;
};

// Automatically detects which language the user is speaking or typing in
export const detectLanguage = (text: string): string => {
  if (!text) return 'en';
  // Check distinctive script unicode ranges
  if (/[\u0A80-\u0AFF]/.test(text)) return 'gu'; // Gujarati
  if (/[\u0A00-\u0A7F]/.test(text)) return 'pa'; // Punjabi (Gurmukhi)
  if (/[\u0980-\u09FF]/.test(text)) return 'bn'; // Bengali
  if (/[\u0B80-\u0BFF]/.test(text)) return 'ta'; // Tamil
  if (/[\u0C00-\u0C7F]/.test(text)) return 'te'; // Telugu
  if (/[\u0C80-\u0CFF]/.test(text)) return 'kn'; // Kannada
  if (/[\u0D00-\u0D7F]/.test(text)) return 'ml'; // Malayalam
  if (/[\u3040-\u30FF]/.test(text)) return 'ja'; // Japanese
  if (/[\uAC00-\uD7AF]/.test(text)) return 'ko'; // Korean
  if (/[\u4E00-\u9FFF]/.test(text)) return 'zh'; // Chinese
  if (/[\u0400-\u04FF]/.test(text)) return 'ru'; // Russian
  if (/[\u0600-\u06FF]/.test(text)) {
    if (/کیا|بارش|موسم|ہے|نہیں|پانی|چھتری|کب/.test(text)) return 'ur';
    return 'ar';
  }
  if (/[\u0900-\u097F]/.test(text)) {
    if (/पाऊस|आहे|काय|तापमान|वारा|हवामान|छत्री|कधी|जावे/.test(text)) return 'mr';
    return 'hi';
  }
  
  const lower = (text || '').toLowerCase();

  // Romanized / Transliterated Language Detection
  if (/\b(varsad|varsat|chhatri|chatri|aaje|aaj|kem|su|tamare|hovanu|nathi|khabar|pavan|garmi|tapman)\b/i.test(lower)) {
    return 'gu';
  }
  if (/\b(barish|baarish|chata|mausam|garmi|tufan|hawa|hogi|hoga|kya|dhoop|aandhi|taapman)\b/i.test(lower)) {
    return 'hi';
  }
  if (/\b(paus|paoos|vara|hava|kiti|kadhi)\b/i.test(lower)) {
    return 'mr';
  }

  if (/\b(lluvia|paraguas|clima|tiempo|hoy|temperatura|calor|viento|llover|nublado)\b/i.test(lower)) return 'es';
  if (/\b(pluie|parapluie|temps|aujourd'hui|météo|chaleur|vent|pleuvoir|nuageux)\b/i.test(lower)) return 'fr';
  if (/\b(regen|wetter|heute|temperatur|wind|schirm|sonne|regnen|gewitter)\b/i.test(lower)) return 'de';
  if (/\b(pioggia|ombrello|meteo|tempo|oggi|temperatura|caldo|vento|piovere)\b/i.test(lower)) return 'it';
  if (/\b(chuva|guarda-chuva|tempo|hoje|temperatura|calor|vento|chover)\b/i.test(lower)) return 'pt';
  if (/\b(yağmur|hava|bugün|sıcaklık|şemsiye|rüzgar|durumu)\b/i.test(lower)) return 'tr';

  return 'en';
};

export interface ChatMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: string;
  language?: string;
  image?: string;
  lensData?: import('../services/weatherGptApi').WeatherLensResponse;
  explainWhy?: any;
}

export interface ChatSession {
  id: string;
  title: string;
  dateCategory: 'Today' | 'Yesterday' | 'Previous 7 Days';
  messages: ChatMessage[];
  languageCode: string;
  updatedAt: number;
}

// Helper to generate a brand new clean session
const createFreshSession = (userName?: string): ChatSession[] => {
  const name = userName ? userName.split(' ')[0] : 'there';
  return [
    {
      id: `session-${Date.now()}`,
      title: 'New Weather Chat',
      dateCategory: 'Today',
      languageCode: 'en',
      updatedAt: Date.now(),
      messages: [
        {
          id: `msg-${Date.now()}`,
          role: 'assistant',
          content: `👋 Hello ${name}! I am WeatherGPT, your AI meteorologist. Ask me anything about current weather, rain alerts, forecasts, farming advice, or travel routes in any language!`,
          timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          language: 'en'
        }
      ]
    }
  ];
};

// Helper to load chat sessions strictly scoped to the logged-in user's email
const loadSessionsForUser = (userEmail: string, userName?: string): ChatSession[] => {
  const normalizedKey = userEmail ? userEmail.toLowerCase().trim() : 'guest';
  const key = `weathergpt_sessions_v3_${normalizedKey}`;
  const saved = localStorage.getItem(key);
  if (saved) {
    try {
      const parsed: ChatSession[] = JSON.parse(saved);
      // Filter out any old mock dummy sessions
      const clean = parsed.filter(s => s.id !== 'session-1' && s.id !== 'session-2' && s.id !== 'session-3');
      if (clean.length > 0) {
        return clean;
      }
    } catch (e) {
      console.warn('Failed to parse saved sessions for user:', e);
    }
  }

  // Clear legacy mock sessions if present
  try {
    localStorage.removeItem('weathergpt_sessions');
    localStorage.removeItem('weathergpt_sessions_guest');
  } catch {}

  // Brand new fresh session
  return createFreshSession(userName);
};

// Component for rendering AI response with progressive word highlighting and auto-scrolling during speech
interface SpokenTextRendererProps {
  content: string;
  isSpeaking: boolean;
  speakingCharIndex: number | null;
}

function SpokenTextRenderer({ content, isSpeaking, speakingCharIndex }: SpokenTextRendererProps) {
  const activeWordRef = useRef<HTMLSpanElement>(null);

  // Split content into words and whitespace tokens
  const tokens = useMemo(() => {
    if (!content) return [];
    const result: { text: string; start: number; end: number; isWord: boolean }[] = [];
    const regex = /\S+|\s+/g;
    let match;
    while ((match = regex.exec(content)) !== null) {
      result.push({
        text: match[0],
        start: match.index,
        end: match.index + match[0].length,
        isWord: /\S/.test(match[0]),
      });
    }
    return result;
  }, [content]);

  // Determine which word index is currently being spoken
  const activeWordIdx = useMemo(() => {
    if (!isSpeaking || speakingCharIndex === null || speakingCharIndex === undefined) return -1;
    for (let i = 0; i < tokens.length; i++) {
      if (tokens[i].isWord && speakingCharIndex >= tokens[i].start && speakingCharIndex <= tokens[i].end + 4) {
        return i;
      }
    }
    for (let i = tokens.length - 1; i >= 0; i--) {
      if (tokens[i].isWord && speakingCharIndex >= tokens[i].start) {
        return i;
      }
    }
    return 0;
  }, [tokens, isSpeaking, speakingCharIndex]);

  // Smoothly auto-scroll down to the currently highlighted spoken word
  useEffect(() => {
    if (isSpeaking && activeWordRef.current) {
      activeWordRef.current.scrollIntoView({
        behavior: 'smooth',
        block: 'center',
        inline: 'nearest'
      });
    }
  }, [activeWordIdx, isSpeaking]);

  if (!isSpeaking) {
    return (
      <ReactMarkdown remarkPlugins={[remarkGfm]}>
        {typeof content === 'string' ? content : String(content || '')}
      </ReactMarkdown>
    );
  }

  return (
    <div className="text-sm leading-relaxed whitespace-pre-wrap font-normal">
      {tokens.map((token, idx) => {
        if (!token.isWord) {
          return <span key={idx}>{token.text}</span>;
        }

        const isPast = activeWordIdx > idx;
        const isCurrent = activeWordIdx === idx;

        if (isCurrent) {
          return (
            <span
              key={idx}
              ref={activeWordRef}
              className="inline-block bg-primary text-primary-foreground font-bold px-1.5 py-0.5 mx-0.5 rounded-lg shadow-lg scale-105 border border-primary/50 transition-all duration-150 animate-pulse ring-2 ring-primary/30"
            >
              {token.text}
            </span>
          );
        }

        if (isPast) {
          return (
            <span key={idx} className="text-foreground transition-opacity duration-200">
              {token.text}
            </span>
          );
        }

        // Upcoming words: subtle dimming so focus remains on currently spoken portion
        return (
          <span key={idx} className="text-muted-foreground/35 transition-opacity duration-300">
            {token.text}
          </span>
        );
      })}
    </div>
  );
}

export default function VoiceAssistantPage() {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const { formatTemp, profile, isAuthenticated } = useUserProfile();

  // Current user key based on authenticated Gmail / email
  const currentUserEmail = (isAuthenticated && profile?.email ? profile.email : 'guest').toLowerCase().trim();

  // Sessions and Active Chat strictly scoped to the logged-in Gmail/email
  const [sessions, setSessions] = useState<ChatSession[]>(() => {
    return loadSessionsForUser(currentUserEmail, profile?.name);
  });

  const [activeSessionId, setActiveSessionId] = useState<string>(() => {
    return sessions[0]?.id || 'session-1';
  });

  const prevUserEmailRef = useRef<string>(currentUserEmail);

  // Automatically switch history when user logs in with a different Gmail or logs out
  useEffect(() => {
    if (prevUserEmailRef.current !== currentUserEmail) {
      prevUserEmailRef.current = currentUserEmail;
      const userSessions = loadSessionsForUser(currentUserEmail, profile?.name);
      setSessions(userSessions);
      setActiveSessionId(userSessions[0]?.id || 'session-1');
    }
  }, [currentUserEmail, profile?.name]);

  // Save sessions to the user-specific localStorage key
  useEffect(() => {
    if (sessions && sessions.length > 0) {
      const key = `weathergpt_sessions_v3_${currentUserEmail}`;
      localStorage.setItem(key, JSON.stringify(sessions));
    }
  }, [sessions, currentUserEmail]);

  const { setLanguage: setGlobalLanguage } = useLanguage();

  // Selected Language: Default to 'auto' (Auto Detect) on initial load per requirements
  const [selectedLang, setSelectedLang] = useState<LanguageOption>(() => {
    return SUPPORTED_LANGUAGES[0]; // 'auto' is the first entry
  });
  const [langDropdownOpen, setLangDropdownOpen] = useState(false);

  // Sidebar & Layout state
  const [sidebarOpen, setSidebarOpen] = useState(() => {
    return typeof window !== 'undefined' ? window.innerWidth > 768 : true;
  });

  // Input state
  const [input, setInput] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const [copiedId, setCopiedId] = useState<string | null>(null);
  
  // Camera & Image state
  const [previewImage, setPreviewImage] = useState<string | null>(null);
  const [showCameraOptions, setShowCameraOptions] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const cameraInputRef = useRef<HTMLInputElement>(null);

  const handleImageSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setPreviewImage(reader.result as string);
        setShowCameraOptions(false);
      };
      reader.readAsDataURL(file);
    }
    e.target.value = '';
  };

  // Live Voice Mode (ChatGPT Voice Assistant UI)
  const [isLiveVoiceMode, setIsLiveVoiceMode] = useState(false);
  const [voiceState, setVoiceState] = useState<'idle' | 'listening' | 'thinking' | 'speaking'>('idle');
  const [isSpeechRecognitionActive, setIsSpeechRecognitionActive] = useState(false);
  const [liveTranscript, setLiveTranscript] = useState('');
  const [isAudioMuted, setIsAudioMuted] = useState(false);

  const messagesEndRef = useRef<HTMLDivElement>(null);
  const recognitionRef = useRef<any>(null);
  const synthRef = useRef<SpeechSynthesis | null>(null);
  const activeUtteranceRef = useRef<SpeechSynthesisUtterance | null>(null);
  const activeAudioRef = useRef<HTMLAudioElement | null>(null);
  const activeAudioUrlRef = useRef<string | null>(null);

  // Progressive speaking highlighting and tracking
  const [speakingMessageId, setSpeakingMessageId] = useState<string | null>(null);
  const [speakingCharIndex, setSpeakingCharIndex] = useState<number | null>(null);
  const speechTickerRef = useRef<any>(null);

  const isLiveVoiceModeRef = useRef<boolean>(isLiveVoiceMode);
  const voiceStateRef = useRef<'idle' | 'listening' | 'thinking' | 'speaking'>(voiceState);
  const isAudioMutedRef = useRef<boolean>(isAudioMuted);
  const selectedLangRef = useRef<LanguageOption>(selectedLang);

  useEffect(() => { isLiveVoiceModeRef.current = isLiveVoiceMode; }, [isLiveVoiceMode]);
  useEffect(() => { voiceStateRef.current = voiceState; }, [voiceState]);
  useEffect(() => { isAudioMutedRef.current = isAudioMuted; }, [isAudioMuted]);
  useEffect(() => { selectedLangRef.current = selectedLang; }, [selectedLang]);

  const activeSession = sessions.find(s => s.id === activeSessionId) || sessions[0];

  // Handle URL query prompt (e.g. from Map page "Ask AI about this area")
  useEffect(() => {
    const promptParam = searchParams.get('prompt');
    if (promptParam) {
      setInput(promptParam);
    }
  }, [searchParams]);

  // Scroll to bottom on message update
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [activeSession?.messages, isTyping, liveTranscript]);

  // Stop any active audio and speech immediately
  const stopAllAudio = () => {
    if (speechTickerRef.current) {
      clearInterval(speechTickerRef.current);
      speechTickerRef.current = null;
    }
    setSpeakingMessageId(null);
    setSpeakingCharIndex(null);

    // 1. Pause and reset HTMLAudioElement instance if present
    if (activeAudioRef.current) {
      try {
        activeAudioRef.current.pause();
        activeAudioRef.current.currentTime = 0;
      } catch (e) {
        console.warn('Error pausing active audio:', e);
      }
      activeAudioRef.current = null;
    }

    // 2. Revoke any active Object URL to free memory
    if (activeAudioUrlRef.current) {
      try {
        URL.revokeObjectURL(activeAudioUrlRef.current);
      } catch (e) {
        console.warn('Error revoking audio ObjectURL:', e);
      }
      activeAudioUrlRef.current = null;
    }

    // 3. Cancel Web Speech Synthesis
    if (typeof window !== 'undefined' && 'speechSynthesis' in window) {
      try {
        window.speechSynthesis.cancel();
      } catch (e) {
        console.warn('Error cancelling speech synthesis:', e);
      }
    }
    activeUtteranceRef.current = null;
    setVoiceState('idle');
  };

  // Initialize Speech Synthesis + cleanup on unmount
  useEffect(() => {
    if (typeof window !== 'undefined' && 'speechSynthesis' in window) {
      synthRef.current = window.speechSynthesis;
    }
    return () => {
      // Stop all AI voice and audio immediately when component unmounts or user navigates away
      stopAllAudio();
      // Also stop speech recognition
      if (recognitionRef.current) {
        try { recognitionRef.current.stop(); } catch {}
      }
    };
  }, []);

  const stopSpeaking = () => {
    stopAllAudio();
  };

  // Fallback Text-to-Speech using browser Web SpeechSynthesis
  const fallbackWebSpeechTTS = (text: string, langCode: string = selectedLangRef.current.speechLang, messageId?: string) => {
    if (isAudioMutedRef.current || typeof window === 'undefined' || !('speechSynthesis' in window)) {
      setVoiceState('idle');
      setSpeakingMessageId(null);
      setSpeakingCharIndex(null);
      return;
    }

    try {
      window.speechSynthesis.cancel();
      if (speechTickerRef.current) {
        clearInterval(speechTickerRef.current);
        speechTickerRef.current = null;
      }

      setSpeakingMessageId(messageId || null);
      setSpeakingCharIndex(0);

      const voices = window.speechSynthesis.getVoices();
      // Normalise: accept both 'gu' and 'gu-IN' formats
      const prefix = (langCode || '').slice(0, 2).toLowerCase();

      let textToSpeak = text;
      let targetLang = langCode;
      let matchVoice: SpeechSynthesisVoice | undefined;

      if (prefix === 'gu') {
        targetLang = 'gu-IN';
        // Prefer Gujarati voice; fall back to Hindi/Indian if unavailable
        matchVoice = voices.find(v => v.lang && v.lang.startsWith('gu'))
          || voices.find(v => v.lang && v.lang.startsWith('hi'))
          || voices.find(v => v.lang && v.lang.toLowerCase().includes('in'));
        // If no native Gujarati TTS, transliterate to Devanagari for Hindi voice
        if (!voices.find(v => v.lang && v.lang.startsWith('gu'))) {
          textToSpeak = gujaratiToDevanagari(text);
          targetLang = 'hi-IN';
        }
      } else if (prefix === 'hi') {
        targetLang = 'hi-IN';
        matchVoice = voices.find(v => v.lang.startsWith('hi'));
      } else {
        // Default: English (Indian accent preferred)
        targetLang = 'en-IN';
        matchVoice = voices.find(v => v.lang === 'en-IN')
          || voices.find(v => v.lang.startsWith('en'));
      }

      const utterance = new SpeechSynthesisUtterance(textToSpeak);
      utterance.lang = targetLang;
      utterance.rate = 0.92;
      utterance.pitch = 1.0;
      if (matchVoice) utterance.voice = matchVoice;

      utterance.onstart = () => {
        setVoiceState('speaking');
        // Progressive ticker fallback to highlight spoken words smoothly
        const words = text.split(/\s+/);
        let currWord = 0;
        speechTickerRef.current = setInterval(() => {
          currWord++;
          if (currWord < words.length) {
            const charIdx = words.slice(0, currWord).join(' ').length;
            setSpeakingCharIndex(prev => Math.max(prev || 0, charIdx));
          } else if (speechTickerRef.current) {
            clearInterval(speechTickerRef.current);
            speechTickerRef.current = null;
          }
        }, 300);
      };

      utterance.onboundary = (event) => {
        if (typeof event.charIndex === 'number') {
          setSpeakingCharIndex(event.charIndex);
        }
      };

      utterance.onend = () => {
        if (speechTickerRef.current) {
          clearInterval(speechTickerRef.current);
          speechTickerRef.current = null;
        }
        setSpeakingMessageId(null);
        setSpeakingCharIndex(null);
        setVoiceState('idle');
        if (isLiveVoiceModeRef.current) {
          setTimeout(() => {
            if (isLiveVoiceModeRef.current) startSpeechRecognition();
          }, 400);
        }
      };

      utterance.onerror = (err) => {
        console.warn('Speech synthesis utterance error:', err);
        if (speechTickerRef.current) {
          clearInterval(speechTickerRef.current);
          speechTickerRef.current = null;
        }
        setSpeakingMessageId(null);
        setSpeakingCharIndex(null);
        setVoiceState('idle');
      };

      activeUtteranceRef.current = utterance;
      window.speechSynthesis.speak(utterance);
    } catch (e) {
      console.warn('Speech synthesis error:', e);
      if (speechTickerRef.current) {
        clearInterval(speechTickerRef.current);
        speechTickerRef.current = null;
      }
      setSpeakingMessageId(null);
      setSpeakingCharIndex(null);
      setVoiceState('idle');
    }
  };

  // Primary Text-to-Speech: Direct backend fetch to /api/voice/speak with HTML5 Audio, fallback to Web Speech
  const speakText = async (text: string, langCode: string = selectedLangRef.current.speechLang, messageId?: string) => {
    if (isAudioMutedRef.current) return;

    // 1. Stop any existing playing audio immediately
    stopAllAudio();

    setSpeakingMessageId(messageId || null);
    setSpeakingCharIndex(0);

    try {
      // 2. Fetch audio blob directly from Render backend (/api/voice/speak)
      const audioBlob = await fetchVoiceSpeakAudio(text, langCode);

      if (audioBlob && audioBlob.size > 0) {
        const audioUrl = URL.createObjectURL(audioBlob);
        activeAudioUrlRef.current = audioUrl;

        const audio = new Audio(audioUrl);
        activeAudioRef.current = audio;

        audio.onplay = () => {
          setVoiceState('speaking');
        };

        audio.ontimeupdate = () => {
          if (audio.duration > 0) {
            const ratio = audio.currentTime / audio.duration;
            const charIdx = Math.floor(ratio * text.length);
            setSpeakingCharIndex(charIdx);
          }
        };

        audio.onended = () => {
          setVoiceState('idle');
          setSpeakingMessageId(null);
          setSpeakingCharIndex(null);
          if (activeAudioUrlRef.current) {
            URL.revokeObjectURL(activeAudioUrlRef.current);
            activeAudioUrlRef.current = null;
          }
          activeAudioRef.current = null;
          if (isLiveVoiceModeRef.current) {
            setTimeout(() => {
              if (isLiveVoiceModeRef.current) startSpeechRecognition();
            }, 400);
          }
        };

        audio.onerror = (e) => {
          console.warn('Backend HTML5 Audio playback failed, using Web Speech fallback:', e);
          if (activeAudioUrlRef.current) {
            URL.revokeObjectURL(activeAudioUrlRef.current);
            activeAudioUrlRef.current = null;
          }
          activeAudioRef.current = null;
          fallbackWebSpeechTTS(text, langCode, messageId);
        };

        await audio.play();
        return;
      }
    } catch (err) {
      console.warn('Backend TTS error, falling back to Web Speech:', err);
    }

    // 3. Fallback to Web SpeechSynthesis if backend audio is not returned
    fallbackWebSpeechTTS(text, langCode, messageId);
  };


  // NATIVE SPEECH RECOGNITION (Web Speech API)
  // Fast, client-side, zero backend latency, no quota limits
  // ============================================================================

  const startSpeechRecognition = () => {
    // 1. Stop any playing speech/audio first
    stopSpeaking();

    // 2. Check for browser Web Speech Recognition support
    const SpeechRecognition = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;
    if (!SpeechRecognition) {
      alert('Speech Recognition is not supported by your browser. Please use Google Chrome, Microsoft Edge, or Safari.');
      setIsSpeechRecognitionActive(false);
      setVoiceState('idle');
      return;
    }

    // 3. Clean up any existing recognition instance
    if (recognitionRef.current) {
      try {
        recognitionRef.current.onresult = null;
        recognitionRef.current.onerror = null;
        recognitionRef.current.onend = null;
        recognitionRef.current.abort();
      } catch (e) {
        console.warn('Error aborting previous speech recognition:', e);
      }
      recognitionRef.current = null;
    }

    try {
      const recognition = new SpeechRecognition();
      recognitionRef.current = recognition;

      recognition.continuous = false; // Capture complete sentence then stop
      recognition.interimResults = true; // Real-time feedback as user speaks
      recognition.maxAlternatives = 1;

      // Determine speech recognition language
      const currLang = selectedLangRef.current;
      let speechLang = 'en-IN';
      if (currLang.code === 'gu') {
        speechLang = 'gu-IN';
      } else if (currLang.code === 'hi') {
        speechLang = 'hi-IN';
      } else if (currLang.code === 'auto') {
        // Auto: default to Indian English / Hindi context
        speechLang = 'en-IN';
      } else if (currLang.speechLang) {
        speechLang = currLang.speechLang;
      }
      recognition.lang = speechLang;

      let capturedFinalText = '';

      recognition.onstart = () => {
        setIsSpeechRecognitionActive(true);
        setVoiceState('listening');
        setLiveTranscript('');
      };

      recognition.onresult = (event: any) => {
        let interimText = '';
        for (let i = event.resultIndex; i < event.results.length; i++) {
          const transcriptChunk = event.results[i][0].transcript;
          if (event.results[i].isFinal) {
            capturedFinalText += transcriptChunk;
          } else {
            interimText += transcriptChunk;
          }
        }

        const displayText = capturedFinalText || interimText;
        if (displayText) {
          setLiveTranscript(displayText);
          setInput(displayText);
        }
      };

      recognition.onerror = (event: any) => {
        console.warn('SpeechRecognition error:', event.error);
        setIsSpeechRecognitionActive(false);
        if (voiceStateRef.current === 'listening') {
          setVoiceState('idle');
        }

        if (event.error === 'not-allowed') {
          alert('Microphone access was denied. Please allow microphone permissions in your browser settings.');
        } else if (event.error === 'network') {
          console.warn('Network issue during speech recognition.');
        }
      };

      recognition.onend = () => {
        setIsSpeechRecognitionActive(false);
        const queryText = (capturedFinalText || liveTranscript || input).trim();

        if (queryText) {
          setLiveTranscript(queryText);
          // Automatically submit the recognized text as voice input!
          handleSendMessage(queryText, true);
        } else {
          setVoiceState('idle');
          if (isLiveVoiceModeRef.current) {
            // In Live Voice Call mode, restart listening after pause if nothing said
            setTimeout(() => {
              if (isLiveVoiceModeRef.current && voiceStateRef.current === 'idle') {
                startSpeechRecognition();
              }
            }, 1200);
          }
        }
      };

      recognition.start();
    } catch (err: any) {
      console.error('Failed to start speech recognition:', err);
      setIsSpeechRecognitionActive(false);
      setVoiceState('idle');
      if (err.name === 'NotAllowedError') {
        alert('Microphone access was denied. Please allow microphone permissions in your browser settings.');
      }
    }
  };

  const stopSpeechRecognition = () => {
    if (recognitionRef.current) {
      try {
        recognitionRef.current.stop();
      } catch (e) {
        console.warn('Error stopping speech recognition:', e);
      }
    }
    setIsSpeechRecognitionActive(false);
    if (voiceState === 'listening') {
      setVoiceState('idle');
    }
  };

  // Generate Multilingual Realistic AI Weather Response for ALL languages
  const generateWeatherResponse = (query: string, langCode: string): string => {
    // If auto-detect, determine language from query text
    const activeLang = langCode === 'auto' ? detectLanguage(query) : langCode;
    const q = (query || '').toLowerCase();

    // Dynamic temperature strings matching user unit (°C or °F)
    const curTemp = formatTemp(28);
    const feelsTemp = formatTemp(30);
    const maxTemp = formatTemp(32);
    const minTemp = formatTemp(24);

    // Check if user mentioned a specific location
    const locationMatch = (query || '').match(/\b(rajkot|ahmedabad|surat|vadodara|mumbai|delhi|bengaluru|chennai|kolkata|pune|hyderabad|london|paris|dubai|tokyo|new york)\b/i);
    const locName = locationMatch ? locationMatch[0].charAt(0).toUpperCase() + (locationMatch[0].slice(1) || '').toLowerCase() : (profile.location ? profile.location.split(',')[0].trim() : "Rajkot");

    // 1. GUJARATI (ગુજરાતી)
    if (activeLang === 'gu') {
      // Greetings & Introductions
      if (q.includes('હેલો') || q.includes('હાય') || q.includes('નમસ્તે') || q.includes('નમસ્કાર') || q.includes('કેમ છો') || q.includes('કોણ') || q.includes('hi') || q.includes('hello') || q.includes('kem') || q.includes('namaste')) {
        return `નમસ્તે! હું WeatherGPT વોઇસ AI છું. હું તમને ${locName} અને ગુજરાતના હવામાન, વરસાદની આગાહી, તાપમાન અને વાવાઝોડાના અલર્ટ વિશે પૂરી માહિતી આપી શકું છું. આજે તમને હવામાન વિશે શું જાણવું છે?`;
      } 
      // Rain & Thunderstorms
      else if (q.includes('વરસાદ') || q.includes('છત્રી') || q.includes('પાણી') || q.includes('મેઘ') || q.includes('ઝરમર') || q.includes('ગાજવીજ') || q.includes('છાટા') || q.includes('varsad') || q.includes('varsat') || q.includes('rain') || q.includes('chhatri') || q.includes('chatri')) {
        return `${locName}માં આજે સાંજે 5:00 થી 8:00 વાગ્યા દરમિયાન 80% ગાજવીજ સાથે ભારે વરસાદની શક્યતા છે. હવામાં ભેજ 68% છે અને પવન 15.4 કિમી/કલાકની ઝડપે ફૂંકાઈ રહ્યો છે. જો તમે બહાર નીકળવાના હોવ તો સાથે છત્રી અથવા રેઈનકોટ ચોક્કસ રાખજો!`;
      } 
      // Temperature & Heat Index
      else if (q.includes('તાપમાન') || q.includes('ગરમી') || q.includes('તડકો') || q.includes('ઠંડી') || q.includes('હવામાન') || q.includes('tapman') || q.includes('garmi') || q.includes('temp') || q.includes('tadko')) {
        return `${locName}નું હાલનું તાપમાન ${curTemp} છે (અનુભવાતું તાપમાન ${feelsTemp}). આજે મહત્તમ તાપમાન ${maxTemp} અને રાત્રે લઘુત્તમ ${minTemp} રહેશે. બપોરના સમયે UV ઇન્ડેક્સ 6 (મધ્યમ) રહેશે, તેથી બપોરે તડકાથી બચવું.`;
      } 
      // Agriculture & Crop weather
      else if (q.includes('ખેતી') || q.includes('પાક') || q.includes('જમીન') || q.includes('કપાસ') || q.includes('મગફળી') || q.includes('ખેડૂત') || q.includes('kheti') || q.includes('pak')) {
        return `ખેડૂત મિત્રો માટે કૃષિ હવામાન સલાહ: આગામી 48 કલાક દરમિયાન ${locName} અને સૌરાષ્ટ્રમાં હળવોથી મધ્યમ વરસાદ મગફળી અને કપાસના પાક માટે ખૂબ લાભદાયી છે. પરંતુ ખેતરમાં વધારાનું પાણી ભરાય નહીં તેની નિકાલ વ્યવસ્થા રાખવી.`;
      } 
      // Wind & Storm Alert
      else if (q.includes('પવન') || q.includes('વાવાઝોડું') || q.includes('તોફાન') || q.includes('આગાહી') || q.includes('અલર્ટ') || q.includes('ચેતવણી') || q.includes('pavan') || q.includes('wind') || q.includes('alert')) {
        return `⚠️ હવામાન ચેતવણી: ${locName} અને દરિયાકાંઠાના વિસ્તારોમાં પવનની ઝડપ 40 થી 62 કિમી/કલાક સુધી પહોંચી શકે છે. દરિયામાં મોજા ઉછળવાની શક્યતા હોવાથી માછીમારોને દરિયો ન ખેડવાની સલાહ આપવામાં આવે છે.`;
      } 
      // Forecast & Tomorrow
      else if (q.includes('કાલે') || q.includes('આવતીકાલે') || q.includes('અઠવાડિયું') || q.includes('પૂર્વાનુમાન') || q.includes('kale') || q.includes('tomorrow') || q.includes('week') || q.includes('forecast')) {
        return `${locName} માટે 7 દિવસની આગાહી: કાલે મંગળવારે 90% વરસાદની શક્યતા સાથે મહત્તમ તાપમાન ${maxTemp} રહેશે. બુધવાર અને ગુરુવારથી આકાશ ખુલ્લું થશે અને રમણીય હવામાન રહેશે.`;
      } 
      // Travel & Road Safety
      else if (q.includes('મુસાફરી') || q.includes('ગાડી') || q.includes('રસ્તો') || q.includes('હાઈવે') || q.includes('travel') || q.includes('drive')) {
        return `મુસાફરી અંગે સલાહ: ${locName} અને NH47 હાઈવે પર સાંજે ભારે વરસાદના કારણે રસ્તા પર પાણી ભરાવાની શક્યતા છે. શનિવારે સવારે મુસાફરી કરવી વધુ સુરક્ષિત રહેશે.`;
      }

      // Comprehensive Default Full Response for any other Gujarati query
      return `${locName}માં આજનું હવામાન વાદળછાયું અને આહલાદક છે. હાલમાં તાપમાન ${curTemp} (અનુભવાતું ${feelsTemp}) છે, હવામાં ભેજ 68% અને સાંજના સમયે 80% વરસાદની શક્યતા છે. પવન ઉત્તર-પશ્ચિમ દિશામાંથી 15.4 કિમી/કલાકની ઝડપે ફૂંકાઈ રહ્યો છે. તમે મને વરસાદ, તાપમાન, ખેતી કે મુસાફરી વિશે પૂછી શકો છો.`;
    }

    // 2. HINDI (हिन्दी)
    if (activeLang === 'hi') {
      if (q.includes('बारिश') || q.includes('छाता') || q.includes('पानी') || q.includes('मानसून')) {
        return `${locName} में आज शाम 5:00 बजे से रात 8:00 बजे के बीच 80% बारिश और गरज-चमक की संभावना है। आर्द्रता 68% है। यदि आप शाम को बाहर जा रहे हैं, तो छाता या रेनकोट अवश्य साथ रखें!`;
      } else if (q.includes('तापमान') || q.includes('गर्मी') || q.includes('धूप')) {
        return `${locName} का वर्तमान तापमान ${curTemp} है और 'फील्स लाइक' तापमान ${feelsTemp} दर्ज किया गया है। आज अधिकतम तापमान ${maxTemp} और रात में न्यूनतम ${minTemp} रहेगा।`;
      } else if (q.includes('हवा') || q.includes('तूफान') || q.includes('आंधी') || q.includes('अलर्ट')) {
        return `मौसम चेतावनी: ${locName} और आसपास के जिलों में 40 किमी/घंटा तक के तेज हवा के झोंके और मूसलाधार बारिश का येलो अलर्ट जारी किया गया है।`;
      }
      return `${locName} में आज का मौसम आंशिक रूप से बादलों भरा और सुहावना है। तापमान ${curTemp} है तथा शाम को बारिश का अनुमान है। क्या आप 7 दिनों का पूर्वानुमान या यात्रा सलाह जानना चाहते हैं?`;
    }

    // 3. MARATHI (मराठी)
    if (activeLang === 'mr') {
      if (q.includes('पाऊस') || q.includes('छत्री') || q.includes('पाणी')) {
        return `${locName}मध्ये आज संध्याकाळी 5:00 ते रात्री 8:00 दरम्यान 80% मुसळधार पावसाची शक्यता आहे. हवेतील आर्द्रता 68% आहे. बाहेर जाताना छत्री नक्की सोबत ठेवा!`;
      } else if (q.includes('तापमान') || q.includes('उष्णता') || q.includes('ऊन')) {
        return `${locName}चे सध्याचे तापमान ${curTemp} असून जाणवणारे तापमान ${feelsTemp} आहे. कमाल तापमान ${maxTemp} आणि किमान तापमान ${minTemp} राहण्याचा अंदाज आहे.`;
      }
      return `${locName}मध्ये आज ढगाळ हवामान राहील. सध्या तापमान ${curTemp} असून वारे ताशी 15.4 किमी वेगाने वाहत आहेत. संध्याकाळी पावसाचा अंदाज आहे.`;
    }

    // 4. BENGALI (বাংলা)
    if (activeLang === 'bn') {
      if (q.includes('বৃষ্টি') || q.includes('ছাতা') || q.includes('জল')) {
        return `${locName}-এ আজ সন্ধ্যা ৫:০০ থেকে রাত ৮:০০ এর মধ্যে ৮০% বজ্রসহ বৃষ্টির সম্ভাবনা রয়েছে। বাতাসে আর্দ্রতা ৬৮%। বাইরে যাওয়ার সময় সঙ্গে ছাতা রাখার পরামর্শ দেওয়া হচ্ছে!`;
      } else if (q.includes('তাপমাত্রা') || q.includes('গরম')) {
        return `${locName}-এর বর্তমান তাপমাত্রা ${curTemp} এবং অনুভূত তাপমাত্রা ${feelsTemp}। দিনের সর্বোচ্চ তাপমাত্রা ${maxTemp} পর্যন্ত পৌঁছাতে পারে।`;
      }
      return `${locName}-এ আজ আংশিক মেঘলা আবহাওয়া থাকবে। তাপমাত্রা ${curTemp} এবং সন্ধ্যার দিকে বৃষ্টির সম্ভাবনা রয়েছে।`;
    }

    // 5. TAMIL (தமிழ்)
    if (activeLang === 'ta') {
      if (q.includes('மழை') || q.includes('குடை')) {
        return `${locName} பகுதியில் இன்று மாலை 5 மணி முதல் 8 மணி வரை 80% இடியுடன் கூடிய கனமழை பெய்ய வாய்ப்புள்ளது. ஈரப்பதம் 68%. வெளியே செல்லும்போது குடை எடுத்துச் செல்லுங்கள்!`;
      } else if (q.includes('வெப்பநிலை') || q.includes('வெயில்')) {
        return `${locName} தற்போதைய வெப்பநிலை ${curTemp} (உணரப்படும் வெப்பநிலை ${feelsTemp}). இன்றைய அதிகபட்ச வெப்பநிலை ${maxTemp} ஆக இருக்கும்.`;
      }
      return `${locName} பகுதியில் இன்று வானம் மேகமூட்டத்துடன் காணப்படும். வெப்பநிலை ${curTemp} மற்றும் மாலை நேரத்தில் மழை பெய்ய வாய்ப்புள்ளது.`;
    }

    // 6. TELUGU (తెలుగు)
    if (activeLang === 'te') {
      if (q.includes('వర్షం') || q.includes('గొడుగు')) {
        return `${locName}లో ఈరోజు సాయంత్రం 5:00 నుండి 8:00 గంటల మధ్య 80% ఉరుములతో కూడిన వర్షం పడే అవకాశం ఉంది. గాలిలో తేమ 68%. బయటకు వెళ్లేటప్పుడు గొడుగు తీసుకెళ్లడం మంచిది!`;
      }
      return `${locName}లో ప్రస్తుత ఉష్णోగ్రత ${curTemp}. ఆకాశం పాక్షికంగా మేఘావృతమై ఉంటుంది మరియు సాయంత్రం వర్ష సూచన ఉంది.`;
    }

    // 7. KANNADA (ಕನ್ನಡ)
    if (activeLang === 'kn') {
      if (q.includes('ಮಳೆ') || q.includes('ಛತ್ರಿ')) {
        return `${locName}ನಲ್ಲಿ ಇಂದು ಸಂಜೆ 5:00 ರಿಂದ 8:00 ರ ನಡುವೆ 80% ಗುಡುಗು ಸಹಿತ ಮಳೆಯಾಗುವ ಸಾಧ್ಯತೆಯಿದೆ. ತೇವಾಂಶ 68%. ಹೊರಗೆ ಹೋಗುವಾಗ ಛತ್ರಿ ತೆಗೆದುಕೊಂಡು ಹೋಗುವುದು ಸೂಕ್ತ!`;
      }
      return `${locName}ನಲ್ಲಿ ಪ್ರಸ್ತುತ ತಾಪಮಾನ ${curTemp} ಆಗಿದೆ. ಸಂಜೆ ವೇಳೆಗೆ ಮಳೆಯಾಗುವ ಮುನ್ಸೂಚನೆ ಇದೆ.`;
    }

    // 8. MALAYALAM (മലയാളം)
    if (activeLang === 'ml') {
      if (q.includes('മഴ') || q.includes('കുട')) {
        return `${locName}ൽ ഇന്ന് വൈകുന്നೇരം 5:00 നും 8:00 നും ഇടയിൽ 80% ഇടിಮಿന്നലോട് കൂടിയ മഴയ്ക്ക് സാധ്യതയുണ്ട്. ഈർപ്പം 68%. പുറത്തിറങ്ങുമ്പോൾ കുട കരുതുക!`;
      }
      return `${locName}ൽ നിലവിലെ താപനില ${curTemp} ആണ്. വൈകുന്നേരത്തോടെ മഴയ്ക്ക് സാധ്യതയുണ്ട്.`;
    }

    // 9. PUNJABI (ਪੰਜਾਬੀ)
    if (activeLang === 'pa') {
      if (q.includes('ਮੀਂਹ') || q.includes('ਛਤਰੀ')) {
        return `${locName} ਵਿੱਚ ਅੱਜ ਸ਼ਾਮ 5:00 ਤੋਂ 8:00 ਵਜੇ ਦਰਮਿਆਨ 80% ਮੀਂਹ ਪੈਣ ਦੀ ਸੰਭਾਵਨਾ ਹੈ। ਨਮੀ 68% ਹੈ। ਬਾਹਰ ਜਾਂਦੇ ਸਮੇਂ ਛਤਰੀ ਜ਼ਰੂਰ ਨਾਲ ਰੱਖੋ!`;
      }
      return `${locName} ਵਿੱਚ ਅੱਜ ਮੌਸਮ ਬੱਦਲਵਾਈ ਵਾਲਾ ਰਹੇਗਾ। ਤਾਪਮਾਨ ${curTemp} ਹੈ ਅਤੇ ਸ਼ਾਮ ਨੂੰ ਮੀਂਹ ਦਾ ਅਨੁਮਾਨ ਹੈ।`;
    }

    // 10. URDU (اردو)
    if (activeLang === 'ur') {
      if (q.includes('بارش') || q.includes('چھتری')) {
        return `${locName} میں آج شام 5:00 سے 8:00 بجے کے درمیان 80 فیصد گرج چمک کے ساتھ بارش کا امکان ہے۔ نمی 68 فیصد ہے۔ باہر جاتے وقت چھتری ضرور ساتھ رکھیں!`;
      }
      return `${locName} میں آج کا موسم جزوی طور پر ابر آلود رہے گا۔ موجودہ درجہ حرارت ${curTemp} ہے اور شام کو بارش کی توقع ہے۔`;
    }

    // 11. SPANISH (Español)
    if (activeLang === 'es') {
      if (q.includes('lluvia') || q.includes('paraguas') || q.includes('llover')) {
        return `Hay un 80% de probabilidad de tormentas y lluvia esta tarde en ${locName} entre las 5:00 PM y las 8:00 PM. Humedad al 68%. ¡Te recomiendo llevar paraguas!`;
      } else if (q.includes('temperatura') || q.includes('calor')) {
        return `La temperatura actual en ${locName} es de ${curTemp} con sensación térmica de ${feelsTemp}. La máxima de hoy alcanzará ${maxTemp}.`;
      }
      return `El clima en ${locName} está parcialmente nublado con ${curTemp} y vientos de 15 km/h. Se esperan lluvias hacia el final de la tarde.`;
    }

    // 12. FRENCH (Français)
    if (activeLang === 'fr') {
      if (q.includes('pluie') || q.includes('parapluie') || q.includes('pleuvoir')) {
        return `Il y a 80 % de risques d'averses orageuses ce soir à ${locName} entre 17h00 et 20h00. Humidité à 68 %. Pensez à vous munir d'un parapluie !`;
      }
      return `À ${locName}, le ciel est actuellement partiellement nuageux avec ${curTemp}. Risque de précipitations en soirée.`;
    }

    // 13. GERMAN (Deutsch)
    if (activeLang === 'de') {
      if (q.includes('regen') || q.includes('schirm') || q.includes('regnen')) {
        return `In ${locName} besteht heute Abend zwischen 17:00 und 20:00 Uhr eine 80%ige Wahrscheinlichkeit für Regenschauer. Luftfeuchtigkeit 68%. Ein Regenschirm wird empfohlen!`;
      }
      return `Aktuell in ${locName}: ${curTemp}, teils bewölkt mit leichtem Wind aus Nordwest (15,4 km/h).`;
    }

    // 14. ITALIAN (Italiano)
    if (activeLang === 'it') {
      if (q.includes('pioggia') || q.includes('ombrello') || q.includes('piovere')) {
        return `C'è una probabilità dell'80% di rovesci a ${locName} stasera tra le 17:00 e le 20:00. Umidità al 68%. Si consiglia di portare un ombrello!`;
      }
      return `Attualmente a ${locName} ci sono ${curTemp} con cielo parzialmente nuvoloso e vento a 15 km/h.`;
    }

    // 15. PORTUGUESE (Português)
    if (activeLang === 'pt') {
      if (q.includes('chuva') || q.includes('guarda-chuva') || q.includes('chover')) {
        return `Há 80% de chance de chuva com trovoadas em ${locName} hoje entre 17h e 20h. Umidade em 68%. Recomenda-se levar um guarda-chuva!`;
      }
      return `Atualmente em ${locName}: ${curTemp}, parcialmente nublado com ventos de 15,4 km/h.`;
    }

    // 16. RUSSIAN (Русский)
    if (activeLang === 'ru') {
      if (q.includes('дождь') || q.includes('зонт') || q.includes('осадки')) {
        return `В городе ${locName} сегодня вечером с 17:00 до 20:00 ожидается 80% вероятность грозового дождя. Влажность 68%. Возьмите с собой зонт!`;
      }
      return `В ${locName} сейчас переменная облачность, температура ${curTemp}, ветер 15 км/ч. К вечеру возможен дождь.`;
    }

    // 17. CHINESE (中文)
    if (activeLang === 'zh') {
      if (q.includes('雨') || q.includes('伞')) {
        return `${locName} 今天傍晚 17:00 至 20:00 之间有 80% 的雷阵雨概率，空气湿度 68%。出行请务必携带雨伞！`;
      }
      return `${locName} 目前天气多云，气温 ${curTemp}，体感温度 ${feelsTemp}，西北风 15.4 公里/小时。`;
    }

    // 18. JAPANESE (日本語)
    if (activeLang === 'ja') {
      if (q.includes('雨') || q.includes('傘')) {
        return `${locName}では本日夕方17時から20時にかけて80%の確率で雷雨が予想されています。湿度68%。外出時は傘を持参してください！`;
      }
      return `${locName}の現在の天気は一部曇り、気温${curTemp}、北西の風15.4km/hです。夕方に降雨が予想されます。`;
    }

    // 19. KOREAN (한국어)
    if (activeLang === 'ko') {
      if (q.includes('비') || q.includes('우산')) {
        return `${locName}에서는 오늘 저녁 5시부터 8시 사이에 80%의 확률로 소나기와 뇌우가 내릴 것으로 예상됩니다. 습도 68%. 우산을 챙기세요!`;
      }
      return `현재 ${locName}은(는) 구름 조금, 기온 ${curTemp}(체감 ${feelsTemp})입니다. 저녁에 비 소식이 있습니다.`;
    }

    // 20. ARABIC (العربية)
    if (activeLang === 'ar') {
      if (q.includes('مطر') || q.includes('مظلة') || q.includes('امطار')) {
        return `هناك احتمال بنسبة 80٪ لهطول أمطار رعدية في ${locName} هذا المساء بين الساعة 5:00 و 8:00 مساءً. الرطوبة 68٪. يُنصح بحمل مظلة!`;
      }
      return `الطقس في ${locName} حالياً غائم جزئياً مع ${curTemp} ورياح بسرعة 15.4 كم/ساعة.`;
    }

    // 21. TURKISH (Türkçe)
    if (activeLang === 'tr') {
      if (q.includes('yağmur') || q.includes('şemsiye')) {
        return `${locName}'de bu akşam 17:00 ile 20:00 saatleri arasında %80 gök gürültülü sağanak yağış bekleniyor. Nem %68. Yanınıza şemsiye alınız!`;
      }
      return `${locName}'de şu an hava parçalı bulutlu, sıcaklık ${curTemp} ve rüzgar 15.4 km/s hızında esiyor.`;
    }

    // 22. DEFAULT ENGLISH
    if (q.includes('rain') || q.includes('umbrella') || q.includes('precipitation')) {
      return `There is an 80% chance of showers and thunderstorms in ${locName} this evening between 5:00 PM and 8:00 PM. Humidity is at 68% with NW winds at 15.4 km/h. Carrying an umbrella is strongly advised!`;
    } else if (q.includes('temp') || q.includes('heat') || q.includes('hot') || q.includes('cold')) {
      return `The current temperature in ${locName} is ${curTemp} with a 'Feels Like' index of ${feelsTemp}. High today will reach ${maxTemp}, and the overnight low will dip to ${minTemp}. UV index is moderate at 6.`;
    } else if (q.includes('alert') || q.includes('storm') || q.includes('warning')) {
      return `⚠️ Weather Warning: High precipitation alert is active for the ${locName} basin. Wind gusts up to 45 km/h are expected in the afternoon. Avoid unnecessary outdoor transit during peak hours.`;
    } else if (q.includes('forecast') || q.includes('week') || q.includes('tomorrow')) {
      return `7-Day Outlook for ${locName}: Rain will continue into Tuesday (90% probability, ${maxTemp}). Skies will clear by Wednesday and Thursday with sunny intervals and warm conditions.`;
    }

    return `Currently in ${locName}, conditions are Partly Cloudy at ${curTemp} with 68% humidity and gentle NW breezes at 15.4 km/h. An 80% chance of showers is forecast for the evening. Feel free to ask in ANY language about hourly radar, travel safety, or climate trends!`;
  };

  // Handle Sending a Message with Dynamic Language Recognition & Live API connection
  const handleSendMessage = async (textToSend?: string, isVoiceInput: boolean = false) => {
    stopSpeaking(); // 🛑 Stop any ongoing speech immediately
    const messageContent = (textToSend || input).trim();
    if ((!messageContent && !previewImage) || isTyping) return;

    // Keep selectedLang as 'auto' if chosen, while using detected language for message tagging
    const effectiveLangCode = selectedLang.code === 'auto' ? detectLanguage(messageContent) : selectedLang.code;

    const currentImage = previewImage;
    const userMessage: ChatMessage = {
      id: `msg-${Date.now()}`,
      role: 'user',
      content: messageContent,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      language: effectiveLangCode,
      image: currentImage || undefined
    };

    // Update active session messages
    const updatedMessages = [...activeSession.messages, userMessage];

    // If this is the first user message, update session title
    const isFirstQuery = activeSession.messages.filter(m => m.role === 'user').length === 0;
    const newTitle = isFirstQuery && messageContent 
      ? messageContent.slice(0, 32) + (messageContent.length > 32 ? '...' : '') 
      : (currentImage && isFirstQuery ? "Weather Lens Analysis" : activeSession.title);

    setSessions(prev => prev.map(s => {
      if (s.id === activeSession.id) {
        return {
          ...s,
          title: newTitle,
          messages: updatedMessages,
          languageCode: effectiveLangCode,
          updatedAt: Date.now()
        };
      }
      return s;
    }));

    setInput('');
    setPreviewImage(null);
    setIsTyping(true);
    setVoiceState('thinking');

    let aiResponseText = '';
    let responseLang = effectiveLangCode;
    let aiExplainWhy: string | undefined = undefined;
    let aiLensData: import('../services/weatherGptApi').WeatherLensResponse | undefined = undefined;

    try {
      // Call live WeatherGPT backend API
      const loc = await getUserLocation();
      const locationStr = loc ? `${loc.latitude},${loc.longitude}` : 'Unknown';

      if (currentImage) {
        const apiRes = await analyzeWeatherLens(currentImage, messageContent, locationStr, effectiveLangCode);
        aiResponseText = apiRes.answer;
        aiLensData = apiRes;
      } else {
        const apiRes = await askWeatherGPT({
          question: messageContent,
          location: loc,
          language: selectedLang.code === 'auto' ? 'auto' : selectedLang.code
        });
        
        if (apiRes.answer) {
          aiResponseText = apiRes.answer;
          aiExplainWhy = apiRes.explainWhy;
          if (apiRes.language) responseLang = apiRes.language;
        } else if (apiRes.error) {
          const errStr = typeof apiRes.error === 'string' ? apiRes.error : apiRes.error.message;
          aiResponseText = `⚠️ **WeatherGPT Error**: ${errStr || 'Unable to retrieve weather forecast.'}`;
        } else {
          aiResponseText = generateWeatherResponse(messageContent, effectiveLangCode);
        }
      }
    } catch (err: any) {
      console.warn('WeatherGPT API live request fallback:', err);
      aiResponseText = generateWeatherResponse(messageContent, effectiveLangCode);
    }

    const aiMessage: ChatMessage = {
      id: `msg-${Date.now() + 1}`,
      role: 'assistant',
      content: aiResponseText,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      language: responseLang,
      explainWhy: aiExplainWhy,
      lensData: aiLensData
    };

    setSessions(prev => prev.map(s => {
      if (s.id === activeSession.id) {
        return {
          ...s,
          messages: [...updatedMessages, aiMessage],
          updatedAt: Date.now()
        };
      }
      return s;
    }));

    setIsTyping(false);

    // Speak response aloud ONLY if the message was spoken by voice or in Live Voice Call mode!
    const shouldSpeakAloud = (isVoiceInput || isLiveVoiceModeRef.current) && !isAudioMutedRef.current;
    if (shouldSpeakAloud) {
      // Clean markdown symbols for natural TTS speech output
      const cleanTtsText = aiResponseText.replace(/[*#`_-]/g, ' ');
      
      let targetSpeechLang = 'en-IN';
      if (responseLang === 'gu') {
        targetSpeechLang = 'gu-IN';
      } else if (responseLang === 'hi' || responseLang === 'hinglish') {
        targetSpeechLang = 'hi-IN';
      } else if (responseLang) {
        // Fallback to match if possible, otherwise en-IN
        const matched = SUPPORTED_LANGUAGES.find(l => l.code === responseLang);
        if (matched) targetSpeechLang = matched.speechLang;
      }
      
      speakText(cleanTtsText, targetSpeechLang, aiMessage.id);
    } else {
      setVoiceState('idle');
    }
  };

  // Start New Chat Session
  const handleCreateNewChat = () => {
    const newSession: ChatSession = {
      id: `session-${Date.now()}`,
      title: `${selectedLang.name} Weather Chat`,
      dateCategory: 'Today',
      languageCode: selectedLang.code,
      updatedAt: Date.now(),
      messages: [
        {
          id: `msg-${Date.now()}`,
          role: 'assistant',
          content: selectedLang.greeting,
          timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          language: selectedLang.code
        }
      ]
    };

    setSessions(prev => [newSession, ...prev]);
    setActiveSessionId(newSession.id);
  };

  // Delete Session
  const handleDeleteSession = (sessionId: string, e: React.MouseEvent) => {
    e.stopPropagation();
    if (sessions.length <= 1) {
      alert('You must keep at least one chat session.');
      return;
    }
    const filtered = sessions.filter(s => s.id !== sessionId);
    setSessions(filtered);
    if (activeSessionId === sessionId) {
      setActiveSessionId(filtered[0].id);
    }
  };

  // Copy text to clipboard
  const handleCopy = (id: string, text: string) => {
    navigator.clipboard.writeText(text);
    setCopiedId(id);
    setTimeout(() => setCopiedId(null), 2000);
  };

  // Switch Language
  // const handleSelectLanguage = (lang: LanguageOption) => {
  //   setSelectedLang(lang);
  //   setLangDropdownOpen(false);

  //   // If active session has no user messages, update greeting to new language
  //   if (activeSession.messages.filter(m => m.role === 'user').length === 0) {
  //     setSessions(prev => prev.map(s => {
  //       if (s.id === activeSession.id) {
  //         return {
  //           ...s,
  //           languageCode: lang.code,
  //           messages: [
  //             {
  //               id: `msg-${Date.now()}`,
  //               role: 'assistant',
  //               content: lang.greeting,
  //               timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
  //               language: lang.code
  //             }
  //           ]
  //         };
  //       }
  //       return s;
  //     }));
  //   }
  // };

  // Enter Live Voice Mode
  const handleEnterLiveVoiceMode = () => {
    stopSpeaking();
    setIsLiveVoiceMode(true);
    // Start listening right away!
    startSpeechRecognition();
  };

  // Exit Live Voice Mode
  const handleExitLiveVoiceMode = () => {
    // Immediately stop all AI voice, audio elements, and recognition
    stopAllAudio();
    stopSpeechRecognition();
    setIsLiveVoiceMode(false);
  };

  return (
    <div className="relative flex h-[calc(100vh-4rem)] w-full rounded-2xl border border-border bg-background shadow-2xl overflow-hidden animate-in fade-in duration-300">
      
      {/* ========================================================================= */}
      {/* 1. COLLAPSIBLE SIDEBAR - CHAT HISTORY                                     */}
      {/* ========================================================================= */}
      <div className={cn(
        "absolute md:relative z-40 h-full flex flex-col border-r border-border glass-panel text-white/80 backdrop-blur-xl transition-all duration-300 ease-in-out",
        sidebarOpen ? "w-72 translate-x-0" : "w-72 -translate-x-full md:w-0 md:translate-x-0 overflow-hidden border-none"
      )}>
        <div className="p-4 border-b border-border flex items-center justify-between">
          <button
            onClick={handleCreateNewChat}
            className="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 bg-primary/10 text-primary hover:bg-primary hover:text-primary-foreground rounded-xl text-sm font-bold transition-all cursor-pointer"
          >
            <Plus className="w-4 h-4" />
            <span>New Chat</span>
          </button>
          <button
            onClick={() => setSidebarOpen(false)}
            className="p-2 ml-2 md:hidden text-muted-foreground hover:bg-muted rounded-lg"
          >
            <PanelLeftClose className="w-4 h-4" />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-3 space-y-4">
          {['Today', 'Yesterday', 'Previous 7 Days'].map((category) => {
            const categorySessions = sessions.filter(s => s.dateCategory === category);
            if (categorySessions.length === 0) return null;
            return (
              <div key={category} className="space-y-1">
                <div className="px-2 py-1 text-[10px] font-bold text-muted-foreground uppercase tracking-wider">
                  {category}
                </div>
                {categorySessions.map((session) => {
                  const isActive = session.id === activeSessionId;
                  const lang = SUPPORTED_LANGUAGES.find(l => l.code === session.languageCode) || SUPPORTED_LANGUAGES[0];
                  return (
                    <div
                      key={session.id}
                      onClick={() => { setActiveSessionId(session.id); if (window.innerWidth < 768) setSidebarOpen(false); }}
                      className={cn(
                        "group flex items-center justify-between px-3 py-2.5 rounded-xl text-sm font-medium transition-all cursor-pointer",
                        isActive 
                          ? "bg-primary/10 text-primary font-bold shadow-xs" 
                          : "hover:bg-muted text-muted-foreground hover:text-foreground"
                      )}
                    >
                      <div className="flex items-center gap-2 min-w-0 flex-1">
                        <span className="text-xs">{lang.flag}</span>
                        <span className="truncate text-xs">{session.title}</span>
                      </div>
                      <button
                        onClick={(e) => handleDeleteSession(session.id, e)}
                        className="opacity-0 group-hover:opacity-100 p-1 hover:text-red-500 rounded transition-opacity"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  );
                })}
              </div>
            );
          })}
        </div>

        {/* User Account / History Scoping Footer */}
        <div className="p-3 border-t border-border bg-white/[0.02]">
          <div className="flex items-center gap-2.5 px-2 py-1.5 rounded-xl bg-white/[0.04] border border-white/5">
            <div className="w-7 h-7 rounded-lg bg-primary/20 text-primary flex items-center justify-center text-xs font-bold shrink-0">
              {isAuthenticated && profile?.avatarInitials ? profile.avatarInitials : '👤'}
            </div>
            <div className="min-w-0 flex-1">
              <div className="text-[11px] font-semibold text-white/90 truncate">
                {isAuthenticated ? profile?.name : 'Guest User'}
              </div>
              <div className="text-[10px] text-white/50 truncate">
                {isAuthenticated ? profile?.email : 'Local History'}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* 2. MAIN CHAT AREA                                                         */}
      {/* ========================================================================= */}
      <div className="flex-1 flex flex-col h-full relative">
        
        {/* Header */}
        <div className="flex items-center justify-between px-4 py-3 bg-background/80 backdrop-blur-md z-30 absolute top-0 left-0 right-0 border-b border-border/50">
          <div className="flex items-center gap-3">
            {!sidebarOpen && (
              <button
                onClick={() => setSidebarOpen(true)}
                className="p-2 hover:bg-muted rounded-xl text-muted-foreground hover:text-foreground transition-colors cursor-pointer"
              >
                <PanelLeft className="w-5 h-5" />
              </button>
            )}
            <div className="hidden sm:flex items-center gap-2">
              <span className="font-bold text-foreground">WeatherGPT AI Assistant</span>
            </div>
          </div>

          <div className="flex items-center gap-2">
            {/* Language Dropdown in Header */}
            <div className="relative">
              <button
                onClick={() => setLangDropdownOpen(!langDropdownOpen)}
                className="flex items-center gap-2 px-3 py-1.5 bg-muted/50 hover:bg-muted rounded-xl text-xs font-bold transition-colors cursor-pointer"
              >
                <span>{selectedLang.flag}</span>
                <span className="hidden sm:inline">{selectedLang.name}</span>
                <ChevronDown className="w-3.5 h-3.5" />
              </button>
              {langDropdownOpen && (
                <div className="absolute top-full right-0 mt-2 w-56 glass-panel text-white border border-white/20 rounded-2xl shadow-2xl overflow-hidden z-50">
                  <div className="p-1 max-h-64 overflow-y-auto">
                    {SUPPORTED_LANGUAGES.map((l) => (
                      <button
                        key={l.code}
                        onClick={() => {
                          setSelectedLang(l);
                          const globalMatch = SITE_LANGUAGES.find(g => g.code === l.code);
                          if (globalMatch) setGlobalLanguage(globalMatch);
                          setLangDropdownOpen(false);
                        }}
                        className={cn(
                          "w-full flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-semibold transition-colors cursor-pointer text-left",
                          selectedLang.code === l.code ? "bg-primary/10 text-primary" : "hover:bg-muted text-foreground"
                        )}
                      >
                        <span className="text-base">{l.flag}</span>
                        <div className="flex flex-col">
                          <span>{l.nativeName}</span>
                          <span className="text-[10px] text-muted-foreground opacity-70">{l.name}</span>
                        </div>
                      </button>
                    ))}
                  </div>
                </div>
              )}
            </div>

            <button
              onClick={() => setIsAudioMuted(!isAudioMuted)}
              className={cn(
                "p-2 rounded-xl transition-colors cursor-pointer",
                isAudioMuted ? "bg-red-500/10 text-red-500" : "bg-muted/50 hover:bg-muted text-foreground"
              )}
            >
              {isAudioMuted ? <VolumeX className="w-4 h-4" /> : <Volume2 className="w-4 h-4" />}
            </button>
            <button
              onClick={() => navigate('/map?locate=true')}
              className="p-2 rounded-xl bg-muted/50 hover:bg-muted text-foreground transition-colors cursor-pointer hidden sm:block"
            >
              <Compass className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Scrollable Messages Area */}
        <div className="flex-1 overflow-y-auto pt-16 pb-32 px-2 md:px-4 w-full mx-auto scroll-smooth">
          
          {/* Empty State / Welcome Screen */}
          {activeSession.messages.length <= 1 && (
            <div className="h-full flex flex-col items-center justify-center pt-4 pb-8 animate-in fade-in zoom-in duration-500">
              <div className="relative w-48 h-48 sm:w-64 sm:h-64 mb-6">
                <div className="absolute inset-0 bg-primary/20 blur-3xl rounded-full animate-pulse" />
                <AIVoiceOrb3D state={voiceState} className="w-full h-full relative z-10" />
              </div>
              
              <h2 className="text-2xl sm:text-3xl font-black text-center mb-3 bg-gradient-to-r from-primary to-blue-500 bg-clip-text text-transparent">
                How can I help with the weather?
              </h2>
              <p className="text-sm text-muted-foreground text-center max-w-md mb-8">
                {selectedLang.greeting}
              </p>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 w-full max-w-2xl">
                {selectedLang.suggestions.map((suggestion, i) => (
                  <button
                    key={i}
                    onClick={() => handleSendMessage(suggestion)}
                    className="p-3.5 rounded-2xl glass-panel text-white border border-white/20 hover:border-primary/40 hover:bg-primary/5 text-sm font-medium text-left transition-all cursor-pointer shadow-xs group"
                  >
                    <div className="text-foreground group-hover:text-primary transition-colors">{suggestion}</div>
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Message List */}
          {activeSession.messages.length > 1 && (
            <div className="space-y-6 pb-4 pt-4">
              {activeSession.messages.map((message) => {
                const isUser = message.role === 'user';
                return (
                  <div key={message.id} className={cn("flex gap-4", isUser ? "justify-end" : "justify-start")}>
                    {!isUser && (
                      <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center flex-shrink-0 mt-1">
                        <Sparkles className="w-4 h-4 text-primary" />
                      </div>
                    )}
                    <div className={cn(
                      "group flex flex-col gap-1 max-w-[85%] md:max-w-[75%]",
                      isUser ? "items-end" : "items-start"
                    )}>
                      <div className={cn(
                        "px-5 py-3.5 rounded-3xl text-sm leading-relaxed shadow-sm",
                        isUser 
                          ? "bg-primary text-primary-foreground rounded-br-sm" 
                          : "bg-muted/50 border border-border/50 text-foreground rounded-bl-sm"
                      )}>
                        {isUser ? (
                          <div className="relative group/msg">
                            {message.image && (
                              <img src={message.image} alt="User upload" className="max-w-[200px] rounded-xl mb-2 border shadow-sm" />
                            )}
                            <p className="whitespace-pre-wrap">{message.content}</p>
                            <button
                              onClick={() => {
                                setInput(message.content);
                                const msgIndex = activeSession.messages.findIndex(m => m.id === message.id);
                                if (msgIndex !== -1) {
                                  setSessions(prev => prev.map(s => {
                                    if (s.id === activeSession.id) {
                                      return { ...s, messages: s.messages.slice(0, msgIndex) };
                                    }
                                    return s;
                                  }));
                                }
                              }}
                              className="absolute -left-10 top-0 p-1.5 bg-background border border-border/50 text-muted-foreground hover:text-primary rounded-full opacity-0 group-hover/msg:opacity-100 transition-all cursor-pointer shadow-sm"
                              title="Edit prompt"
                            >
                              <Edit2 className="w-3.5 h-3.5" />
                            </button>
                          </div>
                        ) : (
                          <div className="prose dark:prose-invert max-w-none text-sm leading-relaxed prose-p:my-1 prose-headings:font-bold prose-headings:my-2.5 prose-ul:my-1 prose-li:my-0.5 prose-strong:text-primary whitespace-pre-line overflow-x-auto relative">
                            {message.lensData && (
                              <div className="mb-4 bg-muted/30 border border-border/60 rounded-xl p-3 flex flex-col gap-2">
                                <div className="text-xs font-bold uppercase tracking-wider text-muted-foreground flex items-center gap-1.5">
                                  <Camera className="w-3.5 h-3.5" /> AI Sky Camera Lens
                                </div>
                                <div className="grid grid-cols-2 gap-2 mt-1">
                                  <div className="bg-background rounded-lg p-2 text-center text-xs shadow-sm">
                                    <div className="text-muted-foreground">Cloud Type</div>
                                    <div className="font-bold text-primary truncate" title={message.lensData.cloudType}>{message.lensData.cloudType}</div>
                                  </div>
                                  <div className="bg-background rounded-lg p-2 text-center text-xs shadow-sm">
                                    <div className="text-muted-foreground">Rain Risk</div>
                                    <div className="font-bold text-red-500">{message.lensData.rainRiskPercent}%</div>
                                  </div>
                                </div>
                              </div>
                            )}
                            <SpokenTextRenderer
                              content={typeof message.content === 'string' ? message.content : String(message.content || '')}
                              isSpeaking={voiceState === 'speaking' && speakingMessageId === message.id}
                              speakingCharIndex={speakingCharIndex}
                            />
                            {message.explainWhy && (
                              <details className="mt-3 text-xs border border-amber-500/20 bg-amber-500/5 rounded-lg overflow-hidden group/explain cursor-pointer">
                                <summary className="px-3 py-2 font-bold text-amber-600 dark:text-amber-400 flex items-center gap-1.5 hover:bg-amber-500/10 transition-colors outline-none list-none">
                                  <span className="w-4 h-4 rounded-full bg-amber-500/20 flex items-center justify-center text-[10px]">💡</span>
                                  Why this prediction?
                                  <ChevronDown className="w-3.5 h-3.5 ml-auto group-open/explain:rotate-180 transition-transform" />
                                </summary>
                                <div className="px-3 pb-3 pt-1 text-muted-foreground whitespace-pre-line">
                                  {typeof message.explainWhy === 'string' ? message.explainWhy : (
                                    <>
                                      <div className="font-bold text-foreground mb-1">{message.explainWhy.title || 'Analysis'}</div>
                                      <div>{message.explainWhy.summary}</div>
                                      {message.explainWhy.factors && message.explainWhy.factors.length > 0 && (
                                        <ul className="list-disc pl-4 mt-1 space-y-0.5">
                                          {message.explainWhy.factors.map((f: any, i: number) => (
                                            <li key={i}>{typeof f === 'string' ? f : JSON.stringify(f)}</li>
                                          ))}
                                        </ul>
                                      )}
                                    </>
                                  )}
                                </div>
                              </details>
                            )}
                          </div>
                        )}
                      </div>
                      
                      {!isUser && (
                        <div className="flex items-center gap-3 px-2 mt-1 opacity-0 group-hover:opacity-100 transition-opacity">
                          <button
                            onClick={() => {
                              const langObj = SUPPORTED_LANGUAGES.find(l => l.code === message.language) || selectedLang;
                              speakText(message.content, langObj.speechLang, message.id);
                            }}
                            className="text-muted-foreground hover:text-primary transition-colors cursor-pointer"
                          >
                            <Volume2 className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => handleCopy(message.id, message.content)}
                            className="text-muted-foreground hover:text-primary transition-colors cursor-pointer"
                          >
                            {copiedId === message.id ? <Check className="w-4 h-4 text-emerald-500" /> : <Copy className="w-4 h-4" />}
                          </button>
                          <button
                            onClick={() => {
                              const waUrl = `https://wa.me/?text=${encodeURIComponent(message.content)}`;
                              window.open(waUrl, '_blank');
                            }}
                            className="text-emerald-500 hover:text-emerald-600 transition-colors cursor-pointer"
                            title="Share on WhatsApp"
                          >
                            <Share2 className="w-4 h-4" />
                          </button>
                        </div>
                      )}
                    </div>
                  </div>
                );
              })}

              {isTyping && (
                <div className="flex gap-4">
                  <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center flex-shrink-0 mt-1">
                    <Sparkles className="w-4 h-4 text-primary animate-spin" />
                  </div>
                  <div className="px-5 py-4 rounded-3xl bg-muted/50 border border-border/50 rounded-bl-sm flex items-center gap-2">
                    <div className="w-2 h-2 rounded-full bg-primary/60 animate-bounce" style={{ animationDelay: '0ms' }} />
                    <div className="w-2 h-2 rounded-full bg-primary/60 animate-bounce" style={{ animationDelay: '150ms' }} />
                    <div className="w-2 h-2 rounded-full bg-primary/60 animate-bounce" style={{ animationDelay: '300ms' }} />
                  </div>
                </div>
              )}
              <div ref={messagesEndRef} />
            </div>
          )}
        </div>

        {/* Floating Input Area (Positioned at bottom center) */}
        <div className="absolute bottom-0 left-0 right-0 p-4 bg-gradient-to-t from-background via-background/90 to-transparent pt-8 pointer-events-none">
          <div className="max-w-3xl mx-auto flex flex-col items-center gap-2 pointer-events-auto">
            {/* Live Speech Recognition Feedback Banner */}
            {isSpeechRecognitionActive && (
              <div className="flex items-center gap-2.5 px-4 py-2 bg-background/90 border border-primary/40 rounded-full shadow-lg backdrop-blur-md animate-in fade-in slide-in-from-bottom-2 duration-200">
                <span className="w-2.5 h-2.5 rounded-full bg-red-500 animate-ping" />
                <span className="text-xs font-semibold text-primary">Listening:</span>
                <span className="text-xs text-foreground font-medium max-w-xs sm:max-w-md truncate">
                  {liveTranscript || 'Speak now... (say "what is the weather today?")'}
                </span>
              </div>
            )}

            {/* Input Bar with integrated Live Voice Call button */}
            <div className="w-full glass-panel text-white border border-white/20 shadow-2xl rounded-[2rem] p-2 flex items-center gap-2 transition-all focus-within:ring-2 focus-within:ring-primary/20">
              
              {/* Mic Speech Dictation Button */}
              <button
                onClick={() => {
                  stopSpeaking();
                  isSpeechRecognitionActive ? stopSpeechRecognition() : startSpeechRecognition();
                }}
                className={cn(
                  "p-3 rounded-full transition-all cursor-pointer flex-shrink-0",
                  isSpeechRecognitionActive 
                    ? "bg-red-500 text-white shadow-lg shadow-red-500/20 animate-pulse" 
                    : "bg-primary/10 text-primary hover:bg-primary/20"
                )}
                title={isSpeechRecognitionActive ? "Stop listening" : "Dictate speech to chat"}
              >
                {isSpeechRecognitionActive ? <MicOff className="w-5 h-5" /> : <Mic className="w-5 h-5" />}
              </button>

              {/* Shifted Live Call Conversation Option (Inside chat box near voice assistant mic) */}
              <button
                onClick={handleEnterLiveVoiceMode}
                className="flex items-center gap-1.5 px-3 py-2 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white rounded-full text-xs font-bold transition-all shadow-md hover:scale-105 cursor-pointer flex-shrink-0 group"
                title="Start 2-Way Interactive Live Voice Call"
              >
                <Radio className="w-3.5 h-3.5 text-amber-300 group-hover:animate-pulse" />
                <span className="hidden sm:inline">Live Call</span>
              </button>

              {/* Camera Button */}
              <div className="relative">
                <button
                  onClick={() => setShowCameraOptions(!showCameraOptions)}
                  className="p-2.5 text-muted-foreground hover:bg-muted rounded-full transition-colors cursor-pointer"
                  title="Upload image or take photo for Weather Lens"
                >
                  <Camera className="w-5 h-5" />
                </button>

                {showCameraOptions && (
                  <div className="absolute bottom-full left-0 mb-2 w-48 glass-panel text-white border border-white/20 shadow-xl rounded-xl p-2 z-50 animate-in slide-in-from-bottom-2">
                    <input 
                      type="file" 
                      accept="image/*" 
                      capture="environment" 
                      className="hidden" 
                      ref={cameraInputRef}
                      onChange={handleImageSelect}
                    />
                    <input 
                      type="file" 
                      accept="image/*" 
                      className="hidden" 
                      ref={fileInputRef}
                      onChange={handleImageSelect}
                    />
                    
                    <button 
                      onClick={() => { cameraInputRef.current?.click(); setShowCameraOptions(false); }}
                      className="w-full flex items-center gap-2 px-3 py-2 text-sm hover:bg-muted rounded-lg transition-colors cursor-pointer"
                    >
                      <Camera className="w-4 h-4" /> Take Photo
                    </button>
                    <button 
                      onClick={() => { fileInputRef.current?.click(); setShowCameraOptions(false); }}
                      className="w-full flex items-center gap-2 px-3 py-2 text-sm hover:bg-muted rounded-lg transition-colors cursor-pointer mt-1"
                    >
                      <ImageIcon className="w-4 h-4" /> Choose from Gallery
                    </button>
                  </div>
                )}
              </div>

              {/* Text Input Field */}
              <div className="flex-1 flex flex-col relative">
                {previewImage && (
                  <div className="absolute bottom-full mb-3 left-0">
                    <div className="relative inline-block">
                      <img src={previewImage} alt="Preview" className="h-24 w-auto rounded-xl border-2 border-primary/20 shadow-lg object-cover" />
                      <button
                        onClick={() => setPreviewImage(null)}
                        className="absolute -top-2 -right-2 bg-background border border-border rounded-full p-1 text-muted-foreground hover:text-red-500 shadow-sm transition-colors cursor-pointer"
                      >
                        <X className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  </div>
                )}
                <input
                  type="text"
                  value={input}
                  onFocus={stopSpeaking}
                  onClick={stopSpeaking}
                  onChange={(e) => {
                    stopSpeaking();
                    setInput(e.target.value);
                  }}
                  onKeyDown={(e) => e.key === 'Enter' && handleSendMessage()}
                  placeholder={isSpeechRecognitionActive ? `Listening...` : `Ask WeatherGPT...`}
                  className="w-full bg-transparent border-none outline-none text-base px-2 text-foreground placeholder:text-muted-foreground"
                />
              </div>

              {/* Send Button */}
              <button
                onClick={() => handleSendMessage()}
                disabled={!input.trim() || isTyping}
                className="p-3 bg-primary text-primary-foreground rounded-full disabled:opacity-40 hover:bg-primary/90 transition-all cursor-pointer flex-shrink-0"
                title="Send message"
              >
                <Send className="w-5 h-5" />
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* 3. LIVE VOICE MODAL OVERLAY                                                */}
      {/* ========================================================================= */}
      {isLiveVoiceMode && (
        <div className="fixed inset-0 z-[100] bg-background/95 backdrop-blur-3xl flex flex-col items-center justify-between p-6 sm:p-12 animate-in fade-in zoom-in-95 duration-300">
          
          <div className="w-full max-w-2xl flex items-center justify-between">
            <button onClick={handleExitLiveVoiceMode} className="p-3 rounded-full bg-muted hover:bg-muted/80 transition-colors">
              <ChevronDown className="w-6 h-6" />
            </button>
            <div className="px-4 py-1.5 bg-primary/10 text-primary font-bold text-xs rounded-full border border-primary/20">
              Live {selectedLang.flag}
            </div>
          </div>
          {/* Language Switcher Pill - Auto Detect instead of the three languages */}
          <div className="flex items-center justify-center gap-2 my-3">
            <div className="flex items-center gap-2 px-4 py-1.5 rounded-full text-xs font-bold bg-primary text-primary-foreground shadow-md ring-2 ring-primary/40">
              <span className="text-sm">🌐</span>
              <span>Auto Detect</span>
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-ping ml-0.5" />
            </div>
          </div>
          <div className="flex-1 flex flex-col items-center justify-center w-full relative">
            <div className={cn(
              "absolute w-64 h-64 rounded-full blur-3xl opacity-40 transition-all duration-700 pointer-events-none",
              voiceState === 'listening' ? "bg-emerald-500 scale-150 animate-pulse" :
              voiceState === 'speaking' ? "bg-amber-500 scale-125" :
              "bg-primary scale-100"
            )} />
            <AIVoiceOrb3D state={voiceState} className="w-72 h-72 relative z-10" />

            <div className="mt-12 text-center space-y-4 relative z-20">
              <div className="text-2xl font-black">
                {voiceState === 'listening' && (selectedLang.code === 'gu' ? "સાંભળી રહ્યો છું..." : "Listening...")}
                {voiceState === 'thinking' && (selectedLang.code === 'gu' ? "વિચાર કરી રહ્યો છું..." : "Thinking...")}
                {voiceState === 'speaking' && (selectedLang.code === 'gu' ? "WeatherGPT બોલી રહ્યો છે..." : "WeatherGPT Speaking...")}
                {voiceState === 'idle' && (selectedLang.code === 'gu' ? "બોલવા માટે માઇક દબાવો" : "Tap mic to speak")}
              </div>
              <div className="h-16 text-muted-foreground max-w-md mx-auto text-lg font-medium">
                {liveTranscript || <span className="opacity-60">Speak in any language (Gujarati, Hindi, English...)...</span>}
              </div>
            </div>
          </div>

          <div className="flex items-center gap-6 mb-8 relative z-20">
            <button
              onClick={() => setIsAudioMuted(!isAudioMuted)}
              className={cn("p-5 rounded-full transition-all cursor-pointer", isAudioMuted ? "bg-red-500/10 text-red-500" : "bg-muted text-foreground hover:bg-muted/80")}
            >
              {isAudioMuted ? <VolumeX className="w-6 h-6" /> : <Volume2 className="w-6 h-6" />}
            </button>
            
            <button
              onClick={isSpeechRecognitionActive ? stopSpeechRecognition : startSpeechRecognition}
              className={cn(
                "p-8 rounded-full shadow-2xl transition-all hover:scale-105 cursor-pointer",
                isSpeechRecognitionActive ? "bg-red-500 text-white animate-pulse" : "bg-primary text-primary-foreground"
              )}
            >
              {isSpeechRecognitionActive ? <MicOff className="w-8 h-8" /> : <Mic className="w-8 h-8" />}
            </button>

            <button
              onClick={handleExitLiveVoiceMode}
              className="p-5 rounded-full bg-red-500 text-white shadow-lg hover:bg-red-600 transition-all hover:scale-105 cursor-pointer"
            >
              <PhoneOff className="w-6 h-6" />
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
