import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:equatable/equatable.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/digests/keccak.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/ecc/api.dart' show ECCurve, ECDomainParameters, ECPoint, ECPrivateKey, ECSignature;
import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/signers/ecdsa_signer.dart';

class CryptoEthers {
  static String signPersonalMessage({required Uint8List message, String? privateKey, Uint8List? privateKeyInBytes}) {
    final personalMessage = _getPersonalMessage(message);
    return sign(message: personalMessage, privateKey: privateKey, privateKeyInBytes: privateKeyInBytes);
  }

  static // Converts the [bytes] given as a list of integers into a hexadecimal
  /// representation.
  ///
  /// If any of the bytes is outside of the range [0, 256], the method will throw.
  /// The outcome of this function will prefix a 0 if it would otherwise not be
  /// of even length. If [include0x] is set, it will prefix "0x" to the hexadecimal
  /// representation. If [forcePadLength] is set, the hexadecimal representation
  /// will be expanded with zeroes until the desired length is reached. The "0x"
  /// prefix does not count for the length.
  String
  bytesToHex(List<int> bytes, {bool include0x = false, int? forcePadLength, bool padToEvenLength = false}) {
    var encoded = hex.encode(bytes);

    if (forcePadLength != null) {
      assert(forcePadLength >= encoded.length);

      final padding = forcePadLength - encoded.length;
      encoded = ('0' * padding) + encoded;
    }

    if (padToEvenLength && encoded.length % 2 != 0) {
      encoded = '0$encoded';
    }

    return (include0x ? '0x' : '') + encoded;
  }

  static Uint8List hexToBytes(String hexStr) {
    final bytes = hex.decode(stripHexPrefix(hexStr));
    if (bytes is Uint8List) return bytes;
    return Uint8List.fromList(bytes);
  }

  static String sign({required Uint8List message, String? privateKey, Uint8List? privateKeyInBytes}) {
    if (privateKey == null && privateKeyInBytes == null) {
      throw ArgumentError('Missing private key to sign');
    }
    final sig = signToSignature(message, privateKeyInBytes ?? hexToBytes(privateKey!));
    return concatSig(toBuffer(sig.r), toBuffer(sig.s), toBuffer(sig.v));
  }

  static final ECDomainParameters _params = ECCurve_secp256k1();

  static BigInt decodeBigInt(List<int> bytes) {
    BigInt result = BigInt.from(0);
    for (int i = 0; i < bytes.length; i++) {
      result += BigInt.from(bytes[bytes.length - i - 1]) << (8 * i);
    }
    return result;
  }

  static final BigInt _halfCurveOrder = _params.n ~/ BigInt.two;

  /// Generates a public key for the given private key using the ecdsa curve which
  /// Ethereum uses.
  static Uint8List privateKeyToPublicKey(Uint8List privateKey) {
    final privateKeyNum = decodeBigInt(privateKey);
    final p = _params.G * privateKeyNum;

    //skip the type flag, https://github.com/ethereumjs/ethereumjs-util/blob/master/index.js#L319
    return Uint8List.view(p!.getEncoded(false).buffer, 1);
  }

  static ECDSASignature signToSignature(Uint8List message, Uint8List privateKey) {
    final digest = SHA256Digest();
    final signer = ECDSASigner(null, HMac(digest, 64));
    final key = ECPrivateKey(decodeBigInt(privateKey), _params);

    signer.init(true, PrivateKeyParameter(key));
    var sig = signer.generateSignature(message) as ECSignature;

    /*
	This is necessary because if a message can be signed by (r, s), it can also
	be signed by (r, -s (mod N)) which N being the order of the elliptic function
	used. In order to ensure transactions can't be tampered with (even though it
	would be harmless), Ethereum only accepts the signature with the lower value
	of s to make the signature for the message unique.
	More details at
	https://github.com/web3j/web3j/blob/master/crypto/src/main/java/org/web3j/crypto/ECDSASignature.java#L27
	 */
    if (sig.s.compareTo(_halfCurveOrder) > 0) {
      final canonicalisedS = _params.n - sig.s;
      sig = ECSignature(sig.r, canonicalisedS);
    }

    // Now we have to work backwards to figure out the recId needed to recover the signature.
    //https://github.com/web3j/web3j/blob/master/crypto/src/main/java/org/web3j/crypto/Sign.java
    final publicKey = privateKeyToPublicKey(privateKey);
    int recoveryId = -1;
    for (var i = 0; i < 2; i++) {
      final k = _recoverPublicKeyFromSignature(i, sig.r, sig.s, message);
      if (ListEquality().equals(k, publicKey)) {
        recoveryId = i;
        break;
      }
    }

    if (recoveryId == -1) {
      throw Exception('Could not construct a recoverable key. This should never happen');
    }

    return ECDSASignature(sig.r, sig.s, recoveryId + 27);
  }

