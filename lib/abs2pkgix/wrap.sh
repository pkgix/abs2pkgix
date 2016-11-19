version="${pkgver}-${pkgrel}"
website="${url:-}"
description="${pkgdesc:-}"
provides+=("${pkgname[@]}")

builddepends=("${makedepends[@]:+${makedepends[@]}}")

_set_vars() {
	srcdir="$(pwd)"
	pkgdir="${destdir}"

	# Individual steps in PKGBUILDs can export variables that survive across
	# steps. Store all exports and reload them in the next step.
	local exports_file="${srcdir}/.${pkgname}-${version}.abs2pkgix.vars"
	[[ -f "${exports_file}" ]] && eval "$(< "${exports_file}")" || :
}

_store_exports() {
	local exports_file="${srcdir}/.${pkgname}-${version}.abs2pkgix.vars"
	# Need to rewrite 'declare -x' to 'export' (or declare -gx), as otherwise
	# the eval above will only be in scope for _set_vars.
	: > "${exports_file}"
	declare -x | while read line; do
		echo "export ${line#declare -x}" >> "${exports_file}"
	done
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
	local to_from
	for (( i=0 ; i < ${#source[@]}; ++i )); do
		# deal with "<target>::<source-url>" format here
		url="${source[i]}"
		file_name="$(get_fetch_target "${url%%::*}")"
		url="${url##*::}"
		checksum="${_checksums[i]}"

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
	_prepare && _store_exports
}

build() {
	type -p _build &>/dev/null || return 0
	_set_vars
	_build && _store_exports
}

check() {
	type -p _check &>/dev/null || return 0
	_set_vars
	_check || warning_printf "Check failed!\n"
}

installenv() {
	_set_vars

	type -p package &>/dev/null && package || :

	declare -F | while read line; do
		read -ra split_line <<< "$line"
		if [[ "${split_line[2]}" =~ ^package_ ]]; then
			package_func="${split_line[2]}"
			_p="${package_func#package_}"
			msg_printf "installing split %s ...\n" "$_p"
			$package_func
		fi
	done
}

#forceinstall
#postinstall
#preremove
#postremove
