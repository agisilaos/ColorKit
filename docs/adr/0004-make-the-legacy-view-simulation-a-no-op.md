# Make the legacy view simulation a no-op

The deprecated arbitrary-view color-blindness modifier will return its content unchanged while preserving its public symbols for source compatibility. Its overlay implementation does not transform rendered pixels and therefore produces misleading output; retaining that behavior would be less safe than visibly withdrawing it and directing callers to `Color.simulated(for:)` for fixed colors.