  static const _messagePrefix = '\u0019Ethereum Signed Message:\n';

  static Uint8List _getPersonalMessage(Uint8List message) {
    final prefix = _messagePrefix + message.length.toString();
    final prefixBytes = ascii.encode(prefix);
    return keccak256(Uint8List.fromList(prefixBytes + message));
  }

  static Uint8List? _recoverPublicKeyFromSignature(int recId, BigInt r, BigInt s, Uint8List message) {
    final n = _params.n;
    final i = BigInt.from(recId ~/ 2);
    final x = r + (i * n);

    //Parameter q of curve
    final prime = BigInt.parse('fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f', radix: 16);
    if (x.compareTo(prime) >= 0) return null;

    final R = _decompressKey(x, (recId & 1) == 1, _params.curve);
    final ECPoint? ecPoint = R * n;
    if (ecPoint == null || !ecPoint.isInfinity) return null;

    final e = decodeBigInt(message);

    final eInv = (BigInt.zero - e) % n;
    final rInv = r.modInverse(n);
    final srInv = (rInv * s) % n;
    final eInvrInv = (rInv * eInv) % n;

    final preQ = (_params.G * eInvrInv);
    if (preQ == null) return null;
    final q = preQ + (R * srInv);

    final bytes = q?.getEncoded(false);
    return bytes?.sublist(1);
  }

  static ECPoint _decompressKey(BigInt xBN, bool yBit, ECCurve c) {
    List<int> x9IntegerToBytes(BigInt s, int qLength) {
      //https://github.com/bcgit/bc-java/blob/master/core/src/main/java/org/bouncycastle/asn1/x9/X9IntegerConverter.java#L45
      final bytes = encodeBigInt(s);

      if (qLength < bytes.length) {
        return bytes.sublist(0, bytes.length - qLength);
      } else if (qLength > bytes.length) {
        final tmp = List<int>.filled(qLength, 0);

        final offset = qLength - bytes.length;
        for (var i = 0; i < bytes.length; i++) {
          tmp[i + offset] = bytes[i];
        }

        return tmp;
      }

      return bytes;
    }

    final compEnc = x9IntegerToBytes(xBN, 1 + ((c.fieldSize + 7) ~/ 8));
    compEnc[0] = yBit ? 0x03 : 0x02;
    return c.decodePoint(compEnc)!;
  }

  static final BigInt _byteMask = BigInt.from(0xff);

  static Uint8List encodeBigInt(BigInt input, {Endian endian = Endian.be, int length = 0}) {
    int byteLength = (input.bitLength + 7) >> 3;
    int reqLength = length > 0 ? length : math.max(1, byteLength);
    assert(byteLength <= reqLength, 'byte array longer than desired length');
    assert(reqLength > 0, 'Requested array length <= 0');

    var res = Uint8List(reqLength);
    res.fillRange(0, reqLength - byteLength, 0);

    var q = input;
    if (endian == Endian.be) {
      for (int i = 0; i < byteLength; i++) {
        res[reqLength - i - 1] = (q & _byteMask).toInt();
        q = q >> 8;
      }
      return res;
    } else {
      // FIXME: le
      throw UnimplementedError('little-endian is not supported');
    }
  }

