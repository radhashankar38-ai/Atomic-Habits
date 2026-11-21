import React, { useState, useEffect, useRef, FormEvent, ChangeEvent, useMemo, useCallback } from 'react';
import { Plus, Check, CheckCircle, X, ChevronLeft, ChevronRight, Trash2, Edit2, Activity, Heart, Flame, Zap, MoreHorizontal, Settings, Bell, Smartphone, Download, RotateCcw, AlertCircle, Home, Share2, Loader2, Lock, Award, Star, Shield, Trophy, Target, Crown, Gem, HeartPulse, Briefcase, BookOpen, User, Wallet, Paperclip, Dumbbell, Users, Info, MessageSquareText, Zap as ProductivityIcon } from 'lucide-react';
import { motion, AnimatePresence, useDragControls, useMotionValue, useTransform } from 'motion/react';
import confetti from 'canvas-confetti';
import { toPng } from 'html-to-image';

// --- Types ---
type Habit = {
  id: string;
  name: string;
  color: string;
  createdAt: string;
  targetDays: number;
  completedAt?: string;
  category?: string;
  notes?: string;
};

type Completions = {
  [habitId: string]: string[]; // Array of YYYY-MM-DD strings
};

type Reflections = {
  [habitId: string]: {
    [dateStr: string]: string;
  };
};

type Todo = {
  id: string;
  text: string;
  completed: boolean;
  createdAt: string;
};

// --- Constants ---
const HABIT_CATEGORIES = [
  { value: 'health', label: 'Health', icon: HeartPulse },
  { value: 'work', label: 'Work', icon: Briefcase },
  { value: 'learning', label: 'Learning', icon: BookOpen },
  { value: 'productivity', label: 'Productivity', icon: Target },
  { value: 'personal', label: 'Personal', icon: User },
  { value: 'fitness', label: 'Fitness', icon: Dumbbell },
  { value: 'finance', label: 'Finance', icon: Wallet },
  { value: 'social', label: 'Social', icon: Users },
  { value: 'other', label: 'Others', icon: MoreHorizontal },
];

const COLORS = [
  { name: 'Move', value: '#fa114f', bg: 'bg-[#fa114f]', text: 'text-[#fa114f]', border: 'border-[#fa114f]' },
  { name: 'Exercise', value: '#92ff00', bg: 'bg-[#92ff00]', text: 'text-[#92ff00]', border: 'border-[#92ff00]' },
  { name: 'Stand', value: '#00f2ff', bg: 'bg-[#00f2ff]', text: 'text-[#00f2ff]', border: 'border-[#00f2ff]' },
  { name: 'Mind', value: '#bf5af2', bg: 'bg-[#bf5af2]', text: 'text-[#bf5af2]', border: 'border-[#bf5af2]' },
  { name: 'Hydrate', value: '#0a84ff', bg: 'bg-[#0a84ff]', text: 'text-[#0a84ff]', border: 'border-[#0a84ff]' },
  { name: 'Sleep', value: '#5e5ce6', bg: 'bg-[#5e5ce6]', text: 'text-[#5e5ce6]', border: 'border-[#5e5ce6]' },
  { name: 'Energy', value: '#ff9500', bg: 'bg-[#ff9500]', text: 'text-[#ff9500]', border: 'border-[#ff9500]' },
  { name: 'Focus', value: '#ffd60a', bg: 'bg-[#ffd60a]', text: 'text-[#ffd60a]', border: 'border-[#ffd60a]' },
  { name: 'Breathe', value: '#64d2ff', bg: 'bg-[#64d2ff]', text: 'text-[#64d2ff]', border: 'border-[#64d2ff]' },
  { name: 'Nature', value: '#00d281', bg: 'bg-[#00d281]', text: 'text-[#00d281]', border: 'border-[#00d281]' },
  { name: 'Passion', value: '#ff2d55', bg: 'bg-[#ff2d55]', text: 'text-[#ff2d55]', border: 'border-[#ff2d55]' },
  { name: 'Ground', value: '#a2845e', bg: 'bg-[#a2845e]', text: 'text-[#a2845e]', border: 'border-[#a2845e]' },
  { name: 'Aura', value: '#ff00ff', bg: 'bg-[#ff00ff]', text: 'text-[#ff00ff]', border: 'border-[#ff00ff]' },
  { name: 'Bolt', value: '#ffff00', bg: 'bg-[#ffff00]', text: 'text-[#ffff00]', border: 'border-[#ffff00]' },
  { name: 'Glacier', value: '#a0feff', bg: 'bg-[#a0feff]', text: 'text-[#a0feff]', border: 'border-[#a0feff]' },
  { name: 'Zen', value: '#d4ffea', bg: 'bg-[#d4ffea]', text: 'text-[#d4ffea]', border: 'border-[#d4ffea]' },
  { name: 'Spirit', value: '#af52de', bg: 'bg-[#af52de]', text: 'text-[#af52de]', border: 'border-[#af52de]' },
  { name: 'Mars', value: '#ff4500', bg: 'bg-[#ff4500]', text: 'text-[#ff4500]', border: 'border-[#ff4500]' },
];

const GLOBAL_BADGES = [
  { id: 'first_step', name: 'First Step', desc: '1 Habit', icon: <Star size={20} />, req: 1, type: 'completions', tier: 'Bronze' },
  { id: 'streak_3', name: 'On Fire', desc: '3 Day Streak', icon: <Flame size={20} />, req: 3, type: 'streak', tier: 'Bronze' },
  { id: 'steadfast', name: 'Steadfast', desc: '20 Habits', icon: <Shield size={20} />, req: 20, type: 'completions', tier: 'Silver' },
  { id: 'streak_7', name: 'Unstoppable', desc: '7 Day Streak', icon: <Zap size={20} />, req: 7, type: 'streak', tier: 'Silver' },
  { id: 'centurion', name: 'Centurion', desc: '100 Habits', icon: <Award size={20} />, req: 100, type: 'completions', tier: 'Gold' },
  { id: 'streak_30', name: 'Legend', desc: '30 Day Streak', icon: <Trophy size={20} />, req: 30, type: 'streak', tier: 'Gold' },
  { id: 'streak_90', name: 'Consistent Pro', desc: '90 Day Streak', icon: <Crown size={20} />, req: 90, type: 'streak', tier: 'Gold' },
  { id: 'streak_365', name: 'Immortal', desc: '365 Day Streak', icon: <Award size={20} />, req: 365, type: 'streak', tier: 'Diamond' },
  { id: 'master_builder', name: 'Master Builder', desc: '500 Habits', icon: <Gem size={20} />, req: 500, type: 'completions', tier: 'Diamond' },
];

const HABIT_MILESTONES = [
  { tier: 'Bronze', req: 3, icon: <Star size={14} /> },
  { tier: 'Silver', req: 10, icon: <Shield size={14} /> },
  { tier: 'Gold', req: 30, icon: <Trophy size={14} /> },
  { tier: 'Platinum', req: 100, icon: <Crown size={14} /> },
];

// --- Utils ---
const formatDate = (date: Date) => {
  const d = new Date(date);
  d.setMinutes(d.getMinutes() - d.getTimezoneOffset());
  return d.toISOString().split('T')[0];
};

const isDateCompleted = (completions: string[], dateStr: string) => {
  if (!completions) return false;
  return completions.some(c => c.startsWith(dateStr));
};

const calculateStreak = (completions: string[], createdAt?: string) => {
  if (!completions) return 0;
  
  const today = new Date();
  const todayStr = formatDate(today);
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  const yesterdayStr = formatDate(yesterday);

  // Check if today is completed
  const isTodayCompleted = isDateCompleted(completions, todayStr);
  // Check if yesterday is completed
  const isYesterdayCompleted = isDateCompleted(completions, yesterdayStr);

  if (isTodayCompleted || isYesterdayCompleted) {
    // Positive streak
    let count = 0;
    let checkDate = new Date(isTodayCompleted ? today : yesterday);
    
    while (isDateCompleted(completions, formatDate(checkDate))) {
      count++;
      checkDate.setDate(checkDate.getDate() - 1);
      if (count > 1000) break; // Safety
    }
    
    // Formula: Day 1 = 1, Day 10 = 50 -> Math.ceil(n*n/2)
    return Math.ceil((count * count) / 2);
  } else {
    // Negative streak
    let count = 0;
    let checkDate = new Date(yesterday); // Start checking from yesterday, as today is not yet missed
    const startLimit = createdAt ? new Date(createdAt) : null;
    if (startLimit) startLimit.setHours(0, 0, 0, 0);

    while (!isDateCompleted(completions, formatDate(checkDate))) {
      // Don't count missed days before the habit was created
      if (startLimit && checkDate < startLimit) break;
      
      count++;
      checkDate.setDate(checkDate.getDate() - 1);
      
      if (count > 1000) break; // Safety
    }
    
    if (count === 0) return 0;
    if (count > 10) return 0;
    
    // Formula: Missed Day 1 = -1, Day 2 = -3 -> -(m * (m + 1)) / 2
    return -((count * (count + 1)) / 2);
  }
};

const getStreakCount = (completions: string[]) => {
  if (!completions || completions.length === 0) return 0;
  const today = new Date();
  const todayStr = formatDate(today);
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  const yesterdayStr = formatDate(yesterday);

  const isTodayCompleted = isDateCompleted(completions, todayStr);
  const isYesterdayCompleted = isDateCompleted(completions, yesterdayStr);

  if (!isTodayCompleted && !isYesterdayCompleted) return 0;

  let count = 0;
  let checkDate = new Date(isTodayCompleted ? today : yesterday);
  
  while (isDateCompleted(completions, formatDate(checkDate))) {
    count++;
    checkDate.setDate(checkDate.getDate() - 1);
    if (count > 2000) break;
  }
  return count;
};

const getDaysArray = (endDate: Date, numDays: number) => {
  const days = [];
  for (let i = 0; i < numDays; i++) {
    const d = new Date(endDate);
    d.setDate(d.getDate() - i);
    days.push(d);
  }
  return days;
};

const getEndDate = (createdAt: string, targetDays: number) => {
  const start = new Date(createdAt);
  const end = new Date(start);
  end.setDate(start.getDate() + targetDays);
  return end;
};

// --- Components ---
const Certificate = ({ habit, onClose, userName }: { habit: Habit, onClose: () => void, userName: string }) => {
  const cObj = COLORS.find(c => c.value === habit.color) || COLORS[0];
  const [isSharing, setIsSharing] = useState(false);
  const [isGenerating, setIsGenerating] = useState(false);
  const certificateRef = useRef<HTMLDivElement>(null);

  const milestone = useMemo(() => {
    return [...HABIT_MILESTONES].reverse().find(m => habit.targetDays >= m.req) || HABIT_MILESTONES[0];
  }, [habit.targetDays]);

  const handleShare = async () => {
    if (!certificateRef.current) return;
    
    setIsGenerating(true);
    try {
      // Small delay to ensure animations are settled
      await new Promise(resolve => setTimeout(resolve, 300));
      
      const element = certificateRef.current;
      const width = element.offsetWidth;
      // Target 4K width (3840px)
      const targetWidth = 3840;
      const scale = targetWidth / width;

      const dataUrl = await toPng(element, {
        cacheBust: true,
        backgroundColor: '#000000',
        pixelRatio: scale, 
        quality: 1,
        style: {
          borderRadius: '0',
          transform: 'none'
        }
      });

      const blob = await (await fetch(dataUrl)).blob();
      const file = new File([blob], `certificate-${habit.name}.png`, { type: 'image/png' });

      const shareText = `I just mastered my "${habit.name}" habit for ${habit.targetDays} days! 🏆 #HabitTracker #Consistency`;

      if (navigator.share && navigator.canShare && navigator.canShare({ files: [file] })) {
        await navigator.share({
          files: [file],
          title: 'Habit Mastered!',
          text: shareText,
        });
      } else {
        // Fallback: Download the image
        const link = document.createElement('a');
        link.download = `habit-mastery-${habit.name.toLowerCase().replace(/\s+/g, '-')}.png`;
        link.href = dataUrl;
        link.click();
        
        setIsSharing(true);
        setTimeout(() => setIsSharing(false), 2000);
      }
    } catch (err) {
      console.error('Error generating or sharing image:', err);
      // Final fallback to text sharing
      const shareText = `I just mastered my "${habit.name}" habit for ${habit.targetDays} days! 🏆`;
      if (navigator.share) {
        await navigator.share({ text: shareText });
      }
    } finally {
      setIsGenerating(false);
    }
  };
  
  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-[100] bg-black/90 backdrop-blur-xl flex items-center justify-center p-6"
    >
      <motion.div
        initial={{ scale: 0.8, y: 20 }}
        animate={{ scale: 1, y: 0 }}
        exit={{ scale: 0.8, y: 20 }}
        className="bg-[#1c1c1e] w-full max-w-md rounded-[2rem] overflow-hidden border border-white/10 shadow-2xl relative"
      >
        {/* Certificate Content Wrapper for Capture */}
        <div ref={certificateRef} className="bg-black relative overflow-hidden">
          <div className="p-10 text-center space-y-10 relative z-10">
            <div className="absolute top-0 left-0 w-full h-2 bg-gradient-to-r from-transparent via-white/30 to-transparent" />
            
            <div className="flex justify-center pt-8">
              <div className={`w-32 h-32 rounded-full ${cObj.bg} flex items-center justify-center shadow-[0_0_50px_rgba(0,0,0,0.5)] relative overflow-hidden group`}>
                <div className="absolute inset-0 bg-white/20 opacity-0 group-hover:opacity-100 transition-opacity duration-150" />
                <div className="relative z-10 flex flex-col items-center text-black">
                  {React.cloneElement(milestone.icon as React.ReactElement, { size: 42, strokeWidth: 3, fill: 'currentColor' })}
                  <span className="text-[12px] font-black uppercase tracking-tighter mt-1">{milestone.tier}</span>
                </div>
                <motion.div
                  animate={{ rotate: 360 }}
                  transition={{ duration: 20, repeat: Infinity, ease: "linear" }}
                  className="absolute inset-2 border border-dashed border-black/40 rounded-full"
                />
              </div>
            </div>

            <div className="space-y-2">
              <h2 className="text-4xl font-black uppercase tracking-tighter italic leading-none text-white drop-shadow-2xl">Mastery</h2>
              <p className="text-zinc-500 text-[11px] font-black uppercase tracking-[0.4em]">{milestone.tier} Achievement</p>
            </div>

            <div className="py-8 border-y border-white/10 space-y-4">
              <p className="text-zinc-400 text-sm font-bold uppercase tracking-widest opacity-80">successfully completed</p>
              <h3 className={`text-5xl font-black tracking-tight ${cObj.text} drop-shadow-lg`}>{habit.name}</h3>
              <p className="text-zinc-400 text-base font-medium">for a total of <span className="text-white font-black">{habit.targetDays} days</span></p>
            </div>

            <div className="flex justify-between items-end pt-6">
              <div className="text-left">
                <p className="text-[10px] text-zinc-500 font-black uppercase tracking-widest mb-1.5 opacity-60">Date of Achievement</p>
                <p className="text-base font-mono font-bold text-zinc-300">{new Date(habit.completedAt || Date.now()).toLocaleDateString()}</p>
              </div>
              <div className="text-right">
                <p className="text-[10px] text-zinc-500 font-black uppercase tracking-widest mb-1.5 opacity-60">Verified by</p>
                <p className="text-xl font-serif italic text-zinc-200 font-bold">{userName || 'User'}</p>
              </div>
            </div>

            {/* Quality Indicator (Only visible in high-res export) */}
            <div className="pt-4 opacity-10">
              <p className="text-[8px] font-black uppercase tracking-[0.5em] text-white">4K Ultra HD Authentic Generation</p>
            </div>
          </div>

          {/* Sharper Decorative elements */}
          <div className="absolute -top-32 -left-32 w-64 h-64 bg-[#0a84ff]/15 rounded-full blur-[80px] pointer-events-none" />
          <div className="absolute -bottom-32 -right-32 w-64 h-64 bg-[#fa114f]/15 rounded-full blur-[80px] pointer-events-none" />
          <div className="absolute inset-0 bg-[url('https://www.transparenttextures.com/patterns/carbon-fibre.png')] opacity-[0.03] pointer-events-none" />
        </div>

        {/* Controls (Outside capture ref) */}
        <div className="px-8 pb-8 space-y-4">
          <div className="flex justify-between items-center absolute top-6 left-6 right-6 z-20">
            <button 
              onClick={handleShare}
              disabled={isGenerating}
              className="px-4 h-10 rounded-full bg-white/5 border border-white/10 flex items-center gap-2 text-white hover:bg-white/10 transition-colors relative disabled:opacity-50"
            >
              {isGenerating ? (
                <>
                  <Loader2 size={16} className="animate-spin" />
                  <span className="text-[10px] font-bold uppercase tracking-widest">Generating 4K...</span>
                </>
              ) : (
                <>
                  <Share2 size={16} />
                  <span className="text-[10px] font-bold uppercase tracking-widest">Share 4K Achievement</span>
                </>
              )}
              <AnimatePresence>
                {isSharing && (
                  <motion.div
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -10 }}
                    className="absolute bottom-full mb-2 px-2 py-1 bg-white text-black text-[10px] font-bold rounded whitespace-nowrap"
                  >
                    Saved!
                  </motion.div>
                )}
              </AnimatePresence>
            </button>
            <button 
              onClick={onClose}
              className="w-10 h-10 rounded-full bg-white/5 border border-white/10 flex items-center justify-center text-white hover:bg-white/10 transition-colors"
            >
              <X size={18} />
            </button>
          </div>

          <button
            onClick={onClose}
            className={`w-full py-4 rounded-2xl ${cObj.bg} text-black font-black uppercase tracking-widest text-sm shadow-lg active:scale-95 transition-transform`}
          >
            Claim Achievement
          </button>
        </div>
      </motion.div>
    </motion.div>
  );
};

