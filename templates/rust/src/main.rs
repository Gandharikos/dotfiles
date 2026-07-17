use sample_rust::greeting;

fn main() {
    if std::env::args()
        .skip(1)
        .any(|argument| argument == "--version" || argument == "-V")
    {
        println!("{} {}", env!("CARGO_PKG_NAME"), env!("CARGO_PKG_VERSION"));
        return;
    }

    println!("{}", greeting("Nix"));
}
