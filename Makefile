.PHONY: all
all: package_file_list.gz

package_file_list.gz: /var/log/pacman.log
	pacman -Ql | gzip > $@

.PHONY: lint
lint:
	export PYTHONPATH=$(PWD)/lib/python:$${PYTHONPATH}; \
	pylint abs2pkgix

.PHONY: clean
clean:
	$(RM) package_file_list.gz
