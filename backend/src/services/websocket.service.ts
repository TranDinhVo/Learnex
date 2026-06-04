import { Server } from 'http';
import WebSocket from 'ws';
import jwt from 'jsonwebtoken';
import { TokenPayload } from '../models/types';
import { messageService } from './message.service';
import { roomService } from './room.service';
import { db } from '../config/database';

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

export class WebSocketService {
  private static instance: WebSocketService;
  private wss!: any;
  private connections: Map<string, WebSocket[]> = new Map();
  private activeCallParticipants: Map<string, Set<string>> = new Map(); // roomId -> Set<userId>
  private callStartTimes: Map<string, number> = new Map();
  private callMaxParticipants: Map<string, number> = new Map();

  private constructor() {}

  public static getInstance(): WebSocketService {
    if (!WebSocketService.instance) {
      WebSocketService.instance = new WebSocketService();
    }
    return WebSocketService.instance;
  }

  public initialize(server: Server): void {
    this.wss = new (WebSocket as any).Server({ noServer: true });

    server.on('upgrade', (request, socket, head) => {
      const url = new URL(request.url || '', `http://${request.headers.host}`);
      const token = url.searchParams.get('token');

      if (!token) {
        socket.write('HTTP/1.1 401 Unauthorized\r\n\r\n');
        socket.destroy();
        return;
      }

      try {
        const decoded = jwt.verify(token, JWT_SECRET) as TokenPayload;
        this.wss.handleUpgrade(request, socket, head, (ws: any) => {
          this.wss.emit('connection', ws, request, decoded);
        });
      } catch (err) {
        socket.write('HTTP/1.1 401 Unauthorized\r\n\r\n');
        socket.destroy();
      }
    });

    this.wss.on('connection', (ws: WebSocket, request: any, decoded: TokenPayload) => {
      const userId = decoded.userId;
      this.addConnection(userId, ws);

      console.log(`[WS] User ${userId} connected. Total active users: ${this.connections.size}`);

      // Setup Heartbeat (ping-pong)
      (ws as any).isAlive = true;
      ws.on('pong', () => {
        (ws as any).isAlive = true;
      });

      // Handle messages
      ws.on('message', async (messageData: string) => {
        try {
          const parsed = JSON.parse(messageData);
          await this.handleMessage(userId, parsed);
        } catch (error) {
          console.error('[WS] Error processing message:', error);
          ws.send(JSON.stringify({ type: 'error', data: { message: 'Invalid message format' } }));
        }
      });

      // Handle close
      ws.on('close', () => {
        this.removeConnection(userId, ws);
        console.log(`[WS] User ${userId} disconnected.`);
      });

      // Send initial online status
      this.broadcastOnlineStatus();
    });

    // Start ping interval
    setInterval(() => {
      this.wss.clients.forEach((ws: any) => {
        if ((ws as any).isAlive === false) return ws.terminate();
        (ws as any).isAlive = false;
        ws.ping();
      });
    }, 30000); // 30s heartbeat
  }

  private addConnection(userId: string, ws: WebSocket): void {
    const userConns = this.connections.get(userId) || [];
    userConns.push(ws);
    this.connections.set(userId, userConns);
  }

  private removeConnection(userId: string, ws: WebSocket): void {
    const userConns = this.connections.get(userId) || [];
    const filtered = userConns.filter((c) => c !== ws);
    if (filtered.length > 0) {
      this.connections.set(userId, filtered);
    } else {
      this.connections.delete(userId);
      // Remove from any active calls
      this.activeCallParticipants.forEach((participants, roomId) => {
        if (participants.has(userId)) {
          participants.delete(userId);
          this.broadcastRoomActiveStatus(roomId);
        }
      });
    }
    this.broadcastOnlineStatus();
  }

  private async broadcastRoomActiveStatus(roomId: string): Promise<void> {
    try {
      const participants = this.activeCallParticipants.get(roomId) || new Set();
      const onlineMembers = await roomService.getMembers(roomId);
      for (const member of onlineMembers) {
        this.sendToUser(member.user_id, {
          type: 'room_active_status',
          data: { roomId, activeUsers: Array.from(participants) }
        });
      }
    } catch (e) {
      console.error('[WS] Failed to broadcast room active status', e);
    }
  }

