class Bind < Formula
  desc "Implementation of the DNS protocols"
  homepage "https://www.isc.org/downloads/bind/"

  # BIND releases with even minor version numbers (9.14.x, 9.16.x, etc) are
  # stable. Odd-numbered minor versions are for testing, and can be unstable
  # or buggy. They are not suitable for general deployment. We have to use
  # "version_scheme" because someone upgraded to 9.15.0, and required a
  # downgrade.

  url "https://downloads.isc.org/isc/bind9/9.16.1/bind-9.16.1.tar.xz"
  sha256 "a913d7e78135b9123d233215b58102fa0f18130fb1e158465a1c2b6f3bd75e91"
  revision 1
  version_scheme 1
  head "https://gitlab.isc.org/isc-projects/bind9.git"

  bottle do
    sha256 "f9e1a8039cf1ee1a38bedc48f9926cea641f6b0bcba97611836e3c1f7fde3d95" => :catalina
    sha256 "b3942cae835a7e0b3299b272630a06199f3cb35dce0595101e70e82d3dfe93ea" => :mojave
    sha256 "efc27f8f2679a47c4df251616c753d67f12e23369b97e83e47602fcc2e4d1d6f" => :high_sierra
    sha256 "c3f65704e86e72d042c274f28131c6012314396cc42d1ace6802e088b9e04919" => :x86_64_linux
  end

  depends_on "pkg-config" => :build
  depends_on "json-c"
  depends_on "libuv"
  depends_on "openssl@1.1"
  depends_on "python@3.8"

  resource "ply" do
    url "https://files.pythonhosted.org/packages/e5/69/882ee5c9d017149285cab114ebeab373308ef0f874fcdac9beb90e0ac4da/ply-3.11.tar.gz"
    sha256 "00c7c1aaa88358b9c765b6d3000c6eec0ba42abca5351b095321aef446081da3"
  end

  def install
    xy = Language::Python.major_minor_version Formula["python@3.8"].opt_bin/"python3"
    vendor_site_packages = libexec/"vendor/lib/python#{xy}/site-packages"
    ENV.prepend_create_path "PYTHONPATH", vendor_site_packages
    resources.each do |r|
      r.stage do
        system Formula["python@3.8"].opt_bin/"python3", *Language::Python.setup_install_args(libexec/"vendor")
      end
    end

    # Fix "configure: error: xml2-config returns badness"
    ENV["SDKROOT"] = MacOS.sdk_path if MacOS.version == :sierra || MacOS.version == :el_capitan

    system "./configure", "--prefix=#{prefix}",
                          "--with-json-c",
                          "--with-openssl=#{Formula["openssl@1.1"].opt_prefix}",
                          "--with-libjson=#{Formula["json-c"].opt_prefix}",
                          "--with-python-install-dir=#{vendor_site_packages}",
                          "--without-lmdb",
                          "--with-python=#{Formula["python@3.8"].opt_bin}/python3",
                          *("--disable-linux-caps" unless OS.mac?)

    system "make"
    system "make", "install"

    (buildpath/"named.conf").write named_conf
    system "#{sbin}/rndc-confgen", "-a", "-c", "#{buildpath}/rndc.key"
    etc.install "named.conf", "rndc.key"
  end

  def post_install
    (var/"log/named").mkpath

    # Create initial configuration/zone/ca files.
    # (Mirrors Apple system install from 10.8)
    unless (var/"named").exist?
      (var/"named").mkpath
      (var/"named/localhost.zone").write localhost_zone
      (var/"named/named.local").write named_local
    end
  end

  def named_conf
    <<~EOS
      //
      // Include keys file
      //
      include "#{etc}/rndc.key";

      // Declares control channels to be used by the rndc utility.
      //
      // It is recommended that 127.0.0.1 be the only address used.
      // This also allows non-privileged users on the local host to manage
      // your name server.

      //
      // Default controls
      //
      controls {
          inet 127.0.0.1 port 54 allow { any; }
          keys { "rndc-key"; };
      };

      options {
          directory "#{var}/named";
          /*
           * If there is a firewall between you and nameservers you want
           * to talk to, you might need to uncomment the query-source
           * directive below.  Previous versions of BIND always asked
           * questions using port 53, but BIND 8.1 uses an unprivileged
           * port by default.
           */
          // query-source address * port 53;
      };
      //
      // a caching only nameserver config
      //
      zone "localhost" IN {
          type master;
          file "localhost.zone";
          allow-update { none; };
      };

      zone "0.0.127.in-addr.arpa" IN {
          type master;
          file "named.local";
          allow-update { none; };
      };

      logging {
              category default {
                      _default_log;
              };

              channel _default_log  {
                      file "#{var}/log/named/named.log";
                      severity info;
                      print-time yes;
              };
      };
    EOS
  end

  def localhost_zone
    <<~EOS
      $TTL    86400
      $ORIGIN localhost.
      @            1D IN SOA    @ root (
                          42        ; serial (d. adams)
                          3H        ; refresh
                          15M        ; retry
                          1W        ; expiry
                          1D )        ; minimum

                  1D IN NS    @
                  1D IN A        127.0.0.1
    EOS
  end

  def named_local
    <<~EOS
      $TTL    86400
      @       IN      SOA     localhost. root.localhost.  (
                                            1997022700 ; Serial
                                            28800      ; Refresh
                                            14400      ; Retry
                                            3600000    ; Expire
                                            86400 )    ; Minimum
                    IN      NS      localhost.

      1       IN      PTR     localhost.
    EOS
  end

  plist_options :startup => true

  def plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>EnableTransactions</key>
        <true/>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>RunAtLoad</key>
        <true/>
        <key>ProgramArguments</key>
        <array>
          <string>#{opt_sbin}/named</string>
          <string>-f</string>
          <string>-c</string>
          <string>#{etc}/named.conf</string>
        </array>
        <key>ServiceIPC</key>
        <false/>
      </dict>
      </plist>
    EOS
  end

  test do
    system bin/"dig", "-v"
    system bin/"dig", "brew.sh"
  end
end
