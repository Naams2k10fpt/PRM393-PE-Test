import { readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { before, after, beforeEach, test } from 'node:test';
import assert from 'node:assert/strict';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, collection, setDoc, getDoc, getDocs, updateDoc, deleteDoc,
  query, where, runTransaction, Timestamp } from 'firebase/firestore';

const hash = value => createHash('sha256').update(value, 'utf8').digest('hex');
const key = (uid, title, author) => [uid, title.trim().toLowerCase(), author.trim().toLowerCase()]
  .map(hash).join('_');
const book = (uid = 'alice', changes = {}) => {
  const value = { userId: uid, title: 'Dune', author: 'Frank Herbert', genre: 'Fiction',
    status: 'To Read', favorite: false, notes: '', createdAt: Timestamp.fromMillis(1000), ...changes };
  return { ...value, id: key(uid, value.title, value.author) };
};
let environment;
const db = uid => uid ? environment.authenticatedContext(uid).firestore()
  : environment.unauthenticatedContext().firestore();
const ref = (database, value) => doc(database, 'books', value.id);
before(async () => {
  environment = await initializeTestEnvironment({ projectId: 'demo-bookshelf',
    firestore: { rules: await readFile(new URL('../firestore.rules', import.meta.url), 'utf8') } });
});
beforeEach(async () => environment.clearFirestore());
after(async () => environment?.cleanup());

test('owner can create, read, update favorite and delete', async () => {
  const database = db('alice'), value = book();
  await assertSucceeds(setDoc(ref(database, value), value));
  await assertSucceeds(getDoc(ref(database, value)));
  await assertSucceeds(updateDoc(ref(database, value), { favorite: true, rating: 0 }));
  await assertSucceeds(deleteDoc(ref(database, value)));
});

test('only own absent canonical path is readable for transactions', async () => {
  await assertSucceeds(getDoc(ref(db('alice'), book())));
  await assertFails(getDoc(ref(db('bob'), book())));
  await assertFails(getDoc(doc(db('alice'), 'books', 'random-id')));
});

test('queries require the current UID and reject unscoped reads', async () => {
  await setDoc(ref(db('alice'), book()), book());
  await setDoc(ref(db('bob'), book('bob')), book('bob'));
  await assertSucceeds(getDocs(query(collection(db('alice'), 'books'), where('userId', '==', 'alice'))));
  await assertFails(getDocs(collection(db('alice'), 'books')));
  await assertFails(getDocs(query(collection(db('alice'), 'books'), where('userId', '==', 'bob'))));
});

test('anonymous client cannot read, query, add, change or delete', async () => {
  const value = book();
  await setDoc(ref(db('alice'), value), value);
  await assertFails(getDoc(ref(db(), value)));
  await assertFails(getDocs(collection(db(), 'books')));
  await assertFails(setDoc(ref(db(), value), value));
  await assertFails(updateDoc(ref(db(), value), { favorite: true }));
  await assertFails(deleteDoc(ref(db(), value)));
});

test('another UID cannot read, edit, delete, create as owner or take ownership', async () => {
  const value = book(), other = db('bob');
  await setDoc(ref(db('alice'), value), value);
  await assertFails(getDoc(ref(other, value)));
  await assertFails(updateDoc(ref(other, value), { favorite: true }));
  await assertFails(deleteDoc(ref(other, value)));
  await assertFails(setDoc(ref(other, value), value));
  await assertFails(updateDoc(ref(other, value), { userId: 'bob' }));
  await assertFails(updateDoc(ref(db('alice'), value), { userId: 'bob' }));
});

const invalidValues = [
  ['empty title', { title: '' }], ['spaces title', { title: ' \t\n ' }],
  ['long title', { title: 'a'.repeat(101) }],
  ['empty author', { author: '' }], ['spaces author', { author: ' \t ' }],
  ['long author', { author: 'a'.repeat(61) }],
  ['invalid genre', { genre: 'Romance' }], ['invalid status', { status: 'Done' }],
  ['rating float', { rating: 2.5 }], ['rating text', { rating: '5' }],
  ['rating low', { rating: -1 }], ['rating high', { rating: 6 }],
  ['rating null', { rating: null }], ['rating bool', { rating: true }],
  ['long notes', { notes: 'a'.repeat(301) }], ['notes type', { notes: 123 }],
  ['favorite type', { favorite: 'true' }], ['createdAt type', { createdAt: 'today' }],
  ['future timestamp', { createdAt: Timestamp.fromMillis(9999999999999) }],
  ['extra fields', { admin: true }],
];
for (const [name, changes] of invalidValues) {
  test(`direct create refuses ${name}`, async () => {
    const value = book('alice', changes);
    await assertFails(setDoc(ref(db('alice'), value), value));
  });
  test(`direct update refuses ${name}`, async () => {
    const value = book();
    await setDoc(ref(db('alice'), value), value);
    await assertFails(updateDoc(ref(db('alice'), value), changes));
  });
}

