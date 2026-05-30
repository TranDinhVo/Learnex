import { Application } from "express";

import authRoutes from "@/module/auth/auth.routes";
import userRoutes from "@/module/user/user.routes";
import postRoutes from "@/module/post/post.routes";
import documentRoutes from "@/module/document/document.routes";
import friendRoutes from "@/module/friend/friend.routes";
import messageRoutes from "@/module/message/message.routes";
import roomRoutes from "@/module/room/room.routes";
import searchRoutes from "@/module/search/search.routes";
import uploadRoutes from "@/module/upload/upload.routes";
import adminRoutes from "@/module/admin/admin.routes";
import notificationRoutes from "@/module/notification/notification.routes";
import chatRoutes from "@/module/chat/chat.routes";

const clientRoute = (app: Application) => {
  const path = "/api/v1";

  app.use(`${path}/auth`, authRoutes);
  app.use(`${path}/users`, userRoutes);
  app.use(`${path}/posts`, postRoutes);
  app.use(`${path}/documents`, documentRoutes);
  app.use(`${path}/friends`, friendRoutes);
  app.use(`${path}/messages`, messageRoutes);
  app.use(`${path}/rooms`, roomRoutes);
  app.use(`${path}/search`, searchRoutes);
  app.use(`${path}/upload`, uploadRoutes);
  app.use(`${path}/admin`, adminRoutes);
  app.use(`${path}/notifications`, notificationRoutes);
  app.use(`${path}/chat`, chatRoutes);
};

export default clientRoute;
