import { db } from "../config/database";
import bcrypt from "bcryptjs";
import { v4 as uuidv4 } from "uuid";

async function seed() {
  console.log("🌱 Bắt đầu nạp dữ liệu mẫu Demo (Production-like)...");
  try {
    await db.raw("SELECT 1");
    console.log("🔗 Đã kết nối cơ sở dữ liệu để seeding.");

    // 1. Dọn dẹp dữ liệu cũ theo thứ tự ràng buộc khóa ngoại (Foreign Keys)
    console.log("🧹 Đang dọn dẹp dữ liệu cũ...");
    await db("story_reactions").del();
    await db("story_views").del();
    await db("stories").del();
    await db("room_messages").del();
    await db("room_members").del();
    await db("rooms").del();
    await db("direct_messages").del();
    await db("comments").del();
    await db("likes").del();
    await db("saved_documents").del();
    await db("posts").del();
    await db("documents").del();
    await db("friendships").del();
    await db("notifications").del();
    await db("users").del();
    console.log("✅ Dọn dẹp hoàn tất.");

    // 2. Hash mật khẩu chung
    const passwordHash = await bcrypt.hash("123456", 10);

    // 3. Nạp danh sách Users
    const users = [
      {
        id: uuidv4(),
        email: "user1@learnex.edu.vn",
        password_hash: passwordHash,
        full_name: "Trần Đăng Khoa",
        username: "khoatran",
        school: "Đại học Bách Khoa",
        major: "Khoa học Máy tính",
        role: "user",
        avatar_url: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80",
        bio: "Đam mê code dạo và thuật toán 💻",
        is_banned: false,
      },
      {
        id: uuidv4(),
        email: "user2@learnex.edu.vn",
        password_hash: passwordHash,
        full_name: "Nguyễn Minh Tuấn",
        username: "tuannguyen",
        school: "Đại học Khoa học Tự nhiên",
        major: "Công nghệ Phần mềm",
        role: "user",
        avatar_url: "https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&w=150&q=80",
        bio: "Life is short, use Python 🐍",
        is_banned: false,
      },
      {
        id: uuidv4(),
        email: "mai.le@learnex.edu.vn",
        password_hash: passwordHash,
        full_name: "Lê Ngọc Mai",
        username: "ngocmai",
        school: "Đại học Ngoại Thương",
        major: "Kinh tế quốc tế",
        role: "user",
        avatar_url: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=150&q=80",
        bio: "Học ngoại ngữ và khởi nghiệp 🚀",
        is_banned: false,
      },
      {
        id: uuidv4(),
        email: "hoang.pham@learnex.edu.vn",
        password_hash: passwordHash,
        full_name: "Phạm Việt Hoàng",
        username: "hoangpv",
        school: "Đại học Bách Khoa",
        major: "Điện tử viễn thông",
        role: "user",
        avatar_url: "https://images.unsplash.com/photo-1527980965255-d3b416303d12?auto=format&fit=crop&w=150&q=80",
        bio: "Looking for an IoT project team ⚡",
        is_banned: false,
      },
      {
        id: uuidv4(),
        email: "thuy.duong@learnex.edu.vn",
        password_hash: passwordHash,
        full_name: "Trần Thùy Dương",
        username: "thuyduong99",
        school: "Đại học Sư phạm",
        major: "Sư phạm Toán học",
        role: "user",
        avatar_url: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&w=150&q=80",
        bio: "Chia sẻ tài liệu học Toán Cao Cấp miễn phí 📚",
        is_banned: false,
      },
      {
        id: uuidv4(),
        email: "admin@learnex.edu.vn",
        password_hash: passwordHash,
        full_name: "Learnex Admin",
        username: "admin",
        school: "Learnex Team",
        major: "Hệ thống Thông tin",
        role: "admin",
        avatar_url: "https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&w=150&q=80",
        bio: "Quản trị viên hệ thống Learnex 🛡️",
        is_banned: false,
      },
    ];

    const insertedUsers = await db("users").insert(users).returning("*");
    console.log(`✅ Đã nạp ${insertedUsers.length} tài khoản người dùng.`);

    // Map by username to access easier
    const userMap: Record<string, any> = {};
    for (const u of insertedUsers) {
      userMap[u.username] = u;
    }

    // 4. Kết bạn (Friendships)
    const friendships = [
      { requester_id: userMap["khoatran"].id, addressee_id: userMap["tuannguyen"].id, status: "accepted" },
      { requester_id: userMap["khoatran"].id, addressee_id: userMap["ngocmai"].id, status: "accepted" },
      { requester_id: userMap["tuannguyen"].id, addressee_id: userMap["hoangpv"].id, status: "accepted" },
      { requester_id: userMap["thuyduong99"].id, addressee_id: userMap["khoatran"].id, status: "accepted" },
      { requester_id: userMap["ngocmai"].id, addressee_id: userMap["tuannguyen"].id, status: "pending" }, // Pending request
    ];
    await db("friendships").insert(friendships);
    console.log("✅ Đã kết nối các mối quan hệ bạn bè.");

    // 5. Nạp Bài Viết (Posts)
    const posts = [
      {
        id: uuidv4(),
        user_id: userMap["khoatran"].id,
        content: "Cuối cùng cũng xong môn Hệ Điều Hành! Có bạn nào khóa dưới cần xin tài liệu thực hành C/C++ không, comment email nhé mình share thư mục Drive cho! 🔥",
        image_urls: JSON.stringify(["https://images.unsplash.com/photo-1555066931-4365d14bab8c?auto=format&fit=crop&w=800&q=80"]),
        visibility: "public",
      },
      {
        id: uuidv4(),
        user_id: userMap["thuyduong99"].id,
        content: "Review nhanh đề thi Giải Tích 2 sáng nay:\n- Đề 5 câu, 2 câu khó nằm ở phần tích phân bội 3 và vi phân toàn phần.\n- Mọi người nhớ ôn kỹ định lý Gauss-Ostrogradsky nhé, chắc chắn sẽ có 1 câu.\nChúc các bạn thi ca sau may mắn! 🍀",
        image_urls: null,
        visibility: "public",
      },
      {
        id: uuidv4(),
        user_id: userMap["ngocmai"].id,
        content: "Tuần sau nhóm mình có buổi thảo luận môn Kinh tế vĩ mô. Có ai muốn lập team chạy deadline cùng không ạ? Cần tuyển 1 bạn giỏi làm slide! 🥺",
        image_urls: JSON.stringify(["https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=800&q=80"]),
        visibility: "friends", // Only friends
      },
      {
        id: uuidv4(),
        user_id: userMap["admin"].id,
        content: "🎉 [THÔNG BÁO] Hệ thống Learnex chính thức ra mắt tính năng Story mới!\n\nTừ hôm nay các bạn có thể chia sẻ khoảnh khắc học tập dưới dạng Ảnh hoặc Video ngắn tự biến mất sau 12h. Cùng trải nghiệm nhé!",
        image_urls: JSON.stringify(["https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=800&q=80"]),
        visibility: "public",
      }
    ];
    const insertedPosts = await db("posts").insert(posts).returning("*");
    console.log("✅ Đã nạp dữ liệu bài viết (Posts).");

    // 6. Nạp Comments & Likes
    const comments = [
      { post_id: insertedPosts[0].id, user_id: userMap["tuannguyen"].id, content: "Cho mình xin với bạn ơi, email: tuannguyen@gmail.com" },
      { post_id: insertedPosts[0].id, user_id: userMap["hoangpv"].id, content: "Đỉnh quá Khoa ơi 👏" },
      { post_id: insertedPosts[1].id, user_id: userMap["khoatran"].id, content: "Đề năm nay khó hơn năm ngoái nhiều không cậu?" },
      { post_id: insertedPosts[2].id, user_id: userMap["thuyduong99"].id, content: "Mình đăng ký làm slide nhé, nhắn tin cho mình đi!" },
    ];
    await db("comments").insert(comments);
    
    const likes = [
      { post_id: insertedPosts[0].id, user_id: userMap["tuannguyen"].id },
      { post_id: insertedPosts[0].id, user_id: userMap["hoangpv"].id },
      { post_id: insertedPosts[0].id, user_id: userMap["ngocmai"].id },
      { post_id: insertedPosts[1].id, user_id: userMap["khoatran"].id },
      { post_id: insertedPosts[1].id, user_id: userMap["tuannguyen"].id },
      { post_id: insertedPosts[3].id, user_id: userMap["khoatran"].id },
      { post_id: insertedPosts[3].id, user_id: userMap["thuyduong99"].id },
    ];
    await db("likes").insert(likes);
    console.log("✅ Đã nạp tương tác (Comments & Likes).");

    // 7. Nạp Rooms (Nhóm học)
    const [room1] = await db("rooms").insert({
      id: uuidv4(),
      owner_id: userMap["khoatran"].id,
      name: "Tự học Cấu trúc dữ liệu & Giải thuật",
      description: "Nhóm lập ra để cùng nhau cày Leetcode và bài tập DSA thầy Hùng. Online vào 20h mỗi tối thứ 3-5-7.",
      privacy_mode: "public",
      avatar_url: "https://images.unsplash.com/photo-1542831371-29b0f74f9713?auto=format&fit=crop&w=200&q=80"
    }).returning("*");

    const [room2] = await db("rooms").insert({
      id: uuidv4(),
      owner_id: userMap["thuyduong99"].id,
      name: "CLB Tiếng Anh Giao Tiếp",
      description: "Môi trường thực hành speaking 100% bằng tiếng Anh.",
      privacy_mode: "public",
      avatar_url: "https://images.unsplash.com/photo-1574880521406-8dce4fbfa1b9?auto=format&fit=crop&w=200&q=80"
    }).returning("*");

    await db("room_members").insert([
      { room_id: room1.id, user_id: userMap["khoatran"].id, role: "owner" },
      { room_id: room1.id, user_id: userMap["tuannguyen"].id, role: "moderator" },
      { room_id: room1.id, user_id: userMap["hoangpv"].id, role: "member" },
      { room_id: room2.id, user_id: userMap["thuyduong99"].id, role: "owner" },
      { room_id: room2.id, user_id: userMap["ngocmai"].id, role: "member" },
    ]);
    
    // Add some room messages
    await db("room_messages").insert([
      { room_id: room1.id, sender_id: userMap["khoatran"].id, content: "Tối nay mọi người có ai bận không? Mình định giải đề Leetcode Array." },
      { room_id: room1.id, sender_id: userMap["tuannguyen"].id, content: "Triển luôn đi ông, tôi đang rảnh." },
      { room_id: room2.id, sender_id: userMap["thuyduong99"].id, content: "Hi everyone! Our topic tonight is 'Technology impact on Gen Z'." },
    ]);
    console.log("✅ Đã nạp Phòng học nhóm (Rooms) và tin nhắn.");

    // 8. Nạp Stories
    const stories = [
      {
        id: uuidv4(),
        user_id: userMap["ngocmai"].id,
        media_type: "text",
        text_content: "Trời mưa buồn ngủ quá... ☕",
        bg_gradient: '["#FF9A9E", "#FECFEF"]',
        visibility: "friends",
        created_at: new Date(),
        expires_at: new Date(Date.now() + 12 * 3600 * 1000)
      },
      {
        id: uuidv4(),
        user_id: userMap["khoatran"].id,
        media_type: "image",
        media_url: "https://images.unsplash.com/photo-1517694712202-14dd9538aa97?auto=format&fit=crop&w=800&q=80",
        visibility: "public",
        created_at: new Date(Date.now() - 2 * 3600 * 1000), // 2 hours ago
        expires_at: new Date(Date.now() + 10 * 3600 * 1000)
      }
    ];
    await db("stories").insert(stories);
    console.log("✅ Đã nạp bảng tin ngắn (Stories).");

    console.log("🎉 XIN CHÚC MỪNG! Nạp dữ liệu mẫu Demo (Production) hoàn tất thành công!");
  } catch (error) {
    console.error("❌ Lỗi khi nạp dữ liệu mẫu:", error);
  } finally {
    await db.destroy();
    process.exit();
  }
}

seed();
