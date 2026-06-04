export const exportToCSV = (data: Record<string, unknown>[], filename: string) => {
  if (!data || !data.length) {
    alert('Không có dữ liệu để xuất');
    return;
  }

  // Lấy danh sách tiêu đề (keys) từ object đầu tiên
  // Chỉ lấy những field không phải là object lồng nhau (hoặc convert nó)
  const headers = Object.keys(data[0]);

  // Escape CSV function
  const escapeCSV = (val: unknown) => {
    if (val === null || val === undefined) return '';
    if (typeof val === 'object') {
      const obj = val as Record<string, unknown>;
      // Nếu là object lồng nhau, thử lấy .name hoặc .email hoặc stringify
      if (obj.name) return `"${String(obj.name).replace(/"/g, '""')}"`;
      if (obj.email) return `"${String(obj.email).replace(/"/g, '""')}"`;
      return `"${JSON.stringify(val).replace(/"/g, '""')}"`;
    }
    const str = String(val);
    if (str.includes(',') || str.includes('\n') || str.includes('"')) {
      return `"${str.replace(/"/g, '""')}"`;
    }
    return str;
  };

  // Tạo content CSV
  const csvContent = [
    headers.join(','),
    ...data.map(row => headers.map(fieldName => escapeCSV(row[fieldName])).join(','))
  ].join('\n');

  // Thêm BOM để Excel đọc đúng tiếng Việt UTF-8
  const BOM = '\uFEFF';
  const blob = new Blob([BOM + csvContent], { type: 'text/csv;charset=utf-8;' });
  
  // Kích hoạt tải xuống
  const link = document.createElement('a');
  if (link.download !== undefined) {
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', `${filename}_${new Date().toISOString().split('T')[0]}.csv`);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }
};
