class Armor < Formula
  desc "Uncomplicated, modern HTTP server"
  homepage "https://github.com/labstack/armor"
  url "https://github.com/labstack/armor/archive/v0.4.14.tar.gz"
  sha256 "bcaee0eaa1ef29ef439d5235b955516871c88d67c3ec5191e3421f65e364e4b8"
  head "https://github.com/labstack/armor.git"

  bottle do
    cellar :any_skip_relocation
    rebuild 1
    sha256 "d0bbf39148c0dabb28f777b951492814a708dc64610106587b1315fcd6a08559" => :catalina
    sha256 "538f2c340ec151aa7c22847a61d3c8e1d255d121a2b2a75fe2fe7d22f5067347" => :mojave
    sha256 "8fc3b2ebb6d8bc978f6dd04c92e2a43573b052e51d69398deb4f5a2b04e0f87d" => :high_sierra
    sha256 "22317bcb46b542191211393d8c0f460b142991b9b779c0d9c98c0d6b71a8dc3d" => :x86_64_linux
  end

  depends_on "go" => :build

  def install
    system "go", "build", "-ldflags", "-s -w", "-trimpath", "-o", bin/"armor", "cmd/armor/main.go"
    prefix.install_metafiles
  end

  test do
    port = free_port
    pid = fork do
      exec "#{bin}/armor --port #{port}"
    end
    sleep 1
    output = shell_output("curl -sI http://localhost:#{port}")
    assert_match(/200 OK/m, output)
  ensure
    Process.kill("HUP", pid)
  end
end
