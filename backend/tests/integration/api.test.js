const request = require('supertest');
const { createApp } = require('../../src/server');

const app = createApp();

describe('API Integration Tests', () => {
  let authToken;
  const testPhone = `+23767${Date.now().toString().slice(-7)}`;
  const testEmail = `test_${Date.now()}@example.com`;

  describe('Health', () => {
    test('GET /api/health', async () => {
      const res = await request(app).get('/api/health');
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });
  });

  describe('School', () => {
    test('GET /api/school/hierarchy', async () => {
      const res = await request(app).get('/api/school/hierarchy');
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });

    test('GET /api/school/classrooms', async () => {
      const res = await request(app).get('/api/school/classrooms');
      expect(res.status).toBe(200);
      expect(Array.isArray(res.body.data)).toBe(true);
    });
  });

  describe('Auth', () => {
    test('POST /api/auth/register', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          nom: 'Test',
          prenom: 'User',
          telephone: testPhone,
          email: testEmail,
          password: 'password123',
          etablissement: 'Lycée Test',
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.token).toBeDefined();
      authToken = res.body.data.token;
    });

    test('POST /api/auth/login avec telephone', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ telephone: testPhone, password: 'password123' });

      expect(res.status).toBe(200);
      expect(res.body.data.token).toBeDefined();
      authToken = res.body.data.token;
    });

    test('POST /api/auth/login avec email', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ identifier: testEmail, password: 'password123' });

      expect(res.status).toBe(200);
      expect(res.body.data.token).toBeDefined();
    });

    test('POST /api/auth/login avec mauvais mot de passe', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ telephone: testPhone, password: 'wrong' });

      expect(res.status).toBe(401);
    });
  });

  describe('Protected routes', () => {
    test('GET /api/dashboard sans token', async () => {
      const res = await request(app).get('/api/dashboard');
      expect(res.status).toBe(401);
    });

    test('GET /api/dashboard avec token', async () => {
      if (!authToken) return;
      const res = await request(app)
        .get('/api/dashboard')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.progression).toBeDefined();
    });

    test('GET /api/users/profile', async () => {
      if (!authToken) return;
      const res = await request(app)
        .get('/api/users/profile')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.telephone).toBe(testPhone);
    });
  });

  describe('Subscriptions', () => {
    test('GET /api/subscriptions/plans', async () => {
      const res = await request(app).get('/api/subscriptions/plans');
      expect(res.status).toBe(200);
      expect(res.body.data).toHaveLength(3);
    });

    test('POST /api/subscriptions/subscribe avec Airtel Money', async () => {
      if (!authToken) return;
      const res = await request(app)
        .post('/api/subscriptions/subscribe')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          plan: 'individuel',
          method: 'airtel_money',
          phoneNumber: testPhone,
        });

      expect(res.status).toBe(200);
      expect(res.body.data.payment.status).toBe('completed');
    });
  });

  describe('Work Groups', () => {
    let groupId;
    let inviteCode;

    test('POST /api/work-groups', async () => {
      if (!authToken) return;
      const res = await request(app)
        .post('/api/work-groups')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name: 'Groupe Maths', description: 'Révisions' });

      expect(res.status).toBe(201);
      groupId = res.body.data.id;
      inviteCode = res.body.data.inviteCode;
    });

    test('GET /api/work-groups', async () => {
      if (!authToken) return;
      const res = await request(app)
        .get('/api/work-groups')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.length).toBeGreaterThan(0);
    });

    test('GET /api/work-groups/:id', async () => {
      if (!authToken || !groupId) return;
      const res = await request(app)
        .get(`/api/work-groups/${groupId}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.members).toBeDefined();
    });
  });
});
