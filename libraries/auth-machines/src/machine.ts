import { setup, assign, fromPromise } from 'xstate';
import type { EmailPasswordContext, EmailPasswordEvent } from './types.js';

// exponential backoff: 30s, 60s, 120s, etc.
function lockoutDuration(retryCount: number): number {
  return Math.pow(2, Math.floor(retryCount / 5)) * 30_000;
}

export const emailPasswordMachine = setup({
  types: {
    context: {} as EmailPasswordContext,
    events: {} as EmailPasswordEvent,
  },
  actors: {
    // override these with .provide() — they throw by default so you
    // know immediately if you forgot to wire up your actual auth calls
    submitCredentials: fromPromise<
      { mfaRequired: boolean },
      { email: string; password: string }
    >(async ({ input }) => {
      throw new Error(
        `submitCredentials not wired up (got ${input.email}). Use .provide({ actors: { submitCredentials: ... } }) to plug in your auth API.`
      );
    }),
    verifyMfa: fromPromise<void, { email: string; code: string }>(
      async ({ input }) => {
        throw new Error(
          `verifyMfa not wired up (got code ${input.code}). Use .provide({ actors: { verifyMfa: ... } }) to plug in your MFA verification.`
        );
      }
    ),
  },
  guards: {
    // check against maxRetries - 1 because we increment AFTER this guard runs
    canRetry: ({ context }) => context.retryCount < context.maxRetries - 1,
    isLocked: ({ context }) =>
      context.lockoutUntil !== null && Date.now() < context.lockoutUntil,
    isMfaRequired: (_, params: { mfaRequired: boolean }) => params.mfaRequired,
  },
  actions: {
    setEmail: assign({
      email: (_, params: { email: string }) => params.email,
    }),
    incrementRetry: assign({
      retryCount: ({ context }) => context.retryCount + 1,
    }),
    setLockout: assign({
      lockoutUntil: ({ context }) =>
        Date.now() + lockoutDuration(context.retryCount),
    }),
    setError: assign({
      error: (_, params: { message: string }) => ({
        code: 'AUTH_ERROR',
        message: params.message,
      }),
    }),
    clearError: assign({ error: () => null }),
    resetRetries: assign({ retryCount: () => 0, lockoutUntil: () => null }),
    setMfaCode: assign({
      mfaCode: (_, params: { code: string }) => params.code,
    }),
    clearContext: assign({
      email: () => '',
      retryCount: () => 0,
      lockoutUntil: () => null,
      error: () => null,
      mfaCode: () => '',
    }),
  },
}).createMachine({
  id: 'emailPassword',
  initial: 'idle',
  context: {
    email: '',
    retryCount: 0,
    maxRetries: 5,
    lockoutUntil: null,
    error: null,
    mfaCode: '',
  },
  states: {
    idle: {
      on: {
        SUBMIT: [
          {
            guard: 'isLocked',
            actions: {
              type: 'setError',
              params: { message: 'Account is temporarily locked' },
            },
          },
          {
            target: 'submitting',
            actions: [
              'clearError',
              {
                type: 'setEmail',
                params: ({ event }) => ({ email: event.email }),
              },
            ],
          },
        ],
      },
    },

    submitting: {
      invoke: {
        src: 'submitCredentials',
        input: ({ context, event }) => ({
          email: context.email,
          password: (event as Extract<EmailPasswordEvent, { type: 'SUBMIT' }>)
            .password,
        }),
        onDone: [
          {
            guard: {
              type: 'isMfaRequired',
              params: ({ event }) => ({
                mfaRequired: event.output.mfaRequired,
              }),
            },
            target: 'mfaChallenge',
          },
          {
            target: 'authenticated',
            actions: 'resetRetries',
          },
        ],
        onError: [
          {
            guard: 'canRetry',
            target: 'idle',
            actions: [
              'incrementRetry',
              {
                type: 'setError',
                params: ({ event }) => ({
                  message:
                    (event.error as Error)?.message ?? 'Login failed',
                }),
              },
            ],
          },
          {
            target: 'locked',
            actions: ['incrementRetry', 'setLockout'],
          },
        ],
      },
    },

    mfaChallenge: {
      on: {
        SUBMIT_MFA: {
          target: 'verifyingMfa',
          actions: {
            type: 'setMfaCode',
            params: ({ event }) => ({ code: event.code }),
          },
        },
        LOGOUT: { target: 'idle', actions: 'clearContext' },
      },
    },

    verifyingMfa: {
      invoke: {
        src: 'verifyMfa',
        input: ({ context }) => ({
          email: context.email,
          code: context.mfaCode,
        }),
        onDone: {
          target: 'authenticated',
          actions: 'resetRetries',
        },
        onError: {
          target: 'mfaChallenge',
          actions: {
            type: 'setError',
            params: ({ event }) => ({
              message:
                (event.error as Error)?.message ?? 'MFA verification failed',
            }),
          },
        },
      },
    },

    authenticated: {
      on: {
        LOGOUT: { target: 'idle', actions: 'clearContext' },
      },
    },

    locked: {
      on: {
        UNLOCK: { target: 'idle', actions: 'resetRetries' },
      },
    },
  },
});
