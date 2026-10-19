import 'package:flutter_test/flutter_test.dart';

import 'package:mdk_tech_ai_automation/services/tor/tor_circuit_manager.dart';

void main() {
  test('each slot gets its own username under the same identity', () {
    final m = TorCircuitManager.instance;
    final a = m.credentialsFor('z-ai/glm-5:free');
    final b = m.credentialsFor('deepseek/deepseek-r1:free');
    expect(a.username, isNot(b.username));
    expect(a.password, b.password);
  });

  test('SOCKS username is limited to safe characters and length', () {
    final c = TorCircuitManager.instance.credentialsFor('a/b:c d' * 60);
    expect(RegExp(r'^[A-Za-z0-9-]+$').hasMatch(c.username), isTrue);
    expect(c.username.length, lessThanOrEqualTo(200));
    expect(c.username.isNotEmpty, isTrue);
  });

  test('newIdentity changes credentials and counts rotations', () {
    final m = TorCircuitManager.instance;
    final before = m.credentialsFor('x');
    final rotationsBefore = m.rotations;
    m.newIdentity();
    final after = m.credentialsFor('x');
    expect(after.password, isNot(before.password));
    expect(after.username, isNot(before.username));
    expect(m.rotations, rotationsBefore + 1);
  });
}
