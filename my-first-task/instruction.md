<uploaded_files>
/app/pydantic-assessment
</uploaded_files>

I've uploaded a code repository in the directory `/app/pydantic-assessment`. Consider the following task:

## Bug

`AliasPath` currently avoids indexing into strings when a validation alias path contains an integer segment, but it still indexes into `bytes` and `bytearray` values.

This can cause model validation to accidentally treat a scalar bytes value as an indexable container. For example, a model using `Field(validation_alias=AliasPath("payload", 0))` may read the first byte of `b"abc"` (97) as the field input.

## Expected behavior

When an `AliasPath` step would index into a `str`, `bytes`, or `bytearray` value, the path search must stop and return `PydanticUndefined`.

As a result, `BaseModel` validation should treat the field as missing:
- If the field is required, validation should raise a `ValidationError` for a missing field (instead of producing a value like `97`).
- Normal list/tuple traversal must still work, e.g. `AliasPath("payload", 1)` should still resolve the second item for `{"payload": ["zero", "one"]}`.