  static String concatSig(Uint8List r, Uint8List s, Uint8List v) {
    var rSig = fromSigned(r);
    var sSig = fromSigned(s);
    var vSig = bufferToInt(v);
    var rStr = _padWithZeroes(hex.encode(toUnsigned(rSig)), 64);
    var sStr = _padWithZeroes(hex.encode(toUnsigned(sSig)), 64);
    var vStr = stripHexPrefix(intToHex(vSig));
    return addHexPrefix(rStr + sStr + vStr);
  }

  /// Adds "0x" to a given [String] if it does not already start with "0x".
  static String addHexPrefix(String str) {
    return isHexPrefixed(str) ? str : '0x$str';
  }

  /// Converts a [int] into a hex [String]
  static String intToHex(int i) {
    return "0x${i.toRadixString(16)}";
  }

  static bool isHexPrefixed(String str) {
    return str.startsWith('0x');
  }

  static String stripHexPrefix(String str) {
    return isHexPrefixed(str) ? str.substring(2) : str;
  }

  static String _padWithZeroes(String number, int length) {
    var myString = number;
    while (myString.length < length) {
      myString = '0$myString';
    }
    return myString;
  }

  /// Interprets a [Uint8List] as a signed integer and returns a [BigInt]. Assumes 256-bit numbers.
  static BigInt fromSigned(Uint8List signedInt) {
    return decodeBigInt(signedInt).toSigned(256);
  }

  static
  /// Converts a [BigInt] to an unsigned integer and returns it as a [Uint8List]. Assumes 256-bit numbers.
  Uint8List
  toUnsigned(BigInt unsignedInt) {
    return encodeBigInt(unsignedInt.toUnsigned(256));
  }

  /// Converts a [Uint8List] to a [int].
  static int bufferToInt(Uint8List buf) {
    return decodeBigInt(toBuffer(buf)).toInt();
  }

  /// Attempts to turn a value into a [Uint8List]. As input it supports [Uint8List], [String], [int], [null], [BigInt] method.
  static Uint8List toBuffer(Object? v) {
    if (v is! Uint8List) {
      if (v is List<int>) {
        v = Uint8List.fromList(v);
      } else if (v is String) {
        if (isHexString(v)) {
          v = Uint8List.fromList(hex.decode(padToEven(stripHexPrefix(v))));
        } else {
          v = Uint8List.fromList(utf8.encode(v));
        }
      } else if (v is int) {
        v = intToBuffer(v);
      } else if (v == null) {
        v = Uint8List(0);
      } else if (v is BigInt) {
        v = Uint8List.fromList(encodeBigInt(v));
      } else {
        throw ArgumentError.value(v, 'v', 'invalid type "${v.runtimeType}"');
      }
    }

    return v;
  }

  /// Converts an [int] to a [Uint8List]
  static Uint8List intToBuffer(int i) {
    return Uint8List.fromList(hex.decode(padToEven(intToHex(i).substring(2))));
  }

  /// Pads a [String] to have an even length
  static String padToEven(String value) {
    var a = value;

    if (a.length % 2 == 1) {
      a = "0$a";
    }

    return a;
  }

  /// Is the string a hex string.
  static bool isHexString(String value, {int length = 0}) {
    if (!RegExp('^0x[0-9A-Fa-f]*\$').hasMatch(value)) {
      return false;
    }

    if (length > 0 && value.length != 2 + 2 * length) {
      return false;
    }

    return true;
  }
}

enum Endian {
  be,
  // FIXME: le
}

class ECDSASignature extends Equatable {
  final BigInt r;
  final BigInt s;
  final int v;

  const ECDSASignature(this.r, this.s, this.v);

  @override
  List<Object?> get props => [r, s, v];
}

final KeccakDigest keccakDigest = KeccakDigest(256);

Uint8List keccak256(Uint8List input) {
  keccakDigest.reset();
  return keccakDigest.process(input);
}

Uint8List keccakUtf8(String input) {
  return keccak256(Uint8List.fromList(utf8.encode(input)));
}

Uint8List keccakAscii(String input) {
  return keccak256(ascii.encode(input));
}
