import '../entities/purchase_event.dart';
import '../entities/shopping_suggestion_item.dart';

/// Resultado del análisis: cuándo conviene avisarle al usuario que vaya de
/// compras y qué productos sugerirle, basado en su propio historial.
class ShoppingTripPrediction {
  ShoppingTripPrediction({
    required this.nextDate,
    required this.items,
    required this.tripsAnalyzed,
  });

  /// Próxima fecha/hora estimada del viaje de compras.
  final DateTime nextDate;

  /// Productos habituales sugeridos, ordenados por frecuencia descendente.
  final List<ShoppingSuggestionItem> items;

  /// Cantidad de viajes de compra distintos usados para el cálculo.
  final int tripsAnalyzed;
}

/// Analiza el historial de compras del usuario (100% en el dispositivo, sin
/// backend) para aprender dos cosas:
///
/// 1. Cada cuánto suele ir de compras (intervalo típico entre "viajes") y a
///    qué hora, para predecir la próxima fecha.
/// 2. Qué productos compra habitualmente y con qué cantidad/unidad típica,
///    para sugerírselos de una vez.
///
/// Un "viaje de compras" se define como el conjunto de productos marcados
/// como comprados el mismo día calendario: es una aproximación simple pero
/// suficientemente buena sin necesitar que el usuario confirme nada extra.
class ShoppingPatternAnalyzer {
  const ShoppingPatternAnalyzer();

  /// Viajes mínimos en el historial para animarse a predecir algo. Con menos
  /// de esto, cualquier intervalo calculado sería ruido.
  static const int minTripsForPrediction = 2;

  /// No mirar más allá de los últimos N viajes: los hábitos cambian y el
  /// historial viejo no debería pesar igual que el reciente.
  static const int maxTripsConsidered = 10;

  static const int maxSuggestions = 12;

  /// Un producto entra en la sugerencia si apareció en al menos esta
  /// proporción de los viajes considerados (o al menos 2 veces, ver abajo).
  static const double minFrequency = 0.34;

  ShoppingTripPrediction? analyze(List<PurchaseEvent> events) {
    if (events.isEmpty) return null;

    final byDay = <DateTime, List<PurchaseEvent>>{};
    for (final e in events) {
      final day = DateTime(e.purchasedAt.year, e.purchasedAt.month, e.purchasedAt.day);
      byDay.putIfAbsent(day, () => []).add(e);
    }

    final allDays = byDay.keys.toList()..sort();
    if (allDays.length < minTripsForPrediction) return null;

    final recentDays = allDays.length > maxTripsConsidered
        ? allDays.sublist(allDays.length - maxTripsConsidered)
        : allDays;

    // Intervalo típico entre viajes: la mediana es más robusta que el
    // promedio ante algún viaje aislado (ej. una compra de emergencia).
    final intervals = <int>[];
    for (var i = 1; i < recentDays.length; i++) {
      intervals.add(recentDays[i].difference(recentDays[i - 1]).inDays);
    }
    intervals.sort();
    final medianInterval = intervals[intervals.length ~/ 2];
    final safeInterval = medianInterval <= 0 ? 7 : medianInterval;

    // Hora habitual: promedio de la hora del día de todos los eventos
    // recientes, acotado a un rango razonable para no notificar de madrugada.
    final recentEvents = [for (final d in recentDays) ...byDay[d]!];
    final avgHour = (recentEvents.map((e) => e.purchasedAt.hour).reduce((a, b) => a + b) /
            recentEvents.length)
        .round()
        .clamp(8, 21);

    final lastDay = recentDays.last;
    var nextDate =
        DateTime(lastDay.year, lastDay.month, lastDay.day, avgHour).add(Duration(days: safeInterval));

    // Si el cálculo cae en el pasado (la app estuvo cerrada más tiempo del
    // esperado), reprogramar para el próximo día a esa misma hora en vez de
    // dejar una fecha vencida.
    final now = DateTime.now();
    if (!nextDate.isAfter(now)) {
      nextDate = DateTime(now.year, now.month, now.day, avgHour).add(const Duration(days: 1));
    }

    // Frecuencia por producto: una aparición por día como máximo (evita que
    // un producto agregado dos veces el mismo día infle su frecuencia).
    final totalTrips = recentDays.length;
    final perProduct = <String, List<PurchaseEvent>>{};
    for (final day in recentDays) {
      final seenToday = <String>{};
      for (final e in byDay[day]!) {
        if (!seenToday.add(e.productKey.trim().toLowerCase())) continue;
        perProduct.putIfAbsent(e.productKey, () => []).add(e);
      }
    }

    final suggestions = <ShoppingSuggestionItem>[];
    perProduct.forEach((productKey, evs) {
      final frequency = evs.length / totalTrips;
      if (frequency < minFrequency && evs.length < 2) return;
      suggestions.add(ShoppingSuggestionItem(
        productKey: productKey,
        categoryKey: evs.last.categoryKey,
        quantity: _typicalQuantity(evs),
        unit: _typicalUnit(evs),
        frequency: frequency,
      ));
    });

    suggestions.sort((a, b) => b.frequency.compareTo(a.frequency));

    return ShoppingTripPrediction(
      nextDate: nextDate,
      items: suggestions.take(maxSuggestions).toList(),
      tripsAnalyzed: totalTrips,
    );
  }

  /// Moda de las cantidades registradas (la más repetida); si nunca se
  /// registró cantidad, devuelve null (se sugiere sin cantidad).
  double? _typicalQuantity(List<PurchaseEvent> events) {
    final counts = <double, int>{};
    for (final e in events) {
      final q = e.quantity;
      if (q != null) counts[q] = (counts[q] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  String? _typicalUnit(List<PurchaseEvent> events) {
    final counts = <String, int>{};
    for (final e in events) {
      final u = e.unit;
      if (u != null && u.isNotEmpty) counts[u] = (counts[u] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}
