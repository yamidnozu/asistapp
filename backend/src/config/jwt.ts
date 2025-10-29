import crypto from 'crypto';
import jwt, { SignOptions } from 'jsonwebtoken';
import { JWTPayload } from '../types';
import { config } from './app';

export class JWTService {
  private static accessSecret: string = config.jwtSecret;
  private static refreshSecret: string = config.jwtSecret + '_refresh'; // Diferente secret para refresh
  private static accessExpiresIn: string = config.jwtExpiresIn;
  private static refreshExpiresIn: string = '7d'; // 7 días para refresh tokens

  public static signAccessToken(payload: Omit<JWTPayload, 'iat' | 'exp'>): string {
    return jwt.sign(payload, this.accessSecret, { expiresIn: this.accessExpiresIn } as SignOptions);
  }

  public static verifyAccessToken(token: string): JWTPayload {
    try {
      const decoded = jwt.verify(token, this.accessSecret) as JWTPayload;
      return decoded;
    } catch (error) {
      throw new Error('Access token inválido o expirado');
    }
  }

  public static signRefreshToken(payload: Omit<JWTPayload, 'iat' | 'exp'>): string {
    const tokenPayload = {
      ...payload,
      jti: crypto.randomUUID(), // JWT ID único para evitar colisiones
    };
    return jwt.sign(tokenPayload, this.refreshSecret, { expiresIn: this.refreshExpiresIn } as SignOptions);
  }

  public static verifyRefreshToken(token: string): JWTPayload {
    try {
      const decoded = jwt.verify(token, this.refreshSecret) as JWTPayload;
      return decoded;
    } catch (error) {
      throw new Error('Refresh token inválido o expirado');
    }
  }

  public static sign(payload: Omit<JWTPayload, 'iat' | 'exp'>): string {
    return this.signAccessToken(payload);
  }

  public static verify(token: string): JWTPayload {
    return this.verifyAccessToken(token);
  }

  public static decode(token: string): JWTPayload | null {
    try {
      return jwt.decode(token) as JWTPayload;
    } catch (error) {
      return null;
    }
  }
}

export default JWTService;