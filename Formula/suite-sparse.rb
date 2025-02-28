class SuiteSparse < Formula
  desc "Suite of Sparse Matrix Software"
  homepage "http://faculty.cse.tamu.edu/davis/suitesparse.html"
  url "https://github.com/DrTimothyAldenDavis/SuiteSparse/archive/v5.7.1.tar.gz"
  sha256 "5ba5add1663d51a1b6fb128b50fe869b497f3096765ff7f8212f0ede044b9557"
  revision 1

  bottle do
    sha256 "5c3ce3ea482f6f46b7b012c21a1998a8eccb1b9261e6a06afe6b5900d2c55f19" => :catalina
    sha256 "cc77c74d00061555f536afa554d088395a75c405b364d1093c39122fbf2af352" => :mojave
    sha256 "1b9f2d0df61c59594115a70a1cafd849904244a1ac00cbdc7b7fc67b689cc69b" => :high_sierra
    sha256 "d3590baa33527e0122cf30f914ef5d87fa9f0f4a9563fa140cf7b6721bd96882" => :x86_64_linux
  end

  depends_on "cmake" => :build
  depends_on "metis"
  depends_on "openblas"
  depends_on "tbb"

  uses_from_macos "m4"

  conflicts_with "mongoose", :because => "suite-sparse vendors libmongoose.dylib"

  def install
    mkdir "GraphBLAS/build" do
      system "cmake", "..", *std_cmake_args
    end

    args = [
      "INSTALL=#{prefix}",
      "BLAS=-L#{Formula["openblas"].opt_lib} -lopenblas",
      "LAPACK=$(BLAS)",
      "MY_METIS_LIB=-L#{Formula["metis"].opt_lib} -lmetis",
      "MY_METIS_INC=#{Formula["metis"].opt_include}",
    ]

    system "make", "library", *args
    unless OS.mac?
      args << "INSTALL_LIB=#{lib}"
      args << "INSTALL_INCLUDE=#{include}"
      args << "DESTDIR=#{prefix}"
    end
    system "make", "install", *args
    lib.install Dir["**/*.a"]
    pkgshare.install "KLU/Demo/klu_simple.c"
  end

  test do
    system ENV.cc, "-o", "test", pkgshare/"klu_simple.c",
           "-L#{lib}", "-lsuitesparseconfig", "-lklu"
    assert_predicate testpath/"test", :exist?
    assert_match "x [0] = 1", shell_output("./test")
  end
end
