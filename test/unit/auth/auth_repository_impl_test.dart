import 'package:fieldops/core/auth/data/auth_local_datasource.dart';
import 'package:fieldops/core/auth/data/auth_repository_impl.dart';
import 'package:fieldops/core/auth/domain/entities/user.dart';
import 'package:fieldops/core/permissions/role.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthLocalDatasource extends Mock implements AuthLocalDatasource {}

void main() {
  late MockAuthLocalDatasource ds;
  late AuthRepositoryImpl repo;

  setUp(() {
    ds = MockAuthLocalDatasource();
    repo = AuthRepositoryImpl(ds);
    when(() => ds.saveUser(any())).thenAnswer((_) async {});
    when(() => ds.clearUser()).thenAnswer((_) async {});
    when(() => ds.getUser()).thenAnswer((_) async => null);
  });

  setUpAll(() {
    registerFallbackValue(AppUser.mock(Role.viewer));
  });

  group('signIn — role derivation from email', () {
    Future<Role> roleFor(String email) async {
      final user = await repo.signIn(email: email, password: 'pw');
      return user.role;
    }

    test('email containing "admin" → Role.admin', () async {
      expect(await roleFor('admin@example.com'), Role.admin);
    });

    test('email containing "supervisor" → Role.supervisor', () async {
      expect(await roleFor('supervisor@example.com'), Role.supervisor);
    });

    test('email containing "worker" → Role.worker', () async {
      expect(await roleFor('worker@example.com'), Role.worker);
    });

    test('any other email → Role.viewer', () async {
      expect(await roleFor('jane@example.com'), Role.viewer);
    });

    test('case-insensitive matching (ADMIN)', () async {
      expect(await roleFor('ADMIN@example.com'), Role.admin);
    });

    test('saves user to local datasource on sign-in', () async {
      await repo.signIn(email: 'worker@example.com', password: 'pw');
      verify(() => ds.saveUser(any())).called(1);
    });
  });

  group('signOut', () {
    test('clears local datasource', () async {
      await repo.signOut();
      verify(() => ds.clearUser()).called(1);
    });
  });

  group('currentUser', () {
    test('returns null when no persisted user', () async {
      when(() => ds.getUser()).thenAnswer((_) async => null);
      expect(await repo.currentUser(), isNull);
    });

    test('returns persisted user', () async {
      final user = AppUser.mock(Role.supervisor);
      when(() => ds.getUser()).thenAnswer((_) async => user);
      expect(await repo.currentUser(), equals(user));
    });
  });

  group('watchCurrentUser', () {
    test('emits the current persisted user first', () async {
      final user = AppUser.mock(Role.admin);
      when(() => ds.getUser()).thenAnswer((_) async => user);
      final first = await repo.watchCurrentUser().first;
      expect(first, equals(user));
    });

    test('emits updated user after sign-in', () async {
      when(() => ds.getUser()).thenAnswer((_) async => null);

      final emissions = <AppUser?>[];
      final sub = repo.watchCurrentUser().listen(emissions.add);

      await Future<void>.delayed(Duration.zero);
      expect(emissions, [null]);

      await repo.signIn(email: 'admin@test.com', password: 'pw');
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      expect(emissions.last?.role, Role.admin);
    });

    test('emits null after sign-out', () async {
      final user = AppUser.mock(Role.worker);
      when(() => ds.getUser()).thenAnswer((_) async => user);

      final emissions = <AppUser?>[];
      final sub = repo.watchCurrentUser().listen(emissions.add);

      await Future<void>.delayed(Duration.zero);
      expect(emissions, [user]);

      await repo.signOut();
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      expect(emissions.last, isNull);
    });
  });
}
