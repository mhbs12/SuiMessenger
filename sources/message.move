module sui_messenger::message;

use std::string::String;

public struct Message has key, store {
    id: UID,
    sender: address,
    recipient: address,
    walrus_blob_id: String,
    encrypted_metadata: vector<u8>,
    created_at: u64,
    is_read: bool,
}

public(package) fun new_message(
    sender: address,
    recipient: address,
    walrus_blob_id: String,
    encrypted_metadata: vector<u8>,
    created_at: u64,
    ctx: &mut TxContext,
): Message {
    Message {
        id: object::new(ctx),
        sender,
        recipient,
        walrus_blob_id,
        encrypted_metadata,
        created_at,
        is_read: false,
    }
}

public fun id(message: &Message): &UID {
    &message.id
}

public fun sender(message: &Message): address {
    message.sender
}

public fun recipient(message: &Message): address {
    message.recipient
}

public fun walrus_blob_id(message: &Message): String {
    message.walrus_blob_id
}

public fun encrypted_metadata(message: &Message): vector<u8> {
    message.encrypted_metadata
}

public fun created_at(message: &Message): u64 {
    message.created_at
}

public fun is_read(message: &Message): bool {
    message.is_read
}

public(package) fun mark_as_read(message: &mut Message) {
    message.is_read = true;
}

public fun get_full_info(message: &Message): (address, address, String, vector<u8>, u64, bool) {
    (
        message.sender,
        message.recipient,
        message.walrus_blob_id,
        message.encrypted_metadata,
        message.created_at,
        message.is_read,
    )
}

public(package) fun destroy(message: Message) {
    let Message {
        id,
        sender: _,
        recipient: _,
        walrus_blob_id: _,
        encrypted_metadata: _,
        created_at: _,
        is_read: _,
    } = message;

    object::delete(id);
}
