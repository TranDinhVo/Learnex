import knex from "knex";
import dotenv from "dotenv";

dotenv.config();

export const db = knex({
  client: "pg",
  connection: process.env.DATABASE_URL,
  pool: {
    min: 2,
    max: 10,
  },
});

export const checkDatabaseConnection = async () => {
  try {
    await db.raw("SELECT 1");
    console.log("✅ PostgreSQL connected successfully");

    // Tính năng bảo vệ: Kiểm tra xem DB đã có bảng users chưa
    const checkTable = await db.raw(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'users'
      );
    `);

    if (!checkTable.rows[0].exists) {
      console.log("⚠️ CHÚ Ý: Database hiện đang trống!");
      console.log(
        "👉 Vui lòng mở DBeaver/pgAdmin, copy toàn bộ file 'init.sql' và chạy để khởi tạo các bảng.",
      );
      return; // Dừng việc thao tác với DB để tránh sập app
    }

    console.log("✅ PostgreSQL tables are ready!");
  } catch (error) {
    console.error("❌ PostgreSQL connection failed:", error);
    process.exit(1);
  }
};
