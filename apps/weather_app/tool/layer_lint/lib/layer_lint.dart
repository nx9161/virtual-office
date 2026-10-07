// Weather App layer-enforcement lints (R-9).
//
// Three rules:
//  * no_data_imports_in_presentation — lib/features/** (and the pure core
//    dirs: units, error, validation, utils) must never import lib/data/** or
//    transport/storage/plugin packages — EXCEPT lib/data/di/**, the sanctioned
//    composition seam (usecase providers; domain must stay pure Dart so the
//    concrete providers that wire domain objects together live there).
//    The DI composition rule (abstract providers in domain, impls via
//    ProviderScope overrides in main.dart) makes this possible; this lint
//    makes it stick. core/network, core/config, core/logging, core/telemetry
//    are infrastructure and are intentionally exempt.
//  * domain_stays_pure — lib/domain/** may import only Dart core / intl and
//    sibling domain files. No flutter, no data, no features.
//  * no_json_casts — `as` casts are banned under lib/data/**. All network
//    data goes through the canonical asInt/asDouble/asCleanString helpers
//    (core/validation/validators.dart). DoD#2 / B-6.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

PluginBase createPlugin() => _LayerLintPlugin();

class _LayerLintPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => <LintRule>[
        _NoDataImportsInPresentation(),
        _DomainStaysPure(),
        _NoJsonCasts(),
      ];
}

/// Files that must not reach into the data layer or plugin SDKs.
bool _isPresentationFile(String path) {
  final String p = path.replaceAll(r'\', '/');
  if (p.contains('/lib/features/')) return true;
  return p.contains('/lib/core/units/') ||
      p.contains('/lib/core/error/') ||
      p.contains('/lib/core/validation/') ||
      p.contains('/lib/core/utils/');
}

class _NoDataImportsInPresentation extends DartLintRule {
  _NoDataImportsInPresentation()
      : super(
          code: const LintCode(
            'no_data_imports_in_presentation',
            'Presentation must not import the data layer or transport/storage '
            'plugins. Depend on domain interfaces instead; implementations are '
            'bound via ProviderScope overrides in main.dart (R-9).',
          ),
        );

  static const List<String> _deniedPackages = <String>[
    'package:dio',
    'package:hive_ce',
    'package:hive_ce_flutter',
    'package:geolocator',
    'package:geocoding',
    'package:connectivity_plus',
    'package:sentry_flutter',
    'package:shared_preferences',
    'package:path_provider',
  ];

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isPresentationFile(resolver.source.fullName)) return;
    context.registry.addImportDirective((ImportDirective node) {
      final String? uri = node.uri.stringValue;
      if (uri == null) return;
      final bool isDiSeam = uri.contains('/lib/data/di/') ||
          uri.startsWith('package:weather_app/data/di/');
      final bool denied = !isDiSeam &&
          (uri.contains('/lib/data/') ||
              uri.startsWith('package:weather_app/data/') ||
              _deniedPackages.any(
                  (String p) => uri == p || uri.startsWith('$p/')));
      if (denied) reporter.reportErrorForNode(code, node);
    });
  }
}

class _DomainStaysPure extends DartLintRule {
  _DomainStaysPure()
      : super(
          code: const LintCode(
            'domain_stays_pure',
            'Domain must stay pure Dart: no flutter, data, or feature imports. '
            'Domain owns entities, repository interfaces, usecases, failures, '
            'and value objects only (ADR-03).',
          ),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final String path = resolver.source.fullName.replaceAll(r'\', '/');
    if (!path.contains('/lib/domain/')) return;
    context.registry.addImportDirective((ImportDirective node) {
      final String? uri = node.uri.stringValue;
      if (uri == null) return;
      final bool denied = uri.startsWith('package:flutter/') ||
          uri == 'package:flutter' ||
          uri.startsWith('dart:ui') ||
          uri.contains('/lib/data/') ||
          uri.contains('/lib/features/') ||
          uri.startsWith('package:weather_app/data/') ||
          uri.startsWith('package:weather_app/features/');
      if (denied) reporter.reportErrorForNode(code, node);
    });
  }
}

class _NoJsonCasts extends DartLintRule {
  _NoJsonCasts()
      : super(
          code: const LintCode(
            'no_json_casts',
            'Do not use `as` casts in the data layer. Network data is '
            'untrusted: use asInt/asDouble/asCleanString from '
            'core/validation/validators.dart (DoD#2 / B-6).',
          ),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final String path = resolver.source.fullName.replaceAll(r'\', '/');
    if (!path.contains('/lib/data/')) return;
    context.registry.addAsExpression((AsExpression node) {
      reporter.reportErrorForNode(code, node);
    });
  }
}
