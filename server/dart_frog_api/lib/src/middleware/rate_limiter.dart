import 'package:dart_frog/dart_frog.dart';

import '../core/errors/app_exception.dart';

/// Simple in-process fixed-window rate limiter, keyed by client IP.
///
/// This is intentionally minimal: it protects a single server instance from
/// abuse and accidental client retry storms. It is NOT a substitute for a
/// shared limiter once the API is horizontally scaled — at that point back
/// this with Redis (`REDIS_URL` is already reserved for this in .env.example)
/// instead of the in-memory map below.
class RateLimiter {
  RateLimiter({this.maxRequests = 60, this.window = const Duration(minutes: 1)});

  final int maxRequests;
  final Duration window;

  final Map<String, _Bucket> _buckets = {};

  void checkAndRecord(String key) {
    final now = DateTime.now();
    final bucket = _buckets[key];
    if (bucket == null || now.difference(bucket.windowStart) > window) {
      _buckets[key] = _Bucket(windowStart: now, count: 1);
      return;
    }
    if (bucket.count >= maxRequests) {
      throw AppException.rateLimited('Too many requests. Please slow down and try again shortly.');
    }
    bucket.count++;
  }
}

class _Bucket {
  _Bucket({required this.windowStart, required this.count});
  final DateTime windowStart;
  int count;
}

Middleware rateLimitMiddleware(RateLimiter limiter) {
  return (handler) {
    return (context) async {
      limiter.checkAndRecord(_clientKey(context));
      return handler(context);
    };
  };
}

/// Resolves a best-effort client identifier from proxy headers. Production
/// deployments should sit behind a reverse proxy / load balancer that sets
/// `X-Forwarded-For`; when absent (e.g. local dev), all requests share one
/// bucket, which is acceptable for a single-developer environment.
String _clientKey(RequestContext context) {
  final forwardedFor = context.request.headers['x-forwarded-for'];
  if (forwardedFor != null && forwardedFor.isNotEmpty) {
    return forwardedFor.split(',').first.trim();
  }
  final realIp = context.request.headers['x-real-ip'];
  if (realIp != null && realIp.isNotEmpty) return realIp;
  return 'unknown';
}