const CalendarGrid = ({ habit, completions }: { habit: Habit, completions: string[] }) => {
  const cObj = COLORS.find(c => c.value === habit.color) || COLORS[0];
  const [currentMonth, setCurrentMonth] = useState(new Date());

  const nextMonth = () => {
    setCurrentMonth(prev => new Date(prev.getFullYear(), prev.getMonth() + 1, 1));
  };

  const prevMonth = () => {
    setCurrentMonth(prev => new Date(prev.getFullYear(), prev.getMonth() - 1, 1));
  };

  const year = currentMonth.getFullYear();
  const month = currentMonth.getMonth();
  const firstDay = new Date(year, month, 1).getDay();
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  
  const today = new Date();
  const isCurrentMonth = today.getFullYear() === year && today.getMonth() === month;
  const todayDate = today.getDate();

  const days = [];
  const weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  // padding
  for (let i = 0; i < firstDay; i++) {
    days.push(<div key={`empty-${i}`} className="w-6 h-6" />);
  }

  // days
  for (let i = 1; i <= daysInMonth; i++) {
    const isToday = isCurrentMonth && i === todayDate;
    const dateStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(i).padStart(2, '0')}`;
    const isCompleted = isDateCompleted(completions, dateStr);

    days.push(
      <div key={i} className="flex flex-col items-center justify-center w-6 h-6 relative">
        <div className={`w-5 h-5 flex items-center justify-center rounded-full text-[11px] ${
          isCompleted 
            ? `${cObj.bg} text-black font-bold` 
            : isToday 
              ? 'border border-[#0a84ff] text-[#0a84ff] font-bold' 
              : 'text-app-text-muted'
        }`}>
          {i}
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col">
      <div className="flex justify-between items-center mb-2 px-1">
        <button onClick={prevMonth} className="text-app-text-muted p-1 hover:bg-app-text/10 rounded-full transition-colors"><ChevronLeft size={14} /></button>
        <span className="font-semibold text-[11px] text-app-text-muted">
          {currentMonth.toLocaleDateString('en-US', { month: 'short', year: 'numeric' })}
        </span>
        <button onClick={nextMonth} className="text-app-text-muted p-1 hover:bg-app-text/10 rounded-full transition-colors"><ChevronRight size={14} /></button>
      </div>
      <div className="grid grid-cols-7 gap-y-1.5 place-items-center">
        {weekDays.map((d, i) => (
          <div key={`wd-${i}`} className="text-[9px] font-bold text-app-text-muted mb-0.5">{d}</div>
        ))}
        {days}
      </div>
    </div>
  );
};

const Typewriter = ({ text, delay = 0 }: { text: string, delay?: number }) => {
  const [displayedText, setDisplayedText] = useState('');
  
  useEffect(() => {
    let timeout: NodeJS.Timeout;
    let charIndex = 0;
    setDisplayedText('');
    
    const startTyping = () => {
      const typeChar = () => {
        if (charIndex < text.length) {
          setDisplayedText(text.slice(0, charIndex + 1));
          charIndex++;
          timeout = setTimeout(typeChar, 30);
        }
      };
      typeChar();
    };

    const initialDelay = setTimeout(startTyping, delay * 1000);
    
    return () => {
      clearTimeout(initialDelay);
      clearTimeout(timeout);
    };
  }, [text, delay]);

  return <span>{displayedText}</span>;
};

const TodoItem = React.forwardRef<HTMLDivElement, { todo: Todo, toggleTodo: (id: string) => void, removeTodo: (id: string) => void }>(({ todo, toggleTodo, removeTodo }, ref) => {
  const x = useMotionValue(0);
  const binOpacity = useTransform(x, [0, -40, -80], [0, 0.5, 1]);
  const binScale = useTransform(x, [0, -80], [0.8, 1]);

  return (
    <motion.div 
      ref={ref}
      layout
      initial={{ opacity: 0, height: 0, marginBottom: 0 }}
      animate={{ opacity: 1, height: "auto", marginBottom: 12 }}
      exit={{ opacity: 0, height: 0, marginBottom: 0 }}
      className="relative overflow-hidden rounded-[20px] bg-black"
    >
      {/* Delete button layer underneath */}
      <div className="absolute inset-0 bg-black flex justify-end items-center pr-4">
        <motion.button 
          style={{ opacity: binOpacity, scale: binScale }}
          whileTap={{ scale: 0.95 }}
          onClick={() => removeTodo(todo.id)}
          className="w-12 h-12 rounded-[18px] bg-red-500 text-white flex items-center justify-center shadow-lg shadow-red-500/30 cursor-pointer"
        >
          <Trash2 size={24} />
        </motion.button>
      </div>

      {/* Main todo content layer */}
      <motion.div
        drag="x"
        style={{ x }}
        dragConstraints={{ right: 0, left: -80 }}
        dragElastic={0.05}
        className={`bg-black p-5 flex items-center gap-4 relative z-10 select-none border border-white/10 rounded-[20px] ${todo.completed ? 'opacity-40 grayscale' : ''}`}
      >
        <button 
          onClick={() => toggleTodo(todo.id)}
          className={`w-7 h-7 rounded-xl border-2 flex items-center justify-center transition-all duration-150 shrink-0 ${
            todo.completed ? 'bg-[#34c759] border-[#34c759] shadow-lg shadow-[#34c759]/20' : 'border-white/10 bg-white/5 hover:border-zinc-500'
          }`}
        >
          {todo.completed && <Check size={16} className="text-black" strokeWidth={4} />}
        </button>
        
        <span className={`flex-1 text-sm font-bold tracking-tight transition-all duration-150 ${todo.completed ? 'line-through text-zinc-500' : 'text-zinc-200'}`}>
          {todo.text}
        </span>
      </motion.div>
    </motion.div>
  );
});

TodoItem.displayName = 'TodoItem';

const ActivityRings = ({ habits, completions }: { habits: Habit[], completions: Completions }) => {
  const rings = habits.slice(0, 3).map((habit, i) => {
    const cObj = COLORS.find(c => c.value === habit.color) || COLORS[i % COLORS.length];
    const habitComps = completions[habit.id] || [];
    const progress = habit.targetDays > 0 
      ? Math.min(1, habitComps.length / habit.targetDays) 
      : (habitComps.length > 0 ? 1 : 0);
    const radius = 44 - (i * 10);
    const circumference = 2 * Math.PI * radius;
    const offset = circumference - (progress * circumference);

    return (
      <g key={`ring-${habit.id}`} className="rotate-[-90deg] origin-center">
        {/* Background Track */}
        <circle
          cx="50"
          cy="50"
          r={radius}
          stroke={cObj.value}
          strokeWidth="8"
          fill="transparent"
          style={{ opacity: 0.1 }}
        />
        {/* Progress Ring */}
        <motion.circle
          cx="50"
          cy="50"
          r={radius}
          stroke={cObj.value}
          strokeWidth="8"
          strokeDasharray={circumference}
          initial={{ strokeDashoffset: circumference }}
          animate={{ strokeDashoffset: offset }}
          transition={{ type: "spring", bounce: 0.2, duration: 0.1, delay: i * 0.02 }}
          fill="transparent"
          strokeLinecap="round"
          style={{
            filter: `drop-shadow(0 0 2px ${cObj.value}44)`
          }}
        />
      </g>
    );
  });

  return (
    <div className="relative w-52 h-52">
      <svg viewBox="0 0 100 100" className="w-full h-full">
        {rings}
      </svg>
    </div>
  );
};

const TodoPage = ({ 
  todos, 
  setTodos, 
  onBack,
  userName,
  setIsAdding,
  setIsSettingsOpen
}: { 
  todos: Todo[], 
  setTodos: React.Dispatch<React.SetStateAction<Todo[]>>, 
  onBack: () => void,
  userName: string,
  setIsAdding: (val: boolean) => void,
  setIsSettingsOpen: (val: boolean) => void
}) => {
  const [newTodo, setNewTodo] = useState('');
  const [showTodoNav, setShowTodoNav] = useState(true);
  const [isAtTop, setIsAtTop] = useState(true);

  const handleScroll = (e: React.UIEvent<HTMLDivElement>) => {
    const currentScrollY = e.currentTarget.scrollTop;
    setIsAtTop(currentScrollY <= 0);
    if (currentScrollY <= 20) {
      setShowTodoNav(true);
    } else {
      setShowTodoNav(false);
    }
  };

  const addTodo = (e: FormEvent) => {
    e.preventDefault();
    if (!newTodo.trim()) return;
    
    const todo: Todo = {
      id: Math.random().toString(36).substring(2, 9),
      text: newTodo.trim(),
      completed: false,
      createdAt: new Date().toISOString(),
    };
    
    setTodos([todo, ...todos]);
    setNewTodo('');
  };

  const toggleTodo = (id: string) => {
    setTodos(todos.map(t => t.id === id ? { ...t, completed: !t.completed } : t));
  };

  const removeTodo = (id: string) => {
    setTodos(todos.filter(t => t.id !== id));
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 50, filter: 'blur(10px)' }}
      animate={{ opacity: 1, y: 0, filter: 'blur(0px)' }}
      exit={{ opacity: 0, y: 50, filter: 'blur(10px)' }}
      drag={isAtTop ? "y" : false}
      dragConstraints={{ top: 0, bottom: 0 }}
      dragElastic={{ top: 0, bottom: 0.5 }}
      onDragEnd={(_, info) => {
        if (info.offset.y > 60) {
          onBack();
        }
      }}
      transition={{ type: 'spring', damping: 28, stiffness: 220, mass: 0.8 }}
      className="fixed inset-0 z-[120] bg-black flex flex-col overflow-hidden"
    >
      <motion.div 
        animate={{
          backgroundColor: showTodoNav ? 'rgba(0, 0, 0, 0.8)' : 'rgba(0, 0, 0, 0)',
          backdropFilter: showTodoNav ? 'blur(12px)' : 'blur(0px)',
          y: showTodoNav ? 0 : -20
        }}
        className="shrink-0 px-6 pt-8 pb-4 z-50 fixed top-0 left-0 right-0 pointer-events-none"
      >
        <div className="flex items-center justify-between h-11 pointer-events-auto">
          <AnimatePresence>
            {showTodoNav && (
              <motion.h1 
                initial={{ opacity: 0, x: -10, filter: 'blur(8px)' }}
                animate={{ opacity: 1, x: 0, filter: 'blur(0px)' }}
                exit={{ opacity: 0, x: -10, filter: 'blur(8px)' }}
                transition={{ duration: 0.1 }}
                className="text-3xl font-bold tracking-tight text-white whitespace-nowrap"
              >
                To-Do
              </motion.h1>
            )}
          </AnimatePresence>
        </div>
      </motion.div>

      <div 
        onScroll={handleScroll}
        className="flex-1 overflow-y-auto no-scrollbar pt-28"
      >
        <motion.div 
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          className="px-6 mb-8 mt-6"
        >
          <h1 className="text-3xl font-bold tracking-tight">
            <Typewriter text={userName ? `Hello, ${userName}` : 'Hello, Friend'} />
          </h1>
          <p className="text-sm text-app-text-muted mt-1">Ready to complete your checklists?</p>
        </motion.div>

        <div className="px-6 space-y-3 pb-12">
          <AnimatePresence mode="popLayout">
          {todos.length === 0 ? (
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="h-full flex flex-col items-center justify-center text-zinc-600 space-y-4 py-20"
            >
              <div className="w-20 h-20 rounded-full glass-panel flex items-center justify-center opacity-20 relative">
                 <div className="absolute inset-0 bg-[#0a84ff]/10 blur-xl rounded-full" />
                 <CheckCircle size={40} className="relative z-10" />
              </div>
              <p className="text-xs font-bold uppercase tracking-[0.2em] opacity-40">No tasks for today</p>
            </motion.div>
          ) : (
            todos.map(todo => (
              <TodoItem 
                key={todo.id} 
                todo={todo} 
                toggleTodo={toggleTodo} 
                removeTodo={removeTodo} 
              />
            ))
          )}
        </AnimatePresence>
      </div>
    </div>

    <div className="shrink-0 z-50 mt-auto bg-black/40 backdrop-blur-2xl border-t border-white/5 pt-4 pb-12 px-6">
      <form onSubmit={addTodo} className="mb-6 relative z-50">
        <div className="relative">
          <input
            type="text"
            value={newTodo}
            onChange={(e) => setNewTodo(e.target.value)}
            placeholder="Add a new task..."
            className="w-full bg-app-card border border-app-border rounded-2xl px-5 py-4 text-app-text placeholder:text-zinc-600 focus:outline-none focus:ring-2 focus:ring-[#0a84ff]/50 transition-all font-medium"
          />
          <button 
            type="submit"
            className="absolute right-2 top-2 bottom-2 px-6 rounded-xl bg-[#0a84ff] text-white font-black text-[10px] uppercase tracking-widest shadow-lg shadow-[#0a84ff]/20 active:scale-95 transition-transform"
          >
            ADD
          </button>
        </div>
      </form>

      <motion.div 
        initial={false}
        animate={{
          y: showTodoNav ? 0 : 100,
          opacity: showTodoNav ? 1 : 0,
          filter: showTodoNav ? 'blur(0px)' : 'blur(4px)',
          height: showTodoNav ? 'auto' : 0
        }}
        transition={{ duration: 0.15, ease: [0.23, 1, 0.32, 1] }}
        className="flex flex-col items-center overflow-hidden"
      >
        <div className="bg-app-card-secondary/80 backdrop-blur-2xl px-5 sm:px-10 py-4 sm:py-5 rounded-full flex items-center justify-center gap-2.5 sm:gap-4 border border-app-border shadow-2xl mx-auto w-fit select-none">
          <CheckCircle className="w-6 h-6 sm:w-8 sm:h-8 text-white" />
          <h2 className="text-xs font-black uppercase tracking-[0.2em] text-white whitespace-nowrap">TO-DO</h2>
        </div>
      </motion.div>
    </div>
  </motion.div>

  );
};

const TIMEFRAMES = ['week', 'month', 'year'] as const;

export default function HabitTracker() {
  // --- State ---
  const [userName, setUserName] = useState(() => {
    return localStorage.getItem('habitTrackerUserName') || '';
  });
  const [isEditingName, setIsEditingName] = useState(() => {
    return !localStorage.getItem('habitTrackerUserName');
  });

  const [habits, setHabits] = useState<Habit[]>(() => {
    const saved = localStorage.getItem('habits');
    const parsed: Habit[] = saved ? JSON.parse(saved) : [];
    // Deduplicate by ID
    return Array.from(new Map(parsed.map(h => [h.id, h])).values());
  });
  
  const [completedHabits, setCompletedHabits] = useState<Habit[]>(() => {
    const saved = localStorage.getItem('completedHabits');
    const parsed: Habit[] = saved ? JSON.parse(saved) : [];
    // Deduplicate by ID
    return Array.from(new Map(parsed.map(h => [h.id, h])).values());
  });
  
  const [completions, setCompletions] = useState<Completions>(() => {
    const saved = localStorage.getItem('completions');
    return saved ? JSON.parse(saved) : {};
  });

  const [reflections, setReflections] = useState<Reflections>(() => {
    const saved = localStorage.getItem('reflections');
    return saved ? JSON.parse(saved) : {};
  });

  const [isAdding, setIsAdding] = useState(false);
  const [newHabitName, setNewHabitName] = useState('');
  const [newHabitColor, setNewHabitColor] = useState(COLORS[0]);
  const [newHabitTarget, setNewHabitTarget] = useState<number | string>('');
  const [newHabitCategory, setNewHabitCategory] = useState(HABIT_CATEGORIES[0].value);
  const [newHabitNotes, setNewHabitNotes] = useState('');
  
  const [editingHabitId, setEditingHabitId] = useState<string | null>(null);
  const [editHabitName, setEditHabitName] = useState('');
  const [editHabitColor, setEditHabitColor] = useState(COLORS[0]);
  const [editHabitTarget, setEditHabitTarget] = useState(30);
  
  const [habitToDelete, setHabitToDelete] = useState<string | null>(null);
  const [habitToReset, setHabitToReset] = useState<string | null>(null);
  const [habitToUndo, setHabitToUndo] = useState<string | null>(null);
  const [showClearConfirm, setShowClearConfirm] = useState(false);
  const [activeHabitSettings, setActiveHabitSettings] = useState<Habit | null>(null);
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);
  const [isTodoOpen, setIsTodoOpen] = useState(false);
  const [todos, setTodos] = useState<Todo[]>(() => {
    try {
      const saved = localStorage.getItem('todos');
      return saved ? JSON.parse(saved) : [];
    } catch {
      return [];
    }
  });
  const [totalActivityTimeframe, setTotalActivityTimeframe] = useState<'week' | 'month' | 'year'>('week');
  const [showCertificateFor, setShowCertificateFor] = useState<Habit | null>(null);
  const [showNav, setShowNav] = useState(true);
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const lastScrollY = useRef(0);
  
  // Settings state (stored locally)
  const [notificationsEnabled, setNotificationsEnabled] = useState<boolean>(() => {
    try {
      const saved = localStorage.getItem('notificationsEnabled');
      return saved !== null ? JSON.parse(saved) : true;
    } catch {
      return true;
    }
  });
  const [hapticsEnabled, setHapticsEnabled] = useState<boolean>(() => {
    try {
      const saved = localStorage.getItem('hapticsEnabled');
      return saved !== null ? JSON.parse(saved) : true;
    } catch {
      return true;
    }
  });
  
  const [activeRange, setActiveRange] = useState('M');
  const [viewEndDate, setViewEndDate] = useState<Date>(new Date());
  
  // Calendar state
  const [currentMonth, setCurrentMonth] = useState(new Date());

  // Quote state
  const [quote, setQuote] = useState<{text: string, author: string} | null>(null);

  const [activeTool, setActiveTool] = useState<'home' | 'progress' | 'badges' | 'completed'>('home');
  const [activeChunkIndex, setActiveChunkIndex] = useState(0);
  const [isGeneratingMotivation, setIsGeneratingMotivation] = useState(false);
  const [noteToEdit, setNoteToEdit] = useState<{ habitId: string; date: string; content: string } | null>(null);

  const motivationRef = useRef<HTMLDivElement>(null);

  const handleShareMotivationImage = async () => {
    if (!motivationRef.current || !quote) return;
    
    setIsGeneratingMotivation(true);
    try {
      const dataUrl = await toPng(motivationRef.current, {
        cacheBust: true,
        backgroundColor: '#000000',
        pixelRatio: 3, // Higher quality
        quality: 1,
        style: {
          borderRadius: '0',
          transform: 'none'
        },
        filter: (node) => {
          const el = node as HTMLElement;
          if (el.classList && el.classList.contains('hide-on-share')) return false;
          return true;
        }
      });

      const blob = await (await fetch(dataUrl)).blob();
      const file = new File([blob], `motivation-${new Date().toISOString().split('T')[0]}.png`, { type: 'image/png' });

      if (navigator.share && navigator.canShare && navigator.canShare({ files: [file] })) {
        await navigator.share({
          files: [file],
          title: 'Daily Motivation',
          text: `"${quote.text}" — ${quote.author}`,
        });
      } else {
        const link = document.createElement('a');
        link.download = `daily-motivation-${new Date().toISOString().split('T')[0]}.png`;
        link.href = dataUrl;
        link.click();
      }
    } catch (err) {
      console.error('Error generating or sharing motivation image:', err);
      // Fallback to text sharing
      if (navigator.share) {
        await navigator.share({
          title: 'Daily Motivation',
          text: `"${quote.text}" — ${quote.author}`,
          url: window.location.href
        });
      }
    } finally {
      setIsGeneratingMotivation(false);
    }
  };

  const saveReflection = (habitId: string, date: string, content: string) => {
    setReflections(prev => ({
      ...prev,
      [habitId]: {
        ...(prev[habitId] || {}),
        [date]: content
      }
    }));
    setNoteToEdit(null);
  };

  const carouselRef = useRef<HTMLDivElement>(null);
  const tabDragControls = useDragControls();

  const handleCarouselScroll = () => {
    if (carouselRef.current) {
      const scrollLeft = carouselRef.current.scrollLeft;
      const width = carouselRef.current.children[0] ? (carouselRef.current.children[0] as HTMLElement).offsetWidth + 32 : carouselRef.current.offsetWidth;
      const index = Math.round(scrollLeft / width);
      if (index !== activeChunkIndex) setActiveChunkIndex(index);
    }
  };
  const [direction, setDirection] = useState(0);
  const [dataLoaded, setDataLoaded] = useState(false);

  const handleToolChange = (newTool: 'home' | 'progress' | 'badges' | 'completed') => {
    const order: ('home' | 'progress' | 'badges' | 'completed')[] = ['home', 'progress', 'badges', 'completed'];
    const curIdx = order.indexOf(activeTool);
    const newIdx = order.indexOf(newTool);
    if (curIdx === newIdx) return;
    setDirection(newIdx > curIdx ? 1 : -1);
    setActiveTool(newTool);
  };

  // --- Effects ---
  // Ensure local storage is authoritative and primary store
  useEffect(() => {
    const initializeData = async () => {
      // Check if user already has data stored locally
      const hasLocalHabits = localStorage.getItem('habits') !== null;
      const hasLocalTodos = localStorage.getItem('todos') !== null;

      if (hasLocalHabits || hasLocalTodos) {
        // Local storage data exists: keep it authoritative!
        setDataLoaded(true);
        // Silently sync local state to server as background backup
        try {
          await fetch('/api/data', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              habits,
              completedHabits,
              completions,
              reflections,
              todos,
              userName
            }),
          });
        } catch {
          // Completely fine if offline: app is fully local
        }
        return;
      }

      // If local storage is completely empty, check if server has an existing backup
      try {
        const res = await fetch('/api/data');
        if (res.ok) {
          const data = await res.json();
          if (Array.isArray(data.habits) && data.habits.length > 0) setHabits(data.habits);
          if (Array.isArray(data.completedHabits) && data.completedHabits.length > 0) setCompletedHabits(data.completedHabits);
          if (data.completions && Object.keys(data.completions).length > 0) setCompletions(data.completions);
          if (data.userName) setUserName(data.userName);
          if (data.reflections && Object.keys(data.reflections).length > 0) setReflections(data.reflections);
          if (Array.isArray(data.todos) && data.todos.length > 0) setTodos(data.todos);
        }
      } catch (err) {
        console.warn('Running purely in local storage mode:', err);
      } finally {
        setDataLoaded(true);
      }
    };

    initializeData();
  }, []);

  // Save all state to localStorage immediately whenever anything changes
  useEffect(() => {
    try {
      localStorage.setItem('habits', JSON.stringify(habits));
      localStorage.setItem('completedHabits', JSON.stringify(completedHabits));
      localStorage.setItem('completions', JSON.stringify(completions));
      localStorage.setItem('reflections', JSON.stringify(reflections));
      localStorage.setItem('todos', JSON.stringify(todos));
      localStorage.setItem('habitTrackerUserName', userName);
      localStorage.setItem('notificationsEnabled', JSON.stringify(notificationsEnabled));
      localStorage.setItem('hapticsEnabled', JSON.stringify(hapticsEnabled));
    } catch (e) {
      console.warn('Failed to save to localStorage:', e);
    }
  }, [habits, completedHabits, completions, reflections, todos, userName, notificationsEnabled, hapticsEnabled]);

  // Background server sync without ever blocking or overwriting local storage
  useEffect(() => {
    if (!dataLoaded) return;

    const backupToServer = async () => {
      try {
        await fetch('/api/data', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            habits,
            completedHabits,
            completions,
            reflections,
            todos,
            userName
          }),
        });
      } catch {
        // Safe to ignore since data is permanently saved in localStorage
      }
    };

    const timeout = setTimeout(backupToServer, 400);
    return () => clearTimeout(timeout);
  }, [habits, completedHabits, completions, reflections, todos, userName, dataLoaded]);

  useEffect(() => {
    const handleScroll = () => {
      const currentScrollY = window.scrollY;
      
      // Only show when at the top of the page (within 20px)
      if (currentScrollY <= 20) {
        setShowNav(true);
      } else {
        setShowNav(false);
      }
      
      lastScrollY.current = currentScrollY;
    };

    window.addEventListener('scroll', handleScroll, { passive: true });
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  useEffect(() => {
    const fetchQuote = async () => {
      try {
        const today = new Date().toISOString().split('T')[0];
        const storedQuote = localStorage.getItem('dailyQuote');
        if (storedQuote) {
          const parsed = JSON.parse(storedQuote);
          if (parsed.date === today) {
            setQuote({ text: parsed.text, author: parsed.author });
            return;
          }
        }
        
        const res = await fetch('https://dummyjson.com/quotes/random');
        const data = await res.json();
        const newQuote = { text: data.quote, author: data.author };
        setQuote(newQuote);
        localStorage.setItem('dailyQuote', JSON.stringify({ ...newQuote, date: today }));
      } catch (err) {
        console.error("Failed to fetch quote", err);
        setQuote({ text: "Small daily improvements are the key to staggering long-term results.", author: "Unknown" });
      }
    };
    fetchQuote();
  }, []);

  // --- Derived Data ---
  const todayStr = useMemo(() => formatDate(new Date()), []);
  
  const getChartData = useCallback((habitId: string) => {
    const habitComps = completions[habitId] || [];
    const now = new Date();
    const sunday = new Date(now);
    sunday.setDate(now.getDate() - now.getDay());
    sunday.setHours(0, 0, 0, 0);

    const weekDays = [];
    for (let i = 0; i < 7; i++) {
      const d = new Date(sunday);
      d.setDate(sunday.getDate() + i);
      weekDays.push(d);
    }
    
    return weekDays.map(date => {
      const dateStr = formatDate(date);
      const completionStr = habitComps.find(c => c.startsWith(dateStr));
      let timingValue = 0;
      let tooltipValue = '';
      let isCompleted = false;
      
      if (completionStr) {
        isCompleted = true;
        const d = new Date(completionStr);
        timingValue = 24 - (d.getHours() + d.getMinutes() / 60);
        let hours = d.getHours();
        const ampm = hours >= 12 ? 'PM' : 'AM';
        hours = hours % 12;
        hours = hours ? hours : 12;
        const minutes = d.getMinutes().toString().padStart(2, '0');
        tooltipValue = `${hours}:${minutes} ${ampm}`;
      }

      return {
        label: date.toLocaleDateString('en-US', { weekday: 'narrow' }),
        value: timingValue,
        max: 24,
        isToday: dateStr === todayStr,
        isCompleted,
        tooltip: tooltipValue
      };
    });
  }, [completions, todayStr]);

  const totalChartData = useMemo(() => {
    const now = new Date();
    const sunday = new Date(now);
    sunday.setDate(now.getDate() - now.getDay());
    sunday.setHours(0, 0, 0, 0);

    const weekDays = [];
    for (let i = 0; i < 7; i++) {
      const d = new Date(sunday);
      d.setDate(sunday.getDate() + i);
      weekDays.push(d);
    }

    const allHabitIds = [...habits, ...completedHabits].map(h => h.id);
    const getSumForDate = (dateStr: string) => {
      return allHabitIds.reduce((sum, id) => sum + (isDateCompleted(completions[id] || [], dateStr) ? 1 : 0), 0);
    };

    return weekDays.map(date => {
      const dateStr = formatDate(date);
      return {
        label: date.toLocaleDateString('en-US', { weekday: 'narrow' }),
        value: getSumForDate(dateStr),
        max: (habits.length + completedHabits.length) || 1,
        isToday: dateStr === todayStr
      };
    });
  }, [habits, completedHabits, completions, todayStr]);

  const hourlyChartData = useMemo(() => {
    const hourlyDistribution = Array(24).fill(0);
    const allCompletions = Object.values(completions) as string[][];
    
    // Only look at last 7 days of data for the timing chart to keep it relevant
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    allCompletions.flat().forEach(isoStr => {
      const d = new Date(isoStr);
      if (d >= sevenDaysAgo) {
        const hour = d.getHours();
        hourlyDistribution[hour]++;
      }
    });
    
    return hourlyDistribution.map((count, hour) => ({
      hour: hour,
      label: `${hour % 12 === 0 ? 12 : hour % 12}${hour >= 12 ? 'PM' : 'AM'}`,
      value: count,
      max: Math.max(...hourlyDistribution, 1)
    }));
  }, [completions]);

  const peakHour = useMemo(() => {
    if (hourlyChartData.length === 0) return "N/A";
    const peak = hourlyChartData.reduce((prev, current) => (prev.value > current.value) ? prev : current, hourlyChartData[0]);
    return peak.value > 0 ? peak.label : "N/A";
  }, [hourlyChartData]);

  const averageStreak = useMemo(() => {
    const activeHabits = habits.filter(h => !h.completedAt);
    if (activeHabits.length === 0) return "0";
    return (activeHabits.reduce((acc, habit) => acc + calculateStreak(completions[habit.id] || [], habit.createdAt), 0) / activeHabits.length).toFixed(1);
  }, [habits, completions]);

  const activeHabits = useMemo(() => habits.filter(h => !h.completedAt), [habits]);

  const usedCategories = useMemo(() => {
    const cats = new Set(activeHabits.map(h => h.category || 'other'));
    return HABIT_CATEGORIES.filter(c => cats.has(c.value));
  }, [activeHabits]);

  useEffect(() => {
    if (selectedCategory !== 'all' && !usedCategories.find(c => c.value === selectedCategory)) {
      setSelectedCategory('all');
    }
  }, [usedCategories, selectedCategory]);

  const chunkedHabits = useMemo(() => {
    const chunks = [];
    const filteredActiveHabits = selectedCategory === 'all' 
      ? activeHabits 
      : activeHabits.filter(h => h.category === selectedCategory || (!h.category && selectedCategory === 'other'));
    
    for (let i = 0; i < filteredActiveHabits.length; i += 3) {
      chunks.push(filteredActiveHabits.slice(i, i + 3));
    }
    return chunks;
  }, [activeHabits, selectedCategory]);

  const stats = useMemo(() => {
    const totalCompletionsCount = Object.values(completions).flat().length;
    const totalPoints = totalCompletionsCount * 10;
    const allHabits = [...habits, ...completedHabits];
    const maxStreakPoints = allHabits.length > 0 ? Math.max(0, ...allHabits.map(h => calculateStreak(completions[h.id] || [], h.createdAt))) : 0;
    const maxStreakDays = allHabits.length > 0 ? Math.max(0, ...allHabits.map(h => getStreakCount(completions[h.id] || []))) : 0;
    
    return {
      totalCompletionsCount,
      totalPoints: totalPoints + maxStreakPoints,
      maxStreakDays,
      rank: totalPoints >= 1000 ? 'Master' : totalPoints >= 500 ? 'Expert' : totalPoints >= 100 ? 'Achiever' : 'Beginner'
    };
  }, [habits, completedHabits, completions]);

  const allCompletedHabits = useMemo(() => {
    const fromHabits = habits.filter(h => h.completedAt);
    const combined = [...fromHabits];
    completedHabits.forEach(ch => {
      if (!combined.find(h => h.id === ch.id)) {
        combined.push(ch);
      }
    });
    return combined;
  }, [habits, completedHabits]);

  const combinedBadges = useMemo(() => {
    const habitAchievements: any[] = [];
    [...habits, ...completedHabits].forEach(habit => {
      const count = completions[habit.id]?.length || 0;
      let highestTierIndex = -1;
      
      HABIT_MILESTONES.forEach((m, idx) => {
        if (count >= m.req) {
          highestTierIndex = Math.max(highestTierIndex, idx);
          habitAchievements.push({
            id: `habit_${habit.id}_${m.tier}`,
            name: `${m.tier} for ${habit.name}`,
            desc: `${m.req} completions`,
            icon: m.icon,
            req: m.req,
            type: 'habit_milestone',
            tier: m.tier,
            habitId: habit.id,
            habitColor: habit.color
          });
        }
      });

      // Special case: If habit is completed (reaches targetDays), but didn't reach Bronze (req: 3)
      // award a "Completion Bronze" badge
      if (habit.targetDays > 0 && count >= habit.targetDays && highestTierIndex === -1) {
        const m = HABIT_MILESTONES[0];
        habitAchievements.push({
          id: `habit_${habit.id}_completion_bronze`,
          name: `Bronze for ${habit.name}`,
          desc: `Completed target!`,
          icon: m.icon,
          req: habit.targetDays,
          type: 'habit_milestone',
          tier: m.tier,
          habitId: habit.id,
          habitColor: habit.color
        });
      }
    });
    return { global: GLOBAL_BADGES, individual: habitAchievements };
  }, [habits, completedHabits, completions]);

  const TIER_STYLES: Record<string, { color: string, border: string, bg: string, shadow: string, glow: string }> = useMemo(() => ({
    Bronze: { color: 'text-orange-500', border: 'border-orange-500/40', bg: 'bg-gradient-to-br from-orange-500/10 to-orange-900/5', shadow: 'shadow-[0_0_15px_rgba(249,115,22,0.1)]', glow: 'bg-orange-500/20' },
    Silver: { color: 'text-zinc-300', border: 'border-zinc-300/40', bg: 'bg-gradient-to-br from-zinc-300/10 to-zinc-600/5', shadow: 'shadow-[0_0_15px_rgba(212,212,216,0.1)]', glow: 'bg-zinc-300/20' },
    Gold: { color: 'text-yellow-500', border: 'border-yellow-500/40', bg: 'bg-gradient-to-br from-yellow-500/10 to-yellow-700/5', shadow: 'shadow-[0_0_15px_rgba(234,179,8,0.15)]', glow: 'bg-yellow-500/20' },
    Platinum: { color: 'text-zinc-100', border: 'border-white/40', bg: 'bg-gradient-to-br from-white/10 to-zinc-900/5', shadow: 'shadow-[0_0_15px_rgba(255,255,255,0.1)]', glow: 'bg-white/20' },
    Diamond: { color: 'text-cyan-400', border: 'border-cyan-400/40', bg: 'bg-gradient-to-br from-cyan-400/10 to-indigo-500/5', shadow: 'shadow-[0_0_20px_rgba(34,211,238,0.2)]', glow: 'bg-cyan-400/30' }
  }), []);

  const getHourlyChartDataWrapper = useCallback(() => {
    return hourlyChartData;
  }, [hourlyChartData]);

  const getPeakHourWrapper = useCallback(() => {
    return peakHour;
  }, [peakHour]);

  const totalTimingChartData = useMemo(() => {
    const now = new Date();
    const allHabitIds = [...habits, ...completedHabits].map(h => h.id);

    if (totalActivityTimeframe === 'week') {
      const sunday = new Date(now);
      sunday.setDate(now.getDate() - now.getDay());
      sunday.setHours(0, 0, 0, 0);

      const weekDays = [];
      for (let i = 0; i < 7; i++) {
        const d = new Date(sunday);
        d.setDate(sunday.getDate() + i);
        weekDays.push(d);
      }

      const getAvgTimeForDate = (dateStr: string) => {
        const times = allHabitIds
          .map(id => completions[id]?.find(c => c.startsWith(dateStr)))
          .filter(c => c != null)
          .map(c => {
            const d = new Date(c!);
            return 24 - (d.getHours() + d.getMinutes() / 60);
          });
        if (times.length === 0) return 0;
        return times.reduce((a, b) => a + b, 0) / times.length;
      };

      return weekDays.map(date => {
        const dateStr = formatDate(date);
        const avgTime = getAvgTimeForDate(dateStr);
        let tooltipValue = '';
        if (avgTime > 0) {
           let originalHours = 24 - avgTime;
           let hr = Math.floor(originalHours);
           let min = Math.round((originalHours - hr) * 60).toString().padStart(2, '0');
           const ampm = hr >= 12 ? 'PM' : 'AM';
           hr = hr % 12;
           hr = hr ? hr : 12;
           tooltipValue = `Avg: ${hr}:${min} ${ampm}`;
        }
        return {
          label: date.toLocaleDateString('en-US', { weekday: 'narrow' }),
          value: avgTime,
          max: 24,
          isToday: dateStr === todayStr,
          isCompleted: avgTime > 0,
          tooltip: tooltipValue
        };
      });
    } else if (totalActivityTimeframe === 'month') {
      const weeks = [3, 2, 1, 0];
      
      const getCountForWeekOffset = (weekOffset: number) => {
        let count = 0;
        
        const todayStart = new Date(now);
        todayStart.setHours(0, 0, 0, 0);

        allHabitIds.forEach(id => {
          if (!completions[id]) return;
          completions[id].forEach(c => {
            const d = new Date(c);
            const dStart = new Date(d);
            dStart.setHours(0, 0, 0, 0);
            
            const diffDays = Math.floor((todayStart.getTime() - dStart.getTime()) / (1000 * 60 * 60 * 24)); 
            
            if (diffDays >= weekOffset * 7 && diffDays < (weekOffset + 1) * 7) {
               count++;
            }
          });
        });
        return count;
      };

      const maxMonthlyVal = Math.max(10, allHabitIds.length * 7);

      return weeks.map((weekOffset, index) => {
        const count = getCountForWeekOffset(weekOffset);
        return {
          label: `W${index + 1}`,
          value: count,
          max: maxMonthlyVal,
          isToday: weekOffset === 0,
          isCompleted: count > 0,
          tooltip: `${count} Activities`
        };
      });
    } else {
      const months = [];
      const currentYear = now.getFullYear();
      for (let i = 0; i < 12; i++) {
        const d = new Date(currentYear, i, 1);
        months.push(d);
      }

      const getCountForMonth = (year: number, month: number) => {
        let count = 0;
        
        allHabitIds.forEach(id => {
          if (!completions[id]) return;
          completions[id].forEach(c => {
            const d = new Date(c);
            if (d.getFullYear() === year && d.getMonth() === month) {
               count++;
            }
          });
        });
        return count;
      };

      const maxYearlyVal = Math.max(20, allHabitIds.length * 31);

      return months.map(date => {
        const count = getCountForMonth(date.getFullYear(), date.getMonth());
        return {
          label: date.toLocaleDateString('en-US', { month: 'short' }).charAt(0),
          value: count,
          max: maxYearlyVal,
          isToday: date.getMonth() === now.getMonth() && date.getFullYear() === now.getFullYear(),
          isCompleted: count > 0,
          tooltip: `${count} Activities`
        };
      });
    }
  }, [habits, completedHabits, completions, todayStr, totalActivityTimeframe]);

  const getTotalChartDataWrapper = useCallback(() => {
    return totalTimingChartData;
  }, [totalTimingChartData]);

  // --- Handlers ---
  const handleAddOrEditHabit = (e: FormEvent) => {
    e.preventDefault();
    if (!newHabitName.trim()) return;

    if (editingHabitId) {
      setHabits(habits.map(h => 
        h.id === editingHabitId 
          ? { ...h, name: newHabitName.trim(), color: newHabitColor.value, targetDays: Number(newHabitTarget) || 0, category: newHabitCategory, notes: newHabitNotes.trim() }
          : h
      ));
    } else {
      const newHabit: Habit = {
        id: crypto.randomUUID(),
        name: newHabitName.trim(),
        color: newHabitColor.value,
        createdAt: new Date().toISOString(),
        targetDays: Number(newHabitTarget) || 0,
        category: newHabitCategory,
        notes: newHabitNotes.trim(),
      };
      setHabits([...habits, newHabit]);
      setCompletions({ ...completions, [newHabit.id]: [] });
    }

    setNewHabitName('');
    setNewHabitTarget('');
    setNewHabitCategory(HABIT_CATEGORIES[0].value);
    setNewHabitNotes('');
    setEditingHabitId(null);
    setIsAdding(false);
  };

  const openEditHabit = (habit: Habit) => {
    setEditingHabitId(habit.id);
    setNewHabitName(habit.name);
    setNewHabitTarget(habit.targetDays);
    setNewHabitColor(COLORS.find(c => c.value === habit.color) || COLORS[0]);
    setNewHabitCategory(habit.category || 'other');
    setNewHabitNotes(habit.notes || '');
    setActiveHabitSettings(null);
    setIsAdding(true);
  };

  const resetHabitProgress = (habitId: string) => {
    setHabitToReset(habitId);
  };

  const confirmResetProgress = () => {
    if (habitToReset) {
      setCompletions({ ...completions, [habitToReset]: [] });
      setHabits(habits.map(h => h.id === habitToReset ? { ...h, createdAt: new Date().toISOString() } : h));
      setActiveHabitSettings(null);
      setHabitToReset(null);
    }
  };

  const confirmUndo = () => {
    if (habitToUndo) {
      toggleCompletion(habitToUndo, formatDate(new Date()));
      setHabitToUndo(null);
    }
  };

  const clearAllData = () => {
    setShowClearConfirm(true);
  };

  const confirmClearAllData = async () => {
    // 1. Wipe all local storage immediately
    localStorage.clear();
    
    // 2. Wipe server data
    try {
      await fetch('/api/data', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          habits: [],
          completedHabits: [],
          completions: {},
          reflections: {},
          userName: ''
        }),
      });
    } catch (err) {
      console.error('Failed to clear server data:', err);
    }

    // 3. Clear all React states to update UI instantly
    setHabits([]);
    setCompletedHabits([]);
    setCompletions({});
    setReflections({});
    setUserName('');
    setIsEditingName(true);
    setActiveTool('home');
    setIsSettingsOpen(false);
    setShowCertificateFor(null);
    setNotificationsEnabled(true);
    setHapticsEnabled(true);
    setShowClearConfirm(false);
    
    // 3. Force a reload to ensure all derived data and effects are completely neutralized
    window.location.reload();
  };

  const exportData = () => {
    const data = JSON.stringify({
      habits,
      completedHabits,
      completions,
      reflections,
      todos,
      userName,
      notificationsEnabled,
      hapticsEnabled,
      exportedAt: new Date().toISOString()
    }, null, 2);
    const blob = new Blob([data], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `atomic-habits-backup-${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const importData = (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (event) => {
      try {
        const text = event.target?.result as string;
        const data = JSON.parse(text);
        if (Array.isArray(data.habits)) {
          setHabits(data.habits);
          localStorage.setItem('habits', JSON.stringify(data.habits));
        }
        if (Array.isArray(data.completedHabits)) {
          setCompletedHabits(data.completedHabits);
          localStorage.setItem('completedHabits', JSON.stringify(data.completedHabits));
        }
        if (data.completions && typeof data.completions === 'object') {
          setCompletions(data.completions);
          localStorage.setItem('completions', JSON.stringify(data.completions));
        }
        if (data.reflections && typeof data.reflections === 'object') {
          setReflections(data.reflections);
          localStorage.setItem('reflections', JSON.stringify(data.reflections));
        }
        if (Array.isArray(data.todos)) {
          setTodos(data.todos);
          localStorage.setItem('todos', JSON.stringify(data.todos));
        }
        if (typeof data.userName === 'string') {
          setUserName(data.userName);
          localStorage.setItem('habitTrackerUserName', data.userName);
        }
        if (typeof data.notificationsEnabled === 'boolean') {
          setNotificationsEnabled(data.notificationsEnabled);
          localStorage.setItem('notificationsEnabled', JSON.stringify(data.notificationsEnabled));
        }
        if (typeof data.hapticsEnabled === 'boolean') {
          setHapticsEnabled(data.hapticsEnabled);
          localStorage.setItem('hapticsEnabled', JSON.stringify(data.hapticsEnabled));
        }
      } catch (err) {
        console.error('Failed to parse the backup file:', err);
      }
    };
    reader.readAsText(file);
  };

  const toggleCompletion = (habitId: string, dateStr: string) => {
    const habit = habits.find(h => h.id === habitId);
    if (!habit) return;
    
    // Strictly enforce that only the actual current day can be toggled.
    // This prevents backdating if the app is left open overnight.
    const actualTodayStr = formatDate(new Date());
    if (dateStr !== actualTodayStr) {
      return;
    }
    
    setCompletions(prev => {
      const habitCompletions = prev[habitId] || [];
      const currentStreak = calculateStreak(habitCompletions, habit.createdAt);
      
      // If the habit is locked (negative streak) and they are trying to check it off, prevent it.
      if (currentStreak < 0 && !isDateCompleted(habitCompletions, dateStr)) {
        return prev;
      }

      if (isDateCompleted(habitCompletions, dateStr)) {
        return { ...prev, [habitId]: habitCompletions.filter(d => !d.startsWith(dateStr)) };
      } else {
        const newCompletions = [...habitCompletions, new Date().toISOString()];
        
        // Trigger confetti when completing the final day of the goal
        if (habit && habit.targetDays > 0 && newCompletions.length === habit.targetDays) {
          confetti({
            particleCount: 150,
            spread: 100,
            origin: { y: 0.6 },
            colors: ['#fa114f', '#92ff00', '#00f2ff', '#bf5af2', '#0a84ff', '#5e5ce6']
          });
          
          // Show certificate
          setShowCertificateFor({ ...habit, completedAt: new Date().toISOString() });
          
          // Move to completedHabits once reached target
          setHabits(currentHabits => currentHabits.filter(h => h.id !== habitId));
          setCompletedHabits(prev => {
            if (prev.find(h => h.id === habitId)) return prev;
            return [...prev, { ...habit, completedAt: new Date().toISOString() }];
          });
        }
        
        return { ...prev, [habitId]: newCompletions };
      }
    });
  };

  const nextMonth = () => {
    setCurrentMonth(prev => new Date(prev.getFullYear(), prev.getMonth() + 1, 1));
  };

  const prevMonth = () => {
    setCurrentMonth(prev => new Date(prev.getFullYear(), prev.getMonth() - 1, 1));
  };

  const deleteHabit = (habitId: string) => {
    setHabitToDelete(habitId);
  };

  const confirmDelete = () => {
    if (habitToDelete) {
      setHabits(habits.filter(h => h.id !== habitToDelete));
      setCompletedHabits(prev => prev.filter(h => h.id !== habitToDelete));
      const newCompletions = { ...completions };
      delete newCompletions[habitToDelete];
      setCompletions(newCompletions);
      setHabitToDelete(null);
    }
  };

  const TABS = ['home', 'progress', 'badges', 'completed'] as const;
  
  const [touchStartX, setTouchStartX] = useState<number | null>(null);
  const [touchEndX, setTouchEndX] = useState<number | null>(null);
  const [touchStartY, setTouchStartY] = useState<number | null>(null);
  const [touchEndY, setTouchEndY] = useState<number | null>(null);

  const minSwipeDistance = 50;

  const handleTouchStart = (e: React.TouchEvent<HTMLDivElement>) => {
    setTouchEndX(null);
    setTouchEndY(null);
    setTouchStartX(e.targetTouches[0].clientX);
    setTouchStartY(e.targetTouches[0].clientY);
  }

  const handleTouchMove = (e: React.TouchEvent<HTMLDivElement>) => {
    setTouchEndX(e.targetTouches[0].clientX);
    setTouchEndY(e.targetTouches[0].clientY);
  }

  const handleTouchEnd = () => {
    if (!touchStartX || !touchEndX || !touchStartY || !touchEndY) return;
    const distanceX = touchStartX - touchEndX;
    const distanceY = touchStartY - touchEndY;
    const isLeftSwipe = distanceX > minSwipeDistance;
    const isRightSwipe = distanceX < -minSwipeDistance;
    const isSwipeDown = distanceY < -minSwipeDistance;
    
    // Ensure it's mostly a horizontal swipe, not vertical scrolling
    if (Math.abs(distanceX) > Math.abs(distanceY) && (isLeftSwipe || isRightSwipe)) {
      const currentIndex = TABS.indexOf(activeTool as any);
      if (isLeftSwipe && currentIndex < TABS.length - 1) {
        handleToolChange(TABS[currentIndex + 1]);
      }
      if (isRightSwipe && currentIndex > 0) {
        handleToolChange(TABS[currentIndex - 1]);
      }
    }
  }

  return (
    <div 
      className="min-h-[100dvh] w-full max-w-2xl overflow-x-hidden text-app-text font-sans pt-28 pb-32 mx-auto selection:bg-[#0a84ff]/30 no-scrollbar relative"
      onTouchStart={handleTouchStart}
      onTouchMove={handleTouchMove}
      onTouchEnd={handleTouchEnd}
    >
      {/* Header Navigation */}
      {!isSettingsOpen && !activeHabitSettings && !isAdding && (
        <motion.div 
          initial={false}
          animate={{
            backgroundColor: showNav ? 'rgba(0, 0, 0, 0.8)' : 'rgba(0, 0, 0, 0)',
            backdropFilter: showNav ? 'blur(12px)' : 'blur(0px)',
          }}
          transition={{ duration: 0.15 }}
          className="px-6 pt-8 pb-4 fixed top-0 left-0 right-0 z-40"
          style={{ pointerEvents: showNav ? 'auto' : 'none' }}
        >
          <motion.div className="flex items-center justify-between h-11 pointer-events-auto max-w-2xl mx-auto">
            <AnimatePresence>
              {showNav && (
                <motion.h1 
                  key="header-title"
                  initial={{ opacity: 0, x: -10, filter: 'blur(8px)' }}
                  animate={{ opacity: 1, x: 0, filter: 'blur(0px)' }}
                  exit={{ opacity: 0, x: -10, filter: 'blur(8px)' }}
                  transition={{ type: 'spring', bounce: 0, duration: 0.15 }}
                  className="text-3xl font-bold tracking-tight text-white whitespace-nowrap"
                >
                  Atomic Habits
                </motion.h1>
              )}
            </AnimatePresence>
            
            <div className="flex-1" />

            <div className="flex items-center gap-2">
              <motion.button 
                whileTap={{ scale: 0.9 }}
                onClick={() => setIsAdding(true)}
                className="w-11 h-11 rounded-full glass-panel flex items-center justify-center text-[#0a84ff] hover:bg-app-card-secondary transition-colors active:scale-90 shadow-lg z-10"
              >
                <Plus size={22} strokeWidth={2.5} />
              </motion.button>
              
              <AnimatePresence>
                {showNav && (
                  <motion.button 
                    key="header-settings"
                    initial={{ opacity: 0, scale: 0.8, x: 10, width: 0 }}
                    animate={{ opacity: 1, scale: 1, x: 0, width: 44 }}
                    exit={{ opacity: 0, scale: 0.8, x: 10, width: 0 }}
                    transition={{ type: 'spring', bounce: 0, duration: 0.15 }}
                    onClick={() => setIsSettingsOpen(true)}
                    className="h-11 rounded-full glass-panel flex items-center justify-center text-zinc-400 hover:text-app-text transition-colors active:scale-90 shadow-lg shrink-0 overflow-hidden"
                  >
                    <div className="w-11 h-11 flex items-center justify-center">
                      <Settings size={22} />
                    </div>
                  </motion.button>
                )}
              </AnimatePresence>
            </div>
          </motion.div>
        </motion.div>
      )}

      <AnimatePresence mode="popLayout" custom={direction} initial={false}>
        {activeTool === 'home' ? (
          <motion.div
            key="home"
            custom={direction}
            initial={{ opacity: 0, x: direction > 0 ? 50 : -50, filter: 'blur(10px)' }}
            animate={{ opacity: 1, x: 0, filter: 'blur(0px)' }}
            exit={{ opacity: 0, x: direction > 0 ? -50 : 50, filter: 'blur(10px)' }}
            transition={{ type: 'spring', damping: 28, stiffness: 220, mass: 0.8 }}
            className="w-full"
          >
            <div className="px-6 mb-6 mt-4">
              {/* User Greeting */}
              <motion.div 
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.2, delay: 0.05 }}
                className="mb-8"
              >
                {isEditingName ? (
                  <input
                    type="text"
                    value={userName}
                    onChange={(e) => setUserName(e.target.value)}
                    onBlur={() => {
                      if (userName.trim()) setIsEditingName(false);
                    }}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter' && userName.trim()) setIsEditingName(false);
                    }}
                    autoFocus
                    className="text-3xl font-bold bg-transparent border-b-2 border-[#0a84ff] outline-none text-app-text w-full pb-1 placeholder:text-zinc-600"
                    placeholder="What's your name?"
                  />
                ) : (
                  <h1 
                    onClick={() => setIsEditingName(true)}
                    className="text-3xl font-bold tracking-tight cursor-pointer hover:opacity-80 transition-opacity"
                  >
                    <Typewriter text={userName ? `Hello, ${userName}` : 'Hello! Tap to add name'} />
                  </h1>
                )}
                <p className="text-sm text-app-text-muted mt-1">Ready to crush your goals today?</p>
              </motion.div>

              {/* Rings and Main Stats */}
              <div 
                ref={carouselRef}
                onScroll={handleCarouselScroll}
                className="flex overflow-x-auto snap-x snap-mandatory no-scrollbar gap-8 mb-4 pb-4 relative"
                onTouchStart={(e) => e.stopPropagation()}
                onTouchMove={(e) => e.stopPropagation()}
                onTouchEnd={(e) => e.stopPropagation()}
              >
                {chunkedHabits.length === 0 ? (
                  <div className="flex items-center gap-4 sm:gap-8 min-w-full shrink-0 snap-center">
                    <ActivityRings habits={[]} completions={completions} />
                    <div className="flex-1 flex items-center justify-center text-zinc-500 text-[10px] font-bold uppercase tracking-widest opacity-30 pointer-events-none">
                      No habits yet
                    </div>
                  </div>
                ) : (
                  chunkedHabits.map((chunk, chunkIndex) => (
                    <motion.div 
                      layout 
                      key={chunkIndex} 
                      whileTap={{ scale: 0.98 }}
                      className="flex items-center gap-4 sm:gap-8 min-w-full max-w-full shrink-0 snap-center justify-between"
                    >
                      <div className="shrink-0 flex items-center justify-center sm:ml-0">
                        <ActivityRings habits={chunk} completions={completions} />
                      </div>
                      <div className="flex-1 min-w-0 flex flex-col justify-center space-y-3 sm:space-y-4 pl-2">
                        {chunk.map((habit, i) => {
                          const cObj = COLORS.find(c => c.value === habit.color) || COLORS[i % COLORS.length];
                          const habitComps = completions[habit.id] || [];
                          const streak = getStreakCount(habitComps);
                          return (
                            <motion.div 
                              layout 
                              key={`stat-${habit.id}`} 
                              initial={{ opacity: 0, x: -10 }}
                              animate={{ opacity: 1, x: 0 }}
                              transition={{ duration: 0.15, delay: i * 0.02 }}
                              className="flex flex-col min-w-0"
                            >
                              <div className="flex flex-col min-w-0">
                                <div className={`${cObj.text} text-[11px] font-bold uppercase tracking-tight flex items-center gap-1 w-full min-w-0`}>
                                  <div className="truncate flex-1 min-w-0"><Typewriter text={habit.name} delay={i * 0.2 + 0.3} /></div>
                                  {habit.completedAt && <Trophy size={10} className="text-yellow-500 fill-current shrink-0" />}
                                </div>
                                {habit.category && habit.category !== 'other' && (() => {
                                  const cat = HABIT_CATEGORIES.find(c => c.value === habit.category);
                                  const Icon = cat?.icon;
                                  return (
                                    <div className="flex items-center gap-1 text-[8px] font-medium text-zinc-500 uppercase tracking-widest mt-0.5 ml-0">
                                      {Icon && <Icon size={8} />}
                                      <span>{cat?.label}</span>
                                    </div>
                                  );
                                })()}
                              </div>
                            </motion.div>
                          );
                        })}
                      </div>
                    </motion.div>
                  ))
                )}
              </div>

              {/* Category Filter */}
              {activeHabits.length > 0 && usedCategories.length > 0 && (
                <div 
                  className="flex overflow-x-auto gap-3 no-scrollbar mb-6 snap-x"
                  onTouchStart={(e) => e.stopPropagation()}
                  onTouchMove={(e) => e.stopPropagation()}
                  onTouchEnd={(e) => e.stopPropagation()}
                >
                  <button
                    onClick={() => setSelectedCategory('all')}
                    className={`px-4 py-2 rounded-full whitespace-nowrap text-sm font-medium transition-all shadow-sm snap-start shrink-0 pointer-events-auto touch-manipulation z-50 ${selectedCategory === 'all' ? 'bg-[#0a84ff] text-white' : 'glass-panel text-zinc-400 hover:text-white border border-app-border'}`}
                  >
                    All Habits
                  </button>
                  {usedCategories.map(cat => (
                    <button
                      key={cat.value}
                      onClick={() => setSelectedCategory(cat.value)}
                      className={`px-4 py-2 rounded-full whitespace-nowrap text-sm font-medium transition-all shadow-sm snap-start shrink-0 pointer-events-auto touch-manipulation z-50 flex items-center gap-2 ${selectedCategory === cat.value ? 'bg-[#0a84ff] text-white' : 'glass-panel text-zinc-400 hover:text-white border border-app-border'}`}
                    >
                      <cat.icon size={16} />
                      {cat.label}
                    </button>
                  ))}
                </div>
              )}
            </div>

      <div className="px-6 space-y-6 mb-12">
        {/* Daily Motivation */}
        <motion.div 
          whileTap={{ scale: 0.98 }}
          ref={motivationRef}
          className="glass-card rounded-2xl p-5 relative overflow-hidden bg-black"
        >
          <div className="absolute top-0 right-0 w-32 h-32 bg-[#0a84ff]/10 rounded-full blur-3xl -mr-10 -mt-10 pointer-events-none" />
          <div className="space-y-3 relative z-10">
            <div className="flex justify-between items-start hide-on-share">
              <div className="flex items-center gap-2 text-[#0a84ff]">
                <Activity size={16} strokeWidth={3} />
                <span className="text-xs font-bold uppercase tracking-wider">Daily Motivation</span>
              </div>
              {quote && (
                <button 
                  onClick={handleShareMotivationImage}
                  disabled={isGeneratingMotivation}
                  className="w-8 h-8 rounded-full bg-[#0a84ff]/10 flex items-center justify-center text-[#0a84ff] hover:bg-[#0a84ff]/20 transition-all disabled:opacity-50"
                  title="Share Motivation as Picture"
                >
                  {isGeneratingMotivation ? (
                    <Loader2 size={14} className="animate-spin" />
                  ) : (
                    <Share2 size={14} strokeWidth={3} />
                  )}
                </button>
              )}
            </div>
            {quote ? (
              <>
                <p className="text-lg font-medium leading-snug text-app-text/90 italic">
                  <Typewriter text={quote.text} delay={0.6} />
                </p>
                <p className="text-[10px] text-zinc-500 font-bold mt-2 uppercase tracking-widest">— {quote.author}</p>
              </>
            ) : (
              <div className="animate-pulse space-y-2 py-1">
                <div className="h-4 bg-app-text/10 rounded w-3/4"></div>
                <div className="h-4 bg-app-text/10 rounded w-1/2"></div>
              </div>
            )}
          </div>
        </motion.div>

        {/* Today's Check-in Summary */}
        <motion.div 
          whileTap={{ scale: 0.98 }}
          className="glass-card rounded-3xl p-6"
        >
          <div className="flex justify-between items-start mb-6">
            <h2 className="text-2xl font-bold tracking-tight mt-1">Today's Goals</h2>
            <div className="flex flex-col items-end gap-2">
              <div className="flex items-center gap-1.5 glass-panel px-3 py-1.5 rounded-xl border border-app-border">
                <Flame size={14} className="text-[#ff9500]" />
                <span className="text-sm font-bold text-app-text">{averageStreak}</span>
                <span className="text-[10px] text-app-text-muted font-medium uppercase tracking-wider">Avg Streak</span>
              </div>
              <p className="text-sm text-app-text-muted pr-1">
                {habits.filter(h => isDateCompleted(completions[h.id] || [], todayStr)).length} of {habits.length} completed
              </p>
            </div>
          </div>
        </motion.div>

        {/* Weekly Activity Summary (Home Screen) */}
        <div className="glass-card rounded-3xl p-6 space-y-4">
          <div className="flex justify-between items-center">
            <h3 className="text-sm font-bold text-app-text-muted uppercase tracking-widest">Weekly Activity</h3>
            <span className="text-[10px] text-app-text-muted font-bold uppercase tracking-widest">Last 7 Days</span>
          </div>
          <div className="h-20 flex items-end gap-2 pt-2">
            {totalChartData.map((data, i) => {
              const height = (data.value / data.max) * 100;
              return (
                <div key={i} className="flex-1 relative h-full flex flex-col items-center justify-end gap-2">
                  <motion.div 
                    initial={{ height: 0 }}
                    animate={{ height: `${Math.max(height, 10)}%` }}
                    transition={{ type: "spring", bounce: 0.2, duration: 0.2, delay: i * 0.02 }}
                    className={`w-full rounded-t-[4px] transition-all ${
                      data.value > 0 ? 'bg-[#30d158]' : 'bg-app-card-secondary/60 backdrop-blur-md'
                    } ${data.isToday ? 'ring-1 ring-app-text/40' : ''}`}
                  />
                  <span className={`text-[9px] font-bold ${data.isToday ? 'text-app-text' : 'text-app-text-muted'}`}>
                    {data.label}
                  </span>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Empty space placeholder replaced by merged component */}
          </motion.div>
        ) : activeTool === 'badges' ? (
          <motion.div
            key="badges"
            custom={direction}
            initial={{ opacity: 0, x: direction > 0 ? 50 : -50, filter: 'blur(10px)' }}
            animate={{ opacity: 1, x: 0, filter: 'blur(0px)' }}
            exit={{ opacity: 0, x: direction > 0 ? -50 : 50, filter: 'blur(10px)' }}
            transition={{ type: 'spring', damping: 28, stiffness: 220, mass: 0.8 }}
            className="px-6 space-y-12 pb-32"
          >
            {/* Gamification Section */}
            <div className="space-y-6">
              {/* Points Card */}
              <motion.div 
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: 0.05 }}
                whileTap={{ scale: 0.98 }}
                className="glass-card rounded-3xl p-6 relative overflow-hidden group"
              >
                <div className="absolute top-0 right-0 w-32 h-32 bg-[#ffcc00]/10 rounded-full blur-3xl -mr-10 -mt-10 pointer-events-none" />
                <div className="flex justify-between items-center relative z-10">
                  <div className="space-y-1">
                    <h3 className="text-sm font-bold text-app-text-muted uppercase tracking-widest">Total Points</h3>
                    <div className="text-3xl font-bold text-[#ffcc00] flex items-center gap-2">
                      <Target size={24} />
                      {stats.totalPoints}
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-[10px] text-zinc-500 uppercase font-bold tracking-widest">Rank</div>
                    <div className="text-sm font-bold text-white tracking-tight">
                      {stats.rank}
                    </div>
                  </div>
                </div>
              </motion.div>

              {/* Badges Grid */}
              <div className="space-y-3">
                <h3 className="text-xs font-bold text-app-text-muted uppercase tracking-widest px-2">Global Achievements</h3>
                <div className="grid grid-cols-3 gap-3">
                  {combinedBadges.global.map(badge => {
                    const unlocked = badge.type === 'streak' 
                      ? stats.maxStreakDays >= badge.req 
                      : stats.totalCompletionsCount >= badge.req;
                    
                    const progress = badge.type === 'streak'
                      ? Math.min(1, stats.maxStreakDays / badge.req)
                      : Math.min(1, stats.totalCompletionsCount / badge.req);

                    const style = TIER_STYLES[badge.tier as keyof typeof TIER_STYLES];
                    
                    return (
                      <div 
                        key={badge.id}
                        className={`glass-card rounded-2xl p-4 flex flex-col items-center gap-2 relative overflow-hidden transition-all duration-100 ${
                          unlocked 
                            ? `${style.border} ${style.bg} ${style.shadow} scale-[1.02]` 
                            : 'opacity-40 grayscale blur-[0.5px]'
                        }`}
                      >
                        {unlocked && (
                          <div className={`absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-20 h-20 ${style.glow} rounded-full blur-2xl -z-10`} />
                        )}
                        <div className={`${unlocked ? style.color : 'text-zinc-500'} transition-colors duration-100`}>
                          {badge.icon}
                        </div>
                        <div className="text-center space-y-0.5">
                          <div className="text-[10px] font-bold text-white whitespace-nowrap">{badge.name}</div>
                          <div className={`text-[8px] font-bold uppercase tracking-widest ${unlocked ? style.color : 'text-zinc-600'}`}>
                            {badge.tier}
                          </div>
                          <div className="text-[7px] font-medium text-zinc-500 uppercase tracking-wider">{badge.desc}</div>
                        </div>
                        {!unlocked && (
                          <div className="w-full h-1 bg-zinc-800/50 rounded-full mt-1 overflow-hidden">
                            <motion.div 
                              initial={{ width: 0 }}
                              animate={{ width: `${progress * 100}%` }}
                              className="h-full bg-zinc-600 rounded-full" 
                            />
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* Individual Habit Badges */}
              {combinedBadges.individual.length > 0 && (
                <div className="space-y-4">
                  <h3 className="text-xs font-bold text-app-text-muted uppercase tracking-widest px-2">Individual Badges</h3>
                  <div className="grid grid-cols-2 gap-3">
                    {combinedBadges.individual.map(badge => {
                      const style = TIER_STYLES[badge.tier as keyof typeof TIER_STYLES];
                      const habitColor = COLORS.find(c => c.value === badge.habitColor) || COLORS[0];
                      
                      return (
                        <div 
                          key={badge.id}
                          className={`glass-card rounded-2xl p-4 flex flex-col items-center gap-2 relative overflow-hidden border ${habitColor.border}/40 ${habitColor.bg}/10 ${style.shadow}`}
                        >
                          <div className={`absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-16 h-16 ${style.glow} rounded-full blur-2xl -z-10`} />
                          <div className={`${style.color} relative`}>
                            {badge.icon}
                          </div>
                          <div className="text-center space-y-0.5">
                            <div className="text-[11px] font-bold text-white line-clamp-1">{badge.name}</div>
                            <div className={`text-[8px] font-black uppercase tracking-widest ${style.color}`}>
                              {badge.tier}
                            </div>
                            <div className="text-[7px] text-zinc-500 font-medium">{badge.desc}</div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* Completed Habits Hall of Fame */}
              {allCompletedHabits.length > 0 && (
                <div className="space-y-4">
                  <h3 className="text-xs font-bold text-app-text-muted uppercase tracking-widest px-2">Hall of Fame</h3>
                  <div className="grid grid-cols-1 gap-3">
                    {allCompletedHabits.map(habit => {
                      const habitColor = COLORS.find(c => c.value === habit.color) || COLORS[0];
                      const totalComps = (completions[habit.id] || []).length;
                      const milestone = [...HABIT_MILESTONES].reverse().find(m => totalComps >= m.req) || (habit.completedAt || (habit.targetDays > 0 && totalComps >= habit.targetDays) ? HABIT_MILESTONES[0] : null);
                      const style = milestone ? TIER_STYLES[milestone.tier as keyof typeof TIER_STYLES] : null;
                      
                      return (
                        <div 
                          key={`completed-${habit.id}`}
                          className={`glass-card rounded-2xl p-4 flex items-center justify-between relative overflow-hidden group transition-all duration-150 border ${
                            style 
                              ? `${style.border} ${style.bg} ${style.shadow}` 
                              : `${habitColor.border}/30 ${habitColor.bg}/5`
                          }`}
                        >
                          <div className="flex items-center gap-4 relative z-10">
                            <div className={`w-12 h-12 rounded-2xl ${
                              style ? 'bg-black/20' : habitColor.bg
                            } flex items-center justify-center ${style ? style.color : 'text-black'} shadow-xl rotate-3 group-hover:rotate-0 transition-transform duration-150`}>
                              {milestone ? React.cloneElement(milestone.icon as React.ReactElement, { size: 24 }) : <Award size={24} />}
                            </div>
                            <div className="flex flex-col">
                              <span className="font-bold text-base tracking-tight text-white">{habit.name}</span>
                              <div className="flex items-center gap-2">
                                <span className={`text-[9px] font-bold uppercase tracking-widest ${style ? style.color : 'text-zinc-500'}`}>
                                  {milestone ? milestone.tier : 'Initiate'} Master
                                </span>
                                <span className="w-1 h-1 rounded-full bg-zinc-700" />
                                <span className="text-[9px] text-zinc-500 font-bold uppercase">
                                  {habit.completedAt ? new Date(habit.completedAt).toLocaleDateString() : 'Archived'}
                                </span>
                              </div>
                            </div>
                          </div>

                          <div className="text-right relative z-10">
                            <div className={`text-xl font-black ${style ? 'text-white' : 'text-zinc-400'}`}>{totalComps}</div>
                            <div className="text-[8px] text-zinc-500 font-bold uppercase tracking-widest">Total Sprints</div>
                          </div>

                          {/* Decorative tier icon in background */}
                          {milestone && (
                            <div className={`absolute -right-4 -top-4 opacity-5 ${style.color} rotate-12 scale-[2.5] pointer-events-none group-hover:scale-150 transition-transform duration-100`}>
                              {milestone.icon}
                            </div>
                          )}
                          
                          {/* Background Glow */}
                          {style && (
                            <div className={`absolute -left-10 -top-10 w-32 h-32 ${style.glow} rounded-full blur-3xl opacity-20 pointer-events-none`} />
                          )}
                          
                          {/* Shine Effect */}
                          <div className="absolute inset-0 bg-gradient-to-tr from-transparent via-white/5 to-transparent -translate-x-full group-hover:translate-x-full transition-transform duration-100 ease-in-out pointer-events-none" />
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* Individual Habit Progress Tracking */}
              {activeHabits.length > 0 && (
                <div className="space-y-4">
                  <h3 className="text-xs font-bold text-app-text-muted uppercase tracking-widest px-2">Next Milestones</h3>
                  <div className="grid grid-cols-1 gap-3">
                    {activeHabits.map((habit, i) => {
                      const count = completions[habit.id]?.length || 0;
                      const habitColor = COLORS.find(c => c.value === habit.color) || COLORS[0];
                      const currentMilestone = [...HABIT_MILESTONES].reverse().find(m => count >= m.req) || (habit.completedAt || (habit.targetDays > 0 && count >= habit.targetDays) ? HABIT_MILESTONES[0] : null);
                      const style = currentMilestone ? TIER_STYLES[currentMilestone.tier as keyof typeof TIER_STYLES] : null;
                      
                      const nextMilestone = HABIT_MILESTONES.find(m => m.req > count) || HABIT_MILESTONES[HABIT_MILESTONES.length - 1];
                      const prevMilestoneReq = currentMilestone ? currentMilestone.req : 0;
                      const progress = Math.min(1, (count - prevMilestoneReq) / (nextMilestone.req - prevMilestoneReq));
                      const isMaxed = count >= HABIT_MILESTONES[HABIT_MILESTONES.length - 1].req;
                      const icon = currentMilestone ? currentMilestone.icon : <Flame size={18} />;
                      
                      return (
                        <motion.div 
                          key={`track-${habit.id}`} 
                          initial={{ opacity: 0, scale: 0.9 }}
                          animate={{ opacity: 1, scale: 1 }}
                          transition={{ delay: i * 0.02 }}
                          whileTap={{ scale: 0.98 }}
                          className={`glass-card rounded-2xl p-4 space-y-3 relative overflow-hidden group transition-all duration-150 border ${
                            style 
                              ? `${style.border} ${style.bg} ${style.shadow}` 
                              : `${habitColor.border}/40 ${habitColor.bg}/10`
                          }`}
                        >
                          <div className="flex justify-between items-center relative z-10">
                            <div className="flex items-center gap-3">
                              <div className={`w-9 h-9 rounded-xl ${
                                style ? 'bg-black/20' : habitColor.bg
                              } flex items-center justify-center ${style ? style.color : 'text-black'} shadow-lg transition-colors`}>
                                {React.cloneElement(icon as React.ReactElement, { size: 18 })}
                              </div>
                              <div className="flex flex-col">
                                <span className="font-bold text-sm tracking-tight text-white">{habit.name}</span>
                                <span className={`text-[10px] font-bold uppercase tracking-tighter ${style ? style.color : 'text-zinc-500'}`}>
                                  {isMaxed 
                                    ? `Ultimate ${HABIT_MILESTONES[HABIT_MILESTONES.length-1].tier} Achieved!` 
                                    : `${nextMilestone.req - count} more to ${nextMilestone.tier}`}
                                </span>
                              </div>
                            </div>
                            <div className="text-right">
                              <span className={`text-xl font-black ${style ? 'text-white' : 'text-zinc-400'}`}>{count}</span>
                              <span className="text-[9px] block text-zinc-500 font-bold uppercase tracking-widest">Total</span>
                            </div>
                          </div>
                          
                          {!isMaxed && (
                            <div className="relative z-10 pt-1">
                              <div className="w-full h-1.5 bg-black/20 rounded-full overflow-hidden">
                                <motion.div 
                                  initial={{ width: 0 }}
                                  animate={{ width: `${progress * 100}%` }}
                                  className={`h-full ${style ? 'bg-current' : habitColor.bg} ${style ? style.color : ''} rounded-full`}
                                />
                              </div>
                            </div>
                          )}
                          
                          {/* Background Glow for achieved tier */}
                          {style && (
                            <div className={`absolute -right-4 -top-4 w-24 h-24 ${style.glow} rounded-full blur-3xl opacity-30 pointer-events-none`} />
                          )}
                        </motion.div>
                      );
                    })}
                  </div>
                </div>
              )}
            </div>
          </motion.div>
        ) : activeTool === 'progress' ? (
          <motion.div
            key="progress"
            custom={direction}
            initial={{ opacity: 0, x: direction > 0 ? 50 : -50, filter: 'blur(10px)' }}
            animate={{ opacity: 1, x: 0, filter: 'blur(0px)' }}
            exit={{ opacity: 0, x: direction > 0 ? -50 : 50, filter: 'blur(10px)' }}
            transition={{ type: 'spring', damping: 28, stiffness: 220, mass: 0.8 }}
            className="px-6 space-y-12 pb-32"
          >
            <div className="space-y-16">
              {/* Total Activity Summary Card */}
              <motion.div 
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.2, delay: 0.05 }}
                drag="x"
                dragConstraints={{ left: 0, right: 0 }}
                dragElastic={0.1}
                dragDirectionLock
                dragMomentum={false}
                onDragEnd={(event, info) => {
                  const swipeThreshold = 30;
                  if (info.offset.x < -swipeThreshold) {
                    // Swipe left -> Next
                    setTotalActivityTimeframe(prev => {
                      const idx = TIMEFRAMES.indexOf(prev);
                      return TIMEFRAMES[(idx + 1) % TIMEFRAMES.length];
                    });
                  } else if (info.offset.x > swipeThreshold) {
                    // Swipe right -> Prev
                    setTotalActivityTimeframe(prev => {
                      const idx = TIMEFRAMES.indexOf(prev);
                      return TIMEFRAMES[(idx - 1 + TIMEFRAMES.length) % TIMEFRAMES.length];
                    });
                  }
                }}
                onTouchStart={(e) => e.stopPropagation()}
                onTouchMove={(e) => e.stopPropagation()}
                onTouchEnd={(e) => e.stopPropagation()}
                className="glass-card rounded-3xl p-6 space-y-8 touch-none select-none relative overflow-hidden"
              >
                {(() => {
                  const now = new Date();
                  const allHabitIds = [...habits, ...completedHabits].map(h => h.id);
                  let ticks = 0;
                  
                  if (totalActivityTimeframe === 'week') {
                    const sunday = new Date(now);
                    sunday.setDate(now.getDate() - now.getDay());
                    sunday.setHours(0, 0, 0, 0);
                    allHabitIds.forEach(id => {
                      if (!completions[id]) return;
                      completions[id].forEach(c => {
                        const d = new Date(c);
                        if (d >= sunday) ticks++;
                      });
                    });
                  } else if (totalActivityTimeframe === 'month') {
                    const todayStart = new Date(now);
                    todayStart.setHours(0, 0, 0, 0);
                    allHabitIds.forEach(id => {
                      if (!completions[id]) return;
                      completions[id].forEach(c => {
                        const d = new Date(c);
                        const diffDays = Math.floor((todayStart.getTime() - d.getTime()) / (1000 * 60 * 60 * 24)); 
                        if (diffDays >= 0 && diffDays < 28) ticks++;
                      });
                    });
                  } else {
                    const currentYear = now.getFullYear();
                    allHabitIds.forEach(id => {
                      if (!completions[id]) return;
                      completions[id].forEach(c => {
                        const d = new Date(c);
                        if (d.getFullYear() === currentYear) ticks++;
                      });
                    });
                  }
                  return (
                    <div className="flex justify-between items-center">
                      <div className="space-y-1">
                        <h3 className="text-lg font-bold">Total Activity</h3>
                        <p className="text-xs text-zinc-500 uppercase tracking-widest font-bold">Daily Progress & Timing</p>
                      </div>
                      <div className="text-right">
                        <div className="text-2xl font-bold text-[#0a84ff]">
                          {ticks}
                        </div>
                        <div className="text-[10px] text-zinc-500 uppercase font-bold tracking-widest">{totalActivityTimeframe === 'week' ? 'Weekly' : totalActivityTimeframe === 'month' ? 'Monthly' : 'Yearly'} Ticks</div>
                      </div>
                    </div>
                  );
                })()}

                {/* Hourly Intensity Strip */}
                <div className="space-y-4">
                  <div className="flex justify-between items-center px-1">
                    <span className="text-[9px] text-zinc-500 font-bold uppercase tracking-wider">Hourly Intensity Peak: <span className="text-orange-500">{getPeakHourWrapper()}</span></span>
                    <div className="flex gap-2">
                       <div className="flex items-center gap-1">
                         <div className="w-1.5 h-1.5 rounded-full bg-zinc-800" />
                         <span className="text-[8px] text-zinc-600 font-bold uppercase">Low</span>
                       </div>
                       <div className="flex items-center gap-1">
                         <div className="w-1.5 h-1.5 rounded-full bg-orange-500 shadow-[0_0_5px_rgba(249,115,22,0.5)]" />
                         <span className="text-[8px] text-zinc-600 font-bold uppercase">High</span>
                       </div>
                    </div>
                  </div>
                  
                  <div className="grid grid-cols-24 gap-0.5 h-3 bg-black/20 rounded-full p-0.5 border border-white/5">
                    {getHourlyChartDataWrapper().map((data, i) => {
                      const intensity = data.max > 0 ? (data.value / data.max) : 0;
                      return (
                        <div key={i} className="relative group h-full">
                          <motion.div
                            initial={{ opacity: 0 }}
                            animate={{ opacity: 1 }}
                            className={`w-full h-full rounded-full transition-all duration-150 ${
                              data.value > 0 
                                ? 'bg-orange-500 shadow-[0_0_5px_rgba(249,115,22,0.3)]' 
                                : 'bg-transparent'
                            }`}
                            style={{ opacity: data.value > 0 ? Math.max(intensity, 0.3) : 0 }}
                          />
                          {/* Tooltip */}
                          <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-2 py-1 bg-zinc-900 border border-white/10 text-[8px] rounded opacity-0 group-hover:opacity-100 transition-opacity z-50 pointer-events-none whitespace-nowrap">
                            {data.label}: {data.value} ticks
                          </div>
                        </div>
                      );
                    })}
                  </div>
                  <div className="flex justify-between px-1">
                    <span className="text-[7px] text-zinc-700 font-bold uppercase">12AM</span>
                    <span className="text-[7px] text-zinc-700 font-bold uppercase">12PM</span>
                    <span className="text-[7px] text-zinc-700 font-bold uppercase">11PM</span>
                  </div>
                </div>
                
                <div className="space-y-4 pt-4 border-t border-white/5 mt-6">
                  <div className="flex justify-between items-center">
                    <h4 className="text-[10px] font-bold uppercase tracking-widest text-zinc-500">
                      {totalActivityTimeframe === 'week' ? 'Average Timing' : 'Overall Activity'}
                    </h4>
                    <div className="flex bg-black/20 p-1 rounded-lg border border-white/5">
                      <button 
                        onClick={() => setTotalActivityTimeframe('week')}
                        className={`px-2 py-1 flex-1 text-[9px] uppercase font-bold tracking-wider rounded-md transition-colors ${totalActivityTimeframe === 'week' ? 'bg-[#0a84ff] text-white' : 'text-zinc-500 hover:text-white'}`}
                      >
                        Week
                      </button>
                      <button 
                        onClick={() => setTotalActivityTimeframe('month')}
                        className={`px-2 py-1 flex-1 text-[9px] uppercase font-bold tracking-wider rounded-md transition-colors ${totalActivityTimeframe === 'month' ? 'bg-[#0a84ff] text-white' : 'text-zinc-500 hover:text-white'}`}
                      >
                        Month
                      </button>
                      <button 
                        onClick={() => setTotalActivityTimeframe('year')}
                        className={`px-2 py-1 flex-1 text-[9px] uppercase font-bold tracking-wider rounded-md transition-colors ${totalActivityTimeframe === 'year' ? 'bg-[#0a84ff] text-white' : 'text-zinc-500 hover:text-white'}`}
                      >
                        Year
                      </button>
                    </div>
                  </div>
                  
                  <div className={`relative h-24 flex items-end opacity-80 ${totalActivityTimeframe === 'week' ? 'gap-1 pl-6' : totalActivityTimeframe === 'month' ? 'gap-4 sm:gap-8' : 'gap-1.5 sm:gap-2'}`}>
                    {/* Y-Axis Labels & Grid Lines */}
                    <div className="absolute inset-0 flex flex-col justify-between pointer-events-none py-1">
                    <div className="border-t border-white/5 w-full flex items-center -mt-2">
                      {totalActivityTimeframe === 'week' && <span className="text-[8px] text-zinc-500 w-5 text-right pr-1 min-w-5">12AM</span>}
                    </div>
                    <div className="border-t border-white/5 w-full flex items-center">
                      {totalActivityTimeframe === 'week' && <span className="text-[8px] text-zinc-500 w-5 text-right pr-1 min-w-5">12PM</span>}
                    </div>
                    <div className="border-t border-white/5 w-full flex items-center">
                      {totalActivityTimeframe === 'week' && <span className="text-[8px] text-zinc-500 w-5 text-right pr-1 min-w-5">11PM</span>}
                    </div>
                  </div>

                  {getTotalChartDataWrapper().map((data: any, i, arr) => {
                    const height = data.max > 0 ? (data.value / data.max) * 90 : 0;
                    const isToday = data.isToday;
                    const isFirst = i === 0;
                    const isLast = i === arr.length - 1;
                    const isMid = i === Math.floor(arr.length / 2);
                    const showLabel = isFirst || isLast || isMid || isToday || arr.length <= 12;
                    
                    return (
                      <div key={i} className="flex-1 relative h-full flex items-end group z-10">
                        <motion.div 
                          initial={{ height: 0 }}
                          animate={{ height: data.isCompleted ? `${Math.max(height, 5)}%` : '5%' }}
                          transition={{ type: "spring", bounce: 0.2, duration: 0.2, delay: i * 0.01 }}
                          className={`w-full rounded-t-[3px] transition-all duration-100 ${
                            data.isCompleted ? 'bg-[#0a84ff]' : 'bg-white/5'
                          } ${isToday ? 'ring-1 ring-white/20' : ''}`}
                        />
                        {showLabel && (
                          <div className={`absolute -bottom-5 left-1/2 -translate-x-1/2 text-[9px] font-bold ${isToday ? 'text-app-text' : 'text-zinc-500'}`}>
                            {data.label}
                          </div>
                        )}
                        {data.isCompleted && (
                          <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-2 py-1 bg-zinc-900 border border-white/10 text-app-text text-[10px] rounded opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none whitespace-nowrap z-20">
                            {data.tooltip}
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
                </div>
              </motion.div>
              
              <div className="space-y-12">
                {activeHabits.length > 0 && usedCategories.length > 0 && (
                  <div 
                    className="flex overflow-x-auto gap-3 no-scrollbar pb-2 pt-2 snap-x"
                    onTouchStart={(e) => e.stopPropagation()}
                    onTouchMove={(e) => e.stopPropagation()}
                    onTouchEnd={(e) => e.stopPropagation()}
                  >
                    <button
                      onClick={() => setSelectedCategory('all')}
                      className={`px-4 py-2 rounded-full whitespace-nowrap text-sm font-medium transition-all shadow-sm snap-start shrink-0 pointer-events-auto touch-manipulation z-50 ${selectedCategory === 'all' ? 'bg-[#0a84ff] text-white' : 'glass-panel text-zinc-400 hover:text-white border border-app-border'}`}
                    >
                      All Habits
                    </button>
                    {usedCategories.map(cat => (
                      <button
                        key={cat.value}
                        onClick={() => setSelectedCategory(cat.value)}
                        className={`px-4 py-2 rounded-full whitespace-nowrap text-sm font-medium transition-all shadow-sm snap-start shrink-0 pointer-events-auto touch-manipulation z-50 flex items-center gap-2 ${selectedCategory === cat.value ? 'bg-[#0a84ff] text-white' : 'glass-panel text-zinc-400 hover:text-white border border-app-border'}`}
                      >
                        <cat.icon size={16} />
                        {cat.label}
                      </button>
                    ))}
                  </div>
                )}

              {(selectedCategory === 'all' ? activeHabits : activeHabits.filter(h => h.category === selectedCategory || (!h.category && selectedCategory === 'other'))).length === 0 ? (
                <div className="text-center py-12 px-6">
                  <h3 className="text-lg font-bold mb-2">No habits found</h3>
                  <p className="text-zinc-500 text-sm">No habits match the selected category.</p>
                </div>
              ) : (
                (selectedCategory === 'all' ? activeHabits : activeHabits.filter(h => h.category === selectedCategory || (!h.category && selectedCategory === 'other'))).map((habit, i) => {
                const cObj = COLORS.find(c => c.value === habit.color) || COLORS[0];
                const habitComps = completions[habit.id] || [];
                const isDoneToday = isDateCompleted(habitComps, todayStr);
                const streakDays = getStreakCount(habitComps);
                const progressPercent = habit.targetDays > 0 ? Math.round((habitComps.length / habit.targetDays) * 100) : 0;
                const daysRemaining = Math.max(0, habit.targetDays - habitComps.length);
                const currentStreakScore = calculateStreak(habitComps, habit.createdAt);
                const isLocked = currentStreakScore < 0 && !isDoneToday;
                
                return (
                  <motion.div 
                    layout 
                    key={`progress-section-${habit.id}`} 
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: i * 0.02 }}
                    whileTap={{ scale: 0.99 }}
                    className="space-y-6"
                  >
                    <div className="flex justify-between items-start">
                      <div className="flex items-center gap-4">
                        <motion.button 
                          whileTap={isLocked ? {} : { scale: 0.9 }}
                          onClick={() => {
                            if (!isLocked) {
                              if (isDoneToday) {
                                setHabitToUndo(habit.id);
                              } else {
                                toggleCompletion(habit.id, todayStr);
                              }
                            }
                          }}
                          className={`relative w-12 h-12 rounded-2xl border-2 flex items-center justify-center transition-all overflow-hidden ${
                            isDoneToday 
                              ? `${cObj.bg} ${cObj.border}` 
                              : isLocked
                                ? `border-zinc-800/50 bg-zinc-900/30 opacity-50 cursor-not-allowed`
                                : `border-zinc-800 bg-zinc-900/50 hover:border-zinc-600`
                          }`}
                        >
                          <AnimatePresence>
                            {isDoneToday && (
                               <motion.div
                                 initial={{ scale: 0, opacity: 0.8 }}
                                 animate={{ scale: 2.5, opacity: 0 }}
                                 transition={{ duration: 0.2, ease: "easeOut" }}
                                 className="absolute inset-0 rounded-2xl bg-white/40 z-0 pointer-events-none"
                               />
                            )}
                          </AnimatePresence>
                          {isDoneToday ? (
                            <motion.div
                              initial={{ scale: 0.3, rotate: -45, opacity: 0 }}
                              animate={{ scale: 1, rotate: 0, opacity: 1 }}
                              transition={{ type: "spring", stiffness: 400, damping: 15, mass: 1 }}
                              className="relative z-10"
                            >
                              <Check size={28} className="text-black" strokeWidth={4} />
                            </motion.div>
                          ) : isLocked ? (
                            <Lock size={20} className="text-zinc-600 relative z-10" />
                          ) : null}
                        </motion.button>
                        

                        <div className="space-y-1">
                          <div className="flex items-center gap-2">
                            <div className={`w-2 h-2 rounded-full ${cObj.bg} mt-1`} />
                            <div className="flex flex-col">
                              <span className={`${cObj.text} ${streakDays >= 21 ? 'text-sm' : 'text-xs'} font-bold uppercase tracking-wider transition-all duration-150`}>{habit.name}</span>
                              {habit.category && habit.category !== 'other' && (() => {
                                const cat = HABIT_CATEGORIES.find(c => c.value === habit.category);
                                const Icon = cat?.icon;
                                return (
                                  <div className="flex items-center gap-1 bg-white/5 border border-white/10 px-1 py-0.5 rounded-sm text-[8px] text-zinc-500 font-bold uppercase tracking-widest mt-0.5 w-fit">
                                    {Icon && <Icon size={8} />}
                                    <span>{cat?.label}</span>
                                  </div>
                                );
                              })()}
                            </div>
                            {streakDays > 0 && (
                              <div className="flex flex-col gap-1.5">
                                <motion.div 
                                  initial={{ scale: 0.8, opacity: 0 }}
                                  animate={{ scale: 1, opacity: 1 }}
                                  className={`flex items-center gap-2 px-2 py-0.5 rounded-full border transition-all duration-150 ${
                                    streakDays >= 30 ? 'bg-white/10 border-white/40 shadow-[0_0_15px_rgba(255,255,255,0.4)]' :
                                    streakDays >= 21 ? 'bg-purple-500/10 border-purple-500/30 shadow-[0_0_12px_rgba(168,85,247,0.3)]' :
                                    streakDays >= 14 ? 'bg-cyan-500/10 border-cyan-500/30 shadow-[0_0_10px_rgba(34,211,238,0.2)]' :
                                    streakDays >= 7 ? 'bg-yellow-500/10 border-yellow-500/30' :
                                    'bg-orange-500/10 border-orange-500/20'
                                  }`}
                                >
                                  <motion.div
                                    animate={{ 
                                      scale: [1, 1.2 + Math.min(streakDays / 50, 0.5), 1],
                                      rotate: [0, 5, -5, 0],
                                      filter: streakDays >= 21 ? ["hue-rotate(0deg)", "hue-rotate(360deg)"] : "none"
                                    }}
                                    transition={{ 
                                      duration: Math.max(0.4, 1.5 - (streakDays / 20)),
                                      repeat: Infinity,
                                      ease: "easeInOut"
                                    }}
                                  >
                                    <Flame 
                                      size={12 + Math.min(streakDays / 4, 12)} 
                                      className={`${
                                        streakDays >= 30 ? 'text-white' :
                                        streakDays >= 21 ? 'text-purple-400' :
                                        streakDays >= 14 ? 'text-cyan-400' :
                                        streakDays >= 7 ? 'text-yellow-400' :
                                        'text-orange-500'
                                      } transition-colors duration-150`} 
                                      fill="currentColor" 
                                    />
                                  </motion.div>
                                  <span className={`text-[11px] font-black tracking-tight ${
                                    streakDays >= 30 ? 'text-white' :
                                    streakDays >= 21 ? 'text-purple-400' :
                                    streakDays >= 14 ? 'text-cyan-400' :
                                    streakDays >= 7 ? 'text-yellow-400' :
                                    'text-orange-500'
                                  }`}>{streakDays}d</span>
                                  {streakDays >= 21 && (
                                    <span className="text-[8px] font-black uppercase text-white/60 tracking-widest pl-1">Master</span>
                                  )}
                                </motion.div>
                                <div className={`h-1 w-full bg-white/5 rounded-full overflow-hidden ${streakDays >= 21 ? 'h-1.5' : ''}`}>
                                  <motion.div 
                                    initial={{ width: 0 }}
                                    animate={{ width: `${Math.min((streakDays / 30) * 100, 100)}%` }}
                                    className={`h-full transition-all duration-150 ${
                                      streakDays >= 30 ? 'bg-white shadow-[0_0_10px_white]' :
                                      streakDays >= 21 ? 'bg-purple-500 shadow-[0_0_8px_rgba(168,85,247,0.6)]' :
                                      streakDays >= 14 ? 'bg-cyan-500 shadow-[0_0_6px_rgba(34,211,238,0.5)]' :
                                      streakDays >= 7 ? 'bg-yellow-500' :
                                      'bg-orange-500'
                                    }`}
                                  />
                                </div>
                              </div>
                            )}
                            <button 
                              onClick={() => setActiveHabitSettings(habit)}
                              className="text-zinc-600 hover:text-white transition-colors ml-1 p-1 rounded-full hover:bg-white/10"
                              title="Habit details"
                            >
                              <Info size={14} />
                            </button>
                          </div>
                        </div>
                      </div>
                      <div className="text-right space-y-1">
                        <div className="text-2xl font-bold text-white tracking-tight">{progressPercent}%</div>
                        <div className="text-[10px] text-zinc-500 uppercase font-bold tracking-widest">Progress</div>
                        {currentStreakScore !== 0 && (
                          <div className={`${currentStreakScore > 0 ? 'text-[#ff9500]' : 'text-[#00f2ff]'} text-[11px] font-bold flex items-center justify-end gap-1 mt-1`}>
                            {currentStreakScore > 0 ? <Flame size={12} /> : <AlertCircle size={12} />} {currentStreakScore > 0 ? `+${currentStreakScore}` : currentStreakScore} pts
                          </div>
                        )}
                      </div>
                    </div>

                    {/* Bar Chart with Labels */}
                    <div className="space-y-2">
                      <div className="flex justify-between items-center mb-1">
                        <span className="text-[10px] font-bold text-zinc-600 uppercase tracking-widest">Activity Timing</span>
                      </div>
                      <div className="relative h-24 flex items-end gap-1 pt-4 opacity-80 pl-6">
                        {/* Y-Axis Labels & Grid Lines */}
                        <div className="absolute inset-0 flex flex-col justify-between pointer-events-none py-1">
                          <div className="border-t border-white/5 w-full flex items-center -mt-2"><span className="text-[8px] text-zinc-500 w-5 text-right pr-1">12AM</span></div>
                          <div className="border-t border-white/5 w-full flex items-center"><span className="text-[8px] text-zinc-500 w-5 text-right pr-1">12PM</span></div>
                          <div className="border-t border-white/5 w-full flex items-center"><span className="text-[8px] text-zinc-500 w-5 text-right pr-1">11PM</span></div>
                        </div>

                        {getChartData(habit.id).map((data, i, arr) => {
                          const height = data.max > 0 ? (data.value / data.max) * 90 : 0;
                          const isToday = data.isToday;
                          const isFirst = i === 0;
                          const isLast = i === arr.length - 1;
                          const isMid = i === Math.floor(arr.length / 2);
                          const showLabel = isFirst || isLast || isMid || isToday || arr.length <= 12;
                          
                          return (
                             <motion.div
                              whileTap={{ scale: 0.9 }}
                              key={i}
                              className="flex-1 relative h-full flex items-end group z-10"
                            >
                              <motion.div 
                                initial={{ height: 0 }}
                                animate={{ height: data.isCompleted ? `${Math.max(height, 5)}%` : '5%' }}
                                transition={{ type: "spring", bounce: 0.2, duration: 0.2, delay: i * 0.01 }}
                                className={`w-full rounded-t-[2px] transition-all duration-100 ${
                                  data.isCompleted ? cObj.bg : 'bg-zinc-800/40'
                                } ${isToday ? 'ring-1 ring-white/20' : ''}`}
                              />
                              {showLabel && (
                                <div className={`absolute -bottom-5 left-1/2 -translate-x-1/2 text-[9px] font-bold ${isToday ? 'text-white' : 'text-zinc-600'}`}>
                                  {data.label}
                                </div>
                              )}
                              
                              {/* Tooltip on hover */}
                              {data.isCompleted && (
                                <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-2 py-1 bg-zinc-800 text-white text-[10px] rounded opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none whitespace-nowrap z-20 border border-white/10">
                                  {data.tooltip}
                                </div>
                              )}
                            </motion.div>
                          );
                        })}
                      </div>
                    </div>

                    {/* Detailed Progress Info */}
                    <div className="grid grid-cols-2 gap-4">
                      <div className="bg-[#1c1c1e] rounded-2xl p-4 space-y-4">
                        <div className="flex justify-between items-center">
                          <span className="text-xs font-bold text-zinc-500 uppercase tracking-wider">Calendar</span>
                          <span className="text-[10px] text-zinc-600 font-medium">This Month</span>
                        </div>
                        <CalendarGrid habit={habit} completions={habitComps} />
                      </div>
                      
                      <div className="flex flex-col justify-between">
                        <div className="glass-panel rounded-2xl p-4 flex-1 mb-2">
                          <span className="text-[10px] font-bold text-app-text-muted uppercase tracking-wider block mb-1">Remaining</span>
                          <div className="flex items-baseline gap-1">
                            <span className="text-xl font-bold">{daysRemaining}</span>
                            <span className="text-xs text-app-text-muted">days</span>
                          </div>
                        </div>
                        <div className="glass-panel rounded-2xl p-4 flex-1">
                          <span className="text-[10px] font-bold text-app-text-muted uppercase tracking-wider block mb-1">Target</span>
                          <div className="flex items-baseline gap-1">
                            <span className="text-xl font-bold">{habit.targetDays}</span>
                            <span className="text-xs text-app-text-muted">days</span>
                          </div>
                        </div>
                      </div>
                    </div>
                  </motion.div>
                );
              })
              )}
              </div>

            </div>
          </motion.div>
        ) : activeTool === 'completed' ? (
          <motion.div
            key="completed"
            custom={direction}
            initial={{ opacity: 0, x: direction > 0 ? 50 : -50, filter: 'blur(10px)' }}
            animate={{ opacity: 1, x: 0, filter: 'blur(0px)' }}
            exit={{ opacity: 0, x: direction > 0 ? -50 : 50, filter: 'blur(10px)' }}
            transition={{ type: 'spring', damping: 28, stiffness: 220, mass: 0.8 }}
            className="px-6 space-y-12 pb-32"
          >
            <div className="pt-8 space-y-6">
              <motion.div 
                initial={{ opacity: 0, y: 15 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.15, delay: 0.05 }}
                className="flex items-center gap-3"
              >
                <div className="h-px flex-1 bg-app-border" />
                <h3 className="text-[10px] font-bold text-app-text-muted uppercase tracking-[0.3em] whitespace-nowrap">Completed Achievements</h3>
                <div className="h-px flex-1 bg-app-border" />
              </motion.div>
              
              {allCompletedHabits.length > 0 ? (
                <div className="grid grid-cols-2 gap-4">
                  {allCompletedHabits.map(habit => {
                    const cObj = COLORS.find(c => c.value === habit.color) || COLORS[0];
                    return (
                      <motion.button
                        whileTap={{ scale: 0.95 }}
                        key={`achievement-${habit.id}`}
                        onClick={() => setShowCertificateFor(habit)}
                        className="glass-card rounded-3xl p-5 text-left relative overflow-hidden group"
                      >
                        <div className={`absolute top-0 right-0 w-16 h-16 ${cObj.bg} opacity-5 rounded-full -mr-8 -mt-8 group-hover:opacity-10 transition-opacity`} />
                        <div className="space-y-3 relative z-10">
                          <div className={`w-10 h-10 rounded-2xl ${cObj.bg} flex items-center justify-center shadow-lg shadow-black/20`}>
                            <CheckCircle size={20} className="text-black" />
                          </div>
                          <div>
                            <h4 className="font-bold text-sm truncate">{habit.name}</h4>
                            <p className="text-[10px] text-app-text-muted font-bold uppercase tracking-wider">Mastered</p>
                          </div>
                        </div>
                      </motion.button>
                    );
                  })}
                </div>
              ) : (
                <div className="flex flex-col items-center justify-center py-20 text-center space-y-4">
                  <div className="w-16 h-16 rounded-full bg-app-card-secondary/50 flex items-center justify-center">
                    <Star size={24} className="text-app-text-muted" />
                  </div>
                  <div>
                    <h3 className="font-bold text-app-text">No Completed Achievements</h3>
                    <p className="text-xs text-app-text-muted mt-1">Keep building your habits to earn achievements!</p>
                  </div>
                </div>
              )}
            </div>
          </motion.div>
        ) : null}
      </AnimatePresence>

      {/* Add Habit Modal */}
      <AnimatePresence>
        {isAdding && (
          <motion.div
            initial={{ y: '100%' }}
            animate={{ y: 0 }}
            exit={{ y: '100%' }}
            transition={{ type: 'spring', bounce: 0.2, duration: 0.2 }}
            className="fixed inset-0 z-50 bg-app-bg/60 backdrop-blur-2xl flex flex-col"
          >
            <div className="px-6 pt-12 pb-4 flex justify-between items-center border-b border-app-border">
              <button onClick={() => {
                setIsAdding(false);
                setEditingHabitId(null);
                setNewHabitName('');
              }} className="text-[#0a84ff] text-lg">Cancel</button>
              <h2 className="text-lg font-semibold text-app-text">{editingHabitId ? 'Edit Habit' : 'New Habit'}</h2>
              <button 
                onClick={handleAddOrEditHabit}
                disabled={!newHabitName.trim()}
                className="text-[#0a84ff] text-lg font-semibold disabled:opacity-50"
              >
                {editingHabitId ? 'Save' : 'Add'}
              </button>
            </div>

            <div 
              className="p-6 space-y-10 overflow-y-auto flex-1 pb-24"
              onTouchStart={(e) => e.stopPropagation()}
              onTouchMove={(e) => e.stopPropagation()}
              onTouchEnd={(e) => e.stopPropagation()}
            >
              <div className="space-y-3">
                <label className="text-[11px] font-bold text-app-text-muted uppercase tracking-wider">Name</label>
                <input
                  type="text"
                  autoFocus
                  placeholder="Habit Name"
                  value={newHabitName}
                  onChange={(e) => setNewHabitName(e.target.value)}
                  className="w-full glass-panel rounded-2xl px-5 py-4 text-xl font-medium focus:outline-none focus:ring-2 focus:ring-[#0a84ff]/50"
                />
              </div>

              <div className="space-y-3">
                <label className="text-[11px] font-bold text-app-text-muted uppercase tracking-wider">Goal (Days)</label>
                <input
                  type="number"
                  placeholder="0"
                  value={newHabitTarget}
                  onChange={(e) => setNewHabitTarget(e.target.value === '' ? '' : parseInt(e.target.value) || 0)}
                  className="w-full glass-panel rounded-2xl px-5 py-4 text-xl font-medium focus:outline-none focus:ring-2 focus:ring-[#0a84ff]/50"
                />
              </div>

              <div className="space-y-3">
                <label className="text-[11px] font-bold text-app-text-muted uppercase tracking-wider">Category</label>
                <div 
                  className="flex overflow-x-auto gap-3 no-scrollbar pb-2 pt-2 snap-x"
                  onTouchStart={(e) => e.stopPropagation()}
                  onTouchMove={(e) => e.stopPropagation()}
                  onTouchEnd={(e) => e.stopPropagation()}
                >
                  {HABIT_CATEGORIES.map(category => (
                    <button
                      key={category.value}
                      onClick={() => setNewHabitCategory(category.value)}
                      className={`px-4 py-2 rounded-full whitespace-nowrap text-sm font-medium transition-all shadow-sm snap-start shrink-0 pointer-events-auto flex items-center gap-2 ${
                        newHabitCategory === category.value
                          ? 'bg-[#0a84ff] text-white shadow-[#0a84ff]/20'
                          : 'glass-panel text-zinc-400 hover:text-white border border-app-border'
                      }`}
                    >
                      <category.icon size={16} />
                      <span className="text-sm">{category.label}</span>
                    </button>
                  ))}
                </div>
              </div>

              <div className="space-y-3">
                <label className="text-[11px] font-bold text-app-text-muted uppercase tracking-wider">Color Accent</label>
                <div className="grid grid-cols-6 gap-4">
                  {COLORS.map(color => (
                    <button
                      key={color.name}
                      onClick={() => setNewHabitColor(color)}
                      className={`aspect-square rounded-full flex items-center justify-center transition-all ${
                        newHabitColor.name === color.name 
                          ? `ring-2 ring-offset-2 ring-offset-app-bg ${color.border} scale-110` 
                          : 'opacity-60 hover:opacity-100'
                      }`}
                    >
                      <div className={`w-full h-full rounded-full ${color.bg}`} />
                    </button>
                  ))}
                </div>
              </div>

              <div className="space-y-3">
                <label className="text-[11px] font-bold text-app-text-muted uppercase tracking-wider">Notes (Instructions/Details)</label>
                <textarea
                  placeholder="What are the rules? Any specific details to remember..."
                  value={newHabitNotes}
                  onChange={(e) => setNewHabitNotes(e.target.value)}
                  className="w-full h-32 glass-panel rounded-2xl px-5 py-4 text-sm font-medium focus:outline-none focus:ring-2 focus:ring-[#0a84ff]/50 transition-all resize-none"
                />
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Note Edit Modal */}
      <AnimatePresence>
        {noteToEdit && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-[110] bg-black/70 backdrop-blur-md flex items-center justify-center p-6"
          >
            <motion.div
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              className="glass-card rounded-3xl p-6 w-full max-w-sm space-y-4"
            >
              <h3 className="text-xl font-bold">Reflection Note</h3>
              <p className="text-xs text-zinc-500 uppercase tracking-widest font-bold">
                {new Date(noteToEdit.date).toLocaleDateString(undefined, { weekday: 'long', month: 'short', day: 'numeric' })}
              </p>
              <textarea
                autoFocus
                placeholder="How did it go today?"
                value={noteToEdit.content}
                onChange={(e) => setNoteToEdit({ ...noteToEdit, content: e.target.value })}
                className="w-full h-40 glass-panel rounded-2xl px-5 py-4 text-app-text focus:outline-none focus:ring-2 focus:ring-[#0a84ff]/50 resize-none"
              />
              <div className="flex gap-3">
                <button
                  onClick={() => setNoteToEdit(null)}
                  className="flex-1 py-3 rounded-xl glass-panel font-bold text-app-text hover:bg-white/10"
                >
                  Cancel
                </button>
                <button
                  onClick={() => saveReflection(noteToEdit.habitId, noteToEdit.date, noteToEdit.content)}
                  className="flex-1 py-3 rounded-xl bg-[#0a84ff] font-bold text-white shadow-lg shadow-[#0a84ff]/20"
                >
                  Save
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Delete Confirmation Modal */}
      <AnimatePresence>
        {showCertificateFor && (
          <Certificate 
            habit={showCertificateFor} 
            onClose={() => setShowCertificateFor(null)} 
            userName={userName}
          />
        )}
        {habitToDelete && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-[100] bg-app-bg/60 backdrop-blur-sm flex items-center justify-center p-6"
          >
            <motion.div
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              transition={{ type: 'spring', bounce: 0.2, duration: 0.2 }}
              className="glass-card rounded-3xl p-6 w-full max-w-sm"
            >
              <h3 className="text-xl font-bold mb-2">Delete Habit?</h3>
              <p className="text-app-text-muted text-sm mb-6">
                Are you sure you want to delete this habit? All your completion history for this habit will be permanently removed.
              </p>
              <div className="flex gap-3">
                <button
                  onClick={() => setHabitToDelete(null)}
                  className="flex-1 py-3.5 rounded-xl glass-panel font-semibold text-app-text hover:bg-app-card-secondary/80 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={confirmDelete}
                  className="flex-1 py-3.5 rounded-xl bg-[#fa114f] font-semibold text-white hover:bg-[#fa114f]/80 transition-colors"
                >
                  Delete
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
        {habitToReset && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-[100] bg-app-bg/60 backdrop-blur-sm flex items-center justify-center p-6"
          >
            <motion.div
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              transition={{ type: 'spring', bounce: 0.2, duration: 0.2 }}
              className="glass-card rounded-3xl p-6 w-full max-w-sm"
            >
              <h3 className="text-xl font-bold mb-2">Reset Progress?</h3>
              <p className="text-app-text-muted text-sm mb-6">
                Are you sure you want to reset all progress for this habit? Your streak and stats for this will start from zero.
              </p>
              <div className="flex gap-3">
                <button
                  onClick={() => setHabitToReset(null)}
                  className="flex-1 py-3.5 rounded-xl glass-panel font-semibold text-app-text hover:bg-app-card-secondary/80 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={confirmResetProgress}
                  className={`flex-1 py-3.5 rounded-xl ${COLORS.find(c => c.value === habits.find(h => h.id === habitToReset)?.color)?.bg || 'bg-orange-500'} font-semibold text-black hover:opacity-90 transition-all active:scale-95`}
                >
                  Reset
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
        {habitToUndo && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-[100] bg-app-bg/60 backdrop-blur-sm flex items-center justify-center p-6"
          >
            <motion.div
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              transition={{ type: 'spring', bounce: 0.2, duration: 0.2 }}
              className="glass-card rounded-3xl p-6 w-full max-w-sm"
            >
              <h3 className="text-xl font-bold mb-2">Undo Habit?</h3>
              <p className="text-app-text-muted text-sm mb-6">
                Are you sure you want to undo your progress for today? This will remove today's completion and affect your streak.
              </p>
              <div className="flex gap-3">
                <button
                  onClick={() => setHabitToUndo(null)}
                  className="flex-1 py-3.5 rounded-xl glass-panel font-semibold text-app-text hover:bg-app-card-secondary/80 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={confirmUndo}
                  className={`flex-1 py-3.5 rounded-xl ${COLORS.find(c => c.value === habits.find(h => h.id === habitToUndo)?.color)?.bg || 'bg-orange-500'} font-semibold text-black hover:opacity-90 transition-all active:scale-95`}
                >
                  Undo
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
        {showClearConfirm && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-[100] bg-app-bg/60 backdrop-blur-sm flex items-center justify-center p-6"
          >
            <motion.div
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              transition={{ type: 'spring', bounce: 0.2, duration: 0.2 }}
              className="glass-card rounded-3xl p-6 w-full max-w-sm"
            >
              <div className="w-12 h-12 rounded-full bg-red-500/10 flex items-center justify-center mb-4 text-red-500">
                <AlertCircle size={24} />
              </div>
              <h3 className="text-xl font-bold mb-2 text-white">Clear All Data?</h3>
              <p className="text-app-text-muted text-sm mb-6">
                Are you sure you want to delete all habits, achievements, and history? <span className="font-bold text-red-400">This action cannot be undone.</span>
              </p>
              <div className="flex gap-3">
                <button
                  onClick={() => setShowClearConfirm(false)}
                  className="flex-1 py-3.5 rounded-xl glass-panel font-semibold text-app-text hover:bg-app-card-secondary/80 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={confirmClearAllData}
                  className="flex-1 py-3.5 rounded-xl bg-red-500 font-semibold text-white hover:bg-red-600 transition-colors shadow-lg shadow-red-500/20"
                >
                  Erase Data
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Habit Settings Tray */}
      <AnimatePresence>
        {activeHabitSettings && (
          <>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setActiveHabitSettings(null)}
              className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm"
            />
            <motion.div
              drag="y"
              dragConstraints={{ top: 0, bottom: 0 }}
              dragElastic={{ top: 0.05, bottom: 0.5 }}
              onDragEnd={(_, info) => {
                if (info.offset.y > 100) {
                  setActiveHabitSettings(null);
                }
              }}
              initial={{ y: '100%' }}
              animate={{ y: 0 }}
              exit={{ y: '100%' }}
              transition={{ type: 'spring', bounce: 0.1, duration: 0.2 }}
              className="fixed bottom-0 left-0 right-0 z-50 glass-card rounded-t-3xl p-6 pb-12 max-h-[90vh] overflow-y-auto no-scrollbar"
            >
              <div className="w-12 h-1.5 bg-app-card-secondary rounded-full mx-auto mb-6 shrink-0" />
              
              <div className="flex justify-between items-start mb-6">
                <div>
                  <h3 className="text-2xl font-bold">{activeHabitSettings.name}</h3>
                  <p className="text-xs text-zinc-500 font-bold uppercase tracking-widest mt-1">Detail View & Reflections</p>
                </div>
              </div>

              {/* Stats Grid */}
              <div className="grid grid-cols-2 gap-3 mb-8">
                <div className="glass-panel p-4 rounded-2xl border border-white/5">
                  <div className="text-[10px] font-bold text-zinc-500 uppercase tracking-widest mb-1">Current Streak</div>
                  <div className="text-2xl font-bold flex items-center gap-2">
                    {calculateStreak(completions[activeHabitSettings.id] || [], activeHabitSettings.createdAt)}
                    <Flame size={20} className="text-orange-500" />
                  </div>
                </div>
                <div className="glass-panel p-4 rounded-2xl border border-white/5">
                  <div className="text-[10px] font-bold text-zinc-500 uppercase tracking-widest mb-1">Total Ticks</div>
                  <div className="text-2xl font-bold flex items-center gap-2">
                    {completions[activeHabitSettings.id]?.length || 0}
                    <CheckCircle size={20} className="text-[#92ff00]" />
                  </div>
                </div>
              </div>

              <div className="space-y-8">
                {/* General Notes */}
                {activeHabitSettings.notes && (
                  <div className="space-y-3">
                    <h4 className="text-[10px] font-bold text-zinc-500 uppercase tracking-widest px-2">Instructions / Details</h4>
                    <div className="glass-panel p-4 rounded-2xl border border-white/5 text-sm text-zinc-300 leading-relaxed italic">
                      {activeHabitSettings.notes}
                    </div>
                  </div>
                )}

                {/* Reflections Logic */}
                {(() => {
                  const habitRefs = reflections[activeHabitSettings.id] || {};
                  const sortedDates = Object.keys(habitRefs).sort((a, b) => b.localeCompare(a));
                  if (sortedDates.length > 0) {
                    return (
                      <div className="space-y-4">
                        <h4 className="text-[10px] font-bold text-zinc-500 uppercase tracking-widest px-2">Recent Reflections</h4>
                        <div className="space-y-2 max-h-60 overflow-y-auto pr-2 no-scrollbar">
                          {sortedDates.slice(0, 5).map(date => (
                            <div key={date} className="glass-panel p-3 rounded-xl border border-white/5 space-y-1">
                              <div className="flex justify-between items-center">
                                <span className="text-[9px] font-bold text-[#0a84ff] uppercase">{new Date(date).toLocaleDateString(undefined, { month: 'short', day: 'numeric' })}</span>
                                <button 
                                  onClick={() => setNoteToEdit({ habitId: activeHabitSettings.id, date, content: habitRefs[date] })}
                                  className="text-[9px] text-zinc-600 hover:text-white uppercase font-bold"
                                >
                                  Edit
                                </button>
                              </div>
                              <p className="text-xs text-zinc-400">{habitRefs[date]}</p>
                            </div>
                          ))}
                        </div>
                      </div>
                    );
                  }
                  return null;
                })()}

                {/* Actions */}
                <div className="space-y-2">
                  <h4 className="text-[10px] font-bold text-zinc-500 uppercase tracking-widest mb-3 px-2">Actions</h4>
                  <div className="grid grid-cols-2 gap-2">
                    <button
                      onClick={() => openEditHabit(activeHabitSettings)}
                      className="py-3 rounded-xl bg-app-card-secondary/50 backdrop-blur-md border border-app-border font-bold text-sm text-app-text hover:bg-app-card-secondary transition-colors flex items-center justify-center gap-2"
                    >
                      <Edit2 size={14} />
                      Edit
                    </button>
                    <button
                      onClick={() => resetHabitProgress(activeHabitSettings.id)}
                      className="py-3 rounded-xl bg-app-card-secondary/50 backdrop-blur-md border border-app-border font-bold text-sm text-app-text hover:bg-app-card-secondary transition-colors flex items-center justify-center gap-2"
                    >
                      <RotateCcw size={14} />
                      Reset
                    </button>
                  </div>
                  <button
                    onClick={() => {
                      setHabitToDelete(activeHabitSettings.id);
                      setActiveHabitSettings(null);
                    }}
                    className="w-full py-3 rounded-xl bg-[#fa114f]/10 font-bold text-sm text-[#fa114f] hover:bg-[#fa114f]/20 transition-colors flex items-center justify-center gap-2"
                  >
                    <Trash2 size={14} />
                    Delete Habit
                  </button>
                </div>


              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>

      {/* Global Settings Tray */}
      <AnimatePresence>
        {isSettingsOpen && (
          <>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsSettingsOpen(false)}
              className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm"
            />
            <motion.div
              initial={{ y: '100%' }}
              animate={{ y: 0 }}
              exit={{ y: '100%' }}
              drag="y"
              dragConstraints={{ top: 0 }}
              dragElastic={0.4}
              onDragEnd={(_, info) => {
                if (info.offset.y > 100 || info.velocity.y > 500) {
                  setIsSettingsOpen(false);
                }
              }}
              transition={{ type: 'spring', bounce: 0, duration: 0.15 }}
              className="fixed bottom-0 left-1/2 -translate-x-1/2 w-full max-w-md z-50 glass-card rounded-t-[2.5rem] p-5 pb-10 touch-none"
            >
              <div className="w-10 h-1 bg-app-card-secondary rounded-full mx-auto mb-4" />
              <h3 className="text-lg font-bold mb-4 text-center">Settings</h3>
              
              <div className="space-y-2.5">
                <div className="bg-app-card-secondary/50 backdrop-blur-md border border-app-border rounded-2xl overflow-hidden">
                  <div className="flex items-center justify-between p-3.5 border-b border-app-border">
                    <div className="flex items-center gap-3">
                      <Bell size={18} className="text-[#0a84ff]" />
                      <span className="text-sm font-medium">Notifications</span>
                    </div>
                    <button 
                      onClick={() => setNotificationsEnabled(!notificationsEnabled)}
                      className={`w-10 h-6 rounded-full transition-colors relative ${notificationsEnabled ? 'bg-[#34c759]' : 'bg-zinc-600'}`}
                    >
                      <div className={`w-5 h-5 bg-white rounded-full absolute top-0.5 transition-transform shadow-sm ${notificationsEnabled ? 'translate-x-4.5' : 'translate-x-0.5'}`} />
                    </button>
                  </div>
                  
                  <div className="flex items-center justify-between p-3.5">
                    <div className="flex items-center gap-3">
                      <Smartphone size={18} className="text-[#0a84ff]" />
                      <span className="text-sm font-medium">Haptics</span>
                    </div>
                    <button 
                      onClick={() => setHapticsEnabled(!hapticsEnabled)}
                      className={`w-10 h-6 rounded-full transition-colors relative ${hapticsEnabled ? 'bg-[#34c759]' : 'bg-zinc-600'}`}
                    >
                      <div className={`w-5 h-5 bg-white rounded-full absolute top-0.5 transition-transform shadow-sm ${hapticsEnabled ? 'translate-x-4.5' : 'translate-x-0.5'}`} />
                    </button>
                  </div>
                </div>

                <div className="flex items-center justify-between p-3.5 bg-emerald-500/10 border border-emerald-500/20 rounded-2xl">
                  <div className="flex items-center gap-2.5">
                    <div className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
                    <span className="text-xs font-semibold text-emerald-300">Data Storage</span>
                  </div>
                  <span className="text-[11px] font-bold text-emerald-400 bg-emerald-500/20 px-2 py-0.5 rounded-full">
                    100% Local (On-Device)
                  </span>
                </div>

                <div className="grid grid-cols-2 gap-2">
                  <button
                    onClick={exportData}
                    className="py-3 px-2 rounded-2xl bg-app-card-secondary/50 backdrop-blur-md border border-app-border font-semibold text-xs text-app-text hover:bg-app-card-secondary transition-colors flex items-center justify-center gap-1.5 cursor-pointer"
                  >
                    <Download size={15} className="text-[#0a84ff]" />
                    Backup (JSON)
                  </button>

                  <label className="py-3 px-2 rounded-2xl bg-app-card-secondary/50 backdrop-blur-md border border-app-border font-semibold text-xs text-app-text hover:bg-app-card-secondary transition-colors flex items-center justify-center gap-1.5 cursor-pointer">
                    <input type="file" accept=".json" onChange={importData} className="hidden" />
                    <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-[#30d158]"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" x2="12" y1="3" y2="15"/></svg>
                    Restore Backup
                  </label>
                </div>

                <button
                  onClick={clearAllData}
                  className="w-full py-3 rounded-2xl bg-[#fa114f]/10 font-semibold text-sm text-[#fa114f] hover:bg-[#fa114f]/20 transition-colors flex items-center justify-center gap-2"
                >
                  <AlertCircle size={16} />
                  Clear Data
                </button>
              </div>
              
              <div className="mt-6 text-center">
                <p className="text-[10px] text-app-text-muted font-bold tracking-widest uppercase mb-1">Version 1.2.0</p>
                <div className="inline-flex flex-col items-center">
                  <span className="text-[9px] text-app-text-muted font-bold uppercase tracking-tighter">Developed by</span>
                  <span className="text-sm font-black bg-clip-text text-transparent bg-gradient-to-r from-[#0a84ff] via-[#5e5ce6] to-[#0a84ff] animate-gradient-x bg-[length:200%_auto]">
                    saisriram Sr
                  </span>
                </div>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>

      {/* Floating Navigation Bar */}
      <AnimatePresence>
        {!isSettingsOpen && !activeHabitSettings && !isAdding && showNav && (
          <motion.div 
            initial={{ opacity: 0, y: 50 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 150 }}
            transition={{ type: 'spring', damping: 25, stiffness: 200 }}
            className="fixed bottom-6 sm:bottom-8 left-1/2 -translate-x-1/2 z-50 w-[calc(100%-2rem)] max-w-sm sm:max-w-md md:max-w-lg lg:max-w-xl xl:max-w-2xl pointer-events-none"
          >
            <motion.div 
              layout 
              transition={{ type: "spring", bounce: 0, duration: 0.15 }}
              drag="x"
              dragControls={tabDragControls}
              dragListener={false}
              dragConstraints={{ left: 0, right: 0 }}
              dragElastic={0.2}
              dragDirectionLock
              dragMomentum={false}
              onContextMenu={(e) => e.preventDefault()}
              onDragEnd={(event, info) => {
                const swipeThreshold = 50; // Increased from 20 for more intentional swipes
                const tools = ['home', 'progress', 'badges', 'completed'] as const;
                const currentIndex = tools.indexOf(activeTool as any);
                
                // Only navigate if it's primarily a horizontal swipe
                if (Math.abs(info.offset.x) > Math.abs(info.offset.y)) {
                  if (info.offset.x < -swipeThreshold && currentIndex < tools.length - 1) {
                    handleToolChange(tools[currentIndex + 1]);
                  } else if (info.offset.x > swipeThreshold && currentIndex > 0) {
                    handleToolChange(tools[currentIndex - 1]);
                  }
                }
              }}
              className="glass-card backdrop-blur-2xl p-1.5 sm:p-2 md:p-2.5 rounded-full flex items-center justify-between gap-1 sm:gap-2 border border-app-border shadow-[0_20px_50px_rgba(0,0,0,0.7)] mx-auto w-full pointer-events-auto touch-none select-none"
            >
              <motion.button
                layout
                drag="y"
                dragConstraints={{ top: 0, bottom: 0 }}
                dragElastic={{ top: 0, bottom: 0.5 }}
                onDragEnd={(_, info) => {
                  if (info.offset.y > 60) { // Swipe down on home to open To-do
                    setIsTodoOpen(true);
                  }
                }}
                whileTap={{ scale: 0.95 }}
                transition={{ type: "spring", bounce: 0, duration: 0.15 }}
                onClick={() => {
                  if (activeTool === 'home') {
                    setIsTodoOpen(true);
                  } else {
                    handleToolChange('home');
                  }
                }}
                onPointerDown={(e) => {
                  if (activeTool === 'home') {
                    tabDragControls.start(e);
                  }
                }}
                className={`relative flex-1 py-2.5 sm:py-3 md:py-3.5 px-2 sm:px-4 rounded-full flex flex-row items-center justify-center transition-colors duration-150 overflow-hidden ${
                  activeTool === 'home' ? 'text-app-text gap-2 sm:gap-2.5 bg-app-card-secondary/80 shadow-sm' : 'text-app-text-muted hover:text-app-text/70 hover:bg-white/5 gap-0'
                }`}
              >
                {activeTool === 'home' && (
                  <motion.div
                    layoutId="active-pill"
                    className="absolute inset-0 bg-app-card-secondary/80 backdrop-blur-md rounded-full -z-10"
                    transition={{ type: "spring", bounce: 0, duration: 0.15 }}
                  />
                )}
                <Home className={`relative z-10 ${activeTool === 'home' ? 'scale-110' : ''} w-5 h-5 sm:w-6 sm:h-6 transition-transform duration-150`} />
                <AnimatePresence mode="popLayout">
                  {activeTool === 'home' && (
                    <motion.span 
                      initial={{ width: 0, opacity: 0 }}
                      animate={{ width: 'auto', opacity: 1 }}
                      exit={{ width: 0, opacity: 0 }}
                      transition={{ type: "spring", bounce: 0, duration: 0.15 }}
                      className="text-xs sm:text-sm font-bold uppercase tracking-[0.12em] whitespace-nowrap overflow-hidden relative z-10"
                    >
                      Home
                    </motion.span>
                  )}
                </AnimatePresence>
              </motion.button>

              <motion.button
                layout
                whileTap={{ scale: 0.95 }}
                transition={{ type: "spring", bounce: 0, duration: 0.15 }}
                onClick={() => handleToolChange('progress')}
                onPointerDown={(e) => {
                  if (activeTool === 'progress') {
                    tabDragControls.start(e);
                  }
                }}
                className={`relative flex-1 py-2.5 sm:py-3 md:py-3.5 px-2 sm:px-4 rounded-full flex flex-row items-center justify-center transition-colors duration-150 overflow-hidden ${
                  activeTool === 'progress' ? 'text-app-text gap-2 sm:gap-2.5 bg-app-card-secondary/80 shadow-sm' : 'text-app-text-muted hover:text-app-text/70 hover:bg-white/5 gap-0'
                }`}
              >
                {activeTool === 'progress' && (
                  <motion.div
                    layoutId="active-pill"
                    className="absolute inset-0 bg-app-card-secondary/80 backdrop-blur-md rounded-full -z-10"
                    transition={{ type: "spring", bounce: 0, duration: 0.15 }}
                  />
                )}
                <Activity className={`relative z-10 ${activeTool === 'progress' ? 'scale-110' : ''} -scale-y-100 w-5 h-5 sm:w-6 sm:h-6 transition-transform duration-150`} />
                <AnimatePresence mode="popLayout">
                  {activeTool === 'progress' && (
                    <motion.span 
                      initial={{ width: 0, opacity: 0 }}
                      animate={{ width: 'auto', opacity: 1 }}
                      exit={{ width: 0, opacity: 0 }}
                      transition={{ type: "spring", bounce: 0, duration: 0.15 }}
                      className="text-xs sm:text-sm font-bold uppercase tracking-[0.12em] whitespace-nowrap overflow-hidden relative z-10"
                    >
                      Progress
                    </motion.span>
                  )}
                </AnimatePresence>
              </motion.button>

              <motion.button
                layout
                whileTap={{ scale: 0.95 }}
                transition={{ type: "spring", bounce: 0, duration: 0.15 }}
                onClick={() => handleToolChange('badges')}
                onPointerDown={(e) => {
                  if (activeTool === 'badges') {
                    tabDragControls.start(e);
                  }
                }}
                className={`relative flex-1 py-2.5 sm:py-3 md:py-3.5 px-2 sm:px-4 rounded-full flex flex-row items-center justify-center transition-colors duration-150 overflow-hidden ${
                  activeTool === 'badges' ? 'text-app-text gap-2 sm:gap-2.5 bg-app-card-secondary/80 shadow-sm' : 'text-app-text-muted hover:text-app-text/70 hover:bg-white/5 gap-0'
                }`}
              >
                {activeTool === 'badges' && (
                  <motion.div
                    layoutId="active-pill"
                    className="absolute inset-0 bg-app-card-secondary/80 backdrop-blur-md rounded-full -z-10"
                    transition={{ type: "spring", bounce: 0, duration: 0.15 }}
                  />
                )}
                <Award className={`relative z-10 ${activeTool === 'badges' ? 'scale-110' : ''} w-5 h-5 sm:w-6 sm:h-6 transition-transform duration-150`} />
                <AnimatePresence mode="popLayout">
                  {activeTool === 'badges' && (
                    <motion.span 
                      initial={{ width: 0, opacity: 0 }}
                      animate={{ width: 'auto', opacity: 1 }}
                      exit={{ width: 0, opacity: 0 }}
                      transition={{ type: "spring", bounce: 0, duration: 0.15 }}
                      className="text-xs sm:text-sm font-bold uppercase tracking-[0.12em] whitespace-nowrap overflow-hidden relative z-10"
                    >
                      Badges
                    </motion.span>
                  )}
                </AnimatePresence>
              </motion.button>

              <motion.button
                layout
                whileTap={{ scale: 0.95 }}
                transition={{ type: "spring", bounce: 0, duration: 0.15 }}
                onClick={() => handleToolChange('completed')}
                onPointerDown={(e) => {
                  if (activeTool === 'completed') {
                    tabDragControls.start(e);
                  }
                }}
                className={`relative flex-1 py-2.5 sm:py-3 md:py-3.5 px-2 sm:px-4 rounded-full flex flex-row items-center justify-center transition-colors duration-150 overflow-hidden ${
                  activeTool === 'completed' ? 'text-app-text gap-2 sm:gap-2.5 bg-app-card-secondary/80 shadow-sm' : 'text-app-text-muted hover:text-app-text/70 hover:bg-white/5 gap-0'
                }`}
              >
                {activeTool === 'completed' && (
                  <motion.div
                    layoutId="active-pill"
                    className="absolute inset-0 bg-app-card-secondary/80 backdrop-blur-md rounded-full -z-10"
                    transition={{ type: "spring", bounce: 0, duration: 0.15 }}
                  />
                )}
                <CheckCircle className={`relative z-10 ${activeTool === 'completed' ? 'scale-110' : ''} w-5 h-5 sm:w-6 sm:h-6 transition-transform duration-150`} />
                <AnimatePresence mode="popLayout">
                  {activeTool === 'completed' && (
                    <motion.span 
                      initial={{ width: 0, opacity: 0 }}
                      animate={{ width: 'auto', opacity: 1 }}
                      exit={{ width: 0, opacity: 0 }}
                      transition={{ type: "spring", bounce: 0, duration: 0.15 }}
                      className="text-xs sm:text-sm font-bold uppercase tracking-[0.12em] whitespace-nowrap overflow-hidden relative z-10"
                    >
                      Done
                    </motion.span>
                  )}
                </AnimatePresence>
              </motion.button>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
      <AnimatePresence>
        {isTodoOpen && (
          <TodoPage 
            todos={todos} 
            setTodos={setTodos} 
            onBack={() => setIsTodoOpen(false)} 
            userName={userName}
            setIsAdding={setIsAdding}
            setIsSettingsOpen={setIsSettingsOpen}
          />
        )}
      </AnimatePresence>
    </div>
  );
}

