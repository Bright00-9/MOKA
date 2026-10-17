import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { prisma } from '../../lib/prisma';
import { env } from '../../config/env';
import { ConflictError, UnauthorizedError } from '../../lib/errors';
import { RegisterInput, LoginInput } from './auth.schema';

const BCRYPT_ROUNDS = 12;

function signToken(userId: string, role: string) {
  const options: jwt.SignOptions = { expiresIn: env.JWT_EXPIRES_IN as jwt.SignOptions['expiresIn'] };
  return jwt.sign({ sub: userId, role }, env.JWT_SECRET, options);
}

export const authService = {
  async register(input: RegisterInput) {
    const existing = await prisma.user.findFirst({
      where: { OR: [{ email: input.email }, ...(input.phone ? [{ phone: input.phone }] : [])] },
    });
    if (existing) {
      throw new ConflictError('An account with this email or phone already exists');
    }

    const passwordHash = await bcrypt.hash(input.password, BCRYPT_ROUNDS);

    const user = await prisma.user.create({
      data: {
        fullName: input.fullName,
        email: input.email,
        phone: input.phone,
        passwordHash,
        role: input.role,
        starLevel: input.role === 'PROVIDER' ? 1 : null,
      },
    });

    return { token: signToken(user.id, user.role), user: sanitize(user) };
  },

  async login(input: LoginInput) {
    const user = await prisma.user.findUnique({ where: { email: input.email } });
    if (!user) throw new UnauthorizedError('Invalid email or password');

    const valid = await bcrypt.compare(input.password, user.passwordHash);
    if (!valid) throw new UnauthorizedError('Invalid email or password');

    return { token: signToken(user.id, user.role), user: sanitize(user) };
  },
};

// Never return passwordHash to the client, even on the user's own account.
function sanitize<T extends { passwordHash: string }>(user: T) {
  const { passwordHash: _passwordHash, ...rest } = user;
  return rest;
}
