.PHONY: depend  clean
REPO=avsm/docker-opam-archive
IMAGES=$(shell find containers -maxdepth 1 -name local-* -type d| xargs -n1 basename) 

# Build local containers
depend: .list-all
	@ :

run-opam-archive: .stamp-run-opam-archive
	@ :

build-%: .stamp-build-%
	@ :

local-images: $(IMAGES:%=build-%)
	@ :

list-packages: .list-all
	@ :

.list-all: $(IMAGES:%=.list-%)
	cat $^ > $@

.stamp-logdir:
	#rm -rf logs
	mkdir -p logs
	touch $@

.stamp-log-%: .stamp-logdir
	#rm -rf logs/$*
	mkdir -p logs/$*/raw logs/$*/err logs/$*/ok
	touch $@
	
.stamp-build-%:
	cd containers/$* && sudo docker build --no-cache=true -t $* . > ../../$@

.stamp-run-opam-archive: .stamp-build-opam-archive
	sudo docker rm -f opam-archive || true
	sudo docker run -p 8080 -d --name opam-archive opam-archive opam config exec cohttp-server-lwt > $@

.list-%: .stamp-build-%
	rm -f $@
	for i in `sudo docker run $* opam list -s -a`; do \
	  echo "logs/$*/raw/$$i : .stamp-log-$* .stamp-build-$*" >> $@; \
	  echo "\t./scripts/build-opam-package logs/ $* $$i" >> $@; \
	done

.PRECIOUS: .stamp-* .list-* .log-*

clean:
	rm -f .stamp-* .list-* .log-*

ifneq ($(MAKECMDGOALS),clean)
-include .list-all
endif
