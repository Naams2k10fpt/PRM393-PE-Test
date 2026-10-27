import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { randomBytes } from 'node:crypto';
const directory = new URL('../../submission-private/', import.meta.url);
const path = new URL('test-config.json', directory);
await mkdir(directory, { recursive: true });
try { await readFile(path); }
catch (error) {
  if (error.code !== 'ENOENT') throw error;
  await writeFile(path, JSON.stringify({
    TEST_EMAIL: 'grader.qe190117@example.com',
    TEST_PASSWORD: `Shelf-${randomBytes(12).toString('base64url')}!`,
  }, null, 2));
}
console.log('Test configuration stored privately outside the Git repository.');
