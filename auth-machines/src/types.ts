export interface AuthError {
  code: string;
  message: string;
}

export type EmailPasswordContext = {
  email: string;
  retryCount: number;
  maxRetries: number;
  lockoutUntil: number | null;
  error: AuthError | null;
  mfaCode: string;
};

export type EmailPasswordEvent =
  | { type: 'SUBMIT'; email: string; password: string }
  | { type: 'SUBMIT_MFA'; code: string }
  | { type: 'LOGOUT' }
  | { type: 'UNLOCK' };
