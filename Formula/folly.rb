class Folly < Formula
  desc "Collection of reusable C++ library artifacts developed at Facebook"
  homepage "https://github.com/facebook/folly"
  url "https://github.com/facebook/folly/archive/v2020.03.30.00.tar.gz"
  sha256 "01b5b50f7b51d128593a441f1f5f0de42b0aec406e567d48bb7d7058c6c199f1"
  head "https://github.com/facebook/folly.git"

  bottle do
    cellar :any
    sha256 "180bfe6cd9107828b1ab3dbaf8e06fb9c0c0b823fe0c36a877f1b7ba7523cb5b" => :catalina
    sha256 "82514441b0042737b12982881af1e70d74ff097137ec8ddc60ac65c8b5fabe10" => :mojave
    sha256 "3515adea10fd9941dd08b2d4f7e29602be20207b70c3b913135697f3336c680e" => :high_sierra
    sha256 "a13d4bf62fd52c0f456c00cd2114766e5f239f25306e34a933eea0e903cb9c7f" => :x86_64_linux
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "boost"
  depends_on "double-conversion"
  depends_on "fmt"
  depends_on "gflags"
  depends_on "glog"
  depends_on "libevent"
  depends_on "lz4"
  # https://github.com/facebook/folly/issues/966
  depends_on :macos => :high_sierra if OS.mac?

  depends_on "openssl@1.1"
  depends_on "snappy"
  depends_on "xz"
  depends_on "zstd"
  depends_on "jemalloc" unless OS.mac?

  uses_from_macos "python"

  def install
    mkdir "_build" do
      args = std_cmake_args
      args << "-DFOLLY_USE_JEMALLOC=#{OS.mac? ? "OFF" : "ON"}"

      system "cmake", "..", *args, "-DBUILD_SHARED_LIBS=ON", ("-DCMAKE_POSITION_INDEPENDENT_CODE=ON" unless OS.mac?)
      system "make"
      system "make", "install"

      system "make", "clean"
      system "cmake", "..", *args, "-DBUILD_SHARED_LIBS=OFF"
      system "make"
      lib.install "libfolly.a", "folly/libfollybenchmark.a"
    end
  end

  test do
    (testpath/"test.cc").write <<~EOS
      #include <folly/FBVector.h>
      int main() {
        folly::fbvector<int> numbers({0, 1, 2, 3});
        numbers.reserve(10);
        for (int i = 4; i < 10; i++) {
          numbers.push_back(i * 2);
        }
        assert(numbers[6] == 12);
        return 0;
      }
    EOS
    system ENV.cxx, "-std=c++14", "test.cc", "-I#{include}", "-L#{lib}",
                    "-lfolly", "-o", "test"
    system "./test"
  end
end
