import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { after, before, beforeEach, test } from 'node:test';

// Use the CommonJS exports because the rules testing package loads Firebase's
// compat database entry point, which currently has no ESM file in the SDK.
const require = createRequire(import.meta.url);
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
} = require('firebase/firestore');

const projectId = 'demo-taskflow';
let testEnvironment;

before(async () => {
  const rules = await readFile(new URL('../firestore.rules', import.meta.url), 'utf8');
  testEnvironment = await initializeTestEnvironment({
    projectId,
    firestore: { rules },
  });
});

after(async () => {
  await testEnvironment?.cleanup();
});

beforeEach(async () => {
  await testEnvironment.clearFirestore();
});

test('a signed-in user can manage their own profile and tasks', async () => {
  const alice = testEnvironment.authenticatedContext('alice').firestore();
  const profile = doc(alice, 'users/alice');
  const task = doc(alice, 'users/alice/tasks/task-1');

  await assertSucceeds(setDoc(profile, { email: 'alice@example.test' }));
  await assertSucceeds(setDoc(task, { title: 'Write tests', status: 'todo' }));
  await assertSucceeds(getDoc(profile));
  await assertSucceeds(getDoc(task));
  await assertSucceeds(getDocs(collection(alice, 'users/alice/tasks')));
  await assertSucceeds(updateDoc(task, { status: 'done' }));
  await assertSucceeds(deleteDoc(task));
});

test('unauthenticated clients cannot access profiles or tasks', async () => {
  const anonymous = testEnvironment.unauthenticatedContext().firestore();
  const profile = doc(anonymous, 'users/alice');
  const task = doc(anonymous, 'users/alice/tasks/task-1');

  await assertFails(getDoc(profile));
  await assertFails(setDoc(profile, { email: 'intruder@example.test' }));
  await assertFails(getDoc(task));
  await assertFails(setDoc(task, { title: 'Unauthorized task' }));
});

test('a user cannot read or change another user’s profile or tasks', async () => {
  const alice = testEnvironment.authenticatedContext('alice').firestore();
  const bob = testEnvironment.authenticatedContext('bob').firestore();
  const aliceProfile = doc(alice, 'users/alice');
  const aliceTask = doc(alice, 'users/alice/tasks/task-1');
  const bobProfile = doc(bob, 'users/alice');
  const bobTask = doc(bob, 'users/alice/tasks/task-1');

  await assertSucceeds(setDoc(aliceProfile, { email: 'alice@example.test' }));
  await assertSucceeds(setDoc(aliceTask, { title: 'Private task' }));

  await assertFails(getDoc(bobProfile));
  await assertFails(setDoc(bobProfile, { email: 'changed@example.test' }));
  await assertFails(getDoc(bobTask));
  await assertFails(getDocs(collection(bob, 'users/alice/tasks')));
  await assertFails(updateDoc(bobTask, { title: 'Changed by Bob' }));
  await assertFails(deleteDoc(bobTask));
});

test('users cannot access data outside the explicitly allowed user paths', async () => {
  const alice = testEnvironment.authenticatedContext('alice').firestore();

  await assertFails(setDoc(doc(alice, 'admin/secrets'), { value: 'private' }));
});

test('the rules file remains present and scoped to the authenticated uid', async () => {
  const rules = await readFile(new URL('../firestore.rules', import.meta.url), 'utf8');

  assert.match(rules, /request\.auth\.uid\s*==\s*userId/);
  assert.match(rules, /match \/users\/{userId}/);
  assert.match(rules, /match \/tasks\/{taskId}/);
});
