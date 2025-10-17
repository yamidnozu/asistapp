import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

// Interfaces
interface User {
  displayName: string;
  email: string;
  roles: string[];
  sites: string[];
  status: 'active' | 'inactive';
  createdAt: admin.firestore.Timestamp;
}

interface Site {
  name: string;
  address: string;
  geo?: { lat: number; lng: number };
  active: boolean;
}

interface Job {
  name: string;
  description: string;
  siteIds: string[];
}

interface Responsibility {
  name: string;
  description: string;
  jobIds: string[];
}

interface Task {
  title: string;
  description: string;
  responsibilityId: string;
  location?: string;
  evidenceRequired: boolean;
  durationMin?: number;
  priority?: 'low' | 'medium' | 'high';
  recurrence: {
    type: 'once' | 'daily' | 'weekly' | 'custom';
    times: string[];
    daysOfWeek: number[];
    dateRange?: { start: admin.firestore.Timestamp; end: admin.firestore.Timestamp };
  };
  createdAt: admin.firestore.Timestamp;
}

// Trigger: Create user doc on auth user creation
export const onUserCreate = functions.auth.user().onCreate(async (user) => {
  // Check if this is the first user
  const usersCollection = admin.firestore().collection('taskmonitoring').doc('users').collection('users');
  const existingUsers = await usersCollection.limit(1).get();
  const isFirstUser = existingUsers.docs.length === 0;

  const userDoc: User = {
    displayName: user.displayName || '',
    email: user.email || '',
    roles: isFirstUser ? ['super_admin'] : ['employee'],
    sites: [],
    status: 'active',
    createdAt: admin.firestore.Timestamp.now(),
  };

  await admin.firestore().collection('taskmonitoring').doc('users').collection('users').doc(user.uid).set(userDoc);

  // If this is the first user, create config document
  if (isFirstUser) {
    await admin.firestore().collection('taskmonitoring').doc('config').set({
      superAdminUids: [user.uid],
      allowSeed: true,
      version: '1.0.0',
      createdAt: admin.firestore.Timestamp.now(),
    });
  }
});

// Callable: Set custom claims
export const setCustomClaims = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { uid, roles, siteIds } = data;

  // Check if caller is super admin
  const configDoc = await admin.firestore().collection('taskmonitoring').doc('config').get();
  if (!configDoc.exists) {
    throw new functions.https.HttpsError('failed-precondition', 'Config not found');
  }

  const superAdminUids = configDoc.data()?.superAdminUids || [];
  if (!superAdminUids.includes(context.auth.uid)) {
    throw new functions.https.HttpsError('permission-denied', 'Only super admins can set custom claims');
  }

  await admin.auth().setCustomUserClaims(uid, { roles, siteIds });
  return { success: true };
});

