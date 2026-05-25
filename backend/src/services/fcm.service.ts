// TODO: Install and configure firebase-admin for real push notifications
// import admin from 'firebase-admin';
// admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

export const fcmService = {
  async sendPushNotification(token: string, title: string, body: string): Promise<void> {
    console.log(`[FCM] Would send push notification to token: ${token}`);
    console.log(`[FCM] Title: ${title}`);
    console.log(`[FCM] Body: ${body}`);

    // TODO: Implement with firebase-admin
    // await admin.messaging().send({
    //   token,
    //   notification: { title, body },
    // });
  },

  async sendMultiplePush(tokens: string[], title: string, body: string): Promise<void> {
    console.log(`[FCM] Would send push notification to ${tokens.length} devices`);
    console.log(`[FCM] Title: ${title}`);
    console.log(`[FCM] Body: ${body}`);

    // TODO: Implement with firebase-admin
    // await admin.messaging().sendEachForMulticast({
    //   tokens,
    //   notification: { title, body },
    // });
  },
};
