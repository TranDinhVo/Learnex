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

    // Run migration checks
    await db.raw(
      "ALTER TABLE documents ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT NULL",
    );
    await db.raw(
      "ALTER TABLE posts ADD COLUMN IF NOT EXISTS excluded_user_ids JSONB DEFAULT '[]'::jsonb",
    );
    await db.raw(
      "ALTER TABLE posts ADD COLUMN IF NOT EXISTS visibility VARCHAR(20) DEFAULT 'public'",
    );
    await db.raw(
      "ALTER TABLE posts ADD COLUMN IF NOT EXISTS tagged_user_ids JSONB",
    );
    await db.raw("ALTER TABLE posts ADD COLUMN IF NOT EXISTS image_urls JSONB");
    await db.raw(
      "ALTER TABLE posts ADD COLUMN IF NOT EXISTS document_id UUID REFERENCES documents(id) ON DELETE SET NULL",
    );
    await db.raw(
      "ALTER TABLE posts ADD COLUMN IF NOT EXISTS location VARCHAR(255)",
    );
    await db.raw(
      "ALTER TABLE documents ADD COLUMN IF NOT EXISTS view_count INT DEFAULT 0",
    );
    await db.raw(
      "ALTER TABLE notifications ADD COLUMN IF NOT EXISTS ref_type VARCHAR(50)",
    );
    await db.raw(
      "ALTER TABLE notifications ADD COLUMN IF NOT EXISTS ref_id UUID",
    );

    // Stories tables
    await db.raw(`
      CREATE TABLE IF NOT EXISTS stories (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        media_url TEXT,
        media_type VARCHAR(10) DEFAULT 'image',
        text_content TEXT,
        text_color VARCHAR(7) DEFAULT '#FFFFFF',
        bg_color VARCHAR(7) DEFAULT '#6366F1',
        bg_gradient TEXT,
        duration_sec INT DEFAULT 5,
        visibility VARCHAR(20) DEFAULT 'friends',
        is_active BOOLEAN DEFAULT TRUE,
        is_archived BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '12 hours'),
        archived_at TIMESTAMPTZ
      )
    `);

    await db.raw(
      "ALTER TABLE stories ADD COLUMN IF NOT EXISTS excluded_user_ids JSONB DEFAULT '[]'::jsonb",
    );

    await db.raw(`
      CREATE TABLE IF NOT EXISTS story_views (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        story_id UUID NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
        viewer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        viewed_at TIMESTAMPTZ DEFAULT NOW(),
        UNIQUE(story_id, viewer_id)
      )
    `);

    await db.raw(`
      CREATE TABLE IF NOT EXISTS story_reactions (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        story_id UUID NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        emoji VARCHAR(10) NOT NULL,
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    // Drop constraint if it existed to allow multiple reactions
    try {
      await db.raw(
        "ALTER TABLE story_reactions DROP CONSTRAINT IF EXISTS story_reactions_story_id_user_id_key",
      );
    } catch (e) {}

    // Add support for story replies in direct_messages
    await db.raw(
      `ALTER TABLE direct_messages ADD COLUMN IF NOT EXISTS reply_to_story_id UUID REFERENCES stories(id) ON DELETE SET NULL`,
    );
    await db.raw(
      `ALTER TABLE direct_messages ADD COLUMN IF NOT EXISTS reply_story_preview TEXT`,
    );

    // Subjects table
    await db.raw(`
      CREATE TABLE IF NOT EXISTS subjects (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL UNIQUE,
        description TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    // Default subjects
    const defaultSubjects = [
      "Lập trình",
      "Toán học",
      "Vật lý",
      "Triết học",
      "Tiếng Anh",
    ];
    for (const subject of defaultSubjects) {
      await db.raw(
        `INSERT INTO subjects (name) VALUES (?) ON CONFLICT (name) DO NOTHING`,
        [subject],
      );
    }

    // Saved documents table
    await db.raw(`
      CREATE TABLE IF NOT EXISTS saved_documents (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        UNIQUE(user_id, document_id)
      )
    `);

    console.log("✅ PostgreSQL tables are ready!");
  } catch (error) {
    console.error("❌ PostgreSQL connection failed:", error);
    process.exit(1);
  }
};
