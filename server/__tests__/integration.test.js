const request = require('supertest');
const app = require('../index');

describe('Integration Tests', () => {
  let authToken;
  let workspaceId;

  beforeAll(async () => {
    // Setup test database
    // This would typically involve running migrations and seeding test data
  });

  afterAll(async () => {
    // Cleanup test database
  });

  describe('Authentication Flow', () => {
    test('should register a new user', async () => {
      const userData = {
        username: 'testuser',
        password: 'testpassword123',
        email: 'test@example.com'
      };

      const response = await request(app)
        .post('/api/auth/register')
        .send(userData)
        .expect(201);

      expect(response.body).toHaveProperty('token');
      authToken = response.body.token;
    });

    test('should login with valid credentials', async () => {
      const loginData = {
        username: 'testuser',
        password: 'testpassword123'
      };

      const response = await request(app)
        .post('/api/auth/login')
        .send(loginData)
        .expect(200);

      expect(response.body).toHaveProperty('token');
    });
  });

  describe('Workspace Management', () => {
    beforeEach(() => {
      // Set auth token for authenticated requests
      if (!authToken) {
        // Login to get token
      }
    });

    test('should create a new workspace', async () => {
      const workspaceData = {
        name: 'Test Workspace',
        description: 'A test workspace'
      };

      const response = await request(app)
        .post('/api/workspaces')
        .set('Authorization', `Bearer ${authToken}`)
        .send(workspaceData)
        .expect(201);

      expect(response.body).toHaveProperty('id');
      workspaceId = response.body.id;
    });

    test('should get workspace list', async () => {
      const response = await request(app)
        .get('/api/workspaces')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
    });
  });

  describe('Document Processing', () => {
    test('should upload and process a document', async () => {
      const formData = new FormData();
      formData.append('file', 'test document content');
      formData.append('workspaceId', workspaceId);

      const response = await request(app)
        .post('/api/documents/upload')
        .set('Authorization', `Bearer ${authToken}`)
        .send(formData)
        .expect(200);

      expect(response.body).toHaveProperty('documentId');
    });
  });

  describe('Chat Functionality', () => {
    test('should send a chat message', async () => {
      const messageData = {
        message: 'Hello, how are you?',
        workspaceId: workspaceId
      };

      const response = await request(app)
        .post('/api/chat')
        .set('Authorization', `Bearer ${authToken}`)
        .send(messageData)
        .expect(200);

      expect(response.body).toHaveProperty('response');
    });
  });
});
