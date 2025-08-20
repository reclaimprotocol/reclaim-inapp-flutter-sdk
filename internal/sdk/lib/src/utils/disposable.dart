/// Interface for objects that require resource cleanup.
///
/// Implementers must release all resources (streams, controllers, subscriptions,
/// native resources, etc.) when [dispose] is called to prevent memory leaks.
abstract class Disposable {
  /// Releases all resources held by this object.
  ///
  /// Must be called when the object is no longer needed to prevent memory leaks.
  /// After disposal, the object enters an invalid state and any further method
  /// calls may throw exceptions or produce undefined behavior.
  void dispose();
}
