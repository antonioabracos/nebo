# opt-in: source this file explicitly
: "${NEBO_SDK_ROOT:?set NEBO_SDK_ROOT first}"
export PATH="${NEBO_SDK_ROOT}/bin:${PATH}"
export NEBO_PACKAGE_STORE="${NEBO_PACKAGE_STORE:-${NEBO_SDK_ROOT}/var/packages}"
