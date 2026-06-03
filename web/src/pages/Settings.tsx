import { useEffect, useState } from 'react';
import { settingsApi, type SystemSetting } from '../api/settings.api';
import PageHeader from '../components/ui/PageHeader';
import { Settings as SettingsIcon, Save, Loader2, ShieldAlert } from 'lucide-react';
import clsx from 'clsx';

export default function Settings() {
  const [, setSettings] = useState<SystemSetting[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Local state for toggles
  const [localValues, setLocalValues] = useState<Record<string, boolean>>({});

  const fetchSettings = async () => {
    setLoading(true);
    try {
      const data = await settingsApi.getAll();
      setSettings(data);
      
      const values: Record<string, boolean> = {};
      data.forEach(s => {
        values[s.key] = s.value === 'true';
      });
      setLocalValues(values);
    } catch (err) {
      console.error('Không thể lấy cài đặt:', err);
      setError('Lỗi khi tải cài đặt hệ thống.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchSettings();
  }, []);

  const handleToggle = (key: string) => {
    setLocalValues(prev => ({
      ...prev,
      [key]: !prev[key]
    }));
  };

  const handleSave = async () => {
    setSaving(true);
    setError(null);
    try {
      const updates = Object.keys(localValues).map(key => ({
        key,
        value: localValues[key] ? 'true' : 'false'
      }));
      
      const updated = await settingsApi.update(updates);
      setSettings(updated);
      alert('Đã lưu cấu hình thành công!');
    } catch (err) {
      console.error('Lỗi khi lưu cài đặt:', err);
      setError('Lỗi khi lưu cài đặt hệ thống.');
    } finally {
      setSaving(false);
    }
  };

  const renderSettingRow = (key: string, title: string, subtitle: string, warning: boolean = false) => {
    const isChecked = localValues[key] || false;
    
    return (
      <div className="flex items-center justify-between py-5 border-b border-slate-100 last:border-0">
        <div className="flex flex-col max-w-xl">
          <span className="text-sm font-bold text-slate-800 flex items-center gap-2">
            {title}
            {warning && isChecked && (
              <ShieldAlert className="h-4 w-4 text-red-500" />
            )}
          </span>
          <span className="text-sm text-slate-500 mt-1">{subtitle}</span>
        </div>
        
        <button
          onClick={() => handleToggle(key)}
          className={clsx(
            "relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-indigo-600 focus:ring-offset-2",
            isChecked ? (warning ? "bg-red-500" : "bg-indigo-600") : "bg-slate-200"
          )}
        >
          <span
            className={clsx(
              "pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out",
              isChecked ? "translate-x-5" : "translate-x-0"
            )}
          />
        </button>
      </div>
    );
  };

  if (loading) {
    return (
      <div className="flex h-[60vh] items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-indigo-500" />
      </div>
    );
  }

  return (
    <div className="space-y-6 max-w-4xl mx-auto">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <PageHeader 
          title="Cài đặt hệ thống" 
          description="Cấu hình các thông số hoạt động chung của ứng dụng LearnEx." 
        />
        
        <button
          onClick={handleSave}
          disabled={saving}
          className="flex items-center justify-center gap-2 rounded-xl bg-indigo-600 px-5 py-2.5 text-sm font-semibold text-white transition-all hover:bg-indigo-700 disabled:opacity-70 disabled:cursor-not-allowed"
        >
          {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
          Lưu thay đổi
        </button>
      </div>

      {error && (
        <div className="p-4 bg-red-50 border border-red-200 rounded-xl text-red-600 text-sm font-medium">
          {error}
        </div>
      )}

      <div className="bg-white rounded-2xl shadow-sm border border-slate-200/60 p-6 sm:p-8">
        <div className="flex items-center gap-3 mb-6 pb-6 border-b border-slate-100">
          <div className="h-10 w-10 bg-indigo-50 text-indigo-600 rounded-lg flex items-center justify-center">
            <SettingsIcon className="h-5 w-5" />
          </div>
          <div>
            <h2 className="text-lg font-bold text-slate-800">Cấu hình chung</h2>
            <p className="text-sm text-slate-500">Các tùy chọn này ảnh hưởng trực tiếp đến toàn bộ người dùng.</p>
          </div>
        </div>

        <div className="space-y-2">
          {renderSettingRow(
            'maintenance_mode', 
            'Chế độ bảo trì hệ thống', 
            'Khi bật, tất cả sinh viên sẽ không thể đăng nhập hoặc sử dụng ứng dụng. Chỉ hiển thị màn hình bảo trì. Dùng khi cần nâng cấp server.',
            true
          )}
          
          {renderSettingRow(
            'allow_registrations', 
            'Cho phép đăng ký tài khoản mới', 
            'Cho phép người dùng mới tạo tài khoản. Tắt tùy chọn này khi hệ thống đang bị spam tài khoản rác.'
          )}
          
          {renderSettingRow(
            'auto_approve_documents', 
            'Tự động duyệt tài liệu', 
            'Bỏ qua bước duyệt của Quản trị viên. Các tài liệu do sinh viên tải lên sẽ lập tức được hiển thị công khai.'
          )}
        </div>
      </div>
    </div>
  );
}
