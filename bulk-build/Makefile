.PHONY: depend clean

include Makefile.config

# Build local containers
depend: 
	#sudo $(DOCKER) pull -a $(REPO)
	#sudo $(DOCKER) pull -a $(OPAM_REPO)
	$(MAKE) .list-all
	echo Now run this to perform the full bulk build
	echo "make -j <jobs> -f Makefile.bulk"

.list-all: $(IMAGES:%=.list-%)
	cat $^ > $@
	echo .stamp-pkg-all: $(IMAGES:%=.stamp-pkg-%) >> $@

.stamp-build-tmp-%:
	cd containers/local-$* && sudo $(DOCKER) build --no-cache=true -t tmp-$* . > ../../$@

.stamp-build-local-%: .stamp-run-opam-archive .stamp-build-tmp-%
	sudo $(DOCKER) rm -f local-archive-$* || true
	sudo $(DOCKER) run --link opam-archive:opam-archive --name local-archive-$* tmp-$* opam repository set-url default http://opam-archive:8080 2>&1 > $@ 
	sudo $(DOCKER) commit local-archive-$* local-$* >> $@

.stamp-build-opam-archive:
	cd containers/opam-archive && sudo $(DOCKER) build --no-cache=true -t opam-archive . > ../../$@

.stamp-run-opam-archive: .stamp-build-opam-archive
	sudo $(DOCKER) rm -f opam-archive || true
	sudo $(DOCKER) run -p 8080 -d --name opam-archive opam-archive opam config exec cohttp-server-lwt > $@

.list-%: .stamp-build-%
	@rm -f $@
	pkgs=`sudo $(DOCKER) run $* opam list -s -a`; \
	for i in $$pkgs; do \
	  plist="$$plist logs/$*/raw/$$i"; \
	  echo "logs/$*/raw/$$i : .stamp-log-$*" >> $@; \
	  echo "\t./scripts/build-opam-package logs/ $* $$i" >> $@; \
	done; \
	echo ".stamp-pkg-$*: $$plist" >> $@

.PRECIOUS: .stamp-* .list-*

clean:
	rm -f .stamp-* .list-*
