class Pympress < Formula
  include Language::Python::Virtualenv

  desc "Simple and powerful dual-screen PDF reader designed for presentations"
  homepage "https://github.com/Cimbali/pympress/"
  url "https://files.pythonhosted.org/packages/d1/cf/a81c579fa9b65daa7b159220038adaaeb144d21616dc83868ed7c42589d9/pympress-1.5.2.tar.gz"
  sha256 "3f19236897ba7b3106b0b8ccd04ca32aee42fe3a604ea1d7ced305abcceeecf2"
  revision 1
  head "https://github.com/Cimbali/pympress.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "8487b99dfd1f70e1e7704f89a602c5cad17959f4d7df19c718b937a2120527c7" => :catalina
    sha256 "be26e5f8a140083f387e58269a7da6d54a84f18996adb74af3ed855e9a4a619c" => :mojave
    sha256 "1b26a67b3c2104c26634f86faf363c893433abc0461962ed785f92dac9c07d37" => :high_sierra
    sha256 "0da242d88b09729041b9dc08f3e72ef5a9e2ef45086fa94bcea40562326a8aff" => :x86_64_linux
  end

  depends_on "gobject-introspection"
  depends_on "gtk+3"
  depends_on "poppler"
  depends_on "pygobject3"
  depends_on "python@3.8"

  resource "argh" do
    url "https://files.pythonhosted.org/packages/e3/75/1183b5d1663a66aebb2c184e0398724b624cecd4f4b679cb6e25de97ed15/argh-0.26.2.tar.gz"
    sha256 "e9535b8c84dc9571a48999094fda7f33e63c3f1b74f3e5f3ac0105a58405bb65"
  end

  resource "pathtools" do
    url "https://files.pythonhosted.org/packages/e7/7f/470d6fcdf23f9f3518f6b0b76be9df16dcc8630ad409947f8be2eb0ed13a/pathtools-0.1.2.tar.gz"
    sha256 "7c35c5421a39bb82e58018febd90e3b6e5db34c5443aaaf742b3f33d4655f1c0"
  end

  resource "python-vlc" do
    url "https://files.pythonhosted.org/packages/a8/51/299f4804c43f99d718ed43a63b1ea0712932e25b6bbe1ee1817cb8e954f7/python-vlc-3.0.7110.tar.gz"
    sha256 "821bca0dbe08fbff97a65e56ff2318ad7d499330876579c39f01f3fb38c7b679"
  end

  resource "PyYAML" do
    url "https://files.pythonhosted.org/packages/e3/e8/b3212641ee2718d556df0f23f78de8303f068fe29cdaa7a91018849582fe/PyYAML-5.1.2.tar.gz"
    sha256 "01adf0b6c6f61bd11af6e10ca52b7d4057dd0be0343eb9283c878cf3af56aee4"
  end

  resource "watchdog" do
    url "https://files.pythonhosted.org/packages/bb/e3/5a55d48a29300160779f0a0d2776d17c1b762a2039b36de528b093b87d5b/watchdog-0.9.0.tar.gz"
    sha256 "965f658d0732de3188211932aeb0bb457587f04f63ab4c1e33eab878e9de961d"
  end

  def install
    virtualenv_install_with_resources
    bin.install_symlink libexec/"bin/pympress"
  end

  test do
    # (pympress:48790): Gtk-WARNING **: 13:03:37.080: cannot open display
    return if !OS.mac? && ENV["CI"]

    system bin/"pympress", "--help"

    # Version info contained in log file only if all dependencies loaded successfully
    assert_predicate testpath/"Library/Logs/pympress.log", :exist?
    output = (testpath/"Library/Logs/pympress.log").read
    assert_match /^INFO:pympress.__main__:Pympress: #{version}\s*;/, output
  end
end
