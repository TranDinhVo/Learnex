import { useState } from "react";
import { NavLink, Outlet, useNavigate } from "react-router-dom";
import {
  LayoutDashboard,
  Users,
  FileText,
  FolderOpen,
  MessageSquare,
  Bell,
  LogOut,
  Menu,
  ChevronLeft,
  GraduationCap,
} from "lucide-react";
import clsx from "clsx";
import { useAuthStore } from "../../stores/authStore";
import ToastContainer from "../ui/ToastContainer";

const navItems = [
  { to: "/dashboard", icon: LayoutDashboard, label: "Tổng quan" },
  { to: "/users", icon: Users, label: "Người dùng" },
  { to: "/posts", icon: FileText, label: "Bài viết" },
  { to: "/documents", icon: FolderOpen, label: "Tài liệu" },
  { to: "/rooms", icon: MessageSquare, label: "Phòng học" },
  { to: "/notifications", icon: Bell, label: "Thông báo" },
];

export default function AdminLayout() {
  const [collapsed, setCollapsed] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);
  const { user, logout } = useAuthStore();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate("/login");
  };
  const SidebarContent = () => (
    <div className="flex h-full flex-col bg-white">
      {/* Logo */}
      <div className="flex h-16 items-center gap-3 border-b border-slate-100 px-5">
        <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-indigo-500 to-purple-600 shadow-md shadow-indigo-500/10">
          <GraduationCap className="h-5 w-5 text-white" />
        </div>
        {!collapsed && (
          <span className="text-lg font-bold tracking-tight text-slate-800">
            Learnex{" "}
            <span className="text-xs font-semibold text-indigo-600">Admin</span>
          </span>
        )}
      </div>

      {/* Navigation */}
      <nav className="flex-1 space-y-1 overflow-y-auto px-3 py-4">
        {navItems.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            onClick={() => setMobileOpen(false)}
            className={({ isActive }) =>
              clsx(
                "group flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-semibold transition-all duration-300 border border-transparent",
                collapsed && "justify-center",
                isActive
                  ? "bg-gradient-to-r from-indigo-500/10 to-purple-500/10 text-indigo-700 shadow-sm border-indigo-500/10"
                  : "text-slate-600 hover:bg-slate-50 hover:text-slate-900",
              )
            }
          >
            {({ isActive }) => (
              <>
                <item.icon
                  className={clsx(
                    "h-5 w-5 shrink-0 transition-colors",
                    isActive
                      ? "text-indigo-600"
                      : "text-slate-400 group-hover:text-slate-600",
                  )}
                />
                {!collapsed && <span>{item.label}</span>}
                {isActive && !collapsed && (
                  <div className="ml-auto h-1.5 w-1.5 rounded-full bg-indigo-500" />
                )}
              </>
            )}
          </NavLink>
        ))}
      </nav>

      {/* User section */}
      <div className="border-t border-slate-100 p-3">
        {!collapsed && user && (
          <div className="mb-3 rounded-xl bg-slate-50 px-3 py-2.5">
            <p className="truncate text-sm font-bold text-slate-800">
              {user.name}
            </p>
            <p className="truncate text-xs text-slate-500">{user.email}</p>
          </div>
        )}
        <button
          onClick={handleLogout}
          className={clsx(
            "flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium text-slate-600 transition-all hover:bg-red-50 hover:text-red-600 cursor-pointer",
            collapsed && "justify-center",
          )}
        >
          <LogOut className="h-5 w-5 shrink-0" />
          {!collapsed && <span>Đăng xuất</span>}
        </button>
      </div>
    </div>
  );
  return (
    <div className="flex h-screen bg-[#f8fafc]">
      {/* Desktop sidebar */}
      <aside
        className={clsx(
          "hidden flex-col border-r border-slate-200/80 bg-white/70 backdrop-blur-2xl transition-all duration-300 lg:flex",
          collapsed ? "w-[72px]" : "w-64",
        )}
      >
        <SidebarContent />
        <button
          onClick={() => setCollapsed(!collapsed)}
          className="absolute -right-3 top-20 z-10 hidden h-6 w-6 items-center justify-center rounded-full border border-slate-200 bg-white text-slate-400 shadow-sm transition-colors hover:text-slate-600 lg:flex cursor-pointer"
        >
          <ChevronLeft
            className={clsx(
              "h-3.5 w-3.5 transition-transform",
              collapsed && "rotate-180",
            )}
          />
        </button>
      </aside>

      {/* Mobile sidebar overlay */}
      {mobileOpen && (
        <div className="fixed inset-0 z-40 lg:hidden">
          <div
            className="absolute inset-0 bg-black/40 backdrop-blur-sm"
            onClick={() => setMobileOpen(false)}
          />
          <aside className="relative z-50 flex h-full w-64 flex-col border-r border-slate-200 bg-white">
            <SidebarContent />
          </aside>
        </div>
      )}

      {/* Main */}
      <div className="flex flex-1 flex-col overflow-hidden">
        {/* Top bar */}
        <header className="flex h-16 items-center gap-4 border-b border-slate-100 bg-white/40 px-4 backdrop-blur-xl lg:px-8">
          <button
            onClick={() => setMobileOpen(true)}
            className="text-slate-500 hover:text-slate-800 lg:hidden"
          >
            <Menu className="h-6 w-6" />
          </button>

          <div className="flex-1" />

          <div className="flex items-center gap-3">
            <div className="hidden items-center gap-2 sm:flex">
              <div className="h-8 w-8 overflow-hidden rounded-full bg-gradient-to-br from-indigo-500 to-purple-600">
                {user?.avatar ? (
                  <img
                    src={user.avatar}
                    alt=""
                    className="h-full w-full object-cover"
                  />
                ) : (
                  <div className="flex h-full w-full items-center justify-center text-xs font-bold text-white">
                    {(user?.name || "U").charAt(0).toUpperCase()}
                  </div>
                )}
              </div>
              <span className="text-sm font-semibold text-slate-700">
                {user?.name}
              </span>
            </div>
          </div>
        </header>

        {/* Content */}
        <main className="flex-1 overflow-y-auto bg-[#f8fafc] p-4 lg:p-8">
          <Outlet />
          <ToastContainer />
        </main>
      </div>
    </div>
  );
}
