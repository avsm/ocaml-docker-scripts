.PHONY: depend

# Build local containers
depend:
	for c in $(shell ls -1 containers/); do \
	  sudo docker build --rm=true -t local-$$c; done
