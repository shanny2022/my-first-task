#!/bin/bash
set -euo pipefail

cd "/app/pydantic-assessment"

cat > /tmp/solution.patch <<'__SOLUTION__'
diff --git a/pydantic/aliases.py b/pydantic/aliases.py
--- a/pydantic/aliases.py
+++ b/pydantic/aliases.py
@@ -44,9 +44,9 @@ class AliasPath:
         """
         v = d
         for k in self.path:
-            if isinstance(v, str):
-                # disallow indexing into a str, like for AliasPath('x', 0) and x='abc'
+            if isinstance(v, (str, bytes, bytearray)):
+                # disallow indexing into scalar sequence values, like for AliasPath('x', 0) and x='abc'
                 return PydanticUndefined
             try:
                 v = v[k]
             except (KeyError, IndexError, TypeError):
__SOLUTION__

git apply --verbose --whitespace=nowarn /tmp/solution.patch