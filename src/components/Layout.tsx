import React from 'react';

interface LayoutProps {
  children: React.ReactNode;
}

const Layout: React.FC<LayoutProps> = ({ children }) => {
  return (
    <div className="min-h-screen bg-black text-white flex flex-col relative selection:bg-[#0a84ff]/30">
      {/* Main Content Area */}
      <main className="flex-1 w-full relative">
        {children}
      </main>

      {/* Background Decor */}
      <div className="fixed top-0 right-0 w-[500px] h-[500px] bg-[#0a84ff]/10 rounded-full blur-[120px] pointer-events-none -z-10 opacity-50" />
      <div className="fixed bottom-0 left-0 w-[400px] h-[400px] bg-[#fa114f]/5 rounded-full blur-[100px] pointer-events-none -z-10 opacity-30" />
    </div>
  );
};

export default Layout;
