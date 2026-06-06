/// Tập hợp tất cả các endpoint API của backend.
/// Base URL được cấu hình trong DioClient, các path ở đây là relative.
class ApiEndpoints {
  const ApiEndpoints._();

  // ── Auth ──────────────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';

  // ── User / Profile ───────────────────────────────────────────────
  static const String me = '/users/me';
  static const String updateProfile = '/users/me';
  static const String uploadAvatar = '/users/me/avatar';
  static const String searchUsers = '/users/search';
  static String userById(String id) => '/users/$id';

  // ── Search ────────────────────────────────────────────────────────
  static const String search = '/search';

  // ── Posts / Feed ─────────────────────────────────────────────────
  static const String feed = '/posts/feed';
  static const String savedPosts = '/posts/saved';
  static const String createPost = '/posts';
  static String postById(String id) => '/posts/$id';
  static String toggleLike(String id) => '/posts/$id/like';
  static String toggleSave(String id) => '/posts/$id/save';
  static String postComments(String id) => '/posts/$id/comments';
  static String deleteComment(String postId, String commentId) =>
      '/posts/$postId/comments/$commentId';

  // ── Documents ────────────────────────────────────────────────────
  static const String documents = '/documents';
  static const String searchDocuments = '/documents/search';
  static const String documentRecommendations = '/documents/recommendations';
  static const String documentSubjects = '/documents/subjects';
  static const String savedDocuments = '/documents/saved';
  static String documentById(String id) => '/documents/$id';
  static String downloadDocument(String id) => '/documents/$id/download';
  static String streamDocument(String id) => '/documents/$id/stream';
  static String viewDocument(String id) => '/documents/$id/view';
  static String toggleSaveDocument(String id) => '/documents/$id/save';

  // ── Upload ───────────────────────────────────────────────────────
  static const String uploadFile = '/upload';


  // ── Friends ──────────────────────────────────────────────────────
  static const String friends = '/friends';
  static const String friendRequests = '/friends/requests';
  static String friendshipStatus(String userId) => '/friends/status/$userId';
  static String sendFriendRequest(String userId) => '/friends/request/$userId';
  static String acceptFriendRequest(String id) => '/friends/accept/$id';
  static String rejectFriendRequest(String id) => '/friends/reject/$id';
  static const String friendSuggestions = '/friends/suggestions';
  static String unfriend(String userId) => '/friends/$userId';

  // ── Chat (Direct Messages) ──────────────────────────────────────
  // Các endpoint chat thường đi qua WebSocket, nhưng REST fallback:
  static const String conversations = '/chat/conversations';
  static String chatMessages(String conversationId) =>
      '/chat/conversations/$conversationId/messages';
  static String sendMessage(String conversationId) =>
      '/chat/conversations/$conversationId/messages';
  static String deleteMessage(String messageId) => '/chat/messages/$messageId';
  static String editMessage(String messageId) => '/chat/messages/$messageId';
  static String toggleReaction(String messageId) => '/chat/messages/$messageId/reactions';

  // ── Rooms (Study Groups) ────────────────────────────────────────
  static const String rooms = '/rooms';
  static String roomById(String id) => '/rooms/$id';
  static String roomMembers(String id) => '/rooms/$id/members';
  static String roomMemberRole(String roomId, String userId) => '/rooms/$roomId/members/$userId/role';
  static String joinRoom(String id) => '/rooms/$id/join';
  static String leaveRoom(String id) => '/rooms/$id/leave';
  static String roomMessages(String id) => '/rooms/$id/messages';
  static String roomAvatar(String id) => '/rooms/$id/avatar';
  static String markRoomMessagesRead(String id) => '/rooms/$id/messages/read';
  static String getRoomReadReceipts(String id) => '/rooms/$id/messages/read-receipts';

  // ── Notifications ───────────────────────────────────────────────
  static const String notifications = '/notifications';  
  static String markNotificationRead(String id) => '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';
  static const String registerFcmToken = '/notifications/fcm-token';

  // ── WebSocket ───────────────────────────────────────────────────
  static const String websocket = '/ws';

  // ── Upload ───────────────────────────────────────────────
  static const String uploadImage = '/upload/image';
  static const String uploadDocument = '/upload/document';
}
