enum DomainStatus { unknown, testing, success, failure }

class DomainRow {
  static int _idCounter = 0;
  final String id;
  final String url;
  DomainStatus status = DomainStatus.unknown;
  int? latencyMs;

  DomainRow({required this.url}) : id = 'domain_${_idCounter++}';
}
