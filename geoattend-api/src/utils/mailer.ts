import nodemailer from 'nodemailer';
import { env, isProd } from '../config/env';

const transporter = env.SMTP_HOST
  ? nodemailer.createTransport({
      host: env.SMTP_HOST,
      port: env.SMTP_PORT,
      secure: env.SMTP_PORT === 465,
      auth: env.SMTP_USER ? { user: env.SMTP_USER, pass: env.SMTP_PASS } : undefined,
    })
  : null;

export async function sendResetCode(to: string, name: string, code: string, minutes: number) {
  if (!transporter) {
    if (isProd) console.warn('SMTP is not configured: reset code email was not sent.');
    else console.log(`\n[dev] Password reset code for ${to}: ${code}  (valid ${minutes} min)\n`);
    return;
  }
  await transporter.sendMail({
    from: env.MAIL_FROM,
    to,
    subject: 'Your GeoAttend verification code',
    text: `Hello ${name},\n\nYour GeoAttend verification code is ${code}.\nIt expires in ${minutes} minutes.\n\nIf you did not ask for this, you can ignore this email.`,
  });
}
