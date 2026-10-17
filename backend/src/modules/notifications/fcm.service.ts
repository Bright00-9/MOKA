import admin from 'firebase-admin';
import { env } from '../../config/env';
import { logger } from '../../lib/logger';
import { prisma } from '../../lib/prisma';

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: env.FIREBASE_PROJECT_ID,
      clientEmail: env.FIREBASE_CLIENT_EMAIL,
      // .env stores literal \n — Firebase needs real newlines in the PEM key.
      privateKey: env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
    }),
  });
}

interface SendPushArgs {
  userId: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

class FcmService {
  // Always persist the notification row BEFORE attempting the push.
  // A failed/rate-limited push should never mean the user has no record of the event —
  // the in-app notification list is the source of truth, FCM is best-effort delivery.
  async sendToUser({ userId, title, body, data }: SendPushArgs): Promise<void> {
    const notification = await prisma.notification.create({
      data: { userId, title, body, data: data ?? {} },
    });

    const user = await prisma.user.findUnique({ where: { id: userId }, select: { fcmToken: true } });
    if (!user?.fcmToken) {
      logger.warn({ userId }, 'No FCM token on file — notification stored but not pushed');
      return;
    }

    try {
      await admin.messaging().send({
        token: user.fcmToken,
        notification: { title, body },
        data,
        android: { priority: 'high' },
        apns: { payload: { aps: { sound: 'default' } } },
      });
      await prisma.notification.update({ where: { id: notification.id }, data: { sentAt: new Date() } });
    } catch (err) {
      // A dead/rotated token is routine, not a system failure — log at warn, don't throw.
      logger.warn({ err, userId }, 'FCM push failed — token may be stale');
    }
  }
}

export const fcmService = new FcmService();
