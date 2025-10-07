use core::dict::Felt252Dict;
#[derive(Drop)]
struct Wallet<T, U> {
    balance: T,
    address: U,
}


fn main() -> u32 {
    //Loop Demo 
    //  let mut i: usize = 0;
    //  loop{
    //     if(i >10){
    //         break;
    //     }
    //     if(i == 5){
    //         i+=1;
    //         continue;
    //     }
    //      println!("i = {}", i);
    //     i += 1; //ensure the loop is going on
    //  }
    //WHILE DEMO 
    // let mut i: usize = 0;
    // while i<10{
    //     println!("i = {}", i);
    //     if(i == 5){
    //         i+=1;
    //         continue;
    //     }
    //     i+=1;
    // }

    //FOR GUIDE
    // let a = [10, 20, 30, 40, 50].span();
    // let mut index = 0;

    // while index < 5 {
    //     println!("the value is: {}", a[index]);
    //     index += 1;
    // }
    // for element in a {
    //     println!("the value is: {}", element);
    // }
    //DEMO RANGE 
    // for number in 1..8_u8 {
    //     println!("{number}!");
    // }
    // println!("Go!!!");


    //if in a let demo
    // let cond = true;
    // let number = if cond {
    //     5
    // }else{
    //     6
    // };

    //IF DEMO

    // if number == 5 {
    //     println!("condition was true and number = {}", number);
    // } 
    // else if number == 4 {
    //     println!("condition was true and number = {}", number);
    // }

    
    // else {
    //     println!("condition was false and number = {}", number);
    // }
    // let facto = factorial(5);
    // println!("The factorial number = {}", facto);
    // let facto2 = factorial_not_recursive(5);
    // println!("The factorial number = {}", facto2);

    // let w = Wallet { balance: 3, address: 43 };
       
    //     println!("The w variable =  {}", w.balance);
    //     println!("The w variable =  {}", w.address);
    ////SHOWCASING DICTIONARIES
    // let mut contacts: Felt252Dict<felt252> = Default::default();
    //     contacts.insert('Emma', 0812345678);
    //         // Get a value and match on it
    //     let number = contacts.get('Emma');
    //     println!("{}", number);
    //     // Insert a new value for an existing key
    //     contacts.insert('Emma', 1646743);
    //       let number = contacts.get('Emma');
    //     println!("{}", number);

    // A tuple with a bunch of different types
    let tuple: (u8, ByteArray, i8, bool) = (1, "hello", -1, true);
    println!("tuple is  {:?}", tuple);
    let (x,y,z,a) = tuple;
    println!("tuple elemet is  {}, {}, {}, {}",x,y,z,a );
        fib(16)

    
}



fn fib(mut n: u32) -> u32 {
    let mut a: u32 = 0;
    let mut b: u32 = 1;
    while n != 0 {
        n = n - 1;
        let temp = b;
        b = a + b;
        a = temp;
    };
    a
}

fn factorial(mut n: u32) -> u32{
    if(n == 1){
        return 1;
    }
    n * factorial(n-1)
}

fn factorial_not_recursive(mut n:u32) -> u32{
    if(n <= 1){
        return 1;
    }
     let mut a: u32 = 1;
     for number in 1..n+1 {
        a = a * number
    }
     a
}

