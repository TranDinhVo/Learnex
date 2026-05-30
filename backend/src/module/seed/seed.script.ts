import { db } from '@/config/database';
import bcrypt from 'bcryptjs';
import { v4 as uuidv4 } from 'uuid';

async function seed() {
  console.log('🌱 Bắt đầu nạp dữ liệu mẫu...');
  try {
    // Connect database & test connection
    await db.raw('SELECT 1');
    console.log('🔗 Đã kết nối cơ sở dữ liệu để seeding.');

    // 1. Dọn dẹp dữ liệu cũ (tuân thủ khóa ngoại)
    await db('room_messages').del();
    await db('room_members').del();
    await db('rooms').del();
    await db('direct_messages').del();
    await db('comments').del();
    await db('likes').del();
    await db('posts').del();
    await db('documents').del();
    await db('users').del();

    console.log('🧹 Đã xóa sạch dữ liệu cũ.');

    // 2. Hash mật khẩu dùng chung
    const passwordHash = await bcrypt.hash('123456', 10);

    // 3. Insert Users
    const users = [
      {
        id: uuidv4(),
        email: 'user1@learnex.edu.vn',
        password_hash: passwordHash,
        full_name: 'Trần Đăng Khoa',
        username: 'khoatran',
        school: 'Đại học Bách Khoa',
        major: 'Khoa học Máy tính',
        role: 'user',
        is_banned: false,
      },
      {
        id: uuidv4(),
        email: 'user2@learnex.edu.vn',
        password_hash: passwordHash,
        full_name: 'Nguyễn Minh Tuấn',
        username: 'tuannguyen',
        school: 'Đại học Khoa học Tự nhiên',
        major: 'Công nghệ Phần mềm',
        role: 'user',
        is_banned: false,
      },
      {
        id: uuidv4(),
        email: 'admin@learnex.edu.vn',
        password_hash: passwordHash,
        full_name: 'Admin Learnex',
        username: 'admin',
        school: 'Learnex System',
        major: 'Hệ thống Thông tin',
        role: 'admin',
        is_banned: false,
      },
    ];
    const insertedUsers = await db('users').insert(users).returning('*');
    console.log('✅ Đã nạp 3 người dùng mẫu.');

    // 4. Insert Posts
    const posts = [
      {
        id: uuidv4(),
        user_id: insertedUsers[0].id,
        content: 'Chào mừng các bạn sinh viên đến với cộng đồng học tập Learnex! Chúc mọi người học tập thật tốt 🚀.',
      },
      {
        id: uuidv4(),
        user_id: insertedUsers[1].id,
        content: 'Có bạn nào có tài liệu ôn thi cuối kỳ môn Cấu trúc dữ liệu và giải thuật không? Cho mình xin với!',
      },
    ];
    await db('posts').insert(posts);
    console.log('✅ Đã nạp 2 bài viết mẫu.');

    // 5. Insert Rooms
    const [room] = await db('rooms')
      .insert({
        id: uuidv4(),
        owner_id: insertedUsers[0].id,
        name: 'Nhóm học Toán Cao Cấp A1',
        description: 'Phòng tự học ôn thi giải bài tập Toán cao cấp cuối kỳ.',
        is_private: false,
      })
      .returning('*');

    // Add members
    await db('room_members').insert([
      { room_id: room.id, user_id: insertedUsers[0].id, role: 'owner' },
      { room_id: room.id, user_id: insertedUsers[1].id, role: 'member' },
    ]);

    console.log('✅ Đã nạp 1 phòng học nhóm mẫu.');
    console.log('🎉 Nạp dữ liệu mẫu hoàn tất thành công!');
  } catch (error) {
    console.error('❌ Lỗi khi nạp dữ liệu mẫu:', error);
  } finally {
    await db.destroy();
    process.exit();
  }
}

seed();
