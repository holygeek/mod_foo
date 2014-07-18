export PATH := $(CURDIR)/httpd/bin:$(PATH)

test: httpd/modules/mod_foo.so curl

httpd/modules/mod_foo.so: httpd httpd/conf/mod_foo.conf mod_foo.c
	apxs -i -a -c mod_foo.c
	$(MAKE) restart

restart:
	apachectl restart
stop:
	apachectl stop

curl:
	curl -s localhost:8099/foo|grep --color=always nrequest

curls:
	for i in `seq 1 50`; do curl -s localhost:8099/foo & done|grep Ohai

watch:
	fswatch -0 `pwd`/mod_foo.c | while read -d "" event; do make; done

apache-mirror = http://mirrors.ibiblio.org/apache
apr-version = 1.5.1
apr-util-version = 1.5.3
httpd-version = 2.4.10
apr-tarball = apr-$(apr-version).tar.gz
apr-util-tarball = apr-util-$(apr-util-version).tar.gz
httpd-src-dir = httpd-$(httpd-version)
httpd-srclib-dir = $(httpd-src-dir)/srclib
httpd-tarball = $(httpd-src-dir).tar.gz
httpd-url = $(apache-mirror)/httpd/$(httpd-tarball)
apr-tarball-url = $(apache-mirror)/apr/$(apr-tarball)
apr-util-tarball-url = $(apache-mirror)/apr/$(apr-util-tarball)
httpd:
	if [ ! -f $(httpd-tarball) ]; then wget $(httpd-url); fi
	if [ ! -d $(httpd-src-dir) ]; then tar xf $(httpd-tarball); fi
	if [ ! -f $(apr-tarball) ]; then wget $(apr-tarball-url); fi
	if [ ! -d $(httpd-srclib-dir)/apr-$(apr-version) ]; then \
		tar Cxf $(httpd-srclib-dir) $(apr-tarball) && \
		ln -s apr-$(apr-version) $(httpd-srclib-dir)/apr; \
	fi
	if [ ! -f $(apr-util-tarball) ]; then wget $(apr-util-tarball-url); fi
	if [ ! -d $(httpd-srclib-dir)/apr-util-$(apr-util-version) ]; then \
		tar Cxf $(httpd-srclib-dir) $(apr-util-tarball) && \
		ln -s apr-util-$(apr-util-version) $(httpd-srclib-dir)/apr-util; \
	fi
	cd $(httpd-src-dir) && ./configure \
		--with-included-apr \
		--prefix=$(CURDIR)/httpd
	make -C $(httpd-src-dir) install

httpd/conf/mod_foo.conf:
	if ! grep -q 'Listen\s\s*8000$$' httpd/conf/httpd.conf; then \
		perl -p -i \
			-e 's/Listen 80$$/Listen 8000/' httpd/conf/httpd.conf; \
	fi
	if ! grep -q 'Include conf/mod_foo\.conf' httpd/conf/httpd.conf; then \
		echo 'Include conf/mod_foo.conf' >> httpd/conf/httpd.conf; \
	fi
	if [ ! -f httpd/conf/mod_foo.conf ]; then \
		ln mod_foo.conf httpd/conf/mod_foo.conf; \
	fi
