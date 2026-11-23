/* BLANK START: creates only what the app cannot work without.
     - the first admin account (from ADMIN_* in .env)
     - the default working-hours schedule (08:00, 15 minutes grace)
   Everything else (workplaces, departments, employees...) you add from the app.
   Run:  npx prisma db seed        (safe to run more than once)
   Want sample data instead?  npm run db:seed:demo */
import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  const name = process.env.ADMIN_NAME?.trim() || 'Administrator';
  const email = process.env.ADMIN_EMAIL?.trim().toLowerCase();
  const password = process.env.ADMIN_PASSWORD;

  if (!email || !password) {
    console.error('\nSet ADMIN_EMAIL and ADMIN_PASSWORD in the .env file first, then run this again.\n');
    process.exit(1);
  }
  if (password.length < 6 || !/\d/.test(password)) {
    console.error('\nADMIN_PASSWORD must have at least 6 characters and include a number.\n');
    process.exit(1);
  }

  await prisma.schedule.upsert({
    where: { name: 'Standard Day' },
    update: {},
    create: { name: 'Standard Day', startTime: '08:00', endTime: '17:00', gracePeriodMinutes: 15 },
  });

  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    console.log(`\nAn account for ${email} already exists. Nothing changed.\n`);
    return;
  }

  await prisma.user.create({
    data: { name, email, passwordHash: await bcrypt.hash(password, 10), role: 'admin' },
  });
  console.log(`\nBlank start ready. Sign in on the ADMIN login with:\n  ${email}\n  (the password you put in .env)\n`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
