import 'tables/tx_catalog.dart';
import 'tables/tx_content.dart';
import 'tables/tx_ui.dart';

/// Türkçe metin → [en, es, zh, hi]. Parçalar ayrı dosyalarda tutulur.
final Map<String, List<String>> kTx = {...kTxCatalog, ...kTxContent, ...kTxUi};
