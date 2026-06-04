import { useEffect, useState } from "react";
import { usersApi } from "../api/users.api";
import type { User } from "../types";
import PageHeader from "../components/ui/PageHeader";
import DataTable, { type Column } from "../components/ui/DataTable";
import SearchInput from "../components/ui/SearchInput";
import Pagination from "../components/ui/Pagination";
import StatusBadge from "../components/ui/StatusBadge";
import ConfirmModal from "../components/ui/ConfirmModal";
import UserModal from "../components/ui/UserModal";
import { useToast } from "../stores/toastStore";
import { Shield, ShieldAlert, Trash2, Edit2 } from "lucide-react";

export default function Users() {
  const { addToast } = useToast();
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [limit] = useState(10);
  const [search, setSearch] = useState("");

  // Modals state
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [banModalOpen, setBanModalOpen] = useState(false);
  const [unbanModalOpen, setUnbanModalOpen] = useState(false);
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [roleModalOpen, setRoleModalOpen] = useState(false);
  const [targetRole, setTargetRole] = useState<'admin' | 'user'>('user');
  const [actionLoading, setActionLoading] = useState(false);
  // Create / Edit modal state
  const [userModalOpen, setUserModalOpen] = useState(false);
  const [isEditMode, setIsEditMode] = useState(false);
  const [formData, setFormData] = useState({
    email: "",
    username: "",
    full_name: "",
    role: "user",
    password: "",
    // avatar can be a File (new upload) or a string URL (existing avatar)
    avatar: null as File | null | string,
  });
  const [formErrors, setFormErrors] = useState<Record<string, string>>({});

  const fetchUsers = async () => {
    setLoading(true);
    try {
      const res = await usersApi.getAll({ page, limit, search });
      setUsers(res.data);
      setTotal(res.total);
    } catch (err) {
      console.error("Không thể lấy danh sách người dùng:", err);
      addToast({
        type: "error",
        message: "Không thể tải danh sách người dùng",
      });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [page, search]);

  const handleExportCSV = async () => {
    try {
      // Lấy toàn bộ user để xuất thay vì chỉ trang hiện tại (tùy chỉnh limit lớn)
      const res = await usersApi.getAll({ page: 1, limit: 1000, search });
      
      const formatData = res.data.map(u => ({
        ID: u._id,
        Họ_Tên: u.name,
        Username: u.username,
        Email: u.email,
        Vai_trò: u.role,
        Trạng_thái: u.isBanned ? 'Bị khóa' : 'Hoạt động',
        Ngày_tham_gia: new Date(u.createdAt).toLocaleString('vi-VN')
      }));
      
      exportToCSV(formatData, 'Danh_sach_nguoi_dung');
    } catch (err) {
      console.error('Lỗi khi xuất file:', err);
      alert('Có lỗi xảy ra khi xuất dữ liệu.');
    }
  };

  const handleBan = async () => {
    if (!selectedUser) return;
    setActionLoading(true);
    try {
      await usersApi.ban(selectedUser._id);
      setBanModalOpen(false);
      fetchUsers();
      addToast({ type: "success", message: "Đã khóa tài khoản thành công" });
    } catch (err) {
      console.error("Banned error", err);
      addToast({ type: "error", message: "Khóa tài khoản thất bại" });
    } finally {
      setActionLoading(false);
    }
  };

  const handleUnban = async () => {
    if (!selectedUser) return;
    setActionLoading(true);
    try {
      await usersApi.unban(selectedUser._id);
      setUnbanModalOpen(false);
      fetchUsers();
      addToast({ type: "success", message: "Mở khóa tài khoản thành công" });
    } catch (err) {
      console.error("Unbanned error", err);
      addToast({ type: "error", message: "Mở khóa thất bại" });
    } finally {
      setActionLoading(false);
    }
  };

  const handleDelete = async () => {
    if (!selectedUser) return;
    setActionLoading(true);
    try {
      await usersApi.delete(selectedUser._id);
      setDeleteModalOpen(false);
      fetchUsers();
      addToast({ type: "success", message: "Người dùng đã được xóa" });
    } catch (err) {
      console.error("Delete error", err);
      addToast({ type: "error", message: "Xóa người dùng thất bại" });
    } finally {
      setActionLoading(false);
    }
  };

  const openCreateModal = () => {
    setIsEditMode(false);
    setFormData({
      email: "",
      username: "",
      full_name: "",
      role: "user",
      password: "",
      avatar: null,
    });
    setFormErrors({});
    setUserModalOpen(true);
  };

  const openEditModal = async (u: User) => {
    setIsEditMode(true);
    setFormErrors({});
    setActionLoading(true);
    try {
      const data = await usersApi.getById(u._id);
      setFormData({
        email: data.email || "",
        username: data.username || "",
        full_name: data.full_name || "",
        role: data.role || "user",
        password: "",
        avatar: data.avatar_url || null,
      });
      setUserModalOpen(true);
      setSelectedUser(u);
    } catch (err) {
      console.error("Fetch user failed", err);
      addToast({
        type: "error",
        message: "Không lấy được thông tin người dùng",
      });
    } finally {
      setActionLoading(false);
    }
  };

  const validateForm = () => {
    const errs: Record<string, string> = {};
    if (!formData.email || !formData.email.includes("@"))
      errs.email = "Email không hợp lệ";
    if (!formData.username || formData.username.length < 3)
      errs.username = "Username tối thiểu 3 ký tự";
    if (!formData.full_name) errs.full_name = "Họ và tên là bắt buộc";
    if (!isEditMode && (!formData.password || formData.password.length < 6))
      errs.password = "Mật khẩu tối thiểu 6 ký tự";
    setFormErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleSubmitUser = async () => {
    if (!validateForm()) return;
    setActionLoading(true);
    try {
      if (isEditMode && selectedUser) {
        // Only include avatar when it's a File (new upload). If it's a URL, backend will keep existing.
        const updatePayload: any = {
          email: formData.email,
          username: formData.username,
          full_name: formData.full_name,
          role: formData.role,
          password: formData.password,
        };
        if (formData.avatar instanceof File)
          updatePayload.avatar = formData.avatar;
        await usersApi.update(selectedUser._id, updatePayload);
        addToast({
          type: "success",
          message: "Cập nhật người dùng thành công",
        });
      } else {
        const createPayload: any = {
          email: formData.email,
          password: formData.password,
          full_name: formData.full_name,
          username: formData.username,
          role: formData.role,
        };
        if (formData.avatar instanceof File)
          createPayload.avatar = formData.avatar;
        await usersApi.create(createPayload);
        addToast({ type: "success", message: "Tạo người dùng thành công" });
      }
      setUserModalOpen(false);
      fetchUsers();
    } catch (err) {
      console.error("User submit error", err);
      addToast({ type: "error", message: "Thao tác không thành công" });
    } finally {
      setActionLoading(false);
    }
  };

  const handleRoleChange = async () => {
    if (!selectedUser) return;
    setActionLoading(true);
    try {
      await usersApi.updateRole(selectedUser._id, targetRole);
      setRoleModalOpen(false);
      fetchUsers();
    } catch (err) {
      console.error('Role update error', err);
    } finally {
      setActionLoading(false);
    }
  };

  const columns: Column<User>[] = [
    {
      key: "avatar",
      header: "Thành viên",
      render: (u) => (
        <div className="flex items-center gap-3">
          <div className="h-9 w-9 overflow-hidden rounded-full bg-gradient-to-br from-indigo-500 to-purple-600">
            {u.avatar ? (
              <img
                src={u.avatar}
                alt=""
                className="h-full w-full object-cover"
              />
            ) : (
              <div className="flex h-full w-full items-center justify-center text-xs font-bold text-white">
                {u.name?.charAt(0).toUpperCase()}
              </div>
            )}
          </div>
          <div>
            <p className="font-semibold text-slate-800">{u.name}</p>
            <p className="text-xs text-slate-500">{u.email}</p>
          </div>
        </div>
      ),
    },
    {
      key: "username",
      header: "Tên đăng nhập",
      render: (u) => <span className="text-slate-500">@{u.username}</span>,
    },
    {
      key: "role",
      header: "Vai trò",
      render: (u) => <StatusBadge status={u.role} />,
    },
    {
      key: "isBanned",
      header: "Trạng thái",
      render: (u) => (
        <StatusBadge
          status={u.isBanned ? "banned" : "active"}
          label={u.isBanned ? "Bị khóa" : "Đang hoạt động"}
        />
      ),
    },
    {
      key: "actions",
      header: "Hành động",
      className: "text-right",
      render: (u) => {
        return (
          <div className="flex justify-end gap-2.5">
            <button
              onClick={() => openEditModal(u)}
              className="flex h-8 w-8 items-center justify-center rounded-lg border border-slate-200/60 bg-white text-slate-600 transition-all duration-300 hover:scale-110 active:scale-95 hover:shadow-sm cursor-pointer"
              title="Chỉnh sửa"
            >
              <Edit2 className="h-4 w-4" />
            </button>
            {u.isBanned ? (
              <button
                onClick={() => {
                  setSelectedUser(u);
                  setUnbanModalOpen(true);
                }}
                className="flex h-8 w-8 items-center justify-center rounded-lg border border-emerald-200/60 bg-emerald-50/50 text-emerald-600 transition-all duration-300 hover:scale-110 active:scale-95 hover:bg-emerald-100 hover:border-emerald-300 hover:shadow-sm cursor-pointer"
                title="Mở khóa tài khoản"
              >
                <Shield className="h-4 w-4" />
              </button>
            ) : (
              <button
                onClick={() => {
                  setSelectedUser(u);
                  setBanModalOpen(true);
                }}
                className="flex h-8 w-8 items-center justify-center rounded-lg border border-amber-200/60 bg-amber-50/50 text-amber-600 transition-all duration-300 hover:scale-110 active:scale-95 hover:bg-amber-100 hover:border-amber-300 hover:shadow-sm cursor-pointer"
                title="Khóa tài khoản"
              >
                <ShieldAlert className="h-4 w-4" />
              </button>
            )}
            <button
              onClick={() => {
                setSelectedUser(u);
                setDeleteModalOpen(true);
              }}
              className="flex h-8 w-8 items-center justify-center rounded-lg border border-red-200/60 bg-red-50/50 text-red-600 transition-all duration-300 hover:scale-110 active:scale-95 hover:bg-red-100 hover:border-red-300 hover:shadow-sm cursor-pointer"
              title="Xóa vĩnh viễn"
            >
              <Trash2 className="h-4 w-4" />
            </button>
          </div>
        );
      },
    },
  ];

  return (
    <div className="space-y-8">
      <div className="flex flex-col gap-6 md:flex-row md:items-center md:justify-between">
        <PageHeader
          title="Quản lý thành viên"
          description="Kiểm duyệt và khóa/mở khóa tài khoản sinh viên"
        />
        <div className="flex items-center gap-3">
          <button
            onClick={openCreateModal}
            className="flex items-center gap-2 rounded-xl bg-gradient-to-r from-indigo-600 to-purple-600 px-5 py-2.5 text-sm font-bold text-white shadow-lg shadow-indigo-500/30 transition-all duration-300 hover:opacity-90 hover:-translate-y-0.5 hover:shadow-indigo-500/40 active:scale-95 cursor-pointer"
          >
            <span className="text-lg leading-none mb-0.5">+</span> Tạo thành viên mới
          </button>
        </div>
        <div className="w-full md:w-80">
          <SearchInput
            placeholder="Tìm theo tên, email..."
            value={search}
            onChange={(val) => {
              setSearch(val);
              setPage(1);
            }}
          />
        </div>
      </div>

      <div className="shadow-xl shadow-slate-200/40 rounded-2xl overflow-hidden border border-slate-200/60 bg-white">
        <DataTable
          columns={columns}
          data={users}
          keyExtractor={(u) => u._id}
          isLoading={loading}
          emptyMessage="Không tìm thấy người dùng nào."
        />
      </div>

      {total > limit && (
        <div className="flex justify-end pt-4">
          <Pagination
            currentPage={page}
            totalPages={Math.ceil(total / limit)}
            onPageChange={setPage}
          />
        </div>
      )}

      {/* Ban Confirm Modal */}
      <ConfirmModal
        open={banModalOpen}
        onCancel={() => setBanModalOpen(false)}
        onConfirm={handleBan}
        title="Khóa tài khoản"
        message={`Bạn có chắc muốn KHÓA tài khoản của ${selectedUser?.name}? Tài khoản này sẽ không thể đăng nhập hoặc tham gia phòng.`}
        confirmLabel="Khóa tài khoản"
        variant="danger"
        loading={actionLoading}
      />

      <UserModal
        open={userModalOpen}
        isEditMode={isEditMode}
        loading={actionLoading}
        data={formData}
        errors={formErrors}
        onClose={() => setUserModalOpen(false)}
        onChange={(patch) => setFormData({ ...formData, ...patch })}
        onSubmit={handleSubmitUser}
      />

      {/* Unban Confirm Modal */}
      <ConfirmModal
        open={unbanModalOpen}
        onCancel={() => setUnbanModalOpen(false)}
        onConfirm={handleUnban}
        title="Mở khóa tài khoản"
        message={`Bạn có chắc muốn MỞ KHÓA tài khoản của ${selectedUser?.name}?`}
        confirmLabel="Mở khóa"
        variant="info"
        loading={actionLoading}
      />

      {/* Delete Confirm Modal */}
      <ConfirmModal
        open={deleteModalOpen}
        onCancel={() => setDeleteModalOpen(false)}
        onConfirm={handleDelete}
        title="Xóa tài khoản"
        message={`Bạn có chắc muốn XÓA VĨNH VIỄN tài khoản của ${selectedUser?.name}? Hành động này KHÔNG THỂ khôi phục và sẽ xóa sạch mọi thông tin liên quan.`}
        confirmLabel="Xóa vĩnh viễn"
        variant="danger"
        loading={actionLoading}
      />

      {/* Role Change Modal */}
      <ConfirmModal
        open={roleModalOpen}
        onCancel={() => setRoleModalOpen(false)}
        onConfirm={handleRoleChange}
        title={targetRole === 'admin' ? "Cấp quyền Admin" : "Thu hồi quyền Admin"}
        message={targetRole === 'admin' 
          ? `Bạn có chắc muốn cấp quyền Quản trị viên (Admin) cho tài khoản ${selectedUser?.name}? Người này sẽ có toàn quyền kiểm duyệt bài viết và quản lý người dùng.`
          : `Bạn có chắc muốn hạ cấp tài khoản ${selectedUser?.name} xuống người dùng thường?`}
        confirmLabel={targetRole === 'admin' ? "Cấp quyền" : "Hạ quyền"}
        variant={targetRole === 'admin' ? "info" : "danger"}
        loading={actionLoading}
      />
    </div>
  );
}
