class ApiResponse<T> {
  final String code;
  final String message;
  final T? data;

  ApiResponse({required this.code, required this.message, this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) dataFromJson,
  ) {
    return ApiResponse(
      code: json['code'] as String? ?? 'OK',
      message: json['message'] as String? ?? '',
      data: json['data'] != null ? dataFromJson(json['data']) : null,
    );
  }
}
