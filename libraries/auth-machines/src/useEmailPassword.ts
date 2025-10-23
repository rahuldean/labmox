import { useMachine } from '@xstate/react';
import { emailPasswordMachine } from './machine.js';

type Overrides = Parameters<typeof emailPasswordMachine.provide>[0];

export function useEmailPassword(overrides?: Overrides) {
  const machine = overrides
    ? emailPasswordMachine.provide(overrides)
    : emailPasswordMachine;

  const [snapshot, send] = useMachine(machine);

  return {
    // which state we're in
    isIdle: snapshot.matches('idle'),
    isSubmitting: snapshot.matches('submitting'),
    isMfaChallenge: snapshot.matches('mfaChallenge'),
    isVerifyingMfa: snapshot.matches('verifyingMfa'),
    isAuthenticated: snapshot.matches('authenticated'),
    isLocked: snapshot.matches('locked'),

    // data
    email: snapshot.context.email,
    retryCount: snapshot.context.retryCount,
    error: snapshot.context.error,
    lockoutUntil: snapshot.context.lockoutUntil,

    // actions
    submit: (email: string, password: string) =>
      send({ type: 'SUBMIT', email, password }),
    submitMfa: (code: string) => send({ type: 'SUBMIT_MFA', code }),
    logout: () => send({ type: 'LOGOUT' }),
    unlock: () => send({ type: 'UNLOCK' }),
  };
}
