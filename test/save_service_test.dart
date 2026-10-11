import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soulrealm/services/save_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('SaveService shards and upgrades test', () async {
    final save = SaveService();
    await save.init();

    // Default stats
    expect(save.getSoulShards(), 0);
    expect(save.getMaxHealth(), 3.0);
    expect(save.getPlayerSpeed(), 120.0);
    expect(save.getPlayerDamage(), 1.0);
    expect(save.getDashCooldownSeconds(), 1.4);

    // Add shards
    await save.addSoulShards(50);
    expect(save.getSoulShards(), 50);

    // Purchase health upgrade (costs 15)
    final bought = await save.purchaseUpgrade('health');
    expect(bought, true);
    expect(save.getSoulShards(), 35);
    expect(save.getUpgradeLevel('health'), 1);
    expect(save.getMaxHealth(), 4.0);

    // Stars
    expect(save.getLevelStars(1), 0);
    await save.saveLevelStars(1, 3);
    expect(save.getLevelStars(1), 3);
    expect(save.getTotalStars(), 3);
  });
}
