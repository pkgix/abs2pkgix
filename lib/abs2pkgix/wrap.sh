version="${pkgver}-${pkgrel}"
website="${url}"
description="${pkgdesc}"

builddepends=("${makedepends[@]:+${makedepends[@]}}")
for optdepend in "${optdepends[@]:+${optdepends[@]}}"; do
	optdepend="${optdepend%%:*}"
	builddepends+=("$optdepend")
done

_set_vars() {
	srcdir="$(pwd)"
	pkgdir="${destdir}"
}

isinstalled() {
	local headerpath
	local old_IFS

	for filepath in "${_isinstalled_list[@]:+${_isinstalled_list[@]}}"; do
		old_IFS="$IFS"
		IFS=":"
		for path in "" "${CPATH[@]}"; do
			# Get prefix (PKGIX_PREFIX may be unset)
			path="${path%/include}"
			path="${path%/usr}"

			if [[ -f "${path}${filepath}" ]]; then
				return 0
			fi
		done
		IFS="$old_IFS"
	done

	return 1
}

iscompat() {
	[[ "$ostype" == "linux" ]] || return 1
	in_list "any" "${arch[@]}" \
		|| in_list "$architecture" "${arch[@]}"
}

_fetch_sources() {
	local i
	local url
	local checksum
	local file_name
	for (( i=0 ; i < ${#source[@]}; ++i )); do
		url="${source[i]}"
		checksum="${_checksums[i]}"
		file_name="${url##*/}"

		if [[ "$file_name" == "$url" ]]; then
			url="${repo}/../support/${pkgname}/${url}"
		fi

		if [[ "$checksum" == "SKIP" ]]; then
			arg_ignore_checksums=1 fetch "$url" "$checksum" "$file_name"
		else
			fetch "$url" "${_checksums_digest}=$checksum" "$file_name"
		fi

		( extract_archive "$file_name" &>/dev/null ) || :
	done
}

prepare() {
	_fetch_sources

	type -p _prepare &>/dev/null || return 0
	_set_vars
	_prepare
}

build() {
	type -p _build &>/dev/null || return 0
	_set_vars
	_build
}

check() {
	type -p _check &>/dev/null || return 0
	_set_vars
	_check || warning_printf "Check failed!\n"
}

installenv() {
	_set_vars
	package
}

#checkdepends
#provides
#forceinstall
#postinstall
#preremove
#postremove
