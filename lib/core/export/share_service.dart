import 'package:share_plus/share_plus.dart';

class ShareService {
  Future<void> shareFile(String path, {String? subject}) =>
      Share.shareXFiles([XFile(path)], subject: subject);
}
