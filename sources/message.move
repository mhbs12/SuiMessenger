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
    created_at: u64,
    expires_at: u64,
    is_read: bool,
    read_proof: Option<vector<u8>>, // ZK proof de leitura
    is_burned: bool,
}

/// Configuração de auto-destruição
public struct BurnConfig has key, store {
    id: UID,
    owner: address,
    default_ttl: u64, // Tempo padrão (segundos)
    auto_burn: bool,
}

// ==================== CONSTRUTORES ====================

public(package) fun new_message(
    sender: address,
    recipient: address,
    walrus_blob_id: String,
    encrypted_metadata: vector<u8>,
    created_at: u64,
    expires_at: u64,
    ctx: &mut TxContext,
): Message {
    Message {
        id: object::new(ctx),
        sender,
        recipient,
        walrus_blob_id,
        encrypted_metadata,
        created_at,
        expires_at,
        is_read: false,
        read_proof: std::option::none(),
        is_burned: false,
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

public fun expires_at(message: &Message): u64 {
    message.expires_at
}

public fun is_read(message: &Message): bool {
    message.is_read
}

public fun read_proof(message: &Message): &Option<vector<u8>> {
    &message.read_proof
}

public fun is_burned(message: &Message): bool {
    message.is_burned
}

// ==================== SETTERS (package only) ====================

public(package) fun mark_as_read(message: &mut Message, proof: vector<u8>) {
    message.is_read = true;
    message.read_proof = std::option::some(proof);
}

public(package) fun mark_as_burned(message: &mut Message) {
    message.is_burned = true;
}

// ==================== HELPERS ====================

public fun is_expired(message: &Message, current_time: u64): bool {
    current_time >= message.expires_at
}

public fun get_full_info(
    message: &Message,
): (
    address, // sender
    address, // recipient
    String, // blob_id
    u64, // created_at
    u64, // expires_at
    bool, // is_read
    bool, // is_burned
) {
    (
        message.sender,
        message.recipient,
        message.walrus_blob_id,
        message.created_at,
        message.expires_at,
        message.is_read,
        message.is_burned,
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
        created_at: _,
        expires_at: _,
        is_read: _,
        read_proof: _,
        is_burned: _,
    } = message;

    object::delete(id);
}
