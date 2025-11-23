enum Flavor { dev, prod }

class FlavorConfig {
  final Flavor flavor;
  final String name;
  final String firebaseProjectId;

  FlavorConfig._({
    required this.flavor,
    required this.name,
    required this.firebaseProjectId,
  });

  static FlavorConfig? _instance;

  static FlavorConfig get instance {
    if (_instance == null) {
      throw Exception(
        'FlavorConfig not initialized. Call FlavorConfig.initialize() first.',
      );
    }
    return _instance!;
  }

  static void initialize({required Flavor flavor}) {
    switch (flavor) {
      case Flavor.dev:
        _instance = FlavorConfig._(
          flavor: Flavor.dev,
          name: 'Development',
          firebaseProjectId: 'honeysales', // 既存の開発用プロジェクト
        );
        break;
      case Flavor.prod:
        _instance = FlavorConfig._(
          flavor: Flavor.prod,
          name: 'Production',
          firebaseProjectId: 'YOUR_PROD_PROJECT_ID', // 本番用プロジェクトIDに置き換え
        );
        break;
    }
  }

  bool get isDev => flavor == Flavor.dev;
  bool get isProd => flavor == Flavor.prod;
}
