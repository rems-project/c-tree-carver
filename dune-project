(lang dune 3.7)

(name c-tree-carver)

(generate_opam_files true)

(source
 (github rems-project/c-tree-carver))

(authors "Dhruv Makwana <dhruv.makwana@cl.cam.ac.uk")

(maintainers "Dhruv Makwana <dhruv.makwana@cl.cam.ac.uk")

(license MIT BSD-2-Clause)

; (documentation https://url/to/documentation)

(package
 (name c-tree-carver)
 (synopsis "Clang-based tool for tree-carving C source trees")
 (description "")
 (depends
     (ocaml (>= 4.14.1))
     conf-c++
     (conf-cmake :dev)
     (conf-llvm (= 15))
     (conf-python-3 :with-test)
     (fileutils (>= 0.6.4))
     (shexp (>= v0.15.0))
     (ocamlformat (and (>= 0.25.1) :dev))
     (ppx_deriving (and (>= 5.2.1)))
     (ppx_expect (and (>= v0.15.1) :with-test)))

 (tags
  (topics c clang tool tree-carving)))

(package
 (name conf-libclang-15-dev)
 (allow_empty))


(formatting)

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
