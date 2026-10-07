// Tiny Result type for usecase boundaries.

import 'package:weather_app/core/error/failures.dart';

sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(AppFailure failure) = FailureResult<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is FailureResult<T>;
}

final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

final class FailureResult<T> extends Result<T> {
  final AppFailure failure;
  const FailureResult(this.failure);
}
