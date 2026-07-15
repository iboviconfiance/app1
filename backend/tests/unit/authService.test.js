const jwt = require('jsonwebtoken');
const config = require('../../src/config');
const AuthService = require('../../src/application/services/AuthService');

describe('AuthService', () => {
  const authService = new AuthService();

  test('generateToken produit un JWT valide', () => {
    const userId = 'test-user-id';
    const token = authService.generateToken(userId);
    const decoded = jwt.verify(token, config.jwt.secret);
    expect(decoded.userId).toBe(userId);
  });
});
