/// Builds the greeting shown by the example binary.
#[must_use]
pub fn greeting(name: &str) -> String {
    format!("Hello, {name}!")
}

#[cfg(test)]
mod tests {
    use super::greeting;

    #[test]
    fn greets_the_given_name() {
        assert_eq!(greeting("Rust"), "Hello, Rust!");
    }
}
