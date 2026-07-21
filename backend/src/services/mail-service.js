import nodemailer from 'nodemailer';
import { env } from '../config/env.js';

const transport = nodemailer.createTransport({ host: env.SMTP_HOST, port: env.SMTP_PORT, secure: env.SMTP_PORT === 465, auth: { user: env.SMTP_USER, pass: env.SMTP_PASSWORD } });
export function sendPasswordReset(email, token) { return transport.sendMail({ from: env.SMTP_FROM, to: email, subject: 'The Wiretap - إعادة تعيين كلمة السر', text: `استخدم الرابط ده لإعادة تعيين كلمة السر: thewiretap://reset-password?token=${encodeURIComponent(token)}\nأو انسخ رمز التعيين: ${token}\nالرابط والرمز صالحين لمدة ساعة واحدة. لو ما طلبتش إعادة التعيين، تجاهل الرسالة.` }); }
