export function remainingSeconds(startedAt, durationSeconds, now = Date.now()) {
  const deadline = new Date(startedAt).getTime() + durationSeconds * 1000;
  return Math.max(0, Math.ceil((deadline - now) / 1000));
}

