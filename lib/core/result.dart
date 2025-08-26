// 가벼운 Result 타입 (성공/실패 래핑)
sealed class Result<T> {
  const Result();
  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;
  T get value => (this as Ok<T>).value;
  Object get error => (this as Err<T>).error;
}

class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

class Err<T> extends Result<T> {
  final Object error;
  const Err(this.error);
}
