import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haven/data/services/auth_service.dart';
import 'package:haven/providers.dart';

/// Telefonda görülen hata: çıkıştan sonra Firebase'de oturum kapalı, ama
/// Firebase'in oturum akışı bunu uygulamaya iletmedi; ekran ana sayfada kaldı.
/// syncAuthState iki tarafı karşılaştırıp akışı yeniden dinletir.
class _User implements User {
  _User(this.uid);
  @override
  final String uid;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Auth implements FirebaseAuth {
  User? user;
  @override
  User? get currentUser => user;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Auth firebase;
  late int listens;
  late ProviderContainer container;

  setUp(() {
    firebase = _Auth()..user = _User('u1');
    listens = 0;
    container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(AuthService(firebase)),
        // Firebase gibi: yeni dinleyici o anki oturumu hemen alır, sonra susar.
        authStateProvider.overrideWith((ref) {
          listens++;
          return Stream.value(firebase.user);
        }),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<String?> uid() async {
    final sub = container.listen(authStateProvider, (_, _) {});
    await container.read(authStateProvider.future);
    sub.close();
    return container.read(uidProvider);
  }

  test('akış çıkışı kaçırdıysa uygulamanın oturumu da kapanır', () async {
    expect(await uid(), 'u1');
    firebase.user = null; // Firebase'de çıkış yapıldı, akış olay göndermedi
    expect(await uid(), 'u1', reason: 'hata: uygulama hâlâ girişli sanıyor');
    syncAuthState(container);
    expect(await uid(), isNull);
  });

  test('iki taraf aynıysa akışa dokunulmaz', () async {
    expect(await uid(), 'u1');
    final before = listens;
    syncAuthState(container);
    expect(await uid(), 'u1');
    expect(listens, before);
  });
}
