const SubscriptionRepository = require('../../src/infrastructure/repositories/SubscriptionRepository');

describe('SubscriptionRepository', () => {
  const repo = new SubscriptionRepository();

  test('getPlans retourne les 3 forfaits', async () => {
    const plans = await repo.getPlans();
    expect(plans).toHaveLength(3);
    expect(plans.map(p => p.id)).toEqual(['gratuit', 'individuel', 'familial']);
  });

  test('getPlanPrice retourne les bons montants', async () => {
    expect(await repo.getPlanPrice('gratuit')).toBe(0);
    expect(await repo.getPlanPrice('individuel')).toBe(5000);
    expect(await repo.getPlanPrice('familial')).toBe(12000);
  });
});
