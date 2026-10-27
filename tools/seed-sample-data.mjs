import { readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { initializeApp, deleteApp } from 'firebase/app';
import { getAuth, createUserWithEmailAndPassword, signInWithEmailAndPassword, signOut } from 'firebase/auth';
import { getFirestore, doc, runTransaction, serverTimestamp, terminate } from 'firebase/firestore';

// Uses the public client SDK and the same published rules as the Android app.
const config = JSON.parse(await readFile(new URL('../android/app/google-services.json', import.meta.url), 'utf8'));
const credentials = JSON.parse(await readFile(new URL('../../submission-private/test-config.json', import.meta.url), 'utf8'));
const android = config.client.find(client => client.client_info.android_client_info.package_name === 'com.prm393.bookshelf');
const app = initializeApp({ apiKey: android.api_key[0].current_key,
  appId: android.client_info.mobilesdk_app_id, projectId: config.project_info.project_id });
const auth = getAuth(app), database = getFirestore(app);
const hash = value => createHash('sha256').update(value, 'utf8').digest('hex');
try {
  try {
    await createUserWithEmailAndPassword(auth, credentials.TEST_EMAIL, credentials.TEST_PASSWORD);
  } catch (error) {
    if (error.code !== 'auth/email-already-in-use') throw error;
    await signInWithEmailAndPassword(auth, credentials.TEST_EMAIL, credentials.TEST_PASSWORD);
  }
  const uid = auth.currentUser.uid;
  for (const [title, author, genre, status, favorite, rating, notes] of [
    ['Clean Code', 'Robert C. Martin', 'Non-Fiction', 'Reading', true, 4, 'Ideas for writing clearer code.'],
    ['Dune', 'Frank Herbert', 'Fiction', 'To Read', true, 5, 'A desert planet, a powerful story.'],
    ['Flutter Notes', 'Student', 'Academic', 'Reading', true, undefined, 'Notes for the PRM393 practical exam.'],
    ['The Hobbit', 'J. R. R. Tolkien', 'Fiction', 'Finished', false, 5, 'There and back again.'],
    ['Travel Journal', 'Student', 'Other', 'To Read', false, undefined, 'Places to read about next.'],
  ]) {
    const id = [uid, title.trim().toLowerCase(), author.trim().toLowerCase()].map(hash).join('_');
    const reference = doc(database, 'books', id);
    await runTransaction(database, async transaction => {
      if ((await transaction.get(reference)).exists()) return;
      transaction.set(reference, { id, userId: uid, title, author, genre, status, favorite,
        ...(rating === undefined ? {} : { rating }), notes, createdAt: serverTimestamp() });
    });
  }
  console.log(JSON.stringify({ projectId: config.project_info.project_id,
    testAccount: credentials.TEST_EMAIL, sampleBooksPrepared: 5 }));
} finally {
  await signOut(auth); await terminate(database); await deleteApp(app);
}
