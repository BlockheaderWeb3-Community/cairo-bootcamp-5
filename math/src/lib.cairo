fn main() {
    println!("Hello, world!");
}

pub mod math;

#[cfg(test)]
mod tests {
    use crate::math::math::{add, sub, mul};

    fn test_assert(result: u256, expected: u256) {
        assert(result == expected, 'This works!');
    }

    #[test]
    fn test_add() {
        let result = add(30, 50);
        println!("Result: {}", result);
        test_assert(result.into(), 80_u256);
    }

    #[test]
    fn test_sub() {
        let result = sub(2, 3);
        let converted_result: i8 = result.try_into().unwrap();
        println!("This felt works: {}", converted_result);
        assert(result == -1, 'This works!');
    }
    #[test]
    fn test_mul() {
        let result = mul(255, 255);
        assert(result == 255 * 255, 'Working perfectly!');
    }

}
