import 'dart:collection';

enum JobStatus { unconsumed, consumed }

class JobStatusManager {
  static final JobStatusManager _instance = JobStatusManager._internal();
  factory JobStatusManager() => _instance;
  JobStatusManager._internal();

  final Map<int, JobStatus> _jobStatusMap = HashMap<int, JobStatus>();

  int generateJobId() {
    final random = DateTime.now().microsecond * DateTime.now().second;
    final jobId = (random % 1000000);
    _jobStatusMap[jobId] = JobStatus.unconsumed;
    return jobId;
  }

  void markJobAsConsumed(int jobId) {
    _jobStatusMap[jobId] = JobStatus.consumed;
  }

  bool isJobConsumed(int jobId) {
    return _jobStatusMap[jobId] == JobStatus.consumed;
  }

  bool isJobUnconsumed(int jobId) {
    return _jobStatusMap[jobId] == JobStatus.unconsumed;
  }

  void clear() {
    _jobStatusMap.clear();
  }
}
