FROM us-docker.pkg.dev/afterqueryai/silver-repo-images/pydantic-assessment-tokwn@sha256:69afc7d61716218b4843148af521659861cdf0fef386fc5592daee2bb6c514f2

ENTRYPOINT []

WORKDIR /app/pydantic-assessment

RUN set -e \
 && git reset --hard 9e9a11132c980c4ec84ff6d2df06d4c1a55ca8f3 \
 && git clean -fd

# Install the repo + test dependencies required by the repo's test suite at this commit.
RUN pip install --no-cache-dir -e . pytest==8.3.5 jsonschema==4.23.0

RUN mkdir -p /logs/verifier
