require "language/node"

class ContentfulCli < Formula
  desc "Contentful command-line tools"
  homepage "https://github.com/contentful/contentful-cli"
  url "https://registry.npmjs.org/contentful-cli/-/contentful-cli-1.3.12.tgz"
  sha256 "e7dfbf608ba66c2c8c1b15dd0b1da51f655ca5720e497f5db34b1e136f16a3fc"
  head "https://github.com/contentful/contentful-cli.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "0efd6da469a7623c2d5d1184c2d77afc7f553c465a3058016718d58a37f0d414" => :catalina
    sha256 "b6de547a49f7e15012d184e465a07bcd2f855442e87430acb9815b329d740b8e" => :mojave
    sha256 "0e9163ce60ff6ff72e103339dbffd180814c4212cb0482c16a2722e3455232c2" => :high_sierra
    sha256 "cf2743a710f8db104c91c07e872aa68ac5ceae1f170debde36382ba2e830525e" => :x86_64_linux
  end

  depends_on "node"

  def install
    system "npm", "install", *Language::Node.std_npm_install_args(libexec)
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    output = shell_output("#{bin}/contentful space list 2>&1", 1)
    assert_match "🚨  Error: You have to be logged in to do this.", output
    assert_match "You can log in via contentful login", output
    assert_match "Or provide a managementToken via --management-Token argument", output
  end
end
