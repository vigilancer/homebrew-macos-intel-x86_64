class EvilHelix < Formula
  desc "Soft fork of the helix editor"
  homepage "https://evil-helix.github.io"
  license "MPL-2.0"
  # `brew install` refuses a formula with no stable spec unless `--HEAD` is passed.
  # Reporting the head spec as stable makes a plain install build main.
  # `brew upgrade` skips HEAD unless `--fetch-HEAD`, so always compare commits.
  head "https://github.com/usagi-flow/evil-helix.git", branch: "main"

  depends_on "rust" => :build

  conflicts_with "helix", because: "both install `hx` binaries"
  conflicts_with "hex", because: "both install `hx` binaries"

  def stable = head

  def head_version_outdated?(version, fetch_head: false)
    super(version, fetch_head: true)
  end

  def install
    ENV["HELIX_DEFAULT_RUNTIME"] = libexec/"runtime"
    system "cargo", "install", "-vv", *std_cargo_args(path: "helix-term")
    rm_r "runtime/grammars/sources/"
    libexec.install "runtime"

    bash_completion.install "contrib/completion/hx.bash" => "hx"
    fish_completion.install "contrib/completion/hx.fish"
    zsh_completion.install "contrib/completion/hx.zsh" => "_hx"
  end

  test do
    assert_match(/\d/, shell_output("#{bin}/hx --version"))
    assert_match "✓", shell_output("#{bin}/hx --health")
  end
end
