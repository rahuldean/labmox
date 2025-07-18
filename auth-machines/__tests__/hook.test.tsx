import { describe, it, expect } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { fromPromise } from 'xstate';
import { useEmailPassword } from '../src/useEmailPassword.js';

describe('useEmailPassword hook', () => {
  it('starts idle with sane defaults', () => {
    const { result } = renderHook(() => useEmailPassword());
    expect(result.current.isIdle).toBe(true);
    expect(result.current.isAuthenticated).toBe(false);
    expect(result.current.email).toBe('');
    expect(result.current.error).toBeNull();
  });

  it('goes through submit → authenticated', async () => {
    const { result } = renderHook(() =>
      useEmailPassword({
        actors: {
          submitCredentials: fromPromise(async (): Promise<{ mfaRequired: boolean }> => ({ mfaRequired: false })),
        },
      })
    );

    act(() => {
      result.current.submit('me@test.com', 'pass');
    });
    expect(result.current.isSubmitting).toBe(true);

    await act(async () => {
      await new Promise((r) => setTimeout(r, 50));
    });
    expect(result.current.isAuthenticated).toBe(true);
    expect(result.current.email).toBe('me@test.com');
  });

  it('logout resets everything', async () => {
    const { result } = renderHook(() =>
      useEmailPassword({
        actors: {
          submitCredentials: fromPromise(async (): Promise<{ mfaRequired: boolean }> => ({ mfaRequired: false })),
        },
      })
    );

    act(() => { result.current.submit('me@test.com', 'pass'); });
    await act(async () => { await new Promise((r) => setTimeout(r, 50)); });

    act(() => { result.current.logout(); });
    expect(result.current.isIdle).toBe(true);
    expect(result.current.email).toBe('');
  });
});
