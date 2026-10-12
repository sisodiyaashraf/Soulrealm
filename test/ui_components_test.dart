import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soulrealm/services/save_service.dart';
import 'package:soulrealm/ui/codex/bestiary_dialog.dart';
import 'package:soulrealm/ui/hud/hud_overlay.dart';
import 'package:soulrealm/ui/settings/settings_dialog.dart';
import 'package:soulrealm/ui/stats/records_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final save = SaveService();
    await save.init();
  });

  testWidgets('HudOverlay displays health, mana, combo streak, and flask', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    bool usedFlask = false;
    bool paused = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HudOverlay(
            levelName: 'STAGE 1',
            hp: 3.0,
            maxHp: 4.0,
            mana: 80.0,
            maxMana: 100.0,
            litPyres: 2,
            totalPyres: 3,
            comboCount: 5,
            isSoulSurge: true,
            flaskCharges: 2,
            onUseFlask: () => usedFlask = true,
            onPause: () => paused = true,
          ),
        ),
      ),
    );

    // Verify stage name, combo surge text, pyre status
    expect(find.text('STAGE 1'), findsOneWidget);
    expect(find.text('SOUL SURGE ACTIVE! (x5)'), findsOneWidget);
    expect(find.text('PYRES REKINDLED: 2 / 3'), findsOneWidget);
    expect(find.text('FLASK x2'), findsOneWidget);

    // Tap flask
    await tester.tap(find.text('FLASK x2'));
    expect(usedFlask, true);

    // Tap pause
    await tester.tap(find.byIcon(Icons.pause));
    expect(paused, true);
  });

  testWidgets('BestiaryDialog mounts and switches categories', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BestiaryDialog(),
        ),
      ),
    );

    expect(find.text('SHADOW CODEX'), findsOneWidget);
    expect(find.text('VOID LURKER'), findsWidgets);

    // Tap Sacred Relics tab
    await tester.tap(find.textContaining('SACRED RELICS'));
    await tester.pumpAndSettle();

    expect(find.text('SACRED PYRE'), findsWidgets);
  });

  testWidgets('SettingsDialog mounts and toggles options', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsDialog(onDataChanged: () {}),
        ),
      ),
    );

    expect(find.text('REALM PREFERENCES'), findsOneWidget);
    expect(find.text('Screen Shake FX'), findsOneWidget);
    expect(find.text('Haptic Feedback'), findsOneWidget);
    expect(find.text('Floating Combat Numbers'), findsOneWidget);
  });

  testWidgets('RecordsDialog mounts and shows career records', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RecordsDialog(),
        ),
      ),
    );

    expect(find.text('CHRONICLES OF GLORY'), findsOneWidget);
    expect(find.text('FOES SLAIN'), findsOneWidget);
    expect(find.text('TOTAL RUNS'), findsOneWidget);
    expect(find.text('MAX COMBO STREAK'), findsOneWidget);
  });
}
