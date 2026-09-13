import React, { useState } from 'react';
import { useUserProfile } from '../hooks/useUserProfile';
import { useGoogleLogin } from '@react-oauth/google';
import { useNavigate, useLocation } from 'react-router-dom';
import { Cloud, Lock, Mail, User, Loader2, ArrowLeft } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import emailjs from '@emailjs/browser';

const AuthPage = () => {
  const [isLogin, setIsLogin] = useState(true);
  const [showEmailForm, setShowEmailForm] = useState(false);
  const { login, signup } = useUserProfile();
  const navigate = useNavigate();
  const location = useLocation();
  const from = location.state?.from || '/';

  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const googleLogin = useGoogleLogin({
    onSuccess: async (tokenResponse: any) => {
      setIsLoading(true);
      try {
        const userInfoRes = await fetch('https://www.googleapis.com/oauth2/v3/userinfo', {
          headers: { Authorization: `Bearer ${tokenResponse.access_token}` },
        });
        const userInfo = await userInfoRes.json();
        
        login({ name: userInfo.name, email: userInfo.email });
        setIsLoading(false);
        navigate(from);
      } catch (error) {
        console.error("Error fetching Google user info:", error);
        setIsLoading(false);
      }
    },
    onError: (errorResponse: any) => {
      console.error("Google Login Error:", errorResponse);
      setIsLoading(false);
    }
  });

  const handleGuest = () => {
    navigate(from);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      if (isLogin) {
        const displayName = name || email.split('@')[0].replace(/[._-]/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
        login({ name: displayName, email });
        navigate(from);
      } else {
        if (name && email && password) {
          const serviceID = 'YOUR_SERVICE_ID';
          const templateID = 'YOUR_TEMPLATE_ID';
          const publicKey = 'YOUR_PUBLIC_KEY';

          try {
            if (serviceID !== 'YOUR_SERVICE_ID') {
              await emailjs.send(
                serviceID,
                templateID,
                {
                  to_name: name,
                  to_email: email,
                  message: 'Welcome to WeatherGPT! Your account has been created successfully.',
                },
                publicKey
              );
            }
          } catch (error) {
            console.error('Error sending email:', error);
          }

          signup({ name, email });
          navigate(from);
        }
      }
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="h-full w-full min-h-[100dvh] flex items-center justify-center p-4 relative overflow-hidden">
      {/* Animated Weather Background */}
      <div className="absolute inset-0 z-0 overflow-hidden pointer-events-none opacity-50 dark:opacity-30">
        <div className="absolute -top-40 -left-40 w-96 h-96 bg-primary/20 rounded-full blur-[100px] animate-pulse" />
        <div className="absolute top-1/3 -right-20 w-80 h-80 bg-blue-500/20 rounded-full blur-[120px] animate-pulse" style={{ animationDelay: '2s' }} />
        <div className="absolute -bottom-40 left-1/2 w-[30rem] h-[30rem] bg-indigo-500/10 rounded-full blur-[150px] animate-pulse" style={{ animationDelay: '4s' }} />
      </div>

      <motion.div 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
        className="max-w-sm w-full z-10"
      >
        <div className="glass-panel rounded-3xl shadow-2xl overflow-hidden p-8 text-white">
          <div className="flex flex-col items-center justify-center mb-8">
            <motion.div 
              initial={{ scale: 0.8 }}
              animate={{ scale: 1 }}
              transition={{ type: 'spring', bounce: 0.5 }}
              className="bg-primary/10 p-3 rounded-2xl mb-5 border border-primary/20"
            >
              <Cloud className="w-10 h-10 text-primary" />
            </motion.div>
            <h1 className="text-2xl font-extrabold text-center tracking-tight">Welcome to WeatherGPT AI</h1>
            <p className="text-muted-foreground text-sm mt-2 text-center">
              Log in or sign up to get smarter weather insights.
            </p>
          </div>

          <AnimatePresence mode="wait">
            {!showEmailForm ? (
              <motion.div 
                key="social-auth"
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: 20 }}
                className="space-y-3"
              >
                <button
                  onClick={() => googleLogin()}
                  disabled={isLoading}
                  className="w-full flex items-center justify-center gap-3 py-3 px-4 glass-pill rounded-xl text-sm font-semibold transition-all hover:bg-white/10 text-white"
                >
                  <svg className="w-5 h-5" viewBox="0 0 24 24">
                    <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
                    <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
                    <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
                    <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
                    <path d="M1 1h22v22H1z" fill="none"/>
                  </svg>
                  Continue with Google
                </button>

                <button
                  onClick={() => setShowEmailForm(true)}
                  className="w-full flex items-center justify-center gap-3 py-3 px-4 glass-pill rounded-xl text-sm font-semibold transition-all hover:bg-white/10 text-white"
                >
                  <Mail className="w-5 h-5 text-foreground" />
                  Continue with Email
                </button>

                <div className="relative py-4 flex items-center">
                  <div className="flex-grow border-t border-border"></div>
                  <span className="flex-shrink-0 mx-4 text-xs text-muted-foreground uppercase tracking-widest font-semibold">Or</span>
                  <div className="flex-grow border-t border-border"></div>
                </div>

                <button
                  onClick={handleGuest}
                  className="w-full flex items-center justify-center gap-3 py-3 px-4 border border-transparent bg-primary text-primary-foreground hover:bg-primary/90 shadow-md rounded-xl text-sm font-semibold transition-all"
                >
                  Continue as Guest
                </button>
                <p className="text-center text-xs text-muted-foreground mt-2">
                  (Weather only, AI disabled)
                </p>
              </motion.div>
            ) : (
              <motion.div 
                key="email-auth"
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -20 }}
              >
                <button 
                  onClick={() => setShowEmailForm(false)}
                  className="flex items-center gap-1.5 text-xs font-semibold text-muted-foreground hover:text-foreground mb-4 transition-colors"
                >
                  <ArrowLeft className="w-3.5 h-3.5" /> Back
                </button>

                <form onSubmit={handleSubmit} className="space-y-4">
                  {!isLogin && (
                    <div>
                      <div className="relative">
                        <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                          <User className="h-4 w-4 text-muted-foreground" />
                        </div>
                        <input
                          type="text"
                          value={name}
                          onChange={(e) => setName(e.target.value)}
                          className="block w-full pl-9 pr-3 py-2.5 glass-input rounded-xl transition-all sm:text-sm"
                          placeholder="Full Name"
                          required={!isLogin}
                        />
                      </div>
                    </div>
                  )}

                  <div>
                    <div className="relative">
                      <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                        <Mail className="h-4 w-4 text-muted-foreground" />
                      </div>
                      <input
                        type="email"
                        value={email}
                        onChange={(e) => setEmail(e.target.value)}
                        className="block w-full pl-9 pr-3 py-2.5 glass-input rounded-xl transition-all sm:text-sm"
                        placeholder="Email Address"
                        required
                      />
                    </div>
                  </div>

                  <div>
                    <div className="relative">
                      <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                        <Lock className="h-4 w-4 text-muted-foreground" />
                      </div>
                      <input
                        type="password"
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        className="block w-full pl-9 pr-3 py-2.5 glass-input rounded-xl transition-all sm:text-sm"
                        placeholder="Password"
                        required
                      />
                    </div>
                  </div>

                  <button
                    type="submit"
                    disabled={isLoading}
                    className="w-full flex justify-center items-center gap-2 py-2.5 px-4 rounded-xl shadow-md text-sm font-semibold text-primary-foreground bg-primary hover:bg-primary/90 transition-all mt-6 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {isLoading ? (
                      <>
                        <Loader2 className="w-4 h-4 animate-spin" />
                        {isLogin ? 'Signing In...' : 'Signing Up...'}
                      </>
                    ) : (
                      isLogin ? 'Sign In' : 'Sign Up'
                    )}
                  </button>
                </form>

                <div className="mt-6 text-center">
                  <button
                    onClick={() => setIsLogin(!isLogin)}
                    className="text-sm font-semibold text-primary hover:text-primary/80 transition-colors focus:outline-none"
                  >
                    {isLogin ? "Don't have an account? Sign up" : 'Already have an account? Sign in'}
                  </button>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </motion.div>
    </div>
  );
};

export default AuthPage;