  private async handleMessage(senderId: string, message: { type: string; data: any }): Promise<void> {
    const { type, data } = message;

    switch (type) {
      case 'chat_message': {
        const { receiverId, content, fileUrl } = data;
        const savedMessage = await messageService.send(senderId, receiverId, { content, file_url: fileUrl });
        
        // Send to receiver if online
        this.sendToUser(receiverId, {
          type: 'chat_message',
          data: savedMessage,
        });

        // Echo back to sender's other devices
        this.sendToUser(senderId, {
          type: 'chat_message',
          data: savedMessage,
        });
        break;
      }

      case 'room_message': {
        const { roomId, content, fileUrl } = data;
        const savedMessage = await roomService.sendMessage(roomId, senderId, { content, file_url: fileUrl });
        const members = await roomService.getMembers(roomId);
        const sender = await db('users').where({ id: senderId }).first();

        const messageData = {
          ...savedMessage,
          sender_name: sender?.full_name,
          sender_username: sender?.username,
          sender_avatar: sender?.avatar_url,
        };

        // Broadcast to all room members who are online
        for (const member of members) {
          this.sendToUser(member.user_id, {
            type: 'room_message',
            data: messageData,
          });
        }
        break;
      }

      case 'room_message_read': {
        const { roomId, messageIds } = data;
        const members = await roomService.getMembers(roomId);
        const reader = await db('users').where({ id: senderId }).first();

        const readData = {
          roomId,
          messageIds,
          user_id: senderId,
          full_name: reader?.full_name,
          avatar_url: reader?.avatar_url,
          read_at: new Date().toISOString(),
        };

        for (const member of members) {
          if (member.user_id !== senderId) {
            this.sendToUser(member.user_id, {
              type: 'room_message_read',
              data: readData,
            });
          }
        }
        break;
      }

      case 'typing':
      case 'stop_typing': {
        const { receiverId } = data;
        this.sendToUser(receiverId, {
          type,
          data: { senderId },
        });
        break;
      }

      case 'join_call': {
        const { roomId } = data;
        
        if (!this.activeCallParticipants.has(roomId)) {
          this.activeCallParticipants.set(roomId, new Set());
          this.callStartTimes.set(roomId, Date.now());
          this.callMaxParticipants.set(roomId, 0);
        }
        this.activeCallParticipants.get(roomId)!.add(senderId);
        
        const currentCount = this.activeCallParticipants.get(roomId)!.size;
        const maxSoFar = this.callMaxParticipants.get(roomId) || 0;
        this.callMaxParticipants.set(roomId, Math.max(currentCount, maxSoFar));
        
        this.broadcastRoomActiveStatus(roomId);

        // Notify OTHER ACTIVE participants that this user is joining the call
        const activeParticipants = this.activeCallParticipants.get(roomId);
        if (activeParticipants) {
          for (const p of activeParticipants) {
            if (p !== senderId) {
              this.sendToUser(p, {
                type: 'user_joined_call',
                data: { senderId, roomId }
              });
            }
          }
        }
        
        break;
      }

      case 'start_room_call': {
        const { roomId, callerName, callType } = data;
        const activeParticipants = this.activeCallParticipants.get(roomId) || new Set();
        const members = await roomService.getMembers(roomId);
        for (const member of members) {
          if (member.user_id !== senderId && !activeParticipants.has(member.user_id)) {
            this.sendToUser(member.user_id, {
              type: 'room_call_invite',
              data: { callerId: senderId, callerName, callType, roomId }
            });
          }
        }
        break;
      }

      case 'get_room_active_status': {
        const { roomId } = data;
        const participants = this.activeCallParticipants.get(roomId) || new Set();
        this.sendToUser(senderId, {
          type: 'room_active_status',
          data: { roomId, activeUsers: Array.from(participants) }
        });
        break;
      }

      case 'private_join_call': {
        const { roomId, targetId } = data;
        // Gửi user_joined_call đến Caller để Caller khởi tạo Offer WebRTC
        this.sendToUser(targetId, {
          type: 'user_joined_call',
          data: { senderId, roomId }
        });
        break;
      }

      case 'leave_call': {
        const { roomId } = data;

        const participants = this.activeCallParticipants.get(roomId);
        if (participants) {
          participants.delete(senderId);
          if (participants.size === 0) {
            this.activeCallParticipants.delete(roomId);
            
            // Call Ended Logic
            const startTime = this.callStartTimes.get(roomId) || Date.now();
            const durationMs = Date.now() - startTime;
            const durationSec = Math.floor(durationMs / 1000);
            const maxParticipants = this.callMaxParticipants.get(roomId) || 0;
            
            this.callStartTimes.delete(roomId);
            this.callMaxParticipants.delete(roomId);
            
            let callMessage = '';
            if (maxParticipants < 2) {
               callMessage = '[CALL_HISTORY]:VIDEO:MISSED';
            } else {
               callMessage = `[CALL_HISTORY]:VIDEO:${durationSec}`;
            }
            
            // Create system message ONLY IF it's a real room (prevent private call crash)
            try {
              const members = await roomService.getMembers(roomId);
              const sysMsg = await db('room_messages').insert({
                room_id: roomId,
                sender_id: null,
                content: callMessage,
              }).returning('*');
              
              for (const m of members) {
                this.sendToUser(m.user_id, {
                  type: 'room_message',
                  data: {
                    ...sysMsg[0],
                    sender_name: 'Hệ thống',
                    sender_username: 'system',
                    sender_avatar: null,
                  }
                });
              }
            } catch (e) {
              // It's a private call roomId, ignore db insert
            }
          }
        }
        
        try {
          this.broadcastRoomActiveStatus(roomId);
          const members = await roomService.getMembers(roomId);
          for (const member of members) {
            if (member.user_id !== senderId) {
               this.sendToUser(member.user_id, {
                 type: 'user_left_call',
                 data: { senderId, roomId }
               });
            }
          }
        } catch(e) {
          // If room doesn't exist (private call), we just skip room-specific broadcasts
        }
        break;
      }

      case 'private_call_invite': {
        const { targetId, callType, roomId, callerName } = data;
        this.sendToUser(targetId, {
          type: 'private_call_invite',
          data: { callerId: senderId, callerName, callType, roomId }
        });
        break;
      }

      case 'private_call_accept': {
        const { callerId, roomId } = data;
        this.sendToUser(callerId, {
          type: 'private_call_accept',
          data: { acceptedBy: senderId, roomId }
        });
        break;
      }

      case 'private_call_reject': {
        const { callerId } = data;
        this.sendToUser(callerId, {
          type: 'private_call_reject',
          data: { rejectedBy: senderId }
        });
        break;
      }

      case 'private_call_end': {
        const { targetId } = data;
        this.sendToUser(targetId, {
          type: 'private_call_end',
          data: { endedBy: senderId }
        });
        break;
      }

      case 'webrtc_offer':
      case 'webrtc_answer':
      case 'webrtc_ice_candidate': {
        const { targetId, sdp, candidate, roomId } = data;
        this.sendToUser(targetId, {
          type,
          data: {
            senderId, // Who is sending this signal
            sdp,      // For offer/answer
            candidate,// For ice_candidate
            roomId
          },
        });
        break;
      }

      default:
        console.warn(`[WS] Unknown message type received: ${type}`);
    }
  }

  public sendToUser(userId: string, payload: any): void {
    const userConns = this.connections.get(userId);
    if (userConns) {
      const dataStr = JSON.stringify(payload);
      userConns.forEach((ws) => {
        if (ws.readyState === WebSocket.OPEN) {
          ws.send(dataStr);
        }
      });
    }
  }

  public emitToUsers(userIds: string[], payload: any): void {
    userIds.forEach(userId => this.sendToUser(userId, payload));
  }

  private broadcastOnlineStatus(): void {
    const onlineUserIds = Array.from(this.connections.keys());
    const payload = {
      type: 'online_status',
      data: { onlineUsers: onlineUserIds },
    };
    const dataStr = JSON.stringify(payload);

    this.wss?.clients.forEach((client: any) => {
      if (client.readyState === WebSocket.OPEN) {
        client.send(dataStr);
      }
    });
  }

  public broadcastToAll(payload: any): void {
    const dataStr = JSON.stringify(payload);
    this.wss?.clients.forEach((client: any) => {
      if (client.readyState === WebSocket.OPEN) {
        client.send(dataStr);
      }
    });
  }
}

export const webSocketService = WebSocketService.getInstance();
