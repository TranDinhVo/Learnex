import { Server } from 'http';
import WebSocket from 'ws';
import jwt from 'jsonwebtoken';
import { TokenPayload } from '../models/types';
import { messageService } from './message.service';
import { roomService } from './room.service';

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

export class WebSocketService {
  private static instance: WebSocketService;
  private wss!: any;
  private connections: Map<string, WebSocket[]> = new Map();

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
    }
    this.broadcastOnlineStatus();
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

        // Broadcast to all room members who are online
        for (const member of members) {
          this.sendToUser(member.user_id, {
            type: 'room_message',
            data: savedMessage,
          });
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

      case 'call_signal': {
        const { receiverId, signal } = data;
        this.sendToUser(receiverId, {
          type: 'call_signal',
          data: {
            senderId,
            signal,
          },
        });
        break;
      }

      default:
        console.warn(`[WS] Unknown message type received: ${type}`);
    }
  }

  private sendToUser(userId: string, payload: any): void {
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
}

export const webSocketService = WebSocketService.getInstance();
