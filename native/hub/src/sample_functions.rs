//! This module is only for demonstration purposes.
//! You might want to remove this module in production.

use crate::bridge::{
    api::{RustOperation, RustRequest, RustResponse, RustSignal},
    send_rust_signal,
};

use prost::Message;

pub async fn handle_increasing_number(rust_request: RustRequest) -> RustResponse {
    use crate::messages::increasing_number::CounterInc;
    match rust_request.operation {
        RustOperation::Create => RustResponse::default(),
        RustOperation::Read => {
            let message_bytes = rust_request.message.unwrap();
            let request_message = CounterInc::decode(message_bytes.as_slice()).unwrap();
            println!("Rust received: {:?}", request_message.counter);
            let new_number = request_message.counter + 1;
            println!("Rust sending: {:?}", new_number);

            let response_message = CounterInc {
                counter: new_number,
            };
            RustResponse {
                successful: true,
                message: Some(response_message.encode_to_vec()),
                blob: None,
            }
        }
        RustOperation::Update => RustResponse::default(),
        RustOperation::Delete => RustResponse::default(),
    }
}

pub async fn handle_counter_number(rust_request: RustRequest) -> RustResponse {
    use crate::messages::counter_tuto::{ReadRequest, ReadResponse};
    // We import message structs in this handler function
    // because schema will differ by Rust resource.

    match rust_request.operation {
        RustOperation::Create => RustResponse::default(),
        RustOperation::Read => {
            // Decode raw bytes into a Rust message object.
            let message_bytes = rust_request.message.unwrap();
            let request_message = ReadRequest::decode(message_bytes.as_slice()).unwrap();

            let new_number: Vec<i32> = request_message
                .input_numbers
                .into_iter()
                .map(|x| x + 1)
                .collect();
            let new_string = request_message.input_string.to_uppercase();

            // Return the response that will be sent to Dart.
            let response_message = ReadResponse {
                output_numbers: new_number,
                output_string: new_string,
            };
            RustResponse {
                successful: true,
                message: Some(response_message.encode_to_vec()),
                blob: None,
            }
        }
        RustOperation::Update => RustResponse::default(),
        RustOperation::Delete => RustResponse::default(),
    }
}

pub async fn stream_increment_num() {
    use crate::messages::increasing_number::{Signal, ID};

    let mut current_number: i32 = 1;
    loop {
        crate::sleep(std::time::Duration::from_millis(1000)).await;
        let signal_message = Signal { current_number };
        let rust_signal = RustSignal {
            resource: ID,
            message: Some(signal_message.encode_to_vec()),
            blob: None,
        };
        send_rust_signal(rust_signal);
        current_number += 1;
    }
}
