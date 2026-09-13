import { Outlet, useLocation } from 'react-router-dom';
import { useState } from 'react';
import Navbar from '../components/Navbar';
import NotificationToast from '../components/NotificationToast';
import { CommunityReportModal } from '../components/CommunityReportModal';
import { cn } from '../utils/cn';

export default function MainLayout() {
  const location = useLocation();
  const [isReportModalOpen, setIsReportModalOpen] = useState(false);
  const isAssistantPage = location.pathname.startsWith('/assistant') || location.pathname.startsWith('/chat');

  return (
    <div className={cn(
      "min-h-screen flex flex-col relative overflow-x-hidden transition-all duration-700 sky-gradient-default",
      isAssistantPage && "h-screen max-h-screen overflow-hidden"
    )}>
      {/* Ambient Atmospheric Cloud Glow Layers */}
      <div className="fixed inset-0 pointer-events-none overflow-hidden z-0">
        <div className="absolute -top-20 -right-20 w-96 h-96 rounded-full bg-white/10 blur-3xl pointer-events-none" />
        <div className="absolute top-20 left-1/4 w-[550px] h-[200px] bg-white/[0.08] rounded-full blur-3xl animate-cloud-drift pointer-events-none" />
        <div className="absolute top-72 -left-20 w-[600px] h-[220px] bg-white/[0.05] rounded-full blur-3xl animate-cloud-drift-slow pointer-events-none" />
        <div className="absolute top-96 right-10 w-[480px] h-[180px] bg-white/[0.06] rounded-full blur-3xl animate-cloud-drift pointer-events-none" />
      </div>

      <div className="relative z-10 flex flex-col min-h-screen">
        <Navbar />
        <NotificationToast />
        <main className={cn(
          "flex-1 w-full mx-auto",
          isAssistantPage 
            ? "h-[calc(100vh-64px)] max-h-[calc(100vh-64px)] p-2 md:p-3 overflow-hidden flex flex-col" 
            : "overflow-x-hidden px-2 sm:px-3 lg:px-4 py-4 sm:py-6"
        )}>
          <Outlet />
        </main>
      </div>
      <CommunityReportModal 
        isOpen={isReportModalOpen} 
        onClose={() => setIsReportModalOpen(false)} 
      />
    </div>
  );
}
