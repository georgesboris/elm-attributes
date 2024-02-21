# elm-attributes

Create and use opaque attribute APIs without the usual boilerplate.

The opaque attribute pattern is useful for creating highly backwards compatible APIs without locking the author of the module/library into an internal implementation.

However, implementing it can be boilerplate-heavy and you miss the opportunity of reusing generic abstractions across modules that follow the same pattern.

This library helps with that by giving you a set of tools to both create modules following this pattern and use them with access to common utility functions.
