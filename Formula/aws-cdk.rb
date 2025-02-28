require "language/node"

class AwsCdk < Formula
  desc "AWS Cloud Development Kit - framework for defining AWS infra as code"
  homepage "https://github.com/aws/aws-cdk"
  url "https://registry.npmjs.org/aws-cdk/-/aws-cdk-1.32.0.tgz"
  sha256 "e72f3ee4eb6cbc98c15ffdef9438174e60c7415886b78b3c6cf04b186aa76fdc"

  bottle do
    cellar :any_skip_relocation
    sha256 "8622a9e6eb94d50abb57bbd963ff7861772490e324f3b6af383b2dc8c0574d13" => :catalina
    sha256 "c915b41d39ca823f02ec385a3dc381aea59fad1f027b0510b51b2d0925ce3dc0" => :mojave
    sha256 "118e67addb8cf0de1b758d4f46bb275a447d4dff560d9c90f01d2ba5dcf98783" => :high_sierra
    sha256 "51e40f5376f4cd96134dc8a7ea10af24f60805116e78b7721b578a35903d7e88" => :x86_64_linux
  end

  depends_on "node"

  def install
    system "npm", "install", *Language::Node.std_npm_install_args(libexec)
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    mkdir "testapp"
    cd testpath/"testapp"
    shell_output("#{bin}/cdk init app --language=javascript")
    list = shell_output("#{bin}/cdk list")
    cdkversion = shell_output("#{bin}/cdk --version")
    assert_match "TestappStack", list
    assert_match version.to_s, cdkversion
  end
end
