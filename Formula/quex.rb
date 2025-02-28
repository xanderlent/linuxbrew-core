class Quex < Formula
  desc "Generate lexical analyzers"
  homepage "https://quex.sourceforge.io/"
  url "https://downloads.sourceforge.net/project/quex/quex-0.70.0.tar.gz"
  sha256 "761b68d68255862001d1fe8bf8876ba3d35586fd1927a46a667aea11511452cd"
  head "https://svn.code.sf.net/p/quex/code/trunk"

  bottle do
    cellar :any_skip_relocation
    sha256 "f3d39a7468e8c529ce1c0d6ab5b2d028f50771304993e9f2e996490f846c4b6c" => :catalina
    sha256 "f3d39a7468e8c529ce1c0d6ab5b2d028f50771304993e9f2e996490f846c4b6c" => :mojave
    sha256 "f3d39a7468e8c529ce1c0d6ab5b2d028f50771304993e9f2e996490f846c4b6c" => :high_sierra
    sha256 "ef42df0a4413a021056ceb695796065a083651c29f89f9a2f78e707ae3a1b823" => :x86_64_linux
  end

  # Migration to Python 3 has started, see for example:
  # https://sourceforge.net/p/quex/git/ci/e0d9de092751dc0b61e0c7fa2777fdc49ea1d13e/
  depends_on :macos # Due to Python 2 (does not support Python 3)

  def install
    libexec.install "quex", "quex-exe.py"
    doc.install "README", "demo"

    # Use a shim script to set QUEX_PATH on the user's behalf
    (bin/"quex").write <<~EOS
      #!/bin/bash
      QUEX_PATH="#{libexec}" "#{libexec}/quex-exe.py" "$@"
    EOS

    if build.head?
      man1.install "doc/manpage/quex.1"
    else
      man1.install "manpage/quex.1"
    end
  end

  test do
    system bin/"quex", "-i", doc/"demo/C/01-Trivial/easy.qx", "-o", "tiny_lexer"
    assert_predicate testpath/"tiny_lexer", :exist?
  end
end
