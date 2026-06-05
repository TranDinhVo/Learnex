import { useState } from 'react';
import { Link } from 'react-router-dom';
import { 
  Download, 
  Smartphone, 
  BookOpen, 
  MessageSquare, 
  Folder, 
  Bell, 
  ArrowRight, 
  ShieldAlert, 
  CheckCircle2, 
  ArrowLeft,
  Info,
  ShieldCheck,
  Star,
  Users
} from 'lucide-react';

export default function DownloadPage() {
  const [copied, setCopied] = useState(false);

  const handleCopyLink = () => {
    navigator.clipboard.writeText(window.location.origin + '/learnex.apk');
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 font-sans selection:bg-purple-600 selection:text-white relative overflow-hidden">
      
      {/* Decorative ambient background glows */}
      <div className="absolute top-[-10%] left-[-10%] w-[50%] h-[50%] bg-purple-600/10 rounded-full blur-[120px] pointer-events-none" />
      <div className="absolute bottom-[-10%] right-[-10%] w-[50%] h-[50%] bg-indigo-600/15 rounded-full blur-[120px] pointer-events-none" />
      <div className="absolute top-[40%] right-[-20%] w-[40%] h-[45%] bg-blue-600/10 rounded-full blur-[120px] pointer-events-none" />

      {/* Header / Navigation */}
      <header className="sticky top-0 z-40 bg-slate-950/80 backdrop-blur-md border-b border-slate-900 px-6 py-4">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-purple-600 to-indigo-600 flex items-center justify-center shadow-lg shadow-purple-500/25">
              <span className="font-bold text-xl text-white tracking-wider">L</span>
            </div>
            <div>
              <span className="font-bold text-xl tracking-tight bg-gradient-to-r from-white via-slate-100 to-slate-400 bg-clip-text text-transparent">
                Learnex
              </span>
              <span className="text-[10px] block text-purple-400 font-semibold tracking-wider uppercase -mt-0.5">Mobile App</span>
            </div>
          </div>

          <div className="flex items-center gap-4">
            <Link 
              to="/dashboard" 
              className="text-sm font-medium text-slate-400 hover:text-white flex items-center gap-1.5 transition-colors"
            >
              <ArrowLeft size={16} />
              <span className="hidden sm:inline">Quản trị viên</span>
            </Link>
            <a 
              href="/learnex.apk" 
              download
              className="px-4 py-2 rounded-xl bg-gradient-to-r from-purple-600 to-indigo-600 text-white font-medium text-sm hover:from-purple-500 hover:to-indigo-500 shadow-md shadow-purple-500/10 hover:shadow-purple-500/25 transition-all flex items-center gap-1.5"
            >
              <Download size={16} />
              <span>Tải APK</span>
            </a>
          </div>
        </div>
      </header>

      {/* Main Container */}
      <main className="max-w-7xl mx-auto px-6 py-12 md:py-20 relative z-10">
        
        {/* Hero Section */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-8 items-center mb-28">
          
          {/* Left Column: Heading and description */}
          <div className="lg:col-span-7 space-y-8 text-center lg:text-left">
            <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-purple-500/10 border border-purple-500/20 text-purple-400 text-xs font-semibold tracking-wide uppercase">
              <Star size={12} className="fill-purple-400" />
              <span>Học tập không giới hạn cùng Learnex Mobile</span>
            </div>

            <h1 className="text-4xl md:text-5xl lg:text-6xl font-extrabold leading-[1.1] tracking-tight text-white">
              Kết Nối &amp; Học Tập <br className="hidden md:inline" />
              <span className="bg-gradient-to-r from-purple-400 via-indigo-400 to-blue-400 bg-clip-text text-transparent">
                Mọi Lúc, Mọi Nơi
              </span>
            </h1>

            <p className="text-base md:text-lg text-slate-400 max-w-2xl mx-auto lg:mx-0 leading-relaxed">
              Trải nghiệm ứng dụng di động Learnex được thiết kế tối ưu cho trải nghiệm học tập của bạn. Tham gia phòng học thảo luận, luyện tập Flashcards tiện lợi, chia sẻ tài liệu và tương tác cùng cộng đồng học tập trực tuyến.
            </p>

            {/* CTAs */}
            <div className="flex flex-col sm:flex-row gap-4 justify-center lg:justify-start">
              <a 
                href="/learnex.apk" 
                download
                className="px-8 py-4 rounded-2xl bg-gradient-to-r from-purple-600 to-indigo-600 text-white font-semibold hover:from-purple-500 hover:to-indigo-500 shadow-xl shadow-purple-500/20 hover:shadow-purple-500/35 hover:-translate-y-0.5 active:translate-y-0 transition-all flex items-center justify-center gap-2.5 text-base"
              >
                <Download size={20} />
                <span>Tải APK Trực Tiếp</span>
              </a>
              <a 
                href="#guide"
                className="px-8 py-4 rounded-2xl bg-slate-900 border border-slate-800 text-slate-300 font-semibold hover:bg-slate-850 hover:text-white hover:border-slate-700 hover:-translate-y-0.5 active:translate-y-0 transition-all flex items-center justify-center gap-2"
              >
                <span>Hướng dẫn cài đặt</span>
                <ArrowRight size={18} />
              </a>
            </div>

            {/* Quick Metrics / Features */}
            <div className="grid grid-cols-3 gap-6 pt-6 max-w-md mx-auto lg:mx-0">
              <div className="text-center lg:text-left border-r border-slate-900 pr-4">
                <div className="text-2xl font-bold text-white">v1.0.0</div>
                <div className="text-xs text-slate-500 mt-1">Phiên bản hiện tại</div>
              </div>
              <div className="text-center lg:text-left border-r border-slate-900 px-4">
                <div className="text-2xl font-bold text-white">~24 MB</div>
                <div className="text-xs text-slate-500 mt-1">Dung lượng file</div>
              </div>
              <div className="text-center lg:text-left pl-4">
                <div className="text-2xl font-bold text-white">Android</div>
                <div className="text-xs text-slate-500 mt-1">Hỗ trợ Android 7+</div>
              </div>
            </div>
          </div>

          {/* Right Column: Phone Mockup */}
          <div className="lg:col-span-5 flex justify-center">
            
            {/* Phone Container wrapper */}
            <div className="relative">
              
              {/* Backlight glow behind the phone */}
              <div className="absolute inset-0 bg-gradient-to-tr from-purple-600/30 to-indigo-600/30 rounded-[3rem] blur-2xl transform rotate-6 scale-95 pointer-events-none" />
              
              {/* Phone Frame */}
              <div className="relative mx-auto border-slate-800 bg-slate-900 border-[12px] rounded-[3rem] h-[580px] w-[285px] shadow-2xl overflow-hidden ring-1 ring-slate-800">
                
                {/* Notch / Speaker */}
                <div className="absolute top-0 inset-x-0 h-4 w-32 bg-slate-900 rounded-b-2xl mx-auto z-30 flex items-center justify-center">
                  <div className="w-12 h-1 bg-slate-800 rounded-full -mt-1" />
                </div>
                
                {/* Home Indicator Bar */}
                <div className="absolute bottom-1.5 inset-x-0 h-1 w-28 bg-slate-700/80 rounded-full mx-auto z-30" />

                {/* Inside Screen Content */}
                <div className="w-full h-full bg-slate-950 flex flex-col relative select-none">
                  
                  {/* Status Bar */}
                  <div className="h-9 pt-2.5 px-6 flex justify-between items-center text-[10px] font-medium text-slate-400 z-20">
                    <span>9:41</span>
                    <div className="flex items-center gap-1">
                      {/* Signal bar */}
                      <svg className="w-3 h-3 fill-current" viewBox="0 0 24 24"><path d="M12 3c-1.2 0-2.4.2-3.6.7L19.3 15c.5-1.2.7-2.4.7-3.6 0-5.5-4.5-10-10-10zM2.9 4.3L1.5 5.7l2.8 2.8C3.5 9.4 3 10.7 3 12c0 5.5 4.5 10 10 10 1.3 0 2.6-.5 3.6-1.3l2.7 2.7 1.4-1.4L2.9 4.3z"/></svg>
                      {/* Battery */}
                      <div className="w-4 h-2.5 border border-slate-400 rounded-sm p-0.5 flex items-center"><div className="w-full h-full bg-slate-400 rounded-2xs" /></div>
                    </div>
                  </div>

                  {/* App Mockup Header */}
                  <div className="px-4 py-3 flex items-center justify-between border-b border-slate-900/60 bg-slate-950/90 backdrop-blur-md">
                    <div className="flex items-center gap-2">
                      <div className="w-6 h-6 rounded-md bg-purple-600 flex items-center justify-center text-[11px] font-bold text-white">L</div>
                      <span className="font-bold text-xs tracking-tight text-white">Learnex</span>
                    </div>
                    <div className="w-5 h-5 rounded-full bg-slate-900 flex items-center justify-center">
                      <Bell size={10} className="text-slate-400" />
                    </div>
                  </div>

                  {/* Mock Screen Body */}
                  <div className="flex-1 overflow-y-auto px-4 py-3 space-y-4 text-left">
                    
                    {/* Welcome User Card */}
                    <div className="p-3.5 rounded-xl bg-gradient-to-r from-purple-900/35 to-indigo-900/35 border border-purple-500/10">
                      <div className="text-[10px] text-purple-300 font-medium">Xin chào Học Viên! 👋</div>
                      <div className="text-[12px] text-white font-semibold mt-0.5">Tiếp tục tiến độ học tập hôm nay nào</div>
                    </div>

                    {/* Quick Stats Grid */}
                    <div className="grid grid-cols-2 gap-2">
                      <div className="p-2.5 rounded-lg bg-slate-900 border border-slate-850">
                        <span className="text-[9px] text-slate-500 block">Thời gian học</span>
                        <span className="text-[12px] font-bold text-slate-200">1.5 giờ</span>
                      </div>
                      <div className="p-2.5 rounded-lg bg-slate-900 border border-slate-850">
                        <span className="text-[9px] text-slate-500 block">Từ vựng mới</span>
                        <span className="text-[12px] font-bold text-slate-200">25 từ</span>
                      </div>
                    </div>

                    {/* Hot Study Rooms */}
                    <div>
                      <div className="flex justify-between items-center mb-2">
                        <span className="text-[10px] font-bold text-slate-400 tracking-wide uppercase">Phòng học nổi bật</span>
                        <span className="text-[8px] text-purple-400">Xem tất cả</span>
                      </div>
                      <div className="space-y-2">
                        {/* Room 1 */}
                        <div className="p-3 rounded-xl bg-slate-900/80 border border-slate-850 hover:border-slate-800 transition-colors">
                          <div className="flex justify-between items-start">
                            <span className="text-[11px] font-semibold text-slate-200 line-clamp-1">Giải Tích 1 - Lớp K68</span>
                            <span className="px-1.5 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 text-[8px] font-medium flex items-center gap-0.5">
                              <span className="w-1 h-1 rounded-full bg-emerald-400 animate-pulse" /> Live
                            </span>
                          </div>
                          <div className="text-[9px] text-slate-500 mt-1 flex items-center gap-1">
                            <Users size={8} /> <span>14 đang tham gia</span>
                          </div>
                        </div>
                        {/* Room 2 */}
                        <div className="p-3 rounded-xl bg-slate-900/80 border border-slate-850">
                          <div className="flex justify-between items-start">
                            <span className="text-[11px] font-semibold text-slate-200 line-clamp-1">IELTS Speaking Practice</span>
                            <span className="px-1.5 py-0.5 rounded-full bg-purple-500/10 text-purple-400 text-[8px] font-medium">
                              9:00 PM
                            </span>
                          </div>
                          <div className="text-[9px] text-slate-500 mt-1 flex items-center gap-1">
                            <Users size={8} /> <span>30 quan tâm</span>
                          </div>
                        </div>
                      </div>
                    </div>

                    {/* Interactive Flashcard Preview */}
                    <div>
                      <div className="text-[10px] font-bold text-slate-400 tracking-wide uppercase mb-2">Luyện Flashcard</div>
                      <div className="p-4 rounded-xl bg-gradient-to-b from-slate-900 to-slate-950 border border-slate-800/80 text-center relative overflow-hidden">
                        <div className="absolute top-2 right-2 text-[8px] bg-indigo-500/10 text-indigo-400 px-1.5 py-0.5 rounded">Từ vựng C1</div>
                        <div className="text-[15px] font-bold text-white mt-2 mb-1">Ambidextrous</div>
                        <div className="text-[9px] text-slate-500 italic mb-2">/ˌæm.bɪˈdek.strəs/</div>
                        <div className="h-[1px] bg-slate-900 w-3/4 mx-auto my-2" />
                        <div className="text-[10px] text-purple-300">Gõ để lật thẻ và xem nghĩa</div>
                      </div>
                    </div>

                  </div>

                  {/* App Mockup Navigation Bar */}
                  <div className="h-12 border-t border-slate-900 bg-slate-950 px-6 flex justify-between items-center text-slate-500 text-[9px] font-medium z-20">
                    <div className="flex flex-col items-center gap-0.5 text-purple-400">
                      <BookOpen size={12} />
                      <span>Học tập</span>
                    </div>
                    <div className="flex flex-col items-center gap-0.5">
                      <MessageSquare size={12} />
                      <span>Chat</span>
                    </div>
                    <div className="flex flex-col items-center gap-0.5">
                      <Folder size={12} />
                      <span>Tài liệu</span>
                    </div>
                    <div className="flex flex-col items-center gap-0.5">
                      <Smartphone size={12} />
                      <span>Tài khoản</span>
                    </div>
                  </div>

                </div>

              </div>

            </div>

          </div>

        </div>

        {/* Features Grid Section */}
        <div className="border-t border-slate-900 pt-20 mb-28">
          <div className="text-center max-w-3xl mx-auto mb-16 space-y-4">
            <h2 className="text-3xl md:text-4xl font-extrabold text-white">
              Các tính năng vượt trội của app mobile
            </h2>
            <p className="text-slate-400 text-sm md:text-base">
              Learnex được xây dựng để cung cấp môi trường học tập xã hội trực tuyến liền mạch, tiện lợi và tăng hiệu quả tiếp thu kiến thức.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            
            {/* Feature 1 */}
            <div className="p-6 rounded-2xl bg-slate-900/30 border border-slate-900 hover:border-purple-500/30 hover:bg-slate-900/50 transition-all group duration-300">
              <div className="w-12 h-12 rounded-xl bg-purple-500/10 border border-purple-500/20 flex items-center justify-center text-purple-400 group-hover:scale-110 group-hover:bg-purple-600 group-hover:text-white transition-all">
                <BookOpen size={22} />
              </div>
              <h3 className="text-lg font-bold text-white mt-5 mb-2">Học Qua Flashcard</h3>
              <p className="text-sm text-slate-400 leading-relaxed">
                Tạo và học từ vựng, thuật ngữ thông qua các bộ thẻ ghi nhớ tương tác. Hỗ trợ hệ thống thuật toán lặp lại ngắt quãng tối ưu.
              </p>
            </div>

            {/* Feature 2 */}
            <div className="p-6 rounded-2xl bg-slate-900/30 border border-slate-900 hover:border-indigo-500/30 hover:bg-slate-900/50 transition-all group duration-300">
              <div className="w-12 h-12 rounded-xl bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center text-indigo-400 group-hover:scale-110 group-hover:bg-indigo-600 group-hover:text-white transition-all">
                <MessageSquare size={22} />
              </div>
              <h3 className="text-lg font-bold text-white mt-5 mb-2">Phòng Học Trực Tuyến</h3>
              <p className="text-sm text-slate-400 leading-relaxed">
                Tham gia thảo luận nhóm bằng giọng nói và nhắn tin thời gian thực với cộng đồng. Hỗ trợ tạo phòng học riêng tư hoặc công khai.
              </p>
            </div>

            {/* Feature 3 */}
            <div className="p-6 rounded-2xl bg-slate-900/30 border border-slate-900 hover:border-blue-500/30 hover:bg-slate-900/50 transition-all group duration-300">
              <div className="w-12 h-12 rounded-xl bg-blue-500/10 border border-blue-500/20 flex items-center justify-center text-blue-400 group-hover:scale-110 group-hover:bg-blue-600 group-hover:text-white transition-all">
                <Folder size={22} />
              </div>
              <h3 className="text-lg font-bold text-white mt-5 mb-2">Thư Viện Tài Liệu</h3>
              <p className="text-sm text-slate-400 leading-relaxed">
                Kho tài liệu chuyên ngành phong phú được đóng góp bởi các học viên khác. Bạn có thể lưu trữ, đọc trực tiếp trên app di động.
              </p>
            </div>

            {/* Feature 4 */}
            <div className="p-6 rounded-2xl bg-slate-900/30 border border-slate-900 hover:border-pink-500/30 hover:bg-slate-900/50 transition-all group duration-300">
              <div className="w-12 h-12 rounded-xl bg-pink-500/10 border border-pink-500/20 flex items-center justify-center text-pink-400 group-hover:scale-110 group-hover:bg-pink-600 group-hover:text-white transition-all">
                <Bell size={22} />
              </div>
              <h3 className="text-lg font-bold text-white mt-5 mb-2">Thông Báo Đẩy (Push)</h3>
              <p className="text-sm text-slate-400 leading-relaxed">
                Được cập nhật ngay lập tức khi có tin nhắn mới trong phòng học của bạn, phản hồi trên bài đăng hoặc khi tài liệu quan trọng tải lên.
              </p>
            </div>

          </div>
        </div>

        {/* Download & Installation Guide Section */}
        <div id="guide" className="border-t border-slate-900 pt-20 grid grid-cols-1 lg:grid-cols-12 gap-12 mb-16 items-start">
          
          {/* Left Column: Download & Specs */}
          <div className="lg:col-span-5 space-y-8">
            <h2 className="text-3xl font-extrabold text-white">
              Tải xuống file APK
            </h2>
            <p className="text-slate-400 text-sm leading-relaxed">
              Bạn có thể quét mã QR để tải trực tiếp trên điện thoại Android của mình hoặc sao chép liên kết tải xuống để gửi cho bạn bè.
            </p>

            {/* QR Card Mockup */}
            <div className="p-6 rounded-2xl bg-slate-900/40 border border-slate-900 flex flex-col sm:flex-row items-center gap-6">
              
              {/* Custom SVG QR Code Placeholder */}
              <div className="w-32 h-32 bg-white rounded-xl p-2.5 flex items-center justify-center shrink-0">
                <svg className="w-full h-full text-slate-950" viewBox="0 0 100 100" fill="currentColor">
                  {/* Outer boundaries */}
                  <rect x="0" y="0" width="25" height="25" />
                  <rect x="2" y="2" width="21" height="21" fill="white" />
                  <rect x="6" y="6" width="13" height="13" />

                  <rect x="75" y="0" width="25" height="25" />
                  <rect x="77" y="2" width="21" height="21" fill="white" />
                  <rect x="81" y="6" width="13" height="13" />

                  <rect x="0" y="75" width="25" height="25" />
                  <rect x="2" y="77" width="21" height="21" fill="white" />
                  <rect x="6" y="81" width="13" height="13" />
                  
                  {/* Random QR squares */}
                  <rect x="35" y="5" width="8" height="8" />
                  <rect x="50" y="0" width="12" height="6" />
                  <rect x="55" y="10" width="6" height="15" />
                  <rect x="35" y="20" width="10" height="8" />

                  <rect x="10" y="35" width="15" height="8" />
                  <rect x="0" y="50" width="6" height="18" />
                  <rect x="15" y="60" width="15" height="8" />

                  <rect x="80" y="35" width="10" height="12" />
                  <rect x="90" y="55" width="10" height="8" />
                  <rect x="75" y="68" width="12" height="5" />

                  <rect x="35" y="35" width="12" height="12" />
                  <rect x="52" y="35" width="15" height="15" />
                  <rect x="35" y="52" width="16" height="8" />
                  <rect x="42" y="68" width="18" height="12" />
                  <rect x="65" y="60" width="8" height="18" />
                  <rect x="60" y="85" width="12" height="10" />

                  <rect x="80" y="80" width="8" height="8" />
                  <rect x="90" y="90" width="8" height="8" />
                  <rect x="35" y="85" width="12" height="8" />
                </svg>
              </div>

              <div className="space-y-3 text-center sm:text-left">
                <div className="text-xs font-semibold text-purple-400 uppercase tracking-wider">Quét mã để tải nhanh</div>
                <p className="text-xs text-slate-400">
                  Sử dụng camera điện thoại hoặc ứng dụng quét mã QR để tải file APK về máy.
                </p>
                <button 
                  onClick={handleCopyLink}
                  className="text-xs font-semibold text-white hover:text-purple-400 transition-colors flex items-center gap-1.5 mx-auto sm:mx-0 py-1"
                >
                  {copied ? (
                    <>
                      <CheckCircle2 size={13} className="text-emerald-400" />
                      <span className="text-emerald-400">Đã sao chép link!</span>
                    </>
                  ) : (
                    <>
                      <Info size={13} />
                      <span>Sao chép link tải</span>
                    </>
                  )}
                </button>
              </div>

            </div>

            {/* Technical Specs Card */}
            <div className="p-6 rounded-2xl bg-slate-900/20 border border-slate-900 space-y-4">
              <h3 className="text-lg font-bold text-white flex items-center gap-2">
                <Info size={18} className="text-purple-400" />
                <span>Thông tin tệp APK</span>
              </h3>
              
              <div className="divide-y divide-slate-900 text-sm">
                <div className="py-2.5 flex justify-between">
                  <span className="text-slate-500">Tên gói (Package Name)</span>
                  <span className="font-mono text-slate-300 text-xs">com.learnex.app</span>
                </div>
                <div className="py-2.5 flex justify-between">
                  <span className="text-slate-500">Phiên bản (Version)</span>
                  <span className="text-slate-300">1.0.0 (Build 1)</span>
                </div>
                <div className="py-2.5 flex justify-between">
                  <span className="text-slate-500">Kích thước file</span>
                  <span className="text-slate-300">~24.5 MB</span>
                </div>
                <div className="py-2.5 flex justify-between">
                  <span className="text-slate-500">Yêu cầu hệ điều hành</span>
                  <span className="text-slate-300">Android 7.0 (Nougat, API 24) trở lên</span>
                </div>
                <div className="py-2.5 flex justify-between">
                  <span className="text-slate-500">Bảo mật</span>
                  <span className="text-emerald-400 flex items-center gap-1 text-xs">
                    <ShieldCheck size={14} /> Đã quét an toàn (Không virus/malware)
                  </span>
                </div>
              </div>
            </div>

          </div>

          {/* Right Column: Step-by-Step Installation Guide */}
          <div className="lg:col-span-7 p-8 rounded-3xl bg-slate-900/20 border border-slate-900 space-y-8">
            <h3 className="text-2xl font-bold text-white flex items-center gap-2.5">
              <ShieldAlert size={24} className="text-purple-400" />
              <span>Hướng dẫn cài đặt file APK trên Android</span>
            </h3>

            <p className="text-slate-400 text-sm leading-relaxed">
              Vì file APK được cài đặt trực tiếp bên ngoài Google Play Store, bạn cần thực hiện một vài bước cấu hình nhỏ trên điện thoại để hoàn tất cài đặt.
            </p>

            {/* Timeline Steps */}
            <div className="space-y-6 relative before:absolute before:left-5 before:top-2 before:bottom-2 before:w-[2px] before:bg-slate-900">
              
              {/* Step 1 */}
              <div className="relative pl-12">
                <div className="absolute left-0 top-0.5 w-10 h-10 rounded-xl bg-slate-900 border border-slate-800 flex items-center justify-center font-bold text-purple-400 shadow-md">
                  1
                </div>
                <h4 className="text-base font-bold text-white mb-1">Tải xuống file APK</h4>
                <p className="text-xs md:text-sm text-slate-400 leading-relaxed">
                  Bấm nút <strong>"Tải APK"</strong> ở đầu trang hoặc quét mã QR. Trình duyệt trên thiết bị Android sẽ hiển thị cảnh báo bảo mật tải file gây hại. Đừng lo lắng, hãy bấm <strong>"Vẫn tải xuống" (Download anyway)</strong>.
                </p>
              </div>

              {/* Step 2 */}
              <div className="relative pl-12">
                <div className="absolute left-0 top-0.5 w-10 h-10 rounded-xl bg-slate-900 border border-slate-800 flex items-center justify-center font-bold text-purple-400 shadow-md">
                  2
                </div>
                <h4 className="text-base font-bold text-white mb-1">Cho phép Cài đặt từ Nguồn không xác định</h4>
                <p className="text-xs md:text-sm text-slate-400 leading-relaxed">
                  Trước khi mở tệp, truy cập <strong>Cài đặt (Settings)</strong> &rarr; <strong>Bảo mật (Security)</strong> (hoặc Quyền riêng tư) &rarr; Tìm mục <strong>"Cài đặt ứng dụng không rõ nguồn gốc" (Install unknown apps)</strong> &rarr; Chọn trình duyệt của bạn (Chrome/Samsung Internet) và gạt bật <strong>"Cho phép từ nguồn này" (Allow from this source)</strong>.
                </p>
              </div>

              {/* Step 3 */}
              <div className="relative pl-12">
                <div className="absolute left-0 top-0.5 w-10 h-10 rounded-xl bg-slate-900 border border-slate-800 flex items-center justify-center font-bold text-purple-400 shadow-md">
                  3
                </div>
                <h4 className="text-base font-bold text-white mb-1">Tiến hành cài đặt và sử dụng</h4>
                <p className="text-xs md:text-sm text-slate-400 leading-relaxed">
                  Mở ứng dụng <strong>Quản lý tệp (Files)</strong> &rarr; Chọn thư mục <strong>Tải về (Downloads)</strong> &rarr; Nhấp chọn file <code>learnex.apk</code> &rarr; Chọn <strong>"Cài đặt" (Install)</strong>. Sau khi hoàn tất, bạn có thể mở ứng dụng Learnex ngay trên màn hình chính!
                </p>
              </div>

            </div>

            <div className="p-4 rounded-xl bg-amber-500/5 border border-amber-500/15 flex items-start gap-3">
              <ShieldAlert size={18} className="text-amber-400 shrink-0 mt-0.5" />
              <div className="text-xs text-amber-300 leading-relaxed">
                <strong>Chú ý:</strong> Đối với một số dòng máy Oppo, Realme, Xiaomi, hệ thống bảo mật quét virus cục bộ sẽ hiển thị cảnh báo khi cài đặt APK. Đây là thủ tục chuẩn của hãng, file APK Learnex hoàn toàn an toàn và đã được ký mã hóa đầy đủ.
              </div>
            </div>
          </div>

        </div>

      </main>

      {/* Footer */}
      <footer className="border-t border-slate-900 bg-slate-950 px-6 py-12 text-center text-xs text-slate-500 relative z-10">
        <div className="max-w-7xl mx-auto space-y-4">
          <div className="flex justify-center items-center gap-2">
            <span className="font-bold text-slate-400 tracking-tight">Learnex</span>
            <span className="text-slate-700">|</span>
            <span>Ứng dụng di động hỗ trợ học tập liên kết</span>
          </div>
          <p>
            &copy; {new Date().getFullYear()} Learnex Corp. Bảo lưu mọi quyền lợi.
          </p>
          <div className="flex justify-center gap-4 text-slate-400">
            <Link to="/login" className="hover:text-white transition-colors">Đăng nhập</Link>
            <span>&bull;</span>
            <Link to="/dashboard" className="hover:text-white transition-colors">Trang quản trị</Link>
          </div>
        </div>
      </footer>

    </div>
  );
}
