##
# build_set_flags command args...
# Wraps command and sets LDFLAGS to reflect environment variables set by pkgix,
# as some linkers do not use LD_RUN_PATH nor LIBRARY_PATH, or they get reset
# somewhere along the way (makefiles, configure scripts, etc.).
#
build_wrap_ldflags() {
	local library_path
	local ldflags
	local path

	IFS=: read -ra library_path <<< "$LIBRARY_PATH"
	for path in "${library_path[@]}"; do
		ldflags+="-L${path} "
	done

	LDFLAGS="${ldflags}-Wl,-rpath=${LD_RUN_PATH} ${LDFLAGS:-}" "$@"
}


if (( ${PKGIX_PARALLEL_BUILD:-0} )); then
	_make="$(which make)"
	make() {
		$_make -j $(nproc) "$@"
	}
fi
