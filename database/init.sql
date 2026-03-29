CREATE DATABASE DB_LEARNEX;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. USERS
-- ============================================================
CREATE TABLE users (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email         VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  full_name     VARCHAR(255) NOT NULL,
  username      VARCHAR(50)  UNIQUE NOT NULL,
  avatar_url    TEXT,
  bio           TEXT,
  school        VARCHAR(255),
  major         VARCHAR(255),
  role          VARCHAR(20)  DEFAULT 'user',       -- 'user' | 'admin'
  is_banned     BOOLEAN      DEFAULT FALSE,
  created_at    TIMESTAMPTZ  DEFAULT NOW(),
  updated_at    TIMESTAMPTZ  DEFAULT NOW()
);

-- ============================================================
-- 2. REFRESH TOKENS (Auth)
-- ============================================================
CREATE TABLE refresh_tokens (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token      TEXT        UNIQUE NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 3. DOCUMENTS
-- ============================================================
CREATE TABLE documents (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title          VARCHAR(255) NOT NULL,
  description    TEXT,
  file_url       TEXT         NOT NULL,
  file_size      BIGINT,
  file_type      VARCHAR(100),                     -- 'pdf' | 'slide' | 'code' | ...
  subject        VARCHAR(100),
  tags           JSONB        DEFAULT '[]',
  summary        TEXT,                             -- AI tóm tắt tài liệu
  download_count INT          DEFAULT 0,
  view_count     INT          DEFAULT 0,           -- [FIX] thêm view_count
  created_at     TIMESTAMPTZ  DEFAULT NOW()
);

-- ============================================================
-- 4. POSTS
-- ============================================================
CREATE TABLE posts (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content     TEXT,
  image_urls  JSONB,
  document_id UUID        REFERENCES documents(id) ON DELETE SET NULL,  -- [FIX] có FK
  is_deleted  BOOLEAN     DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 5. LIKES
-- ============================================================
CREATE TABLE likes (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id    UUID        NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id    UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- ============================================================
-- 6. COMMENTS
-- ============================================================
CREATE TABLE comments (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id    UUID        NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id    UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content    TEXT        NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 7. SAVED POSTS
-- ============================================================
CREATE TABLE saved_posts (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id    UUID        NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id    UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- ============================================================
-- 8. FRIENDSHIPS
-- ============================================================
CREATE TABLE friendships (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  requester_id UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  addressee_id UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status       VARCHAR(20) DEFAULT 'pending',      -- 'pending' | 'accepted' | 'rejected'
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(requester_id, addressee_id)
);

-- ============================================================
-- 9. DIRECT MESSAGES (Chat cá nhân)
-- [FIX] Tách riêng khỏi room messages
-- ============================================================
CREATE TABLE direct_messages (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sender_id   UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  receiver_id UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content     TEXT,
  file_url    TEXT,
  is_read     BOOLEAN     DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 10. ROOMS (Phòng học nhóm)
-- ============================================================
CREATE TABLE rooms (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id    UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name        VARCHAR(255) NOT NULL,
  description TEXT,
  is_private  BOOLEAN      DEFAULT FALSE,
  created_at  TIMESTAMPTZ  DEFAULT NOW()
);

-- ============================================================
-- 11. ROOM MEMBERS
-- ============================================================
CREATE TABLE room_members (
  id        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id   UUID        NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  user_id   UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role      VARCHAR(20) DEFAULT 'member',          -- 'owner' | 'moderator' | 'member'
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(room_id, user_id)
);

-- ============================================================
-- 12. ROOM MESSAGES (Chat nhóm trong room)
-- [FIX] Tách riêng khỏi direct messages
-- ============================================================
CREATE TABLE room_messages (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id    UUID        NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  sender_id  UUID        REFERENCES users(id) ON DELETE SET NULL,
  content    TEXT,
  file_url   TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 13. NOTIFICATIONS
-- [FIX] Thêm ref_type + ref_id để navigate đúng màn hình
-- ============================================================
CREATE TABLE notifications (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type       VARCHAR(50)  NOT NULL,                -- 'like' | 'comment' | 'friend_request' | 'message' | 'call'
  title      VARCHAR(255) NOT NULL,
  body       TEXT,
  ref_type   VARCHAR(50),                          -- [FIX] 'post' | 'comment' | 'friendship' | 'room' | 'direct_message'
  ref_id     UUID,                                 -- [FIX] id của object liên quan
  is_read    BOOLEAN      DEFAULT FALSE,
  created_at TIMESTAMPTZ  DEFAULT NOW()
);

-- ============================================================
-- 14. DOCUMENT VIEWS (Lịch sử xem tài liệu — dùng cho AI gợi ý)
-- [FIX] Bảng mới
-- ============================================================
CREATE TABLE document_views (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  document_id UUID        NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  viewed_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- INDEXES
-- ============================================================

-- Users
CREATE INDEX idx_users_username      ON users(username);
CREATE INDEX idx_users_role          ON users(role);

-- Posts
CREATE INDEX idx_posts_user_id       ON posts(user_id);
CREATE INDEX idx_posts_created_at    ON posts(created_at DESC);
CREATE INDEX idx_posts_deleted       ON posts(is_deleted, created_at DESC);

-- Documents
CREATE INDEX idx_documents_user_id   ON documents(user_id);
CREATE INDEX idx_documents_subject   ON documents(subject);
CREATE INDEX idx_documents_created   ON documents(created_at DESC);

-- Likes & Comments & Saved
CREATE INDEX idx_likes_post_id       ON likes(post_id);
CREATE INDEX idx_comments_post_id    ON comments(post_id);
CREATE INDEX idx_saved_posts_user    ON saved_posts(user_id);

-- Friendships
CREATE INDEX idx_friendships_users      ON friendships(requester_id, addressee_id);
CREATE INDEX idx_friendships_addressee  ON friendships(addressee_id, status);

-- Direct Messages
CREATE INDEX idx_dm_sender_receiver     ON direct_messages(sender_id, receiver_id);
CREATE INDEX idx_dm_receiver_created    ON direct_messages(receiver_id, created_at DESC);

-- Room Messages
CREATE INDEX idx_room_messages_room     ON room_messages(room_id);
CREATE INDEX idx_room_messages_created  ON room_messages(created_at DESC);

-- Notifications
CREATE INDEX idx_notifications_user     ON notifications(user_id, is_read);
CREATE INDEX idx_notifications_created  ON notifications(user_id, created_at DESC);

-- Document Views
CREATE INDEX idx_document_views_user    ON document_views(user_id, viewed_at DESC);
CREATE INDEX idx_document_views_doc     ON document_views(document_id);

-- Refresh Tokens
CREATE INDEX idx_refresh_tokens_user    ON refresh_tokens(user_id);

-- ============================================================
-- TRIGGER: Tự động cập nhật updated_at
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_posts_updated_at
  BEFORE UPDATE ON posts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();