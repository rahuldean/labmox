import { describe, it, expect } from 'vitest';
import { createActor, fromPromise } from 'xstate';
import { emailPasswordMachine } from '../src/machine.js';

// helper — creates a machine with fake auth that you control
function machineWith(opts: {
  login?: () => Promise<{ mfaRequired: boolean }>;
  mfa?: () => Promise<void>;
}) {
  return emailPasswordMachine.provide({
    actors: {
      ...(opts.login && {
        submitCredentials: fromPromise(opts.login),
      }),
      ...(opts.mfa && {
        verifyMfa: fromPromise(opts.mfa),
      }),
    },
  });
}

describe('emailPasswordMachine', () => {
  it('starts in idle', () => {
    const actor = createActor(emailPasswordMachine).start();
    expect(actor.getSnapshot().value).toBe('idle');
  });

  it('moves to submitting when you send SUBMIT', () => {
    const actor = createActor(emailPasswordMachine).start();
    actor.send({ type: 'SUBMIT', email: 'me@test.com', password: 'hunter2' });
    expect(actor.getSnapshot().value).toBe('submitting');
    expect(actor.getSnapshot().context.email).toBe('me@test.com');
  });

  it('lands on authenticated when login succeeds (no MFA)', async () => {
    const machine = machineWith({
      login: async () => ({ mfaRequired: false }),
    });
    const actor = createActor(machine).start();
    actor.send({ type: 'SUBMIT', email: 'me@test.com', password: 'pass' });

    await new Promise((r) => setTimeout(r, 50));
    expect(actor.getSnapshot().value).toBe('authenticated');
  });

  it('lands on mfaChallenge when login says MFA is needed', async () => {
    const machine = machineWith({
      login: async () => ({ mfaRequired: true }),
    });
    const actor = createActor(machine).start();
    actor.send({ type: 'SUBMIT', email: 'me@test.com', password: 'pass' });

    await new Promise((r) => setTimeout(r, 50));
    expect(actor.getSnapshot().value).toBe('mfaChallenge');
  });

  it('authenticates after valid MFA code', async () => {
    const machine = machineWith({
      login: async () => ({ mfaRequired: true }),
      mfa: async () => {},
    });
    const actor = createActor(machine).start();
    actor.send({ type: 'SUBMIT', email: 'me@test.com', password: 'pass' });
    await new Promise((r) => setTimeout(r, 50));

    actor.send({ type: 'SUBMIT_MFA', code: '123456' });
    await new Promise((r) => setTimeout(r, 50));
    expect(actor.getSnapshot().value).toBe('authenticated');
  });

  it('goes back to mfaChallenge on bad MFA code', async () => {
    const machine = machineWith({
      login: async () => ({ mfaRequired: true }),
      mfa: async () => { throw new Error('wrong code'); },
    });
    const actor = createActor(machine).start();
    actor.send({ type: 'SUBMIT', email: 'me@test.com', password: 'pass' });
    await new Promise((r) => setTimeout(r, 50));

    actor.send({ type: 'SUBMIT_MFA', code: '000000' });
    await new Promise((r) => setTimeout(r, 50));
    expect(actor.getSnapshot().value).toBe('mfaChallenge');
    expect(actor.getSnapshot().context.error?.message).toBe('wrong code');
  });

  it('bumps retryCount on failed login', async () => {
    const machine = machineWith({
      login: async () => { throw new Error('nope'); },
    });
    const actor = createActor(machine).start();
    actor.send({ type: 'SUBMIT', email: 'me@test.com', password: 'wrong' });

    await new Promise((r) => setTimeout(r, 50));
    expect(actor.getSnapshot().context.retryCount).toBe(1);
    expect(actor.getSnapshot().value).toBe('idle');
  });

  it('locks the account after 5 failed attempts', async () => {
    const machine = machineWith({
      login: async () => { throw new Error('nope'); },
    });
    const actor = createActor(machine).start();

    for (let i = 0; i < 5; i++) {
      actor.send({ type: 'SUBMIT', email: 'me@test.com', password: 'wrong' });
      await new Promise((r) => setTimeout(r, 50));
    }

    expect(actor.getSnapshot().value).toBe('locked');
    expect(actor.getSnapshot().context.lockoutUntil).not.toBeNull();
  });

  it('UNLOCK resets the lockout', async () => {
    const machine = machineWith({
      login: async () => { throw new Error('nope'); },
    });
    const actor = createActor(machine).start();

    for (let i = 0; i < 5; i++) {
      actor.send({ type: 'SUBMIT', email: 'me@test.com', password: 'wrong' });
      await new Promise((r) => setTimeout(r, 50));
    }

    actor.send({ type: 'UNLOCK' });
    expect(actor.getSnapshot().value).toBe('idle');
    expect(actor.getSnapshot().context.retryCount).toBe(0);
  });

  it('LOGOUT from authenticated goes back to idle', async () => {
    const machine = machineWith({
      login: async () => ({ mfaRequired: false }),
    });
    const actor = createActor(machine).start();
    actor.send({ type: 'SUBMIT', email: 'me@test.com', password: 'pass' });
    await new Promise((r) => setTimeout(r, 50));

    actor.send({ type: 'LOGOUT' });
    expect(actor.getSnapshot().value).toBe('idle');
    expect(actor.getSnapshot().context.email).toBe('');
  });
});
