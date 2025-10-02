pub mod math {
    pub fn add(a: u8, b: u8) -> u8 {
        a + b // Implicit return
    }
    
    pub fn sub(a: felt252, b: felt252) -> felt252 {
        a - b
    }

    pub fn mul(a: u8, b: u8) -> u32 {
        (a * b).into()
    }

    pub fn div(a: u8, b: u8) -> u8 {
        a / b
    }
    
    
}