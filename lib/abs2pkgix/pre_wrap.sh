
unset pkgname pkgver pkgrel url pkgdesc makedepends optdepends checkdepends
unset _checksums _checksums_digest _isinstalled_list

unset -f _prepare _build _check package
while read line; do
	read -ra split_line <<< "$line"
	if [[ "${split_line[2]}" =~ ^package_ ]]; then
		package_func="${split_line[2]}"
		unset -f "$package_func" || { $package_func; exit 1; }
	fi
done < <(declare -F)

# Force off nounset, as some PKGBUILDs use undeclared variables.
set +o nounset

