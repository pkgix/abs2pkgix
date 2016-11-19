export CPPFLAGS="-D_FORTIFY_SOURCE=2"
export CFLAGS="-O2 -pipe"
export CXXFLAGS="-O2 -pipe"

LDFLAGS="-Wl,-rpath=${LD_RUN_PATH}"
extend_LDFLAGS() {
	local library_path
	local path

	IFS=: read -ra library_path <<< "$LIBRARY_PATH"
	for path in "${library_path[@]}"; do
		LDFLAGS+=" -L${path}"
	done
}
extend_LDFLAGS
export LDFLAGS

if (( ${PKGIX_PARALLEL_BUILD:-0} )); then
	MAKEFLAGS="-j${PKGIX_PARALLEL_BUILD}"
	_make="$(which make)"
	make() {
		$_make $MAKEFLAGS "$@"
	}
fi
