import 'package:uuid/uuid.dart';

const _uuid = Uuid();

abstract final class IdGenerator {
  static String newId() => _uuid.v4();
}
