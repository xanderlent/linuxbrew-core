class Root < Formula
  desc "Object oriented framework for large scale data analysis"
  homepage "https://root.cern.ch/"
  url "https://root.cern.ch/download/root_v6.20.02.source.tar.gz"
  version "6.20.02"
  sha256 "0997586bf097c0afbc6f08edbffcebf5eb6a4237262216114ba3f5c8087dcba6"
  revision 1
  head "https://github.com/root-project/root.git"

  bottle do
    sha256 "3aeb2401063eb4329e5f7c1941b4fe14cdaa146c381d3ca163ccae2501275083" => :catalina
    sha256 "c38f01d9ff39d49fff500944a5a1068e8db1309b0316c75a7556fb9b9c590719" => :mojave
    sha256 "24785964f500c20ab876599e4d104e83346b2448cd726bdea850338d776335dc" => :high_sierra
    sha256 "d99f36e01c4c17008603b1f3af33ca99130291c12d46f41e844723a5a0781125" => :x86_64_linux
  end

  if OS.mac?
    # https://github.com/Homebrew/homebrew-core/issues/30726
    # strings libCling.so | grep Xcode:
    #  /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/include/c++/v1
    #  /Applications/Xcode.app/Contents/Developer
    pour_bottle? do
      reason "The bottle hardcodes locations inside Xcode.app"
      satisfy do
        MacOS::Xcode.installed? &&
          MacOS::Xcode.prefix.to_s.include?("/Applications/Xcode.app/")
      end
    end
  end

  depends_on "cmake" => :build
  depends_on "cfitsio"
  depends_on "davix"
  depends_on "fftw"
  depends_on "gcc" # for gfortran
  depends_on "graphviz"
  depends_on "gsl"
  # Temporarily depend on Homebrew libxml2 to work around a brew issue:
  # https://github.com/Homebrew/brew/issues/5068
  depends_on "libxml2" if MacOS.version >= :mojave
  depends_on "lz4"
  depends_on "numpy" # for tmva
  depends_on "openssl@1.1"
  depends_on "pcre"
  depends_on "python@3.8"
  depends_on "tbb"
  depends_on "xrootd"
  depends_on "xz" # for LZMA
  depends_on "zstd"
  unless OS.mac?
    depends_on "linuxbrew/xorg/libx11"
    depends_on "linuxbrew/xorg/libxext"
    depends_on "linuxbrew/xorg/libxft"
    depends_on "linuxbrew/xorg/libxpm"
  end

  skip_clean "bin"

  def install
    # Work around "error: no member named 'signbit' in the global namespace"
    ENV.delete("SDKROOT") if DevelopmentTools.clang_build_version >= 900

    # Freetype/afterimage/gl2ps/lz4 are vendored in the tarball, so are fine.
    # However, this is still permitting the build process to make remote
    # connections. As a hack, since upstream support it, we inreplace
    # this file to "encourage" the connection over HTTPS rather than HTTP.
    inreplace "cmake/modules/SearchInstalledSoftware.cmake",
              "http://lcgpackages",
              "https://lcgpackages"

    args = std_cmake_args + %W[
      -DCMAKE_INSTALL_ELISPDIR=#{elisp}
      -DPYTHON_EXECUTABLE=#{Formula["python@3.8"].opt_bin}/python3
      -Dbuiltin_cfitsio=OFF
      -Dbuiltin_freetype=ON
      -Ddavix=ON
      -Dfftw3=ON
      -Dfitsio=ON
      -Dfortran=ON
      -Dgdml=ON
      -Dgnuinstall=ON
      -Dimt=ON
      -Dmathmore=ON
      -Dminuit2=ON
      -Dmysql=OFF
      -Dpgsql=OFF
      -Dpython=ON
      -Droofit=ON
      -Dssl=ON
      -Dtmva=ON
      -Dxrootd=ON
    ]

    args << "-DCLING_CXX_PATH=clang++" if OS.mac?

    cxx_version = (MacOS.version < :mojave) ? 14 : 17
    args << "-DCMAKE_CXX_STANDARD=#{cxx_version}"

    mkdir "builddir" do
      system "cmake", "..", *args

      # Work around superenv stripping out isysroot leading to errors with
      # libsystem_symptoms.dylib (only available on >= 10.12) and
      # libsystem_darwin.dylib (only available on >= 10.13)
      if OS.mac? && MacOS.version < :high_sierra
        system "xcrun", "make", "install"
      else
        system "make", "install"
      end

      chmod 0755, Dir[bin/"*.*sh"]
    end
  end

  def caveats
    <<~EOS
      Because ROOT depends on several installation-dependent
      environment variables to function properly, you should
      add the following commands to your shell initialization
      script (.bashrc/.profile/etc.), or call them directly
      before using ROOT.

      For bash users:
        . #{HOMEBREW_PREFIX}/bin/thisroot.sh
      For zsh users:
        pushd #{HOMEBREW_PREFIX} >/dev/null; . bin/thisroot.sh; popd >/dev/null
      For csh/tcsh users:
        source #{HOMEBREW_PREFIX}/bin/thisroot.csh
      For fish users:
        . #{HOMEBREW_PREFIX}/bin/thisroot.fish
    EOS
  end

  test do
    (testpath/"test.C").write <<~EOS
      #include <iostream>
      void test() {
        std::cout << "Hello, world!" << std::endl;
      }
    EOS

    # Test ROOT command line mode
    ENV.prepend_path "LD_LIBRARY_PATH", lib/"root" unless OS.mac?
    system "#{bin}/root", "-b", "-l", "-q", "-e", "gSystem->LoadAllLibraries(); 0"

    # Test ROOT executable
    (testpath/"test_root.bash").write <<~EOS
      . #{bin}/thisroot.sh
      root -l -b -n -q test.C
    EOS
    assert_equal "\nProcessing test.C...\nHello, world!\n",
                 shell_output("/bin/bash test_root.bash")

    (testpath/"test.cpp").write <<~EOS
      #include <iostream>
      #include <TString.h>
      int main() {
        std::cout << TString("Hello, world!") << std::endl;
        return 0;
      }
    EOS

    # Test linking
    (testpath/"test_compile.bash").write <<~EOS
      . #{bin}/thisroot.sh
      $(root-config --cxx) $(root-config --cflags) $(root-config --libs) $(root-config --ldflags) test.cpp
      ./a.out
    EOS
    assert_equal "Hello, world!\n",
                 shell_output("/bin/bash test_compile.bash")

    # Test Python module
    ENV["PYTHONPATH"] = lib/"root"
    system Formula["python@3.8"].opt_bin/"python3", "-c", "import ROOT; ROOT.gSystem.LoadAllLibraries()"
  end
end
