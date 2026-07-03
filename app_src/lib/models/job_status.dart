class JobStatus {
  JobStatus({
    required this.id,
    required this.status,
    required this.done,
    this.answer,
    this.error,
  });

  final String id;
  final String status;
  final bool done;
  final String? answer;
  final String? error;

  factory JobStatus.fromJson(Map<String, dynamic> json) {
    final job = (json['job'] as Map<String, dynamic>?) ?? json;
    return JobStatus(
      id: '${job['id'] ?? ''}',
      status: '${job['status'] ?? ''}',
      done: job['done'] == true || job['status'] == 'done' || job['status'] == 'failed',
      answer: job['answer']?.toString() ?? job['result_text']?.toString(),
      error: job['error']?.toString() ?? job['error_text']?.toString(),
    );
  }
}
