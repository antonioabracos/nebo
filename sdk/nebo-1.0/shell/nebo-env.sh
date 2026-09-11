# opt-in: source this file explicitly
: "${NEBO_SDK_ROOT:?set NEBO_SDK_ROOT first}"
export NEBO_SDK_ROOT
case ":${PATH-}:" in
  *":${NEBO_SDK_ROOT}/bin:"*) ;;
  *) export PATH="${NEBO_SDK_ROOT}/bin:${PATH-}" ;;
esac
export NEBO_PACKAGE_STORE="${NEBO_PACKAGE_STORE:-${NEBO_SDK_ROOT}/var/packages}"
