// Sentry beforeSend scrubber (B-2 / R-2): coordinates and query strings
// must never reach Sentry. The scrubber is a pure function — unit-tested
// without initializing the SDK.

import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:weather_app/core/telemetry/sentry_service.dart';

void main() {
  test('full query redaction in exception values', () {
    final SentryEvent out = scrubEventForPrivacy(
      SentryEvent(
        exceptions: <SentryException>[
          SentryException(
            type: 'DioException',
            value:
                'GET https://api.open-meteo.com/v1/forecast?latitude=52.52&longitude=13.41 failed',
          ),
        ],
      ),
    );
    final String? value = out.exceptions!.first.value;
    expect(value, isNot(contains('latitude=')));
    expect(value, isNot(contains('52.52')));
    expect(value, contains('<redacted>'));
  });

  test('bare coordinate pairs are scrubbed', () {
    final SentryEvent out = scrubEventForPrivacy(
      SentryEvent(
        exceptions: <SentryException>[
          SentryException(type: 'StateError', value: 'bad fix 52.5234,13.4100'),
        ],
      ),
    );
    expect(out.exceptions!.first.value, isNot(contains('52.5234')));
  });

  test('request URLs are scrubbed', () {
    final SentryEvent out = scrubEventForPrivacy(
      SentryEvent(
        request: SentryRequest(
            url:
                'https://api.open-meteo.com/v1/forecast?latitude=1.0&longitude=2.0'),
      ),
    );
    expect(out.request!.url, isNot(contains('latitude=')));
  });

  test('breadcrumb data strings are scrubbed', () {
    final SentryEvent out = scrubEventForPrivacy(
      SentryEvent(
        breadcrumbs: <Breadcrumb>[
          Breadcrumb(
            message: 'retry',
            data: <String, dynamic>{
              'url': 'https://x.test/?lat=52.5&lon=13.4',
              'count': 2,
            },
          ),
        ],
      ),
    );
    expect(out.breadcrumbs!.first.data!['url'], isNot(contains('lat=')));
    expect(out.breadcrumbs!.first.data!['count'], 2);
  });

  test('non-sensitive text survives', () {
    final SentryEvent out = scrubEventForPrivacy(
      SentryEvent(
        exceptions: <SentryException>[
          SentryException(type: 'StateError', value: 'widget tree blew up'),
        ],
      ),
    );
    expect(out.exceptions!.first.value, 'widget tree blew up');
  });
}
