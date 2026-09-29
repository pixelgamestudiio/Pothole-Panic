/// Versioned, portable casual challenge. The checksum detects mistyped codes;
/// it is not a server signature or an anti-cheat mechanism.
class FriendChallenge {
  const FriendChallenge({required this.seed, required this.targetScore});
  final int seed, targetScore;
  static const version = 'PP2';
  static final _codePattern = RegExp(r'PP\d+-[A-Z0-9]+-[A-Z0-9]+-[A-Z0-9]+');
  static String _checksum(String body) {
    var value = 17;
    for (final unit in body.codeUnits) {
      value = (value * 31 + unit) % 65521;
    }
    return value.toRadixString(36).toUpperCase();
  }

  String get code {
    final body =
        '$version-${seed.toRadixString(36)}-${targetScore.toRadixString(36)}'
            .toUpperCase();
    return '$body-${_checksum(body)}';
  }

  static FriendChallenge parse(String input) {
    if (input.length > 4096) {
      throw const FormatException(
        'That invite is too long. Paste just the challenge code.',
      );
    }
    final match = _codePattern.firstMatch(input.trim().toUpperCase());
    if (match == null) {
      throw const FormatException(
        'Enter a Pothole Panic challenge code or invite.',
      );
    }
    final parts = match.group(0)!.split('-');
    if (parts[0] != version) {
      throw const FormatException(
        'This invite uses a different game version. Both players need the same update.',
      );
    }
    if (parts.any((p) => p.length > 8) ||
        parts[3] != _checksum(parts.take(3).join('-'))) {
      throw const FormatException(
        'This code looks mistyped. Copy the complete invite and try again.',
      );
    }
    final seed = int.tryParse(parts[1], radix: 36);
    final score = int.tryParse(parts[2], radix: 36);
    if (seed == null ||
        seed < 0 ||
        seed >= 2147483646 ||
        score == null ||
        score < 0 ||
        score > 1000000000) {
      throw const FormatException(
        'That challenge contains invalid run details.',
      );
    }
    return FriendChallenge(seed: seed, targetScore: score);
  }

  String invite({Uri? publicBase}) {
    final link = publicBase == null
        ? ''
        : '\n${publicBase.replace(queryParameters: {'challenge': code}, fragment: '')}';
    return 'Pothole Panic: can you beat my $targetScore points?\n'
        'Same road, same auto, no rescues.\n$code$link\n'
        'Open Friend Challenge and paste this invite. Send your score back!';
  }

  static Uri? publicBase(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.host == 'localhost' ||
        uri.host == '127.0.0.1' ||
        uri.host == '::1' ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    return uri;
  }
}
