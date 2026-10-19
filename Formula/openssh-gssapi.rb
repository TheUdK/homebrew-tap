class OpensshGssapi < Formula
  desc "OpenSSH with Debian's GSS-API authentication and key exchange patch"
  homepage "https://www.openssh.com/"
  url "https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-10.6p1.tar.gz"
  mirror "https://cloudflare.cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-10.6p1.tar.gz"
  version "10.6p1"
  sha256 "a9dc9565dffe8640f64d863cd29a32bc4a3dbdec0566a7fc44c5d6ee767d5f39"
  license "SSH-OpenSSH"
  compatibility_version 1

  # Stay pinned to whatever homebrew/core's openssh ships, so `brew bump`
  # never drifts ahead of upstream core.
  livecheck do
    formula "openssh"
  end

  # Debian dropped GSS-API from src:openssh on 2026-08-23 and moved it to the
  # separate src:openssh-gssapi package, which is now the only actively
  # rebased home for Simon Wilkinson's gsskex patch. Pinned to the Debian
  # release tag matching the OpenSSH version above -- keep these in lockstep.
  depends_on "autoconf" => :build
  depends_on "pkgconf" => :build
  depends_on "ldns"
  depends_on "libfido2"
  depends_on "openssl@3"

  uses_from_macos "mandoc" => :build
  uses_from_macos "lsof" => :test
  uses_from_macos "krb5"
  uses_from_macos "libedit"
  uses_from_macos "libxcrypt"

  on_linux do
    depends_on "linux-pam"
    depends_on "zlib-ng-compat"
  end

  conflicts_with "openssh", because: "both install ssh, scp, sftp and friends"

  resource "com.openssh.sshd.sb" do
    url "https://raw.githubusercontent.com/apple-oss-distributions/OpenSSH/OpenSSH-268.100.4/com.openssh.sshd.sb"
    sha256 "a273f86360ea5da3910cfa4c118be931d10904267605cdd4b2055ced3a829774"
  end

  patch do
    url "https://salsa.debian.org/ssh-team/openssh-gssapi/-/raw/debian/1%2510.6p1-1/debian/patches/gssapi.patch"
    sha256 "87ef3534e2d62004b315bb2f183d59b0ac82809812352cbf0f3b429d3d5a9eff"
  end

  # The patch edits configure.ac but not the generated configure/config.h.in.

  def install
    ENV.append "CPPFLAGS", "-D__APPLE_SANDBOX_NAMED_EXTERNAL__" if OS.mac?

    # Regenerate for the patched configure.ac.
    system "autoconf"
    system "autoheader"

    args = %W[
      --sysconfdir=#{etc}/ssh
      --with-ldns
      --with-libedit
      --with-kerberos5
      --with-pam
      --with-ssl-dir=#{formula_opt_prefix("openssl@3")}
      --with-security-key-builtin
    ]

    args << "--with-privsep-path=#{var}/lib/sshd" if OS.linux?

    system "./configure", *args, *std_configure_args
    system "make"
    ENV.deparallelize
    system "make", "install"

    bin.install_symlink bin/"ssh" => "slogin"

    buildpath.install resource("com.openssh.sshd.sb")
    (etc/"ssh").install "com.openssh.sshd.sb" => "org.openssh.sshd.sb"

    inreplace etc/"ssh/sshd_config", prefix, opt_prefix
  end

  test do
    assert_match "OpenSSH_", shell_output("#{bin}/ssh -V 2>&1")

    # The whole point of this tap: the gsskex keywords must parse.
    %w[
      GSSAPIClientIdentity=user@EXAMPLE.COM
      GSSAPIServerIdentity=host.example.com
      GSSAPIKeyExchange=yes
      GSSAPITrustDNS=yes
      GSSAPIRenewalForcesRekey=yes
    ].each do |opt|
      output = shell_output("#{bin}/ssh -F /dev/null -o #{opt} -G localhost 2>&1")
      refute_match "Bad configuration option", output
    end
  end
end
