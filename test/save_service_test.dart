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

    // Mana upgrade (costs 15)
    expect(save.getMaxMana(), 100.0);
    expect(save.getManaRegenRate(), 12.0);
    final boughtMana = await save.purchaseUpgrade('mana');
    expect(boughtMana, true);
    expect(save.getSoulShards(), 20);
    expect(save.getUpgradeLevel('mana'), 1);
    expect(save.getMaxMana(), 125.0);
    expect(save.getManaRegenRate(), 15.0);

    // Stars & Titles
    expect(save.getLevelStars(1), 0);
    await save.saveLevelStars(1, 3);
    expect(save.getLevelStars(1), 3);
    expect(save.getTotalStars(), 3);
    expect(save.getPlayerTitle(), 'EMBER INITIATE');

    // Settings
    expect(save.getScreenShake(), true);
    await save.setScreenShake(false);
    expect(save.getScreenShake(), false);

    // Lifetime stats
    expect(save.getTotalEnemiesSlain(), 0);
    await save.incrementEnemiesSlain(5);
    expect(save.getTotalEnemiesSlain(), 5);

    await save.recordCombo(8);
    expect(save.getHighestCombo(), 8);
  });
}
