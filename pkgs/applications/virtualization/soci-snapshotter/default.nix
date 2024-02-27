# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, buildGoModule, fetchFromGitHub, musl, flatbuffers, pkg-config, zlib }:

buildGoModule rec {
  # there is another package called soci - https://soci.sourceforge.net/
  # soci comprises of the soci image indexer plus the service for running
  # soci images in a lazy loading manner; here we don't bother building
  # the soci service as that should be installed separately as a service.

  # this package has a makefile but I found it difficult to use that here
  # so I'm using the more or less standard gomodules build approach - there
  # are a couple of issues:
  # - the go.mod file in the cmd dir imports the module using a relative path
  # - the instructions for cgo to import the zlib library are currently not compatible with pkg-config
  pname = "soci-snapshotter";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "awslabs";
    #owner = "seanrmurphy";
    repo = "soci-snapshotter";
    rev = "v${version}";
    #rev = "ca21d6b4f654de59fc758d3710a15025e8dd1a16";
    sha256 = "sha256-xcEAe0gzhuvquzqXwPl+ESh1qSP+vLraFV21bfHwDH0=";
  };

  # vendorSha256 = "sha256-TbrgKE7P3c0gkqJPDkbchWTPkOuTaTAWd8wDcpffcCc=";
  vendorHash = "sha256-wU3nCaQ1/ZrvJt3P9j2IeifD9WV+0YmHrYhwAnn/s0M=";

  # zlib is required for some compression stuff that is used within soci
  buildInputs = [zlib];

  # according to the documentation flatbuffers can be required in the build
  # but usually it is not
  nativeBuildInputs = [musl flatbuffers pkg-config];

  # zlib is a C dependency
  CGO_ENABLED = 1;

  ldflags = [
    "-linkmode external"
    "-extldflags '-static -L${musl}/lib'"
  ];

  modBuildPhase = ''
    runHook preBuild

    cd cmd
    sed -i 's/github.com\/awslabs\/soci-snapshotter v0.0.0 => ..\//github.com\/awslabs\/soci-snapshotter v0.0.0 => github.com\/awslabs\/soci-snapshotter v0.5.0/' go.mod
    sed -i 's/github.com\/awslabs\/soci-snapshotter v0.0.0-local => ..\//github.com\/awslabs\/soci-snapshotter v0.0.0-local => github.com\/awslabs\/soci-snapshotter v0.5.0/' go.mod

    go mod tidy
    go mod vendor

    runHook postBuild
  '';

  buildPhase = ''
    runHook preBuild

    export GOCACHE=$TMPDIR/go-cache
    export GOPATH="$TMPDIR/go"
    mkdir -p $GOPATH/bin

    # the go-modules derivation is mounted above where it needs to be mounted for this build
    cp -r vendor cmd/vendor
    cd cmd
    sed -i 's/github.com\/awslabs\/soci-snapshotter v0.0.0 => ..\//github.com\/awslabs\/soci-snapshotter v0.0.0 => github.com\/awslabs\/soci-snapshotter v0.5.0/' go.mod
    sed -i 's/github.com\/awslabs\/soci-snapshotter v0.0.0-local => ..\//github.com\/awslabs\/soci-snapshotter v0.0.0-local => github.com\/awslabs\/soci-snapshotter v0.5.0/' go.mod

    cat go.mod

    cat vendor/modules.txt

    ls -al vendor/github.com/awslabs/soci-snapshotter

    chmod 0777 vendor/github.com/awslabs/soci-snapshotter/ztoc/compression/gzip_zinfo.go
    #echo "testing..." > vendor/github.com/awslabs/soci-snapshotter/ztoc/compression/gzip_zinfo.go
    sed 's/#cgo LDFLAGS: -L\''${SRCDIR}\/..\/out -l:libz.a/#cgo pkg-config: zlib/' vendor/github.com/awslabs/soci-snapshotter/ztoc/compression/gzip_zinfo.go > $TMPDIR/gzip_zinfo.go
    cat $TMPDIR/gzip_zinfo.go
    cat $TMPDIR/gzip_zinfo.go > vendor/github.com/awslabs/soci-snapshotter/ztoc/compression/gzip_zinfo.go

    echo
    echo "*** Starting soci build..."
    echo
    go build -v -ldflags '-s -w -X github.com/awslabs/soci-snapshotter/version.Version=${version} -X github.com/awslabs/soci-snapshotter/version.Revision=000000' -o "''${GOPATH}/bin/soci" ./soci
    go build -v -ldflags '-s -w -X github.com/awslabs/soci-snapshotter/version.Version=${version} -X github.com/awslabs/soci-snapshotter/version.Revision=000000' -o "''${GOPATH}/bin/soci-snapshotter-grpc" ./soci-snapshotter-grpc

    runHook postBuild
  '';

  meta = with lib; {
    description = "A tool to index OCI images to support lazy loading mechanisms.";
    homepage = "https://github.com/awslabs/soci-snapshotter";
    license = licenses.asl20;
    # maintainers = with maintainers; [ ];
  };
}
