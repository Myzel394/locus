import '../timers_service.dart';

class TaskExample {
  final String name;
  final List<TaskRuntimeTimer> timers;
  final bool realtime;

  const TaskExample({
    required this.name,
    required this.timers,
    this.realtime = false,
  });
}