// Callable: Seed demo data
export const seedDemo = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  // Check if caller is super admin
  const configDoc = await admin.firestore().collection('taskmonitoring').doc('config').get();
  if (!configDoc.exists) {
    throw new functions.https.HttpsError('failed-precondition', 'Config not found');
  }

  const superAdminUids = configDoc.data()?.superAdminUids || [];
  if (!superAdminUids.includes(context.auth.uid)) {
    throw new functions.https.HttpsError('permission-denied', 'Only super admins can seed demo');
  }

  const batch = admin.firestore().batch();

  // Sites
  const sites: { [key: string]: Site } = {
    site1: { name: 'Oficina Central', address: 'Calle Principal 123', active: true },
    site2: { name: 'Sucursal Norte', address: 'Avenida Norte 456', active: true },
  };

  for (const [id, site] of Object.entries(sites)) {
    const ref = admin.firestore().collection('taskmonitoring').doc('sites').collection('sites').doc(id);
    batch.set(ref, site);
  }

  // Jobs
  const jobs: { [key: string]: Job } = {
    job1: { name: 'Gerente', description: 'Gestión general', siteIds: ['site1', 'site2'] },
    job2: { name: 'Empleado', description: 'Trabajador general', siteIds: ['site1', 'site2'] },
  };

  for (const [id, job] of Object.entries(jobs)) {
    const ref = admin.firestore().collection('taskmonitoring').doc('jobs').collection('jobs').doc(id);
    batch.set(ref, job);
  }

  // Responsibilities
  const responsibilities: { [key: string]: Responsibility } = {
    resp1: { name: 'Limpieza', description: 'Mantener áreas limpias', jobIds: ['job2'] },
    resp2: { name: 'Reportes', description: 'Generar reportes diarios', jobIds: ['job1', 'job2'] },
  };

  for (const [id, resp] of Object.entries(responsibilities)) {
    const ref = admin.firestore().collection('taskmonitoring').doc('responsibilities').collection('responsibilities').doc(id);
    batch.set(ref, resp);
  }

  // Tasks
  const tasks: { [key: string]: Task } = {
    task1: {
      title: 'Limpiar oficina',
      description: 'Limpiar mesas y pisos',
      responsibilityId: 'resp1',
      location: 'Oficina',
      evidenceRequired: true,
      durationMin: 30,
      priority: 'medium',
      recurrence: {
        type: 'daily',
        times: ['09:00'],
        daysOfWeek: [1, 2, 3, 4, 5],
      },
      createdAt: admin.firestore.Timestamp.now(),
    },
    task2: {
      title: 'Generar reporte diario',
      description: 'Crear reporte de actividades',
      responsibilityId: 'resp2',
      evidenceRequired: false,
      durationMin: 15,
      priority: 'high',
      recurrence: {
        type: 'daily',
        times: ['17:00'],
        daysOfWeek: [1, 2, 3, 4, 5],
      },
      createdAt: admin.firestore.Timestamp.now(),
    },
  };

  for (const [id, task] of Object.entries(tasks)) {
    const ref = admin.firestore().collection('taskmonitoring').doc('tasks').collection('tasks').doc(id);
    batch.set(ref, task);
  }

  await batch.commit();
  return { success: true };
});

// Callable: Clear seed data
export const clearSeed = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  // Check if caller is super admin
  const configDoc = await admin.firestore().collection('taskmonitoring').doc('config').get();
  if (!configDoc.exists) {
    throw new functions.https.HttpsError('failed-precondition', 'Config not found');
  }

  const superAdminUids = configDoc.data()?.superAdminUids || [];
  if (!superAdminUids.includes(context.auth.uid)) {
    throw new functions.https.HttpsError('permission-denied', 'Only super admins can clear seed');
  }

  const collections = ['sites', 'jobs', 'responsibilities', 'tasks', 'assignments', 'logs'];

  for (const collection of collections) {
    const query = await admin.firestore().collection('taskmonitoring').doc(collection).collection(collection).get();
    const batch = admin.firestore().batch();
    query.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    await batch.commit();
  }

  return { success: true };
});

// Callable: Reset database
export const resetDatabase = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  // Check if caller is super admin
  const configDoc = await admin.firestore().collection('taskmonitoring').doc('config').get();
  if (!configDoc.exists) {
    throw new functions.https.HttpsError('failed-precondition', 'Config not found');
  }

  const superAdminUids = configDoc.data()?.superAdminUids || [];
  if (!superAdminUids.includes(context.auth.uid)) {
    throw new functions.https.HttpsError('permission-denied', 'Only super admins can reset database');
  }

  const collections = ['sites', 'jobs', 'responsibilities', 'tasks', 'assignments', 'logs', 'users'];

  for (const collection of collections) {
    const query = await admin.firestore().collection('taskmonitoring').doc(collection).collection(collection).get();
    const batch = admin.firestore().batch();
    query.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    await batch.commit();
  }

  // Recreate config
  await admin.firestore().collection('taskmonitoring').doc('config').set({
    superAdminUids,
    allowSeed: true,
    version: '1.0.0',
    createdAt: admin.firestore.Timestamp.now(),
  });

  return { success: true };
});