test('required fields, id equality and canonical document path are enforced', async () => {
  for (const field of ['id', 'userId', 'title', 'author', 'genre', 'status', 'favorite', 'notes', 'createdAt']) {
    const value = book(); const missing = { ...value }; delete missing[field];
    await assertFails(setDoc(ref(db('alice'), value), missing));
  }
  const value = book();
  await assertFails(setDoc(ref(db('alice'), value), { ...value, id: 'wrong' }));
  await assertFails(setDoc(doc(db('alice'), 'books', 'random-id'), { ...value, id: 'random-id' }));
});

test('boundaries, optional rating and all enum values are accepted', async () => {
  for (const genre of ['Fiction', 'Non-Fiction', 'Academic', 'Other']) {
    for (const status of ['To Read', 'Reading', 'Finished']) {
      const value = book('alice', { title: `${genre} ${status}`, genre, status });
      await assertSucceeds(setDoc(ref(db('alice'), value), value));
    }
  }
  const value = book('alice', { title: 'a'.repeat(100), author: 'b'.repeat(60), notes: 'c'.repeat(300) });
  await assertSucceeds(setDoc(ref(db('alice'), value), value));
  for (let rating = 0; rating <= 5; rating++) {
    await assertSucceeds(updateDoc(ref(db('alice'), value), { rating }));
  }
});

test('normalization works with Vietnamese, punctuation and slashes', async () => {
  for (const title of [' SÁCH Tiếng Việt ', 'a/b:c_é', 'DUNE']) {
    const value = book('uid_with_underscore', { title, author: ' PHẠM Huỳnh Sum ' });
    await assertSucceeds(setDoc(ref(db('uid_with_underscore'), value), value));
  }
});

test('same book is allowed for two different users', async () => {
  for (const uid of ['alice', 'bob']) {
    await assertSucceeds(setDoc(ref(db(uid), book(uid)), book(uid)));
  }
});

test('changed case cannot bypass unique canonical id through a random path', async () => {
  await setDoc(ref(db('alice'), book()), book());
  const value = book('alice', { title: ' dune ', author: 'FRANK HERBERT' });
  assert.equal(value.id, book().id);
  await assertFails(setDoc(doc(db('alice'), 'books', 'second-id'), { ...value, id: 'second-id' }));
});

async function addUnique(database, value) {
  await runTransaction(database, async transaction => {
    const existing = await transaction.get(ref(database, value));
    if (existing.exists()) throw new Error('Duplicate book');
    transaction.set(ref(database, value), value);
  });
}

test('concurrent adds produce one book and one duplicate error', async () => {
  const database = db('alice'), value = book();
  const results = await Promise.allSettled([addUnique(database, value), addUnique(database, value)]);
  assert.equal(results.filter(result => result.status === 'fulfilled').length, 1);
  assert.equal(results.filter(result => result.status === 'rejected').length, 1);
  const snapshot = await getDocs(query(collection(database, 'books'), where('userId', '==', 'alice')));
  assert.equal(snapshot.size, 1);
});

test('atomic rename preserves timestamp/favorite and clears an optional rating', async () => {
  const database = db('alice'), old = book('alice', { favorite: true, rating: 5 });
  await setDoc(ref(database, old), old);
  const next = book('alice', { title: 'A new title', favorite: true });
  await assertSucceeds(runTransaction(database, async transaction => {
    const source = await transaction.get(ref(database, old));
    const target = await transaction.get(ref(database, next));
    assert.equal(target.exists(), false);
    transaction.set(ref(database, next), { ...next, createdAt: source.data().createdAt });
    transaction.delete(ref(database, old));
  }));
  assert.equal((await getDoc(ref(database, old))).exists(), false);
  const saved = (await getDoc(ref(database, next))).data();
  assert.equal(saved.favorite, true); assert.equal('rating' in saved, false);
  assert.equal(saved.createdAt.toMillis(), old.createdAt.toMillis());
});

test('updates cannot change createdAt or access unrelated collections', async () => {
  const value = book(); await setDoc(ref(db('alice'), value), value);
  await assertFails(updateDoc(ref(db('alice'), value), { createdAt: Timestamp.fromMillis(2000) }));
  await assertFails(setDoc(doc(db('alice'), 'users', 'alice'), { name: 'Alice' }));
});
