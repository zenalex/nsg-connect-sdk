/// Режим работы SDK (см. ТЗ §5).
///
/// Влияет на:
///   * фильтрацию списка комнат (embeddedProduct → только текущий
///     product; standalone → все продукты);
///   * наличие product-selector-а в AppBar (только standalone);
///   * AppBar-рендер (compactWidget — без AppBar, отдельный chrome).
///
/// На TASK11 hooks заложены, но реальная фильтрация — TASK14 / TASK22.
enum MessengerMode {
  embeddedProduct,
  standalone,
  customerEmbedded,
  supportChat,
  compactWidget,
  internalTeam,
}
