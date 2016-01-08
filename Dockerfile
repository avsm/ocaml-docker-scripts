FROM ocaml/opam:centos-6_ocaml-4.03.0_trunk
RUN sudo -u opam sh -c "opam depext async_ssl jenga cohttp cryptokit menhir core_bench yojson core_extended" && \
  sudo -u opam sh -c "opam install -j 2 -y -v async_ssl jenga cohttp cryptokit menhir core_bench yojson core_extended"