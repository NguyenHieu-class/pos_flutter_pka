sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  R when<R>({
    required R Function(Success<T> success) success,
    required R Function(Failure<T> failure) failure,
  }) {
    final self = this;
    if (self is Success<T>) {
      return success(self);
    }
    return failure(self as Failure<T>);
  }
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);
  final Object error;
}
