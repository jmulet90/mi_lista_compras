typedef Factory<T> = T Function();

class ServiceLocator {
  final Map<Type, dynamic> _instances = {};
  final Map<Type, Factory<dynamic>> _factories = {};

  void registerLazySingleton<T>(Factory<T> factory) {
    _factories[T] = factory;
  }

  T get<T>() {
    if (_instances.containsKey(T)) {
      return _instances[T] as T;
    }
    if (_factories.containsKey(T)) {
      final instance = _factories[T]!() as T;
      _instances[T] = instance;
      return instance;
    }
    throw StateError('No hay ninguna dependencia registrada para $T');
  }

  /// Permite usar la sintaxis `sl<T>()`.
  T call<T>() => get<T>();

  void reset() {
    _instances.clear();
    _factories.clear();
  }
}

final sl = ServiceLocator();
