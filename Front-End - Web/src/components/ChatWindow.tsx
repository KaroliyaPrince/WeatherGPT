import { useState, useRef, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useLanguage } from '../hooks/useLanguage';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { askWeatherGPT, getUserLocation, analyzeWeatherLens } from '../services/weatherGptApi';
import type { WeatherLensResponse } from '../services/weatherGptApi';
import { Send, Mic, Sparkles, X, Bot, User, Maximize2, Loader2, Edit2, Copy, Camera, Image as ImageIcon, ChevronDown, Share2 } from 'lucide-react';
import { cn } from '../utils/cn';
import { useUserProfile } from '../hooks/useUserProfile';

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  image?: string;
  lensData?: WeatherLensResponse;
  explainWhy?: any;
}

export default function ChatWindow() {
  const navigate = useNavigate();
  const location = useLocation();
  const { t } = useLanguage();
  const { isAuthenticated } = useUserProfile();

  const [isOpen, setIsOpen] = useState(false);
  const [input, setInput] = useState('');
  const [previewImage, setPreviewImage] = useState<string | null>(null);
  const [showCameraOptions, setShowCameraOptions] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const cameraInputRef = useRef<HTMLInputElement>(null);

  const [messages, setMessages] = useState<Message[]>([
    {
      id: '1',
      role: 'assistant',
      content: t('chat_greeting'),
    }
  ]);
  const [isTyping, setIsTyping] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages, isTyping]);

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
    // reset input
    e.target.value = '';
  };

  const handleSend = async (queryOverride?: string) => {
    const q = (queryOverride || input).trim();
    if ((!q && !previewImage) || isTyping) return;
    
    const userMsg: Message = { 
      id: Date.now().toString(), 
      role: 'user', 
      content: q,
      image: previewImage || undefined
    };
    
    setMessages(prev => [...prev, userMsg]);
    setInput('');
    const currentImage = previewImage;
    setPreviewImage(null);
    setIsTyping(true);

    try {
      const loc = await getUserLocation();
      const locationStr = loc ? `${loc.latitude},${loc.longitude}` : 'Unknown';

      if (currentImage) {
        // AI Sky Camera Mode
        const res = await analyzeWeatherLens(currentImage, q, locationStr);
        setMessages(prev => [...prev, {
          id: (Date.now() + 1).toString(),
          role: 'assistant',
          content: res.answer,
          lensData: res
        }]);
      } else {
        // Standard Ask Mode
        const res = await askWeatherGPT({ question: q, location: loc });
        let replyText = res.answer;
      if (!replyText && res.error) {
        replyText = `⚠️ **Error**: ${typeof res.error === 'string' ? res.error : res.error.message}`;
      } else if (!replyText) {
        replyText = 'Sorry, could not retrieve weather forecast at the moment.';
      }
      setMessages(prev => [...prev, {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: replyText
      }]);
      }
    } catch (err: any) {
      setMessages(prev => [...prev, {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: `⚠️ ${err?.message || 'Connection error to WeatherGPT live API.'}`
      }]);
    } finally {
      setIsTyping(false);
    }
  };

  const suggestions = [
    "Kale Rajkot ma varsad hase?",
    "Morbi ma garmi kevi hase?",
    "Will it rain today?"
  ];

  useEffect(() => {
    const handleOpen = () => setIsOpen(true);
    window.addEventListener('open-weathergpt', handleOpen);
    return () => window.removeEventListener('open-weathergpt', handleOpen);
  }, []);

  if (location.pathname.startsWith('/assistant') || location.pathname.startsWith('/chat')) {
    return null;
  }

  if (!isOpen) {
    return (
      <button
        onClick={() => {
          if (!isAuthenticated) {
            navigate('/assistant');
          } else {
            setIsOpen(true);
          }
        }}
        className="fixed bottom-6 right-6 lg:bottom-8 lg:right-8 bg-gradient-to-r from-primary via-blue-600 to-indigo-600 text-primary-foreground px-4 py-3 md:px-5 md:py-3 rounded-full shadow-xl hover:shadow-2xl hover:shadow-primary/40 transition-all transform hover:-translate-y-0.5 hover:scale-105 z-50 flex items-center gap-2.5 border border-white/20 backdrop-blur-md cursor-pointer"
        title="Chat with WeatherGPT AI Assistant"
      >
        <div className="relative flex items-center justify-center">
          <Sparkles className="w-5 h-5 text-amber-300 animate-pulse" />
          <span className="absolute -top-1 -right-1 flex h-2 w-2">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-amber-400 opacity-75"></span>
            <span className="relative inline-flex rounded-full h-2 w-2 bg-amber-300"></span>
          </span>
        </div>
        <span className="font-semibold text-sm tracking-wide">{t('chat_title')}</span>
      </button>
    );
  }

  return (
    <div className="fixed bottom-0 right-0 w-full h-[80vh] md:h-[600px] md:w-[400px] md:bottom-6 md:right-6 bg-card border shadow-2xl md:rounded-2xl flex flex-col z-50 overflow-hidden animate-in slide-in-from-bottom-4 md:slide-in-from-bottom-8">
      {/* Header */}
      <div className="p-4 bg-primary text-primary-foreground flex justify-between items-center">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-white/20 rounded-xl">
            <Bot className="w-5 h-5" />
          </div>
          <div>
            <h3 className="font-bold">{t('chat_title')}</h3>
            <p className="text-xs text-primary-foreground/80">{t('chat_subtitle')}</p>
          </div>
        </div>
        <div className="flex items-center gap-1">
          <button
            onClick={() => {
              setIsOpen(false);
              navigate('/assistant');
            }}
            className="p-2 hover:bg-white/20 rounded-full transition-colors cursor-pointer"
            title="Open Fullscreen ChatGPT Voice Assistant"
          >
            <Maximize2 className="w-4 h-4" />
          </button>
          <button onClick={() => setIsOpen(false)} className="p-2 hover:bg-white/20 rounded-full transition-colors cursor-pointer">
            <X className="w-5 h-5" />
          </button>
        </div>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4 bg-muted/30">
        {messages.map((msg) => (
          <div key={msg.id} className={cn("flex gap-3", msg.role === 'user' ? "flex-row-reverse" : "flex-row")}>
            <div className={cn("w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0", 
              msg.role === 'user' ? "bg-primary text-primary-foreground" : "bg-accent text-accent-foreground"
            )}>
              {msg.role === 'user' ? <User className="w-4 h-4" /> : <Sparkles className="w-4 h-4" />}
            </div>
            <div className={cn(
              "px-4 py-2.5 rounded-2xl max-w-[80%] text-sm relative group",
              msg.role === 'user' 
                ? "bg-primary text-primary-foreground rounded-tr-sm" 
                : "bg-card border shadow-sm text-foreground rounded-tl-sm"
            )}>
              {msg.role === 'user' ? (
                <>
                  {msg.image && (
                    <div className="mb-2">
                      <img src={msg.image} alt="User uploaded" className="rounded-xl max-w-full h-auto max-h-48 object-cover shadow-sm" />
                    </div>
                  )}
                  {msg.content && <div className="whitespace-pre-wrap">{msg.content}</div>}
                  {msg.content && (
                    <button
                      onClick={() => {
                        setInput(msg.content);
                        const msgIndex = messages.findIndex(m => m.id === msg.id);
                        if (msgIndex !== -1) {
                          setMessages(prev => prev.slice(0, msgIndex));
                        }
                      }}
                      className="absolute -left-8 top-2 p-1.5 bg-muted border border-border/50 text-muted-foreground hover:text-primary rounded-full opacity-0 group-hover:opacity-100 transition-all cursor-pointer shadow-sm"
                      title="Edit prompt"
                    >
                      <Edit2 className="w-3.5 h-3.5" />
                    </button>
                  )}
                </>
              ) : (
                <>
                  {msg.lensData && (
                    <div className="mb-3 p-3 bg-primary/10 border border-primary/20 rounded-xl space-y-2 text-foreground">
                      <div className="flex items-center gap-2">
                        <Camera className="w-4 h-4 text-primary" />
                        <span className="font-bold text-xs uppercase tracking-wider text-primary">Weather Lens AI</span>
                      </div>
                      <div className="grid grid-cols-2 gap-2 text-xs">
                        <div className="bg-background rounded-lg p-2 border border-border/50 shadow-xs">
                          <div className="text-muted-foreground">Cloud Type</div>
                          <div className="font-bold">☁️ {msg.lensData.cloudType}</div>
                        </div>
                        <div className="bg-background rounded-lg p-2 border border-border/50 shadow-xs">
                          <div className="text-muted-foreground">AI Confidence</div>
                          <div className="font-bold text-emerald-600">🛡️ {msg.lensData.confidenceScore}%</div>
                        </div>
                        <div className="col-span-2 bg-background rounded-lg p-2 border border-border/50 shadow-xs flex justify-between">
                          <span>Cover: <strong className="text-blue-500">{msg.lensData.cloudCoverPercent}%</strong></span>
                          <span>Rain Risk: <strong className={msg.lensData.rainRiskPercent > 50 ? 'text-red-500' : 'text-emerald-500'}>{msg.lensData.rainRiskPercent}%</strong></span>
                        </div>
                      </div>
                    </div>
                  )}
                  <div className="prose dark:prose-invert max-w-none text-xs leading-relaxed prose-p:my-1 prose-headings:font-bold prose-headings:my-1.5 prose-ul:my-1 prose-li:my-0.5 whitespace-pre-line overflow-x-auto">
                    <ReactMarkdown remarkPlugins={[remarkGfm]}>
                      {typeof msg.content === 'string' ? msg.content : String(msg.content || '')}
                    </ReactMarkdown>
                  </div>
                  {msg.explainWhy && (
                    <details className="mt-3 group/details">
                      <summary className="text-xs font-bold text-primary cursor-pointer list-none flex items-center gap-1.5 p-2 bg-primary/5 rounded-lg border border-primary/10 hover:bg-primary/10 transition-colors">
                        <span>💡 Why this prediction?</span>
                        <ChevronDown className="w-3.5 h-3.5 transition-transform group-open/details:rotate-180" />
                      </summary>
                      <div className="p-2 mt-1 text-[11px] text-muted-foreground bg-background rounded-lg border border-border/50">
                        {typeof msg.explainWhy === 'string' ? msg.explainWhy : (
                          <>
                            <div className="font-bold text-foreground mb-1">{msg.explainWhy.title || 'Analysis'}</div>
                            <div>{msg.explainWhy.summary}</div>
                            {msg.explainWhy.factors && msg.explainWhy.factors.length > 0 && (
                              <ul className="list-disc pl-4 mt-1 space-y-0.5">
                                {msg.explainWhy.factors.map((f: any, i: number) => (
                                  <li key={i}>{typeof f === 'string' ? f : JSON.stringify(f)}</li>
                                ))}
                              </ul>
                            )}
                          </>
                        )}
                      </div>
                    </details>
                  )}
                  <div className="absolute -right-10 top-2 flex flex-col gap-1.5 opacity-0 group-hover:opacity-100 transition-all">
                    <button
                      onClick={() => navigator.clipboard.writeText(msg.content)}
                      className="p-1.5 bg-muted border border-border/50 text-muted-foreground hover:text-primary rounded-full cursor-pointer shadow-sm"
                      title="Copy answer"
                    >
                      <Copy className="w-3.5 h-3.5" />
                    </button>
                    <button
                      onClick={() => {
                         const text = encodeURIComponent(msg.content);
                         window.open(`https://wa.me/?text=${text}`, '_blank');
                      }}
                      className="p-1.5 bg-green-500/10 border border-green-500/30 text-green-600 hover:bg-green-500 hover:text-white rounded-full cursor-pointer shadow-sm"
                      title="Share to WhatsApp"
                    >
                      <Share2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </>
              )}
            </div>
          </div>
        ))}
        {isTyping && (
          <div className="flex gap-3 flex-row">
            <div className="w-8 h-8 rounded-full bg-accent text-accent-foreground flex items-center justify-center flex-shrink-0">
              <Sparkles className="w-4 h-4 text-primary animate-pulse" />
            </div>
            <div className="px-4 py-3 rounded-2xl bg-card border shadow-sm rounded-tl-sm flex items-center gap-2 text-xs text-muted-foreground">
              <Loader2 className="w-4 h-4 animate-spin text-primary" />
              <span>{t('chat_typing')}</span>
            </div>
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* Input */}
      <div className="p-4 bg-card border-t relative">
        {/* Image Preview */}
        {previewImage && (
          <div className="mb-3 relative inline-block">
            <img src={previewImage} alt="Preview" className="h-20 w-auto rounded-lg object-cover shadow-sm border border-border" />
            <button 
              onClick={() => setPreviewImage(null)} 
              className="absolute -top-2 -right-2 bg-red-500 text-white rounded-full p-1 shadow-sm cursor-pointer"
            >
              <X className="w-3 h-3" />
            </button>
          </div>
        )}
        
        {/* Hidden File Inputs */}
        <input 
          type="file" 
          accept="image/*" 
          ref={fileInputRef} 
          className="hidden" 
          onChange={handleImageSelect} 
        />
        <input 
          type="file" 
          accept="image/*" 
          capture="environment" 
          ref={cameraInputRef} 
          className="hidden" 
          onChange={handleImageSelect} 
        />

        {showCameraOptions && (
           <div className="absolute bottom-[4.5rem] left-4 bg-card border border-border/60 shadow-xl rounded-xl p-2 flex flex-col gap-1 z-50">
             <button onClick={() => cameraInputRef.current?.click()} className="flex items-center gap-2 px-3 py-2 text-sm hover:bg-muted rounded-lg text-left cursor-pointer">
               <Camera className="w-4 h-4 text-primary" /> 
               <span>📷 Take Photo</span>
             </button>
             <button onClick={() => fileInputRef.current?.click()} className="flex items-center gap-2 px-3 py-2 text-sm hover:bg-muted rounded-lg text-left cursor-pointer">
               <ImageIcon className="w-4 h-4 text-primary" /> 
               <span>🖼️ Choose from Gallery</span>
             </button>
           </div>
        )}

        {messages.length < 4 && !previewImage && (
          <div className="flex flex-wrap gap-1.5 mb-3">
            {suggestions.map((s, i) => (
              <button 
                key={i} 
                onClick={() => handleSend(s)}
                className="text-[11px] bg-muted hover:bg-primary/10 hover:text-primary border border-border/60 px-2.5 py-1 rounded-full transition-colors text-left"
              >
                {s}
              </button>
            ))}
          </div>
        )}
        <div className="flex items-center gap-2">
          <div className="flex-1 flex items-center bg-muted rounded-full px-4 py-2 border focus-within:border-primary focus-within:ring-1 focus-within:ring-primary transition-all">
            <button 
              onClick={() => setShowCameraOptions(!showCameraOptions)} 
              className={cn("p-1 mr-2 transition-colors cursor-pointer rounded-full hover:bg-primary/10", showCameraOptions || previewImage ? "text-primary" : "text-muted-foreground")}
              title="Upload Photo (Cloud Analysis)"
            >
              <Camera className="w-4 h-4" />
            </button>
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleSend()}
              placeholder={previewImage ? "Ask about this photo..." : t('chat_placeholder')}
              className="flex-1 bg-transparent border-none outline-none text-sm placeholder:text-muted-foreground"
            />
            <button className="p-1 hover:text-primary transition-colors text-muted-foreground cursor-pointer">
              <Mic className="w-4 h-4" />
            </button>
          </div>
          <button 
            onClick={() => handleSend()}
            disabled={!input.trim() && !previewImage}
            className="p-3 bg-primary text-primary-foreground rounded-full disabled:opacity-50 hover:bg-primary/90 transition-colors cursor-pointer"
          >
            <Send className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  );
}
