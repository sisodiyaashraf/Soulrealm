import 'package:bonfire/bonfire.dart';
import 'package:bonfire/map/base/layer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:xml/xml.dart';
import 'tiles/tiles.dart';

class MapLoader {
  /// Parses the isometric TMX map and generates the list of Tiles
  /// and interactive components (like pyres and portals).
  static Future<MapLoadResult> load(
    String tmxAssetPath, {
    required Function(int) onPyreLit,
    required Function(int) onPortalTrigger,
    required Sprite pyreUnlitSprite,
    bool isPortalActive = true,
    required List<int> unlockedLevels,
    VoidCallback? onHealFountain,
    VoidCallback? onReadLore,
  }) async {
    final tmxString = await rootBundle.loadString(tmxAssetPath);
    final document = XmlDocument.parse(tmxString);
    final mapElement = document.rootElement;

    final width = int.parse(mapElement.getAttribute('width')!);
    final height = int.parse(mapElement.getAttribute('height')!);
    
    final dataElement = document.findAllElements('data').first;
    final csvText = dataElement.innerText.trim();
    final tileIds = csvText
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map(int.parse)
        .toList();

    final List<Tile> tiles = [];
    final List<GameComponent> dynamicComponents = [];
    final List<Vector2> enemySpawnPoints = [];
    final List<Vector2> shardSpawnPoints = [];
    Vector2 playerSpawnPoint = Vector2(64, 64); // fallback spawn

    // Tile size in pixels (must match the tileset tile dimensions)
    const double tileW = 64.0;
    const double tileH = 64.0;

    // Map origin offset to center it visually
    const double originX = 200.0;
    const double originY = 50.0;

    int pyreCount = 0;
    int portalCount = 0;
    final isOverworld = tmxAssetPath.contains('overworld');

    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        final index = row * width + col;
        if (index >= tileIds.length) continue;
        final tileId = tileIds[index];

        // Screen coordinate (isometric projection)
        final double screenX = originX + (col - row) * 32.0;
        final double screenY = originY + (col + row) * 16.0;
        
        if (tileId != 0) {
          tiles.add(
            Tile(
              // Tile x/y are grid indices; Bonfire multiplies by width/height
              x: screenX / tileW,
              y: (screenY - 16) / tileH,
              width: tileW,
              height: tileH,
              sprite: TileSprite(
                path: 'tileset.png',
                // TileSprite position is col/row index (0-based)
                position: Vector2(0, 0), // col 0 = floor tile
                size: Vector2(tileW, tileH),
              ),
            ),
          );
        }

        if (tileId == 1) {
          // Set player spawn point to the first open floor tile in the middle-ish
          if (row == height ~/ 2 && col == width ~/ 2) {
            playerSpawnPoint = Vector2(screenX + 16, screenY);
          } else if (!isOverworld) {
            // Spawn soul shards on floor tiles
            if ((row * 3 + col) % 6 == 0) {
              shardSpawnPoints.add(Vector2(screenX + 20, screenY));
            }
          }
        } else if (tileId == 2) {
          // Wall
          tiles.add(
            Tile(
              x: screenX / tileW,
              y: (screenY - 16) / tileH,
              width: tileW,
              height: tileH,
              sprite: TileSprite(
                path: 'tileset.png',
                position: Vector2(1, 0), // col 1 = wall tile
                size: Vector2(tileW, tileH),
              ),
              collisions: [
                RectangleHitbox(
                  size: Vector2(24, 16),
                  position: Vector2(20, 36),
                ),
              ],
            ),
          );
        } else if (tileId == 3) {
          // Pyre location
          pyreCount++;
          dynamicComponents.add(
            PyreComponent(
              id: pyreCount,
              initialPosition: Vector2(screenX, screenY - 16),
              onLit: () => onPyreLit(pyreCount),
              unlitSprite: pyreUnlitSprite,
            ),
          );
        } else if (tileId == 4) {
          // Portal location
          portalCount++;
          final targetLevelId = portalCount;
          final isThisPortalActive = isOverworld
              ? unlockedLevels.contains(targetLevelId)
              : isPortalActive;

          dynamicComponents.add(
            PortalComponent(
              initialPosition: Vector2(screenX, screenY - 16),
              onTrigger: () => onPortalTrigger(targetLevelId),
              isActive: isThisPortalActive,
            ),
          );
        }

        // Spawn shadow enemies at random floor tiles that are not near spawn point
        if (tileId == 1 && (row != height ~/ 2 && col != width ~/ 2) && !isOverworld) {
          if ((row + col) % 7 == 0) {
            enemySpawnPoints.add(Vector2(screenX + 16, screenY));
          }
        }
      }
    }

    // Add sanctuary fountain and lore obelisk to overworld
    if (isOverworld) {
      dynamicComponents.add(
        SanctuaryFountain(
          initialPosition: Vector2(originX - 60, originY + 120),
          onHeal: onHealFountain ?? () {},
        ),
      );
      dynamicComponents.add(
        LoreObelisk(
          initialPosition: Vector2(originX + 80, originY + 100),
          onRead: onReadLore ?? () {},
        ),
      );
    }

    return MapLoadResult(
      map: WorldMap([
        Layer(id: 1, tiles: tiles),
      ]),
      components: dynamicComponents,
      playerSpawn: playerSpawnPoint,
      enemySpawns: enemySpawnPoints,
      shardSpawns: shardSpawnPoints,
    );
  }
}

class MapLoadResult {
  final WorldMap map;
  final List<GameComponent> components;
  final Vector2 playerSpawn;
  final List<Vector2> enemySpawns;
  final List<Vector2> shardSpawns;

  MapLoadResult({
    required this.map,
    required this.components,
    required this.playerSpawn,
    required this.enemySpawns,
    required this.shardSpawns,
  });
}
