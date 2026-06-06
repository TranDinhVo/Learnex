/**
 * Web Browser Notification Service with Audio
 * - Handles browser notifications for messages and calls
 * - Plays sound when notification arrives
 */

export class NotificationAudioService {
  private static instance: NotificationAudioService;
  private messageSound: HTMLAudioElement;
  private callSound: HTMLAudioElement;

  private constructor() {
    // Create audio elements for message notifications
    this.messageSound = new Audio();
    this.messageSound.src = '/sounds/message_notification.mp3';
    this.messageSound.volume = 0.8;
    this.messageSound.preload = 'auto';

    // Create audio elements for incoming calls
    this.callSound = new Audio();
    this.callSound.src = '/sounds/incoming_call_ringtone.mp3';
    this.callSound.volume = 1.0;
    this.callSound.preload = 'auto';
    this.callSound.loop = true; // Loop call ringtone
  }

  static getInstance(): NotificationAudioService {
    if (!NotificationAudioService.instance) {
      NotificationAudioService.instance = new NotificationAudioService();
    }
    return NotificationAudioService.instance;
  }

  /**
   * Request notification permission from browser
   */
  async requestPermission(): Promise<boolean> {
    if (!('Notification' in window)) {
      console.warn('Browser does not support notifications');
      return false;
    }

    if (Notification.permission === 'granted') {
      return true;
    }

    if (Notification.permission !== 'denied') {
      const permission = await Notification.requestPermission();
      return permission === 'granted';
    }

    return false;
  }

  /**
   * Show notification for new message with sound
   */
  async showMessageNotification(title: string, options?: NotificationOptions): Promise<void> {
    const permitted = await this.requestPermission();
    if (!permitted) return;

    // Play message notification sound
    try {
      await this.messageSound.play();
    } catch (error) {
      console.warn('Error playing message notification sound:', error);
    }

    // Show browser notification
    const notification = new Notification(title, {
      icon: '/assets/app-icon.png',
      badge: '/assets/app-badge.png',
      ...options,
    });

    // Auto-close after 5 seconds
    setTimeout(() => notification.close(), 5000);
  }

  /**
   * Show notification for incoming call with ringtone
   */
  async showIncomingCallNotification(
    title: string,
    options?: NotificationOptions
  ): Promise<void> {
    const permitted = await this.requestPermission();
    if (!permitted) return;

    // Stop any previous call sound and restart
    this.callSound.currentTime = 0;

    // Play incoming call ringtone
    try {
      await this.callSound.play();
    } catch (error) {
      console.warn('Error playing incoming call ringtone:', error);
    }

    // Show browser notification
    const notification = new Notification(title, {
      icon: '/assets/app-icon.png',
      badge: '/assets/app-badge.png',
      tag: 'incoming-call', // Replace previous call notifications
      requireInteraction: true, // Don't auto-close
      ...options,
    });

    // When notification is clicked, stop ringtone
    notification.onclick = () => {
      this.stopIncomingCallRingtone();
      notification.close();
    };
  }

  /**
   * Stop incoming call ringtone
   */
  stopIncomingCallRingtone(): void {
    this.callSound.pause();
    this.callSound.currentTime = 0;
  }

  /**
   * Stop message notification sound
   */
  stopMessageNotification(): void {
    this.messageSound.pause();
    this.messageSound.currentTime = 0;
  }

  /**
   * Clean up
   */
  dispose(): void {
    this.stopMessageNotification();
    this.stopIncomingCallRingtone();
  }
}

// Export singleton instance
export const notificationAudio = NotificationAudioService.getInstance();
