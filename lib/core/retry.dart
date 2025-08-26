import 'dart:async';

/// 429/일시적 실패 등을 대비한 지수 백오프 재시도 유틸
Future<T> retry<T>(
    Future<T> Function() run, {
      int maxAttempts = 3,
      Duration initialDelay = const Duration(milliseconds: 500),
      bool Function(Object error)? retryIf,
      void Function(int attempt, Object error)? onBeforeRetry,
    }) async {
  var attempt = 0;
  var delay = initialDelay;

  while (true) {
    try {
      return await run();
    } catch (e) {
      attempt++;
      final shouldRetry = attempt < maxAttempts &&
          (retryIf?.call(e) ??
              e.toString().contains('429') ||
                  e.toString().contains('rateLimit') ||
                  e.toString().contains('RESOURCE_EXHAUSTED') ||
                  e.toString().contains('deadline exceeded') ||
                  e.toString().contains('internal error') ||
                  e.toString().contains('503'));
      if (!shouldRetry) rethrow;

      onBeforeRetry?.call(attempt, e);
      await Future.delayed(delay);
      delay *= 2; // 지수 증가
    }
  }
}
