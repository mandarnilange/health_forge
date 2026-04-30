// ProviderExtension is a type hierarchy base, not a single-use abstraction.
// ignore_for_file: one_member_abstracts

/// Base class for provider-specific extension data attached to
/// health records.
///
/// Subclasses carry metrics unique to a particular provider that
/// do not belong in the unified record model.
abstract class ProviderExtension {
  /// Serializes this extension to a JSON-compatible map.
  Map<String, dynamic> toJson();
}
