#!/bin/sh

set -e

BELENIOS_SRC="${BELENIOS_SRC:-$PWD}"

# Check that Dune is not installed
# cf. https://github.com/ocaml/opam/issues/3987
if command -v dune >/dev/null; then
    echo "Please uninstall Dune first, or remove it from your PATH."
    exit 1
fi

echo
echo "=-=-= Download and check tarballs =-=-="
echo

# Look for wget or curl
if which wget >/dev/null; then
    echo "wget was found and will be used"
elif which curl >/dev/null; then
    wget () { curl "$1" > "${1##*/}"; }
    echo "curl was found and will be used"
fi

export BELENIOS_SYSROOT="${BELENIOS_SYSROOT:-$HOME/.belenios}"
export OPAMROOT="$BELENIOS_SYSROOT/opam"

if [ -e "$BELENIOS_SYSROOT" ]; then
    echo "$BELENIOS_SYSROOT already exists."
    echo "Please remove it or set BELENIOS_SYSROOT to a non-existent directory first."
    exit 1
fi

mkdir -p "$BELENIOS_SYSROOT/bootstrap/src"

cd "$BELENIOS_SYSROOT/bootstrap/src"
wget https://github.com/ocaml/opam/releases/download/2.0.5/opam-full-2.0.5.tar.gz

if which sha256sum >/dev/null; then
sha256sum --check <<EOF
776c7e64d6e24c2ef1efd1e6a71d36e007645efae94eaf860c05c1929effc76f  opam-full-2.0.5.tar.gz
EOF
else
    echo "WARNING: sha256sum was not found, checking tarballs is impossible!"
fi

export PATH="$BELENIOS_SYSROOT/bootstrap/bin:$PATH"

echo
echo "=-=-= Compilation and installation of OPAM =-=-="
echo
cd "$BELENIOS_SYSROOT/bootstrap/src"
tar -xzf opam-full-2.0.5.tar.gz
cd opam-full-2.0.5
make cold CONFIGURE_ARGS="--prefix $BELENIOS_SYSROOT/bootstrap"
make cold-install LIBINSTALL_DIR="$BELENIOS_SYSROOT/bootstrap/lib/ocaml"

echo
echo "=-=-= Generation of env.sh =-=-="
echo
cat > $BELENIOS_SRC/env.sh <<EOF
PATH="$BELENIOS_SYSROOT/bootstrap/bin:\$PATH"; export PATH;
OPAMROOT=$OPAMROOT; export OPAMROOT;
eval \$(opam env)
EOF

echo
echo "=-=-= Initialization of OPAM root =-=-="
echo
cd "$BELENIOS_SYSROOT"
git clone https://github.com/ocaml/opam-repository.git
cd opam-repository
git reset --hard 0200b396894c6cfae40d7175530747bda96e3195

# ---
# JBL CHIRURGIE 
# ---
# opam init --disable-sandboxing
# opam init --bare --no-setup -k git "$BELENIOS_SYSROOT/opam-repository"
opam init --disable-sandboxing --bare --no-setup -k git "$BELENIOS_SYSROOT/opam-repository"
opam switch create 4.08.1 ocaml-base-compiler.4.08.1
eval $(opam env)

echo
echo "=-=-= Installation of Belenios build-dependencies =-=-="
echo
opam install --yes atdgen zarith cryptokit uuidm calendar cmdliner sqlite3 csv eliom


# ---
# ---



echo
echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
echo
echo "Belenios build-dependencies have been successfully compiled and installed"
echo "to $BELENIOS_SYSROOT. The directory"
echo "  $BELENIOS_SYSROOT/bootstrap/src"
echo "can be safely removed now."
echo
echo "Next, you need to run the following commands or add them to your ~/.bashrc"
echo "or equivalent:"
echo "  source $BELENIOS_SRC/env.sh"
echo "Note that if you use a Bourne-incompatible shell (e.g. tcsh), you'll have"
echo "to adapt env.sh to your shell."
echo
echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
echo