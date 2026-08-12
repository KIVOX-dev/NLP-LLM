import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// PBKDF2-HMAC-SHA256 password hashing (spec §31: "Password hashes must
/// never be stored as plaintext"). Uses only `package:crypto`, already a
/// dependency, rather than pulling in a native bcrypt binding — fine for a
/// server-side-only secret. Stored format: `pbkdf2$<iterations>$<saltB64>$<hashB64>`.
class PasswordHasher {
  const PasswordHasher({this.iterations = 120000, this.keyLength = 32});

  final int iterations;
  final int keyLength;

  String hash(String password) {
    final salt = _randomBytes(16);
    final derived = _pbkdf2(password, salt, iterations, keyLength);
    return 'pbkdf2\$$iterations\$${base64Url.encode(salt)}\$${base64Url.encode(derived)}';
  }

  bool verify(String password, String storedHash) {
    final parts = storedHash.split(r'$');
    if (parts.length != 4 || parts[0] != 'pbkdf2') return false;
    final iterationsUsed = int.tryParse(parts[1]);
    if (iterationsUsed == null) return false;
    final salt = base64Url.decode(parts[2]);
    final expected = base64Url.decode(parts[3]);
    final actual = _pbkdf2(password, salt, iterationsUsed, expected.length);
    return _constantTimeEquals(actual, expected);
  }

  Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
  }

  Uint8List _pbkdf2(String password, List<int> salt, int iterations, int keyLength) {
    final hmac = Hmac(sha256, utf8.encode(password));
    final blockCount = (keyLength / sha256.convert([]).bytes.length).ceil();
    final output = BytesBuilder();

    for (var blockIndex = 1; blockIndex <= blockCount; blockIndex++) {
      var u = hmac.convert([...salt, ...(_intToBytes(blockIndex))]).bytes;
      var block = Uint8List.fromList(u);
      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < block.length; j++) {
          block[j] ^= u[j];
        }
      }
      output.add(block);
    }

    return Uint8List.fromList(output.toBytes().sublist(0, keyLength));
  }

  List<int> _intToBytes(int value) => [
        (value >> 24) & 0xff,
        (value >> 16) & 0xff,
        (value >> 8) & 0xff,
        value & 0xff,
      ];

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
