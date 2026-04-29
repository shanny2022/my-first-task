Root cause:
`AliasPath.search_dict_for_path` contains a guard that prevents indexing into `str`, but it does not treat `bytes` or `bytearray` as scalar values. Python allows integer indexing on bytes-like values, so alias-path traversal can incorrectly return an integer byte instead of treating the path as not found.

Intended fix:
Update the scalar-sequence guard in `pydantic/aliases.py` so it also returns `PydanticUndefined` for `bytes` and `bytearray`, while leaving normal container traversal unchanged.

Test plan:
Add focused tests for direct `AliasPath.search_dict_for_path` behavior with `bytes` and `bytearray`, integration behavior through `BaseModel` validation with `Field(validation_alias=AliasPath(...))`, and a regression check that list traversal still works.
