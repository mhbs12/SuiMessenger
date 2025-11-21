module sui_messenger::message;

use std::string::String;

/// Módulo com estruturas de dados principais

/// Estrutura principal de mensagem
public struct Message has key, store {
    id: UID,
    sender: address,
    recipient: address,
    walrus_blob_id: String, // ID do blob no Walrus
    encrypted_metadata: vector<u8>, // Metadata criptografada
    seal_policy_id: Option<ID>, // ID da policy do SEAL (opcional)
    created_at: u64,
    is_read: bool,
}

// ==================== CONSTRUTORES ====================

public(package) fun new_message(
    sender: address,
    recipient: address,
    walrus_blob_id: String,
    encrypted_metadata: vector<u8>,
    seal_policy_id: Option<ID>,
    created_at: u64,
    ctx: &mut TxContext,
): Message {
    Message {
        id: object::new(ctx),
        sender,
        recipient,
        walrus_blob_id,
        encrypted_metadata,
        seal_policy_id,
        created_at,
        is_read: false,
    }
}

// ==================== GETTERS ====================

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

// ==================== SETTERS (package only) ====================

public(package) fun mark_as_read(message: &mut Message) {
    message.is_read = true;
}

// ==================== HELPERS ====================

public fun get_full_info(
    message: &Message,
): (
    address, // sender
    address, // recipient
    String, // blob_id
    vector<u8>, // encrypted_metadata
    Option<ID>, // seal_policy_id
    u64, // created_at
    bool, // is_read
) {
    (
        message.sender,
        message.recipient,
        message.walrus_blob_id,
        message.encrypted_metadata,
        message.seal_policy_id,
        message.created_at,
        message.is_read,
    )
}

// ==================== DESTRUCTOR ====================

public(package) fun destroy(message: Message) {
    let Message {
        id,
        sender: _,
        recipient: _,
        walrus_blob_id: _,
        encrypted_metadata: _,
        seal_policy_id: _,
        created_at: _,
        is_read: _,
    } = message;

    object::delete(id);
}
