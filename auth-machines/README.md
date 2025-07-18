# auth-machines

A small XState v5 state machine that handles email/password login with MFA and account lockout. Comes with a React hook so you can drop it into any app.

## What it does

```
idle → submitting → authenticated
                  → mfaChallenge → verifyingMfa → authenticated
                  → (fail, retries left) → idle
                  → (fail, out of retries) → locked
```

You bring your own auth API calls. The machine handles the flow, retries, lockout timing, and MFA handoff. You just wire up the network calls with `.provide()`.

## Install

```bash
npm install xstate @xstate/react
```

Then copy `src/` into your project

## Quick start

```tsx
import { fromPromise } from 'xstate';
import { useEmailPassword } from '@labmox/auth-machines';

function LoginPage() {
  const auth = useEmailPassword({
    actors: {
      // plug in your actual auth API
      submitCredentials: fromPromise(async ({ input }) => {
        const res = await fetch('/api/login', {
          method: 'POST',
          body: JSON.stringify({ email: input.email, password: input.password }),
        });
        if (!res.ok) throw new Error('Bad credentials');
        return res.json(); // must return { mfaRequired: boolean }
      }),
      // only needed if your login can return mfaRequired: true
      verifyMfa: fromPromise(async ({ input }) => {
        const res = await fetch('/api/verify-mfa', {
          method: 'POST',
          body: JSON.stringify({ email: input.email, code: input.code }),
        });
        if (!res.ok) throw new Error('Wrong code');
      }),
    },
  });

  if (auth.isAuthenticated) {
    return <button onClick={auth.logout}>Log out ({auth.email})</button>;
  }

  if (auth.isLocked) {
    return <p>Locked until {new Date(auth.lockoutUntil!).toLocaleTimeString()}</p>;
  }

  if (auth.isMfaChallenge) {
    return (
      <form onSubmit={(e) => { e.preventDefault(); auth.submitMfa('123456'); }}>
        <input placeholder="MFA code" />
        <button type="submit">Verify</button>
      </form>
    );
  }

  return (
    <form onSubmit={(e) => { e.preventDefault(); auth.submit('me@example.com', 'password'); }}>
      <input placeholder="email" type="email" />
      <input placeholder="password" type="password" />
      {auth.error && <p style={{ color: 'red' }}>{auth.error.message}</p>}
      <button type="submit" disabled={auth.isSubmitting}>
        {auth.isSubmitting ? 'Signing in...' : 'Sign in'}
      </button>
    </form>
  );
}
```

## What the hook gives you

| Property | Type | What it is |
|---|---|---|
| `isIdle` | boolean | Waiting for user to submit |
| `isSubmitting` | boolean | Login request in flight |
| `isMfaChallenge` | boolean | Waiting for MFA code |
| `isVerifyingMfa` | boolean | MFA verification in flight |
| `isAuthenticated` | boolean | Logged in |
| `isLocked` | boolean | Too many failed attempts |
| `email` | string | Current email |
| `retryCount` | number | How many failed attempts so far |
| `error` | AuthError \| null | Last error |
| `lockoutUntil` | number \| null | Timestamp when lockout expires |
| `submit(email, password)` | function | Start login |
| `submitMfa(code)` | function | Submit MFA code |
| `logout()` | function | Log out |
| `unlock()` | function | Clear lockout manually |

## Using the machine directly (no React)

If you're not using React, you can use the machine with `createActor` from xstate:

```ts
import { createActor, fromPromise } from 'xstate';
import { emailPasswordMachine } from '@labmox/auth-machines';

const machine = emailPasswordMachine.provide({
  actors: {
    submitCredentials: fromPromise(async ({ input }) => {
      // your login call
      return { mfaRequired: false };
    }),
  },
});

const actor = createActor(machine).start();
actor.subscribe((snapshot) => {
  console.log('state:', snapshot.value);
  console.log('context:', snapshot.context);
});

actor.send({ type: 'SUBMIT', email: 'me@test.com', password: 'hunter2' });
```

## How lockout works

After 5 failed login attempts (configurable via `maxRetries` in context), the machine goes to `locked` state. Lockout duration uses exponential backoff starting at 30 seconds. Send `UNLOCK` to reset it manually, or check `lockoutUntil` to show a countdown.

## Running tests

```bash
npm install
npm test
```

## Building

```bash
npm run build
# output goes to dist/
```
