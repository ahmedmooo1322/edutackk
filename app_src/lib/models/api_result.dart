class ApiResult<T> {
  const ApiResult.success(this.data)
      : error = null,
        ok = true;

  const ApiResult.failure(this.error)
      : data = null,
        ok = false;

  final bool ok;
  final T? data;
  final String? error;
}
