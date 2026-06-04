import { useEffect, useState, useRef } from "react";
import { Camera, User as UserIcon, Mail, Lock, Shield, AtSign, X, Check } from "lucide-react";

interface Props {
  open: boolean;
  isEditMode?: boolean;
  loading?: boolean;
  data: {
    email: string;
    username: string;
    full_name: string;
    role: string;
    password?: string;
    avatar?: File | null | string;
  };
  errors?: Record<string, string>;
  onClose: () => void;
  onChange: (
    patch: Partial<{
      email: string;
      username: string;
      full_name: string;
      role: string;
      password?: string;
      avatar?: File | null | string;
    }>,
  ) => void;
  onSubmit: () => void;
}

export default function UserModal({
  open,
  isEditMode = false,
  loading = false,
  data,
  errors = {},
  onClose,
  onChange,
  onSubmit,
}: Props) {
  const [preview, setPreview] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (!open) {
      setPreview(null);
      return;
    }
    if (!data) return;

    if (data.avatar instanceof File) {
      const url = URL.createObjectURL(data.avatar);
      setPreview(url);
      return () => URL.revokeObjectURL(url);
    }
    if (typeof data.avatar === "string" && data.avatar) {
      setPreview(data.avatar);
      return;
    }
    setPreview(null);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [data?.avatar, open]);

  if (!open) return null;

  const getInitials = (name: string) => name ? name.charAt(0).toUpperCase() : "U";

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-0">
      <div 
        className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm transition-opacity" 
        onClick={onClose} 
      />
      
      <div className="relative z-10 w-full max-w-2xl bg-white shadow-2xl rounded-3xl overflow-hidden animate-in fade-in zoom-in-95 duration-200">
        {/* Header */}
        <div className="flex items-center justify-between px-8 py-6 border-b border-slate-100 bg-slate-50/50">
          <div>
            <h2 className="text-xl font-bold text-slate-800">
              {isEditMode ? "Chỉnh sửa tài khoản" : "Tạo thành viên mới"}
            </h2>
            <p className="text-sm text-slate-500 mt-1">
              {isEditMode ? "Cập nhật thông tin và vai trò" : "Thêm một người dùng mới vào hệ thống"}
            </p>
          </div>
          <button 
            onClick={onClose}
            className="p-2 rounded-full hover:bg-slate-200/50 text-slate-500 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="p-8">
          {/* Avatar Upload Section */}
          <div className="flex flex-col items-center mb-8">
            <div className="relative group cursor-pointer" onClick={() => fileInputRef.current?.click()}>
              <div className="w-28 h-28 rounded-full bg-gradient-to-tr from-indigo-100 to-purple-50 p-1 shadow-inner">
                <div className="w-full h-full rounded-full overflow-hidden bg-white flex items-center justify-center relative">
                  {preview ? (
                    <img src={preview} alt="avatar" className="w-full h-full object-cover" />
                  ) : (
                    <span className="text-4xl font-bold text-indigo-300">
                      {getInitials(data.full_name)}
                    </span>
                  )}
                  {/* Hover Overlay */}
                  <div className="absolute inset-0 bg-slate-900/40 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity duration-200">
                    <Camera className="w-8 h-8 text-white" />
                  </div>
                </div>
              </div>
              <input 
                type="file" 
                ref={fileInputRef}
                className="hidden" 
                accept="image/*"
                onChange={(e) => {
                  if (e.target.files && e.target.files[0]) {
                    onChange({ avatar: e.target.files[0] });
                  }
                }}
              />
            </div>
            
            <div className="mt-4 flex items-center gap-3">
              <button 
                type="button"
                onClick={() => fileInputRef.current?.click()}
                className="text-sm font-semibold text-indigo-600 hover:text-indigo-700 transition-colors"
              >
                Tải ảnh lên
              </button>
              {data.avatar && (
                <>
                  <span className="w-1 h-1 rounded-full bg-slate-300"></span>
                  <button 
                    type="button"
                    onClick={() => {
                      if (fileInputRef.current) fileInputRef.current.value = '';
                      onChange({ avatar: null });
                    }}
                    className="text-sm font-medium text-red-500 hover:text-red-600 transition-colors"
                  >
                    Xóa ảnh
                  </button>
                </>
              )}
            </div>
          </div>

          {/* Form Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-6">
            
            {/* Cột 1: Thông tin cá nhân */}
            <div className="space-y-6">
              <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-2 border-b border-slate-100 pb-2">
                Thông tin cá nhân
              </h3>
              
              <div>
                <label className="block text-sm font-semibold text-slate-700 mb-1.5">Họ và tên</label>
                <div className="relative group">
                  <UserIcon className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 group-focus-within:text-indigo-500 transition-colors" />
                  <input
                    value={data.full_name}
                    onChange={(e) => onChange({ full_name: e.target.value })}
                    placeholder="Nhập họ và tên..."
                    className={`w-full pl-10 pr-4 py-2.5 rounded-xl border ${errors.full_name ? 'border-red-300 bg-red-50/30 focus:ring-red-500/20 focus:border-red-500' : 'border-slate-200 bg-slate-50/50 focus:bg-white focus:border-indigo-500 focus:ring-4 focus:ring-indigo-500/10'} text-sm transition-all outline-none`}
                  />
                </div>
                {errors.full_name && <p className="mt-1.5 text-xs font-medium text-red-500 animate-in slide-in-from-top-1">{errors.full_name}</p>}
              </div>

              <div>
                <label className="block text-sm font-semibold text-slate-700 mb-1.5">Địa chỉ Email</label>
                <div className="relative group">
                  <Mail className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 group-focus-within:text-indigo-500 transition-colors" />
                  <input
                    value={data.email}
                    onChange={(e) => onChange({ email: e.target.value })}
                    placeholder="example@gmail.com"
                    className={`w-full pl-10 pr-4 py-2.5 rounded-xl border ${errors.email ? 'border-red-300 bg-red-50/30 focus:ring-red-500/20 focus:border-red-500' : 'border-slate-200 bg-slate-50/50 focus:bg-white focus:border-indigo-500 focus:ring-4 focus:ring-indigo-500/10'} text-sm transition-all outline-none`}
                  />
                </div>
                {errors.email && <p className="mt-1.5 text-xs font-medium text-red-500 animate-in slide-in-from-top-1">{errors.email}</p>}
              </div>
            </div>

            {/* Cột 2: Thông tin tài khoản */}
            <div className="space-y-6">
              <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-2 border-b border-slate-100 pb-2">
                Tài khoản
              </h3>

              <div>
                <label className="block text-sm font-semibold text-slate-700 mb-1.5">Tên đăng nhập</label>
                <div className="relative group">
                  <AtSign className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 group-focus-within:text-indigo-500 transition-colors" />
                  <input
                    value={data.username}
                    onChange={(e) => onChange({ username: e.target.value })}
                    placeholder="Nhập username..."
                    className={`w-full pl-10 pr-4 py-2.5 rounded-xl border ${errors.username ? 'border-red-300 bg-red-50/30 focus:ring-red-500/20 focus:border-red-500' : 'border-slate-200 bg-slate-50/50 focus:bg-white focus:border-indigo-500 focus:ring-4 focus:ring-indigo-500/10'} text-sm transition-all outline-none`}
                  />
                </div>
                {errors.username && <p className="mt-1.5 text-xs font-medium text-red-500 animate-in slide-in-from-top-1">{errors.username}</p>}
              </div>

              {!isEditMode && (
                <div>
                  <label className="block text-sm font-semibold text-slate-700 mb-1.5">Mật khẩu</label>
                  <div className="relative group">
                    <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 group-focus-within:text-indigo-500 transition-colors" />
                    <input
                      type="password"
                      value={data.password || ""}
                      onChange={(e) => onChange({ password: e.target.value })}
                      placeholder="Tối thiểu 6 ký tự"
                      className={`w-full pl-10 pr-4 py-2.5 rounded-xl border ${errors.password ? 'border-red-300 bg-red-50/30 focus:ring-red-500/20 focus:border-red-500' : 'border-slate-200 bg-slate-50/50 focus:bg-white focus:border-indigo-500 focus:ring-4 focus:ring-indigo-500/10'} text-sm transition-all outline-none`}
                    />
                  </div>
                  {errors.password && <p className="mt-1.5 text-xs font-medium text-red-500 animate-in slide-in-from-top-1">{errors.password}</p>}
                </div>
              )}

              <div>
                <label className="block text-sm font-semibold text-slate-700 mb-1.5">Phân quyền Vai trò</label>
                <div className="relative group">
                  <Shield className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 group-focus-within:text-indigo-500 transition-colors" />
                  <select
                    value={data.role}
                    onChange={(e) => onChange({ role: e.target.value })}
                    className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-slate-200 bg-slate-50/50 focus:bg-white focus:border-indigo-500 focus:ring-4 focus:ring-indigo-500/10 text-sm font-medium transition-all outline-none appearance-none cursor-pointer"
                  >
                    <option value="user">Thành viên (User)</option>
                    <option value="admin">Quản trị viên (Admin)</option>
                  </select>
                  {/* Custom Arrow */}
                  <div className="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-slate-400">
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7"></path></svg>
                  </div>
                </div>
              </div>

            </div>
          </div>
        </div>

        {/* Footer Actions */}
        <div className="px-8 py-5 border-t border-slate-100 bg-slate-50 flex items-center justify-end gap-3">
          <button
            onClick={onClose}
            className="px-5 py-2.5 rounded-xl text-sm font-semibold text-slate-600 hover:bg-slate-200/60 transition-colors cursor-pointer"
          >
            Hủy bỏ
          </button>
          <button
            onClick={onSubmit}
            disabled={loading}
            className="flex items-center gap-2 px-6 py-2.5 rounded-xl bg-indigo-600 text-sm font-bold text-white hover:bg-indigo-700 hover:shadow-lg hover:shadow-indigo-500/30 transition-all disabled:opacity-50 disabled:cursor-not-allowed active:scale-95 cursor-pointer"
          >
            {loading ? (
              <span className="w-4 h-4 border-2 border-white/20 border-t-white rounded-full animate-spin"></span>
            ) : (
              <Check className="w-4 h-4" />
            )}
            <span>{isEditMode ? "Lưu cập nhật" : "Tạo thành viên"}</span>
          </button>
        </div>
      </div>
    </div>
  );
}
