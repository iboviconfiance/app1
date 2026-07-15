const SubscriptionRepository = require('../../src/infrastructure/repositories/SubscriptionRepository');

describe('SubscriptionRepository', () => {
  const repo = new SubscriptionRepository();

  test('getPlans retourne les 3 forfaits', () => {
    const plans = repo.getPlans();
    expect(plans).toHaveLength(3);
    expect(plans.map(p => p.id)).toEqual(['gratuit', 'individuel', 'familial']);
  });

  test('getPlanPrice retourne les bons montants', () => {
    expect(repo.getPlanPrice('gratuit')).toBe(0);
    expect(repo.getPlanPrice('individuel')).toBe(5000);
    expect(repo.getPlanPrice('familial')).toBe(12000);
  });
});
